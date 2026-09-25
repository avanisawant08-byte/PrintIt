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

// PUT /api/agent/status — Agent reports installed printers, default printer, and heartbeat
router.put('/agent/status', async (req, res) => {
  const authHeader = req.headers.authorization || '';
  const token = authHeader.replace('Bearer ', '').trim();
  if (!token) return res.status(401).json({ error: 'Missing agent auth token' });

  const { available_printers, selected_printer, agent_version } = req.body;
  const pool = require('../config/db');

  try {
    const result = await pool.query(
      `UPDATE agent_devices 
       SET status = 'ONLINE',
           last_seen_at = NOW(),
           available_printers = COALESCE($1::jsonb, available_printers),
           selected_printer = COALESCE($2, selected_printer),
           agent_version = COALESCE($3, agent_version),
           updated_at = NOW()
       WHERE auth_token = $4
       RETURNING id, shop_id, device_name, selected_printer, available_printers, status`,
      [
        available_printers ? JSON.stringify(available_printers) : null,
        selected_printer || null,
        agent_version || null,
        token
      ]
    );

    if (result.rows.length === 0) {
      return res.status(401).json({ error: 'Invalid agent token' });
    }

    res.json({ success: true, device: result.rows[0] });
  } catch (err) {
    console.error('Agent status update error:', err);
    res.status(500).json({ error: 'Failed to update agent status' });
  }
});





// GET /api/agent/download-url — Returns a valid download URL for the local print agent.
// Uses PostgreSQL to look up the URL stored at upload time (no Firebase Admin SDK needed).
// New uploads (after the backend token fix) embed &token= in the stored URL.
// Legacy files fall back to the raw URL — the agent will still attempt the download.
router.get('/agent/download-url', async (req, res) => {
  const pool = require('../config/db');

  // Authenticate agent using pairing token stored in agent_devices
  const authHeader = req.headers.authorization || '';
  const token = authHeader.replace('Bearer ', '').trim();
  if (!token) return res.status(401).json({ error: 'Missing agent auth token' });

  try {
    const deviceResult = await pool.query(
      'SELECT id, shop_id FROM agent_devices WHERE auth_token = $1',
      [token]
    );
    if (deviceResult.rows.length === 0) {
      return res.status(401).json({ error: 'Invalid or expired agent token' });
    }

    const device = deviceResult.rows[0];
    const storagePath = req.query.path;
    if (!storagePath) return res.status(400).json({ error: 'Missing ?path= query parameter' });

    // 1. PRIMARY & MOST SECURE: Generate time-limited 1-hour signed URL via Firebase Admin SDK
    try {
      const { getStorage } = require('../config/firebase');
      const bucket = getStorage().bucket();
      const file = bucket.file(storagePath);
      const [exists] = await file.exists();

      if (exists) {
        const [signedUrl] = await file.getSignedUrl({
          action: 'read',
          expires: Date.now() + 60 * 60 * 1000 // 1 hour expiration
        });

        console.log('[Agent] Generated 1-hour time-limited signed URL for path:', storagePath);

        // Record security audit log
        pool.query(
          'INSERT INTO print_job_audit (device_id, action, ip_address, details) VALUES ($1, $2, $3, $4)',
          [device.id, 'DOWNLOAD_URL_REQUESTED', req.ip || req.socket.remoteAddress, JSON.stringify({ path: storagePath, expires_in_sec: 3600 })]
        ).catch(auditErr => console.warn('[Audit] Failed to log:', auditErr.message));

        return res.json({
          url: signedUrl,
          storage_path: storagePath,
          expires_in: 3600,
          is_signed_url: true
        });
      }
    } catch (adminErr) {
      console.warn('[Agent] Firebase Admin signed URL generation failed, checking database fallback:', adminErr.message);
    }

    // 2. FALLBACK: Search orders table for stored token URL
    const partialMatch = '%' + storagePath.replace(/[%_]/g, c => '\\' + c) + '%';
    const ordersResult = await pool.query(
      'SELECT files FROM orders WHERE files::text LIKE $1 ORDER BY created_at DESC LIMIT 5',
      [partialMatch]
    );

    for (const row of ordersResult.rows) {
      let files = row.files;
      if (typeof files === 'string') {
        try { files = JSON.parse(files); } catch (e) { continue; }
      }
      if (!Array.isArray(files)) continue;

      for (const entry of files) {
        if (!entry) continue;
        const fileInfo = (entry.file_info && typeof entry.file_info === 'object') ? entry.file_info : entry;
        const url = fileInfo.s3_key || fileInfo.url || '';
        if (url && url.includes(encodeURIComponent(storagePath).replace(/%2F/gi, '%2F')) && url.includes('&token=')) {
          console.log('[Agent] DB lookup found verified token URL for path:', storagePath);
          return res.json({ url, storage_path: storagePath });
        }
      }
    }

    // 3. Fallback: bare URL
    const bucketName = process.env.FIREBASE_STORAGE_BUCKET || 'printit-4d823.firebasestorage.app';
    const fallbackUrl = 'https://firebasestorage.googleapis.com/v0/b/' + bucketName + '/o/' + encodeURIComponent(storagePath) + '?alt=media';
    console.warn('[Agent] Returning bare URL as last resort:', storagePath);
    return res.json({ url: fallbackUrl, storage_path: storagePath, note: 'no_token_available' });

  } catch (err) {
    console.error('[Agent] download-url error:', err);
    return res.status(500).json({ error: 'Failed to resolve download URL. Please try again.' });
  }
});

