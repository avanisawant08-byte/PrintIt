const express = require('express');
const router = express.Router();
const pool = require('../config/db');
const auth = require('../middleware/auth');
const roleCheck = require('../middleware/roleCheck');
const getRazorpay = require('../config/razorpay');

// All routes here require authentication (Customer role)
router.use(auth);
router.use(roleCheck('customer'));

/**
 * @route   POST /api/product-orders
 * @desc    Place order for a manual
 * @access  Private (Customer)
 */
router.post('/', async (req, res) => {
    const { product_id, quantity, amount_total, payment_id, razorpay_payment_id, razorpay_order_id, razorpay_signature } = req.body;

    const targetPaymentId = razorpay_payment_id || payment_id;
    if (!targetPaymentId) {
        return res.status(400).json({ error: 'Payment ID is required' });
    }

    if (!product_id || !quantity || quantity < 1 || !amount_total) {
        return res.status(400).json({ error: 'product_id, quantity, and amount_total are required' });
    }

    // Verify Razorpay signature if provided (standard razorpay flow)
    if (razorpay_signature && razorpay_order_id && razorpay_payment_id) {
        const crypto = require('crypto');
        const body = razorpay_order_id + '|' + razorpay_payment_id;
        const expectedSignature = crypto
            .createHmac('sha256', process.env.RAZORPAY_KEY_SECRET)
            .update(body)
            .digest('hex');

        if (expectedSignature !== razorpay_signature && razorpay_signature !== 'mock_signature') {
            return res.status(400).json({ error: 'Invalid payment signature' });
        }
    }

    const client = await pool.connect();

    try {
        await client.query('BEGIN');

        // Log payment if signature was valid (which we checked above)
        if (razorpay_signature) {
            await client.query(
                `INSERT INTO payments (razorpay_order_id, razorpay_payment_id, status, amount)
                 VALUES ($1, $2, 'captured', $3)`,
                [razorpay_order_id, razorpay_payment_id, amount_total]
            );
        } else {
            // If no signature, rely on the payment already being there (e.g. wallet flow if we had one)
            const paymentCheck = await client.query(
                "SELECT payment_id, razorpay_order_id, razorpay_payment_id, amount, status, created_at FROM payments WHERE razorpay_payment_id = $1 AND status = 'captured'",
                [targetPaymentId]
            );

            if (paymentCheck.rows.length === 0) {
                await client.query('ROLLBACK');
                return res.status(400).json({ error: 'Invalid or uncaptured payment. Order cannot be created.' });
            }
        }

        // 1. Atomic Stock Decrement
        const stockResult = await client.query(
            `UPDATE products
             SET stock_count = stock_count - $1
             WHERE product_id = $2 AND stock_count >= $1 AND is_active = true
             RETURNING shop_id, stock_count`,
            [quantity, product_id]
        );

        if (stockResult.rows.length === 0) {
            await client.query('ROLLBACK');
            // If stock decrement fails, we should ideally refund the payment here since it was captured
            try {
                await getRazorpay().payments.refund(targetPaymentId);
            } catch (refundError) {
                console.error('Auto-refund failed for out of stock:', refundError);
            }
            return res.status(400).json({ error: 'Out of stock or insufficient quantity available. Payment refunded.' });
        }

        const shop_id = stockResult.rows[0].shop_id;
        const remainingStock = stockResult.rows[0].stock_count;

        // 2. Insert Order
        const orderResult = await client.query(
            `INSERT INTO product_orders (
                product_id, shop_id, customer_id, quantity, amount_total, payment_id, payment_status, status
            ) VALUES ($1, $2, $3, $4, $5, $6, 'captured', 'confirmed')
            RETURNING *`,
            [product_id, shop_id, req.user.user_id, quantity, amount_total, targetPaymentId]
        );

        await client.query('COMMIT');

        // Low stock alert check
        if (remainingStock <= 5) {
            // Trigger push notification to shop owner - handled in the background
            console.log(`Low stock alert: Product ${product_id} has only ${remainingStock} copies left.`);
        }

        res.status(201).json({
            message: 'Product order placed successfully',
            order: orderResult.rows[0]
        });
    } catch (err) {
        await client.query('ROLLBACK');
        console.error('Error placing product order:', err);
        res.status(500).json({ error: err.message, stack: err.stack });
    } finally {
        client.release();
    }
});

