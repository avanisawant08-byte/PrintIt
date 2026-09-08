/**
 * Environment Variable Validator
 * Validates critical environment variables at startup and halts execution
 * if critical secrets, database connection, or auth keys are missing or invalid.
 */

function validateEnv() {
    const isTest = process.env.NODE_ENV === 'test';
    if (isTest) return; // Skip validation during automated unit/integration test runs

    // Default NODE_ENV to 'production' if not explicitly provided
    if (!process.env.NODE_ENV) {
        process.env.NODE_ENV = 'production';
    }

    const isProduction = process.env.NODE_ENV === 'production';

    const criticalVars = [
        { 
            name: 'DATABASE_URL', 
            description: 'PostgreSQL connection URL with authentication credentials',
            example: 'postgresql://postgres.xxx:password@host:6543/postgres?sslmode=require'
        },
        { 
            name: 'JWT_SECRET', 
            description: 'Cryptographic secret key for signing authentication tokens (min 32 chars)',
            example: 'min-32-char-random-hex-string'
        },
        { 
            name: 'RAZORPAY_KEY_ID', 
            description: 'Razorpay Key ID for payment processing',
            example: 'rzp_live_xxxxxxxxxxxxxx'
        },
        { 
            name: 'RAZORPAY_KEY_SECRET', 
            description: 'Razorpay Secret Key for HMAC signature verification',
            example: 'xxxxxxxxxxxxxxxxxxxxxxxx'
        }
    ];

    const missing = [];
    const placeholders = [];

    for (const v of criticalVars) {
        const val = process.env[v.name];
        if (!val || val.trim() === '') {
            missing.push(v);
        } else if (
            val.includes('your_') || 
            val.includes('xxxxxxx') || 
            val.includes('placeholder') ||
            val.includes('<') ||
            val.includes('generate_a_secure')
        ) {
            placeholders.push(v);
        }
    }

    // Check CORS configuration in production
    if (isProduction) {
        const origins = process.env.ALLOWED_ORIGINS;
        if (!origins || origins.trim() === '' || origins.includes('*')) {
            console.warn('⚠️ WARNING: ALLOWED_ORIGINS should be explicitly set to your production frontend domains (wildcard * is discouraged in production).');
        }
    }

    if (missing.length > 0 || (isProduction && placeholders.length > 0)) {
        console.error('\n================================================================================');
        console.error('❌ FATAL CONFIGURATION ERROR: Missing or placeholder critical environment variables:');
        console.error('================================================================================');
        
        if (missing.length > 0) {
            console.error('\nMissing Required Variables:');
            missing.forEach(m => {
                console.error(`   - ${m.name}: ${m.description}`);
            });
        }

        if (placeholders.length > 0) {
            console.error('\nVariables using default/placeholder values:');
            placeholders.forEach(p => {
                console.error(`   - ${p.name}: Contains placeholder value (${p.description})`);
            });
        }

        console.error('\nRemediation: Set these variables in your environment or production configuration.');
        console.error('The server refuses to start to prevent insecure or non-functional execution.');
        console.error('================================================================================\n');

        process.exit(1);
    } else {
        console.log(`✅ Environment configuration validated successfully (Environment: ${process.env.NODE_ENV}).`);
    }
}

module.exports = { validateEnv };
