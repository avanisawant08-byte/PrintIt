const auth = require('../middleware/auth');
const express = require('express');
const router = express.Router();
const crypto = require('crypto');
const getRazorpay = require('../config/razorpay');
const pool = require('../config/db');
const { generateOrderId } = require('../utils/orderIdGenerator');
const { calculatePrintSubtotal } = require('../utils/pricingCalculator');
const { paymentLimiter } = require('../middleware/rateLimiter');

router.use(paymentLimiter);

const verifyRazorpaySignature = (orderId, paymentId, signature) => {
    if (!signature || !orderId || !paymentId) return false;
    
    // Allow mock signature ONLY in automated test mode with explicit environment flag
    if (process.env.NODE_ENV === 'test' && process.env.ALLOW_MOCK_PAYMENTS === 'true' && signature === 'mock_signature') {
        return true;
    }
    
    const body = orderId + '|' + paymentId;
    const expectedSignature = crypto
        .createHmac('sha256', process.env.RAZORPAY_KEY_SECRET || '')
        .update(body)
        .digest('hex');

    const expectedBuf = Buffer.from(expectedSignature, 'utf8');
    const signatureBuf = Buffer.from(signature, 'utf8');

    if (expectedBuf.length !== signatureBuf.length) {
        return false;
    }
    return crypto.timingSafeEqual(expectedBuf, signatureBuf);
};

// =================== GUEST ROUTES ===================

// POST /api/payments/guest/create
router.post('/guest/create', async (req, res) => {
    const { amount } = req.body;

    if (!amount || amount <= 0) {
        return res.status(400).json({ error: 'Valid amount is required' });
    }

    try {
        const order = await getRazorpay().orders.create({
            amount: Math.round(amount * 100),
            currency: 'INR',
            receipt: `receipt_guest_${Date.now()}`,
            payment_capture: 1
        });

        return res.status(201).json({
            razorpay_order_id: order.id,
            amount: order.amount,
            currency: order.currency,
            key_id: process.env.RAZORPAY_KEY_ID
        });
    } catch (err) {
        console.error('Razorpay guest order error:', err);
        res.status(500).json({ error: 'Failed to create payment order' });
    }
});

// POST /api/payments/guest/verify
router.post('/guest/verify', async (req, res) => {
    const {
        razorpay_order_id,
        razorpay_payment_id,
        razorpay_signature,
        shop_id,
        files,
        amount_total
    } = req.body;

    // 1. Verify Razorpay signature
    if (!verifyRazorpaySignature(razorpay_order_id, razorpay_payment_id, razorpay_signature)) {
        return res.status(400).json({ error: 'Invalid payment signature' });
    }

    const pickupOptions = JSON.stringify({
        pickup_type: req.body.pickup_type || 'express',
        pickup_time: req.body.pickup_time || null
    });

    // 2. Signature valid — save payment record & create print order
    const client = await pool.connect();
    try {
        await client.query('BEGIN');

        // Prevent Double-Spending: Check if this payment has already been associated with an order
        const existingUsage = await client.query(
            `SELECT 1 FROM orders WHERE payment_id = $1
             UNION ALL
             SELECT 1 FROM product_orders WHERE payment_id = $1`,
            [razorpay_payment_id]
        );

        if (existingUsage.rows.length > 0) {
            await client.query('ROLLBACK');
            return res.status(409).json({ error: 'This payment has already been verified and associated with an existing order.' });
        }

        // Validate Server-Side Pricing
        const { minRequiredAmount } = await calculatePrintSubtotal(client, shop_id, files);
        if (parseFloat(amount_total) < minRequiredAmount) {
            await client.query('ROLLBACK');
            return res.status(400).json({
                error: `Order amount insufficient. Minimum required ₹${minRequiredAmount}, received ₹${amount_total}`
            });
        }

        await client.query(
            `INSERT INTO payments (razorpay_order_id, razorpay_payment_id, status, amount)
             VALUES ($1, $2, 'captured', $3)`,
            [razorpay_order_id, razorpay_payment_id, amount_total]
        );

        const queueResult = await client.query(
            `SELECT COUNT(*) FROM orders
             WHERE shop_id = $1 AND status = 'queued'`,
            [shop_id]
        );
        const queue_position = parseInt(queueResult.rows[0].count) + 1;

        const orderId = await generateOrderId(req.body.pickup_type || 'express', client);
        const cancelToken = crypto.randomBytes(16).toString('hex');

        const result = await client.query(
            `INSERT INTO orders (
                order_id, customer_id, shop_id, files, print_options, status, queue_position, amount_total, payment_status, payment_id, print_instructions, cancel_token
            ) VALUES ($1, NULL, $2, $3, $4, 'queued', $5, $6, 'captured', $7, $8, $9)
            RETURNING *`,
            [
                orderId, shop_id, JSON.stringify(files), pickupOptions, queue_position, amount_total, razorpay_payment_id, '', cancelToken
            ]
        );

        await client.query('COMMIT');
        return res.status(201).json({ message: 'Payment verified & order created', order: result.rows[0], cancel_token: cancelToken });

    } catch (err) {
        await client.query('ROLLBACK');
        console.error('Guest Order creation error:', err);
        if (err.code === '23505') {
            return res.status(409).json({ error: 'This payment has already been used for an existing order.' });
        }
        res.status(500).json({ error: 'Payment verified but order creation failed' });
    } finally {
        client.release();
    }
});

