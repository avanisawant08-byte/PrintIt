import http from 'k6/http';
import { check, sleep } from 'k6';
import { Rate, Trend, Counter } from 'k6/metrics';

// Custom Metrics
export const uploadSuccessRate = new Rate('upload_success_rate');
export const uploadDuration = new Trend('upload_duration_ms', true);
export const uploadSizeBytes = new Counter('upload_bytes_total');
export const failedUploads = new Counter('failed_uploads_count');
export const orderCreationSuccessRate = new Rate('order_creation_success_rate');

// Pre-load binary test files into memory
const file100k = open('./assets/test_100k.pdf', 'b');
const file500k = open('./assets/test_500k.pdf', 'b');
const file1m = open('./assets/test_1m.pdf', 'b');
const file5m = open('./assets/test_5m.pdf', 'b');
const file10m = open('./assets/test_10m.pdf', 'b');

const fileMap = {
  '100k': { data: file100k, name: 'test_100k.pdf', size: 100 * 1024 },
  '500k': { data: file500k, name: 'test_500k.pdf', size: 500 * 1024 },
  '1m':   { data: file1m,   name: 'test_1m.pdf',   size: 1024 * 1024 },
  '5m':   { data: file5m,   name: 'test_5m.pdf',   size: 5 * 1024 * 1024 },
  '10m':  { data: file10m,  name: 'test_10m.pdf',  size: 10 * 1024 * 1024 - 1024 },
};

// Configurable Environment Parameters
const BASE_URL = __ENV.BASE_URL || 'http://127.0.0.1:3000';
const FILE_SIZE_KEY = (__ENV.FILE_SIZE || '100k').toLowerCase();
const AUTH_MODE = (__ENV.AUTH_MODE || 'guest').toLowerCase(); // 'guest' or 'auth'
const CREATE_ORDER = __ENV.CREATE_ORDER === 'true'; // If true, executes complete flow (upload -> order creation)
const SCENARIO = (__ENV.SCENARIO || '').toLowerCase(); // 'baseline', 'normal', 'moderate', 'heavy', 'stress'

// Scenario definitions
const scenarioConfigs = {
  baseline: {
    executor: 'constant-vus',
    vus: 5,
    duration: '20s',
  },
  normal: {
    executor: 'constant-vus',
    vus: 10,
    duration: '20s',
  },
  moderate: {
    executor: 'ramping-vus',
    startVUs: 5,
    stages: [
      { duration: '5s', target: 25 },
      { duration: '20s', target: 25 },
      { duration: '5s', target: 0 },
    ],
  },
  heavy: {
    executor: 'ramping-vus',
    startVUs: 10,
    stages: [
      { duration: '10s', target: 50 },
      { duration: '25s', target: 50 },
      { duration: '10s', target: 0 },
    ],
  },
  stress: {
    executor: 'ramping-vus',
    startVUs: 10,
    stages: [
      { duration: '10s', target: 50 },
      { duration: '15s', target: 100 },
      { duration: '30s', target: 100 },
      { duration: '10s', target: 0 },
    ],
  },
};

export const options = {
  thresholds: {
    // 95% of file uploads must complete within 4 seconds (accounts for network/storage latency)
    'upload_duration_ms': ['p(95)<4000'],
    // At least 98% of uploads must succeed
    'upload_success_rate': ['rate>=0.98'],
    // General HTTP failure rate under 2%
    'http_req_failed': ['rate<0.02'],
  },
  scenarios: SCENARIO && scenarioConfigs[SCENARIO] 
    ? { [SCENARIO]: scenarioConfigs[SCENARIO] } 
    : undefined,
};

