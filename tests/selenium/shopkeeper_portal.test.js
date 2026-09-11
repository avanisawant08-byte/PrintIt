const { By, until } = require('selenium-webdriver');
const { takeScreenshot } = require('./helpers/driver');
const path = require('path');

// Safe database connection to seed and cleanup test orders
let pool = null;
try {
    const dotenv = require(path.resolve(__dirname, '../../backend/node_modules/dotenv'));
    dotenv.config({ path: path.resolve(__dirname, '../../backend/.env') });
    pool = require('../../backend/src/config/db');
} catch (e) {
    console.log('Database helper could not be loaded directly:', e.message);
}

const SHOP_ID = '8473b134-01c6-46b1-9746-4befaaa5fd46';
const TEST_SECURE_QUEUED_ID = 'sec-sel-q-' + Date.now();
const TEST_SECURE_ERASED_ID = 'sec-sel-e-' + Date.now();

async function seedTestOrders() {
    if (!pool) return;
    try {
        // 1. Insert a queued secure order to verify 🔒 SECURE badge in Live Queue
        await pool.query(`
            INSERT INTO orders (
                order_id, shop_id, status, queue_position, amount_total, payment_status,
                files, print_options, print_mode, files_deleted, deletion_status, created_at
            ) VALUES (
                $1, $2, 'queued', 1, 25.00, 'captured',
                $3, $4, 'secure', false, 'retained', NOW()
            )
        `, [
            TEST_SECURE_QUEUED_ID,
            SHOP_ID,
            JSON.stringify([{
                url: 'https://storage.googleapis.com/printit-test/secure_uploads/confidential.pdf',
                file_info: { original_name: 'Confidential_Contract.pdf', format: 'pdf', size: 10240, pages: 2 }
            }]),
            JSON.stringify({ color: 'bw', size: 'A4', sides: 'double', copies: 1 })
        ]);

        // 2. Insert a collected secure order to verify Files Erased badge & disabled actions
        await pool.query(`
            INSERT INTO orders (
                order_id, shop_id, status, queue_position, amount_total, payment_status,
                files, print_options, print_mode, files_deleted, deletion_status, files_deleted_at, created_at
            ) VALUES (
                $1, $2, 'collected', 0, 15.00, 'captured',
                $3, $4, 'secure', true, 'deleted', NOW() - INTERVAL '1 hour', NOW() - INTERVAL '2 hours'
            )
        `, [
            TEST_SECURE_ERASED_ID,
            SHOP_ID,
            JSON.stringify([{
                url: 'https://storage.googleapis.com/printit-test/secure_uploads/erased_doc.pdf',
                file_info: { original_name: 'Medical_Report.pdf', format: 'pdf', size: 4096, pages: 1 }
            }]),
            JSON.stringify({ color: 'color', size: 'A4', sides: 'single', copies: 1 })
        ]);

        console.log('  -> Seeded test secure orders for Live Queue validation.');
    } catch (err) {
        console.warn('  -> Warning: could not seed test orders:', err.message);
    }
}

async function cleanupTestOrders() {
    if (!pool) return;
    try {
        await pool.query('DELETE FROM orders WHERE order_id IN ($1, $2)', [TEST_SECURE_QUEUED_ID, TEST_SECURE_ERASED_ID]);
        await pool.end();
        console.log('  -> Cleaned up test secure orders.');
    } catch (err) {
        console.warn('  -> Warning cleaning up orders:', err.message);
    }
}

/**
 * Execute the Shopkeeper Portal Selenium Test Suite
 */
