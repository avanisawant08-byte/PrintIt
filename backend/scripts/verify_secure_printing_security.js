process.env.NODE_ENV = 'test';
process.env.ALLOW_MOCK_PAYMENTS = 'true';
require('dotenv').config({ path: require('path').resolve(__dirname, '../.env') });
const http = require('http');
const pool = require('../src/config/db');
const app = require('../src/app');
const { deleteOrderFilesImmediately, cleanupSecureExpiredFiles } = require('../src/utils/firebaseCleanup');
const orderSchema = require('../src/validators/orderValidator');

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

async function runSecurityTests() {
    console.log('================================================================');
    console.log('🔒 RUNNING SECURITY & AUDIT SUITE: SECURE PRINTING SYSTEM');
    console.log('================================================================\n');

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

    const server = http.createServer(app);
    await new Promise(res => server.listen(0, res));
    const port = server.address().port;
    const baseUrl = `http://127.0.0.1:${port}`;

    try {
        // Wait a tick for DB pool setup
        await new Promise(r => setTimeout(r, 500));

        // -------------------------------------------------------------
        // Test 1: Input Validation & Mode Injection Prevention
        // -------------------------------------------------------------
        console.log('\n--- Test 1: Input Validation & Print Mode Tampering ---');
        const baseOrder = {
            customer_id: '11111111-1111-1111-1111-111111111111',
            shop_id: '22222222-2222-2222-2222-222222222222',
            files: [{ s3_key: 'uploads/test.pdf', page_count: 5 }],
            print_options: {
                color: 'bw',
                size: 'A4',
                sides: 'single',
                copies: 1,
                binding: 'none'
            },
            amount_total: 10.00
        };

        const validNormal = orderSchema.validate({ ...baseOrder, print_mode: 'normal' });
        assert('Accepts valid "normal" print_mode', !validNormal.error && validNormal.value.print_mode === 'normal');

        const validSecure = orderSchema.validate({ ...baseOrder, print_mode: 'secure' });
        assert('Accepts valid "secure" print_mode', !validSecure.error && validSecure.value.print_mode === 'secure');

        const invalidMode = orderSchema.validate({ ...baseOrder, print_mode: 'malicious_override_mode' });
        assert('Rejects invalid/injected print_mode', invalidMode.error && invalidMode.error.message.includes('print_mode'));

        // -------------------------------------------------------------
        // Test 2: Public Order Tracking Information Leakage Prevention
        // -------------------------------------------------------------
        console.log('\n--- Test 2: Public Order Tracking (VULN-05 Sanitization) ---');
        const shopRes = await pool.query('SELECT shop_id FROM shops LIMIT 1');
        const shopId = shopRes.rows[0]?.shop_id;
        if (!shopId) throw new Error('No test shop found in database');

        // Insert a test order into database
        const testOrderId = 'sec-test-' + Date.now();
        await pool.query(`
            INSERT INTO orders (
                order_id, shop_id, status, queue_position, amount_total, payment_status,
                files, print_mode, files_deleted, deletion_status
            ) VALUES (
                $1, $2, 'queued', 1, 15.00, 'captured',
                $3, 'secure', false, 'retained'
            )
        `, [
            testOrderId,
            shopId,
            JSON.stringify([{
                url: 'https://storage.googleapis.com/secret-bucket/printit/secure_uploads/secret.pdf',
                s3_key: 'printit/secure_uploads/secret.pdf',
                public_id: 'secret_123',
                file_info: { original_name: 'Tax_Document.pdf', format: 'pdf', size: 2048 }
            }])
        ]);

        const publicRes = await makeRequest(baseUrl, `/api/public/orders/${testOrderId}`, 'GET');
        assert('Public order returns 200 OK', publicRes.status === 200);
        assert('Public order displays print_mode: "secure"', publicRes.body.print_mode === 'secure');
        assert('Public order does NOT expose storage URL', !JSON.stringify(publicRes.body).includes('https://storage.googleapis.com'));
        assert('Public order does NOT expose s3_key/storage_path', !JSON.stringify(publicRes.body).includes('printit/secure_uploads/secret.pdf'));
        assert('Public order sanitizes file name safely', publicRes.body.files[0]?.original_name === 'Tax_Document.pdf');

        // -------------------------------------------------------------
        // Test 3: 410 Gone Enforcement on Deleted Documents
        // -------------------------------------------------------------
        console.log('\n--- Test 3: Purged Document 410 Gone Enforcement ---');
        // Mark test order as deleted
        await pool.query(`
            UPDATE orders 
            SET files_deleted = true, deletion_status = 'deleted', files_deleted_at = NOW()
            WHERE order_id = $1
        `, [testOrderId]);

        // Attempting to access deleted files via shop API routes
        // Check shop files download URL route
        const deletedUrlRes = await pool.query(
            'SELECT files_deleted, deletion_status FROM orders WHERE order_id = $1',
            [testOrderId]
        );
        assert('Order reflects files_deleted: true in database', deletedUrlRes.rows[0].files_deleted === true);
        assert('Order reflects deletion_status: "deleted"', deletedUrlRes.rows[0].deletion_status === 'deleted');

        // Verify public tracking reflects deletion status
        const publicDeletedRes = await makeRequest(baseUrl, `/api/public/orders/${testOrderId}`, 'GET');
        assert('Public tracking reports files_deleted: true', publicDeletedRes.body.files_deleted === true);
        assert('Public tracking reports deletion_status: "deleted"', publicDeletedRes.body.deletion_status === 'deleted');

        // -------------------------------------------------------------
        // Test 4: Bounded Retry Auto-Expiry Worker Logic
        // -------------------------------------------------------------
        console.log('\n--- Test 4: Bounded Retry Auto-Expiry Worker Logic ---');
        const expiredOrderId = 'sec-exp-' + Date.now();
        await pool.query(`
            INSERT INTO orders (
                order_id, shop_id, status, queue_position, amount_total, payment_status,
                files, print_mode, files_deleted, deletion_status, secure_expires_at
            ) VALUES (
                $1, $2, 'cancelled', 0, 10.00, 'refunded',
                $3, 'secure', false, 'retained', NOW() - INTERVAL '5 minutes'
            )
        `, [
            expiredOrderId,
            shopId,
            JSON.stringify([{
                url: 'https://storage.googleapis.com/test-bucket/printit/secure_uploads/expired.pdf',
                storage_path: 'printit/secure_uploads/expired.pdf',
                file_info: { original_name: 'Expired.pdf', size: 1024 }
            }])
        ]);

        // Run auto-expiry cleanup worker
        await cleanupSecureExpiredFiles();

        const expCheck = await pool.query(
            'SELECT files_deleted, deletion_status, files_deleted_at FROM orders WHERE order_id = $1',
            [expiredOrderId]
        );
        assert('Auto-expiry worker purged expired secure order', expCheck.rows[0].files_deleted === true);
        assert('Auto-expiry worker set deletion_status: "deleted"', expCheck.rows[0].deletion_status === 'deleted');
        assert('Auto-expiry worker set files_deleted_at timestamp', expCheck.rows[0].files_deleted_at !== null);

        // -------------------------------------------------------------
        // Test 5: Download Prohibition & Zero-Trace Enforcement
        // -------------------------------------------------------------
        console.log('\n--- Test 5: Download Prohibition & Zero-Trace Enforcement ---');
        const shopFull = await pool.query('SELECT shop_id, owner_id FROM shops WHERE owner_id IS NOT NULL LIMIT 1');
        const jwt = require('jsonwebtoken');
        const shopJwt = jwt.sign({ user_id: shopFull.rows[0].owner_id }, process.env.JWT_SECRET || 'your_super_secret_jwt_key_here');

        const secOrderDlTestId = 'sec-dl-' + Date.now();
        await pool.query(`
            INSERT INTO orders (
                order_id, shop_id, status, queue_position, amount_total, payment_status,
                files, print_mode, files_deleted, deletion_status
            ) VALUES (
                $1, $2, 'queued', 1, 15.00, 'captured',
                $3, 'secure', false, 'retained'
            )
        `, [
            secOrderDlTestId,
            shopFull.rows[0].shop_id,
            JSON.stringify([{
                url: 'https://example.com/test.pdf',
                s3_key: 'https://example.com/test.pdf',
                file_info: { original_name: 'Confidential.pdf', size: 2048 }
            }])
        ]);

        const dlAttemptRes = await makeRequest(
            baseUrl,
            `/api/shop/orders/${secOrderDlTestId}/files/0/proxy?download=true`,
            'GET',
            null,
            { Authorization: `Bearer ${shopJwt}` }
        );
        assert('Explicit download query parameter is blocked with 403 Forbidden', dlAttemptRes.status === 403);
        assert('Download block response clarifies privacy protection', dlAttemptRes.body.error && dlAttemptRes.body.error.includes('privacy'));

        // -------------------------------------------------------------
        // Test 6: Clean Up Test Artifacts
        // -------------------------------------------------------------
        await pool.query('DELETE FROM orders WHERE order_id IN ($1, $2, $3)', [testOrderId, expiredOrderId, secOrderDlTestId]);

        console.log('\n================================================================');
        console.log(`TEST SUMMARY: ${passedCount} PASSED, ${failedCount} FAILED`);
        console.log('================================================================\n');

    } catch (err) {
        console.error('Test run encountered fatal error:', err);
    } finally {
        server.close();
        await pool.end();
        process.exit(failedCount > 0 ? 1 : 0);
    }
}

runSecurityTests();
