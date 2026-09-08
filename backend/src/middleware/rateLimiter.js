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
    message: { 
        error: 'Too Many Requests', 
        message: 'Too many requests from this IP. Please try again later.' 
    }
});

// Sensitive Auth Limiter (Registration, Shop Signup): 10 attempts per 15 minutes per IP
const authLimiter = rateLimit({
    windowMs: 15 * 60 * 1000,
    max: isTest ? 100000 : 10,
    standardHeaders: true,
    legacyHeaders: false,
    validate: { xForwardedForHeader: false, default: true },
    message: { 
        error: 'Too Many Requests', 
        message: 'Too many registration attempts. Please try again after 15 minutes.' 
    }
});

// Strict Login Limiter: 5 attempts per 1 minute per IP (Mandated Security Standard)
const loginLimiter = rateLimit({
    windowMs: 1 * 60 * 1000, // 1 minute window
    max: isTest ? 100000 : 5,
    standardHeaders: true,
    legacyHeaders: false,
    validate: { xForwardedForHeader: false, default: true },
    message: { 
        error: 'Too Many Requests', 
        message: 'Too many login attempts. Please wait 1 minute before trying again.' 
    }
});

// Password Reset / Account Security Limiter: 3 attempts per 1 hour per IP
const passwordResetLimiter = rateLimit({
    windowMs: 60 * 60 * 1000, // 1 hour window
    max: isTest ? 100000 : 3,
    standardHeaders: true,
    legacyHeaders: false,
    validate: { xForwardedForHeader: false, default: true },
    message: { 
        error: 'Too Many Requests', 
        message: 'Too many password reset requests. Please wait 1 hour before attempting again.' 
    }
});

// Phone OTP Generation Limiter: 5 requests per 10 minutes per IP
const otpLimiter = rateLimit({
    windowMs: 10 * 60 * 1000,
    max: isTest ? 100000 : 5,
    standardHeaders: true,
    legacyHeaders: false,
    validate: { xForwardedForHeader: false, default: true },
    message: { 
        error: 'Too Many Requests', 
        message: 'Too many OTP requests. Please wait 10 minutes before requesting a new code.' 
    }
});

// Payment & Wallet Limiter: 200 requests per 15 minutes per IP
const paymentLimiter = rateLimit({
    windowMs: 15 * 60 * 1000,
    max: isTest ? 100000 : 200,
    standardHeaders: true,
    legacyHeaders: false,
    validate: { xForwardedForHeader: false, default: true },
    message: { 
        error: 'Too Many Requests', 
        message: 'Too many payment verification requests. Please try again later.' 
    }
});

// Public Tracking & Order Cancellation Limiter: 300 requests per 15 minutes per IP
const publicOrderLimiter = rateLimit({
    windowMs: 15 * 60 * 1000,
    max: isTest ? 100000 : 300,
    standardHeaders: true,
    legacyHeaders: false,
    validate: { xForwardedForHeader: false, default: true },
    message: { 
        error: 'Too Many Requests', 
        message: 'Too many requests for public order endpoints. Please try again later.' 
    }
});

module.exports = {
    apiLimiter,
    authLimiter,
    loginLimiter,
    passwordResetLimiter,
    otpLimiter,
    paymentLimiter,
    publicOrderLimiter
};