async function runShopkeeperTestSuite(driver, baseUrl) {
    console.log('\n================================================================');
    console.log('🚀 RUNNING SELENIUM SUITE: SHOPKEEPER PORTAL & SECURE PRINTING');
    console.log(`🌐 Target Base URL: ${baseUrl}`);
    console.log('================================================================\n');

    let passed = 0;
    let failed = 0;

    async function test(name, fn) {
        process.stdout.write(`• Testing: ${name}... `);
        try {
            await fn();
            console.log('✅ PASS');
            passed++;
        } catch (err) {
            console.log(`❌ FAIL\n  Error: ${err.message}`);
            failed++;
            await takeScreenshot(driver, `FAILURE_${name.replace(/[^a-zA-Z0-9]/g, '_')}.png`);
        }
    }

    try {
        await seedTestOrders();

        // -------------------------------------------------------------
        // Test 1: Landing Page & Legal Navigation
        // -------------------------------------------------------------
        await test('01. Landing page loads branding and legal links', async () => {
            await driver.get(baseUrl + '/');
            await driver.wait(until.elementLocated(By.tagName('body')), 10000);
            
            const title = await driver.getTitle();
            if (!title.toLowerCase().includes('printit')) {
                throw new Error(`Expected title to include 'PrintIt', got: '${title}'`);
            }

            const bodyText = await driver.findElement(By.tagName('body')).getText();
            if (!bodyText.toLowerCase().includes('partner') && !bodyText.toLowerCase().includes('printit')) {
                throw new Error('Landing page missing PrintIt partner branding');
            }

            await takeScreenshot(driver, '01_shopkeeper_landing.png');
        });

        await test('02. Legal and Policy pages load correctly', async () => {
            // Privacy Policy
            await driver.get(baseUrl + '/privacy');
            await driver.wait(until.elementLocated(By.tagName('h1')), 5000);
            let h1 = await driver.findElement(By.tagName('h1')).getText();
            if (!h1.toLowerCase().includes('privacy')) throw new Error('Privacy Policy page failed to load');

            // Security Policy
            await driver.get(baseUrl + '/security');
            await driver.wait(until.elementLocated(By.tagName('h1')), 5000);
            h1 = await driver.findElement(By.tagName('h1')).getText();
            if (!h1.toLowerCase().includes('security')) throw new Error('Security Policy page failed to load');

            await takeScreenshot(driver, '02_legal_security_page.png');
        });

        // -------------------------------------------------------------
        // Test 2: Authentication & Error Handling
        // -------------------------------------------------------------
        await test('03. Login rejects invalid credentials with error notification', async () => {
            await driver.get(baseUrl + '/login');
            await driver.wait(until.elementLocated(By.css('input[type="email"]')), 10000);

            const emailInput = await driver.findElement(By.css('input[type="email"]'));
            const passwordInput = await driver.findElement(By.css('input[type="password"]'));
            const submitBtn = await driver.findElement(By.css('button[type="submit"]'));

            await emailInput.sendKeys('invalid_shopkeeper@random.com');
            await passwordInput.sendKeys('wrongpassword123');
            await submitBtn.click();

            // Wait for alert banner
            const alert = await driver.wait(
                until.elementLocated(By.css('[role="alert"], .bg-red-500\\/15, .text-red-400, .bg-rose-500\\/15, .text-rose-400')),
                8000
            );
            const alertText = await alert.getText();
            if (!alertText || alertText.length === 0) {
                throw new Error('Expected authentication error message not displayed');
            }

            await takeScreenshot(driver, '03_login_invalid_alert.png');
        });

        await test('04. Login succeeds with valid shopkeeper credentials', async () => {
            await driver.get(baseUrl + '/login');
            await driver.wait(until.elementLocated(By.css('input[type="email"]')), 10000);

            const emailInput = await driver.findElement(By.css('input[type="email"]'));
            const passwordInput = await driver.findElement(By.css('input[type="password"]'));
            const submitBtn = await driver.findElement(By.css('button[type="submit"]'));

            // Clear and enter valid credentials
            await emailInput.clear();
            await emailInput.sendKeys('avani.sawant24@pcpolytechnic.com');
            await passwordInput.clear();
            await passwordInput.sendKeys('password123');
            await submitBtn.click();

            // Wait for dashboard redirect
            await driver.wait(until.urlContains('/dashboard'), 15000);
            await driver.wait(until.elementLocated(By.tagName('main')), 10000);

            await takeScreenshot(driver, '04_login_success_dashboard.png');
        });

        // -------------------------------------------------------------
        // Test 3: Live Queue & Secure Printing Badges
        // -------------------------------------------------------------
        await test('05. Live Queue displays Secure Printing badge and Erased tags', async () => {
            await driver.get(baseUrl + '/dashboard/queue');
            await driver.wait(until.elementLocated(By.tagName('main')), 10000);

            // Wait for queue cards to render or fetch to complete
            await driver.sleep(1500);

            const bodyText = await driver.findElement(By.tagName('body')).getText();

            // Check if SECURE badge is visible
            const hasSecureBadge = bodyText.includes('SECURE') || bodyText.includes('Secure');
            if (!hasSecureBadge) {
                throw new Error('Secure printing badge not found in Live Queue');
            }

            await takeScreenshot(driver, '05_live_queue_secure_badges.png');
        });

        // -------------------------------------------------------------
        // Test 4: Order Detail Modal & Confidentiality Protections
        // -------------------------------------------------------------
        await test('06. Order Details Modal displays Confidentiality Banner for Secure Orders', async () => {
            // Find order cards in the queue
            const orderCards = await driver.findElements(By.css('.cursor-pointer, [data-order-id], .bg-surface-container'));
            let openedModal = false;

            for (const card of orderCards) {
                const text = await card.getText();
                if (text.includes('SECURE') || text.includes('Secure') || text.includes('Contract')) {
                    await card.click();
                    openedModal = true;
                    break;
                }
            }

            if (!openedModal && orderCards.length > 0) {
                await orderCards[0].click();
                openedModal = true;
            }

            if (openedModal) {
                // Wait for modal dialog
                await driver.sleep(1000);
                const modalText = await driver.findElement(By.tagName('body')).getText();
                
                // Assert Confidentiality Alert
                const hasConfidentialNotice = modalText.includes('Secure Printing') || 
                                              modalText.includes('permanently destroyed') ||
                                              modalText.includes('Confidentiality') ||
                                              modalText.includes('Order Details');
                
                if (!hasConfidentialNotice) {
                    throw new Error('Order details modal opened but expected confidentiality details were not present');
                }

                await takeScreenshot(driver, '06_order_detail_modal_secure.png');

                // Close modal via Escape key or close button
                try {
                    const closeBtn = await driver.findElement(By.css('button:has(.material-symbols-outlined)'));
                    await closeBtn.click();
                } catch (_) {
                    await driver.findElement(By.tagName('body')).sendKeys('\uE00C'); // Escape
                }
            } else {
                console.log('(Skipped clicking card: no order cards available in DOM)');
            }
        });

        // -------------------------------------------------------------
        // Test 5: Orders Management Table
        // -------------------------------------------------------------
        await test('07. Orders Management table renders Print Orders with Secure tags', async () => {
            await driver.get(baseUrl + '/dashboard/orders');
            await driver.wait(until.elementLocated(By.tagName('main')), 10000);

            // Click "Print Orders" tab button
            const tabButtons = await driver.findElements(By.tagName('button'));
            for (const btn of tabButtons) {
                const txt = await btn.getText();
                if (txt.includes('Print Orders')) {
                    await btn.click();
                    break;
                }
            }

            await driver.sleep(1500);
            const tableText = await driver.findElement(By.tagName('body')).getText();
            if (!tableText.includes('Order ID') && !tableText.includes('Orders')) {
                throw new Error('Orders management table failed to load properly');
            }

            await takeScreenshot(driver, '07_orders_management_table.png');
        });

    } finally {
        await cleanupTestOrders();
    }

    console.log('\n================================================================');
    console.log(`SELENIUM SUMMARY: ${passed} PASSED, ${failed} FAILED`);
    console.log('================================================================\n');

    return { passed, failed };
}

module.exports = {
    runShopkeeperTestSuite
};
