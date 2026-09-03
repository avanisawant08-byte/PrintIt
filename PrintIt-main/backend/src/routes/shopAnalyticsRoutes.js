const express = require('express');
const router = express.Router();
const pool = require('../config/db');
const auth = require('../middleware/auth');
const shopCheck = require('../middleware/shopCheck');

// All routes require shop owner authentication
router.use(auth);
router.use(shopCheck);

/**
 * Helper to compute startDate and endDate from request query params.
 */
function getDateRange(query) {
    const { period, from, to } = query;
    let startDate;
    let endDate = new Date();

    if (from && to) {
        startDate = new Date(from);
        endDate = new Date(to);
        endDate.setHours(23, 59, 59, 999);
    } else if (period === 'week') {
        startDate = new Date();
        startDate.setDate(startDate.getDate() - 7);
        startDate.setHours(0, 0, 0, 0);
    } else if (period === 'month' || period === '30days') {
        startDate = new Date();
        startDate.setDate(startDate.getDate() - 30);
        startDate.setHours(0, 0, 0, 0);
    } else {
        // Default 'today'
        startDate = new Date();
        startDate.setHours(0, 0, 0, 0);
    }

    return { startDate, endDate, period: period || (from && to ? 'custom' : 'today') };
}

/**
 * @route   GET /api/shop/analytics/summary
 * @desc    Get period summary card metrics
 */
router.get('/summary', async (req, res) => {
    try {
        const { startDate, endDate, period } = getDateRange(req.query);
        const shopId = req.shop_id;

        // 1. Revenue & order counts in date range
        const summaryRes = await pool.query(
            `SELECT 
                COUNT(*) as total_orders,
                COALESCE(SUM(CASE WHEN status != 'cancelled' THEN amount_total ELSE 0 END), 0) as total_revenue,
                COALESCE(SUM(CASE WHEN status = 'cancelled' OR refund_status = 'refunded' THEN amount_total ELSE 0 END), 0) as refunds,
                COUNT(CASE WHEN status = 'collected' THEN 1 END) as collected_count,
                COUNT(CASE WHEN status IN ('queued', 'processing', 'ready') THEN 1 END) as pending_count,
                COUNT(CASE WHEN status = 'cancelled' THEN 1 END) as cancelled_count
             FROM orders 
             WHERE shop_id = $1 AND created_at >= $2 AND created_at <= $3`,
            [shopId, startDate, endDate]
        );

        const row = summaryRes.rows[0];
        const totalOrders = parseInt(row.total_orders, 10);
        const totalRevenue = parseFloat(row.total_revenue);
        const refunds = parseFloat(row.refunds);
        const netRevenue = Math.max(0, totalRevenue - refunds);
        const avgOrderValue = totalOrders > 0 ? parseFloat((totalRevenue / totalOrders).toFixed(2)) : 0;
        const cancelledCount = parseInt(row.cancelled_count, 10);
        const cancellationRate = totalOrders > 0 ? parseFloat(((cancelledCount / totalOrders) * 100).toFixed(1)) : 0;

        // 2. Queue stats
        const queueRes = await pool.query(
            `SELECT 
                COUNT(CASE WHEN status = 'queued' THEN 1 END) as current_length,
                COALESCE(AVG(EXTRACT(EPOCH FROM (updated_at - created_at))/60), 12) as avg_wait_minutes
             FROM orders 
             WHERE shop_id = $1 AND created_at >= CURRENT_DATE`,
            [shopId]
        );

        res.json({
            period,
            from: startDate.toISOString(),
            to: endDate.toISOString(),
            revenue: {
                total: totalRevenue,
                net: netRevenue,
                refunds,
                avg_order_value: avgOrderValue
            },
            orders: {
                total: totalOrders,
                collected: parseInt(row.collected_count, 10),
                pending: parseInt(row.pending_count, 10),
                cancelled: cancelledCount,
                cancellation_rate: cancellationRate
            },
            queue: {
                current_length: parseInt(queueRes.rows[0].current_length, 10),
                avg_wait_minutes: Math.round(parseFloat(queueRes.rows[0].avg_wait_minutes) || 12)
            }
        });
    } catch (err) {
        console.error('Error fetching analytics summary:', err);
        res.status(500).json({ error: 'Failed to fetch summary analytics' });
    }
});

