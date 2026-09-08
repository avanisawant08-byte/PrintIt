import http from 'k6/http';
import { check, sleep } from 'k6';
import { Rate } from 'k6/metrics';

// Custom metric: failure rate
export const errorRate = new Rate('errors');

export const options = {
  thresholds: {
    // Stop / fail if error rate is greater than 1%
    'errors': ['rate<0.01'],
    // 95% of requests must complete below 1.5 seconds
    'http_req_duration': ['p(95)<1500'],
  },
};

const BASE_URL = __ENV.TARGET_URL || 'http://127.0.0.1:3000';

export default function () {
  // 1. Health check
  const resHealth = http.get(`${BASE_URL}/api/health`);
  const checkHealth = check(resHealth, {
    'health status is 200': (r) => r.status === 200,
  });
  errorRate.add(!checkHealth);

  sleep(0.1);

  // 2. Public capabilities
  const resCap = http.get(`${BASE_URL}/api/public/capabilities`);
  const checkCap = check(resCap, {
    'capabilities status is 200': (r) => r.status === 200,
  });
  errorRate.add(!checkCap);

  sleep(0.1);

  // 3. Public shops listing
  const resShops = http.get(`${BASE_URL}/api/public/shops`);
  let shopId = null;
  const checkShops = check(resShops, {
    'shops status is 200': (r) => r.status === 200,
    'shops returned valid JSON': (r) => {
      try {
        const body = JSON.parse(r.body);
        if (Array.isArray(body) && body.length > 0) {
          shopId = body[0].shop_id;
        }
        return Array.isArray(body);
      } catch (_) {
        return false;
      }
    },
  });
  errorRate.add(!checkShops);

  sleep(0.1);

  // 4. Products catalog listing
  const resProducts = http.get(`${BASE_URL}/api/products`);
  const checkProducts = check(resProducts, {
    'products status is 200': (r) => r.status === 200,
  });
  errorRate.add(!checkProducts);

  sleep(0.1);

  // 5. Individual shop detail
  if (shopId) {
    const resShopDetail = http.get(`${BASE_URL}/api/public/shops/${shopId}`);
    const checkDetail = check(resShopDetail, {
      'shop detail status is 200': (r) => r.status === 200,
    });
    errorRate.add(!checkDetail);
  }

  sleep(0.2);
}
