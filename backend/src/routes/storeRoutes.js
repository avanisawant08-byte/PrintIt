const express = require('express');
const router = express.Router();
const crypto = require('crypto');
const pool = require('../config/db');
const auth = require('../middleware/auth');

/**
 * @route   GET /api/store/categories
 * @desc    Get master product categories
 * @access  Public
 */
router.get('/categories', async (req, res) => {
    try {
        const defaultCategories = ['All', 'Books', 'Manuals', 'Notes', 'Forms', 'Other'];
        res.json(defaultCategories);
    } catch (err) {
        console.error('Error fetching categories:', err);
        res.status(500).json({ error: 'Failed to fetch categories' });
    }
});

/**
 * @route   GET /api/store/products
 * @desc    Get catalog products with filters, search, and aggregated pricing
 * @access  Public
 */
router.get('/products', async (req, res) => {
    try {
        const { category, branch, course_type, semester, search } = req.query;

        let query = `
            SELECT 
                p.*,
                COALESCE(MIN(i.price) FILTER (WHERE i.stock_count > 0 AND i.is_available = true), 0) AS min_price,
                COALESCE(MAX(i.price) FILTER (WHERE i.stock_count > 0 AND i.is_available = true), 0) AS max_price,
                COUNT(DISTINCT i.shop_id) FILTER (WHERE i.stock_count > 0 AND i.is_available = true) AS shops_count,
                COALESCE(SUM(i.stock_count) FILTER (WHERE i.is_available = true), 0) AS total_stock
            FROM product_catalog p
            LEFT JOIN shop_inventory i ON p.product_id = i.product_id
            WHERE p.is_active = true
        `;

        const params = [];
        let paramIndex = 1;

        if (category && category !== 'All') {
            query += ` AND p.category ILIKE $${paramIndex++}`;
            params.push(category);
        }

        if (branch && branch !== 'All') {
            query += ` AND p.branch ILIKE $${paramIndex++}`;
            params.push(`%${branch}%`);
        }

        if (course_type && course_type !== 'All') {
            query += ` AND p.course_type ILIKE $${paramIndex++}`;
            params.push(`%${course_type}%`);
        }

        if (semester && semester !== 'All') {
            query += ` AND p.semester ILIKE $${paramIndex++}`;
            params.push(`%${semester}%`);
        }

        if (search && search.trim()) {
            query += ` AND (p.title ILIKE $${paramIndex} OR p.subject ILIKE $${paramIndex} OR p.author ILIKE $${paramIndex})`;
            params.push(`%${search.trim()}%`);
            paramIndex++;
        }

        query += ` GROUP BY p.product_id ORDER BY p.created_at DESC`;

        const result = await pool.query(query, params);
        res.json(result.rows);
    } catch (err) {
        console.error('Error fetching store products:', err);
        res.status(500).json({ error: 'Failed to fetch store products' });
    }
});

/**
 * @route   GET /api/store/products/:id
 * @desc    Get master product details
 * @access  Public
 */
router.get('/products/:id', async (req, res) => {
    try {
        const { id } = req.params;
        const result = await pool.query(
            `SELECT p.*,
                COALESCE(MIN(i.price) FILTER (WHERE i.stock_count > 0 AND i.is_available = true), 0) AS min_price,
                COUNT(DISTINCT i.shop_id) FILTER (WHERE i.stock_count > 0 AND i.is_available = true) AS shops_count
             FROM product_catalog p
             LEFT JOIN shop_inventory i ON p.product_id = i.product_id
             WHERE p.product_id = $1 AND p.is_active = true
             GROUP BY p.product_id`,
            [id]
        );

        if (result.rows.length === 0) {
            return res.status(404).json({ error: 'Product not found' });
        }

        res.json(result.rows[0]);
    } catch (err) {
        console.error('Error fetching product detail:', err);
        res.status(500).json({ error: 'Failed to fetch product details' });
    }
});

/**
 * @route   GET /api/store/products/:id/shops
 * @desc    Get all shops stocking a specific product with price and stock status
 * @access  Public
 */
