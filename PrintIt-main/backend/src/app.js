// Server startup configuration
require('dotenv').config();

const { validateEnv } = require('./config/envValidation');
// Validate critical environment variables before bootstrapping services
validateEnv();

const express = require('express');
const cors = require('cors');
const helmet = require('helmet');
const path = require('path');
const routes = require('./routes');
const pool = require('./config/db');
const notificationRoutes = require('./routes/notificationRoutes');
const { setupShopCodeDb } = require('./utils/setupShopCodeDb');
const { setupStoreDb } = require('./utils/setupStoreDb');
const { setupPrintingModeDb } = require('./utils/setupPrintingModeDb');
const { setupOrdersAndSequencesDb } = require('./utils/setupOrdersAndSequencesDb');
const { startCleanupJob } = require('./utils/firebaseCleanup');
const { correlationIdMiddleware, errorHandler } = require('./middleware/errorHandler');

// Connect to DB immediately after import
pool.connect()
  .then(async (client) => {
      console.log("✅ Database pool connected successfully.");
      client.release();
      await setupOrdersAndSequencesDb();
      await setupShopCodeDb();
      await setupStoreDb();
      await setupPrintingModeDb();
      startCleanupJob();
  })
  .catch(err => console.error("❌ Database connection error:", err.message));

const app = express();

// Trust reverse proxy headers (Render, Cloudflare, load balancers)
app.set('trust proxy', 1);

// Attach correlation ID to every incoming request
app.use(correlationIdMiddleware);

// Security Headers: Helmet & Strict Content Security Policy
app.use(helmet({
    contentSecurityPolicy: {
        directives: {
            defaultSrc: ["'self'"],
            scriptSrc: [
                "'self'", 
                "https://checkout.razorpay.com", 
                "https://www.gstatic.com", 
                "https://apis.google.com"
            ],
            styleSrc: ["'self'", "'unsafe-inline'", "https://fonts.googleapis.com"],
            fontSrc: ["'self'", "https://fonts.gstatic.com"],
            imgSrc: ["'self'", "data:", "blob:", "https:"],
            connectSrc: [
                "'self'", 
                "https://*.supabase.co", 
                "https://*.supabase.com", 
                "https://*.googleapis.com", 
                "https://api.razorpay.com", 
                "https://*.firebasestorage.app", 
                "https://firebasestorage.googleapis.com"
            ],
            frameSrc: ["'self'", "https://api.razorpay.com"],
            objectSrc: ["'none'"],
            upgradeInsecureRequests: process.env.NODE_ENV === 'production' ? [] : null
        }
    },
    xContentTypeOptions: true, // X-Content-Type-Options: nosniff
    frameguard: { action: 'deny' }, // X-Frame-Options: DENY
    hsts: {
        maxAge: 31536000, // 1 year Strict-Transport-Security
        includeSubDomains: true,
        preload: true
    },
    crossOriginResourcePolicy: { policy: "cross-origin" }
}));

// CORS Configuration
const allowedOrigins = process.env.ALLOWED_ORIGINS 
    ? process.env.ALLOWED_ORIGINS.split(',').map(o => o.trim())
    : null;

const corsOptions = {
    origin: (origin, callback) => {
        // Allow non-browser clients (Flutter native mobile apps, curl, server-to-server)
        if (!origin) return callback(null, true);

        // Check explicitly allowed origins whitelist if set
        if (allowedOrigins && (allowedOrigins.includes('*') || allowedOrigins.includes(origin))) {
            return callback(null, true);
        }

        try {
            const parsed = new URL(origin);
            // Allow all Vercel deployments (*.vercel.app and vercel.app)
            if (parsed.hostname.endsWith('.vercel.app') || parsed.hostname === 'vercel.app') {
                return callback(null, true);
            }
            // Allow Render domains (*.onrender.com)
            if (parsed.hostname.endsWith('.onrender.com') || parsed.hostname === 'onrender.com') {
                return callback(null, true);
            }
            // Allow localhost & 127.0.0.1 on any port
            if (parsed.hostname === 'localhost' || parsed.hostname === '127.0.0.1') {
                return callback(null, true);
            }
            // Allow private LAN IPs (192.168.x.x, 10.x.x.x, 172.16-31.x.x)
            if (/^(192\.168\.|10\.|172\.(1[6-9]|2[0-9]|3[0-1])\.)/.test(parsed.hostname)) {
                return callback(null, true);
            }
        } catch (_) {
            if (origin.includes('vercel.app') || origin.includes('localhost') || origin.includes('127.0.0.1')) {
                return callback(null, true);
            }
        }

        // Return false gracefully instead of throwing an unhandled exception
        return callback(null, false);
    },
    credentials: true,
    methods: ['GET', 'POST', 'PUT', 'PATCH', 'DELETE', 'OPTIONS'],
    allowedHeaders: ['Content-Type', 'Authorization', 'X-Request-ID', 'Accept', 'Origin'],
    exposedHeaders: ['Content-Disposition', 'X-Request-ID']
};

app.use(cors(corsOptions));

app.use(express.json({ limit: '10mb' }));

// Serve static assets with secure caching
const publicPath = path.join(__dirname, '../public');
app.use(express.static(publicPath, {
    dotfiles: 'ignore',
    setHeaders: (res, filePath) => {
        const normalized = filePath.replace(/\\/g, '/');
        if (normalized.endsWith('.html') || normalized.includes('service_worker') || normalized.endsWith('manifest.json')) {
            res.setHeader('Cache-Control', 'no-store, no-cache, must-revalidate');
        } else if (normalized.includes('/assets/') || /[.-][a-zA-Z0-9_-]{8,}\.(js|css|wasm)$/.test(normalized)) {
            res.setHeader('Cache-Control', 'public, max-age=31536000, immutable');
        } else {
            res.setHeader('Cache-Control', 'public, max-age=86400, stale-while-revalidate=604800');
        }
    }
}));

// API Routes
app.use('/api', routes);
app.use('/api/notifications', notificationRoutes);

// Centralized error handler with correlation ID & response sanitization
app.use(errorHandler);

// Start server
if (require.main === module) {
  const PORT = process.env.PORT || 3000;
  app.listen(PORT, '0.0.0.0', () => {
    console.log(`Server is running on port ${PORT} [Env: ${process.env.NODE_ENV || 'production'}]`);
  });
}

module.exports = app;