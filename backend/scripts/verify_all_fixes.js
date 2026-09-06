process.env.NODE_ENV = 'test';
process.env.ALLOW_MOCK_PAYMENTS = 'true';
require('dotenv').config();
const http = require('http');
const pool = require('../src/config/db');
const app = require('../src/app');

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
            req.write(JSON.stringify(body));
        }
        req.end();
    });
}

async function runAllVerifications() {
    console.log('====================================================');
    console.log('--- COMPREHENSIVE SECURITY VULNERABILITY AUDIT ---');
    console.log('====================================================');

    const server = http.createServer(app);
    await new Promise(res => server.listen(0, res));
    const port = server.address().port;
    const baseUrl = `http://127.0.0.1:${port}`;
    console.log(`Server launched on ${baseUrl}\n`);

    const client = await pool.connect();
    let passedCount = 0;
    let failedCount = 0;

    function assert(name, condition, detail = '') {
        if (condition) {
            console.log(`✅ PASS: ${name}`);
            passedCount++;
        } else {
            console.error(`❌ FAIL: ${name} — ${detail}`);
            failedCount++;
        }
    }

    try {
        // 1. VULN-01: Payment Replay / Double Spending Protection
        console.log('--> Checking Payment Replay & Double Spending Protection (VULN-01)...');
        const shopRes = await client.query('SELECT shop_id FROM shops LIMIT 1');
        const shopId = shopRes.rows[0].shop_id;

        // Insert a dummy used payment
        const usedPaymentId = 'pay_replay_test_' + Date.now();
        await client.query(
            `INSERT INTO payments (razorpay_order_id, razorpay_payment_id, status, amount)
             VALUES ($1, $2, 'captured', 50)`,
            ['order_' + Date.now(), usedPaymentId]
        );
        // Link to an existing order
        const replayOrderId = 'ORD-REPLAY-' + Date.now();
        await client.query(
            `INSERT INTO orders (order_id, shop_id, files, print_options, status, queue_position, amount_total, payment_status, payment_id)
             VALUES ($1, $2, '[]', '{}', 'queued', 1, 50, 'captured', $3)`,
            [replayOrderId, shopId, usedPaymentId]
        );

        // Attempt guest verify with this already used payment
        process.env.ALLOW_MOCK_PAYMENTS = 'true';
        const replayRes = await makeRequest(baseUrl, '/api/payments/guest/verify', 'POST', {
            razorpay_order_id: 'order_test',
            razorpay_payment_id: usedPaymentId,
            razorpay_signature: 'mock_signature',
            shop_id: shopId,
            files: [{ original_name: 'test.pdf', format: 'pdf', size: 100, print_options: { color: 'bw', pages: 1, copies: 1 } }],
            amount_total: 50
        });
        assert('Payment replay rejection (HTTP 409)', replayRes.status === 409, `Got HTTP ${replayRes.status}`);

        // Cleanup
        await client.query('DELETE FROM orders WHERE order_id = $1', [replayOrderId]);
        await client.query('DELETE FROM payments WHERE razorpay_payment_id = $1', [usedPaymentId]);

        // 2. VULN-03: Client-side Price Manipulation Rejection
        console.log('\n--> Checking Server-Side Pricing Validation (VULN-03)...');
        const priceHackRes = await makeRequest(baseUrl, '/api/payments/guest/verify', 'POST', {
            razorpay_order_id: 'order_fake',
            razorpay_payment_id: 'pay_underpaid_' + Date.now(),
            razorpay_signature: 'mock_signature',
            shop_id: shopId,
            files: [{ original_name: 'big_book.pdf', format: 'pdf', size: 500, print_options: { color: 'bw', pages: 100, copies: 1 } }],
            amount_total: 1 // Underpaying drastically
        });
        assert('Underpayment rejection (HTTP 400)', priceHackRes.status === 400, `Got HTTP ${priceHackRes.status}: ${JSON.stringify(priceHackRes.body)}`);

        // 3. VULN-04: Guest Order Cancellation Protection
        console.log('\n--> Checking Guest Order Cancellation Protection (VULN-04)...');
        const testGuestOrd = 'ORD-GUEST-SEC-' + Date.now();
        const testSecretToken = 'super_secret_token_' + Date.now();
        await client.query(
            `INSERT INTO orders (order_id, shop_id, files, print_options, status, queue_position, amount_total, payment_status, cancel_token)
             VALUES ($1, $2, '[]', '{}', 'queued', 1, 10, 'captured', $3)`,
            [testGuestOrd, shopId, testSecretToken]
        );

        const unauthCancel = await makeRequest(baseUrl, `/api/public/orders/${testGuestOrd}/cancel`, 'PATCH', {});
        assert('Cancel without token rejected (HTTP 401)', unauthCancel.status === 401, `Got HTTP ${unauthCancel.status}`);

        const badTokenCancel = await makeRequest(baseUrl, `/api/public/orders/${testGuestOrd}/cancel`, 'PATCH', { cancel_token: 'wrong_token' });
        assert('Cancel with invalid token rejected (HTTP 403)', badTokenCancel.status === 403, `Got HTTP ${badTokenCancel.status}`);

        const validCancel = await makeRequest(baseUrl, `/api/public/orders/${testGuestOrd}/cancel`, 'PATCH', { cancel_token: testSecretToken });
        assert('Cancel with valid token approved (HTTP 200)', validCancel.status === 200, `Got HTTP ${validCancel.status}`);

        // Cleanup
        await client.query('DELETE FROM orders WHERE order_id = $1', [testGuestOrd]);

        // 4. VULN-05: PII / Document Storage URL Stripping in Public Tracking
        console.log('\n--> Checking Document URL Leakage in Public Tracking (VULN-05)...');
        const testLeakOrd = 'ORD-LEAK-TEST-' + Date.now();
        const leakFiles = [{
            original_name: 'private_statement.pdf',
            format: 'pdf',
            size: 2048,
            url: 'https://storage.googleapis.com/secret_url',
            s3_key: 'secret_storage_key_private',
            public_id: 'secret_public_id'
        }];
        await client.query(
            `INSERT INTO orders (order_id, shop_id, files, print_options, status, queue_position, amount_total, payment_status)
             VALUES ($1, $2, $3, '{}', 'queued', 1, 10, 'captured')`,
            [testLeakOrd, shopId, JSON.stringify(leakFiles)]
        );

        const trackingRes = await makeRequest(baseUrl, `/api/public/orders/${testLeakOrd}`);
        const returnedFilesStr = JSON.stringify(trackingRes.body.files || []);
        const leaked = returnedFilesStr.includes('storage.googleapis.com') || returnedFilesStr.includes('secret_storage_key');
        assert('Public tracking strips cloud storage URLs and keys', trackingRes.status === 200 && !leaked, `Returned: ${returnedFilesStr}`);

        // Cleanup
        await client.query('DELETE FROM orders WHERE order_id = $1', [testLeakOrd]);

        // 5. Admin Privilege Escalation on Self-Registration
        console.log('\n--> Checking Admin Privilege Escalation Prevention...');
        const adminRegAttempt = await makeRequest(baseUrl, '/api/auth/register', 'POST', {
            email: 'printitsupport@gmail.com',
            password: 'HackerPassword123!',
            full_name: 'Attacker Impersonator',
            phone: '9999999999'
        });
        assert('Unauthorized admin email registration rejected (HTTP 403)', adminRegAttempt.status === 403, `Got HTTP ${adminRegAttempt.status}`);

        // 6. Internal Stack Trace Disclosure Prevention
        console.log('\n--> Checking Error Stack Trace Leakage Prevention...');
        const loginFail = await makeRequest(baseUrl, '/api/auth/login', 'POST', {
            email: 'nonexistent_user_' + Date.now() + '@test.com',
            password: 'wrongpassword'
        });
        const hasStackInBody = JSON.stringify(loginFail.body).includes('stack') || JSON.stringify(loginFail.body).includes('at Module._compile');
        assert('Login response does not leak stack trace or server internals', !hasStackInBody, `Body: ${JSON.stringify(loginFail.body)}`);

        // 7. Rate Limiter Headers
        console.log('\n--> Checking Rate Limiter Headers...');
        const healthRes = await makeRequest(baseUrl, '/api/health');
        assert('Rate limiting headers present on API routes', healthRes.headers['ratelimit-limit'] !== undefined || healthRes.headers['x-ratelimit-limit'] !== undefined, `Headers: ${JSON.stringify(healthRes.headers)}`);

    } finally {
        client.release();
        server.close();
        await pool.end();
    }

    console.log('\n====================================================');
    console.log(`AUDIT RESULTS: ${passedCount} PASSED, ${failedCount} FAILED`);
    console.log('====================================================');
    if (failedCount > 0) {
        process.exit(1);
    }
}

runAllVerifications().catch(err => {
    console.error('Audit execution error:', err);
    process.exit(1);
});
