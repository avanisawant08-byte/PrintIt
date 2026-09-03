const express = require('express');
const router = express.Router();
const pool = require('../config/db');
const auth = require('../middleware/auth');
const shopCheck = require('../middleware/shopCheck');
const { getMessaging } = require('../config/firebase');

// All routes in this router require authentication and shop verification
router.use(auth);
router.use(shopCheck);

/**
 * @route   GET /api/shop/orders
 * @desc    Fetch all orders for this shop
 * @access  Private (Shop Owner Only)
 */
router.get('/orders', async (req, res) => {
    try {
        const page = parseInt(req.query.page, 10) || 1;
        const limit = parseInt(req.query.limit, 10) || 50;
        const offset = (page - 1) * limit;

        const result = await pool.query(
            `SELECT o.*, u.phone as customer_phone 
             FROM orders o 
             LEFT JOIN users u ON o.customer_id = u.user_id 
             WHERE o.shop_id = $1 
             ORDER BY o.created_at DESC LIMIT $2 OFFSET $3`,
            [req.shop_id, limit, offset]
        );
        const countResult = await pool.query('SELECT COUNT(*) FROM orders WHERE shop_id = $1', [req.shop_id]);
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
        console.error('Error fetching shop orders:', err);
        res.status(500).json({ error: 'Failed to fetch orders' });
    }
});

/**
 * @route   GET /api/shop/queue
 * @desc    Fetch only queued orders for this shop sorted by queue_position ASC
 * @access  Private (Shop Owner Only)
 */
router.get('/queue', async (req, res) => {
    try {
        const page = parseInt(req.query.page, 10) || 1;
        const limit = parseInt(req.query.limit, 10) || 50;
        const offset = (page - 1) * limit;

        const result = await pool.query(
            `SELECT o.*, u.phone as customer_phone 
             FROM orders o 
             LEFT JOIN users u ON o.customer_id = u.user_id 
             WHERE o.shop_id = $1 AND o.status = 'queued' 
             ORDER BY o.queue_position ASC LIMIT $2 OFFSET $3`,
            [req.shop_id, limit, offset]
        );
        const countResult = await pool.query("SELECT COUNT(*) FROM orders WHERE shop_id = $1 AND status = 'queued'", [req.shop_id]);
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
        console.error('Error fetching shop queue:', err);
        res.status(500).json({ error: 'Failed to fetch queue' });
    }
});

/**
 * @route   GET /api/shop/analytics
 * @desc    Fetch shop analytics (revenue and counts)
 * @access  Private (Shop Owner Only)
 */
router.get('/analytics', async (req, res) => {
    try {
        const todayResult = await pool.query(
            `SELECT COUNT(*) as today_count, COALESCE(SUM(amount_total), 0) as today_revenue 
             FROM orders 
             WHERE shop_id = $1 AND created_at >= CURRENT_DATE AND status != 'cancelled'`,
            [req.shop_id]
        );
        const totalResult = await pool.query(
            `SELECT COUNT(*) as total_count, COALESCE(SUM(amount_total), 0) as total_revenue 
             FROM orders 
             WHERE shop_id = $1 AND status != 'cancelled'`,
            [req.shop_id]
        );
        const completedResult = await pool.query(
            `SELECT COUNT(*) as completed_count, COALESCE(SUM(amount_total), 0) as completed_revenue 
             FROM orders 
             WHERE shop_id = $1 AND status = 'collected'`,
            [req.shop_id]
        );

        res.json({
            todayOrders: parseInt(todayResult.rows[0].today_count, 10),
            todayRevenue: parseFloat(todayResult.rows[0].today_revenue),
            totalOrders: parseInt(totalResult.rows[0].total_count, 10),
            totalRevenue: parseFloat(totalResult.rows[0].total_revenue),
            completedOrders: parseInt(completedResult.rows[0].completed_count, 10),
            completedRevenue: parseFloat(completedResult.rows[0].completed_revenue)
        });
    } catch (err) {
        console.error('Error fetching analytics:', err);
        res.status(500).json({ error: 'Failed to fetch analytics' });
    }
});

/**
 * @route   GET /api/shop/orders/:id
 * @desc    Fetch single order (only if it belongs to this shop)
 * @access  Private (Shop Owner Only)
 */
router.get('/orders/:id', async (req, res) => {
    const { id } = req.params;

    try {
        const result = await pool.query(
            'SELECT order_id, customer_id, shop_id, files, print_options, status, queue_position, amount_total, payment_status, created_at, updated_at, completed_at, files_deleted, cancelled_at, payment_id, pickup_qr, print_instructions, refund_status, refund_id FROM orders WHERE order_id = $1',
            [id]
        );

        if (result.rows.length === 0) {
            return res.status(404).json({ error: 'Order not found' });
        }

        const order = result.rows[0];

        // Verify ownership
        if (order.shop_id !== req.shop_id) {
            return res.status(403).json({ error: 'Access denied. This order does not belong to your shop.' });
        }

        res.json(order);
    } catch (err) {
        console.error('Error fetching shop order detail:', err);
        res.status(500).json({ error: 'Failed to fetch order' });
    }
});

