const crypto = require('crypto');

/**
 * Request Correlation ID Middleware
 * Ensures every incoming request has a unique trace ID attached to both request and response.
 */
function correlationIdMiddleware(req, res, next) {
    const correlationId = req.headers['x-request-id'] || crypto.randomUUID();
    req.correlationId = correlationId;
    res.setHeader('X-Request-ID', correlationId);
    next();
}

/**
 * Centralized Production-Ready Error Handler
 * Sanitizes all error outputs sent to clients, preventing stack traces, database query details,
 * file paths, or internal server info from leaking.
 * Detailed error diagnostics go to server-side logs only.
 */
function errorHandler(err, req, res, next) {
    const correlationId = req.correlationId || req.headers['x-request-id'] || crypto.randomUUID();
    res.setHeader('X-Request-ID', correlationId);

    // Determine appropriate HTTP status code
    let status = 500;
    if (typeof err.status === 'number' && err.status >= 400 && err.status < 600) {
        status = err.status;
    } else if (typeof err.statusCode === 'number' && err.statusCode >= 400 && err.statusCode < 600) {
        status = err.statusCode;
    } else if (err.name === 'MulterError') {
        status = 400;
    } else if (err.message && (err.message.includes('Invalid file type') || err.message.includes('file too large'))) {
        status = 400;
    } else if (err.message && err.message.includes('CORS origin restriction')) {
        status = 403;
    }

    // Log full error details with stack trace to server-side console/logs only
    console.error(`[ERROR Correlation ID: ${correlationId}] ${req.method} ${req.originalUrl}:`, err.stack || err.message || err);

    // Never leak stack traces, database queries, table names, or internal file paths
    if (status >= 500) {
        return res.status(status).json({
            error: 'Internal Server Error',
            message: 'An unexpected error occurred while processing your request.',
            request_id: correlationId
        });
    }

    // Sanitize client-facing messages for 4xx errors
    let clientMessage = typeof err.message === 'string' ? err.message : 'Request could not be processed.';
    const containsInternalLeak = /relation\s+"|syntax error|pg_|SELECT\s|INSERT\s|UPDATE\s|DELETE\s|column\s+"|node_modules|[/\\]src[/\\]|at\s\w+/i.test(clientMessage);
    if (containsInternalLeak) {
        clientMessage = 'Invalid request parameters or format.';
    }

    return res.status(status).json({
        error: err.name === 'Error' ? 'Bad Request' : (err.name || 'Bad Request'),
        message: clientMessage,
        request_id: correlationId
    });
}

module.exports = {
    correlationIdMiddleware,
    errorHandler
};