// POST /api/payments/guest/fail
router.post('/guest/fail', async (req, res) => {
    const { shop_id, files, amount_total, pickup_type, pickup_time } = req.body;
    const pickupOptions = JSON.stringify({
        pickup_type: pickup_type || 'express',
        pickup_time: pickup_time || null
    });
    try {
        const client = await pool.connect();
        try {
            await client.query('BEGIN');
            const orderId = await generateOrderId(pickup_type || 'express', client);
            const result = await client.query(
                `INSERT INTO orders (
                    order_id, customer_id, shop_id, files, print_options, status, queue_position, amount_total, payment_status, payment_id
                ) VALUES ($1, NULL, $2, $3, $4, 'cancelled', NULL, $5, 'failed', NULL)
                RETURNING *`,
                [orderId, shop_id, JSON.stringify(files), pickupOptions, amount_total]
            );
            await client.query('COMMIT');
            return res.status(201).json({ message: 'Failed order logged', order: result.rows[0] });
        } catch (err) {
            await client.query('ROLLBACK');
            throw err;
        } finally {
            client.release();
        }
    } catch (err) {
        console.error('Guest Order failure log error:', err);
        res.status(500).json({ error: 'Failed to log failed order' });
    }
});

// =================== AUTH ROUTES ===================
router.use(auth);

// POST /api/payments/create — Create Razorpay order
router.post('/create', async (req, res) => {
    const { amount } = req.body;

    if (!amount || amount <= 0) {
        return res.status(400).json({ error: 'Valid amount is required' });
    }

    try {
        const order = await getRazorpay().orders.create({
            amount: Math.round(amount * 100),
            currency: 'INR',
            receipt: `receipt_${Date.now()}`,
            payment_capture: 1
        });

        return res.status(201).json({
            razorpay_order_id: order.id,
            amount: order.amount,
            currency: order.currency,
            key_id: process.env.RAZORPAY_KEY_ID
        });

    } catch (err) {
        console.error('Razorpay order error:', err);
        res.status(500).json({ error: 'Failed to create payment order' });
    }
});

// POST /api/payments/verify — Verify payment + create print order
router.post('/verify', async (req, res) => {
    const {
        razorpay_order_id,
        razorpay_payment_id,
        razorpay_signature,
        customer_id,
        shop_id,
        files,
        amount_total
    } = req.body;

    // 1. Verify Razorpay signature
    if (!verifyRazorpaySignature(razorpay_order_id, razorpay_payment_id, razorpay_signature)) {
        return res.status(400).json({ error: 'Invalid payment signature' });
    }

    const pickupOptions = JSON.stringify({
        pickup_type: req.body.pickup_type || 'express',
        pickup_time: req.body.pickup_time || null
    });

    // 2. Signature valid — save payment record to payments table and create print order in DB
    const client = await pool.connect();
    try {
        await client.query('BEGIN');

        // Prevent Double-Spending: Check if this payment has already been associated with an order
        const existingUsage = await client.query(
            `SELECT 1 FROM orders WHERE payment_id = $1
             UNION ALL
             SELECT 1 FROM product_orders WHERE payment_id = $1`,
            [razorpay_payment_id]
        );

        if (existingUsage.rows.length > 0) {
            await client.query('ROLLBACK');
            return res.status(409).json({ error: 'This payment has already been verified and associated with an existing order.' });
        }

        // Validate Server-Side Pricing
        const { minRequiredAmount } = await calculatePrintSubtotal(client, shop_id, files);
        if (parseFloat(amount_total) < minRequiredAmount) {
            await client.query('ROLLBACK');
            return res.status(400).json({
                error: `Order amount insufficient. Minimum required ₹${minRequiredAmount}, received ₹${amount_total}`
            });
        }

        // Log payment record in payments table
        await client.query(
            `INSERT INTO payments (razorpay_order_id, razorpay_payment_id, status, amount)
             VALUES ($1, $2, 'captured', $3)`,
            [razorpay_order_id, razorpay_payment_id, amount_total]
        );

        // Get queue position for this shop
        const queueResult = await client.query(
            `SELECT COUNT(*) FROM orders
             WHERE shop_id = $1 AND status = 'queued'`,
            [shop_id]
        );
        const queue_position = parseInt(queueResult.rows[0].count) + 1;

        const orderId = await generateOrderId(req.body.pickup_type || 'express', client);

        // Insert order into DB
        const result = await client.query(
            `INSERT INTO orders (
                order_id,
                customer_id,
                shop_id,
                files,
                print_options,
                status,
                queue_position,
                amount_total,
                payment_status,
                payment_id,
                print_instructions
            ) VALUES ($1, $2, $3, $4, $5, 'queued', $6, $7, 'captured', $8, '')
            RETURNING *`,
            [
                orderId,
                req.user.user_id,
                shop_id,
                JSON.stringify(files),
                pickupOptions,
                queue_position,
                amount_total,
                razorpay_payment_id
            ]
        );

        await client.query('COMMIT');

        return res.status(201).json({
            message: 'Payment verified & order created',
            order: result.rows[0]
        });

    } catch (err) {
        await client.query('ROLLBACK');
        console.error('Order creation/payment logging error:', err);
        if (err.code === '23505') {
            return res.status(409).json({ error: 'This payment has already been used for an existing order.' });
        }
        res.status(500).json({ error: 'Payment verified but order creation failed' });
    } finally {
        client.release();
    }
});