router.get('/products/:id/shops', async (req, res) => {
    try {
        const { id } = req.params;
        const result = await pool.query(
            `SELECT 
                i.inventory_id,
                i.price,
                i.stock_count,
                i.is_available,
                s.shop_id,
                s.name AS shop_name,
                s.shop_code,
                s.address AS shop_address,
                s.phone AS shop_phone,
                s.is_open AS shop_is_open,
                CASE 
                    WHEN i.stock_count <= 0 THEN 'out_of_stock'
                    WHEN i.stock_count BETWEEN 1 AND 5 THEN 'only_n_left'
                    ELSE 'in_stock'
                END AS stock_status
             FROM shop_inventory i
             JOIN shops s ON i.shop_id = s.shop_id
             WHERE i.product_id = $1 AND s.is_active = true AND i.is_available = true
             ORDER BY i.price ASC, i.stock_count DESC`,
            [id]
        );

        res.json(result.rows);
    } catch (err) {
        console.error('Error fetching stocking shops:', err);
        res.status(500).json({ error: 'Failed to fetch stocking shops' });
    }
});

/**
 * @route   GET /api/store/shops/:shop_id/products
 * @desc    Get other products available at a specific shop (for "More from this shop" suggestions)
 * @access  Public
 */
router.get('/shops/:shop_id/products', async (req, res) => {
    try {
        const { shop_id } = req.params;
        const excludeProductId = req.query.exclude_product_id;

        let query = `
            SELECT 
                i.inventory_id,
                i.price,
                i.stock_count,
                p.product_id,
                p.title,
                p.category,
                p.branch,
                p.semester,
                p.subject,
                p.author,
                p.cover_photo_url
            FROM shop_inventory i
            JOIN product_catalog p ON i.product_id = p.product_id
            WHERE i.shop_id = $1 AND i.is_available = true AND i.stock_count > 0 AND p.is_active = true
        `;
        const params = [shop_id];

        if (excludeProductId) {
            query += ` AND p.product_id != $2`;
            params.push(excludeProductId);
        }

        query += ` ORDER BY i.stock_count DESC LIMIT 12`;

        const result = await pool.query(query, params);
        res.json(result.rows);
    } catch (err) {
        console.error('Error fetching shop recommendations:', err);
        res.status(500).json({ error: 'Failed to fetch recommendations for this shop' });
    }
});

/**
 * @route   POST /api/store/orders
 * @desc    Prepaid Store Cart Checkout (Wallet or Razorpay — STRICTLY NO COD)
 * @access  Public (Guest or Customer Auth)
 */