/**
 * @route   GET /api/shop/orders/:id/files
 * @desc    Get all files for an order with download URLs
 * @access  Private (Shop Owner Only)
 */
router.get('/orders/:id/files', async (req, res) => {
    const { id } = req.params;

    try {
        const result = await pool.query(
            'SELECT shop_id, files FROM orders WHERE order_id = $1',
            [id]
        );

        if (result.rows.length === 0) {
            return res.status(404).json({ error: 'Order not found' });
        }

        const order = result.rows[0];

        if (order.shop_id !== req.shop_id) {
            return res.status(403).json({ error: 'Access denied. This order does not belong to your shop.' });
        }

        let files = order.files;
        if (typeof files === 'string') files = JSON.parse(files);
        files = files || [];

        const fileList = files.map((file, index) => {
            if (!file) return null;
            let downloadUrl = file.s3_key || file.url;
            
            return {
                index,
                original_url: file.s3_key || file.url,
                download_url: downloadUrl,
                page_count: file.page_count || null,
                original_name: file.original_name
            };
        }).filter(f => f !== null);

        return res.json(fileList);

    } catch (err) {
        console.error('Error fetching order files:', err);
        res.status(500).json({ error: 'Failed to fetch order files' });
    }
});

/**
 * @route   GET /api/shop/orders/:id/files/:index/download
 * @desc    Get order file and redirect to forced download URL
 * @access  Private (Shop Owner Only)
 */
router.get('/orders/:id/files/:index/download', async (req, res) => {
    const { id, index } = req.params;
    const fileIndex = parseInt(index, 10);

    if (isNaN(fileIndex) || fileIndex < 0) {
        return res.status(400).json({ error: 'Invalid file index' });
    }

    try {
        const result = await pool.query(
            'SELECT shop_id, files FROM orders WHERE order_id = $1',
            [id]
        );

        if (result.rows.length === 0) {
            return res.status(404).json({ error: 'Order not found' });
        }

        const order = result.rows[0];

        if (order.shop_id !== req.shop_id) {
            return res.status(403).json({ error: 'Access denied. This order does not belong to your shop.' });
        }

        let files = order.files;
        if (typeof files === 'string') files = JSON.parse(files);
        files = files || [];

        const rawFile = files[fileIndex];
        if (!rawFile) {
            return res.status(404).json({ error: 'File not found at this index' });
        }

        // Normalize: Flutter wraps file info in a nested 'file_info' object
        const fileInfo = (rawFile.file_info && typeof rawFile.file_info === 'object')
            ? rawFile.file_info
            : rawFile;

        const downloadUrl = fileInfo.s3_key || fileInfo.url;
        if (!downloadUrl) {
            return res.status(404).json({ error: 'File URL not found' });
        }

        return res.redirect(downloadUrl);

    } catch (err) {
        console.error('Error generating download redirect:', err);
        res.status(500).json({ error: 'Failed to generate download url' });
    }
});

/**
 * @route   GET /api/shop/orders/:id/files/:file_index/download-url
 * @desc    Get a short-lived signed download URL for a specific file.
 *          Handles the nested {file_info: {...}} structure stored by the Flutter app.
 * @access  Private (Shop Owner Only)
 */
router.get('/orders/:id/files/:file_index/download-url', async (req, res) => {
    const { id, file_index } = req.params;
    const index = parseInt(file_index, 10);

    if (isNaN(index) || index < 0) {
        return res.status(400).json({ error: 'Invalid file index' });
    }

    try {
        const result = await pool.query(
            'SELECT shop_id, files FROM orders WHERE order_id = $1',
            [id]
        );

        if (result.rows.length === 0) {
            return res.status(404).json({ error: 'Order not found' });
        }

        const order = result.rows[0];

        if (order.shop_id !== req.shop_id) {
            return res.status(403).json({ error: 'Access denied. This order does not belong to your shop.' });
        }

        let files = order.files || [];
        if (typeof files === 'string') files = JSON.parse(files);

        if (index >= files.length) {
            return res.status(404).json({ error: 'File not found at this index' });
        }

        const rawFile = files[index];
        // Normalize: Flutter wraps file info in a nested 'file_info' object
        const fileInfo = (rawFile && rawFile.file_info && typeof rawFile.file_info === 'object')
            ? rawFile.file_info
            : rawFile;

        const rawUrl = fileInfo && (fileInfo.s3_key || fileInfo.url);
        const publicId = fileInfo && fileInfo.public_id;
        
        const rawOriginalName = (fileInfo && fileInfo.original_name) || 'document.pdf';
        const extMatch = rawOriginalName.match(/\.[0-9a-z]+$/i);
        const ext = extMatch ? extMatch[0] : '.pdf';
        const shortId = id.split('-')[0];
        const originalName = files.length > 1 ? `${shortId}_${index + 1}${ext}` : `${shortId}${ext}`;

        if (!rawUrl) {
            console.error('[download-url] No URL found. fileInfo:', JSON.stringify(fileInfo));
            return res.status(404).json({ error: 'File URL not found' });
        }

        // Try to generate a Firebase signed URL (works for private buckets)
        const isFirebaseUrl = rawUrl.includes('firebasestorage.googleapis.com') || rawUrl.includes('.appspot.com');
        let downloadUrl = rawUrl;

        if (isFirebaseUrl && publicId) {
            try {
                const { getStorage } = require('../config/firebase');
                const bucket = getStorage().bucket();
                const fileRef = bucket.file(publicId);
                const [signedUrl] = await fileRef.getSignedUrl({
                    action: 'read',
                    expires: Date.now() + 30 * 60 * 1000, // 30 minutes
                });
                downloadUrl = signedUrl;
                console.log(`[download-url] Generated signed URL for ${publicId}`);
            } catch (signErr) {
                console.warn('[download-url] Signed URL failed, using raw URL:', signErr.message);
                // Fall back to the raw Firebase URL (works if bucket is public)
            }
        }

        return res.json({ download_url: downloadUrl, original_name: originalName });

    } catch (err) {
        console.error('Error generating download url:', err);
        res.status(500).json({ error: 'Failed to generate download url' });
    }
});

