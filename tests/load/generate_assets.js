/**
 * Generates realistic test files for k6 load and negative testing.
 * Creates files in tests/load/assets/:
 *  - 100 KB PDF
 *  - 500 KB PDF
 *  - 1 MB PDF
 *  - 5 MB PDF
 *  - 10 MB PDF (at Multer limit)
 *  - 12 MB PDF (oversized, for negative testing)
 *  - 0 KB PDF (empty file, for negative testing)
 *  - 100 KB EXE (unsupported type, for negative testing)
 */

const fs = require('fs');
const path = require('path');

const ASSETS_DIR = path.join(__dirname, 'assets');
if (!fs.existsSync(ASSETS_DIR)) {
    fs.mkdirSync(ASSETS_DIR, { recursive: true });
}

function createDummyPdf(filePath, targetBytes) {
    const header = '%PDF-1.4\n1 0 obj\n<< /Type /Catalog /Pages 2 0 R >>\nendobj\n2 0 obj\n<< /Type /Pages /Kids [3 0 R] /Count 1 >>\nendobj\n3 0 obj\n<< /Type /Page /Parent 2 0 R /MediaBox [0 0 612 792] /Contents 4 0 R >>\nendobj\n4 0 obj\n<< /Length 5 0 R >>\nstream\nBT /F1 12 Tf 72 712 Td (PrintIt Load Test Document) Tj ET\nendstream\nendobj\n5 0 obj\n';
    const footer = '\nendobj\nxref\n0 6\n0000000000 65535 f \n0000000009 00000 n \n0000000058 00000 n \n0000000115 00000 n \n0000000206 00000 n \n0000000300 00000 n \ntrailer\n<< /Size 6 /Root 1 0 R >>\nstartxref\n350\n%%EOF\n';
    
    const baseLen = Buffer.byteLength(header) + Buffer.byteLength(footer);
    const paddingNeeded = Math.max(0, targetBytes - baseLen);
    
    // Fill padding with repeated printable characters
    const padding = Buffer.alloc(paddingNeeded, 'A');
    const fullBuffer = Buffer.concat([Buffer.from(header), padding, Buffer.from(footer)]);
    
    fs.writeFileSync(filePath, fullBuffer);
    console.log(`Created: ${path.basename(filePath)} (${(fullBuffer.length / 1024).toFixed(1)} KB)`);
}

function generateAllAssets() {
    console.log('Generating test assets for k6 load testing...');
    
    createDummyPdf(path.join(ASSETS_DIR, 'test_100k.pdf'), 100 * 1024);
    createDummyPdf(path.join(ASSETS_DIR, 'test_500k.pdf'), 500 * 1024);
    createDummyPdf(path.join(ASSETS_DIR, 'test_1m.pdf'), 1024 * 1024);
    createDummyPdf(path.join(ASSETS_DIR, 'test_5m.pdf'), 5 * 1024 * 1024);
    createDummyPdf(path.join(ASSETS_DIR, 'test_10m.pdf'), 10 * 1024 * 1024 - 1024); // Just under 10MB limit
    
    // Negative test files
    createDummyPdf(path.join(ASSETS_DIR, 'test_oversize_12m.pdf'), 12 * 1024 * 1024); // Exceeds 10MB limit
    fs.writeFileSync(path.join(ASSETS_DIR, 'test_empty.pdf'), Buffer.alloc(0)); // 0 byte file
    console.log('Created: test_empty.pdf (0 KB)');
    
    fs.writeFileSync(path.join(ASSETS_DIR, 'test_unsupported.exe'), Buffer.from('MZ\x90\x00\x03\x00\x00\x00DummyExe')); // Executable
    console.log('Created: test_unsupported.exe (Unsupported binary)');

    console.log('\nAll assets ready in tests/load/assets/');
}

generateAllAssets();
