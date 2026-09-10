const express = require('express');
const router = express.Router();
const bcrypt = require('bcrypt');
const jwt = require('jsonwebtoken');
const crypto = require('crypto');
const pool = require('../config/db');
const { getAuth } = require('../config/firebase');
const auth = require('../middleware/auth');
const { authLimiter, loginLimiter, passwordResetLimiter, otpLimiter } = require('../middleware/rateLimiter');
const { generateUniqueShopCode } = require('../utils/setupShopCodeDb');

// Ensure tables for password resets and token blacklist exist
async function ensureAuthSecurityTables() {
    try {
        await pool.query(`
            CREATE TABLE IF NOT EXISTS password_resets (
                id SERIAL PRIMARY KEY,
                user_id UUID NOT NULL REFERENCES users(user_id) ON DELETE CASCADE,
                token_hash VARCHAR(64) NOT NULL,
                expires_at TIMESTAMPTZ NOT NULL,
                used BOOLEAN DEFAULT false,
                created_at TIMESTAMPTZ DEFAULT NOW()
            );
            CREATE INDEX IF NOT EXISTS idx_pwd_resets_token ON password_resets(token_hash);

            CREATE TABLE IF NOT EXISTS jwt_blacklist (
                token_hash VARCHAR(64) PRIMARY KEY,
                expires_at TIMESTAMPTZ NOT NULL,
                created_at TIMESTAMPTZ DEFAULT NOW()
            );
            CREATE INDEX IF NOT EXISTS idx_jwt_blacklist_expires ON jwt_blacklist(expires_at);
        `);
    } catch (e) {
        console.warn('Auth security tables setup warning:', e.message);
    }
}
ensureAuthSecurityTables();

// POST /api/auth/register — Create a new user
router.post('/register', authLimiter, async (req, res) => {
    const { email, password, full_name, phone } = req.body;
    let role = 'customer';
    if (email && email.toLowerCase() === 'printitsupport@gmail.com') {
        if (process.env.ADMIN_SIGNUP_TOKEN && req.body.admin_token === process.env.ADMIN_SIGNUP_TOKEN) {
            role = 'admin';
        } else {
            return res.status(403).json({ error: 'Administrative registration requires valid administrator authorization.' });
        }
    }

    if (!email || !password || !full_name) {
        return res.status(400).json({ error: 'Email, password, and full name are required' });
    }

    try {
        // Check if user already exists
        const userCheck = await pool.query('SELECT user_id FROM users WHERE email = $1', [email]);
        if (userCheck.rows.length > 0) {
            return res.status(400).json({ error: 'User with this email already exists' });
        }

        // Hash password
        const salt = await bcrypt.genSalt(10);
        const password_hash = await bcrypt.hash(password, salt);

        // Insert user
        const result = await pool.query(
            `INSERT INTO users (email, password_hash, full_name, phone, role) 
             VALUES ($1, $2, $3, $4, $5) 
             RETURNING user_id, email, full_name, phone, avatar_url, role`,
            [email, password_hash, full_name, phone, role]
        );

        const user = result.rows[0];

        // Create JWT
        const token = jwt.sign(
            { user_id: user.user_id, email: user.email, role: user.role },
            process.env.JWT_SECRET,
            { expiresIn: '7d' }
        );

        res.status(201).json({
            message: 'User registered successfully',
            token,
            user
        });

    } catch (err) {
        console.error('Registration error:', err.message);
        res.status(500).json({ error: 'Failed to register user' });
    }
});

// POST /api/auth/login — User login (Strict rate limit: 5 per minute)
router.post('/login', loginLimiter, async (req, res) => {
    const { email, password } = req.body;

    if (!email || !password) {
        return res.status(400).json({ error: 'Email and password are required' });
    }

    try {
        // Find user
        const result = await pool.query('SELECT user_id, email, password_hash, full_name, phone, avatar_url, role FROM users WHERE email = $1', [email]);
        if (result.rows.length === 0) {
            return res.status(404).json({ error: 'User not found' });
        }

        const user = result.rows[0];

        // Verify password
        if (!user.password_hash) {
            return res.status(401).json({ error: 'Please login with Google or reset your password' });
        }
        const isMatch = await bcrypt.compare(password, user.password_hash);
        if (!isMatch) {
            return res.status(401).json({ error: 'Invalid credentials' });
        }

        // Create JWT
        const token = jwt.sign(
            { user_id: user.user_id, email: user.email, role: user.role },
            process.env.JWT_SECRET,
            { expiresIn: '7d' }
        );

        res.json({
            message: 'Login successful',
            token,
            user: {
                user_id: user.user_id,
                email: user.email,
                full_name: user.full_name,
                phone: user.phone,
                avatar_url: user.avatar_url,
                role: user.role
            }
        });

    } catch (err) {
        console.error('Login error:', err.message);
        res.status(500).json({ error: 'Failed to login' });
    }
});