/**
 * @route   GET /api/shop/orders/:id/files/download-all
 * @desc    Get download URLs for all files in an order
 * @access  Private (Shop Owner Only)
 */
router.get('/orders/:id/files/download-all', async (req, res) => {
    const { id } = req.params;

    try {
        const result = await pool.query(
            'SELECT shop_id, files FROM orders WHERE order_id = $1',
            [id]
        );

        if (result.rows.length === 0) {
            return res.status(404).json({ error: 'Order not found' });
        }

        const order = result.rows[0];

        // Verify ownership
        if (order.shop_id !== req.shop_id) {
            return res.status(403).json({ error: 'Access denied. This order does not belong to your shop.' });
        }

        const files = order.files || [];
        
        const urls = files.map(file => {
            if (!file || !file.s3_key) return null;
            let downloadUrl = file.s3_key;
            return downloadUrl;
        }).filter(url => url !== null);

        return res.json({ urls });

    } catch (err) {
        console.error('Error generating download urls:', err);
        res.status(500).json({ error: 'Failed to generate download urls' });
    }
});

/**
 * @route   GET /api/shop/orders/:id/files/:file_index/proxy
 * @desc    Serve the uploaded file for download/print via a signed Firebase URL.
 *          Uses Firebase Admin SDK to generate a short-lived signed URL so that
 *          private bucket files are always accessible without storing public ACLs.
 * @access  Private (Shop Owner Only)
 */
