const jwt = require('jsonwebtoken');
const crypto = require('crypto');
const pool = require('../config/db');

const auth = async (req, res, next) => {
    const authHeader = req.headers.authorization;

    if (!authHeader || !authHeader.startsWith('Bearer ')) {
        return res.status(401).json({ error: 'Access denied. No token provided.' });
    }

    const token = authHeader.split(' ')[1];

    try {
        const decoded = jwt.verify(token, process.env.JWT_SECRET);

        // Check if token has been blacklisted / revoked
        const tokenHash = crypto.createHash('sha256').update(token).digest('hex');
        try {
            const blacklisted = await pool.query(
                'SELECT 1 FROM jwt_blacklist WHERE token_hash = $1',
                [tokenHash]
            );
            if (blacklisted.rows.length > 0) {
                return res.status(401).json({ error: 'Token has been revoked. Please log in again.' });
            }
        } catch (_) {
            // Table might not exist yet if lazy initialization hasn't triggered
        }

        req.user = decoded;
        req.token = token;
        next();
    } catch (err) {
        res.status(401).json({ error: 'Invalid or expired token.' });
    }
};

module.exports = auth;

