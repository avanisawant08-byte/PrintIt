/**
 * Environment Variable Validator
 * Validates critical environment variables at startup and halts execution
 * if critical secrets or configs are missing in production.
 */

function validateEnv() {
    const isProduction = process.env.NODE_ENV === 'production';
    const isTest = process.env.NODE_ENV === 'test';

    if (isTest) return; // Skip validation during automated unit/integration tests

    const requiredVars = [
        { name: 'DATABASE_URL', description: 'PostgreSQL database connection pooler URL' },
        { name: 'JWT_SECRET', description: 'JWT signature secret key' },
        { name: 'RAZORPAY_KEY_ID', description: 'Razorpay Key ID' },
        { name: 'RAZORPAY_KEY_SECRET', description: 'Razorpay Secret Key' }
    ];

    const missing = [];

    for (const v of requiredVars) {
        const val = process.env[v.name];
        if (!val || val.trim() === '' || val.includes('your_') || val.includes('xxxxxxx')) {
            missing.push(v);
        }
    }

    if (missing.length > 0) {
        console.error('================================================================================');
        console.error('❌ FATAL CONFIGURATION ERROR: Missing or invalid required environment variables:');
        missing.forEach(m => console.error(`   - ${m.name}: ${m.description}`));
        console.error('================================================================================');

        if (isProduction) {
            console.error('Refusing to start in PRODUCTION without valid configuration.');
            process.exit(1);
        } else {
            console.warn('⚠️ Running in DEVELOPMENT with incomplete environment variables.');
        }
    } else {
        console.log('✅ Environment configuration validated successfully.');
    }
}

module.exports = { validateEnv };
