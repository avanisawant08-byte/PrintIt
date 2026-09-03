require('dotenv').config({ path: require('path').resolve(__dirname, '../../.env') });
const pool = require('../config/db');
const bcrypt = require('bcrypt');

async function createAdmin() {
  const email = 'printitsupport@gmail.com';
  const password = 'adminpassword123';
  const full_name = 'System Admin';

  const client = await pool.connect();
  try {
    const userCheck = await client.query('SELECT user_id FROM users WHERE email = $1', [email]);
    if (userCheck.rows.length > 0) {
      console.log('Admin user already exists.');
      return;
    }

    const salt = await bcrypt.genSalt(10);
    const password_hash = await bcrypt.hash(password, salt);

    await client.query(
      `INSERT INTO users (email, password_hash, full_name, role) VALUES ($1, $2, $3, 'admin')`,
      [email, password_hash, full_name]
    );

    console.log('Admin user created successfully! Email: printitsupport@gmail.com, Password: adminpassword123');
  } catch (err) {
    console.error('Error creating admin user:', err);
  } finally {
    client.release();
    pool.end();
  }
}

createAdmin();
