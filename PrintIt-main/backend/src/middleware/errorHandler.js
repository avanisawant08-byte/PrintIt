const crypto = require('crypto');

/**
 * Request Correlation ID Middleware
 * Ensures every incoming request has a unique trace ID.
 */
function correlationIdMiddleware(req, res, next) {
    const correlationId = req.headers['x-request-id'] || crypto.randomUUID();
    req.correlationId = correlationId;
    res.setHeader('X-Request-ID', correlationId);
    next();
}

/**
 * Centralized Production-Ready Error Handler
 * Sanitizes all error outputs sent to clients, preventing stack trace or internal leakage.
 */
function errorHandler(err, req, res, next) {
    const correlationId = req.correlationId || crypto.randomUUID();
    res.setHeader('X-Request-ID', correlationId);

    const status = (typeof err.status === 'number' && err.status >= 400 && err.status < 600) 
        ? err.status 
        : 500;

    // Log full error details server-side only
    console.error(`[ERROR Trace ID: ${correlationId}] ${req.method} ${req.originalUrl}:`, err.stack || err.message || err);

    // Client-safe response format
    if (status >= 500) {
        return res.status(status).json({
            error: 'Internal Server Error',
            message: 'An unexpected error occurred while processing your request.',
            request_id: correlationId
        });
    }

    return res.status(status).json({
        error: err.name || 'Bad Request',
        message: err.message || 'Request could not be processed.',
        request_id: correlationId
    });
}

module.exports = {
    correlationIdMiddleware,
    errorHandler
};