router.get('/orders/:id/files/:file_index/proxy', async (req, res) => {
    const { id, file_index } = req.params;
    const fileIdx = parseInt(file_index, 10);

    if (isNaN(fileIdx) || fileIdx < 0) {
        return res.status(400).json({ error: 'Invalid file index' });
    }

    try {
        const result = await pool.query('SELECT shop_id, files FROM orders WHERE order_id = $1', [id]);
        if (result.rows.length === 0) return res.status(404).json({ error: 'Order not found' });

        const order = result.rows[0];
        if (order.shop_id !== req.shop_id) return res.status(403).json({ error: 'Access denied' });

        let files = order.files;
        if (typeof files === 'string') files = JSON.parse(files);
        files = files || [];

        const rawFile = files[fileIdx];
        if (!rawFile) {
            console.error(`[proxy] No entry at index ${fileIdx}. files:`, JSON.stringify(files));
            return res.status(404).json({ error: 'File not found at this index' });
        }

        // Normalize: Flutter stores files as { file_info: { s3_key, public_id, original_name }, print_options: {} }
        // Legacy format is flat: { s3_key, public_id, original_name }
        const fileInfo = (rawFile.file_info && typeof rawFile.file_info === 'object')
            ? rawFile.file_info
            : rawFile;

        const fileUrl = fileInfo.s3_key || fileInfo.url;
        const filePublicId = fileInfo.public_id;
        
        const rawOriginalName = fileInfo.original_name || 'document.pdf';
        const extMatch = rawOriginalName.match(/\.[0-9a-z]+$/i);
        const ext = extMatch ? extMatch[0] : '.pdf';
        const shortId = id.split('-')[0];
        const originalName = files.length > 1 ? `${shortId}_${fileIdx + 1}${ext}` : `${shortId}${ext}`;

        if (!fileUrl) {
            console.error(`[proxy] No URL in fileInfo:`, JSON.stringify(fileInfo));
            return res.status(404).json({ error: 'File URL not found' });
        }

        console.log(`[proxy] Serving file index ${fileIdx}: ${fileUrl}`);

        // ---------------------------------------------------------------
        // Strategy: Try Firebase Admin signed URL first (works for private
        // buckets). Fall back to direct https proxy if it's not a Firebase
        // Storage URL or if signing fails.
        // ---------------------------------------------------------------
        const isFirebaseUrl = fileUrl.includes('firebasestorage.googleapis.com') || fileUrl.includes('.appspot.com');
        
        if (isFirebaseUrl && filePublicId) {
            // Use Firebase Admin SDK to generate a short-lived signed URL
            try {
                const { getStorage } = require('../config/firebase');
                const bucket = getStorage().bucket();
                const fileRef = bucket.file(filePublicId);

                const [signedUrl] = await fileRef.getSignedUrl({
                    action: 'read',
                    expires: Date.now() + 15 * 60 * 1000, // 15 minutes
                });

                console.log('[proxy] Using Firebase signed URL');
                // Proxy via signed URL so Content-Disposition can be set
                const https = require('https');
                https.get(signedUrl, (response) => {
                    if (response.statusCode !== 200) {
                        console.error('[proxy] Firebase signed URL returned', response.statusCode);
                        return res.status(response.statusCode).send('Failed to fetch file');
                    }
                    const contentType = response.headers['content-type'] || 'application/octet-stream';
                    res.setHeader('Content-Type', contentType);
                    res.setHeader('Content-Disposition', `attachment; filename="${encodeURIComponent(originalName)}"`);
                    response.pipe(res);
                }).on('error', (err) => {
                    console.error('[proxy] Signed URL fetch error:', err);
                    res.status(500).json({ error: 'Error proxying signed file' });
                });
                return;
            } catch (signErr) {
                console.warn('[proxy] Could not generate signed URL, falling back to direct proxy:', signErr.message);
                // Fall through to direct proxy below
            }
        }

        // Direct proxy (for public URLs or non-Firebase storage)
        const https = require('https');
        const http = require('http');
        const httpClient = fileUrl.startsWith('https') ? https : http;

        httpClient.get(fileUrl, (response) => {
            if (response.statusCode !== 200) {
                console.error('[proxy] Direct fetch returned', response.statusCode, 'for URL:', fileUrl);
                return res.status(response.statusCode).send('Failed to fetch file from storage');
            }
            const contentType = response.headers['content-type'] || 'application/octet-stream';
            res.setHeader('Content-Type', contentType);
            res.setHeader('Content-Disposition', `attachment; filename="${encodeURIComponent(originalName)}"`);
            response.pipe(res);
        }).on('error', (err) => {
            console.error('[proxy] Direct proxy error:', err);
            res.status(500).json({ error: 'Error proxying file' });
        });

    } catch (err) {
        console.error('[proxy] Unexpected error:', err);
        res.status(500).json({ error: 'Server error' });
    }
});


/**
 * @route   PATCH /api/shop/orders/:id/status
 * @desc    Update order status (only if it belongs to this shop)
 * @access  Private (Shop Owner Only)
 */
router.patch('/orders/:id/status', async (req, res) => {
    const { id } = req.params;
    const { status } = req.body;

    // Validate status value
    const validStatuses = ['queued', 'processing', 'ready', 'collected', 'cancelled'];
    if (!status || !validStatuses.includes(status)) {
        return res.status(400).json({
            error: 'Invalid status',
            valid_values: validStatuses
        });
    }

    try {
        // Fetch order to verify ownership
        const orderResult = await pool.query(
            'SELECT shop_id, customer_id FROM orders WHERE order_id = $1',
            [id]
        );

        if (orderResult.rows.length === 0) {
            return res.status(404).json({ error: 'Order not found' });
        }

        const order = orderResult.rows[0];

        // Verify order belongs to this shop
        if (order.shop_id !== req.shop_id) {
            return res.status(403).json({ error: 'Access denied. This order does not belong to your shop.' });
        }

        // Perform status update
        const updateResult = await pool.query(
            `UPDATE orders 
             SET status = $1::text::order_status,
                 completed_at = CASE WHEN $1::text = 'collected' OR $1::text = 'cancelled' THEN NOW() ELSE completed_at END
             WHERE order_id = $2 
             RETURNING *`,
            [status, id]
        );

        // Notifications and FCM logic
        if (updateResult.rows[0].customer_id) {
            const customerId = updateResult.rows[0].customer_id;
            let title = '';
            let body = '';
            let type = 'general';

            if (status === 'processing') {
                title = 'Order Accepted 🖨️';
                body = `Your order #${id.substring(0, 8)} has been accepted and is now printing!`;
                type = 'order_accepted';
            } else if (status === 'ready') {
                title = 'Order Ready! 🎉';
                body = `Your order #${id.substring(0, 8)} is ready for pickup at the shop.`;
                type = 'order_ready';
            } else if (status === 'collected') {
                title = 'Order Delivered ✅';
                body = `Your order #${id.substring(0, 8)} has been collected. Thank you for using PrintIt!`;
                type = 'order_collected';
            }

            if (title) {
                // 1. Insert into DB
                try {
                    await pool.query(
                        `INSERT INTO notifications (user_id, title, message, type) VALUES ($1, $2, $3, $4)`,
                        [customerId, title, body, type]
                    );
                } catch (err) {
                    console.error('Failed to insert notification into DB:', err);
                }

                // 2. Send FCM
                triggerNotification(customerId, title, body, id).catch(err => {
                    console.error('Failed to trigger push notification:', err);
                });
            }
        }

        res.json({
            message: 'Order status updated successfully',
            order: updateResult.rows[0]
        });
    } catch (err) {
        console.error('Error updating shop order status:', err);
        res.status(500).json({ error: 'Failed to update order status' });
    }
});

