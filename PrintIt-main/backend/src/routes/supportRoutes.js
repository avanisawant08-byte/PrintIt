const express = require('express');
const router = express.Router();
const pool = require('../config/db');
const auth = require('../middleware/auth');
const { getMessaging } = require('../config/firebase');
const crypto = require('crypto');

// Generate unique ticket token like SUP-YYYY-XXXX
const generateTicketToken = () => {
    const year = new Date().getFullYear();
    const randomHex = crypto.randomBytes(2).toString('hex').toUpperCase();
    return `SUP-${year}-${randomHex}`;
};

// Push notification helper function
const sendPushNotification = async (userId, title, body) => {
    try {
        const result = await pool.query('SELECT fcm_token FROM users WHERE user_id = $1 AND fcm_token IS NOT NULL', [userId]);
        if (result.rows.length > 0) {
            const token = result.rows[0].fcm_token;
            await getMessaging().send({
                token: token,
                notification: {
                    title: title,
                    body: body
                },
                data: {
                    type: 'support_ticket'
                }
            });
            console.log(`Support push sent to ${userId}`);
        }
    } catch (err) {
        console.error('Failed to send push notification:', err);
    }
};

router.use(auth);

/**
 * @route   POST /api/support/tickets
 * @desc    Create a new support ticket
 */
router.post('/tickets', async (req, res) => {
    const { subject, description, shop_id } = req.body;

    if (!subject || !description) {
        return res.status(400).json({ error: 'Subject and description are required' });
    }

    const ticketToken = generateTicketToken();

    try {
        const result = await pool.query(
            `INSERT INTO support_tickets (ticket_token, user_id, shop_id, subject, description)
             VALUES ($1, $2, $3, $4, $5)
             RETURNING *`,
            [ticketToken, req.user.user_id, shop_id || null, subject, description]
        );

        res.status(201).json({
            message: 'Ticket created successfully',
            ticket: result.rows[0]
        });
    } catch (err) {
        console.error('Create ticket error:', err);
        res.status(500).json({ error: 'Failed to create ticket' });
    }
});

/**
 * @route   GET /api/support/tickets
 * @desc    Fetch tickets (Customers see their own, shops see theirs, admin sees all if shop_id null)
 */
router.get('/tickets', async (req, res) => {
    try {
        const role = req.user.role;
        let result;

        if (role === 'customer') {
            result = await pool.query(
                `SELECT t.*, s.name as shop_name 
                 FROM support_tickets t
                 LEFT JOIN shops s ON t.shop_id = s.shop_id
                 WHERE t.user_id = $1
                 ORDER BY t.updated_at DESC`,
                [req.user.user_id]
            );

        } else if (role === 'admin') {
            // For now, if role is admin, they see app-level tickets (shop_id IS NULL)
            result = await pool.query(
                `SELECT t.*, u.full_name as customer_name, u.email as customer_email 
                 FROM support_tickets t
                 JOIN users u ON t.user_id = u.user_id
                 WHERE t.shop_id IS NULL
                 ORDER BY t.updated_at DESC`
            );
        } else {
            return res.status(403).json({ error: 'Unauthorized role' });
        }

        res.json(result.rows);
    } catch (err) {
        console.error('Fetch tickets error:', err);
        res.status(500).json({ error: 'Failed to fetch tickets' });
    }
});

/**
 * @route   GET /api/support/tickets/:id
 * @desc    Get ticket details and all its messages
 */
router.get('/tickets/:id', async (req, res) => {
    const { id } = req.params;

    try {
        // Fetch ticket details
        const ticketResult = await pool.query(
            `SELECT t.*, u.full_name as customer_name, s.name as shop_name
             FROM support_tickets t
             JOIN users u ON t.user_id = u.user_id
             LEFT JOIN shops s ON t.shop_id = s.shop_id
             WHERE t.ticket_id = $1`,
            [id]
        );

        if (ticketResult.rows.length === 0) {
            return res.status(404).json({ error: 'Ticket not found' });
        }

        const ticket = ticketResult.rows[0];

        // Ensure user has permission to view
        if (req.user.role === 'customer' && ticket.user_id !== req.user.user_id) {
            return res.status(403).json({ error: 'Unauthorized to view this ticket' });
        }


        // Fetch messages
        const msgResult = await pool.query(
            `SELECT m.*, u.full_name as sender_name 
             FROM ticket_messages m
             LEFT JOIN users u ON m.sender_id = u.user_id
             WHERE m.ticket_id = $1
             ORDER BY m.created_at ASC`,
            [id]
        );

        res.json({
            ...ticket,
            messages: msgResult.rows
        });
    } catch (err) {
        console.error('Fetch ticket details error:', err);
        res.status(500).json({ error: 'Failed to fetch ticket details' });
    }
});

/**
 * @route   POST /api/support/tickets/:id/messages
 * @desc    Add a message to a ticket
 */
router.post('/tickets/:id/messages', async (req, res) => {
    const { id } = req.params;
    const { message } = req.body;

    if (!message) return res.status(400).json({ error: 'Message cannot be empty' });

    const client = await pool.connect();
    try {
        await client.query('BEGIN');

        // Verify ticket exists
        const ticketResult = await client.query('SELECT * FROM support_tickets WHERE ticket_id = $1', [id]);
        if (ticketResult.rows.length === 0) {
            await client.query('ROLLBACK');
            return res.status(404).json({ error: 'Ticket not found' });
        }

        const ticket = ticketResult.rows[0];

        // Insert message
        const msgResult = await client.query(
            `INSERT INTO ticket_messages (ticket_id, sender_id, sender_role, message)
             VALUES ($1, $2, $3, $4) RETURNING *`,
            [id, req.user.user_id, req.user.role, message]
        );

        // Update ticket updated_at
        await client.query(
            `UPDATE support_tickets SET updated_at = NOW() WHERE ticket_id = $1`,
            [id]
        );

        await client.query('COMMIT');

        // Trigger Notification
        if (req.user.role !== 'customer') {
            // Admin replied to customer
            await sendPushNotification(
                ticket.user_id, 
                `New Reply on ${ticket.ticket_token}`, 
                `Support replied to your ticket.`
            );
        } else if (req.user.role === 'customer') {
            // Customer replied to Shop/Admin. We could theoretically push to shop owner here.
            // Simplified for now.
        }

        res.status(201).json({
            message: 'Message added',
            ticket_message: msgResult.rows[0]
        });

    } catch (err) {
        await client.query('ROLLBACK');
        console.error('Error adding message:', err);
        res.status(500).json({ error: 'Failed to add message' });
    } finally {
        client.release();
    }
});

/**
 * @route   PATCH /api/support/tickets/:id/status
 * @desc    Update ticket status
 */
router.patch('/tickets/:id/status', async (req, res) => {
    const { id } = req.params;
    const { status } = req.body;

    if (!['open', 'in_progress', 'resolved', 'closed'].includes(status)) {
        return res.status(400).json({ error: 'Invalid status' });
    }

    try {
        const result = await pool.query(
            `UPDATE support_tickets SET status = $1::ticket_status, updated_at = NOW() WHERE ticket_id = $2 RETURNING *`,
            [status, id]
        );

        if (result.rows.length === 0) return res.status(404).json({ error: 'Ticket not found' });

        res.json({
            message: 'Status updated',
            ticket: result.rows[0]
        });
    } catch (err) {
        console.error('Update ticket status error:', err);
        res.status(500).json({ error: 'Failed to update ticket status' });
    }
});

module.exports = router;
