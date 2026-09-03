require('dotenv').config({ path: require('path').resolve(__dirname, '.env') });
const pool = require('./src/config/db');

(async () => {
  try {
    const res = await pool.query('SELECT user_id, email, password_hash, full_name, phone, role, avatar_url, google_id, default_print_options, wallet_balance, fcm_token, created_at FROM users WHERE email = $1', ['printitsupport@gmail.com']);
    console.log('Query success:', res.rows);
  } catch(e) {
    console.error('Query failed:', e);
  } finally {
    pool.end();
  }
})();
