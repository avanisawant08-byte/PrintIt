const express = require('express');
const router = express.Router();
const pool = require('../config/db');
const orderSchema = require('../validators/orderValidator');
const auth = require('../middleware/auth');
const roleCheck = require('../middleware/roleCheck');
const getRazorpay = require('../config/razorpay');

/**
 * @route   POST /api/orders/guest
 * @desc    Create a new order without authentication
 * @access  Public
 */
router.post('/guest', async (req, res) => {
    // 1. Validate request body
    const { error, value } = orderSchema.validate(req.body, { abortEarly: false });
    if (error) {
        return res.status(400).json({
            error: 'Validation failed',
            details: error.details.map(d => d.message)
        });
    }

    const {
        customer_id, // Could be null for guests
        shop_id,
        files,
        print_options,
        amount_total,
        payment_id = null,
        print_instructions = null
    } = value;

    // 2. Get current queue position for this shop
    let queue_position = null;
    try {
        const queueResult = await pool.query(
            `SELECT COUNT(*) FROM orders 
       WHERE shop_id = $1 AND status = 'queued'`,
            [shop_id]
        );
        queue_position = parseInt(queueResult.rows[0].count) + 1;
    } catch (err) {
        console.error('Queue position error:', err);
        return res.status(500).json({ error: 'Failed to calculate queue position' });
    }

    // 3. Insert order into DB
    try {
        const result = await pool.query(
            `INSERT INTO orders (
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
      ) VALUES ($1, $2, $3, $4, 'queued', $5, $6, 'pending', $7, $8)
      RETURNING *`,
            [
                customer_id,
                shop_id,
                JSON.stringify(files),
                JSON.stringify(print_options),
                queue_position,
                amount_total,
                payment_id,
                print_instructions
            ]
        );

        return res.status(201).json({
            message: 'Guest order created successfully',
            order: result.rows[0]
        });

    } catch (err) {
        console.error('DB insert error:', err);
        if (err.code === '23503') {
            return res.status(400).json({ error: 'Invalid customer_id or shop_id' });
        }
        return res.status(500).json({ error: 'Failed to create guest order' });
    }
});

// All routes below this point require authentication
router.use(auth);

/**
 * @route   POST /api/orders
 * @desc    Create a new order (Authenticated)
 * @access  Private (Customer Only)
 */
router.post('/', roleCheck('customer'), async (req, res) => {
    // 1. Validate request body
    const { error, value } = orderSchema.validate(req.body, { abortEarly: false });
    if (error) {
        return res.status(400).json({
            error: 'Validation failed',
            details: error.details.map(d => d.message)
        });
    }

    const {
        customer_id,
        shop_id,
        files,
        print_options,
        amount_total,
        payment_id = null,
        razorpay_payment_id = null,
        print_instructions = null
    } = value;

    const targetPaymentId = razorpay_payment_id || payment_id;

    if (!targetPaymentId) {
        return res.status(400).json({ error: 'Payment ID is required to create a print order' });
    }

    try {
        // Verify payment exists and has been captured
        const paymentCheck = await pool.query(
            "SELECT payment_id, razorpay_order_id, razorpay_payment_id, amount, status, created_at FROM payments WHERE razorpay_payment_id = $1 AND status = 'captured'",
            [targetPaymentId]
        );

        if (paymentCheck.rows.length === 0) {
            return res.status(400).json({ error: 'Invalid or uncaptured payment. Order cannot be created.' });
        }

        // 2. Get current queue position for this shop
        let queue_position = null;
        const queueResult = await pool.query(
            `SELECT COUNT(*) FROM orders 
             WHERE shop_id = $1 AND status = 'queued'`,
            [shop_id]
        );
        queue_position = parseInt(queueResult.rows[0].count) + 1;

        // 3. Insert order into DB
        const result = await pool.query(
            `INSERT INTO orders (
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
            ) VALUES ($1, $2, $3, $4, 'queued', $5, $6, 'captured', $7, $8)
            RETURNING *`,
            [
                customer_id,
                shop_id,
                JSON.stringify(files),
                JSON.stringify(print_options),
                queue_position,
                amount_total,
                targetPaymentId,
                print_instructions
            ]
        );

        return res.status(201).json({
            message: 'Order created successfully',
            order: result.rows[0]
        });

    } catch (err) {
        console.error('DB insert error:', err);
        if (err.code === '23503') {
            return res.status(400).json({ error: 'Invalid customer_id or shop_id' });
        }
        return res.status(500).json({ error: 'Failed to create order' });
    }
});

/**
 * @route   GET /api/orders
 * @desc    Fetch all orders
 * @access  Private (Both Customer and Shop)
 */
router.get('/', async (req, res) => {
    try {
        const page = parseInt(req.query.page, 10) || 1;
        const limit = parseInt(req.query.limit, 10) || 50;
        const offset = (page - 1) * limit;

        let result;
        let countResult;

        if (req.user.role === 'customer') {
            result = await pool.query(
                'SELECT order_id, customer_id, shop_id, files, print_options, status, queue_position, amount_total, payment_status, created_at, updated_at, completed_at, files_deleted, cancelled_at, payment_id, pickup_qr, print_instructions, refund_status, refund_id FROM orders WHERE customer_id = $1 ORDER BY created_at DESC LIMIT $2 OFFSET $3',
                [req.user.user_id, limit, offset]
            );
            countResult = await pool.query('SELECT COUNT(*) FROM orders WHERE customer_id = $1', [req.user.user_id]);
        } else {
            result = await pool.query(
                'SELECT order_id, customer_id, shop_id, files, print_options, status, queue_position, amount_total, payment_status, created_at, updated_at, completed_at, files_deleted, cancelled_at, payment_id, pickup_qr, print_instructions, refund_status, refund_id FROM orders ORDER BY created_at DESC LIMIT $1 OFFSET $2',
                [limit, offset]
            );
            countResult = await pool.query('SELECT COUNT(*) FROM orders');
        }
        
        const totalItems = parseInt(countResult.rows[0].count, 10);
        res.json({
            data: result.rows,
            pagination: {
                page,
                limit,
                total_items: totalItems,
                total_pages: Math.ceil(totalItems / limit)
            }
        });
    } catch (err) {
        console.error('DB fetch error:', err);
        res.status(500).json({ error: 'Failed to fetch orders' });
    }
});