/**
 * @route   GET /api/shop/analytics/revenue
 * @desc    Revenue analytics & 30-day/period trend line graph data
 */
router.get('/revenue', async (req, res) => {
    try {
        const { startDate, endDate } = getDateRange(req.query);
        const shopId = req.shop_id;

        const aggRes = await pool.query(
            `SELECT 
                COUNT(*) as total_orders,
                COALESCE(SUM(CASE WHEN status != 'cancelled' THEN amount_total ELSE 0 END), 0) as total_revenue,
                COALESCE(SUM(CASE WHEN status = 'cancelled' OR refund_status = 'refunded' THEN amount_total ELSE 0 END), 0) as refunds
             FROM orders 
             WHERE shop_id = $1 AND created_at >= $2 AND created_at <= $3`,
            [shopId, startDate, endDate]
        );

        const row = aggRes.rows[0];
        const totalOrders = parseInt(row.total_orders, 10);
        const totalRevenue = parseFloat(row.total_revenue);
        const refunds = parseFloat(row.refunds);
        const netRevenue = Math.max(0, totalRevenue - refunds);
        const avgOrderValue = totalOrders > 0 ? parseFloat((totalRevenue / totalOrders).toFixed(2)) : 0;

        // Daily trend
        const trendRes = await pool.query(
            `SELECT 
                TO_CHAR(created_at, 'YYYY-MM-DD') as date,
                COALESCE(SUM(CASE WHEN status != 'cancelled' THEN amount_total ELSE 0 END), 0) as revenue,
                COUNT(*) as order_count
             FROM orders
             WHERE shop_id = $1 AND created_at >= $2 AND created_at <= $3
             GROUP BY TO_CHAR(created_at, 'YYYY-MM-DD')
             ORDER BY date ASC`,
            [shopId, startDate, endDate]
        );

        const trend = trendRes.rows.map(r => ({
            date: r.date,
            revenue: parseFloat(r.revenue),
            orders: parseInt(r.order_count, 10)
        }));

        res.json({
            total_revenue: totalRevenue,
            net_revenue: netRevenue,
            refunds_issued: refunds,
            avg_order_value: avgOrderValue,
            daily_trend: trend
        });
    } catch (err) {
        console.error('Error fetching revenue analytics:', err);
        res.status(500).json({ error: 'Failed to fetch revenue analytics' });
    }
});

/**
 * @route   GET /api/shop/analytics/orders
 * @desc    Order counts, status breakdown, peak hours, busiest days
 */
