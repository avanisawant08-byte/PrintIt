const pool = require('../config/db');

const shopCheck = async (req, res, next) => {
    // Ensure req.user exists (auth middleware should have run)
    if (!req.user || !req.user.user_id) {
        return res.status(401).json({ error: 'Unauthorized. Authentication credentials missing.' });
    }

    // Only shopkeepers can own shops — reject all other roles immediately
    if (req.user.role !== 'shopkeeper' && req.user.role !== 'admin') {
        return res.status(403).json({ error: 'Forbidden. This section is restricted to shop owners.' });
    }

    try {
        const result = await pool.query(
            'SELECT shop_id FROM shops WHERE owner_id = $1',
            [req.user.user_id]
        );

        if (result.rows.length === 0) {
            return res.status(403).json({ error: 'Forbidden. No shop found associated with this account.' });
        }

        req.shop_id = result.rows[0].shop_id;
        next();
    } catch (err) {
        console.error('Error in shopCheck middleware:', err);
        return res.status(500).json({ error: 'Unable to verify shop access. Please try again.' });
    }
};

module.exports = shopCheck;

