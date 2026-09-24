const express = require('express');
const router = express.Router();
const crypto = require('crypto');
const pool = require('../config/db');
const orderSchema = require('../validators/orderValidator');
const auth = require('../middleware/auth');
const roleCheck = require('../middleware/roleCheck');
const getRazorpay = require('../config/razorpay');
const { calculatePrintSubtotal } = require('../utils/pricingCalculator');
const { deleteOrderFilesImmediately } = require('../utils/firebaseCleanup');

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
        customer_id = null,
        shop_id,
        files,
        print_options,
        amount_total,
        payment_id = null,
        razorpay_payment_id = null,
        print_instructions = null,
        print_mode = 'normal'
    } = value;

    const targetPaymentId = razorpay_payment_id || payment_id;
    if (!targetPaymentId) {
        return res.status(400).json({ 
            error: 'Payment ID is required. Please verify payment via /api/payments/guest/verify before order creation.' 
        });
    }

    const client = await pool.connect();
    try {
        await client.query('BEGIN');

        // 2. Verify payment exists and is captured
        const paymentCheck = await client.query(
            "SELECT payment_id, razorpay_order_id, razorpay_payment_id, amount, status FROM payments WHERE razorpay_payment_id = $1 AND status = 'captured'",
            [targetPaymentId]
        );

        if (paymentCheck.rows.length === 0) {
            await client.query('ROLLBACK');
            return res.status(400).json({ error: 'Invalid or uncaptured payment. Order cannot be queued.' });
        }

        // 3. Prevent Double-Spending: Check if payment is already used
        const existingUsage = await client.query(
            `SELECT 1 FROM orders WHERE payment_id = $1
             UNION ALL
             SELECT 1 FROM product_orders WHERE payment_id = $1`,
            [targetPaymentId]
        );
        if (existingUsage.rows.length > 0) {
            await client.query('ROLLBACK');
            return res.status(409).json({ error: 'This payment has already been associated with an existing order.' });
        }

        // 4. Server-side Pricing Validation
        const { minRequiredAmount } = await calculatePrintSubtotal(client, shop_id, files);
        if (parseFloat(amount_total) < minRequiredAmount) {
            await client.query('ROLLBACK');
            return res.status(400).json({
                error: `Order amount insufficient. Minimum required ₹${minRequiredAmount}, received ₹${amount_total}`
            });
        }

        const recordedPaid = parseFloat(paymentCheck.rows[0].amount);
        if (recordedPaid < minRequiredAmount) {
            await client.query('ROLLBACK');
            return res.status(400).json({
                error: `Attached payment amount ₹${recordedPaid} is less than required print cost ₹${minRequiredAmount}`
            });
        }

        // 5. Get current queue position for this shop
        const queueResult = await client.query(
            `SELECT COUNT(*) FROM orders 
             WHERE shop_id = $1 AND status = 'queued'`,
            [shop_id]
        );
        const queue_position = parseInt(queueResult.rows[0].count) + 1;

        const cancelToken = crypto.randomBytes(16).toString('hex');
        const order_id = 'ORD-' + Math.floor(1000 + Math.random() * 9000);

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
                print_instructions,
                cancel_token,
                print_mode,
                deletion_status
            ) VALUES ($1, $2, $3, $4, $5, 'queued', $6, $7, 'captured', $8, $9, $10, $11, 'active')
            RETURNING *`,
            [
                order_id,
                customer_id,
                shop_id,
                JSON.stringify(files),
                JSON.stringify(print_options),
                queue_position,
                amount_total,
                targetPaymentId,
                print_instructions,
                cancelToken,
                print_mode || 'secure'
            ]
        );

        await client.query('COMMIT');

        return res.status(201).json({
            message: 'Guest order created successfully',
            order: result.rows[0],
            cancel_token: cancelToken
        });

    } catch (err) {
        await client.query('ROLLBACK');
        console.error('DB insert error:', err);
        if (err.code === '23505') {
            return res.status(409).json({ error: 'Duplicate order or payment ID already in use' });
        }
        if (err.code === '23503') {
            return res.status(400).json({ error: 'Invalid customer_id or shop_id' });
        }
        return res.status(500).json({ error: 'Failed to create guest order' });
    } finally {
        client.release();
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
        print_instructions = null,
        print_mode = 'normal'
    } = value;

    const targetPaymentId = razorpay_payment_id || payment_id;

    if (!targetPaymentId) {
        return res.status(400).json({ error: 'Payment ID is required to create a print order' });
    }

    const client = await pool.connect();
    try {
        await client.query('BEGIN');

        // 1. Verify payment exists and has been captured
        const paymentCheck = await client.query(
            "SELECT payment_id, razorpay_order_id, razorpay_payment_id, amount, status, created_at FROM payments WHERE razorpay_payment_id = $1 AND status = 'captured'",
            [targetPaymentId]
        );

        if (paymentCheck.rows.length === 0) {
            await client.query('ROLLBACK');
            return res.status(400).json({ error: 'Invalid or uncaptured payment. Order cannot be created.' });
        }

        // 2. Prevent Double-Spending: Check if payment has already been associated with an order
        const existingUsage = await client.query(
            `SELECT 1 FROM orders WHERE payment_id = $1
             UNION ALL
             SELECT 1 FROM product_orders WHERE payment_id = $1`,
            [targetPaymentId]
        );

        if (existingUsage.rows.length > 0) {
            await client.query('ROLLBACK');
            return res.status(409).json({ error: 'This payment has already been associated with an existing order.' });
        }

        // 3. Validate Server-Side Pricing
        const { minRequiredAmount } = await calculatePrintSubtotal(client, shop_id, files);
        if (parseFloat(amount_total) < minRequiredAmount) {
            await client.query('ROLLBACK');
            return res.status(400).json({
                error: `Order amount insufficient. Minimum required ₹${minRequiredAmount}, received ₹${amount_total}`
            });
        }

        const recordedPaid = parseFloat(paymentCheck.rows[0].amount);
        if (recordedPaid < minRequiredAmount) {
            await client.query('ROLLBACK');
            return res.status(400).json({
                error: `Attached payment amount ₹${recordedPaid} is less than required print cost ₹${minRequiredAmount}`
            });
        }

        // 4. Get current queue position for this shop
        let queue_position = null;
        const queueResult = await client.query(
            `SELECT COUNT(*) FROM orders 
             WHERE shop_id = $1 AND status = 'queued'`,
            [shop_id]
        );
        queue_position = parseInt(queueResult.rows[0].count) + 1;

        // 5. Insert order into DB
        const result = await client.query(
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
                print_instructions,
                print_mode,
                deletion_status
            ) VALUES ($1, $2, $3, $4, 'queued', $5, $6, 'captured', $7, $8, $9, 'active')
            RETURNING *`,
            [
                req.user.user_id,
                shop_id,
                JSON.stringify(files),
                JSON.stringify(print_options),
                queue_position,
                amount_total,
                targetPaymentId,
                print_instructions,
                print_mode || 'secure'
            ]
        );

        await client.query('COMMIT');

        return res.status(201).json({
            message: 'Order created successfully',
            order: result.rows[0]
        });

    } catch (err) {
        await client.query('ROLLBACK');
        console.error('DB insert error:', err);
        if (err.code === '23505') {
            return res.status(409).json({ error: 'This payment has already been used for an existing order.' });
        }
        if (err.code === '23503') {
            return res.status(400).json({ error: 'Invalid customer_id or shop_id' });
        }
        return res.status(500).json({ error: 'Failed to create order' });
    } finally {
        client.release();
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
                'SELECT order_id, customer_id, shop_id, files, print_options, status, queue_position, amount_total, payment_status, created_at, updated_at, completed_at, files_deleted, cancelled_at, payment_id, pickup_qr, print_instructions, refund_status, refund_id, print_mode, files_deleted_at, deletion_status, secure_expires_at FROM orders WHERE customer_id = $1 ORDER BY created_at DESC LIMIT $2 OFFSET $3',
                [req.user.user_id, limit, offset]
            );
            countResult = await pool.query('SELECT COUNT(*) FROM orders WHERE customer_id = $1', [req.user.user_id]);
        } else if (req.user.role === 'shopkeeper') {
            const shopResult = await pool.query('SELECT shop_id FROM shops WHERE owner_id = $1', [req.user.user_id]);
            const shopId = shopResult.rows[0]?.shop_id;
            if (!shopId) {
                return res.json({ data: [], pagination: { page, limit, total_items: 0, total_pages: 0 } });
            }
            result = await pool.query(
                'SELECT order_id, customer_id, shop_id, files, print_options, status, queue_position, amount_total, payment_status, created_at, updated_at, completed_at, files_deleted, cancelled_at, payment_id, pickup_qr, print_instructions, refund_status, refund_id, print_mode, files_deleted_at, deletion_status, secure_expires_at FROM orders WHERE shop_id = $1 ORDER BY created_at DESC LIMIT $2 OFFSET $3',
                [shopId, limit, offset]
            );
            countResult = await pool.query('SELECT COUNT(*) FROM orders WHERE shop_id = $1', [shopId]);
        } else if (req.user.role === 'admin') {
            result = await pool.query(
                'SELECT order_id, customer_id, shop_id, files, print_options, status, queue_position, amount_total, payment_status, created_at, updated_at, completed_at, files_deleted, cancelled_at, payment_id, pickup_qr, print_instructions, refund_status, refund_id, print_mode, files_deleted_at, deletion_status, secure_expires_at FROM orders ORDER BY created_at DESC LIMIT $1 OFFSET $2',
                [limit, offset]
            );
            countResult = await pool.query('SELECT COUNT(*) FROM orders');
        } else {
            return res.status(403).json({ error: 'Forbidden' });
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
 * @desc    Fetch a single order (Ownership verified)
 * @access  Private (Both Customer and Shop)
 */
router.get('/:id', async (req, res) => {
    const { id } = req.params;

    try {
        const result = await pool.query(
            'SELECT order_id, customer_id, shop_id, files, print_options, status, queue_position, amount_total, payment_status, created_at, updated_at, completed_at, files_deleted, cancelled_at, payment_id, pickup_qr, print_instructions, refund_status, refund_id, print_mode, files_deleted_at, deletion_status, secure_expires_at FROM orders WHERE order_id = $1',
            [id]
        );

        if (result.rows.length === 0) {
            return res.status(404).json({ error: 'Order not found' });
        }

        const order = result.rows[0];

        // Strict Ownership Authorization
        if (req.user.role === 'customer' && order.customer_id !== req.user.user_id) {
            return res.status(403).json({ error: 'Unauthorized to view this order' });
        } else if (req.user.role === 'shopkeeper') {
            const shopResult = await pool.query('SELECT shop_id FROM shops WHERE owner_id = $1', [req.user.user_id]);
            const shopId = shopResult.rows[0]?.shop_id;
            if (!shopId || order.shop_id !== shopId) {
                return res.status(403).json({ error: 'Unauthorized to view this order' });
            }
        }

        res.json(order);

    } catch (err) {
        console.error('DB fetch error:', err);
        res.status(500).json({ error: 'Failed to fetch order' });
    }
});

/**
 * @route   PATCH /api/orders/:id/status
 * @desc    Update order status (Shopkeeper & Admin only)
 * @access  Private
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
        // Fetch order to verify existence and shop ownership
        const orderResult = await pool.query('SELECT shop_id FROM orders WHERE order_id = $1', [id]);
        if (orderResult.rows.length === 0) {
            return res.status(404).json({ error: 'Order not found' });
        }

        const order = orderResult.rows[0];

        // Authorization: Only the shop owner or an admin can update order status
        if (req.user.role === 'shopkeeper') {
            const shopResult = await pool.query('SELECT shop_id FROM shops WHERE owner_id = $1', [req.user.user_id]);
            const shopId = shopResult.rows[0]?.shop_id;
            if (!shopId || order.shop_id !== shopId) {
                return res.status(403).json({ error: 'Unauthorized: Order belongs to another shop' });
            }
        } else if (req.user.role !== 'admin') {
            return res.status(403).json({ error: 'Forbidden: Customers cannot update order status' });
        }

        const result = await pool.query(
            `UPDATE orders 
             SET status = $1::order_status,
                 completed_at = CASE WHEN $1::text = 'collected' OR $1::text = 'cancelled' THEN NOW() ELSE completed_at END,
                 secure_expires_at = CASE WHEN $1::text = 'cancelled' AND print_mode = 'secure' THEN NOW() + INTERVAL '15 minutes' ELSE secure_expires_at END
             WHERE order_id = $2
             RETURNING *`,
            [status, id]
        );

        if (result.rows.length === 0) {
            return res.status(404).json({ error: 'Order not found' });
        }

        if (status === 'collected' && result.rows[0].print_mode === 'secure') {
            deleteOrderFilesImmediately(id);
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

        if (order.refund_status === 'wallet_refunded' || order.payment_status === 'refunded') {
            await client.query('ROLLBACK');
            return res.status(400).json({ error: 'This order has already been refunded.' });
        }

        if (order.payment_status === 'captured') {
            try {
                // Prevent Cancellation Arbitrage: Refund amount cannot exceed verified payment record
                let verifiedPaidAmount = parseFloat(order.amount_total);

                if (order.payment_id) {
                    if (order.payment_id.startsWith('wt_')) {
                        // Paid via wallet
                        const txId = parseInt(order.payment_id.replace('wt_', ''), 10);
                        if (!isNaN(txId)) {
                            const wtRes = await client.query(
                                "SELECT amount FROM wallet_transactions WHERE id = $1 AND user_id = $2 AND type IN ('order_payment', 'payment', 'topup')",
                                [txId, req.user.user_id]
                            );
                            if (wtRes.rows.length > 0) {
                                verifiedPaidAmount = Math.min(verifiedPaidAmount, Math.abs(parseFloat(wtRes.rows[0].amount)));
                            }
                        }
                    } else {
                        // Paid via Razorpay - verify against actual captured payment record
                        const payRes = await client.query(
                            "SELECT amount FROM payments WHERE razorpay_payment_id = $1 AND status = 'captured'",
                            [order.payment_id]
                        );
                        if (payRes.rows.length > 0) {
                            verifiedPaidAmount = Math.min(verifiedPaidAmount, parseFloat(payRes.rows[0].amount));
                        }
                    }
                }

                if (isNaN(verifiedPaidAmount) || verifiedPaidAmount <= 0) {
                    throw new Error('Invalid refund amount calculation');
                }

                // Refund to Wallet using verifiedPaidAmount
                const userUpdate = await client.query(
                    `UPDATE users 
                     SET wallet_balance = wallet_balance + $1 
                     WHERE user_id = $2 
                     RETURNING wallet_balance`,
                    [verifiedPaidAmount, req.user.user_id]
                );

                const txResult = await client.query(
                    `INSERT INTO wallet_transactions (user_id, amount, type, reference_id)
                     VALUES ($1, $2, 'refund', $3)
                     RETURNING id`,
                    [req.user.user_id, verifiedPaidAmount, order.order_id]
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
                 payment_status = $3,
                 secure_expires_at = CASE WHEN print_mode = 'secure' THEN NOW() + INTERVAL '15 minutes' ELSE secure_expires_at END
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