// POST /api/payments/fail
router.post('/fail', async (req, res) => {
    const { shop_id, files, amount_total, pickup_type, pickup_time } = req.body;
    const pickupOptions = JSON.stringify({
        pickup_type: pickup_type || 'express',
        pickup_time: pickup_time || null
    });
    try {
        const client = await pool.connect();
        try {
            await client.query('BEGIN');
            const orderId = await generateOrderId(pickup_type || 'express', client);
            const result = await client.query(
                `INSERT INTO orders (
                    order_id, customer_id, shop_id, files, print_options, status, queue_position, amount_total, payment_status, payment_id
                ) VALUES ($1, $2, $3, $4, $5, 'cancelled', NULL, $6, 'failed', NULL)
                RETURNING *`,
                [orderId, req.user.user_id, shop_id, JSON.stringify(files), pickupOptions, amount_total]
            );
            await client.query('COMMIT');
            return res.status(201).json({ message: 'Failed order logged', order: result.rows[0] });
        } catch(err) {
            await client.query('ROLLBACK');
            throw err;
        } finally {
            client.release();
        }
    } catch (err) {
        console.error('Order failure log error:', err);
        res.status(500).json({ error: 'Failed to log failed order' });
    }
});

// POST /api/payments/wallet — Pay using Wallet Balance
router.post('/wallet', async (req, res) => {
    const { shop_id, files, amount_total } = req.body;
    
    if (!amount_total || amount_total <= 0) {
        return res.status(400).json({ error: 'Valid amount is required' });
    }

    const client = await pool.connect();
    try {
        await client.query('BEGIN');

        // 1. Calculate Required Print Subtotal on Server
        const { subtotal } = await calculatePrintSubtotal(client, shop_id, files);
        const requiredAmount = Math.max(subtotal, parseFloat(amount_total) || 0);

        // 2. Check Wallet Balance
        const userResult = await client.query(
            'SELECT wallet_balance FROM users WHERE user_id = $1 FOR UPDATE',
            [req.user.user_id]
        );

        if (userResult.rows.length === 0) {
            await client.query('ROLLBACK');
            return res.status(404).json({ error: 'User not found' });
        }

        const balance = parseFloat(userResult.rows[0].wallet_balance);

        if (balance < requiredAmount) {
            await client.query('ROLLBACK');
            return res.status(400).json({ error: `Insufficient wallet balance. Required ₹${requiredAmount}, available ₹${balance}` });
        }

        // 3. Deduct Verified Balance
        await client.query(
            'UPDATE users SET wallet_balance = wallet_balance - $1 WHERE user_id = $2',
            [requiredAmount, req.user.user_id]
        );

        // 4. Log Wallet Transaction
        const txResult = await client.query(
            `INSERT INTO wallet_transactions (user_id, amount, type)
             VALUES ($1, $2, 'payment')
             RETURNING id`,
            [req.user.user_id, -requiredAmount]
        );
        const payment_id = 'wt_' + txResult.rows[0].id;

        // 5. Create Order
        const queueResult = await client.query(
            `SELECT COUNT(*) FROM orders
             WHERE shop_id = $1 AND status = 'queued'`,
            [shop_id]
        );
        const queue_position = parseInt(queueResult.rows[0].count) + 1;

        const pickupOptions = JSON.stringify({
            pickup_type: req.body.pickup_type || 'express',
            pickup_time: req.body.pickup_time || null
        });

        const orderId = await generateOrderId(req.body.pickup_type || 'express', client);

        const result = await client.query(
            `INSERT INTO orders (
                order_id, customer_id, shop_id, files, print_options, status, queue_position, amount_total, payment_status, payment_id, print_instructions
            ) VALUES ($1, $2, $3, $4, $5, 'queued', $6, $7, 'captured', $8, $9)
            RETURNING *`,
            [
                orderId, req.user.user_id, shop_id, JSON.stringify(files), pickupOptions, queue_position, requiredAmount, payment_id, req.body.print_instructions || ''
            ]
        );

        // Link the transaction to the order
        await client.query(
            'UPDATE wallet_transactions SET reference_id = $1 WHERE id = $2',
            [result.rows[0].order_id, txResult.rows[0].id]
        );

        await client.query('COMMIT');

        return res.status(201).json({
            message: 'Payment successful using Wallet',
            order: result.rows[0]
        });

    } catch (err) {
        await client.query('ROLLBACK');
        console.error('Wallet payment error:', err);
        res.status(500).json({ error: 'Wallet payment failed' });
    } finally {
        client.release();
    }
});

module.exports = router;