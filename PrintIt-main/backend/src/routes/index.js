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

// Mount routes
router.use('/auth', authRoutes);
router.use('/orders', orderRoutes);
router.use('/payments', paymentRoutes);
router.use('/upload', uploadRoutes);
router.use('/shop/analytics', shopAnalyticsRoutes);
router.use('/shop', shopRoutes);
router.use('/shop', shopWalletRoutes);
router.use('/admin/payouts', adminPayoutRoutes);
router.use('/public', publicRoutes);
router.use('/wallet', walletRoutes);
router.use('/products', productRoutes);
router.use('/product-orders', productOrderRoutes);
router.use('/support', supportRoutes);

router.get('/test', (req, res) => {
  res.send('PrintIt API Working');
});

// GET /api/health — System health and maintenance status
router.get('/health', async (req, res) => {
  const isMaintenance = process.env.MAINTENANCE_MODE === 'true';
  const pool = require('../config/db');
  let dbStatus = 'connected';

  try {
    const client = await pool.connect();
    client.release();
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

module.exports = router;