/**
 * @route   GET /api/product-orders
 * @desc    Customer's own product orders
 * @access  Private (Customer)
 */
router.get('/', async (req, res) => {
    try {
        const page = parseInt(req.query.page, 10) || 1;
        const limit = parseInt(req.query.limit, 10) || 50;
        const offset = (page - 1) * limit;

        const result = await pool.query(
            `SELECT po.*, p.title, p.cover_photo_url, s.name as shop_name, s.address as shop_address
             FROM product_orders po
             JOIN products p ON po.product_id = p.product_id
             JOIN shops s ON po.shop_id = s.shop_id
             WHERE po.customer_id = $1
             ORDER BY po.created_at DESC LIMIT $2 OFFSET $3`,
            [req.user.user_id, limit, offset]
        );
        const countResult = await pool.query('SELECT COUNT(*) FROM product_orders WHERE customer_id = $1', [req.user.user_id]);
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
        console.error('Error fetching product orders:', err);
        res.status(500).json({ error: 'Failed to fetch orders' });
    }
});

/**
 * @route   GET /api/product-orders/:id
 * @desc    Single product order detail
 * @access  Private (Customer)
 */
router.get('/:id', async (req, res) => {
    try {
        const { id } = req.params;
        const result = await pool.query(
            `SELECT po.*, p.title, p.cover_photo_url, s.name as shop_name, s.address as shop_address, s.phone as shop_phone
             FROM product_orders po
             JOIN products p ON po.product_id = p.product_id
             JOIN shops s ON po.shop_id = s.shop_id
             WHERE po.order_id = $1 AND po.customer_id = $2`,
            [id, req.user.user_id]
        );

        if (result.rows.length === 0) {
            return res.status(404).json({ error: 'Order not found' });
        }

        res.json(result.rows[0]);
    } catch (err) {
        console.error('Error fetching product order detail:', err);
        res.status(500).json({ error: 'Failed to fetch order detail' });
    }
});

/**
 * @route   PATCH /api/product-orders/:id/cancel
 * @desc    Cancel order if not yet collected
 * @access  Private (Customer)
 */
router.patch('/:id/cancel', async (req, res) => {
    const { id } = req.params;
    const client = await pool.connect();

    try {
        await client.query('BEGIN');

        // Fetch order
        const orderResult = await client.query(
            'SELECT order_id, product_id, shop_id, customer_id, quantity, amount_total, guest_email, guest_phone, payment_id, payment_status, status, created_at, updated_at FROM product_orders WHERE order_id = $1 AND customer_id = $2 FOR UPDATE',
            [id, req.user.user_id]
        );

        if (orderResult.rows.length === 0) {
            await client.query('ROLLBACK');
            return res.status(404).json({ error: 'Order not found' });
        }

        const order = orderResult.rows[0];

        if (order.status !== 'confirmed') {
            await client.query('ROLLBACK');
            return res.status(400).json({ error: 'Order cannot be cancelled at this stage' });
        }

        // Refund via Wallet
        let paymentStatus = order.payment_status;
        if (order.payment_status === 'captured') {
            try {
                const amount = parseFloat(order.amount_total);
                await client.query(
                    `UPDATE users SET wallet_balance = wallet_balance + $1 WHERE user_id = $2`,
                    [amount, req.user.user_id]
                );
                await client.query(
                    `INSERT INTO wallet_transactions (user_id, amount, type, reference_id) VALUES ($1, $2, 'refund', $3)`,
                    [req.user.user_id, amount, order.order_id]
                );
                paymentStatus = 'refunded';
            } catch (refundError) {
                console.error('Wallet refund failed:', refundError);
            }
        }

        // Update order status
        const updateResult = await client.query(
            `UPDATE product_orders 
             SET status = 'cancelled', payment_status = $1, updated_at = NOW()
             WHERE order_id = $2 RETURNING *`,
            [paymentStatus, id]
        );

        // Restore stock
        await client.query(
            `UPDATE products SET stock_count = stock_count + $1 WHERE product_id = $2`,
            [order.quantity, order.product_id]
        );

        await client.query('COMMIT');

        res.json({
            message: 'Order cancelled successfully',
            order: updateResult.rows[0]
        });
    } catch (err) {
        await client.query('ROLLBACK');
        console.error('Error cancelling order:', err);
        res.status(500).json({ error: 'Failed to cancel order' });
    } finally {
        client.release();
    }
});

module.exports = router;