// POST /api/auth/register-shop — Register a new shopkeeper + create their shop
router.post('/register-shop', authLimiter, async (req, res) => {
    const { email, password, full_name, phone, shop_name, address, price_bw, price_color } = req.body;

    if (!email || !password || !full_name || !shop_name || price_bw == null || price_color == null) {
        return res.status(400).json({
            error: 'Email, password, full name, shop name, price_bw, and price_color are required'
        });
    }

    if (parseFloat(price_bw) <= 0 || parseFloat(price_color) <= 0) {
        return res.status(400).json({ error: 'Prices must be positive values' });
    }

    const client = await pool.connect();
    try {
        await client.query('BEGIN');

        // Check if user already exists
        const userCheck = await client.query('SELECT user_id FROM users WHERE email = $1', [email]);
        if (userCheck.rows.length > 0) {
            await client.query('ROLLBACK');
            return res.status(400).json({ error: 'User with this email already exists' });
        }

        // Hash password
        const salt = await bcrypt.genSalt(10);
        const password_hash = await bcrypt.hash(password, salt);

        // Create user with role = shopkeeper
        const userResult = await client.query(
            `INSERT INTO users (email, password_hash, full_name, phone, role)
             VALUES ($1, $2, $3, $4, 'shopkeeper')
             RETURNING user_id, email, full_name, role`,
            [email, password_hash, full_name, phone || null]
        );
        const user = userResult.rows[0];

        // Generate a unique 6-character shop code (e.g. PR8473)
        const shop_code = await generateUniqueShopCode(client, shop_name);

        // Create the shop with pricing and short shop code
        const shopResult = await client.query(
            `INSERT INTO shops (owner_id, name, address, price_bw, price_color, shop_code)
             VALUES ($1, $2, $3, $4, $5, $6)
             RETURNING shop_id, name, address, price_bw, price_color, shop_code`,
            [user.user_id, shop_name, address || null, parseFloat(price_bw), parseFloat(price_color), shop_code]
        );
        const shop = shopResult.rows[0];

        await client.query('COMMIT');

        // Create JWT
        const token = jwt.sign(
            { user_id: user.user_id, email: user.email, role: user.role },
            process.env.JWT_SECRET,
            { expiresIn: '7d' }
        );

        res.status(201).json({
            message: 'Shop registered successfully',
            token,
            user,
            shop
        });

    } catch (err) {
        await client.query('ROLLBACK');
        console.error('Shop registration error:', err.message);
        res.status(500).json({ error: 'Failed to register shop' });
    } finally {
        client.release();
    }
});

// POST /api/auth/google — Google Login via Firebase Token
router.post('/google', authLimiter, async (req, res) => {
    const { firebase_token } = req.body;

    if (!firebase_token) {
        return res.status(400).json({ error: 'Firebase token is required' });
    }

    try {
        const decodedToken = await getAuth().verifyIdToken(firebase_token);
        const { email, name, uid, picture } = decodedToken;

        const result = await pool.query('SELECT user_id, email, full_name, phone, avatar_url, role, google_id FROM users WHERE email = $1', [email]);
        let user;

        if (result.rows.length === 0) {
            const insertResult = await pool.query(
                `INSERT INTO users (email, full_name, google_id, role, avatar_url) 
                 VALUES ($1, $2, $3, $4, $5) 
                 RETURNING user_id, email, full_name, phone, avatar_url, role`,
                [email, name || 'Google User', uid, 'customer', picture || null]
            );
            user = insertResult.rows[0];
        } else {
            user = result.rows[0];
            if (!user.google_id) {
                await pool.query('UPDATE users SET google_id = $1 WHERE user_id = $2', [uid, user.user_id]);
            }
        }

        const token = jwt.sign(
            { user_id: user.user_id, email: user.email, role: user.role },
            process.env.JWT_SECRET,
            { expiresIn: '7d' }
        );

        res.json({
            message: 'Google login successful',
            token,
            user: {
                user_id: user.user_id,
                email: user.email,
                full_name: user.full_name,
                phone: user.phone,
                avatar_url: user.avatar_url,
                role: user.role
            }
        });

    } catch (err) {
        console.error('Google login error:', err.message);
        res.status(401).json({ error: 'Invalid or expired Firebase authentication token' });
    }
});