/**
 * Ensures the shop_pricing table exists. Called lazily on first pricing request.
 * Safe to call multiple times due to IF NOT EXISTS.
 */
async function ensurePricingTable() {
    await pool.query(`
        CREATE TABLE IF NOT EXISTS shop_pricing (
            id              SERIAL PRIMARY KEY,
            shop_id         UUID NOT NULL REFERENCES shops(shop_id) ON DELETE CASCADE,
            color           TEXT NOT NULL CHECK (color IN ('bw', 'color')),
            size            TEXT NOT NULL CHECK (size IN ('A4', 'A3', 'Letter')),
            sides           TEXT NOT NULL CHECK (sides IN ('single', 'double')),
            price_per_page  NUMERIC(10, 2) NOT NULL,
            binding_staple_price NUMERIC(10, 2) NOT NULL DEFAULT 0,
            binding_spiral_price NUMERIC(10, 2) NOT NULL DEFAULT 0,
            created_at      TIMESTAMPTZ NOT NULL DEFAULT NOW(),
            UNIQUE (shop_id, color, size, sides)
        )
    `);
}

/**
 * @route   GET /api/shop/pricing
 * @desc    Fetch all pricing rules for this shop
 * @access  Private (Shop Owner Only)
 */
router.get('/pricing', async (req, res) => {
    try {
        await ensurePricingTable();
        const result = await pool.query(
            'SELECT id, shop_id, color, size, sides, price_per_page, binding_staple_price, binding_spiral_price, created_at FROM shop_pricing WHERE shop_id = $1 ORDER BY color, size, sides',
            [req.shop_id]
        );
        res.json(result.rows);
    } catch (err) {
        console.error('Error fetching pricing:', err);
        res.status(500).json({ error: 'Failed to fetch pricing rules' });
    }
});

/**
 * @route   POST /api/shop/pricing
 * @desc    Add a new pricing rule for this shop
 * @access  Private (Shop Owner Only)
 */
router.post('/pricing', async (req, res) => {
    const { color, size, sides, price_per_page, binding_staple_price = 0, binding_spiral_price = 0 } = req.body;

    if (!color || !size || !sides || price_per_page == null) {
        return res.status(400).json({ error: 'color, size, sides, and price_per_page are required' });
    }

    const validColors = ['bw', 'color'];
    const validSizes  = ['A4', 'A3', 'Letter'];
    const validSides  = ['single', 'double'];

    if (!validColors.includes(color)) return res.status(400).json({ error: `color must be one of: ${validColors.join(', ')}` });
    if (!validSizes.includes(size))   return res.status(400).json({ error: `size must be one of: ${validSizes.join(', ')}` });
    if (!validSides.includes(sides))  return res.status(400).json({ error: `sides must be one of: ${validSides.join(', ')}` });
    if (parseFloat(price_per_page) <= 0) return res.status(400).json({ error: 'price_per_page must be positive' });

    try {
        await ensurePricingTable();
        const result = await pool.query(
            `INSERT INTO shop_pricing 
                (shop_id, color, size, sides, price_per_page, binding_staple_price, binding_spiral_price)
             VALUES ($1, $2, $3, $4, $5, $6, $7)
             ON CONFLICT (shop_id, color, size, sides)
             DO UPDATE SET
                price_per_page       = EXCLUDED.price_per_page,
                binding_staple_price = EXCLUDED.binding_staple_price,
                binding_spiral_price = EXCLUDED.binding_spiral_price,
                created_at           = NOW()
             RETURNING *`,
            [req.shop_id, color, size, sides, parseFloat(price_per_page), parseFloat(binding_staple_price), parseFloat(binding_spiral_price)]
        );
        res.status(201).json({
            message: 'Pricing rule saved',
            rule: result.rows[0]
        });
    } catch (err) {
        console.error('Error saving pricing rule:', err);
        res.status(500).json({ error: 'Failed to save pricing rule' });
    }
});

/**
 * @route   DELETE /api/shop/pricing/:id
 * @desc    Delete a pricing rule (only if it belongs to this shop)
 * @access  Private (Shop Owner Only)
 */
