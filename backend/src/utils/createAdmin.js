require('dotenv').config({ path: require('path').resolve(__dirname, '../../.env') });
const pool = require('../config/db');
const bcrypt = require('bcrypt');

async function createAdmin() {
  const email = process.env.ADMIN_EMAIL || 'admin@printit.local';
  const password = process.env.ADMIN_PASSWORD;
  const full_name = process.env.ADMIN_NAME || 'System Admin';

  if (!password) {
    console.error('❌ Error: ADMIN_PASSWORD environment variable is required to create an admin account.');
    process.exit(1);
  }

  const client = await pool.connect();
  try {
    const userCheck = await client.query('SELECT user_id FROM users WHERE email = $1', [email]);
    if (userCheck.rows.length > 0) {
      console.log(`Admin user (${email}) already exists.`);
      return;
    }

    const salt = await bcrypt.genSalt(10);
    const password_hash = await bcrypt.hash(password, salt);

    await client.query(
      `INSERT INTO users (email, password_hash, full_name, role) VALUES ($1, $2, $3, 'admin')`,
      [email, password_hash, full_name]
    );

    console.log(`✅ Admin user created successfully for: ${email}`);
  } catch (err) {
    console.error('Error creating admin user:', err);
  } finally {
    client.release();
    pool.end();
  }
}

createAdmin();