// POST /api/auth/phone — Phone OTP Login via Firebase Token (Rate limited)
router.post('/phone', otpLimiter, async (req, res) => {
    const { firebase_token } = req.body;

    if (!firebase_token) {
        return res.status(400).json({ error: 'Firebase token is required' });
    }

    try {
        const decodedToken = await getAuth().verifyIdToken(firebase_token);
        const { phone_number, uid } = decodedToken;

        if (!phone_number) {
            return res.status(400).json({ error: 'No phone number associated with token' });
        }

        // Search user by phone number
        let result = await pool.query('SELECT user_id, email, phone, full_name, role, avatar_url FROM users WHERE phone = $1', [phone_number]);
        let user;

        if (result.rows.length === 0) {
            const cleanPhone = phone_number.replace(/\D/g, '');
            const fallbackEmail = `${cleanPhone}@phone.printit.in`;
            const last4 = cleanPhone.slice(-4);
            
            const insertResult = await pool.query(
                `INSERT INTO users (email, phone, full_name, role) 
                 VALUES ($1, $2, $3, 'customer') 
                 RETURNING user_id, email, phone, full_name, role, avatar_url`,
                [fallbackEmail, phone_number, `Customer ${last4}`]
            );
            user = insertResult.rows[0];
        } else {
            user = result.rows[0];
        }

        // Retroactively link past guest orders to this user
        try {
            const cleanDigits = phone_number.replace(/\D/g, '').slice(-10);
            await pool.query(
                `UPDATE orders SET customer_id = $1 
                 WHERE customer_id IS NULL AND (
                     print_instructions ILIKE '%' || $2 || '%'
                 )`,
                [user.user_id, cleanDigits]
            );
        } catch (linkErr) {
            console.warn('Retroactive order link warning:', linkErr.message);
        }

        const token = jwt.sign(
            { user_id: user.user_id, email: user.email, phone: user.phone, role: user.role },
            process.env.JWT_SECRET,
            { expiresIn: '7d' }
        );

        res.json({
            message: 'Phone login successful',
            token,
            user: {
                user_id: user.user_id,
                email: user.email,
                full_name: user.full_name,
                phone: user.phone,
                avatar_url: user.avatar_url,
                role: user.role
            }
        });
    } catch (err) {
        console.error('Phone login error:', err.message);
        res.status(401).json({ error: 'Phone authentication verification failed' });
    }
});

// POST /api/auth/reset-password — Password Reset (Generates secure 15-min single-use token)
router.post('/reset-password', passwordResetLimiter, async (req, res) => {
    const { email } = req.body;
    if (!email) {
        return res.status(400).json({ error: 'Email address is required' });
    }

    try {
        await ensureAuthSecurityTables();
        const userRes = await pool.query('SELECT user_id, email FROM users WHERE email = $1', [email]);
        
        let resetToken = null;
        if (userRes.rows.length > 0) {
            const user = userRes.rows[0];
            const rawToken = crypto.randomBytes(32).toString('hex');
            const tokenHash = crypto.createHash('sha256').update(rawToken).digest('hex');

            // Invalidate any existing unused reset tokens for this user
            await pool.query('UPDATE password_resets SET used = true WHERE user_id = $1 AND used = false', [user.user_id]);

            // Insert new single-use token with 15-minute expiration
            await pool.query(
                `INSERT INTO password_resets (user_id, token_hash, expires_at)
                 VALUES ($1, $2, NOW() + INTERVAL '15 minutes')`,
                [user.user_id, tokenHash]
            );

            resetToken = rawToken;
        }

        // Response: In automated test environment expose token for integration test suites; otherwise never expose token
        const isTestEnv = process.env.NODE_ENV === 'test';
        return res.json({
            message: 'If an account exists with this email, password reset instructions have been dispatched.',
            ...(isTestEnv && resetToken ? { reset_token: resetToken } : {})
        });

    } catch (err) {
        console.error('Password reset error:', err.message);
        res.status(500).json({ error: 'Failed to process password reset request' });
    }
});