router.delete('/pricing/:id', async (req, res) => {
    const { id } = req.params;

    try {
        await ensurePricingTable();
        const result = await pool.query(
            'DELETE FROM shop_pricing WHERE id = $1 AND shop_id = $2 RETURNING id',
            [id, req.shop_id]
        );

        if (result.rows.length === 0) {
            return res.status(404).json({ error: 'Pricing rule not found or does not belong to your shop' });
        }

        res.json({ message: 'Pricing rule deleted', id: result.rows[0].id });
    } catch (err) {
        console.error('Error deleting pricing rule:', err);
        res.status(500).json({ error: 'Failed to delete pricing rule' });
    }
});


/**
 * Send a push notification to the customer.
 * Fails silently — notification errors never block the HTTP response.
 *
 * @param {string} customerId - The customer's user_id (UUID)
 * @param {string} title      - The notification title
 * @param {string} body       - The notification body
 * @param {string} orderId    - The order_id to include in notification data
 */
async function triggerNotification(customerId, title, body, orderId) {
    try {
        // Look up the customer's FCM token
        const result = await pool.query(
            'SELECT fcm_token FROM users WHERE user_id = $1',
            [customerId]
        );

        const user = result.rows[0];
        if (!user || !user.fcm_token) {
            console.log(`ℹ️ No FCM token for customer ${customerId} — skipping push notification.`);
            return;
        }

        const message = {
            token: user.fcm_token,
            // The 'notification' block is what Android auto-displays
            // when the app is in background or killed
            notification: {
                title: title,
                body: body,
            },
            // Android-specific config — REQUIRED for system notifications
            android: {
                priority: 'high', // Ensures immediate delivery, not batched
                notification: {
                    channel_id: 'print_it_channel', // Must match the channel created in Flutter
                    priority: 'max',
                    default_sound: true,
                    default_vibrate_timings: true,
                    notification_count: 1,
                },
            },
            // Data payload — available to the app when user taps the notification
            data: {
                order_id: String(orderId),
                click_action: 'FLUTTER_NOTIFICATION_CLICK',
            },
        };

        const response = await getMessaging().send(message);
        console.log(`✅ Push notification sent for order ${orderId}:`, response);
    } catch (err) {
        // Log but never throw — notification failure must not break the status update
        console.error(`❌ Push notification failed for order ${orderId}:`, err.message);
    }
}

/**
 * @route   GET /api/shop/profile
 * @desc    Get current shop details and capabilities
 * @access  Private (Shop Owner Only)
 */
router.get('/profile', async (req, res) => {
    try {
        const result = await pool.query(
            `SELECT s.*, 
                COALESCE(
                    (SELECT json_agg(sc.capability) FROM shop_capabilities sc WHERE sc.shop_id = s.shop_id), 
                    '[]'::json
                ) AS capabilities
             FROM shops s 
             WHERE s.shop_id = $1`,
            [req.shop_id]
        );
        if (result.rows.length === 0) {
            return res.status(404).json({ error: 'Shop not found' });
        }
        res.json(result.rows[0]);
    } catch (err) {
        console.error('Error fetching shop profile:', err);
        res.status(500).json({ error: 'Failed to fetch shop profile' });
    }
});

/**
 * @route   PATCH /api/shop/profile
 * @desc    Update current shop details
 * @access  Private (Shop Owner Only)
 */
router.patch('/profile', async (req, res) => {
    const { name, address, phone, price_bw, price_color, opening_time, closing_time, is_open } = req.body;

    try {
        const result = await pool.query(
            `UPDATE shops 
             SET name = COALESCE($1, name), 
                 address = COALESCE($2, address), 
                 phone = COALESCE($3, phone),
                 price_bw = COALESCE($4, price_bw),
                 price_color = COALESCE($5, price_color),
                 opening_time = COALESCE($6, opening_time), 
                 closing_time = COALESCE($7, closing_time),
                 is_open = COALESCE($8, is_open)
             WHERE shop_id = $9 
             RETURNING *`,
            [name, address, phone, price_bw, price_color, opening_time, closing_time, is_open, req.shop_id]
        );

        res.json({
            message: 'Shop profile updated successfully',
            shop: result.rows[0]
        });
    } catch (err) {
        console.error('Error updating shop profile:', err);
        res.status(500).json({ error: 'Failed to update shop profile' });
    }
});

/**
 * @route   GET /api/shop/status
 * @desc    Get the shop's open/close status and timings
 * @access  Private (Shop Owner Only)
 */
router.get('/status', async (req, res) => {
    try {
        const result = await pool.query(
            'SELECT is_open, opening_time, closing_time FROM shops WHERE shop_id = $1',
            [req.shop_id]
        );
        if (result.rows.length === 0) {
            return res.status(404).json({ error: 'Shop not found' });
        }
        res.json(result.rows[0]);
    } catch (err) {
        console.error('Error fetching shop status:', err);
        res.status(500).json({ error: 'Failed to fetch shop status' });
    }
});

/**
 * @route   PATCH /api/shop/status
 * @desc    Update the shop's open/close status and timings
 * @access  Private (Shop Owner Only)
 */
