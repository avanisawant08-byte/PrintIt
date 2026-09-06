const rateLimit = require('express-rate-limit');

const isTest = process.env.NODE_ENV === 'test';

// Global API Limiter: 3,000 requests per 15 minutes per IP (supports active portal polling & mobile catalog browsing)
const apiLimiter = rateLimit({
    windowMs: 15 * 60 * 1000,
    max: isTest ? 100000 : 3000,
    standardHeaders: true,
    legacyHeaders: false,
    validate: { xForwardedForHeader: false, default: true },
    skip: (req) => req.path === '/health' || req.path === '/test',
    message: { error: 'Too many requests, please try again later.' }
});

// Sensitive Auth Limiter (Login, Register, Phone OTP): 100 attempts per 15 minutes per IP
// skipSuccessfulRequests ensures legitimate successful logins don't exhaust the threshold
const authLimiter = rateLimit({
    windowMs: 15 * 60 * 1000,
    max: isTest ? 100000 : 100,
    standardHeaders: true,
    legacyHeaders: false,
    skipSuccessfulRequests: true,
    validate: { xForwardedForHeader: false, default: true },
    message: { error: 'Too many authentication attempts from this IP. Please try again after 15 minutes.' }
});

// Payment & Wallet Limiter: 200 requests per 15 minutes per IP
const paymentLimiter = rateLimit({
    windowMs: 15 * 60 * 1000,
    max: isTest ? 100000 : 200,
    standardHeaders: true,
    legacyHeaders: false,
    validate: { xForwardedForHeader: false, default: true },
    message: { error: 'Too many payment verification requests. Please try again later.' }
});

// Public Tracking & Order Cancellation Limiter: 300 requests per 15 minutes per IP
const publicOrderLimiter = rateLimit({
    windowMs: 15 * 60 * 1000,
    max: isTest ? 100000 : 300,
    standardHeaders: true,
    legacyHeaders: false,
    validate: { xForwardedForHeader: false, default: true },
    message: { error: 'Too many requests for public order endpoints. Please try again later.' }
});

module.exports = {
    apiLimiter,
    authLimiter,
    paymentLimiter,
    publicOrderLimiter
};
