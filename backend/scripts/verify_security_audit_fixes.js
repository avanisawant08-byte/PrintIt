process.env.NODE_ENV = 'test';
process.env.ALLOW_MOCK_PAYMENTS = 'true';
process.env.RAZORPAY_WEBHOOK_SECRET = 'test_webhook_secret_key_12345';
require('dotenv').config({ path: require('path').resolve(__dirname, '../.env') });
const http = require('http');
const crypto = require('crypto');
const jwt = require('jsonwebtoken');
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
            req.write(typeof body === 'string' ? body : JSON.stringify(body));
        }
        req.end();
    });
}

async function runAuditTests() {
    console.log('====================================================');
    console.log('--- RUNNING SECURITY VULNERABILITY FIXES AUDIT ---');
    console.log('====================================================\n');

    const server = http.createServer(app);
    await new Promise(res => server.listen(0, res));
    const port = server.address().port;
    const baseUrl = `http://127.0.0.1:${port}`;

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

    const client = await pool.connect();

    try {
        // Setup mock customer and shopkeeper
        const customerRes = await client.query(`SELECT user_id, email, role FROM users WHERE role = 'customer' LIMIT 1`);
        const customer = customerRes.rows[0];
        const customerToken = jwt.sign(
            { user_id: customer.user_id, email: customer.email, role: 'customer' },
            process.env.JWT_SECRET,
            { expiresIn: '1h' }
        );

        const shopRes = await client.query(`SELECT s.shop_id, s.owner_id, u.email FROM shops s JOIN users u ON s.owner_id = u.user_id LIMIT 1`);
        const shop = shopRes.rows[0];
        const shopkeeperToken = jwt.sign(
            { user_id: shop.owner_id, email: shop.email, role: 'shopkeeper' },
            process.env.JWT_SECRET,
            { expiresIn: '1h' }
        );

        // ----------------------------------------------------
        // TEST 1: VULN-01 Product Order Price Tampering
        // ----------------------------------------------------
        console.log('\n[TEST 1] VULN-01: Product Order Price Tampering & Wallet Refund Check');
        const prodRes = await client.query(`SELECT product_id, price FROM products WHERE is_active = true LIMIT 1`);
        if (prodRes.rows.length > 0) {
            const prod = prodRes.rows[0];
            const realPrice = parseFloat(prod.price);
            const fakeHighAmount = 99999;
            const mockPayId = 'pay_tamper_test_' + Date.now();

            await client.query(
                `INSERT INTO payments (razorpay_order_id, razorpay_payment_id, status, amount)
                 VALUES ($1, $2, 'captured', $3)`,
                ['order_' + Date.now(), mockPayId, realPrice]
            );

            // Customer attempts to place product order sending inflated amount_total: 99999
            const orderRes = await makeRequest(baseUrl, '/api/product-orders', 'POST', {
                product_id: prod.product_id,
                quantity: 1,
                amount_total: fakeHighAmount,
                payment_id: mockPayId
            }, { 'Authorization': `Bearer ${customerToken}` });

            assert('Product order created with HTTP 201', orderRes.status === 201, `Status: ${orderRes.status}`);
            if (orderRes.body && orderRes.body.order) {
                const recordedAmount = parseFloat(orderRes.body.order.amount_total);
                assert('Recorded order amount uses server expected price, ignoring client spoof', recordedAmount === realPrice, `Recorded amount: ₹${recordedAmount}, Expected: ₹${realPrice}`);
                
                // Cleanup test order
                await client.query('DELETE FROM product_orders WHERE order_id = $1', [orderRes.body.order.order_id]);
            }
            await client.query('DELETE FROM payments WHERE razorpay_payment_id = $1', [mockPayId]);
        } else {
            console.log('⚠️ Skipping Product Order test (no active products in DB)');
        }

        // ----------------------------------------------------
        // TEST 2: VULN-02 Support Ticket Status Modification IDOR
        // ----------------------------------------------------
        console.log('\n[TEST 2] VULN-02: Support Ticket Status Modification IDOR');
        const testToken = 'SUP-T-' + Date.now().toString().slice(-8);
        const ticketRes = await client.query(
            `INSERT INTO support_tickets (ticket_token, user_id, shop_id, subject, description, status)
             VALUES ($1, $2, $3, 'Test Ticket', 'Test Desc', 'open') RETURNING ticket_id`,
            [testToken, customer.user_id, shop.shop_id]
        );
        const testTicketId = ticketRes.rows[0].ticket_id;

        // Customer attempts to change ticket status to resolved -> MUST BE FORBIDDEN (403)
        const custAttempt = await makeRequest(baseUrl, `/api/support/tickets/${testTicketId}/status`, 'PATCH', {
            status: 'resolved'
        }, { 'Authorization': `Bearer ${customerToken}` });
        assert('Customer forbidden from changing ticket status (HTTP 403)', custAttempt.status === 403, `Got HTTP ${custAttempt.status}`);

        // Shopkeeper assigned to shop changes status -> ALLOWED (200)
        const shopAttempt = await makeRequest(baseUrl, `/api/support/tickets/${testTicketId}/status`, 'PATCH', {
            status: 'in_progress'
        }, { 'Authorization': `Bearer ${shopkeeperToken}` });
        assert('Assigned shopkeeper allowed to update status (HTTP 200)', shopAttempt.status === 200, `Got HTTP ${shopAttempt.status}`);

        // Cleanup
        await client.query('DELETE FROM support_tickets WHERE ticket_id = $1', [testTicketId]);

        // ----------------------------------------------------
        // TEST 3: VULN-03 Unpaid Guest Order Queue Injection
        // ----------------------------------------------------
        console.log('\n[TEST 3] VULN-03: Unpaid Guest Order Queue Injection');
        const unpaidGuestRes = await makeRequest(baseUrl, '/api/orders/guest', 'POST', {
            customer_id: '00000000-0000-0000-0000-000000000000',
            shop_id: shop.shop_id,
            files: [{ s3_key: 'https://storage/test.pdf', page_count: 1 }],
            print_options: { color: 'bw', size: 'A4', sides: 'single', copies: 1, binding: 'none' },
            amount_total: 10
            // No payment_id provided
        });
        assert('Unpaid guest order rejected (HTTP 400)', unpaidGuestRes.status === 400, `Got HTTP ${unpaidGuestRes.status}`);

        // ----------------------------------------------------
        // TEST 4: VULN-04 Password Reset & JWT Token Blacklist
        // ----------------------------------------------------
        console.log('\n[TEST 4] VULN-04: Password Reset & JWT Logout Blacklist');
        
        // 4a. Password reset generation
        const resetReq = await makeRequest(baseUrl, '/api/auth/reset-password', 'POST', {
            email: customer.email
        });
        assert('Password reset request accepted (HTTP 200)', resetReq.status === 200, `Status: ${resetReq.status}`);
        const resetToken = resetReq.body.reset_token;

        if (resetToken) {
            // 4b. Confirm password reset
            const confirmReq = await makeRequest(baseUrl, '/api/auth/reset-password/confirm', 'POST', {
                token: resetToken,
                new_password: 'NewSecurePassword123!'
            });
            assert('Password reset confirmation succeeded (HTTP 200)', confirmReq.status === 200, `Status: ${confirmReq.status}`);

            // 4c. Attempt replay with same single-use token -> MUST FAIL (400)
            const replayReq = await makeRequest(baseUrl, '/api/auth/reset-password/confirm', 'POST', {
                token: resetToken,
                new_password: 'AnotherPassword123!'
            });
            assert('Replay of single-use reset token rejected (HTTP 400)', replayReq.status === 400, `Status: ${replayReq.status}`);
        }

        // 4d. Logout token blacklist
        const tempToken = jwt.sign(
            { user_id: customer.user_id, email: customer.email, role: 'customer' },
            process.env.JWT_SECRET,
            { expiresIn: '1h' }
        );
        // Verify valid before logout
        const meBefore = await makeRequest(baseUrl, '/api/auth/me', 'GET', null, { 'Authorization': `Bearer ${tempToken}` });
        assert('Token valid prior to logout (HTTP 200)', meBefore.status === 200, `Status: ${meBefore.status}`);

        // Logout
        const logoutRes = await makeRequest(baseUrl, '/api/auth/logout', 'POST', null, { 'Authorization': `Bearer ${tempToken}` });
        assert('Logout succeeded (HTTP 200)', logoutRes.status === 200, `Status: ${logoutRes.status}`);

        // Verify token rejected after logout
        const meAfter = await makeRequest(baseUrl, '/api/auth/me', 'GET', null, { 'Authorization': `Bearer ${tempToken}` });
        assert('Blacklisted token rejected after logout (HTTP 401)', meAfter.status === 401, `Status: ${meAfter.status}`);

        // ----------------------------------------------------
        // TEST 5: VULN-05 Razorpay Webhook Signature Verification
        // ----------------------------------------------------
        console.log('\n[TEST 5] VULN-05: Razorpay Webhook HMAC SHA-256 Verification');
        const webhookPayload = JSON.stringify({
            event: 'payment.captured',
            payload: {
                payment: {
                    entity: {
                        id: 'pay_hook_test_' + Date.now(),
                        order_id: 'order_hook_' + Date.now(),
                        amount: 5000 // 50.00 INR in paise
                    }
                }
            }
        });

        const validSig = crypto
            .createHmac('sha256', process.env.RAZORPAY_WEBHOOK_SECRET)
            .update(webhookPayload)
            .digest('hex');

        // Valid webhook request
        const validWebhookRes = await makeRequest(baseUrl, '/api/payments/webhook', 'POST', webhookPayload, {
            'x-razorpay-signature': validSig,
            'Content-Type': 'application/json'
        });
        assert('Valid webhook HMAC accepted (HTTP 200)', validWebhookRes.status === 200, `Status: ${validWebhookRes.status}`);

        // Invalid signature request
        const invalidWebhookRes = await makeRequest(baseUrl, '/api/payments/webhook', 'POST', webhookPayload, {
            'x-razorpay-signature': 'invalid_forged_signature_hex_1234567890abcdef1234567890abcdef12345678',
            'Content-Type': 'application/json'
        });
        assert('Forged webhook HMAC rejected (HTTP 400)', invalidWebhookRes.status === 400, `Status: ${invalidWebhookRes.status}`);

    } finally {
        client.release();
        server.close();
    }

    console.log('\n====================================================');
    console.log(`AUDIT RESULTS: ${passedCount} PASSED, ${failedCount} FAILED`);
    console.log('====================================================');

    if (failedCount > 0) {
        process.exit(1);
    } else {
        process.exit(0);
    }
}

runAuditTests().catch(err => {
    console.error('Audit execution error:', err);
    process.exit(1);
});
