const pool = require('../config/db');

/**
 * Migrates the orders table to include printing mode and secure storage lifecycle tracking columns.
 * Runs idempotently on server bootstrap.
 */
async function setupPrintingModeDb() {
    let client;
    try {
        client = await pool.connect();
    } catch (connErr) {
        console.warn('⚠️ setupPrintingModeDb: DB connection not available yet:', connErr.message);
        return;
    }

    try {
        await client.query('BEGIN');

        // 1. Add print_mode column (default 'normal')
        await client.query(`
            DO $$ 
            BEGIN
                IF NOT EXISTS (
                    SELECT 1 FROM information_schema.columns 
                    WHERE table_name = 'orders' AND column_name = 'print_mode'
                ) THEN
                    ALTER TABLE orders ADD COLUMN print_mode VARCHAR(20) DEFAULT 'normal';
                END IF;
            END $$;
        `);

        // 2. Add storage_path column
        await client.query(`
            DO $$ 
            BEGIN
                IF NOT EXISTS (
                    SELECT 1 FROM information_schema.columns 
                    WHERE table_name = 'orders' AND column_name = 'storage_path'
                ) THEN
                    ALTER TABLE orders ADD COLUMN storage_path VARCHAR(255);
                END IF;
            END $$;
        `);

        // 3. Add files_deleted_at column
        await client.query(`
            DO $$ 
            BEGIN
                IF NOT EXISTS (
                    SELECT 1 FROM information_schema.columns 
                    WHERE table_name = 'orders' AND column_name = 'files_deleted_at'
                ) THEN
                    ALTER TABLE orders ADD COLUMN files_deleted_at TIMESTAMP WITH TIME ZONE NULL;
                END IF;
            END $$;
        `);

        // 4. Add deletion_status column
        await client.query(`
            DO $$ 
            BEGIN
                IF NOT EXISTS (
                    SELECT 1 FROM information_schema.columns 
                    WHERE table_name = 'orders' AND column_name = 'deletion_status'
                ) THEN
                    ALTER TABLE orders ADD COLUMN deletion_status VARCHAR(50) DEFAULT 'active';
                END IF;
            END $$;
        `);

        // 5. Add secure_expires_at column
        await client.query(`
            DO $$ 
            BEGIN
                IF NOT EXISTS (
                    SELECT 1 FROM information_schema.columns 
                    WHERE table_name = 'orders' AND column_name = 'secure_expires_at'
                ) THEN
                    ALTER TABLE orders ADD COLUMN secure_expires_at TIMESTAMP WITH TIME ZONE NULL;
                END IF;
            END $$;
        `);

        // 6. Ensure indices exist for fast cleanup queries
        await client.query(`
            CREATE INDEX IF NOT EXISTS idx_orders_print_mode_cleanup 
            ON orders (print_mode, files_deleted, status);
        `);

        await client.query(`
            CREATE INDEX IF NOT EXISTS idx_orders_secure_expiry 
            ON orders (secure_expires_at) 
            WHERE print_mode = 'secure' AND files_deleted = false;
        `);

        await client.query('COMMIT');
        console.log('✅ Printing Mode & Secure Storage DB schema initialized successfully.');
    } catch (err) {
        await client.query('ROLLBACK');
        console.error('❌ Error setting up printing mode DB schema:', err.message);
    } finally {
        client.release();
    }
}

module.exports = { setupPrintingModeDb };
