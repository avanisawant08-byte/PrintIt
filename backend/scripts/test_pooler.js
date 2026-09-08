require('dotenv').config();
const { Pool } = require('pg');

async function testConnection(port, pgbouncer = false) {
    const baseDbUrl = process.env.DATABASE_URL;
    if (!baseDbUrl) {
        console.error('❌ DATABASE_URL environment variable is not set. Please set it in .env.');
        return false;
    }

    let urlObj;
    try {
        urlObj = new URL(baseDbUrl);
    } catch {
        console.error('❌ Invalid DATABASE_URL format.');
        return false;
    }

    if (port) {
        urlObj.port = port.toString();
    }
    if (pgbouncer) {
        urlObj.searchParams.set('pgbouncer', 'true');
    } else {
        urlObj.searchParams.delete('pgbouncer');
    }

    const testUrl = urlObj.toString();
    console.log(`Testing Supabase connection on host ${urlObj.hostname}:${port} (pgbouncer=${pgbouncer})...`);
    
    const pool = new Pool({
        connectionString: testUrl,
        ssl: { rejectUnauthorized: false },
        connectionTimeoutMillis: 5000
    });

    try {
        const start = Date.now();
        const res = await pool.query('SELECT 1 as val, current_database(), current_user, version()');
        console.log(`✅ Port ${port} SUCCESS in ${Date.now() - start}ms:`, res.rows[0].val, res.rows[0].current_database);
        return true;
    } catch (err) {
        console.error(`❌ Port ${port} FAILED:`, err.message);
        return false;
    } finally {
        await pool.end();
    }
}

async function run() {
    console.log('--- TESTING SUPABASE POOLER PORTS ---');
    await testConnection(6543, true);
    await testConnection(6543, false);
    await testConnection(5432, false);
}

run();
