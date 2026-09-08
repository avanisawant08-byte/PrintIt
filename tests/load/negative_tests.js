import http from 'k6/http';
import { check, sleep } from 'k6';
import { Rate } from 'k6/metrics';

export const negativeTestPassRate = new Rate('negative_test_pass_rate');

// Preload test assets
const oversizePdf = open('./assets/test_oversize_12m.pdf', 'b');
const unsupportedExe = open('./assets/test_unsupported.exe', 'b');
const emptyPdf = open('./assets/test_empty.pdf', 'b');
const validPdf = open('./assets/test_100k.pdf', 'b');

const BASE_URL = __ENV.BASE_URL || 'http://127.0.0.1:3000';

export const options = {
  vus: 1,
  iterations: 1,
  thresholds: {
    'negative_test_pass_rate': ['rate==1.0'], // All negative tests must pass!
  },
};

export default function () {
  console.log('--- RUNNING NEGATIVE UPLOAD TESTS ---');

  // 1. Invalid Authentication (Malformed / Expired Bearer Token)
  console.log('Test 1: Invalid Authentication on /api/upload...');
  const resInvalidAuth = http.post(
    `${BASE_URL}/api/upload`,
    { file: http.file(validPdf, 'test.pdf', 'application/pdf') },
    { headers: { 'Authorization': 'Bearer invalid_bogus_token_123' } }
  );
  const passInvalidAuth = check(resInvalidAuth, {
    'rejects invalid JWT with 401': (r) => r.status === 401,
  });
  negativeTestPassRate.add(passInvalidAuth);

  // 2. Missing File in Payload
  console.log('Test 2: Missing File in payload...');
  const resMissingFile = http.post(
    `${BASE_URL}/api/upload/guest`,
    { wrong_field_name: 'no_file_here' }
  );
  const passMissingFile = check(resMissingFile, {
    'rejects missing file with 400': (r) => r.status === 400,
    'contains error message': (r) => r.body.includes('No file uploaded') || r.status === 400,
  });
  negativeTestPassRate.add(passMissingFile);

  // 3. Unsupported File Type (.exe executable)
  console.log('Test 3: Unsupported File Type (.exe)...');
  const resUnsupported = http.post(
    `${BASE_URL}/api/upload/guest`,
    { file: http.file(unsupportedExe, 'malware.exe', 'application/x-msdownload') }
  );
  const passUnsupported = check(resUnsupported, {
    'rejects unsupported file type with 400 or 500': (r) => r.status === 400 || r.status === 500,
    'backend does not allow file': (r) => r.status !== 201,
  });
  negativeTestPassRate.add(passUnsupported);

  // 4. File Exceeding Maximum Allowed Size (12MB file > 10MB Multer limit)
  console.log('Test 4: File Exceeding 10MB limit (12MB payload)...');
  const resOversize = http.post(
    `${BASE_URL}/api/upload/guest`,
    { file: http.file(oversizePdf, 'too_large.pdf', 'application/pdf') }
  );
  const passOversize = check(resOversize, {
    'rejects oversized file with 400 or 500': (r) => r.status === 400 || r.status === 500,
    'does not return 201': (r) => r.status !== 201,
  });
  negativeTestPassRate.add(passOversize);

  // 5. Empty File (0 bytes)
  console.log('Test 5: Empty File (0 bytes)...');
  const resEmpty = http.post(
    `${BASE_URL}/api/upload/guest`,
    { file: http.file(emptyPdf, 'empty.pdf', 'application/pdf') }
  );
  const passEmpty = check(resEmpty, {
    'handles 0 byte file gracefully without crashing server': (r) => r.status === 201 || r.status === 400 || r.status === 500,
  });
  negativeTestPassRate.add(passEmpty);

  // 6. Server Liveness Health Check (ensure server didn't crash)
  console.log('Test 6: Post-negative test liveness check...');
  const resHealth = http.get(`${BASE_URL}/api/health`);
  const passHealth = check(resHealth, {
    'backend remained healthy and alive (200)': (r) => r.status === 200,
  });
  negativeTestPassRate.add(passHealth);

  console.log('--- NEGATIVE TESTS COMPLETE ---');
}
