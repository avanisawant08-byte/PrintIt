const express = require('express');
const router = express.Router();
const fs = require('fs');
const auth = require('../middleware/auth');
const upload = require('../config/multer');
const { getStorage } = require('../config/firebase');

const bucket = getStorage().bucket();

const sanitizeFileName = (name) => {
    return (name || 'document')
        .replace(/[^a-zA-Z0-9._-]/g, '_')
        .replace(/\.{2,}/g, '_');
};

const safeDelete = async (filePath) => {
    if (!filePath) return;
    try {
        await fs.promises.unlink(filePath);
    } catch (e) {
        // ignore if already deleted or doesn't exist
    }
};

const uploadToFirebase = (file) => {
    return new Promise((resolve, reject) => {
        const originalName = file.originalname;
        const mimeType = file.mimetype;
        const uniqueId = Date.now() + '-' + Math.round(Math.random() * 1E9);
        const safeName = sanitizeFileName(originalName);
        const fileName = `printit/uploads/${uniqueId}_${safeName}`;
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
                bytes: file.size || (file.buffer ? file.buffer.length : 0)
            });
        });

        if (file.path) {
            const readStream = fs.createReadStream(file.path);
            readStream.on('error', (err) => {
                blobStream.destroy();
                reject(err);
            });
            readStream.pipe(blobStream);
        } else if (file.buffer) {
            blobStream.end(file.buffer);
        } else {
            reject(new Error('No file content found to upload'));
        }
    });
};

// POST /api/upload — Single file
router.post('/', auth, upload.single('file'), async (req, res) => {
    try {
        if (!req.file) {
            return res.status(400).json({ error: 'No file uploaded' });
        }

        // Stream file from disk to Firebase Storage
        const result = await uploadToFirebase(req.file);

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
    } finally {
        if (req.file && req.file.path) {
            await safeDelete(req.file.path);
        }
    }
});

// POST /api/upload/guest — Single file for guest
router.post('/guest', upload.single('file'), async (req, res) => {
    try {
        if (!req.file) {
            return res.status(400).json({ error: 'No file uploaded' });
        }

        const result = await uploadToFirebase(req.file);

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
    } finally {
        if (req.file && req.file.path) {
            await safeDelete(req.file.path);
        }
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
                const result = await uploadToFirebase(file);
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
    } finally {
        if (req.files && req.files.length > 0) {
            await Promise.all(req.files.map(f => safeDelete(f.path)));
        }
    }
});

module.exports = router;