router.patch('/status', async (req, res) => {
    const { is_open, opening_time, closing_time } = req.body;

    try {
        const result = await pool.query(
            `UPDATE shops 
             SET is_open = COALESCE($1, is_open), 
                 opening_time = COALESCE($2, opening_time), 
                 closing_time = COALESCE($3, closing_time)
             WHERE shop_id = $4 
             RETURNING is_open, opening_time, closing_time`,
            [is_open, opening_time, closing_time, req.shop_id]
        );

        res.json({
            message: 'Shop status updated successfully',
            status: result.rows[0]
        });
    } catch (err) {
        console.error('Error updating shop status:', err);
        res.status(500).json({ error: 'Failed to update shop status' });
    }
});

/**
 * @route   GET /api/shop/capabilities
 * @desc    Get current shop's tagged capabilities
 * @access  Private (Shop Owner Only)
 */
router.get('/capabilities', async (req, res) => {
    try {
        const result = await pool.query(
            'SELECT capability FROM shop_capabilities WHERE shop_id = $1',
            [req.shop_id]
        );
        res.json(result.rows.map(r => r.capability));
    } catch (err) {
        console.error('Error fetching shop capabilities:', err);
        res.status(500).json({ error: 'Failed to fetch capabilities' });
    }
});

/**
 * @route   POST /api/shop/capabilities
 * @desc    Add a capability tag to the shop
 * @access  Private (Shop Owner Only)
 */
router.post('/capabilities', async (req, res) => {
    const { capability } = req.body;

    if (!capability) {
        return res.status(400).json({ error: 'capability is required' });
    }

    const validCapabilities = [
        'books', 'spiral_binding', 'lamination', 
        'large_format', 'id_cards', 'notebooks', 'bulk_printing', 'same_day'
    ];

    if (!validCapabilities.includes(capability)) {
        return res.status(400).json({ error: 'Invalid capability tag' });
    }

    try {
        await pool.query(
            `INSERT INTO shop_capabilities (shop_id, capability) 
             VALUES ($1, $2) ON CONFLICT DO NOTHING`,
            [req.shop_id, capability]
        );
        res.status(201).json({ message: 'Capability added' });
    } catch (err) {
        console.error('Error adding capability:', err);
        res.status(500).json({ error: 'Failed to add capability' });
    }
});

/**
 * @route   DELETE /api/shop/capabilities/:capability
 * @desc    Remove a capability tag from the shop
 * @access  Private (Shop Owner Only)
 */
router.delete('/capabilities/:capability', async (req, res) => {
    const { capability } = req.params;

    try {
        await pool.query(
            'DELETE FROM shop_capabilities WHERE shop_id = $1 AND capability = $2',
            [req.shop_id, capability]
        );
        res.json({ message: 'Capability removed' });
    } catch (err) {
        console.error('Error removing capability:', err);
        res.status(500).json({ error: 'Failed to remove capability' });
    }
});

// ==========================================
// PHYSICAL MANUAL MARKETPLACE (SHOP OWNER)
// ==========================================

/**
 * @route   GET /api/shop/products
 * @desc    Shop's own listings
 * @access  Private (Shop Owner Only)
 */
router.get('/products', async (req, res) => {
    try {
        const page = parseInt(req.query.page, 10) || 1;
        const limit = parseInt(req.query.limit, 10) || 50;
        const offset = (page - 1) * limit;

        const result = await pool.query(
            'SELECT * FROM products WHERE shop_id = $1 ORDER BY created_at DESC LIMIT $2 OFFSET $3',
            [req.shop_id, limit, offset]
        );
        const countResult = await pool.query('SELECT COUNT(*) FROM products WHERE shop_id = $1', [req.shop_id]);
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
        console.error('Error fetching shop products:', err);
        res.status(500).json({ error: 'Failed to fetch shop products' });
    }
});

/**
 * @route   POST /api/shop/products
 * @desc    Add new listing
 * @access  Private (Shop Owner Only)
 */
router.post('/products', async (req, res) => {
    const { title, description, branch, course_type, semester, subject, price, stock_count, cover_photo_url, is_active } = req.body;
    try {
        const result = await pool.query(
            `INSERT INTO products (shop_id, title, description, branch, course_type, semester, subject, price, stock_count, cover_photo_url, is_active)
             VALUES ($1, $2, $3, $4, $5, $6, $7, $8, $9, $10, $11)
             RETURNING *`,
            [req.shop_id, title, description, branch, course_type, semester, subject, price, stock_count, cover_photo_url, is_active !== undefined ? is_active : true]
        );
        res.status(201).json({ message: 'Product created', product: result.rows[0] });
    } catch (err) {
        console.error('Error creating product:', err);
        res.status(500).json({ error: 'Failed to create product' });
    }
});

/**
 * @route   PUT /api/shop/products/:id
 * @desc    Edit listing
 * @access  Private (Shop Owner Only)
 */