router.get('/orders', async (req, res) => {
    try {
        const { startDate, endDate } = getDateRange(req.query);
        const shopId = req.shop_id;

        // Status breakdown & cancellation rate
        const statusRes = await pool.query(
            `SELECT 
                status,
                COUNT(*) as count,
                COALESCE(SUM(amount_total), 0) as revenue
             FROM orders
             WHERE shop_id = $1 AND created_at >= $2 AND created_at <= $3
             GROUP BY status`,
            [shopId, startDate, endDate]
        );

        let totalOrders = 0;
        let cancelledCount = 0;
        const statusBreakdown = {};

        statusRes.rows.forEach(r => {
            const count = parseInt(r.count, 10);
            totalOrders += count;
            statusBreakdown[r.status] = count;
            if (r.status === 'cancelled') cancelledCount = count;
        });

        const cancellationRate = totalOrders > 0 ? parseFloat(((cancelledCount / totalOrders) * 100).toFixed(1)) : 0;

        // Average fulfillment time (placed -> ready/collected)
        const fulfillmentRes = await pool.query(
            `SELECT COALESCE(AVG(EXTRACT(EPOCH FROM (COALESCE(completed_at, updated_at) - created_at))/60), 0) as avg_minutes
             FROM orders
             WHERE shop_id = $1 AND status IN ('ready', 'collected') AND created_at >= $2 AND created_at <= $3`,
            [shopId, startDate, endDate]
        );
        const avgFulfillmentMinutes = Math.round(parseFloat(fulfillmentRes.rows[0].avg_minutes) || 0);

        // Busiest hours heatmap (0..23)
        const hoursRes = await pool.query(
            `SELECT 
                EXTRACT(HOUR FROM created_at)::int as hour,
                COUNT(*) as order_count
             FROM orders
             WHERE shop_id = $1 AND created_at >= $2 AND created_at <= $3
             GROUP BY hour
             ORDER BY hour ASC`,
            [shopId, startDate, endDate]
        );

        const hoursMap = {};
        for (let i = 0; i < 24; i++) hoursMap[i] = 0;
        hoursRes.rows.forEach(r => { hoursMap[r.hour] = parseInt(r.order_count, 10); });

        const busiestHours = Object.keys(hoursMap).map(h => ({
            hour: parseInt(h, 10),
            label: `${String(h).padStart(2, '0')}:00`,
            orders: hoursMap[h]
        }));

        // Busiest days (1=Mon, 7=Sun)
        const daysMap = { 1: 'Mon', 2: 'Tue', 3: 'Wed', 4: 'Thu', 5: 'Fri', 6: 'Sat', 7: 'Sun' };
        const daysRes = await pool.query(
            `SELECT 
                EXTRACT(ISODOW FROM created_at)::int as day_of_week,
                COUNT(*) as order_count
             FROM orders
             WHERE shop_id = $1 AND created_at >= $2 AND created_at <= $3
             GROUP BY day_of_week
             ORDER BY day_of_week ASC`,
            [shopId, startDate, endDate]
        );

        const busiestDays = [1, 2, 3, 4, 5, 6, 7].map(d => {
            const found = daysRes.rows.find(r => parseInt(r.day_of_week, 10) === d);
            return {
                day: d,
                name: daysMap[d],
                orders: found ? parseInt(found.order_count, 10) : 0
            };
        });

        // Daily orders trend
        const dailyOrdersRes = await pool.query(
            `SELECT 
                TO_CHAR(created_at, 'YYYY-MM-DD') as date,
                COUNT(*) as count
             FROM orders
             WHERE shop_id = $1 AND created_at >= $2 AND created_at <= $3
             GROUP BY TO_CHAR(created_at, 'YYYY-MM-DD')
             ORDER BY date ASC`,
            [shopId, startDate, endDate]
        );

        res.json({
            total_orders: totalOrders,
            status_breakdown: statusBreakdown,
            cancellation_rate: cancellationRate,
            avg_fulfillment_time_minutes: avgFulfillmentMinutes,
            busiest_hours: busiestHours,
            busiest_days: busiestDays,
            daily_trend: dailyOrdersRes.rows.map(r => ({ date: r.date, orders: parseInt(r.count, 10) }))
        });
    } catch (err) {
        console.error('Error fetching order analytics:', err);
        res.status(500).json({ error: 'Failed to fetch order analytics' });
    }
});

/**
 * @route   GET /api/shop/analytics/print-options
 * @desc    Print option popularity breakdown (color, size, sides, binding)
 */
