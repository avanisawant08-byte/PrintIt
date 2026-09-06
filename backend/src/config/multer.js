const multer = require('multer');
const path = require('path');

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
]);

const ALLOWED_EXTENSIONS = new Set([
    '.pdf', '.jpg', '.jpeg', '.png', '.webp',
    '.doc', '.docx', '.ppt', '.pptx', '.xls', '.xlsx', '.txt'
]);

const fileFilter = (req, file, cb) => {
    const ext = path.extname(file.originalname || '').toLowerCase();
    
    if (!ALLOWED_MIME_TYPES.has(file.mimetype) || !ALLOWED_EXTENSIONS.has(ext)) {
        return cb(new Error('Invalid file type. Only standard documents (PDF, DOCX, PPTX, XLSX, TXT) and images (JPEG, PNG, WEBP) are allowed.'), false);
    }
    
    cb(null, true);
};

const upload = multer({
    storage: multer.memoryStorage(),
    limits: { fileSize: 10 * 1024 * 1024 }, // 10MB limit
    fileFilter
});

module.exports = upload;