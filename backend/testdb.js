require('dotenv').config({ path: require('path').resolve(__dirname, '.env') });
const pool = require('./src/config/db');

(async () => {
  try {
    const res = await pool.query('SELECT 1 as connected, NOW() as current_time');
    console.log('Database connection verification success:', res.rows[0]);
  } catch(e) {
    console.error('Database query failed:', e.message);
  } finally {
    pool.end();
  }
})();