router.get('/print-options', async (req, res) => {
    try {
        const { startDate, endDate } = getDateRange(req.query);
        const shopId = req.shop_id;

        const ordersRes = await pool.query(
            `SELECT print_options, files FROM orders WHERE shop_id = $1 AND created_at >= $2 AND created_at <= $3`,
            [shopId, startDate, endDate]
        );

        const counts = {
            color: { bw: 0, color: 0 },
            size: { A4: 0, A3: 0, Letter: 0, other: 0 },
            sides: { single: 0, double: 0 },
            binding: { none: 0, staple: 0, spiral: 0 },
            totalCopies: 0,
            totalPages: 0,
            sampleCount: ordersRes.rows.length
        };

        ordersRes.rows.forEach(r => {
            let opts = {};
            try {
                opts = typeof r.print_options === 'string' ? JSON.parse(r.print_options) : (r.print_options || {});
            } catch (e) {}

            // Color
            const col = (opts.color || '').toLowerCase();
            if (col === 'color') counts.color.color++;
            else counts.color.bw++;

            // Size
            const sz = (opts.size || 'A4').toUpperCase();
            if (counts.size[sz] !== undefined) counts.size[sz]++;
            else counts.size.other++;

            // Sides
            const sd = (opts.sides || 'single').toLowerCase();
            if (sd.includes('double') || sd.includes('two')) counts.sides.double++;
            else counts.sides.single++;

            // Binding
            const bd = (opts.binding || 'none').toLowerCase();
            if (bd.includes('staple')) counts.binding.staple++;
            else if (bd.includes('spiral')) counts.binding.spiral++;
            else counts.binding.none++;

            counts.totalCopies += parseInt(opts.copies, 10) || 1;
            counts.totalPages += parseInt(opts.page_count, 10) || 1;
        });

        const total = Math.max(1, counts.sampleCount);

        res.json({
            total_orders_analyzed: counts.sampleCount,
            color_split: {
                bw_pct: parseFloat(((counts.color.bw / total) * 100).toFixed(1)),
                color_pct: parseFloat(((counts.color.color / total) * 100).toFixed(1)),
                counts: counts.color
            },
            size_split: {
                a4_pct: parseFloat(((counts.size.A4 / total) * 100).toFixed(1)),
                a3_pct: parseFloat(((counts.size.A3 / total) * 100).toFixed(1)),
                letter_pct: parseFloat(((counts.size.Letter / total) * 100).toFixed(1)),
                counts: counts.size
            },
            sides_split: {
                single_pct: parseFloat(((counts.sides.single / total) * 100).toFixed(1)),
                double_pct: parseFloat(((counts.sides.double / total) * 100).toFixed(1)),
                counts: counts.sides
            },
            binding_split: {
                none_pct: parseFloat(((counts.binding.none / total) * 100).toFixed(1)),
                staple_pct: parseFloat(((counts.binding.staple / total) * 100).toFixed(1)),
                spiral_pct: parseFloat(((counts.binding.spiral / total) * 100).toFixed(1)),
                counts: counts.binding
            },
            averages: {
                avg_copies_per_order: parseFloat((counts.totalCopies / total).toFixed(1)),
                avg_pages_per_order: parseFloat((counts.totalPages / total).toFixed(1))
            }
        });
    } catch (err) {
        console.error('Error fetching print options analytics:', err);
        res.status(500).json({ error: 'Failed to fetch print options analytics' });
    }
});

/**
 * @route   GET /api/shop/analytics/customers
 * @desc    Customer metrics: unique customers, new vs returning, guest %
 */
router.get('/customers', async (req, res) => {
    try {
        const { startDate, endDate } = getDateRange(req.query);
        const shopId = req.shop_id;

        const custRes = await pool.query(
            `SELECT 
                COUNT(*) as total_orders,
                COUNT(DISTINCT customer_id) FILTER (WHERE customer_id IS NOT NULL) as unique_registered_customers,
                COUNT(*) FILTER (WHERE customer_id IS NULL) as guest_orders
             FROM orders
             WHERE shop_id = $1 AND created_at >= $2 AND created_at <= $3`,
            [shopId, startDate, endDate]
        );

        const row = custRes.rows[0];
        const totalOrders = parseInt(row.total_orders, 10);
        const uniqueCustomers = parseInt(row.unique_registered_customers, 10);
        const guestOrders = parseInt(row.guest_orders, 10);
        const guestPct = totalOrders > 0 ? parseFloat(((guestOrders / totalOrders) * 100).toFixed(1)) : 0;

        // New vs returning customers in shop history
        const repeatRes = await pool.query(
            `SELECT customer_id, COUNT(*) as order_count 
             FROM orders 
             WHERE shop_id = $1 AND customer_id IS NOT NULL 
             GROUP BY customer_id`,
            [shopId]
        );

        let returningCustomers = 0;
        let newCustomers = 0;

        repeatRes.rows.forEach(r => {
            if (parseInt(r.order_count, 10) > 1) returningCustomers++;
            else newCustomers++;
        });

        const retentionRate = (newCustomers + returningCustomers) > 0 
            ? parseFloat(((returningCustomers / (newCustomers + returningCustomers)) * 100).toFixed(1)) 
            : 0;

        res.json({
            total_unique_customers: uniqueCustomers,
            guest_orders: guestOrders,
            guest_orders_pct: guestPct,
            new_customers: newCustomers,
            returning_customers: returningCustomers,
            customer_retention_pct: retentionRate
        });
    } catch (err) {
        console.error('Error fetching customer analytics:', err);
        res.status(500).json({ error: 'Failed to fetch customer analytics' });
    }
});

/**
 * @route   GET /api/shop/analytics/queue
 * @desc    Queue performance metrics
 */
