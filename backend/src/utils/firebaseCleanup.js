const pool = require('../config/db');
const { getStorage } = require('../config/firebase');

const CLEANUP_INTERVAL_MS = 30 * 60 * 1000;  // Run every 30 minutes
const DELETE_AFTER_HOURS  = 12;

/**
 * Finds orders that were collected/cancelled more than 12 hours ago
 * and still have files on Firebase Storage (files_deleted = false).
 * Deletes each file from Firebase, then marks the order as cleaned.
 */
async function cleanupExpiredFiles() {
    try {
        // Find orders eligible for file cleanup
        const result = await pool.query(
            `SELECT order_id, files
             FROM orders
             WHERE status IN ('collected', 'cancelled')
               AND files_deleted = false
               AND completed_at IS NOT NULL
               AND completed_at < NOW() - INTERVAL '${DELETE_AFTER_HOURS} hours'
             LIMIT 20`
        );

        if (result.rows.length === 0) return;

        console.log(`🗑️  Firebase cleanup: found ${result.rows.length} order(s) to clean.`);

        const bucket = getStorage().bucket();

        for (const order of result.rows) {
            try {
                // Parse files — stored as JSON array
                let files = order.files;
                if (typeof files === 'string') {
                    files = JSON.parse(files);
                }

                // Ensure it's an array
                if (!Array.isArray(files)) files = [files];

                // Delete each file from Firebase Storage
                for (const rawFile of files) {
                    const fileInfo = (rawFile && rawFile.file_info && typeof rawFile.file_info === 'object')
                        ? rawFile.file_info
                        : rawFile;
                    
                    const publicId = fileInfo && fileInfo.public_id;
                    if (!publicId) {
                        console.warn(`  ⚠️ Order ${order.order_id}: file entry has no public_id, skipping.`);
                        continue;
                    }

                    try {
                        await bucket.file(publicId).delete();
                        console.log(`  ✅ Deleted from Firebase: ${publicId}`);
                    } catch (delErr) {
                        if (delErr.code === 404) {
                            console.log(`  ✅ File already deleted from Firebase: ${publicId}`);
                        } else {
                            console.error(`  ❌ Failed to delete ${publicId}:`, delErr.message);
                        }
                    }
                }

                // Mark files as deleted in the database
                await pool.query(
                    'UPDATE orders SET files_deleted = true WHERE order_id = $1',
                    [order.order_id]
                );

                console.log(`  📋 Order ${order.order_id}: files_deleted = true`);

            } catch (orderErr) {
                console.error(`  ❌ Error processing order ${order.order_id}:`, orderErr.message);
            }
        }

        console.log('🗑️  Firebase cleanup cycle complete.');
    } catch (err) {
        console.error('❌ Firebase cleanup job error:', err.message);
    }
}

/**
 * Start the periodic cleanup job.
 * Call this once from app.js at server startup.
 */
function startCleanupJob() {
    console.log(`🕐 Firebase cleanup job scheduled: every ${CLEANUP_INTERVAL_MS / 60000} min, deletes files ${DELETE_AFTER_HOURS}h after order completion.`);

    // Run once at startup (after a short delay to let DB connect)
    setTimeout(cleanupExpiredFiles, 10000);

    // Then run on interval
    setInterval(cleanupExpiredFiles, CLEANUP_INTERVAL_MS);
}

module.exports = { startCleanupJob, cleanupExpiredFiles };
