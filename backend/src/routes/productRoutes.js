const express = require('express');
const router = express.Router();
const pool = require('../config/db');

/**
 * @route   GET /api/products
 * @desc    Browse all active listings, filter by branch/course_type/semester
 * @access  Public
 */
router.get('/', async (req, res) => {
    try {
        const { branch, course_type, semester, query } = req.query;

        let sql = `
            SELECT p.*, s.name as shop_name, s.address as shop_address, s.is_open, s.opening_time, s.closing_time
            FROM products p
            JOIN shops s ON p.shop_id = s.shop_id
            WHERE p.is_active = true AND s.is_active = true
        `;
        const queryParams = [];
        let paramIndex = 1;

        if (branch) {
            sql += ` AND p.branch = $${paramIndex++}`;
            queryParams.push(branch);
        }
        if (course_type) {
            sql += ` AND p.course_type = $${paramIndex++}`;
            queryParams.push(course_type);
        }
        if (semester) {
            sql += ` AND p.semester = $${paramIndex++}`;
            queryParams.push(semester);
        }
        if (query) {
            sql += ` AND (p.title ILIKE $${paramIndex} OR p.subject ILIKE $${paramIndex})`;
            queryParams.push(`%${query}%`);
            paramIndex++;
        }

        sql += ` ORDER BY p.created_at DESC`;

        const result = await pool.query(sql, queryParams);
        res.json(result.rows);
    } catch (err) {
        console.error('Error fetching products:', err);
        res.status(500).json({ error: 'Failed to fetch products' });
    }
});

/**
 * @route   GET /api/products/shop/:shop_id
 * @desc    All listings by a specific shop
 * @access  Public
 */
router.get('/shop/:shop_id', async (req, res) => {
    try {
        const { shop_id } = req.params;
        const result = await pool.query(
            `SELECT p.*, s.name as shop_name 
             FROM products p
             JOIN shops s ON p.shop_id = s.shop_id
             WHERE p.shop_id = $1 AND p.is_active = true
             ORDER BY p.created_at DESC`,
            [shop_id]
        );
        res.json(result.rows);
    } catch (err) {
        console.error('Error fetching shop products:', err);
        res.status(500).json({ error: 'Failed to fetch shop products' });
    }
});

/**
 * @route   GET /api/products/:id
 * @desc    Single product detail
 * @access  Public
 */
router.get('/:id', async (req, res) => {
    try {
        const { id } = req.params;
        const result = await pool.query(
            `SELECT p.*, s.name as shop_name, s.address as shop_address, s.phone as shop_phone, s.is_open, s.opening_time, s.closing_time
             FROM products p
             JOIN shops s ON p.shop_id = s.shop_id
             WHERE p.product_id = $1`,
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

module.exports = router;
