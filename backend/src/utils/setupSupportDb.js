require('dotenv').config({ path: require('path').resolve(__dirname, '../../.env') });
const pool = require('../config/db');

async function setupSupportDb() {
  const client = await pool.connect();
  try {
    await client.query('BEGIN');

    // ENUM for ticket status if not exists
    await client.query(`
      DO $$ BEGIN
        CREATE TYPE ticket_status AS ENUM ('open', 'in_progress', 'resolved', 'closed');
      EXCEPTION
        WHEN duplicate_object THEN null;
      END $$;
    `);

    // support_tickets table
    await client.query(`
      CREATE TABLE IF NOT EXISTS support_tickets (
        ticket_id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
        ticket_token VARCHAR(20) UNIQUE NOT NULL,
        user_id UUID REFERENCES users(user_id) ON DELETE CASCADE,
        shop_id UUID REFERENCES shops(shop_id) ON DELETE CASCADE NULL,
        order_id VARCHAR(100) NULL,
        issue_type VARCHAR(100) NULL,
        subject VARCHAR(255) NOT NULL,
        description TEXT NOT NULL,
        status ticket_status DEFAULT 'open',
        created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
        updated_at TIMESTAMP WITH TIME ZONE DEFAULT NOW()
      );
    `);

    // ticket_messages table
    await client.query(`
      CREATE TABLE IF NOT EXISTS ticket_messages (
        message_id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
        ticket_id UUID REFERENCES support_tickets(ticket_id) ON DELETE CASCADE,
        sender_id UUID REFERENCES users(user_id) ON DELETE SET NULL,
        sender_role VARCHAR(50) NOT NULL, -- 'customer', 'shop', 'admin'
        message TEXT NOT NULL,
        created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW()
      );
    `);

    await client.query('COMMIT');
    console.log('Support DB setup completed successfully.');
  } catch (err) {
    await client.query('ROLLBACK');
    console.error('Error setting up support DB:', err);
  } finally {
    client.release();
    pool.end();
  }
}

setupSupportDb();
