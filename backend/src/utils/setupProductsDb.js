require('dotenv').config();
const pool = require('../config/db');

async function setupProductsDb() {
    console.log('Starting products database setup...');
    try {
        // Create products table
        await pool.query(`
            CREATE TABLE IF NOT EXISTS products (
                product_id        UUID PRIMARY KEY DEFAULT gen_random_uuid(),
                shop_id           UUID REFERENCES shops(shop_id) ON DELETE CASCADE,
                title             VARCHAR(255) NOT NULL,
                description       TEXT,
                branch            VARCHAR(100) NOT NULL,
                course_type       VARCHAR(50) NOT NULL,
                semester          VARCHAR(20),
                subject           VARCHAR(255),
                price             DECIMAL(10,2) NOT NULL,
                stock_count       INT NOT NULL DEFAULT 0,
                cover_photo_url   VARCHAR(500),
                is_active         BOOLEAN DEFAULT true,
                created_at        TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
                updated_at        TIMESTAMP WITH TIME ZONE DEFAULT NOW()
            );
        `);
        console.log('✅ Created products table');

        // Create indexes on products
        await pool.query(`CREATE INDEX IF NOT EXISTS idx_products_shop ON products(shop_id);`);
        await pool.query(`CREATE INDEX IF NOT EXISTS idx_products_branch ON products(branch);`);
        await pool.query(`CREATE INDEX IF NOT EXISTS idx_products_course_type ON products(course_type);`);
        console.log('✅ Created products indexes');

        // Create product_orders table
        await pool.query(`
            CREATE TABLE IF NOT EXISTS product_orders (
                order_id          UUID PRIMARY KEY DEFAULT gen_random_uuid(),
                product_id        UUID REFERENCES products(product_id),
                shop_id           UUID REFERENCES shops(shop_id),
                customer_id       UUID REFERENCES users(user_id) ON DELETE SET NULL,
                guest_email       VARCHAR(255),
                guest_phone       VARCHAR(20),
                quantity          INT NOT NULL DEFAULT 1,
                amount_total      DECIMAL(10,2) NOT NULL,
                payment_id        VARCHAR(255),
                payment_status    VARCHAR(20) DEFAULT 'pending',
                status            VARCHAR(20) DEFAULT 'confirmed',
                created_at        TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
                updated_at        TIMESTAMP WITH TIME ZONE DEFAULT NOW()
            );
        `);
        console.log('✅ Created product_orders table');

        console.log('Database setup completed successfully.');
        process.exit(0);
    } catch (error) {
        console.error('Error setting up database:', error);
        process.exit(1);
    }
}

setupProductsDb();
