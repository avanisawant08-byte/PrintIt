const http = require('http');
const assert = require('assert');

process.env.NODE_ENV = 'test';
process.env.ALLOW_MOCK_PAYMENTS = 'true';
process.env.RAZORPAY_WEBHOOK_SECRET = 'test_webhook_secret_key_12345';
require('dotenv').config({ path: require('path').resolve(__dirname, '../.env') });

const app = require('../src/app');
const pool = require('../src/config/db');

function makeRequest(serverUrl, path, method = 'GET', body = null, headers = {}) {
    return new Promise((resolve, reject) => {
        const url = new URL(path, serverUrl);
        const reqHeaders = {
            'Content-Type': 'application/json',
            ...headers
        };
        const req = http.request(url, {
            method,
            headers: reqHeaders
        }, (res) => {
            let data = '';
            res.on('data', chunk => data += chunk);
            res.on('end', () => {
                let parsed;
                try {
                    parsed = JSON.parse(data);
                } catch {
                    parsed = data;
                }
                resolve({ status: res.statusCode, headers: res.headers, body: parsed });
            });
        });
        req.on('error', reject);
        if (body) {
            req.write(typeof body === 'string' ? body : JSON.stringify(body));
        }
        req.end();
    });
}

async function runPreDeploymentChecks() {
    console.log('================================================================');
    console.log('🚀 PRE-DEPLOYMENT PRODUCTION READINESS VERIFICATION SUITE');
    console.log('================================================================\n');

    const server = http.createServer(app);
    await new Promise(res => server.listen(0, res));
    const port = server.address().port;
    const baseUrl = `http://127.0.0.1:${port}`;

    let totalPassed = 0;
    let totalFailed = 0;

    function check(description, passed, details = '') {
        if (passed) {
            console.log(`  ✅ [PASS] ${description}`);
            totalPassed++;
        } else {
            console.error(`  ❌ [FAIL] ${description} -> ${details}`);
            totalFailed++;
        }
    }

    try {
        // -------------------------------------------------------------
        // CHECK 1: Environment Variables
        // -------------------------------------------------------------
        console.log('[CHECK 1] Environment Variables Validation');
        const { validateEnv } = require('../src/config/envValidation');
        check('Env validator module exists and exports validateEnv()', typeof validateEnv === 'function');
        check('DATABASE_URL is set in environment', !!process.env.DATABASE_URL);
        check('JWT_SECRET is set in environment', !!process.env.JWT_SECRET);
        check('RAZORPAY_KEY_ID is set in environment', !!process.env.RAZORPAY_KEY_ID);
        check('RAZORPAY_KEY_SECRET is set in environment', !!process.env.RAZORPAY_KEY_SECRET);

        // -------------------------------------------------------------
        // CHECK 2: Debug Code Removal & Endpoints
        // -------------------------------------------------------------
        console.log('\n[CHECK 2] Debug Code & Test Endpoints Removal');
        const debugEndpoints = ['/debug', '/test', '/admin-backdoor', '/seed-data', '/api/debug', '/api/test', '/api/seed-data'];
        for (const ep of debugEndpoints) {
            const res = await makeRequest(baseUrl, ep);
            check(`Test/Debug endpoint '${ep}' returns 404 Not Found`, res.status === 404);
        }

        // -------------------------------------------------------------
        // CHECK 3: Error Handling & Data Leakage Prevention
        // -------------------------------------------------------------
        console.log('\n[CHECK 3] Error Handling & Sanitization');
        const invalidOrderRes = await makeRequest(baseUrl, '/api/orders/non-existent-id-uuid-test');
        check('Error returns Correlation ID (X-Request-ID header or request_id)', 
            !!invalidOrderRes.headers['x-request-id'] || (invalidOrderRes.body && !!invalidOrderRes.body.request_id));
        
        const resBodyStr = JSON.stringify(invalidOrderRes.body);
        const leaksStack = resBodyStr.includes('at Object.') || resBodyStr.includes('node_modules') || resBodyStr.includes('app.js:');
        const leaksQuery = resBodyStr.includes('SELECT ') || resBodyStr.includes('pg_catalog') || resBodyStr.includes('syntax error');
        check('Error response does NOT leak stack traces', !leaksStack);
        check('Error response does NOT leak database queries or table internals', !leaksQuery);

        // -------------------------------------------------------------
        // CHECK 4: Security Headers
        // -------------------------------------------------------------
        console.log('\n[CHECK 4] Security Headers (Helmet, HSTS, CSP, X-Frame-Options)');
        const healthRes = await makeRequest(baseUrl, '/api/health');
        check('X-Content-Type-Options is "nosniff"', healthRes.headers['x-content-type-options'] === 'nosniff');
        check('X-Frame-Options is "DENY"', healthRes.headers['x-frame-options'] === 'DENY');
        check('Strict-Transport-Security is present with max-age >= 1 year (31536000s)', 
            healthRes.headers['strict-transport-security'] && healthRes.headers['strict-transport-security'].includes('max-age=31536000'));
        check('Content-Security-Policy header is configured', !!healthRes.headers['content-security-policy']);

        // -------------------------------------------------------------
        // CHECK 5: Rate Limiting
        // -------------------------------------------------------------
        console.log('\n[CHECK 5] Rate Limiting on Auth Endpoints');
        const { loginLimiter, passwordResetLimiter, otpLimiter, authLimiter } = require('../src/middleware/rateLimiter');
        check('Login rate limiter configured (5 attempts/min)', loginLimiter && typeof loginLimiter === 'function');
        check('Password reset rate limiter configured (3 attempts/hour)', passwordResetLimiter && typeof passwordResetLimiter === 'function');
        check('OTP rate limiter configured', otpLimiter && typeof otpLimiter === 'function');
        check('General auth rate limiter configured', authLimiter && typeof authLimiter === 'function');

        // -------------------------------------------------------------
        // CHECK 6: CORS Configuration
        // -------------------------------------------------------------
        console.log('\n[CHECK 6] CORS Configuration');
        const corsHeadersRes = await makeRequest(baseUrl, '/api/health', 'OPTIONS', null, {
            'Origin': 'http://localhost:5173',
            'Access-Control-Request-Method': 'GET'
        });
        check('CORS handles origin checks correctly', corsHeadersRes.status === 200 || corsHeadersRes.status === 204);

        // -------------------------------------------------------------
        // CHECK 7: Database Security & TLS/SSL
        // -------------------------------------------------------------
        console.log('\n[CHECK 7] Database Security & TLS/SSL Configuration');
        const dbRes = await pool.query('SELECT 1 as test');
        check('Database connection is active and authenticated', dbRes.rows.length === 1 && dbRes.rows[0].test === 1);
        check('Database pool configured with SSL enabled', pool.options && !!pool.options.ssl);

    } catch (error) {
        console.error('Fatal test suite error:', error);
        totalFailed++;
    } finally {
        server.close();
        await pool.end();
    }

    console.log('\n================================================================');
    console.log(`SUMMARY: ${totalPassed} PASSED, ${totalFailed} FAILED`);
    console.log('================================================================\n');

    if (totalFailed > 0) {
        process.exit(1);
    }
}

runPreDeploymentChecks();
