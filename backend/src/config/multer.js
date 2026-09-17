const multer = require('multer');
const path = require('path');
const os = require('os');
const fs = require('fs');

// Create dedicated temporary directory for streamed uploads
const uploadDir = path.join(os.tmpdir(), 'printit_uploads');
if (!fs.existsSync(uploadDir)) {
    fs.mkdirSync(uploadDir, { recursive: true });
}

// Whitelist of allowed MIME types for print documents and images
const ALLOWED_MIME_TYPES = new Set([
    'application/pdf',
    'image/jpeg',
    'image/png',
    'image/webp',
    'application/msword',
    'application/vnd.openxmlformats-officedocument.wordprocessingml.document',
    'application/vnd.ms-powerpoint',
    'application/vnd.openxmlformats-officedocument.presentationml.presentation',
    'application/vnd.ms-excel',
    'application/vnd.openxmlformats-officedocument.spreadsheetml.sheet',
    'text/plain',
    'application/octet-stream', // In web apps, blobs and byte arrays often arrive as octet-stream
]);

const ALLOWED_EXTENSIONS = new Set([
    '.pdf', '.jpg', '.jpeg', '.png', '.webp',
    '.doc', '.docx', '.ppt', '.pptx', '.xls', '.xlsx', '.txt'
]);

const fileFilter = (req, file, cb) => {
    const ext = path.extname(file.originalname || '').toLowerCase();
    
    // Check if extension is allowed
    const isExtAllowed = ALLOWED_EXTENSIONS.has(ext);
    // If MIME type is standard or generic application/octet-stream, extension check validates it
    const isMimeAllowed = ALLOWED_MIME_TYPES.has(file.mimetype) || (file.mimetype === 'application/octet-stream' && isExtAllowed);

    if (!isExtAllowed || !isMimeAllowed) {
        const error = new Error(`Invalid file type (${file.mimetype || 'unknown'}, ${ext || 'none'}). Only standard documents (PDF, DOCX, PPTX, XLSX, TXT) and images (JPEG, PNG, WEBP) are allowed.`);
        error.status = 400;
        error.statusCode = 400;
        return cb(error, false);
    }
    
    cb(null, true);
};

// Use diskStorage instead of memoryStorage to stream uploads without RAM buffering
const storage = multer.diskStorage({
    destination: (req, file, cb) => {
        cb(null, uploadDir);
    },
    filename: (req, file, cb) => {
        const uniqueSuffix = Date.now() + '-' + Math.round(Math.random() * 1E9);
        const ext = path.extname(file.originalname || '').toLowerCase();
        cb(null, `upload_${uniqueSuffix}${ext}`);
    }
});

const upload = multer({
    storage,
    limits: { fileSize: 50 * 1024 * 1024 }, // 50MB limit
    fileFilter
});

module.exports = upload;