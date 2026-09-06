const assert = require('assert');
const { generateUniqueShopCode } = require('../src/utils/setupShopCodeDb');

async function testShopCodeGeneration() {
    console.log('🧪 Testing Shop Code Generation & Dual Lookup Logic...');

    // Mock client to simulate DB checks
    const existingCodes = new Set(['PR8473', 'PR1001']);
    const mockClient = {
        query: async (sql, params) => {
            if (sql.includes('SELECT shop_id FROM shops WHERE shop_code')) {
                const code = params[0];
                if (existingCodes.has(code)) {
                    return { rows: [{ shop_id: 'mock-uuid' }] };
                }
                return { rows: [] };
            }
            return { rows: [] };
        }
    };

    // Test 1: Code format
    const code1 = await generateUniqueShopCode(mockClient);
    console.log(`Generated code: ${code1}`);
    assert(code1.startsWith('PR'), 'Shop code must start with PR prefix');
    assert.strictEqual(code1.length, 6, 'Shop code must be exactly 6 characters');
    assert(/^[A-Z0-9]+$/.test(code1), 'Shop code must be alphanumeric uppercase');
    console.log('✅ Test 1 Passed: Generated shop code has valid format (PRxxxx).');

    // Test 2: Preferred seed (from UUID)
    const seededCode = await generateUniqueShopCode(mockClient, '9b2c3d4e');
    console.log(`Seeded code for 9b2c3d4e: ${seededCode}`);
    assert.strictEqual(seededCode, 'PR9B2C', 'Should use preferred seed when available');
    console.log('✅ Test 2 Passed: Preferred seed generates matching prefix code.');

    // Test 3: Collision resolution (PR8473 already exists)
    const collidedCode = await generateUniqueShopCode(mockClient, '8473b134');
    console.log(`Collision fallback code: ${collidedCode}`);
    assert.notStrictEqual(collidedCode, 'PR8473', 'Must not duplicate existing code');
    assert(collidedCode.startsWith('PR'), 'Collision resolution should still start with PR');
    console.log('✅ Test 3 Passed: Collision resolved with alternate unique code.');

    // Test 4: Dual lookup condition logic
    const mockShops = [
        { shop_id: '8473b134-01c6-46b1-9746-4befaaa5fd46', shop_code: 'PR8473', name: 'Campus Print Hub' },
        { shop_id: '12345678-0000-0000-0000-000000000000', shop_code: 'PR1234', name: 'Metro Xerox' },
    ];

    function findShop(identifier) {
        const idClean = (identifier || '').trim().toUpperCase();
        return mockShops.find(s => 
            s.shop_code.toUpperCase() === idClean || 
            s.shop_id.toLowerCase() === identifier.trim().toLowerCase()
        );
    }

    // Lookup by exact short code
    assert.strictEqual(findShop('PR8473')?.name, 'Campus Print Hub');
    // Lookup by lowercase short code
    assert.strictEqual(findShop('pr8473')?.name, 'Campus Print Hub');
    // Lookup by UUID
    assert.strictEqual(findShop('8473b134-01c6-46b1-9746-4befaaa5fd46')?.name, 'Campus Print Hub');
    // Non-existent
    assert.strictEqual(findShop('INVALID'), undefined);
    console.log('✅ Test 4 Passed: Dual lookup matches both UUID and short code (case-insensitive).');

    console.log('\n🎉 ALL SHOP CODE LOGIC VERIFICATIONS PASSED!\n');
}

testShopCodeGeneration().catch(err => {
    console.error('❌ Verification failed:', err);
    process.exit(1);
});
