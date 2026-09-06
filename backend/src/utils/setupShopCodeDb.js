const pool = require('../config/db');

// Unambiguous uppercase alphanumeric charset (avoids 0/O, 1/I confusion)
const CHARSET = '23456789ABCDEFGHJKLMNPQRSTUVWXYZ';

function generateRandomCode(length = 4) {
    let result = '';
    for (let i = 0; i < length; i++) {
        const randomIndex = Math.floor(Math.random() * CHARSET.length);
        result += CHARSET[randomIndex];
    }
    return result;
}

/**
 * Generates a unique 6-character shop code (e.g., PR8473, PR9K2M).
 * Format: 'PR' + 4 uppercase characters.
 * 
 * @param {object} client - pg client or pool
 * @param {string} [preferredSeed] - Optional seed such as UUID prefix
 * @returns {Promise<string>}
 */
async function generateUniqueShopCode(client, preferredSeed = '') {
    // If a seed is provided (e.g., first 4 hex chars of shop_id), try it first
    let candidate = '';
    if (preferredSeed && preferredSeed.length >= 4) {
        candidate = 'PR' + preferredSeed.substring(0, 4).toUpperCase();
        const check = await client.query('SELECT shop_id FROM shops WHERE shop_code = $1', [candidate]);
        if (check.rows.length === 0) {
            return candidate;
        }
    }

    // Otherwise generate random unique codes with max retries
    for (let attempt = 0; attempt < 20; attempt++) {
        candidate = 'PR' + generateRandomCode(4);
        const check = await client.query('SELECT shop_id FROM shops WHERE shop_code = $1', [candidate]);
        if (check.rows.length === 0) {
            return candidate;
        }
    }

    // Fallback if 4 chars exhausted: use 6 random characters
    return 'PR' + generateRandomCode(6);
}

/**
 * Migrates the shops table to include shop_code column, unique index,
 * and backfills any existing shop rows that lack a shop_code.
 */
async function setupShopCodeDb() {
    let client;
    try {
        client = await pool.connect();
    } catch (connErr) {
        console.warn('⚠️ setupShopCodeDb: DB connection not available yet:', connErr.message);
        return;
    }

    try {
        await client.query('BEGIN');

        // 1. Add shop_code column if missing
        await client.query(`
            ALTER TABLE shops 
            ADD COLUMN IF NOT EXISTS shop_code VARCHAR(16) UNIQUE;
        `);

        // 2. Ensure index exists
        await client.query(`
            CREATE UNIQUE INDEX IF NOT EXISTS idx_shops_shop_code ON shops (shop_code);
        `);

        // 3. Find any shops with missing shop_code
        const missing = await client.query(`
            SELECT shop_id, name FROM shops WHERE shop_code IS NULL OR shop_code = ''
        `);

        if (missing.rows.length > 0) {
            console.log(`ℹ️ Backfilling shop_code for ${missing.rows.length} existing shops...`);
            for (const row of missing.rows) {
                // Use first 4 chars of UUID without hyphens as seed
                const rawSeed = (row.shop_id || '').toString().replace(/[^a-zA-Z0-9]/g, '');
                const code = await generateUniqueShopCode(client, rawSeed);
                await client.query(
                    'UPDATE shops SET shop_code = $1 WHERE shop_id = $2',
                    [code, row.shop_id]
                );
                console.log(`  -> Assigned code "${code}" to shop "${row.name || row.shop_id}"`);
            }
        }

        await client.query('COMMIT');
        console.log('✅ Shop code mechanism initialized successfully.');
    } catch (err) {
        await client.query('ROLLBACK');
        console.error('❌ Error setting up shop_code in DB:', err.message);
    } finally {
        client.release();
    }
}

module.exports = {
    setupShopCodeDb,
    generateUniqueShopCode
};