router.post('/orders', async (req, res) => {
    const {
        shop_id,
        items,
        payment_method, // 'wallet' or 'razorpay'
        razorpay_payment_id,
        razorpay_order_id,
        razorpay_signature,
        guest_email,
        guest_phone
    } = req.body;

    // 1. Strict COD Prohibition
    if (!payment_method || payment_method.toLowerCase() === 'cod' || payment_method.toLowerCase() === 'cash_on_delivery') {
        return res.status(400).json({
            error: 'Cash on Delivery is not supported. All store pickup orders must be prepaid via Wallet or Razorpay.'
        });
    }

    if (!shop_id) {
        return res.status(400).json({ error: 'Shop ID is required' });
    }

    if (!items || !Array.isArray(items) || items.length === 0) {
        return res.status(400).json({ error: 'Cart is empty. Please add items to checkout.' });
    }

    // Determine customer ID if authenticated
    let customer_id = null;
    if (req.headers.authorization) {
        try {
            const token = req.headers.authorization.split(' ')[1];
            const decoded = require('jsonwebtoken').verify(token, process.env.JWT_SECRET);
            customer_id = decoded.user_id;
        } catch (_) {}
    }

    if (!customer_id && !guest_email && !guest_phone) {
        return res.status(400).json({ error: 'Please sign in or provide contact details for your pickup receipt.' });
    }

    const client = await pool.connect();

    try {
        await client.query('BEGIN');

        let computedTotal = 0;
        const verifiedItems = [];

        // 2. Validate and atomically decrement stock for all items
        for (const item of items) {
            const qty = parseInt(item.quantity, 10) || 1;
            if (qty <= 0) {
                await client.query('ROLLBACK');
                return res.status(400).json({ error: 'Invalid item quantity' });
            }

            // Lock inventory row & verify ownership
            const invResult = await client.query(
                `SELECT i.inventory_id, i.price, i.stock_count, p.product_id, p.title
                 FROM shop_inventory i
                 JOIN product_catalog p ON i.product_id = p.product_id
                 WHERE i.inventory_id = $1 AND i.shop_id = $2
                 FOR UPDATE`,
                [item.inventory_id, shop_id]
            );

            if (invResult.rows.length === 0) {
                await client.query('ROLLBACK');
                return res.status(400).json({ error: 'One or more items do not belong to the selected shop.' });
            }

            const inv = invResult.rows[0];

            // Atomic decrement: ensure stock is sufficient
            const decResult = await client.query(
                `UPDATE shop_inventory
                 SET stock_count = stock_count - $1, updated_at = NOW()
                 WHERE inventory_id = $2 AND stock_count >= $1
                 RETURNING stock_count`,
                [qty, item.inventory_id]
            );

            if (decResult.rows.length === 0) {
                await client.query('ROLLBACK');
                return res.status(409).json({
                    error: `Insufficient stock for "${inv.title}". Available copies: ${inv.stock_count}. Please adjust your cart.`
                });
            }

            const unitPrice = parseFloat(inv.price);
            const subtotal = unitPrice * qty;
            computedTotal += subtotal;

            verifiedItems.push({
                inventory_id: inv.inventory_id,
                product_id: inv.product_id,
                title: inv.title,
                quantity: qty,
                unit_price: unitPrice,
                subtotal
            });
        }

        // 3. Process Prepaid Payment
        if (payment_method === 'wallet') {
            if (!customer_id) {
                await client.query('ROLLBACK');
                return res.status(401).json({ error: 'Wallet payment requires an authenticated account.' });
            }

            const walletRes = await client.query(
                'SELECT wallet_balance FROM users WHERE user_id = $1 FOR UPDATE',
                [customer_id]
            );

            if (walletRes.rows.length === 0) {
                await client.query('ROLLBACK');
                return res.status(404).json({ error: 'User account not found.' });
            }

            const currentBalance = parseFloat(walletRes.rows[0].wallet_balance || 0);
            if (currentBalance < computedTotal) {
                await client.query('ROLLBACK');
                return res.status(400).json({
                    error: `Insufficient wallet balance (₹${currentBalance.toFixed(2)}). Need ₹${computedTotal.toFixed(2)}.`
                });
            }

            // Deduct customer wallet
            await client.query(
                'UPDATE users SET wallet_balance = wallet_balance - $1 WHERE user_id = $2',
                [computedTotal, customer_id]
            );
        } else if (payment_method === 'razorpay') {
            // Verify Razorpay signature if secret is available
            if (process.env.RAZORPAY_KEY_SECRET && razorpay_payment_id && razorpay_order_id && razorpay_signature) {
                const generatedSignature = crypto
                    .createHmac('sha256', process.env.RAZORPAY_KEY_SECRET)
                    .update(`${razorpay_order_id}|${razorpay_payment_id}`)
                    .digest('hex');

                if (generatedSignature !== razorpay_signature) {
                    await client.query('ROLLBACK');
                    return res.status(400).json({ error: 'Invalid Razorpay payment signature.' });
                }
            }
        }

        // 4. Generate Order Number & 4-Digit Pickup Code
        const orderNumber = 'STR-' + Date.now().toString(36).toUpperCase();
        const pickupCode = Math.floor(1000 + Math.random() * 9000).toString();

        // 5. Insert Master Store Order
        const orderResult = await client.query(
            `INSERT INTO store_orders (
                order_number, pickup_code, shop_id, customer_id, guest_email, guest_phone,
                total_amount, payment_method, payment_id, payment_status, status
            ) VALUES ($1, $2, $3, $4, $5, $6, $7, $8, $9, 'completed', 'confirmed')
            RETURNING *`,
            [
                orderNumber,
                pickupCode,
                shop_id,
                customer_id,
                guest_email || null,
                guest_phone || null,
                computedTotal,
                payment_method,
                razorpay_payment_id || `WAL-${Date.now()}`
            ]
        );

        const newOrder = orderResult.rows[0];

        // 6. Insert Line Items
        for (const item of verifiedItems) {
            await client.query(
                `INSERT INTO store_order_items (
                    order_id, inventory_id, product_id, title, quantity, unit_price, subtotal
                ) VALUES ($1, $2, $3, $4, $5, $6, $7)`,
                [
                    newOrder.order_id,
                    item.inventory_id,
                    item.product_id,
                    item.title,
                    item.quantity,
                    item.unit_price,
                    item.subtotal
                ]
            );
        }

        // 7. Credit Shop Wallet Pending Balance
        await client.query(`
            INSERT INTO shop_wallets (shop_id, pending_balance, total_earned, updated_at)
            VALUES ($1, $2, $2, NOW())
            ON CONFLICT (shop_id) DO UPDATE
            SET pending_balance = shop_wallets.pending_balance + $2,
                total_earned = shop_wallets.total_earned + $2,
                updated_at = NOW()
        `, [shop_id, computedTotal]);

        await client.query('COMMIT');

        res.status(201).json({
            message: 'Store order confirmed successfully!',
            order: {
                ...newOrder,
                items: verifiedItems
            }
        });
    } catch (err) {
        await client.query('ROLLBACK');
        console.error('Store order placement error:', err);
        res.status(500).json({ error: 'Failed to complete store order: ' + err.message });
    } finally {
        client.release();
    }
});

