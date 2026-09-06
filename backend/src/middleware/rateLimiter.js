const rateLimit = require('express-rate-limit');

const isTest = process.env.NODE_ENV === 'test';

// Global API Limiter: 500 requests per 15 minutes per IP
const apiLimiter = rateLimit({
    windowMs: 15 * 60 * 1000,
    max: isTest ? 100000 : 500,
    standardHeaders: true,
    legacyHeaders: false,
    message: { error: 'Too many requests, please try again later.' }
});

// Sensitive Auth Limiter (Login, Register, Phone OTP): 15 attempts per 15 minutes per IP
const authLimiter = rateLimit({
    windowMs: 15 * 60 * 1000,
    max: isTest ? 100000 : 15,
    standardHeaders: true,
    legacyHeaders: false,
    message: { error: 'Too many authentication attempts from this IP. Please try again after 15 minutes.' }
});

// Payment & Wallet Limiter: 40 requests per 15 minutes per IP
const paymentLimiter = rateLimit({
    windowMs: 15 * 60 * 1000,
    max: isTest ? 100000 : 40,
    standardHeaders: true,
    legacyHeaders: false,
    message: { error: 'Too many payment verification requests. Please try again later.' }
});

// Public Tracking & Order Cancellation Limiter: 60 requests per 15 minutes per IP
const publicOrderLimiter = rateLimit({
    windowMs: 15 * 60 * 1000,
    max: isTest ? 100000 : 60,
    standardHeaders: true,
    legacyHeaders: false,
    message: { error: 'Too many requests for public order endpoints. Please try again later.' }
});

module.exports = {
    apiLimiter,
    authLimiter,
    paymentLimiter,
    publicOrderLimiter
};
