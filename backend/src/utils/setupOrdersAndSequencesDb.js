const pool = require('../config/db');

/**
 * Ensures critical sequences, tables, and columns exist for order creation & payments.
 * Runs idempotently on server bootstrap.
 */
async function setupOrdersAndSequencesDb() {
    let client;
    try {
        client = await pool.connect();
    } catch (connErr) {
        console.warn('⚠️ setupOrdersAndSequencesDb: DB connection not available yet:', connErr.message);
        return;
    }

    try {
        await client.query('BEGIN');

        // 1. Create order sequences if they do not exist
        await client.query(`CREATE SEQUENCE IF NOT EXISTS order_seq_express START 1;`);
        await client.query(`CREATE SEQUENCE IF NOT EXISTS order_seq_scheduled START 1;`);

        // 2. Ensure payments table exists
        await client.query(`
            CREATE TABLE IF NOT EXISTS payments (
                payment_id SERIAL PRIMARY KEY,
                razorpay_order_id VARCHAR(255),
                razorpay_payment_id VARCHAR(255) UNIQUE,
                status VARCHAR(50) DEFAULT 'captured',
                amount NUMERIC(10, 2),
                created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW()
            );
        `);

        // 3. Ensure critical columns on orders table exist
        await client.query(`
            DO $$ 
            BEGIN
                IF NOT EXISTS (
                    SELECT 1 FROM information_schema.columns 
                    WHERE table_name = 'orders' AND column_name = 'cancel_token'
                ) THEN
                    ALTER TABLE orders ADD COLUMN cancel_token VARCHAR(64);
                END IF;

                IF NOT EXISTS (
                    SELECT 1 FROM information_schema.columns 
                    WHERE table_name = 'orders' AND column_name = 'print_mode'
                ) THEN
                    ALTER TABLE orders ADD COLUMN print_mode VARCHAR(20) DEFAULT 'normal';
                END IF;

                IF NOT EXISTS (
                    SELECT 1 FROM information_schema.columns 
                    WHERE table_name = 'orders' AND column_name = 'deletion_status'
                ) THEN
                    ALTER TABLE orders ADD COLUMN deletion_status VARCHAR(50) DEFAULT 'active';
                END IF;

                IF NOT EXISTS (
                    SELECT 1 FROM information_schema.columns 
                    WHERE table_name = 'orders' AND column_name = 'files_deleted'
                ) THEN
                    ALTER TABLE orders ADD COLUMN files_deleted BOOLEAN DEFAULT false;
                END IF;

                IF NOT EXISTS (
                    SELECT 1 FROM information_schema.columns 
                    WHERE table_name = 'orders' AND column_name = 'files_deleted_at'
                ) THEN
                    ALTER TABLE orders ADD COLUMN files_deleted_at TIMESTAMP WITH TIME ZONE NULL;
                END IF;

                IF NOT EXISTS (
                    SELECT 1 FROM information_schema.columns 
                    WHERE table_name = 'orders' AND column_name = 'secure_expires_at'
                ) THEN
                    ALTER TABLE orders ADD COLUMN secure_expires_at TIMESTAMP WITH TIME ZONE NULL;
                END IF;

                IF NOT EXISTS (
                    SELECT 1 FROM information_schema.columns 
                    WHERE table_name = 'orders' AND column_name = 'storage_path'
                ) THEN
                    ALTER TABLE orders ADD COLUMN storage_path VARCHAR(255);
                END IF;
            END $$;
        `);

        // 4. Ensure payments unique index
        await client.query(`
            CREATE UNIQUE INDEX IF NOT EXISTS idx_payments_unique_razorpay_payment_id 
            ON payments(razorpay_payment_id) 
            WHERE razorpay_payment_id IS NOT NULL;
        `);

        await client.query('COMMIT');
        console.log('✅ Order sequences, payments table, and orders columns verified successfully.');
    } catch (err) {
        await client.query('ROLLBACK');
        console.error('❌ Error setting up orders and sequences DB schema:', err.message);
    } finally {
        client.release();
    }
}

module.exports = { setupOrdersAndSequencesDb };
