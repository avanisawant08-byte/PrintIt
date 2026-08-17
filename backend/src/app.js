require('dotenv').config();

console.log("ENV FILE CHECK:", process.env);

const express = require('express');
const cors = require('cors');
const routes = require('./routes');
const pool = require('./config/db');
const paymentRoutes = require('./routes/paymentRoutes');
const publicRoutes = require('./routes/publicRoutes');
const walletRoutes = require('./routes/walletRoutes');
const notificationRoutes = require('./routes/notificationRoutes');
const { startCleanupJob } = require('./utils/firebaseCleanup');

// ✅ Connect to DB immediately after import
pool.connect()
  .then((client) => {
      console.log("✅ Database connected");
      client.release();
      startCleanupJob();
  })
  .catch(err => console.error("❌ DB connection error:", err));

const app = express();

// Middleware
app.use(cors({ exposedHeaders: ['Content-Disposition'] }));
app.use(express.json());
const path = require('path');
// Serve static files — disable browser caching so HTML/JS changes load immediately
app.use(express.static(path.join(__dirname, '../'), {
    setHeaders: (res, filePath) => {
        if (filePath.endsWith('.html')) {
            res.setHeader('Cache-Control', 'no-store, no-cache, must-revalidate');
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