/**
 * @route   GET /api/store/orders
 * @desc    Get customer's store pickup orders
 * @access  Private (Customer)
 */
router.get('/orders', auth, async (req, res) => {
    try {
        const ordersResult = await pool.query(
            `SELECT 
                o.*,
                s.name AS shop_name,
                s.shop_code,
                s.address AS shop_address,
                s.phone AS shop_phone,
                COALESCE(
                    json_agg(
                        json_build_object(
                            'item_id', oi.item_id,
                            'title', oi.title,
                            'quantity', oi.quantity,
                            'unit_price', oi.unit_price,
                            'subtotal', oi.subtotal
                        )
                    ) FILTER (WHERE oi.item_id IS NOT NULL),
                    '[]'::json
                ) AS items
             FROM store_orders o
             JOIN shops s ON o.shop_id = s.shop_id
             LEFT JOIN store_order_items oi ON o.order_id = oi.order_id
             WHERE o.customer_id = $1
             GROUP BY o.order_id, s.name, s.shop_code, s.address, s.phone
             ORDER BY o.created_at DESC`,
            [req.user.user_id]
        );

        res.json(ordersResult.rows);
    } catch (err) {
        console.error('Error fetching store orders:', err);
        res.status(500).json({ error: 'Failed to fetch store orders' });
    }
});

/**
 * @route   PATCH /api/store/orders/:id/cancel
 * @desc    Cancel an uncollected store order, restore stock, and refund to wallet
 * @access  Private (Customer)
 */
router.patch('/orders/:id/cancel', auth, async (req, res) => {
    const { id } = req.params;
    const client = await pool.connect();

    try {
        await client.query('BEGIN');

        const orderRes = await client.query(
            `SELECT * FROM store_orders WHERE order_id = $1 AND customer_id = $2 FOR UPDATE`,
            [id, req.user.user_id]
        );

        if (orderRes.rows.length === 0) {
            await client.query('ROLLBACK');
            return res.status(404).json({ error: 'Order not found' });
        }

        const order = orderRes.rows[0];

        if (order.status !== 'confirmed') {
            await client.query('ROLLBACK');
            return res.status(400).json({ error: `Cannot cancel order in "${order.status}" status.` });
        }

        // Restore item stock
        const itemsRes = await client.query(
            `SELECT inventory_id, quantity FROM store_order_items WHERE order_id = $1`,
            [id]
        );

        for (const item of itemsRes.rows) {
            if (item.inventory_id) {
                await client.query(
                    `UPDATE shop_inventory SET stock_count = stock_count + $1, updated_at = NOW() WHERE inventory_id = $2`,
                    [item.quantity, item.inventory_id]
                );
            }
        }

        // Mark cancelled
        await client.query(
            `UPDATE store_orders SET status = 'cancelled', updated_at = NOW() WHERE order_id = $1`,
            [id]
        );

        // Refund to customer wallet
        await client.query(
            `UPDATE users SET wallet_balance = wallet_balance + $1 WHERE user_id = $2`,
            [order.total_amount, req.user.user_id]
        );

        // Deduct shop pending balance
        await client.query(`
            UPDATE shop_wallets 
            SET pending_balance = GREATEST(0, pending_balance - $1),
                total_earned = GREATEST(0, total_earned - $1),
                updated_at = NOW()
            WHERE shop_id = $2
        `, [order.total_amount, order.shop_id]);

        await client.query('COMMIT');
        res.json({ message: 'Order cancelled successfully and funds refunded to your wallet.' });
    } catch (err) {
        await client.query('ROLLBACK');
        console.error('Error cancelling store order:', err);
        res.status(500).json({ error: 'Failed to cancel store order' });
    } finally {
        client.release();
    }
});

module.exports = router;
