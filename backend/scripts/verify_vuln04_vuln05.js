require('dotenv').config();
const http = require('http');
const pool = require('../src/config/db');
const app = require('../src/app');

function makeRequest(serverUrl, path, method = 'GET', body = null) {
    return new Promise((resolve, reject) => {
        const url = new URL(path, serverUrl);
        const req = http.request(url, {
            method,
            headers: {
                'Content-Type': 'application/json'
            }
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
                resolve({ status: res.statusCode, body: parsed });
            });
        });
        req.on('error', reject);
        if (body) {
            req.write(JSON.stringify(body));
        }
        req.end();
    });
}

async function runTests() {
    console.log('--- STARTING VULN-04 & VULN-05 VERIFICATION TESTS ---');
    const server = http.createServer(app);
    await new Promise(res => server.listen(0, res));
    const port = server.address().port;
    const baseUrl = `http://127.0.0.1:${port}`;
    console.log(`Test server running at ${baseUrl}`);

    const client = await pool.connect();
    try {
        // Find or create test shop
        const shopRes = await client.query('SELECT shop_id FROM shops LIMIT 1');
        if (shopRes.rows.length === 0) {
            throw new Error('No shops found in database');
        }
        const shopId = shopRes.rows[0].shop_id;

        // 1. Create a guest order directly in DB with sensitive file URLs & cancel_token
        const testGuestOrderId = 'TEST-GUEST-' + Date.now();
        const testCancelToken = 'secret_guest_token_12345';
        const sensitiveFiles = [
            {
                original_name: 'confidential_exam.pdf',
                format: 'pdf',
                size: 1048576,
                url: 'https://storage.googleapis.com/printit-bucket/secret_orders/confidential_exam.pdf',
                s3_key: 'secret_orders/confidential_exam.pdf',
                public_id: 'cloud_storage_confidential_id'
            }
        ];

        await client.query(
            `INSERT INTO orders (
                order_id, customer_id, shop_id, files, print_options, status, queue_position, amount_total, payment_status, cancel_token
            ) VALUES ($1, NULL, $2, $3, $4, 'queued', 1, 10, 'captured', $5)`,
            [
                testGuestOrderId,
                shopId,
                JSON.stringify(sensitiveFiles),
                JSON.stringify({ pickup_type: 'express' }),
                testCancelToken
            ]
        );

        console.log('\n[TEST 1: VULN-05 PII / Document URL Stripping]');
        const getRes = await makeRequest(baseUrl, `/api/public/orders/${testGuestOrderId}`);
        console.log('GET /api/public/orders/:id status:', getRes.status);
        console.log('GET response files:', JSON.stringify(getRes.body.files));

        const returnedFiles = getRes.body.files || [];
        const hasUrl = JSON.stringify(returnedFiles).includes('https://storage.googleapis.com');
        const hasS3Key = JSON.stringify(returnedFiles).includes('secret_orders');
        const hasPublicId = JSON.stringify(returnedFiles).includes('cloud_storage_confidential_id');

        if (!hasUrl && !hasS3Key && !hasPublicId && returnedFiles[0].original_name === 'confidential_exam.pdf') {
            console.log('✅ PASS: VULN-05 Verified! File storage URLs and keys are properly sanitized from public tracking.');
        } else {
            console.error('❌ FAIL: Sensitive storage URL leaked in public tracking response!');
            process.exitCode = 1;
        }

        console.log('\n[TEST 2: VULN-04 Unauthorized Cancel Attempt without Token]');
        const cancelNoToken = await makeRequest(baseUrl, `/api/public/orders/${testGuestOrderId}/cancel`, 'PATCH', {});
        console.log('No token cancel status:', cancelNoToken.status, cancelNoToken.body);
        if (cancelNoToken.status === 401) {
            console.log('✅ PASS: Cancellation without token correctly rejected with HTTP 401.');
        } else {
            console.error('❌ FAIL: Expected HTTP 401, got', cancelNoToken.status);
            process.exitCode = 1;
        }

        console.log('\n[TEST 3: VULN-04 Unauthorized Cancel Attempt with Invalid Token]');
        const cancelWrongToken = await makeRequest(baseUrl, `/api/public/orders/${testGuestOrderId}/cancel`, 'PATCH', { cancel_token: 'attacker_guessed_wrong_token' });
        console.log('Wrong token cancel status:', cancelWrongToken.status, cancelWrongToken.body);
        if (cancelWrongToken.status === 403) {
            console.log('✅ PASS: Cancellation with invalid token correctly rejected with HTTP 403.');
        } else {
            console.error('❌ FAIL: Expected HTTP 403, got', cancelWrongToken.status);
            process.exitCode = 1;
        }

        console.log('\n[TEST 4: VULN-04 Authorized Guest Cancel with Valid Token]');
        const cancelValidToken = await makeRequest(baseUrl, `/api/public/orders/${testGuestOrderId}/cancel`, 'PATCH', { cancel_token: testCancelToken });
        console.log('Valid token cancel status:', cancelValidToken.status, cancelValidToken.body.message);
        if (cancelValidToken.status === 200) {
            console.log('✅ PASS: Cancellation with valid token succeeded!');
        } else {
            console.error('❌ FAIL: Expected HTTP 200, got', cancelValidToken.status);
            process.exitCode = 1;
        }

        console.log('\n[TEST 5: VULN-04 Attempt to Cancel Authenticated Order via Public Cancel Endpoint]');
        // Insert order with customer_id set
        const testAuthOrderId = 'TEST-AUTH-' + Date.now();
        const custRes = await client.query("SELECT user_id FROM users WHERE role = 'customer' LIMIT 1");
        const custId = custRes.rows.length > 0 ? custRes.rows[0].user_id : null;
        if (custId) {
            await client.query(
                `INSERT INTO orders (
                    order_id, customer_id, shop_id, files, print_options, status, queue_position, amount_total, payment_status, cancel_token
                ) VALUES ($1, $2, $3, $4, $5, 'queued', 1, 10, 'captured', $6)`,
                [testAuthOrderId, custId, shopId, JSON.stringify(sensitiveFiles), JSON.stringify({}), 'any_token']
            );
            const cancelAuthOrder = await makeRequest(baseUrl, `/api/public/orders/${testAuthOrderId}/cancel`, 'PATCH', { cancel_token: 'any_token' });
            console.log('Auth order cancel via public endpoint status:', cancelAuthOrder.status, cancelAuthOrder.body);
            if (cancelAuthOrder.status === 403) {
                console.log('✅ PASS: Authenticated order cannot be cancelled via public guest endpoint.');
            } else {
                console.error('❌ FAIL: Expected HTTP 403 for authenticated order cancellation via public endpoint, got', cancelAuthOrder.status);
                process.exitCode = 1;
            }
            // Cleanup
            await client.query('DELETE FROM orders WHERE order_id = $1', [testAuthOrderId]);
        }

        // Cleanup
        await client.query('DELETE FROM orders WHERE order_id = $1', [testGuestOrderId]);

    } finally {
        client.release();
        server.close();
        await pool.end();
    }
}

runTests().catch(err => {
    console.error('Test error:', err);
    process.exit(1);
});
