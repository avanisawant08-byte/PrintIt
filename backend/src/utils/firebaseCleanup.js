const pool = require('../config/db');
const { getStorage } = require('../config/firebase');

const NORMAL_CLEANUP_INTERVAL_MS = 30 * 60 * 1000; // Run every 30 minutes for normal orders
const SECURE_CLEANUP_INTERVAL_MS = 60 * 1000;       // Run every 1 minute for secure orders
const NORMAL_DELETE_AFTER_HOURS  = 12;

/**
 * Permanently deletes all files for a given order from Firebase Storage
 * and updates the order's deletion status and timestamps in the database.
 * 
 * @param {string} orderId - Order identifier
 * @returns {Promise<boolean>}
 */
async function deleteOrderFilesImmediately(orderId) {
    if (!orderId) return false;
    try {
        const res = await pool.query(
            'SELECT order_id, files, files_deleted, print_mode FROM orders WHERE order_id = $1',
            [orderId]
        );

        if (res.rows.length === 0) return false;
        const order = res.rows[0];

        if (order.files_deleted) {
            return true; // Already deleted
        }

        let files = order.files;
        if (typeof files === 'string') {
            try {
                files = JSON.parse(files);
            } catch (e) {
                files = [];
            }
        }
        if (!Array.isArray(files)) files = [files];

        const bucket = getStorage().bucket();

        for (const rawFile of files) {
            const fileInfo = (rawFile && rawFile.file_info && typeof rawFile.file_info === 'object')
                ? rawFile.file_info
                : rawFile;

            const publicId = fileInfo && fileInfo.public_id;
            if (!publicId) continue;

            try {
                await bucket.file(publicId).delete();
                console.log(`🗑️ [Immediate Delete] Deleted file "${publicId}" for order ${orderId}`);
            } catch (delErr) {
                if (delErr.code !== 404) {
                    console.warn(`⚠️ [Immediate Delete] Could not delete file "${publicId}":`, delErr.message);
                }
            }
        }

        await pool.query(
            `UPDATE orders 
             SET files_deleted = true, 
                 files_deleted_at = NOW(), 
                 deletion_status = 'deleted' 
             WHERE order_id = $1`,
            [orderId]
        );

        console.log(`✅ [Immediate Delete] Successfully purged files for order ${orderId}`);
        return true;
    } catch (err) {
        console.error(`❌ [Immediate Delete] Error deleting files for order ${orderId}:`, err.message);
        return false;
    }
}

/**
 * Finds secure printing orders that must be deleted immediately or have expired:
 * 1. Confirmed printed / collected (status = 'collected')
 * 2. Failed / cancelled past 15-minute retry window
 * 3. Stale orders past 15 minutes
 */
async function cleanupSecureExpiredFiles() {
    try {
        const result = await pool.query(
            `SELECT order_id, files, status, created_at, secure_expires_at
             FROM orders
             WHERE 1=1
               AND files_deleted = false
                AND (
                    status = 'collected'
                    OR (secure_expires_at IS NOT NULL AND secure_expires_at <= NOW())
                    OR (status = 'cancelled' AND created_at < NOW() - INTERVAL '15 minutes')
                )
             LIMIT 25`
        );

        if (result.rows.length === 0) return;

        console.log(`🔒 [Secure Cleanup] Found ${result.rows.length} secure order(s) eligible for immediate deletion / auto-expiry.`);

        for (const order of result.rows) {
            await deleteOrderFilesImmediately(order.order_id);
        }
    } catch (err) {
        console.error('❌ [Secure Cleanup] Error in secure cleanup cycle:', err.message);
    }
}

/**
 * Finds normal mode orders that were collected/cancelled more than 12 hours ago
 * and still have files on Firebase Storage (files_deleted = false).
 */
async function cleanupExpiredFiles() {
    try {
        const result = await pool.query(
            `SELECT order_id, files
             FROM orders
             WHERE (print_mode IS NULL OR print_mode = 'normal')
               AND status IN ('collected', 'cancelled')
               AND files_deleted = false
               AND completed_at IS NOT NULL
               AND completed_at < NOW() - INTERVAL '${NORMAL_DELETE_AFTER_HOURS} hours'
             LIMIT 20`
        );

        if (result.rows.length === 0) return;

        console.log(`🗑️ [Standard Cleanup] Found ${result.rows.length} normal order(s) to clean.`);

        for (const order of result.rows) {
            await deleteOrderFilesImmediately(order.order_id);
        }

        console.log('🗑️ [Standard Cleanup] Standard storage cleanup cycle completed.');
    } catch (err) {
        console.error('❌ [Standard Cleanup] Firebase cleanup job error:', err.message);
    }
}

/**
 * Start periodic cleanup jobs.
 * Call this once from app.js at server startup.
 */
function startCleanupJob() {
    console.log(`🕐 Cleanup workers initialized: Normal (${NORMAL_DELETE_AFTER_HOURS}h retention), Secure (Immediate delete on collected + 15m failure auto-expiry).`);

    // Initial run after DB connects
    setTimeout(() => {
        cleanupSecureExpiredFiles();
        cleanupExpiredFiles();
    }, 5000);

    // Secure worker runs every 1 minute
    setInterval(cleanupSecureExpiredFiles, SECURE_CLEANUP_INTERVAL_MS);

    // Standard worker runs every 30 minutes
    setInterval(cleanupExpiredFiles, NORMAL_CLEANUP_INTERVAL_MS);
}

module.exports = {
    startCleanupJob,
    cleanupExpiredFiles,
    cleanupSecureExpiredFiles,
    deleteOrderFilesImmediately
};
