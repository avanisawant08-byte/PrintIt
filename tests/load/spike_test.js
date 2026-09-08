import http from 'k6/http';
import { check, sleep } from 'k6';
import { Rate, Trend, Counter } from 'k6/metrics';

export const spikeUploadSuccessRate = new Rate('spike_upload_success_rate');
export const spikeUploadDuration = new Trend('spike_upload_duration_ms', true);
export const spikeFailedCount = new Counter('spike_failed_uploads_total');

// Preload 100KB realistic PDF test asset
const testPdf = open('./assets/test_100k.pdf', 'b');

const BASE_URL = __ENV.BASE_URL || 'http://127.0.0.1:3000';

export const options = {
  scenarios: {
    upload_spike: {
      executor: 'ramping-vus',
      startVUs: 0,
      stages: [
        { duration: '5s', target: 10 },   // Fast ramp to 10 VUs
        { duration: '5s', target: 25 },   // Ramp to 25 VUs
        { duration: '10s', target: 50 },  // Ramp to 50 VUs
        { duration: '10s', target: 100 }, // Spike to 100 VUs!
        { duration: '20s', target: 100 }, // Hold high load at 100 VUs
        { duration: '10s', target: 10 },  // Quick drop down to 10 VUs
        { duration: '10s', target: 0 },   // Cool down to 0 (recovery observation)
      ],
    },
  },
  thresholds: {
    'http_req_duration': ['p(95)<5000'], // Under extreme 100-user spike, p95 under 5s
    'spike_upload_success_rate': ['rate>=0.95'], // Tolerate at most 5% failure during spike
  },
};

export default function () {
  const payload = {
    file: http.file(testPdf, 'spike_test_100k.pdf', 'application/pdf'),
  };

  const start = Date.now();
  const res = http.post(`${BASE_URL}/api/upload/guest`, payload, {
    timeout: '25s',
  });
  const elapsed = Date.now() - start;
  spikeUploadDuration.add(elapsed);

  const isSuccess = res.status === 201;
  spikeUploadSuccessRate.add(isSuccess);

  if (!isSuccess) {
    spikeFailedCount.add(1);
  }

  check(res, {
    'spike response is HTTP 201': (r) => r.status === 201,
    'returned valid s3_key': (r) => {
      try {
        return !!JSON.parse(r.body).file?.s3_key;
      } catch (_) {
        return false;
      }
    },
  });

  // Short user think time during spike
  sleep(0.3 + Math.random() * 0.7);
}