router.get('/queue', async (req, res) => {
    try {
        const { startDate, endDate } = getDateRange(req.query);
        const shopId = req.shop_id;

        const queueRes = await pool.query(
            `SELECT 
                COUNT(CASE WHEN status = 'queued' THEN 1 END) as current_length,
                COALESCE(AVG(EXTRACT(EPOCH FROM (updated_at - created_at))/60), 12) as avg_wait_minutes,
                COUNT(CASE WHEN status = 'ready' OR status = 'collected' THEN 1 END) as completed_on_time
             FROM orders
             WHERE shop_id = $1 AND created_at >= $2 AND created_at <= $3`,
            [shopId, startDate, endDate]
        );

        const r = queueRes.rows[0];

        res.json({
            current_queue_length: parseInt(r.current_length, 10),
            avg_wait_minutes: Math.round(parseFloat(r.avg_wait_minutes) || 12),
            orders_completed_on_time: parseInt(r.completed_on_time, 10)
        });
    } catch (err) {
        console.error('Error fetching queue analytics:', err);
        res.status(500).json({ error: 'Failed to fetch queue analytics' });
    }
});

/**
 * @route   GET /api/shop/analytics/products
 * @desc    Product / Manual sales metrics (top selling manuals, low stock alerts, revenue split)
 */
router.get('/products', async (req, res) => {
    try {
        const { startDate, endDate } = getDateRange(req.query);
        const shopId = req.shop_id;

        // 1. Top selling manuals
        const topRes = await pool.query(
            `SELECT 
                p.product_id,
                p.title,
                p.branch,
                p.course_type,
                p.price,
                p.stock_count,
                COALESCE(SUM(po.quantity), 0) as units_sold,
                COALESCE(SUM(po.amount_total), 0) as total_revenue
             FROM products p
             LEFT JOIN product_orders po ON p.product_id = po.product_id AND po.status != 'cancelled' AND po.created_at >= $2 AND po.created_at <= $3
             WHERE p.shop_id = $1
             GROUP BY p.product_id, p.title, p.branch, p.course_type, p.price, p.stock_count
             ORDER BY units_sold DESC, total_revenue DESC
             LIMIT 10`,
            [shopId, startDate, endDate]
        );

        // 2. Low stock alerts (stock <= 5)
        const lowStockRes = await pool.query(
            `SELECT product_id, title, stock_count, price 
             FROM products 
             WHERE shop_id = $1 AND is_active = true AND stock_count <= 5 
             ORDER BY stock_count ASC`,
            [shopId]
        );

        // 3. Revenue split: print orders vs product orders
        const printRevRes = await pool.query(
            `SELECT COALESCE(SUM(amount_total), 0) as print_rev 
             FROM orders 
             WHERE shop_id = $1 AND status != 'cancelled' AND created_at >= $2 AND created_at <= $3`,
            [shopId, startDate, endDate]
        );

        const prodRevRes = await pool.query(
            `SELECT COALESCE(SUM(amount_total), 0) as product_rev 
             FROM product_orders 
             WHERE shop_id = $1 AND status != 'cancelled' AND created_at >= $2 AND created_at <= $3`,
            [shopId, startDate, endDate]
        );

        const printRevenue = parseFloat(printRevRes.rows[0].print_rev);
        const productRevenue = parseFloat(prodRevRes.rows[0].product_rev);

        res.json({
            top_selling_manuals: topRes.rows.map(r => ({
                product_id: r.product_id,
                title: r.title,
                branch: r.branch,
                course_type: r.course_type,
                price: parseFloat(r.price),
                stock_count: parseInt(r.stock_count, 10),
                units_sold: parseInt(r.units_sold, 10),
                total_revenue: parseFloat(r.total_revenue)
            })),
            low_stock_alerts: lowStockRes.rows.map(r => ({
                product_id: r.product_id,
                title: r.title,
                stock_count: parseInt(r.stock_count, 10),
                price: parseFloat(r.price)
            })),
            revenue_split: {
                print_revenue: printRevenue,
                product_revenue: productRevenue,
                total_combined: printRevenue + productRevenue
            }
        });
    } catch (err) {
        console.error('Error fetching product analytics:', err);
        res.status(500).json({ error: 'Failed to fetch product analytics' });
    }
});

module.exports = router;