// GET /api/agent/jobs — Agent polls for pending print jobs assigned to its shop
router.get('/agent/jobs', async (req, res) => {
  const authHeader = req.headers.authorization || '';
  const token = authHeader.replace('Bearer ', '').trim();
  if (!token) return res.status(401).json({ error: 'Missing agent auth token' });

  const pool = require('../config/db');
  try {
    // Resolve shop from agent token
    const deviceRes = await pool.query(
      'SELECT id, shop_id FROM agent_devices WHERE auth_token = $1',
      [token]
    );
    if (deviceRes.rows.length === 0) {
      return res.status(401).json({ error: 'Invalid or expired agent token' });
    }
    const { id: deviceId, shop_id } = deviceRes.rows[0];

    // Heartbeat: keep the agent marked ONLINE whenever it polls
    pool.query(
      "UPDATE agent_devices SET status = 'ONLINE', last_seen_at = NOW() WHERE id = $1",
      [deviceId]
    ).catch(e => console.warn('[Agent] Heartbeat update failed:', e.message));

    // Ensure agent_print_jobs exists (idempotent)
    await pool.query(`
      CREATE TABLE IF NOT EXISTS agent_print_jobs (
        id           SERIAL PRIMARY KEY,
        shop_id      TEXT NOT NULL,
        order_id     TEXT NOT NULL,
        file_index   INT NOT NULL DEFAULT 0,
        storage_path TEXT,
        print_options JSONB,
        status       TEXT NOT NULL DEFAULT 'pending',
        created_at   TIMESTAMPTZ NOT NULL DEFAULT NOW(),
        acked_at     TIMESTAMPTZ
      )
    `);

    // Fetch pending jobs for this shop (created in last 2 hours, not yet acked)
    const jobsRes = await pool.query(
      `SELECT id, order_id, file_index, storage_path, print_options
       FROM agent_print_jobs
       WHERE shop_id = $1 AND status = 'pending' AND created_at > NOW() - INTERVAL '2 hours'
       ORDER BY created_at ASC
       LIMIT 10`,
      [shop_id]
    );

    return res.json({ jobs: jobsRes.rows });
  } catch (err) {
    console.error('[Agent Jobs] Error:', err.message);
    return res.status(500).json({ error: 'Failed to fetch agent jobs' });
  }
});

// PUT /api/agent/jobs/:jobId/ack — Agent acknowledges it has started printing a job
router.put('/agent/jobs/:jobId/ack', async (req, res) => {
  const authHeader = req.headers.authorization || '';
  const token = authHeader.replace('Bearer ', '').trim();
  if (!token) return res.status(401).json({ error: 'Missing agent auth token' });

  const pool = require('../config/db');
  try {
    const deviceRes = await pool.query(
      'SELECT id, shop_id FROM agent_devices WHERE auth_token = $1',
      [token]
    );
    if (deviceRes.rows.length === 0) {
      return res.status(401).json({ error: 'Invalid or expired agent token' });
    }
    const { shop_id } = deviceRes.rows[0];

    await pool.query(
      `UPDATE agent_print_jobs
       SET status = 'printing', acked_at = NOW()
       WHERE id = $1 AND shop_id = $2 AND status = 'pending'`,
      [req.params.jobId, shop_id]
    );

    return res.json({ success: true });
  } catch (err) {
    console.error('[Agent Ack] Error:', err.message);
    return res.status(500).json({ error: 'Failed to acknowledge job' });
  }
});

module.exports = router;