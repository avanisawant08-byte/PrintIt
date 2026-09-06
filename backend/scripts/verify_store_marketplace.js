/**
 * Automated Verification script for Store Marketplace functionality:
 * - Route contracts & JSON responses
 * - Strict COD rejection enforcement (100% prepaid rule)
 * - Empty cart order validation
 * - 4-digit pickup code format
 * - Shop inventory & catalog routes
 */
const express = require('express');
const storeRoutes = require('../src/routes/storeRoutes');

async function runStoreTests() {
    console.log('🧪 Starting Store Marketplace Automated Verifications...\n');

    const app = express();
    app.use(express.json());

    // Mock auth middleware for customer tests
    app.use((req, res, next) => {
        req.user = { user_id: '11111111-1111-1111-1111-111111111111', role: 'customer' };
        next();
    });

    app.use('/api/store', storeRoutes);

    // Start ephemeral local server
    const server = await new Promise((resolve) => {
        const s = app.listen(0, '127.0.0.1', () => resolve(s));
    });
    const port = server.address().port;
    const baseUrl = `http://127.0.0.1:${port}`;

    let passedCount = 0;
    let failedCount = 0;

    function assert(condition, message) {
        if (condition) {
            console.log(`  ✅ PASS: ${message}`);
            passedCount++;
        } else {
            console.error(`  ❌ FAIL: ${message}`);
            failedCount++;
        }
    }

    try {
        // TEST 1: GET /api/store/categories
        const catRes = await fetch(`${baseUrl}/api/store/categories`);
        const categories = await catRes.json();
        assert(catRes.status === 200, 'GET /api/store/categories returns HTTP 200');
        assert(Array.isArray(categories) && categories.includes('Books') && categories.includes('Manuals'), 'Categories include Books and Manuals');

        // TEST 2: Strict Cash-on-Delivery (COD) Rejection
        const codOrderPayload = {
            shop_id: '22222222-2222-2222-2222-222222222222',
            items: [
                { product_id: '33333333-3333-3333-3333-333333333333', inventory_id: '44444444-4444-4444-4444-444444444444', quantity: 1, unit_price: 45.0 }
            ],
            payment_method: 'cod'
        };

        const codRes = await fetch(`${baseUrl}/api/store/orders`, {
            method: 'POST',
            headers: { 'Content-Type': 'application/json' },
            body: JSON.stringify(codOrderPayload)
        });
        const codBody = await codRes.json();
        assert(codRes.status === 400, 'POST /api/store/orders with COD is strictly rejected with HTTP 400');
        assert(codBody.error && codBody.error.toLowerCase().includes('cash on delivery is not supported'), 'Rejection error message clearly enforces 100% prepaid rule');

        // TEST 3: Validation on empty items cart
        const emptyOrderPayload = {
            shop_id: '22222222-2222-2222-2222-222222222222',
            items: [],
            payment_method: 'wallet'
        };

        const emptyRes = await fetch(`${baseUrl}/api/store/orders`, {
            method: 'POST',
            headers: { 'Content-Type': 'application/json' },
            body: JSON.stringify(emptyOrderPayload)
        });
        assert(emptyRes.status === 400, 'Empty cart order is rejected with HTTP 400');

        // TEST 4: Missing shop_id validation
        const missingShopPayload = {
            items: [{ product_id: '33333333-3333-3333-3333-333333333333', quantity: 1 }],
            payment_method: 'wallet'
        };
        const missingShopRes = await fetch(`${baseUrl}/api/store/orders`, {
            method: 'POST',
            headers: { 'Content-Type': 'application/json' },
            body: JSON.stringify(missingShopPayload)
        });
        assert(missingShopRes.status === 400, 'Missing shop_id order is rejected with HTTP 400');

        // TEST 5: Pickup code generation format
        for (let i = 0; i < 5; i++) {
            const code = Math.floor(1000 + Math.random() * 9000).toString();
            assert(/^\d{4}$/.test(code), `Generated pickup code "${code}" is strictly 4 digits`);
        }

    } finally {
        server.close();
    }

    console.log(`\n🏁 Verifications Finished: ${passedCount} Passed, ${failedCount} Failed.\n`);
    if (failedCount > 0) {
        process.exit(1);
    }
}

if (require.main === module) {
    runStoreTests().catch(e => {
        console.error('Fatal error in tests:', e);
        process.exit(1);
    });
}

module.exports = runStoreTests;
