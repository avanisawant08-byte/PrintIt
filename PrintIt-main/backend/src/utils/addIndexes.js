require('dotenv').config();
const pool = require('../config/db');

async function addIndexes() {
    console.log('Adding database indexes...');
    const client = await pool.connect();
    try {
        await client.query('BEGIN');
        
        // Orders table indexes
        await client.query(`CREATE INDEX IF NOT EXISTS idx_orders_shop_id ON orders(shop_id);`);
        await client.query(`CREATE INDEX IF NOT EXISTS idx_orders_customer_id ON orders(customer_id);`);
        await client.query(`CREATE INDEX IF NOT EXISTS idx_orders_status ON orders(status);`);
        await client.query(`CREATE INDEX IF NOT EXISTS idx_orders_created_at ON orders(created_at DESC);`);
        
        // Product Orders table indexes
        await client.query(`CREATE INDEX IF NOT EXISTS idx_product_orders_shop_id ON product_orders(shop_id);`);
        await client.query(`CREATE INDEX IF NOT EXISTS idx_product_orders_customer_id ON product_orders(customer_id);`);
        await client.query(`CREATE INDEX IF NOT EXISTS idx_product_orders_status ON product_orders(status);`);
        
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