router.put('/products/:id', async (req, res) => {
    const { id } = req.params;
    const { title, description, branch, course_type, semester, subject, price, stock_count, cover_photo_url, is_active } = req.body;
    try {
        const result = await pool.query(
            `UPDATE products 
             SET title = $1, description = $2, branch = $3, course_type = $4, semester = $5, subject = $6, price = $7, stock_count = $8, cover_photo_url = $9, is_active = $10, updated_at = NOW()
             WHERE product_id = $11 AND shop_id = $12
             RETURNING *`,
            [title, description, branch, course_type, semester, subject, price, stock_count, cover_photo_url, is_active, id, req.shop_id]
        );
        if (result.rows.length === 0) return res.status(404).json({ error: 'Product not found' });
        res.json({ message: 'Product updated', product: result.rows[0] });
    } catch (err) {
        console.error('Error updating product:', err);
        res.status(500).json({ error: 'Failed to update product' });
    }
});

/**
 * @route   PATCH /api/shop/products/:id/stock
 * @desc    Update stock count and toggle active state
 * @access  Private (Shop Owner Only)
 */
router.patch('/products/:id/stock', async (req, res) => {
    const { id } = req.params;
    const { stock_count, is_active } = req.body;
    
    let query = 'UPDATE products SET ';
    const queryParams = [];
    let paramIndex = 1;

    if (stock_count !== undefined) {
        query += `stock_count = $${paramIndex++}`;
        queryParams.push(stock_count);
    }
    if (is_active !== undefined) {
        if (queryParams.length > 0) query += ', ';
        query += `is_active = $${paramIndex++}`;
        queryParams.push(is_active);
    }

    if (queryParams.length === 0) return res.status(400).json({ error: 'No fields to update' });

    query += `, updated_at = NOW() WHERE product_id = $${paramIndex++} AND shop_id = $${paramIndex} RETURNING *`;
    queryParams.push(id, req.shop_id);

    try {
        const result = await pool.query(query, queryParams);
        if (result.rows.length === 0) return res.status(404).json({ error: 'Product not found' });
        res.json({ message: 'Product stock updated', product: result.rows[0] });
    } catch (err) {
        console.error('Error updating product stock:', err);
        res.status(500).json({ error: 'Failed to update product stock' });
    }
});

/**
 * @route   DELETE /api/shop/products/:id
 * @desc    Remove listing (soft delete)
 * @access  Private (Shop Owner Only)
 */
router.delete('/products/:id', async (req, res) => {
    const { id } = req.params;
    try {
        // Soft delete: set is_active to false
        const result = await pool.query(
            `UPDATE products SET is_active = false, updated_at = NOW() WHERE product_id = $1 AND shop_id = $2 RETURNING *`,
            [id, req.shop_id]
        );
        if (result.rows.length === 0) return res.status(404).json({ error: 'Product not found' });
        res.json({ message: 'Product deactivated', product: result.rows[0] });
    } catch (err) {
        console.error('Error deleting product:', err);
        res.status(500).json({ error: 'Failed to delete product' });
    }
});

/**
 * @route   GET /api/shop/product-orders
 * @desc    Orders placed for shop's manuals
 * @access  Private (Shop Owner Only)
 */
router.get('/product-orders', async (req, res) => {
    try {
        const page = parseInt(req.query.page, 10) || 1;
        const limit = parseInt(req.query.limit, 10) || 50;
        const offset = (page - 1) * limit;

        const result = await pool.query(
            `SELECT po.*, p.title, p.cover_photo_url, u.phone as customer_phone, u.name as customer_name
             FROM product_orders po
             JOIN products p ON po.product_id = p.product_id
             LEFT JOIN users u ON po.customer_id = u.user_id
             WHERE po.shop_id = $1
             ORDER BY po.created_at DESC LIMIT $2 OFFSET $3`,
            [req.shop_id, limit, offset]
        );
        const countResult = await pool.query('SELECT COUNT(*) FROM product_orders WHERE shop_id = $1', [req.shop_id]);
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
        console.error('Error fetching shop product orders:', err);
        res.status(500).json({ error: 'Failed to fetch shop product orders' });
    }
});

/**
 * @route   PATCH /api/shop/product-orders/:id/collect
 * @desc    Mark order as collected
 * @access  Private (Shop Owner Only)
 */
router.patch('/product-orders/:id/collect', async (req, res) => {
    const { id } = req.params;
    try {
        const result = await pool.query(
            `UPDATE product_orders 
             SET status = 'collected', updated_at = NOW() 
             WHERE order_id = $1 AND shop_id = $2 AND status = 'confirmed'
             RETURNING *`,
            [id, req.shop_id]
        );
        if (result.rows.length === 0) return res.status(404).json({ error: 'Order not found or already processed' });
        res.json({ message: 'Order marked as collected', order: result.rows[0] });
    } catch (err) {
        console.error('Error updating order to collected:', err);
        res.status(500).json({ error: 'Failed to update order status' });
    }
});

module.exports = router;