// POST /api/auth/reset-password/confirm — Confirm password reset with token
router.post('/reset-password/confirm', passwordResetLimiter, async (req, res) => {
    const { token, new_password } = req.body;

    if (!token || !new_password) {
        return res.status(400).json({ error: 'Reset token and new password are required' });
    }

    if (new_password.length < 6) {
        return res.status(400).json({ error: 'Password must be at least 6 characters long' });
    }

    const client = await pool.connect();
    try {
        await client.query('BEGIN');
        await ensureAuthSecurityTables();

        const tokenHash = crypto.createHash('sha256').update(token.trim()).digest('hex');

        // Check if token exists, is unused, and has not expired
        const resetRes = await client.query(
            `SELECT id, user_id, expires_at, used 
             FROM password_resets 
             WHERE token_hash = $1 FOR UPDATE`,
            [tokenHash]
        );

        if (resetRes.rows.length === 0 || resetRes.rows[0].used || new Date(resetRes.rows[0].expires_at) < new Date()) {
            await client.query('ROLLBACK');
            return res.status(400).json({ error: 'Invalid, expired, or previously used password reset token' });
        }

        const resetRecord = resetRes.rows[0];

        // Hash new password
        const salt = await bcrypt.genSalt(10);
        const password_hash = await bcrypt.hash(new_password, salt);

        // Update user's password
        await client.query(
            'UPDATE users SET password_hash = $1 WHERE user_id = $2',
            [password_hash, resetRecord.user_id]
        );

        // Mark token as used
        await client.query(
            'UPDATE password_resets SET used = true WHERE id = $1',
            [resetRecord.id]
        );

        await client.query('COMMIT');

        res.json({
            message: 'Password successfully reset. You may now log in with your new credentials.'
        });

    } catch (err) {
        await client.query('ROLLBACK');
        console.error('Password reset confirmation error:', err.message);
        res.status(500).json({ error: 'Failed to reset password' });
    } finally {
        client.release();
    }
});

// POST /api/auth/logout — Invalidate current JWT token (Blacklist)
router.post('/logout', auth, async (req, res) => {
    try {
        await ensureAuthSecurityTables();
        const token = req.token;
        if (token) {
            const tokenHash = crypto.createHash('sha256').update(token).digest('hex');
            const expiresAt = req.user && req.user.exp 
                ? new Date(req.user.exp * 1000) 
                : new Date(Date.now() + 7 * 24 * 60 * 60 * 1000);

            await pool.query(
                `INSERT INTO jwt_blacklist (token_hash, expires_at)
                 VALUES ($1, $2)
                 ON CONFLICT (token_hash) DO NOTHING`,
                [tokenHash, expiresAt]
            );
        }

        res.json({ message: 'Logged out successfully. Session invalidated.' });
    } catch (err) {
        console.error('Logout error:', err.message);
        res.status(500).json({ error: 'Failed to process logout' });
    }
});


// GET /api/auth/me — Get current user profile
router.get('/me', auth, async (req, res) => {
    try {
        const result = await pool.query('SELECT user_id, email, full_name, phone, avatar_url, role, default_print_options FROM users WHERE user_id = $1', [req.user.user_id]);
        if (result.rows.length === 0) {
            return res.status(404).json({ error: 'User not found' });
        }
        res.json(result.rows[0]);
    } catch (err) {
        console.error('Fetch user error:', err);
        res.status(500).json({ error: 'Failed to fetch user profile' });
    }
});

// GET /api/auth/profile — Get current user profile (with user wrapper for customer app consistency)
router.get('/profile', auth, async (req, res) => {
    try {
        const result = await pool.query('SELECT user_id, email, full_name, phone, avatar_url, role, default_print_options FROM users WHERE user_id = $1', [req.user.user_id]);
        if (result.rows.length === 0) {
            return res.status(404).json({ error: 'User not found' });
        }
        res.json({ user: result.rows[0], ...result.rows[0] });
    } catch (err) {
        console.error('Fetch profile error:', err);
        res.status(500).json({ error: 'Failed to fetch user profile' });
    }
});

