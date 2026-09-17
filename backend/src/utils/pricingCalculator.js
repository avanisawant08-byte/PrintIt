/**
 * Pricing calculation and verification engine for PrintIt.
 * Computes exact required amounts on the server to prevent price tampering.
 */

/**
 * Calculates the required print subtotal for a given shop and files array.
 * 
 * @param {object} client - pg client or pool
 * @param {string} shopId - UUID of the shop
 * @param {Array} files - array of file entries with print options
 * @returns {Promise<{ subtotal: number, minRequiredAmount: number }>}
 */
async function calculatePrintSubtotal(client, shopId, files) {
    if (!shopId) {
        throw new Error('shop_id is required to calculate pricing');
    }

    // 1. Fetch shop base rates
    const shopRes = await client.query(
        'SELECT price_bw, price_color FROM shops WHERE shop_id = $1',
        [shopId]
    );

    if (shopRes.rows.length === 0) {
        throw new Error('Shop not found');
    }

    const shop = shopRes.rows[0];
    const defaultPriceBw = parseFloat(shop.price_bw) || 2.0;
    const defaultPriceColor = parseFloat(shop.price_color) || 10.0;

    // 2. Fetch granular shop pricing rules
    let rules = [];
    try {
        const pricingRes = await client.query(
            'SELECT color, size, sides, price_per_page, binding_staple_price, binding_spiral_price FROM shop_pricing WHERE shop_id = $1',
            [shopId]
        );
        rules = pricingRes.rows;
    } catch (_) {
        // shop_pricing table might be empty or fallback to defaults
    }

    let fileList = files;
    if (typeof fileList === 'string') {
        try {
            fileList = JSON.parse(fileList);
        } catch (_) {
            fileList = [];
        }
    }
    if (!Array.isArray(fileList) || fileList.length === 0) {
        // Minimum order base cost is at least 1 page of B&W
        return { subtotal: defaultPriceBw, minRequiredAmount: defaultPriceBw };
    }

    let subtotal = 0.0;

    for (const rawFile of fileList) {
        const entry = (rawFile && rawFile.file_info && typeof rawFile.file_info === 'object')
            ? rawFile.file_info
            : (rawFile || {});

        const printOptions = entry.print_options || rawFile.print_options || {};

        // Color Mode
        const rawColor = (entry.colorMode || entry.color_mode || printOptions.color || 'bw').toString().toLowerCase();
        const isBw = rawColor.includes('b&w') || rawColor.includes('bw') || rawColor.includes('black');
        const targetColor = isBw ? 'bw' : 'color';

        // Paper Size & Sides
        const targetSize = (entry.paperSize || entry.paper_size || entry.size || printOptions.size || 'A4').toString().toUpperCase();
        const rawSides = (entry.sides || printOptions.sides || 'single').toString().toLowerCase();
        const targetSides = rawSides.includes('double') || rawSides.includes('duplex') ? 'double' : 'single';

        let baseSinglePrice = isBw ? defaultPriceBw : defaultPriceColor;
        let baseDoublePrice = baseSinglePrice * 1.5;
        let bindingPrice = 0.0;

        const rawBinding = (entry.binding || printOptions.binding || 'none').toString().toLowerCase();
        if (rawBinding.includes('spiral')) bindingPrice = 25.0;
        else if (rawBinding.includes('hardcover')) bindingPrice = 60.0;
        else if (rawBinding.includes('staple')) bindingPrice = 5.0;

        // Match custom rules if defined
        for (const rule of rules) {
            const ruleColor = (rule.color || '').toLowerCase();
            const ruleSize = (rule.size || '').toUpperCase();
            const ruleSides = (rule.sides || '').toLowerCase();

            if (ruleColor === targetColor && ruleSize === targetSize) {
                if (ruleSides === 'single' && rule.price_per_page != null) {
                    baseSinglePrice = parseFloat(rule.price_per_page);
                } else if (ruleSides === 'double' && rule.price_per_page != null) {
                    baseDoublePrice = parseFloat(rule.price_per_page);
                }
                if (rawBinding.includes('spiral') && rule.binding_spiral_price != null) {
                    bindingPrice = parseFloat(rule.binding_spiral_price);
                } else if (rawBinding.includes('staple') && rule.binding_staple_price != null) {
                    bindingPrice = parseFloat(rule.binding_staple_price);
                }
            }
        }

        const pages = parseInt(entry.pages || entry.page_count || printOptions.pages || 1, 10);
        const validPages = pages > 0 ? pages : 1;

        const pagesPerPaper = parseInt(entry.pagesPerPaper || printOptions.pages_per_paper || 1, 10);
        const validPagesPerPaper = pagesPerPaper > 0 ? pagesPerPaper : 1;

        const copies = parseInt(entry.copies || printOptions.copies || 1, 10);
        const validCopies = copies > 0 ? copies : 1;

        const printedSides = Math.ceil(validPages / validPagesPerPaper);

        let sheetCost = 0.0;
        if (targetSides === 'double') {
            const fullDoubleSheets = Math.floor(printedSides / 2);
            const remainingSingleSides = printedSides % 2;
            sheetCost = (fullDoubleSheets * baseDoublePrice) + (remainingSingleSides * baseSinglePrice);
        } else {
            sheetCost = printedSides * baseSinglePrice;
        }

        const fileCost = (sheetCost * validCopies) + bindingPrice;

        subtotal += fileCost;
    }

    const calculatedSubtotal = parseFloat(subtotal.toFixed(2));
    return {
        subtotal: calculatedSubtotal,
        minRequiredAmount: calculatedSubtotal
    };
}

/**
 * Calculates and validates marketplace product pricing.
 * 
 * @param {object} client - pg client or pool
 * @param {string} productId - UUID of the product
 * @param {number} quantity - Number of items
 * @returns {Promise<{ unitPrice: number, totalExpectedAmount: number, shopId: string }>}
 */
async function calculateProductTotal(client, productId, quantity) {
    if (!productId) {
        throw new Error('product_id is required');
    }
    const qty = parseInt(quantity, 10);
    if (isNaN(qty) || qty < 1) {
        throw new Error('Valid quantity of at least 1 is required');
    }

    const productRes = await client.query(
        'SELECT shop_id, price, stock_count, is_active FROM products WHERE product_id = $1',
        [productId]
    );

    if (productRes.rows.length === 0) {
        throw new Error('Product not found');
    }

    const product = productRes.rows[0];
    if (!product.is_active) {
        throw new Error('Product is currently inactive');
    }

    const unitPrice = parseFloat(product.price);
    const totalExpectedAmount = parseFloat((unitPrice * qty).toFixed(2));

    return {
        unitPrice,
        totalExpectedAmount,
        shopId: product.shop_id,
        stockCount: parseInt(product.stock_count, 10)
    };
}

module.exports = {
    calculatePrintSubtotal,
    calculateProductTotal
};
