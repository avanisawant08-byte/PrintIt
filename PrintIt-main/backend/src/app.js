// Server startup configuration
require('dotenv').config();

const express = require('express');
const cors = require('cors');
const helmet = require('helmet');
const path = require('path');
const routes = require('./routes');
const pool = require('./config/db');
const paymentRoutes = require('./routes/paymentRoutes');
const publicRoutes = require('./routes/publicRoutes');
const walletRoutes = require('./routes/walletRoutes');
const notificationRoutes = require('./routes/notificationRoutes');
const { startCleanupJob } = require('./utils/firebaseCleanup');
const { setupShopCodeDb } = require('./utils/setupShopCodeDb');
const { setupStoreDb } = require('./utils/setupStoreDb');

// Connect to DB immediately after import
pool.connect()
  .then((client) => {
      console.log("Database connected");
      client.release();
      setupShopCodeDb();
      setupStoreDb();
      startCleanupJob();
  })
  .catch(err => console.error("DB connection error:", err));

const app = express();

// Security Middleware: Set HTTP security headers
app.use(helmet({
    crossOriginResourcePolicy: { policy: "cross-origin" }
}));

// CORS Configuration
const allowedOrigins = process.env.ALLOWED_ORIGINS 
    ? process.env.ALLOWED_ORIGINS.split(',').map(o => o.trim())
    : null;

app.use(cors({
    origin: (origin, callback) => {
        // Allow requests with no origin (mobile Flutter app, CLI, server-to-server)
        if (!origin) return callback(null, true);
        if (!allowedOrigins || allowedOrigins.includes('*') || allowedOrigins.includes(origin)) {
            return callback(null, true);
        }
        return callback(new Error('CORS policy: Not allowed by CORS origin restriction'));
    },
    exposedHeaders: ['Content-Disposition']
}));
app.use(express.json());

// Serve only dedicated public static files with optimal caching headers
const publicPath = path.join(__dirname, '../public');
app.use(express.static(publicPath, {
    dotfiles: 'ignore',
    setHeaders: (res, filePath) => {
        const normalized = filePath.replace(/\\/g, '/');
        if (normalized.endsWith('.html') || normalized.includes('service_worker') || normalized.endsWith('manifest.json')) {
            res.setHeader('Cache-Control', 'no-store, no-cache, must-revalidate');
        } else if (normalized.includes('/assets/') || /[.-][a-zA-Z0-9_-]{8,}\.(js|css|wasm)$/.test(normalized)) {
            // Fingerprinted / hashed bundles can be cached immutably for 1 year
            res.setHeader('Cache-Control', 'public, max-age=31536000, immutable');
        } else {
            // General static media & icons
            res.setHeader('Cache-Control', 'public, max-age=86400, stale-while-revalidate=604800');
        }
    }
}));

// Routes
app.use('/api', routes);
app.use('/api/notifications', notificationRoutes);

// Error handling
app.use((err, req, res, next) => {
  console.error(err.stack);
  res.status(500).json({ error: 'Something went wrong!' });
});

// Start server
if (require.main === module) {
  const PORT = process.env.PORT || 3000;
  app.listen(PORT, '0.0.0.0', () => {
    console.log(`Server is running on http://0.0.0.0:${PORT}`);
  });
}

module.exports = app;