// PATCH /api/auth/preferences — Update user default print options
router.patch('/preferences', auth, async (req, res) => {
    const { default_print_options } = req.body;
    try {
        const result = await pool.query(
            'UPDATE users SET default_print_options = $1 WHERE user_id = $2 RETURNING user_id, default_print_options',
            [JSON.stringify(default_print_options), req.user.user_id]
        );
        res.json({ message: 'Preferences updated', user: result.rows[0] });
    } catch (err) {
        console.error('Update preferences error:', err);
        res.status(500).json({ error: 'Failed to update preferences' });
    }
});

// POST /api/auth/fcm-token — Save FCM token
router.post('/fcm-token', auth, async (req, res) => {
    const { fcm_token } = req.body;

    if (!fcm_token) {
        return res.status(400).json({ error: 'FCM token is required' });
    }

    try {
        await pool.query(
            'UPDATE users SET fcm_token = $1 WHERE user_id = $2',
            [fcm_token, req.user.user_id]
        );
        res.json({ message: 'FCM token saved successfully' });
    } catch (err) {
        console.error('Save FCM token error:', err);
        res.status(500).json({ error: 'Failed to save FCM token' });
    }
});

// DELETE /api/auth/fcm-token — Remove FCM token
router.delete('/fcm-token', auth, async (req, res) => {
    try {
        await pool.query(
            'UPDATE users SET fcm_token = NULL WHERE user_id = $1',
            [req.user.user_id]
        );
        res.json({ message: 'FCM token removed successfully' });
    } catch (err) {
        console.error('Remove FCM token error:', err);
        res.status(500).json({ error: 'Failed to remove FCM token' });
    }
});

// PUT /api/auth/profile — Update user profile (name, phone, avatar, email)
router.put('/profile', auth, async (req, res) => {
    const { full_name, phone, avatar_url, email } = req.body;
    try {
        if (email) {
            // Check if the new email is already in use by another user
            const emailCheck = await pool.query('SELECT user_id FROM users WHERE email = $1 AND user_id != $2', [email, req.user.user_id]);
            if (emailCheck.rows.length > 0) {
                return res.status(400).json({ error: 'Email already in use' });
            }
        }

        const result = await pool.query(
            'UPDATE users SET full_name = COALESCE($1, full_name), phone = COALESCE($2, phone), avatar_url = COALESCE($3, avatar_url), email = COALESCE($4, email) WHERE user_id = $5 RETURNING user_id, email, full_name, phone, avatar_url, role',
            [full_name, phone, avatar_url, email, req.user.user_id]
        );
        if (result.rows.length === 0) {
            return res.status(404).json({ error: 'User not found' });
        }
        res.json({ message: 'Profile updated', user: result.rows[0] });
    } catch (err) {
        console.error('Update profile error:', err);
        res.status(500).json({ error: 'Failed to update profile' });
    }
});

// DELETE /api/auth/account — Permanently delete / anonymize user account and purge PII
router.delete('/account', auth, async (req, res) => {
    const userId = req.user.user_id;
    const client = await pool.connect();
    try {
        await client.query('BEGIN');

        // Check if user exists
        const userRes = await client.query('SELECT user_id, role FROM users WHERE user_id = $1', [userId]);
        if (userRes.rows.length === 0) {
            await client.query('ROLLBACK');
            return res.status(404).json({ error: 'User account not found' });
        }

        // Try direct deletion if no restrictive relations exist
        let deleted = false;
        try {
            await client.query('DELETE FROM users WHERE user_id = $1', [userId]);
            deleted = true;
        } catch (fkErr) {
            // If historical foreign keys exist (orders, financial ledger), anonymize and purge all personal PII
            const anonymousEmail = `deleted_${userId}_${Date.now()}@purged.printit.in`;
            await client.query(
                `UPDATE users 
                 SET full_name = 'Deleted User',
                     email = $1,
                     phone = NULL,
                     avatar_url = NULL,
                     password_hash = NULL,
                     google_id = NULL,
                     fcm_token = NULL,
                     wallet_balance = 0.00
                 WHERE user_id = $2`,
                [anonymousEmail, userId]
            );
        }

        await client.query('COMMIT');
        res.json({ message: 'Account and personal data successfully deleted' });
    } catch (err) {
        await client.query('ROLLBACK');
        console.error('Account deletion error:', err);
        res.status(500).json({ error: 'Failed to delete account' });
    } finally {
        client.release();
    }
});

module.exports = router;

