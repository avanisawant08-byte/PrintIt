const express = require('express');
const router = express.Router();
const pool = require('../config/db');
const auth = require('../middleware/auth');

// All notification routes require authentication
router.use(auth);

/**
 * @route   GET /api/notifications
 * @desc    Fetch all notifications for the authenticated user
 * @access  Private
 */
router.get('/', async (req, res) => {
    try {
        const result = await pool.query(
            'SELECT id, user_id, title, message, type, is_read, created_at FROM notifications WHERE user_id = $1 ORDER BY created_at DESC',
            [req.user.user_id]
        );
        res.json(result.rows);
    } catch (err) {
        console.error('Error fetching notifications:', err);
        res.status(500).json({ error: 'Failed to fetch notifications' });
    }
});

/**
 * @route   PATCH /api/notifications/:id/read
 * @desc    Mark a single notification as read
 * @access  Private
 */
router.patch('/:id/read', async (req, res) => {
    const { id } = req.params;

    try {
        const result = await pool.query(
            'UPDATE notifications SET is_read = true WHERE id = $1 AND user_id = $2 RETURNING *',
            [id, req.user.user_id]
        );

        if (result.rows.length === 0) {
            return res.status(404).json({ error: 'Notification not found' });
        }

        res.json({ message: 'Notification marked as read', notification: result.rows[0] });
    } catch (err) {
        console.error('Error updating notification:', err);
        res.status(500).json({ error: 'Failed to update notification' });
    }
});

/**
 * @route   PATCH /api/notifications/read-all
 * @desc    Mark all notifications as read for the user
 * @access  Private
 */
router.patch('/read-all', async (req, res) => {
    try {
        await pool.query(
            'UPDATE notifications SET is_read = true WHERE user_id = $1 AND is_read = false',
            [req.user.user_id]
        );
        res.json({ message: 'All notifications marked as read' });
    } catch (err) {
        console.error('Error updating notifications:', err);
        res.status(500).json({ error: 'Failed to mark all as read' });
    }
});

module.exports = router;

