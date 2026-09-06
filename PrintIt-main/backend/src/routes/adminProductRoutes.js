const express = require('express');
const router = express.Router();
const pool = require('../config/db');
const auth = require('../middleware/auth');
const roleCheck = require('../middleware/roleCheck');

// All admin product routes require authentication and admin role
router.use(auth);
router.use(roleCheck('admin'));

/**
 * @route   GET /api/admin/products
 * @desc    Fetch all master catalog products with stocking shop counts
 * @access  Private (Admin Only)
 */
router.get('/', async (req, res) => {
    try {
        const { search, category, branch, is_active } = req.query;

        let query = `
            SELECT 
                p.*,
                COUNT(DISTINCT i.shop_id) AS stocking_shops_count,
                COALESCE(SUM(i.stock_count), 0) AS total_inventory_stock,
                COALESCE(MIN(i.price) FILTER (WHERE i.stock_count > 0 AND i.is_available = true), 0) AS min_price,
                COALESCE(MAX(i.price) FILTER (WHERE i.stock_count > 0 AND i.is_available = true), 0) AS max_price
            FROM product_catalog p
            LEFT JOIN shop_inventory i ON p.product_id = i.product_id
            WHERE 1=1
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

        if (is_active !== undefined) {
            query += ` AND p.is_active = $${paramIndex++}`;
            params.push(is_active === 'true');
        }

        if (search && search.trim()) {
            query += ` AND (p.title ILIKE $${paramIndex} OR p.subject ILIKE $${paramIndex} OR p.author ILIKE $${paramIndex})`;
            params.push(`%${search.trim()}%`);
            paramIndex++;
        }

        query += ` GROUP BY p.product_id ORDER BY p.created_at DESC`;

        const result = await pool.query(query, params);
        res.json({ success: true, count: result.rows.length, products: result.rows });
    } catch (err) {
        console.error('Error fetching master products for admin:', err);
        res.status(500).json({ error: 'Failed to fetch catalog products' });
    }
});

/**
 * @route   POST /api/admin/products
 * @desc    Create a new master catalog product
 * @access  Private (Admin Only)
 */
router.post('/', async (req, res) => {
    try {
        const {
            title,
            description,
            category,
            branch,
            course_type,
            semester,
            subject,
            author,
            isbn,
            cover_photo_url
        } = req.body;

        if (!title || !category) {
            return res.status(400).json({ error: 'Title and category are required' });
        }

        const validCategories = ['Books', 'Manuals', 'Notes', 'Forms', 'Other'];
        if (!validCategories.includes(category)) {
            return res.status(400).json({
                error: `Invalid category. Allowed: ${validCategories.join(', ')}`
            });
        }

        const query = `
            INSERT INTO product_catalog (
                title, description, category, branch, course_type, 
                semester, subject, author, isbn, cover_photo_url, 
                created_by, is_active
            )
            VALUES ($1, $2, $3, $4, $5, $6, $7, $8, $9, $10, $11, true)
            RETURNING *;
        `;

        const values = [
            title.trim(),
            description || '',
            category,
            branch || '',
            course_type || 'Degree',
            semester || '',
            subject || '',
            author || '',
            isbn || '',
            cover_photo_url || '',
            req.user.user_id
        ];

        const result = await pool.query(query, values);
        res.status(201).json({
            success: true,
            message: 'Product created in master catalog',
            product: result.rows[0]
        });
    } catch (err) {
        console.error('Error creating master product:', err);
        res.status(500).json({ error: 'Failed to create product in master catalog' });
    }
});

/**
 * @route   PUT /api/admin/products/:id
 * @desc    Update a master catalog product
 * @access  Private (Admin Only)
 */
router.put('/:id', async (req, res) => {
    try {
        const { id } = req.params;
        const {
            title,
            description,
            category,
            branch,
            course_type,
            semester,
            subject,
            author,
            isbn,
            cover_photo_url,
            is_active
        } = req.body;

        const query = `
            UPDATE product_catalog 
            SET 
                title = COALESCE($1, title),
                description = COALESCE($2, description),
                category = COALESCE($3, category),
                branch = COALESCE($4, branch),
                course_type = COALESCE($5, course_type),
                semester = COALESCE($6, semester),
                subject = COALESCE($7, subject),
                author = COALESCE($8, author),
                isbn = COALESCE($9, isbn),
                cover_photo_url = COALESCE($10, cover_photo_url),
                is_active = COALESCE($11, is_active)
            WHERE product_id = $12
            RETURNING *;
        `;

        const values = [
            title ? title.trim() : null,
            description !== undefined ? description : null,
            category || null,
            branch !== undefined ? branch : null,
            course_type !== undefined ? course_type : null,
            semester !== undefined ? semester : null,
            subject !== undefined ? subject : null,
            author !== undefined ? author : null,
            isbn !== undefined ? isbn : null,
            cover_photo_url !== undefined ? cover_photo_url : null,
            is_active !== undefined ? is_active : null,
            id
        ];

        const result = await pool.query(query, values);
        if (result.rows.length === 0) {
            return res.status(404).json({ error: 'Product not found in catalog' });
        }

        res.json({
            success: true,
            message: 'Product updated successfully',
            product: result.rows[0]
        });
    } catch (err) {
        console.error('Error updating master product:', err);
        res.status(500).json({ error: 'Failed to update product' });
    }
});

/**
 * @route   PATCH /api/admin/products/:id/toggle
 * @desc    Toggle product active/inactive
 * @access  Private (Admin Only)
 */
router.patch('/:id/toggle', async (req, res) => {
    try {
        const { id } = req.params;
        const result = await pool.query(
            `UPDATE product_catalog 
             SET is_active = NOT is_active 
             WHERE product_id = $1 
             RETURNING product_id, title, is_active`,
            [id]
        );

        if (result.rows.length === 0) {
            return res.status(404).json({ error: 'Product not found' });
        }

        res.json({
            success: true,
            message: `Product is now ${result.rows[0].is_active ? 'active' : 'inactive'}`,
            product: result.rows[0]
        });
    } catch (err) {
        console.error('Error toggling product status:', err);
        res.status(500).json({ error: 'Failed to toggle product status' });
    }
});

/**
 * @route   DELETE /api/admin/products/:id
 * @desc    Delete or deactivate product
 * @access  Private (Admin Only)
 */
router.delete('/:id', async (req, res) => {
    try {
        const { id } = req.params;

        // Check if any orders exist for this product
        const orderCheck = await pool.query(
            'SELECT order_item_id FROM store_order_items WHERE product_id = $1 LIMIT 1',
            [id]
        );

        if (orderCheck.rows.length > 0) {
            // Soft delete by setting is_active = false to preserve order history
            await pool.query('UPDATE product_catalog SET is_active = false WHERE product_id = $1', [id]);
            return res.json({
                success: true,
                message: 'Product is referenced in orders; marked as inactive instead of deleting.'
            });
        }

        const result = await pool.query('DELETE FROM product_catalog WHERE product_id = $1 RETURNING product_id', [id]);
        if (result.rows.length === 0) {
            return res.status(404).json({ error: 'Product not found' });
        }

        res.json({ success: true, message: 'Product deleted from master catalog' });
    } catch (err) {
        console.error('Error deleting product:', err);
        res.status(500).json({ error: 'Failed to delete product' });
    }
});

module.exports = router;