/**
 * @route   GET /api/orders/:id
 * @desc    Fetch a single order
 * @access  Private (Both Customer and Shop)
 */
router.get('/:id', async (req, res) => {
    const { id } = req.params;

    try {
        const result = await pool.query(
            'SELECT order_id, customer_id, shop_id, files, print_options, status, queue_position, amount_total, payment_status, created_at, updated_at, completed_at, files_deleted, cancelled_at, payment_id, pickup_qr, print_instructions, refund_status, refund_id FROM orders WHERE order_id = $1',
            [id]
        );

        if (result.rows.length === 0) {
            return res.status(404).json({ error: 'Order not found' });
        }

        res.json(result.rows[0]);

    } catch (err) {
        console.error('DB fetch error:', err);
        res.status(500).json({ error: 'Failed to fetch order' });
    }
});

/**
 * @route   PATCH /api/orders/:id/status
 * @desc    Update order status
 * @access  Private (Both Customer and Shop)
 */
router.patch('/:id/status', async (req, res) => {
    const { id } = req.params;
    const { status } = req.body;

    // 1. Validate status value
    const validStatuses = ['queued', 'processing', 'ready', 'collected', 'cancelled'];
    if (!status || !validStatuses.includes(status)) {
        return res.status(400).json({
            error: 'Invalid status',
            valid_values: validStatuses
        });
    }

    try {
        const result = await pool.query(
            `UPDATE orders 
   SET status = $1::order_status
   WHERE order_id = $2
   RETURNING *`,
            [status, id]
        );

        if (result.rows.length === 0) {
            return res.status(404).json({ error: 'Order not found' });
        }

        return res.json({
            message: 'Order status updated',
            order: result.rows[0]
        });

    } catch (err) {
        console.error('DB update error:', err);
        res.status(500).json({ error: 'Failed to update order status' });
    }
});

/**
 * @route   PATCH /api/orders/:id/cancel
 * @desc    Cancel an order and trigger refund
 * @access  Private (Customer Only)
 */
router.patch('/:id/cancel', roleCheck('customer'), async (req, res) => {
    const { id } = req.params;
    const client = await pool.connect();

    try {
        await client.query('BEGIN');

        // 1. Fetch order and verify ownership & status
        const orderResult = await client.query(
            'SELECT order_id, customer_id, shop_id, files, print_options, status, queue_position, amount_total, payment_status, created_at, updated_at, completed_at, files_deleted, cancelled_at, payment_id, pickup_qr, print_instructions, refund_status, refund_id FROM orders WHERE order_id = $1 FOR UPDATE',
            [id]
        );

        if (orderResult.rows.length === 0) {
            await client.query('ROLLBACK');
            return res.status(404).json({ error: 'Order not found' });
        }

        const order = orderResult.rows[0];

        if (order.customer_id !== req.user.user_id) {
            await client.query('ROLLBACK');
            return res.status(403).json({ error: 'Unauthorized to cancel this order' });
        }

        if (order.status !== 'queued') {
            await client.query('ROLLBACK');
            return res.status(400).json({ error: 'Order already in progress, cannot cancel' });
        }

        // 2. Trigger Refund (Wallet for Auth Users)
        let refundStatus = null;
        let refundId = null;
        let paymentStatus = order.payment_status;

        if (order.payment_status === 'captured') {
            try {
                // Refund to Wallet
                const amount = parseFloat(order.amount_total);
                
                const userUpdate = await client.query(
                    `UPDATE users 
                     SET wallet_balance = wallet_balance + $1 
                     WHERE user_id = $2 
                     RETURNING wallet_balance`,
                    [amount, req.user.user_id]
                );

                const txResult = await client.query(
                    `INSERT INTO wallet_transactions (user_id, amount, type, reference_id)
                     VALUES ($1, $2, 'refund', $3)
                     RETURNING id`,
                    [req.user.user_id, amount, order.order_id]
                );

                refundStatus = 'wallet_refunded';
                refundId = 'wt_' + txResult.rows[0].id;
                paymentStatus = 'refunded';
            } catch (refundError) {
                console.error('Wallet refund failed:', refundError);
                refundStatus = 'failed';
            }
        }

        // 3. Update Order Status
        const updateResult = await client.query(
            `UPDATE orders 
             SET status = 'cancelled', 
                 cancelled_at = NOW(),
                 refund_status = $1,
                 refund_id = $2,
                 payment_status = $3
             WHERE order_id = $4
             RETURNING *`,
            [refundStatus, refundId, paymentStatus, id]
        );

        await client.query('COMMIT');
        
        return res.json({
            message: 'Order cancelled successfully',
            order: updateResult.rows[0]
        });

    } catch (err) {
        await client.query('ROLLBACK');
        console.error('Order cancellation error:', err);
        return res.status(500).json({ error: 'Failed to cancel order' });
    } finally {
        client.release();
    }
});

module.exports = router;