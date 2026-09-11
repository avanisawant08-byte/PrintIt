const express = require('express');
const router = express.Router();
const uploadRoutes = require('./uploadRoutes');
const authRoutes = require('./authRoutes');
const orderRoutes = require('./orderRoutes');
const paymentRoutes = require('./paymentRoutes');
const shopRoutes = require('./shopRoutes');
const publicRoutes = require('./publicRoutes');
const walletRoutes = require('./walletRoutes');
const productRoutes = require('./productRoutes');
const productOrderRoutes = require('./productOrderRoutes');
const supportRoutes = require('./supportRoutes');

const shopWalletRoutes = require('./shopWalletRoutes');
const shopAnalyticsRoutes = require('./shopAnalyticsRoutes');
const adminPayoutRoutes = require('./adminPayoutRoutes');
const storeRoutes = require('./storeRoutes');
const shopInventoryRoutes = require('./shopInventoryRoutes');
const adminProductRoutes = require('./adminProductRoutes');
const { apiLimiter } = require('../middleware/rateLimiter');

// GET /api/health — System health and maintenance status (exempt from rate limiter for uptime monitors)
router.get('/health', async (req, res) => {
  const isMaintenance = process.env.MAINTENANCE_MODE === 'true';
  const pool = require('../config/db');
  let dbStatus = 'connected';

  try {
    await pool.query('SELECT 1');
  } catch (err) {
    dbStatus = 'disconnected';
  }

  res.status(isMaintenance ? 503 : (dbStatus === 'connected' ? 200 : 500)).json({
    status: isMaintenance ? 'maintenance' : (dbStatus === 'connected' ? 'ok' : 'degraded'),
    maintenance: isMaintenance,
    database: dbStatus,
    timestamp: new Date().toISOString(),
    version: '1.0.0'
  });
});

// Mount global API rate limiter
router.use(apiLimiter);

// Mount routes
router.use('/auth', authRoutes);
router.use('/orders', orderRoutes);
router.use('/payments', paymentRoutes);
router.use('/upload', uploadRoutes);
router.use('/shop/analytics', shopAnalyticsRoutes);
router.use('/shop/inventory', shopInventoryRoutes);
router.use('/shop', shopRoutes);
router.use('/shop', shopWalletRoutes);
router.use('/admin/payouts', adminPayoutRoutes);
router.use('/admin/products', adminProductRoutes);
router.use('/public', publicRoutes);
router.use('/wallet', walletRoutes);
router.use('/products', productRoutes);
router.use('/product-orders', productOrderRoutes);
router.use('/store', storeRoutes);
router.use('/support', supportRoutes);


// POST /api/agent/pair â€” Agent Device Pairing by 6-character code
router.post('/agent/pair', async (req, res) => {
  const { pairingCode, deviceName = 'Counter-Station' } = req.body;
  const pool = require('../config/db');
  try {
    const code = (pairingCode || '').trim().toUpperCase();
    const result = await pool.query(
      'SELECT id, shop_id, pairing_code_expires_at FROM agent_devices WHERE pairing_code = $1 AND pairing_code_expires_at > NOW()',
      [code]
    );
    if (result.rows.length === 0) {
      return res.status(400).json({ error: 'Pairing code expired or invalid.' });
    }
    const device = result.rows[0];
    const token = 'agent-jwt-' + device.id + '-' + Date.now();
    await pool.query(
      "UPDATE agent_devices SET device_name = $1, status = 'ONLINE', pairing_code = NULL, auth_token = $2, last_seen_at = NOW() WHERE id = $3",
      [deviceName, token, device.id]
    );
    return res.json({ shopId: device.shop_id, deviceId: device.id, token });
  } catch (err) {
    console.error('Agent pairing error:', err);
    return res.status(500).json({ error: 'Failed to pair agent device' });
  }
});

module.exports = router;