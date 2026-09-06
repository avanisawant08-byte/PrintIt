const pool = require('../config/db');

/**
 * Sets up product_catalog, shop_inventory, store_orders, and store_order_items tables.
 * Pre-populates standard catalog items and maps initial inventory to active print shops.
 */
async function setupStoreDb() {
    let client;
    try {
        client = await pool.connect();
    } catch (connErr) {
        console.warn('⚠️ setupStoreDb: DB connection not available yet:', connErr.message);
        return;
    }

    try {
        await client.query('BEGIN');

        // 1. Master Product Catalog
        await client.query(`
            CREATE TABLE IF NOT EXISTS product_catalog (
                product_id      UUID PRIMARY KEY DEFAULT gen_random_uuid(),
                title           VARCHAR(255) NOT NULL,
                description     TEXT,
                category        VARCHAR(50) NOT NULL, -- 'Books', 'Manuals', 'Notes', 'Forms', 'Other'
                branch          VARCHAR(100),
                course_type     VARCHAR(50),
                semester        VARCHAR(20),
                subject         VARCHAR(255),
                author          VARCHAR(255),
                isbn            VARCHAR(50),
                cover_photo_url VARCHAR(500),
                created_by      UUID REFERENCES users(user_id) ON DELETE SET NULL,
                is_active       BOOLEAN DEFAULT true,
                created_at      TIMESTAMP WITH TIME ZONE DEFAULT NOW()
            );
        `);

        // Catalog Indexes
        await client.query(`CREATE INDEX IF NOT EXISTS idx_product_catalog_category ON product_catalog(category);`);
        await client.query(`CREATE INDEX IF NOT EXISTS idx_product_catalog_branch ON product_catalog(branch);`);
        await client.query(`CREATE INDEX IF NOT EXISTS idx_product_catalog_semester ON product_catalog(semester);`);
        await client.query(`CREATE INDEX IF NOT EXISTS idx_product_catalog_active ON product_catalog(is_active);`);

        // 2. Shop Specific Inventory (Prices & Stock)
        await client.query(`
            CREATE TABLE IF NOT EXISTS shop_inventory (
                inventory_id    UUID PRIMARY KEY DEFAULT gen_random_uuid(),
                shop_id         UUID REFERENCES shops(shop_id) ON DELETE CASCADE,
                product_id      UUID REFERENCES product_catalog(product_id) ON DELETE CASCADE,
                price           DECIMAL(10,2) NOT NULL,
                stock_count     INT NOT NULL DEFAULT 0,
                is_available    BOOLEAN DEFAULT true,
                created_at      TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
                updated_at      TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
                UNIQUE(shop_id, product_id)
            );
        `);

        await client.query(`CREATE INDEX IF NOT EXISTS idx_shop_inventory_shop ON shop_inventory(shop_id);`);
        await client.query(`CREATE INDEX IF NOT EXISTS idx_shop_inventory_product ON shop_inventory(product_id);`);
        await client.query(`CREATE INDEX IF NOT EXISTS idx_shop_inventory_stock ON shop_inventory(stock_count);`);

        // 3. Store Orders (Single-Shop Cart Checkout)
        await client.query(`
            CREATE TABLE IF NOT EXISTS store_orders (
                order_id        UUID PRIMARY KEY DEFAULT gen_random_uuid(),
                order_number    VARCHAR(32) UNIQUE NOT NULL,
                pickup_code     VARCHAR(8) NOT NULL,
                shop_id         UUID REFERENCES shops(shop_id),
                customer_id     UUID REFERENCES users(user_id) ON DELETE SET NULL,
                guest_email     VARCHAR(255),
                guest_phone     VARCHAR(20),
                total_amount    DECIMAL(10,2) NOT NULL,
                payment_method  VARCHAR(20) NOT NULL, -- 'wallet' or 'razorpay'
                payment_id      VARCHAR(255),
                payment_status  VARCHAR(20) DEFAULT 'completed',
                status          VARCHAR(20) DEFAULT 'confirmed', -- 'confirmed', 'ready_for_pickup', 'collected', 'cancelled'
                created_at      TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
                updated_at      TIMESTAMP WITH TIME ZONE DEFAULT NOW()
            );
        `);

        await client.query(`CREATE INDEX IF NOT EXISTS idx_store_orders_shop ON store_orders(shop_id);`);
        await client.query(`CREATE INDEX IF NOT EXISTS idx_store_orders_customer ON store_orders(customer_id);`);
        await client.query(`CREATE INDEX IF NOT EXISTS idx_store_orders_status ON store_orders(status);`);

        // 4. Store Order Line Items
        await client.query(`
            CREATE TABLE IF NOT EXISTS store_order_items (
                item_id         UUID PRIMARY KEY DEFAULT gen_random_uuid(),
                order_id        UUID REFERENCES store_orders(order_id) ON DELETE CASCADE,
                inventory_id    UUID REFERENCES shop_inventory(inventory_id) ON DELETE SET NULL,
                product_id      UUID REFERENCES product_catalog(product_id),
                title           VARCHAR(255) NOT NULL,
                quantity        INT NOT NULL DEFAULT 1,
                unit_price      DECIMAL(10,2) NOT NULL,
                subtotal        DECIMAL(10,2) NOT NULL
            );
        `);

        await client.query(`CREATE INDEX IF NOT EXISTS idx_store_order_items_order ON store_order_items(order_id);`);

        // 5. Seed Initial Master Catalog if empty
        const countRes = await client.query('SELECT COUNT(*) FROM product_catalog');
        if (parseInt(countRes.rows[0].count, 10) === 0) {
            console.log('📦 Seeding initial master product catalog...');
            const seedProducts = [
                {
                    title: 'Engineering Mathematics III',
                    description: 'Comprehensive guide covering Laplace transforms, Fourier series, complex variables, and partial differential equations with solved university question papers.',
                    category: 'Books',
                    branch: 'Computer Science',
                    course_type: 'Engineering',
                    semester: '3rd',
                    subject: 'Mathematics III',
                    author: 'Dr. B.S. Grewal',
                    isbn: '978-8174091955',
                    cover_photo_url: 'https://images.unsplash.com/photo-1544716278-ca5e3f4abd8c?w=600&auto=format&fit=crop'
                },
                {
                    title: 'Data Structures & Algorithms Lab Manual',
                    description: 'Official verified lab manual with full C++ and Java implementations of stacks, queues, trees, graphs, sorting algorithms, and viva questions.',
                    category: 'Manuals',
                    branch: 'Computer Science',
                    course_type: 'Engineering',
                    semester: '3rd',
                    subject: 'Data Structures',
                    author: 'Department of Computer Engineering',
                    isbn: 'MAN-CS-301',
                    cover_photo_url: 'https://images.unsplash.com/photo-1517694712202-14dd9538aa97?w=600&auto=format&fit=crop'
                },
                {
                    title: 'Object Oriented Programming with Java',
                    description: 'Complete syllabus textbook covering inheritance, polymorphism, multithreading, exception handling, and JDBC with lab exercises.',
                    category: 'Books',
                    branch: 'Computer Science',
                    course_type: 'Engineering',
                    semester: '4th',
                    subject: 'Java Programming',
                    author: 'E. Balagurusamy',
                    isbn: '978-9351341796',
                    cover_photo_url: 'https://images.unsplash.com/photo-1532012164546-f432f2e3777f?w=600&auto=format&fit=crop'
                },
                {
                    title: 'Digital Electronics & Logic Design Manual',
                    description: 'Complete experiment manual for logic gates, multiplexers, decoders, flip-flops, shift registers, and counter circuit designs.',
                    category: 'Manuals',
                    branch: 'Electronics',
                    course_type: 'Engineering',
                    semester: '3rd',
                    subject: 'Digital Electronics',
                    author: 'Department of Electronics',
                    isbn: 'MAN-EC-302',
                    cover_photo_url: 'https://images.unsplash.com/photo-1518770660439-4636190af475?w=600&auto=format&fit=crop'
                },
                {
                    title: 'Fluid Mechanics & Machinery Manual',
                    description: 'Detailed laboratory procedure for venturimeter, orifice meter, Pelton wheel, Francis turbine, and centrifugal pump performance tests.',
                    category: 'Manuals',
                    branch: 'Mechanical',
                    course_type: 'Engineering',
                    semester: '4th',
                    subject: 'Fluid Mechanics',
                    author: 'Mechanical Faculty Team',
                    isbn: 'MAN-ME-402',
                    cover_photo_url: 'https://images.unsplash.com/photo-1581092160607-ee22621dd758?w=600&auto=format&fit=crop'
                },
                {
                    title: 'Microprocessor 8085 & 8086 Quick Revision Notes',
                    description: 'Handwritten typed exam notes with pin diagrams, instruction sets, memory interfacing schemes, and 20 crucial recurring university questions.',
                    category: 'Notes',
                    branch: 'Computer Science',
                    course_type: 'Engineering',
                    semester: '4th',
                    subject: 'Microprocessors',
                    author: 'Prof. S. R. Kulkarni',
                    isbn: 'NTE-CS-405',
                    cover_photo_url: 'https://images.unsplash.com/photo-1456513080510-7bf3a84b82f8?w=600&auto=format&fit=crop'
                },
                {
                    title: 'Workshop Practice & Machine Shop Manual',
                    description: 'Standard 1st year manual covering carpentry, fitting, welding, smithy, sheet metal, and lathe machine operations with safety guidelines.',
                    category: 'Manuals',
                    branch: 'Mechanical',
                    course_type: 'Engineering',
                    semester: '1st',
                    subject: 'Basic Workshop',
                    author: 'Workshop Superintendent Team',
                    isbn: 'MAN-FE-101',
                    cover_photo_url: 'https://images.unsplash.com/photo-1504917599217-d4dc5ebe6122?w=600&auto=format&fit=crop'
                },
                {
                    title: 'Bonafide & Railway Concession Application Booklet',
                    description: 'Official printed multi-carbon duplicate forms bundle required for college bonafide certificate, bus pass, and railway concession requests.',
                    category: 'Forms',
                    branch: 'All Branches',
                    course_type: 'Engineering',
                    semester: 'All Semesters',
                    subject: 'Administration',
                    author: 'PrintIt College Stationary Cell',
                    isbn: 'FRM-ADM-01',
                    cover_photo_url: 'https://images.unsplash.com/photo-1586281380349-632531db7ed4?w=600&auto=format&fit=crop'
                },
                {
                    title: 'Engineering Physics Laboratory Manual',
                    description: 'Standard experiments including Newton rings, diffraction grating, semiconductor bandgap determination, laser wavelength, and ultrasonic interferometer.',
                    category: 'Manuals',
                    branch: 'All Branches',
                    course_type: 'Engineering',
                    semester: '2nd',
                    subject: 'Engineering Physics',
                    author: 'Physics Department Faculty',
                    isbn: 'MAN-FE-201',
                    cover_photo_url: 'https://images.unsplash.com/photo-1532094349884-543bc11b234d?w=600&auto=format&fit=crop'
                },
                {
                    title: 'University Practical Exam Answer Sheets (Pack of 10)',
                    description: 'Official standard ruled answer booklet with barcoded front sheet, stitching, and graph attachment provisions for university semester practical exams.',
                    category: 'Forms',
                    branch: 'All Branches',
                    course_type: 'Engineering',
                    semester: 'All Semesters',
                    subject: 'Examination',
                    author: 'Exam Cell Supplies',
                    isbn: 'FRM-EXM-10',
                    cover_photo_url: 'https://images.unsplash.com/photo-1606326608606-aa0b62935f2b?w=600&auto=format&fit=crop'
                }
            ];

            for (const p of seedProducts) {
                await client.query(`
                    INSERT INTO product_catalog (
                        title, description, category, branch, course_type, semester, subject, author, isbn, cover_photo_url
                    ) VALUES ($1, $2, $3, $4, $5, $6, $7, $8, $9, $10)
                `, [p.title, p.description, p.category, p.branch, p.course_type, p.semester, p.subject, p.author, p.isbn, p.cover_photo_url]);
            }
            console.log(`✅ Seeded ${seedProducts.length} catalog items.`);
        }

        // 6. Map sample inventory to any registered shops that have no inventory
        const shopsRes = await client.query('SELECT shop_id, name FROM shops LIMIT 10');
        if (shopsRes.rows.length > 0) {
            const catalogItemsRes = await client.query('SELECT product_id, title, category FROM product_catalog LIMIT 10');
            for (const shop of shopsRes.rows) {
                const invCount = await client.query('SELECT COUNT(*) FROM shop_inventory WHERE shop_id = $1', [shop.shop_id]);
                if (parseInt(invCount.rows[0].count, 10) === 0) {
                    console.log(`ℹ️ Mapping sample inventory to shop: ${shop.name}...`);
                    for (let i = 0; i < catalogItemsRes.rows.length; i++) {
                        const item = catalogItemsRes.rows[i];
                        // Reasonable pricing: manuals ~₹45-65, books ~₹120-180, notes ~₹35, forms ~₹20
                        let price = 50.00;
                        if (item.category === 'Books') price = 140.00 + (i * 10);
                        else if (item.category === 'Manuals') price = 45.00 + (i * 5);
                        else if (item.category === 'Notes') price = 35.00;
                        else if (item.category === 'Forms') price = 25.00;

                        const stockCount = 5 + (i * 3); // realistic stock e.g. 5, 8, 11, 14...
                        await client.query(`
                            INSERT INTO shop_inventory (shop_id, product_id, price, stock_count, is_available)
                            VALUES ($1, $2, $3, $4, true)
                            ON CONFLICT (shop_id, product_id) DO NOTHING
                        `, [shop.shop_id, item.product_id, price, stockCount]);
                    }
                }
            }
        }

        await client.query('COMMIT');
        console.log('✅ Store database setup and verification completed.');
    } catch (err) {
        await client.query('ROLLBACK');
        console.error('❌ Error setting up Store DB:', err.message);
    } finally {
        client.release();
    }
}

module.exports = { setupStoreDb };
