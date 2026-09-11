const pool = require('../config/db');

/**
 * Generates a sequential order ID based on pickup type and a database sequence.
 * 
 * Format: [PickupPrefix][Letter1][Letter2][Digit1][Digit2][Digit3][Digit4]
 * Example: Eaa0001, Saa0001, Eab0001
 * 
 * @param {string} pickupType - 'express' or 'scheduled'
 * @param {object} client - The pg client from a transaction
 * @returns {Promise<string>} The generated order ID
 */
async function generateOrderId(pickupType, client) {
    const isExpress = pickupType === 'express';
    const prefix = isExpress ? 'E' : 'S';
    const seqName = isExpress ? 'order_seq_express' : 'order_seq_scheduled';

    let n;
    // We use a PostgreSQL SAVEPOINT so if the sequence query encounters an issue,
    // it can roll back to the savepoint without aborting the parent transaction!
    try {
        await client.query('SAVEPOINT order_seq_sp');
        const result = await client.query(`SELECT nextval('${seqName}') AS seq`);
        n = parseInt(result.rows[0].seq, 10);
        await client.query('RELEASE SAVEPOINT order_seq_sp');
    } catch (seqErr) {
        console.warn(`[orderIdGenerator] Sequence '${seqName}' failed, rolling back to savepoint and attempting creation:`, seqErr.message);
        try {
            await client.query('ROLLBACK TO SAVEPOINT order_seq_sp');
            // Try creating sequence
            await client.query(`CREATE SEQUENCE IF NOT EXISTS ${seqName} START 1`);
            const retryResult = await client.query(`SELECT nextval('${seqName}') AS seq`);
            n = parseInt(retryResult.rows[0].seq, 10);
        } catch (createErr) {
            console.error(`[orderIdGenerator] Fallback for '${seqName}':`, createErr.message);
            // Safe resilient fallback: calculate order count
            try {
                const countRes = await client.query(`SELECT COUNT(*) FROM orders WHERE order_id LIKE $1`, [`${prefix}%`]);
                n = (parseInt(countRes.rows[0]?.count || 0, 10) + 1);
            } catch (_) {
                n = Math.floor(1000 + Math.random() * 8999);
            }
        }
    }

    if (!n || isNaN(n) || n < 1) {
        n = 1;
    }

    // Math for [a-z][a-z] and 0001-9999
    // N=1 -> aa0001, N=9999 -> aa9999, N=10000 -> ab0001
    const maxDigits = 9999;
    const digitPart = ((n - 1) % maxDigits) + 1;
    const lettersValue = Math.floor((n - 1) / maxDigits);

    const letter1 = String.fromCharCode(97 + (Math.floor(lettersValue / 26) % 26)); // 97 is 'a'
    const letter2 = String.fromCharCode(97 + (lettersValue % 26));

    const formattedDigits = String(digitPart).padStart(4, '0');

    return `${prefix}${letter1}${letter2}${formattedDigits}`;
}

module.exports = { generateOrderId };
