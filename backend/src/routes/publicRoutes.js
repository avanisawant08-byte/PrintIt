const express = require('express');
const router = express.Router();
const pool = require('../config/db');
const getRazorpay = require('../config/razorpay');

/**
 * @route   GET /api/public/shops
 * @desc    Get all shops with their pricing info (public, no auth needed)
 * @access  Public
 */
router.get('/shops', async (req, res) => {
    try {
        const { capability } = req.query;

        let shopsQuery = `
             SELECT 
                 s.shop_id, s.owner_id, s.name, s.address, s.price_bw, s.price_color, s.is_open, s.opening_time, s.closing_time,
                 COALESCE(
                     (SELECT json_agg(
                         json_build_object(
                             'color', sp.color,
                             'size', sp.size,
                             'sides', sp.sides,
                             'price_per_page', sp.price_per_page,
                             'binding_staple_price', sp.binding_staple_price,
                             'binding_spiral_price', sp.binding_spiral_price
                         )
                     ) FROM shop_pricing sp WHERE sp.shop_id = s.shop_id), 
                     '[]'::json
                 ) AS pricing_rules,
                 COALESCE(
                     (SELECT json_agg(sc.capability) FROM shop_capabilities sc WHERE sc.shop_id = s.shop_id), 
                     '[]'::json
                 ) AS capabilities
             FROM shops s
             WHERE s.is_active = true
        `;
        const queryParams = [];

        if (capability) {
            shopsQuery = `
                 SELECT 
                     s.shop_id, s.owner_id, s.name, s.address, s.price_bw, s.price_color, s.is_open, s.opening_time, s.closing_time,
                     COALESCE(
                         (SELECT json_agg(
                             json_build_object(
                                 'color', sp.color,
                                 'size', sp.size,
                                 'sides', sp.sides,
                                 'price_per_page', sp.price_per_page,
                                 'binding_staple_price', sp.binding_staple_price,
                                 'binding_spiral_price', sp.binding_spiral_price
                             )
                         ) FROM shop_pricing sp WHERE sp.shop_id = s.shop_id), 
                         '[]'::json
                     ) AS pricing_rules,
                     COALESCE(
                         (SELECT json_agg(sc2.capability) FROM shop_capabilities sc2 WHERE sc2.shop_id = s.shop_id), 
                         '[]'::json
                     ) AS capabilities
                 FROM shops s
                 JOIN shop_capabilities sc ON s.shop_id = sc.shop_id
                 WHERE s.is_active = true AND sc.capability = $1
            `;
            queryParams.push(capability);
        }

        shopsQuery += ` ORDER BY s.name ASC`;

        const shopsResult = await pool.query(shopsQuery, queryParams);
        const shops = shopsResult.rows;

        res.json(shops);
    } catch (err) {
        console.error('Error fetching shops:', err);
        res.status(500).json({ error: 'Failed to fetch shops' });
    }
});

/**
 * @route   GET /api/public/shops/:shop_id
 * @desc    Get full details of a specific shop
 * @access  Public
 */
router.get('/shops/:shop_id', async (req, res) => {
    try {
        const { shop_id } = req.params;

        const shopResult = await pool.query(
            `SELECT 
                 s.shop_id, s.owner_id, s.name, s.address, s.phone, s.price_bw, s.price_color, s.is_open, s.opening_time, s.closing_time, s.is_active,
                 COALESCE(
                     (SELECT json_agg(
                         json_build_object(
                             'color', sp.color,
                             'size', sp.size,
                             'sides', sp.sides,
                             'price_per_page', sp.price_per_page,
                             'binding_staple_price', sp.binding_staple_price,
                             'binding_spiral_price', sp.binding_spiral_price
                         )
                     ) FROM shop_pricing sp WHERE sp.shop_id = s.shop_id), 
                     '[]'::json
                 ) AS pricing_rules,
                 COALESCE(
                     (SELECT json_agg(sc.capability) FROM shop_capabilities sc WHERE sc.shop_id = s.shop_id), 
                     '[]'::json
                 ) AS capabilities
             FROM shops s
             WHERE s.shop_id = $1`,
            [shop_id]
        );

        if (shopResult.rows.length === 0) {
            return res.status(404).json({ error: 'Shop not found' });
        }

        const shop = shopResult.rows[0];

        res.json(shop);
    } catch (err) {
        console.error('Error fetching shop detail:', err);
        res.status(500).json({ error: 'Failed to fetch shop details' });
    }
});

/**
 * @route   GET /api/public/capabilities
 * @desc    Get master list of capabilities
 * @access  Public
 */
router.get('/capabilities', (req, res) => {
    const capabilities = [
        { id: 'books', name: 'Books', description: 'Book printing, perfect binding', icon: 'book' },
        { id: 'spiral_binding', name: 'Spiral Binding', description: 'Spiral/comb binding', icon: 'library_books' },
        { id: 'lamination', name: 'Lamination', description: 'Lamination services', icon: 'layers' },
        { id: 'large_format', name: 'Large Format', description: 'A3, banners, posters', icon: 'map' },
        { id: 'id_cards', name: 'ID Cards', description: 'PVC/paper ID cards', icon: 'badge' },
        { id: 'notebooks', name: 'Notebooks', description: 'Custom notebooks', icon: 'import_contacts' },
        { id: 'bulk_printing', name: 'Bulk Printing', description: 'High volume orders', icon: 'print' },
        { id: 'same_day', name: 'Same Day', description: 'Same day delivery/pickup', icon: 'flash_on' },
    ];
    res.json(capabilities);
});

/**
 * @route   GET /api/public/orders/:id
 * @desc    Get order details by UUID (public for tracking)
 * @access  Public
 */
router.get('/orders/:id', async (req, res) => {
    try {
        const { id } = req.params;
        const result = await pool.query(
            `SELECT order_id, shop_id, status, queue_position, amount_total, payment_status, created_at, files
             FROM orders
             WHERE order_id = $1`,
            [id]
        );

        if (result.rows.length === 0) {
            return res.status(404).json({ error: 'Order not found' });
        }

        res.json(result.rows[0]);
    } catch (err) {
        console.error('Error fetching public order:', err);
        res.status(500).json({ error: 'Failed to fetch order details' });
    }
});

/**
 * @route   PATCH /api/public/orders/:id/cancel
 * @desc    Cancel a guest order and trigger refund
 * @access  Public
 */
router.patch('/orders/:id/cancel', async (req, res) => {
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

        if (order.customer_id !== null) {
            await client.query('ROLLBACK');
            return res.status(403).json({ error: 'This is an authenticated order, please log in to cancel.' });
        }

        if (order.status !== 'queued') {
            await client.query('ROLLBACK');
            return res.status(400).json({ error: 'Order already in progress, cannot cancel' });
        }

        // 2. Trigger Razorpay Refund
        let refundStatus = null;
        let refundId = null;
        let paymentStatus = order.payment_status;

        if (order.payment_id && order.payment_status === 'captured') {
            try {
                // Refund full amount
                const refund = await getRazorpay().payments.refund(order.payment_id);
                refundStatus = 'success';
                refundId = refund.id;
                paymentStatus = 'refunded';
            } catch (refundError) {
                console.error('Razorpay guest refund failed:', refundError);
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
        console.error('Guest order cancellation error:', err);
        return res.status(500).json({ error: 'Failed to cancel order' });
    } finally {
        client.release();
    }
});

module.exports = router;
