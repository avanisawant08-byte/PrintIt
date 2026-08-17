const express = require('express');
const router = express.Router();
const auth = require('../middleware/auth');
const upload = require('../config/multer');
const { getStorage } = require('../config/firebase');

const bucket = getStorage().bucket();

const uploadToFirebase = (fileBuffer, originalName, mimeType) => {
    return new Promise((resolve, reject) => {
        const uniqueId = Date.now() + '-' + Math.round(Math.random() * 1E9);
        const fileName = `printit/uploads/${uniqueId}_${originalName}`;
        const blob = bucket.file(fileName);
        
        const blobStream = blob.createWriteStream({
            resumable: false,
            contentType: mimeType,
        });

        blobStream.on('error', (error) => {
            reject(error);
        });

        blobStream.on('finish', () => {
            const publicUrl = `https://firebasestorage.googleapis.com/v0/b/${bucket.name}/o/${encodeURIComponent(blob.name)}?alt=media`;
            resolve({
                secure_url: publicUrl,
                public_id: blob.name,
                format: mimeType.split('/')[1] || '',
                bytes: fileBuffer.length
            });
        });

        blobStream.end(fileBuffer);
    });
};

// POST /api/upload — Single file
router.post('/', auth, upload.single('file'), async (req, res) => {
    try {
        if (!req.file) {
            return res.status(400).json({ error: 'No file uploaded' });
        }

        // Upload buffer to Firebase Storage
        const result = await uploadToFirebase(req.file.buffer, req.file.originalname, req.file.mimetype);

        return res.status(201).json({
            message: 'File uploaded successfully',
            file: {
                s3_key: result.secure_url,
                public_id: result.public_id,
                original_name: req.file.originalname,
                format: result.format,
                size: result.bytes
            }
        });

    } catch (err) {
        console.error('Upload error:', err);
        res.status(500).json({ error: 'File upload failed' });
    }
});

// POST /api/upload/guest — Single file for guest
router.post('/guest', upload.single('file'), async (req, res) => {
    try {
        if (!req.file) {
            return res.status(400).json({ error: 'No file uploaded' });
        }

        const result = await uploadToFirebase(req.file.buffer, req.file.originalname, req.file.mimetype);

        return res.status(201).json({
            message: 'File uploaded successfully',
            file: {
                s3_key: result.secure_url,
                public_id: result.public_id,
                original_name: req.file.originalname,
                format: result.format,
                size: result.bytes
            }
        });

    } catch (err) {
        console.error('Upload error:', err);
        res.status(500).json({ error: 'File upload failed' });
    }
});

// POST /api/upload/multiple — Multiple files
router.post('/multiple', auth, upload.array('files', 5), async (req, res) => {
    try {
        if (!req.files || req.files.length === 0) {
            return res.status(400).json({ error: 'No files uploaded' });
        }

        const uploadedFiles = await Promise.all(
            req.files.map(async file => {
                const result = await uploadToFirebase(file.buffer, file.originalname, file.mimetype);
                return {
                    s3_key: result.secure_url,
                    public_id: result.public_id,
                    original_name: file.originalname,
                    format: result.format,
                    size: result.bytes
                };
            })
        );

        return res.status(201).json({
            message: `${req.files.length} file(s) uploaded successfully`,
            files: uploadedFiles
        });

    } catch (err) {
        console.error('Upload error:', err);
        res.status(500).json({ error: 'File upload failed' });
    }
});

module.exports = router;