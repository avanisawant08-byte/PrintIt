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
    const body = razorpay_order_id + '|' + razorpay_payment_id;
    const expectedSignature = crypto
        .createHmac('sha256', process.env.RAZORPAY_KEY_SECRET)
        .update(body)
        .digest('hex');

    if (expectedSignature !== razorpay_signature) {
        return res.status(400).json({ error: 'Invalid payment signature' });
    }

    const client = await pool.connect();
    try {
        await client.query('BEGIN');

        // Log payment
        await client.query(
            `INSERT INTO payments (razorpay_order_id, razorpay_payment_id, status, amount)
             VALUES ($1, $2, 'captured', $3)`,
            [razorpay_order_id, razorpay_payment_id, amount]
        );

        // Update Wallet
        const updateResult = await client.query(
            `UPDATE users SET wallet_balance = wallet_balance + $1 WHERE user_id = $2 RETURNING wallet_balance`,
            [amount, req.user.user_id]
        );

        // Insert Transaction
        await client.query(
            `INSERT INTO wallet_transactions (user_id, amount, type, reference_id)
             VALUES ($1, $2, 'topup', $3)`,
            [req.user.user_id, amount, razorpay_payment_id]
        );

        await client.query('COMMIT');

        res.status(200).json({ 
            message: 'Wallet topup successful',
            new_balance: parseFloat(updateResult.rows[0].wallet_balance)
        });

    } catch (err) {
        await client.query('ROLLBACK');
        console.error('Wallet topup verification error:', err);
        res.status(500).json({ error: 'Failed to complete topup' });
    } finally {
        client.release();
    }
});

module.exports = router;
