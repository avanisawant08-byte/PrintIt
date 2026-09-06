const express = require('express');
const router = express.Router();
const pool = require('../config/db');
const auth = require('../middleware/auth');
const getRazorpay = require('../config/razorpay');
const crypto = require('crypto');

router.use(auth);

// GET /api/wallet
// Fetch wallet balance and transactions
router.get('/', async (req, res) => {
    try {
        const userResult = await pool.query(
            'SELECT wallet_balance FROM users WHERE user_id = $1',
            [req.user.user_id]
        );
        
        if (userResult.rows.length === 0) {
            return res.status(404).json({ error: 'User not found' });
        }

        const balance = userResult.rows[0].wallet_balance;

        const txResult = await pool.query(
            'SELECT id, user_id, amount, type, reference_id, created_at FROM wallet_transactions WHERE user_id = $1 ORDER BY created_at DESC LIMIT 50',
            [req.user.user_id]
        );

        res.json({
            balance: parseFloat(balance),
            transactions: txResult.rows
        });
    } catch (err) {
        console.error('Wallet fetch error:', err);
        res.status(500).json({ error: 'Failed to fetch wallet data' });
    }
});

// POST /api/wallet/topup/create
// Create a Razorpay order for wallet topup
router.post('/topup/create', async (req, res) => {
    const { amount } = req.body; // amount in rupees

    if (!amount || amount <= 0) {
        return res.status(400).json({ error: 'Valid amount is required' });
    }

    try {
        const order = await getRazorpay().orders.create({
            amount: Math.round(amount * 100),
            currency: 'INR',
            receipt: `topup_${Date.now()}`,
            payment_capture: 1
        });

        return res.status(201).json({
            razorpay_order_id: order.id,
            amount: order.amount,
            currency: order.currency,
            key_id: process.env.RAZORPAY_KEY_ID
        });

    } catch (err) {
        console.error('Razorpay topup order error:', err);
        res.status(500).json({ error: 'Failed to create topup order' });
    }
});

// POST /api/wallet/topup/verify
// Verify topup payment and add to wallet
router.post('/topup/verify', async (req, res) => {
    const {
        razorpay_order_id,
        razorpay_payment_id,
        razorpay_signature,
        amount // amount in rupees
    } = req.body;

    // 1. Verify Razorpay signature
    let isValid = false;
    if (process.env.NODE_ENV === 'test' && process.env.ALLOW_MOCK_PAYMENTS === 'true' && razorpay_signature === 'mock_signature') {
        isValid = true;
    } else {
        const body = razorpay_order_id + '|' + razorpay_payment_id;
        const expectedSignature = crypto
            .createHmac('sha256', process.env.RAZORPAY_KEY_SECRET || '')
            .update(body)
            .digest('hex');

        const expectedBuf = Buffer.from(expectedSignature, 'utf8');
        const signatureBuf = Buffer.from(razorpay_signature || '', 'utf8');
        isValid = expectedBuf.length === signatureBuf.length && crypto.timingSafeEqual(expectedBuf, signatureBuf);
    }

    if (!isValid) {
        return res.status(400).json({ error: 'Invalid payment signature' });
    }

    // 2. Gateway Amount Verification (Never trust client-supplied amount)
    let verifiedAmount = parseFloat(amount);
    if (isNaN(verifiedAmount) || verifiedAmount <= 0) {
        return res.status(400).json({ error: 'Valid amount is required' });
    }

    if (!(process.env.NODE_ENV === 'test' && process.env.ALLOW_MOCK_PAYMENTS === 'true' && razorpay_signature === 'mock_signature')) {
        try {
            const razorpay = getRazorpay();
            const paymentDetails = await razorpay.payments.fetch(razorpay_payment_id);

            if (!paymentDetails || paymentDetails.status !== 'captured') {
                return res.status(400).json({ error: 'Payment is not captured or is invalid.' });
            }

            if (paymentDetails.order_id !== razorpay_order_id) {
                return res.status(400).json({ error: 'Payment does not match the Razorpay order.' });
            }

            // Razorpay amounts are represented in paise (1 INR = 100 paise)
            const actualRupees = paymentDetails.amount / 100;
            if (actualRupees <= 0) {
                return res.status(400).json({ error: 'Invalid captured payment amount.' });
            }

            // Always credit the actual captured amount from the gateway, never client-specified amount
            verifiedAmount = actualRupees;
        } catch (fetchErr) {
            console.error('Razorpay verification error:', fetchErr);
            return res.status(500).json({ error: 'Unable to verify payment with payment gateway' });
        }
    }

    const client = await pool.connect();
    try {
        await client.query('BEGIN');

        // Prevent Double-Spending: Check if this payment has already been processed anywhere
        const existingUsage = await client.query(
            `SELECT 1 FROM wallet_transactions WHERE reference_id = $1
             UNION ALL
             SELECT 1 FROM orders WHERE payment_id = $1
             UNION ALL
             SELECT 1 FROM product_orders WHERE payment_id = $1`,
            [razorpay_payment_id]
        );

        if (existingUsage.rows.length > 0) {
            await client.query('ROLLBACK');
            return res.status(409).json({ error: 'This payment has already been processed.' });
        }

        // Log payment
        await client.query(
            `INSERT INTO payments (razorpay_order_id, razorpay_payment_id, status, amount)
             VALUES ($1, $2, 'captured', $3)`,
            [razorpay_order_id, razorpay_payment_id, verifiedAmount]
        );

        // Update Wallet using verifiedAmount
        const updateResult = await client.query(
            `UPDATE users SET wallet_balance = wallet_balance + $1 WHERE user_id = $2 RETURNING wallet_balance`,
            [verifiedAmount, req.user.user_id]
        );

        // Insert Transaction
        await client.query(
            `INSERT INTO wallet_transactions (user_id, amount, type, reference_id)
             VALUES ($1, $2, 'topup', $3)`,
            [req.user.user_id, verifiedAmount, razorpay_payment_id]
        );

        await client.query('COMMIT');

        res.status(200).json({ 
            message: 'Wallet topup successful',
            new_balance: parseFloat(updateResult.rows[0].wallet_balance)
        });

    } catch (err) {
        await client.query('ROLLBACK');
        console.error('Wallet topup verification error:', err);
        if (err.code === '23505') {
            return res.status(409).json({ error: 'This payment has already been processed.' });
        }
        res.status(500).json({ error: 'Failed to complete topup' });
    } finally {
        client.release();
    }
});

module.exports = router;