// Setup runs once before virtual users start
export function setup() {
  let authToken = null;
  let shopId = null;

  // Retrieve an active shop_id for full flow order creation
  try {
    const shopRes = http.get(`${BASE_URL}/api/public/shops`);
    if (shopRes.status === 200) {
      const shops = JSON.parse(shopRes.body);
      if (Array.isArray(shops) && shops.length > 0) {
        shopId = shops[0].shop_id;
      }
    }
  } catch (err) {
    console.warn('Could not pre-fetch shop_id:', err);
  }

  // If testing authenticated upload, obtain JWT
  if (AUTH_MODE === 'auth') {
    const email = __ENV.TEST_USER_EMAIL || `loadtest_${Date.now()}@example.com`;
    const password = __ENV.TEST_USER_PASSWORD || 'LoadTestPass123!';

    // Try login first
    let loginRes = http.post(
      `${BASE_URL}/api/auth/login`,
      JSON.stringify({ email, password }),
      { headers: { 'Content-Type': 'application/json' } }
    );

    if (loginRes.status === 200) {
      authToken = JSON.parse(loginRes.body).token;
    } else {
      // If login fails, register a new load-test customer user
      const regRes = http.post(
        `${BASE_URL}/api/auth/register`,
        JSON.stringify({
          email,
          password,
          full_name: 'Load Test Runner',
          phone: '9876543210',
        }),
        { headers: { 'Content-Type': 'application/json' } }
      );
      if (regRes.status === 201) {
        authToken = JSON.parse(regRes.body).token;
      } else {
        console.error('Failed to obtain auth token. Status:', regRes.status, regRes.body);
      }
    }
  }

  return { authToken, shopId };
}

export default function (data) {
  const selectedFile = fileMap[FILE_SIZE_KEY] || fileMap['100k'];
  const isAuth = AUTH_MODE === 'auth' && data.authToken;
  const endpoint = isAuth ? `${BASE_URL}/api/upload` : `${BASE_URL}/api/upload/guest`;

  const headers = {};
  if (isAuth) {
    headers['Authorization'] = `Bearer ${data.authToken}`;
  }

  // Construct multipart/form-data payload with the exact field name 'file'
  const payload = {
    file: http.file(selectedFile.data, selectedFile.name, 'application/pdf'),
  };

  const startTime = Date.now();
  const res = http.post(endpoint, payload, {
    headers,
    timeout: '30s', // Avoid hanging indefinitely under heavy concurrency
  });
  const duration = Date.now() - startTime;
  uploadDuration.add(duration);

  let uploadSuccess = false;
  let uploadedFile = null;

  if (res.status === 201) {
    try {
      const body = JSON.parse(res.body);
      if (body && body.file && body.file.s3_key && body.file.public_id) {
        uploadSuccess = true;
        uploadedFile = body.file;
        uploadSizeBytes.add(uploadedFile.size || selectedFile.size);
      }
    } catch (_) {
      uploadSuccess = false;
    }
  }

  uploadSuccessRate.add(uploadSuccess);
  if (!uploadSuccess) {
    failedUploads.add(1);
  }

  check(res, {
    'upload returns HTTP 201': (r) => r.status === 201,
    'response has file metadata': () => uploadSuccess === true,
    'response matches uploaded format': () => uploadedFile && uploadedFile.format === 'pdf',
  });

  // Optional Complete Workflow: Create Order after Uploading
  if (CREATE_ORDER && uploadSuccess && data.shopId) {
    const orderEndpoint = isAuth ? `${BASE_URL}/api/orders` : `${BASE_URL}/api/orders/guest`;
    const orderPayload = {
      shop_id: data.shopId,
      files: [
        {
          original_name: uploadedFile.original_name,
          format: uploadedFile.format,
          size: uploadedFile.size,
          s3_key: uploadedFile.s3_key,
          public_id: uploadedFile.public_id,
          print_options: {
            color: 'bw',
            pages: 1,
            copies: 1,
            sides: 'single',
            size: 'A4',
          },
        },
      ],
      print_options: { pickup_type: 'express' },
      amount_total: 10,
    };

    const orderRes = http.post(orderEndpoint, JSON.stringify(orderPayload), {
      headers: {
        'Content-Type': 'application/json',
        ...(isAuth ? { 'Authorization': `Bearer ${data.authToken}` } : {}),
      },
    });

    const orderOk = check(orderRes, {
      'order creation status is 201': (r) => r.status === 201,
      'order returned valid order_id': (r) => {
        try {
          return !!JSON.parse(r.body).order?.order_id;
        } catch (_) {
          return false;
        }
      },
    });
    orderCreationSuccessRate.add(orderOk);
  }

  // Realistic user pacing between upload actions (0.5s - 1.5s)
  sleep(0.5 + Math.random());
}
