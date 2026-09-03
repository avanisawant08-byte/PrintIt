require('dotenv').config({ path: require('path').resolve(__dirname, '../../.env') });
const pool = require('../config/db');

async function setupWalletDb() {
  const client = await pool.connect();
  try {
    await client.query('BEGIN');

    // 1. shop_wallets
    await client.query(`
      CREATE TABLE IF NOT EXISTS shop_wallets (
        shop_id UUID PRIMARY KEY REFERENCES shops(shop_id) ON DELETE CASCADE,
        available_balance NUMERIC(12, 2) NOT NULL DEFAULT 0.00,
        pending_balance NUMERIC(12, 2) NOT NULL DEFAULT 0.00,
        total_earned NUMERIC(12, 2) NOT NULL DEFAULT 0.00,
        total_withdrawn NUMERIC(12, 2) NOT NULL DEFAULT 0.00,
        updated_at TIMESTAMP WITH TIME ZONE DEFAULT NOW()
      );
    `);

    // 2. shop_bank_accounts
    await client.query(`
      CREATE TABLE IF NOT EXISTS shop_bank_accounts (
        id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
        shop_id UUID NOT NULL REFERENCES shops(shop_id) ON DELETE CASCADE,
        account_holder_name VARCHAR(255) NOT NULL,
        account_number VARCHAR(100) NOT NULL,
        ifsc_code VARCHAR(20) NOT NULL,
        bank_name VARCHAR(255),
        account_type VARCHAR(20) DEFAULT 'savings',
        upi_id VARCHAR(100),
        is_primary BOOLEAN DEFAULT true,
        created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW()
      );
    `);

    // 3. withdrawal_requests
    await client.query(`
      CREATE TABLE IF NOT EXISTS withdrawal_requests (
        id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
        shop_id UUID NOT NULL REFERENCES shops(shop_id) ON DELETE CASCADE,
        amount NUMERIC(12, 2) NOT NULL,
        net_payout NUMERIC(12, 2) NOT NULL,
        bank_account_id UUID REFERENCES shop_bank_accounts(id) ON DELETE SET NULL,
        status VARCHAR(20) DEFAULT 'pending',
        utr_number VARCHAR(100),
        rejection_reason TEXT,
        processed_by UUID REFERENCES users(user_id) ON DELETE SET NULL,
        requested_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
        processed_at TIMESTAMP WITH TIME ZONE
      );
    `);

    // 4. shop_wallet_transactions
    await client.query(`
      CREATE TABLE IF NOT EXISTS shop_wallet_transactions (
        id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
        shop_id UUID NOT NULL REFERENCES shops(shop_id) ON DELETE CASCADE,
        type VARCHAR(20) NOT NULL,
        order_id UUID,
        gross_amount NUMERIC(12, 2) DEFAULT 0.00,
        platform_fee NUMERIC(12, 2) DEFAULT 0.00,
        gst_on_fee NUMERIC(12, 2) DEFAULT 0.00,
        net_amount NUMERIC(12, 2) NOT NULL,
        balance_after NUMERIC(12, 2) NOT NULL,
        status VARCHAR(20) DEFAULT 'confirmed',
        description TEXT,
        created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW()
      );
    `);

    await client.query('COMMIT');
    console.log('✅ Wallet DB tables setup completed successfully.');
  } catch (err) {
    await client.query('ROLLBACK');
    console.error('❌ Error setting up wallet DB:', err);
  } finally {
    client.release();
    pool.end();
  }
}

setupWalletDb();
