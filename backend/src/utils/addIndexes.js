require('dotenv').config();
const pool = require('../config/db');

async function addIndexes() {
    console.log('Adding database indexes...');
    const client = await pool.connect();
    try {
        await client.query('BEGIN');
        
        // Orders table indexes & columns
        await client.query(`ALTER TABLE orders ADD COLUMN IF NOT EXISTS cancel_token VARCHAR(64);`);
        await client.query(`CREATE INDEX IF NOT EXISTS idx_orders_shop_id ON orders(shop_id);`);
        await client.query(`CREATE INDEX IF NOT EXISTS idx_orders_customer_id ON orders(customer_id);`);
        await client.query(`CREATE INDEX IF NOT EXISTS idx_orders_status ON orders(status);`);
        await client.query(`CREATE INDEX IF NOT EXISTS idx_orders_created_at ON orders(created_at DESC);`);
        // Use a full UNIQUE constraint (not partial index) so ON CONFLICT (payment_id) works in PostgreSQL
        await client.query(`
            DO $$ BEGIN
                IF NOT EXISTS (SELECT 1 FROM pg_constraint WHERE conname = 'orders_payment_id_unique') THEN
                    BEGIN
                        ALTER TABLE orders ADD CONSTRAINT orders_payment_id_unique UNIQUE (payment_id);
                    EXCEPTION WHEN OTHERS THEN
                        RAISE NOTICE 'Could not add orders_payment_id_unique: %', SQLERRM;
                    END;
                END IF;
            END $$;
        `);
        await client.query(`CREATE INDEX IF NOT EXISTS idx_orders_cancel_token ON orders(cancel_token);`);
        
        // Product Orders table indexes
        await client.query(`CREATE INDEX IF NOT EXISTS idx_product_orders_shop_id ON product_orders(shop_id);`);
        await client.query(`CREATE INDEX IF NOT EXISTS idx_product_orders_customer_id ON product_orders(customer_id);`);
        await client.query(`CREATE INDEX IF NOT EXISTS idx_product_orders_status ON product_orders(status);`);
        // Use a full UNIQUE constraint (not partial index) so ON CONFLICT (payment_id) works in PostgreSQL
        await client.query(`
            DO $$ BEGIN
                IF NOT EXISTS (SELECT 1 FROM pg_constraint WHERE conname = 'product_orders_payment_id_unique') THEN
                    BEGIN
                        ALTER TABLE product_orders ADD CONSTRAINT product_orders_payment_id_unique UNIQUE (payment_id);
                    EXCEPTION WHEN OTHERS THEN
                        RAISE NOTICE 'Could not add product_orders_payment_id_unique: %', SQLERRM;
                    END;
                END IF;
            END $$;
        `);
        
        // Payments table indexes
        await client.query(`CREATE UNIQUE INDEX IF NOT EXISTS idx_payments_unique_razorpay_payment_id ON payments(razorpay_payment_id) WHERE razorpay_payment_id IS NOT NULL;`);
        
        await client.query('COMMIT');
        console.log('Successfully added missing indexes.');
    } catch (err) {
        await client.query('ROLLBACK');
        console.error('Error adding indexes:', err);
    } finally {
        client.release();
        pool.end();
    }
}

addIndexes();
