import React, { useState, useEffect } from 'react';
import api from '../../core/api';
import {
  ResponsiveContainer,
  AreaChart,
  Area,
  BarChart,
  Bar,
  XAxis,
  YAxis,
  Tooltip,
  CartesianGrid,
  PieChart,
  Pie,
  Cell,
  Legend
} from 'recharts';

const Analytics = () => {
  const [period, setPeriod] = useState('30days'); // 'today' | 'week' | '30days' | 'custom'
  const [customFrom, setCustomFrom] = useState('');
  const [customTo, setCustomTo] = useState('');

  const [isLoading, setIsLoading] = useState(true);
  const [summaryData, setSummaryData] = useState(null);
  const [revenueData, setRevenueData] = useState(null);
  const [orderData, setOrderData] = useState(null);
  const [printOptData, setPrintOptData] = useState(null);
  const [customerData, setCustomerData] = useState(null);
  const [productData, setProductData] = useState(null);

  const fetchAnalytics = async () => {
    setIsLoading(true);
    try {
      let queryStr = `period=${period}`;
      if (period === 'custom' && customFrom && customTo) {
        queryStr = `from=${customFrom}&to=${customTo}`;
      }

      const [sumRes, revRes, ordRes, optRes, custRes, prodRes] = await Promise.all([
        api.get(`/shop/analytics/summary?${queryStr}`),
        api.get(`/shop/analytics/revenue?${queryStr}`),
        api.get(`/shop/analytics/orders?${queryStr}`),
        api.get(`/shop/analytics/print-options?${queryStr}`),
        api.get(`/shop/analytics/customers?${queryStr}`),
        api.get(`/shop/analytics/products?${queryStr}`)
      ]);

      setSummaryData(sumRes.data);
      setRevenueData(revRes.data);
      setOrderData(ordRes.data);
      setPrintOptData(optRes.data);
      setCustomerData(custRes.data);
      setProductData(prodRes.data);
    } catch (err) {
      console.error('Failed to load shop analytics:', err);
    } finally {
      setIsLoading(false);
    }
  };

  useEffect(() => {
    fetchAnalytics();
  }, [period]);

  const handleCustomSubmit = (e) => {
    e.preventDefault();
    if (customFrom && customTo) {
      fetchAnalytics();
    }
  };

  // Color constants for charts
  const COLOR_PALETTE = ['#00E5FF', '#FFC107', '#DDB7FF', '#FF5252', '#4CAF50', '#FF9800'];

  return (
    <div className="p-4 md:p-8 h-full flex flex-col gap-6 overflow-y-auto">
      {/* Header & Controls */}
      <div className="flex flex-col md:flex-row md:items-center justify-between gap-4">
        <div>
          <h1 className="text-2xl font-bold text-on-surface">Shop Analytics & Insights</h1>
          <p className="text-sm text-on-surface-variant">Data-driven insights to help optimize shop revenue, peak hours, and print volume</p>
        </div>

        <div className="flex items-center gap-3">
          <button 
            onClick={fetchAnalytics}
            className="bg-surface-container-highest border border-outline-variant text-on-surface px-4 py-2 rounded-lg text-sm hover:bg-surface-variant transition-colors"
          >
            ↻ Refresh Data
          </button>
        </div>
      </div>

      {/* Time Filter Bar */}
      <div className="flex flex-wrap items-center justify-between gap-4 p-2 bg-black/30 border border-outline-variant/30 rounded-xl">
        <div className="flex items-center gap-2">
          {[
            { key: 'today', label: 'Today' },
            { key: 'week', label: 'Last 7 Days' },
            { key: '30days', label: 'Last 30 Days' },
            { key: 'custom', label: 'Custom Range' }
          ].map(t => (
            <button
              key={t.key}
              onClick={() => setPeriod(t.key)}
              className={`px-4 py-1.5 rounded-lg text-sm font-medium transition-all ${
                period === t.key
                  ? 'bg-primary-container text-on-primary-container border border-primary/40 shadow'
                  : 'text-on-surface-variant hover:text-on-surface hover:bg-white/5'
              }`}
            >
              {t.label}
            </button>
          ))}
        </div>

        {period === 'custom' && (
          <form onSubmit={handleCustomSubmit} className="flex items-center gap-2 text-sm">
            <input
              type="date"
              value={customFrom}
              onChange={e => setCustomFrom(e.target.value)}
              className="bg-surface-container border border-outline-variant/40 text-on-surface px-3 py-1 rounded"
              required
            />
            <span className="text-on-surface-variant">to</span>
            <input
              type="date"
              value={customTo}
              onChange={e => setCustomTo(e.target.value)}
              className="bg-surface-container border border-outline-variant/40 text-on-surface px-3 py-1 rounded"
              required
            />
            <button type="submit" className="bg-tertiary/20 text-tertiary border border-tertiary/30 px-3 py-1 rounded hover:bg-tertiary/30">
              Apply
            </button>
          </form>
        )}
      </div>

      {isLoading ? (
        <div className="flex-1 flex items-center justify-center text-on-surface-variant py-20">
          <div className="flex flex-col items-center gap-3">
            <div className="w-8 h-8 border-4 border-primary border-t-transparent rounded-full animate-spin"></div>
            <span>Calculating analytics metrics...</span>
          </div>
        </div>
      ) : (
        <>
          {/* Summary Metric Cards */}
          <div className="grid grid-cols-1 sm:grid-cols-2 lg:grid-cols-4 gap-6">
            {/* Total Revenue */}
            <div className="bg-surface-container/90 border border-outline-variant/30 rounded-2xl p-5 shadow-sm hover:border-outline-variant transition-all flex flex-col justify-between">
              <div>
                <div className="flex justify-between items-start">
                  <span className="text-xs font-semibold uppercase tracking-wider text-on-surface-variant">Total Revenue</span>
                  <span className="material-symbols-outlined text-green-400 text-xl">payments</span>
                </div>
                <div className="text-3xl font-extrabold text-green-400 mt-2">
                  ₹{(summaryData?.revenue?.total || 0).toLocaleString('en-IN', { minimumFractionDigits: 2 })}
                </div>
              </div>
              <div className="mt-4 pt-3 border-t border-white/5 flex justify-between text-xs text-on-surface-variant">
                <span>Net: ₹{(summaryData?.revenue?.net || 0).toFixed(2)}</span>
                <span className="text-red-400">Refunds: ₹{(summaryData?.revenue?.refunds || 0).toFixed(2)}</span>
              </div>
            </div>

            {/* Total Orders */}
            <div className="bg-surface-container/90 border border-outline-variant/30 rounded-2xl p-5 shadow-sm hover:border-outline-variant transition-all flex flex-col justify-between">
              <div>
                <div className="flex justify-between items-start">
                  <span className="text-xs font-semibold uppercase tracking-wider text-on-surface-variant">Total Orders</span>
                  <span className="material-symbols-outlined text-primary text-xl">receipt_long</span>
                </div>
                <div className="text-3xl font-extrabold text-primary mt-2">
                  {summaryData?.orders?.total || 0}
                </div>
              </div>
              <div className="mt-4 pt-3 border-t border-white/5 flex justify-between text-xs text-on-surface-variant">
                <span className="text-green-400">✓ {summaryData?.orders?.collected || 0} Delivered</span>
                <span className="text-yellow-400">⏱ {summaryData?.orders?.cancellation_rate || 0}% Cancelled</span>
              </div>
            </div>

            {/* Avg Order Value */}
            <div className="bg-surface-container/90 border border-outline-variant/30 rounded-2xl p-5 shadow-sm hover:border-outline-variant transition-all flex flex-col justify-between">
              <div>
                <div className="flex justify-between items-start">
                  <span className="text-xs font-semibold uppercase tracking-wider text-on-surface-variant">Avg Order Value</span>
                  <span className="material-symbols-outlined text-amber-400 text-xl">analytics</span>
                </div>
                <div className="text-3xl font-extrabold text-amber-400 mt-2">
                  ₹{(summaryData?.revenue?.avg_order_value || 0).toFixed(2)}
                </div>
              </div>
              <div className="mt-4 pt-3 border-t border-white/5 text-xs text-on-surface-variant">
                Average ticket size per checkout
              </div>
            </div>

            {/* Queue Performance */}
            <div className="bg-surface-container/90 border border-outline-variant/30 rounded-2xl p-5 shadow-sm hover:border-outline-variant transition-all flex flex-col justify-between">
              <div>
                <div className="flex justify-between items-start">
                  <span className="text-xs font-semibold uppercase tracking-wider text-on-surface-variant">Queue Speed</span>
                  <span className="material-symbols-outlined text-cyan-400 text-xl">timer</span>
                </div>
                <div className="text-3xl font-extrabold text-cyan-400 mt-2">
                  ~{summaryData?.queue?.avg_wait_minutes || 12} min
                </div>
              </div>
              <div className="mt-4 pt-3 border-t border-white/5 flex justify-between text-xs text-on-surface-variant">
                <span>Active Queue: {summaryData?.queue?.current_length || 0} orders</span>
              </div>
            </div>
          </div>

          {/* Revenue & Orders Trend Charts */}
          <div className="grid grid-cols-1 lg:grid-cols-2 gap-6">
            {/* Revenue Trend Area Chart */}
            <div className="bg-surface-container border border-outline-variant/30 rounded-2xl p-6 shadow-sm flex flex-col gap-4">
              <div className="flex justify-between items-center">
                <div>
                  <h3 className="font-bold text-lg text-on-surface">Revenue Trend</h3>
                  <p className="text-xs text-on-surface-variant">Daily earnings over selected period</p>
                </div>
                <span className="text-xs bg-green-500/10 text-green-400 border border-green-500/30 px-2 py-1 rounded-full">
                  Line Chart
                </span>
              </div>

              <div className="h-[260px] w-full">
                {revenueData?.daily_trend && revenueData.daily_trend.length > 0 ? (
                  <ResponsiveContainer width="100%" height="100%">
                    <AreaChart data={revenueData.daily_trend} margin={{ top: 10, right: 10, left: -20, bottom: 0 }}>
                      <defs>
                        <linearGradient id="colorRevenue" x1="0" y1="0" x2="0" y2="1">
                          <stop offset="5%" stopColor="#4CAF50" stopOpacity={0.4}/>
                          <stop offset="95%" stopColor="#4CAF50" stopOpacity={0.0}/>
                        </linearGradient>
                      </defs>
                      <CartesianGrid strokeDasharray="3 3" stroke="rgba(255,255,255,0.05)" />
                      <XAxis dataKey="date" stroke="#888" fontSize={11} tickLine={false} />
                      <YAxis stroke="#888" fontSize={11} tickLine={false} />
                      <Tooltip 
                        contentStyle={{ backgroundColor: '#182032', borderColor: '#334155', borderRadius: '8px', color: '#fff' }}
                        formatter={(val) => [`₹${val}`, 'Revenue']}
                      />
                      <Area type="monotone" dataKey="revenue" stroke="#4CAF50" strokeWidth={2} fillOpacity={1} fill="url(#colorRevenue)" />
                    </AreaChart>
                  </ResponsiveContainer>
                ) : (
                  <div className="h-full flex items-center justify-center text-sm text-on-surface-variant">
                    No revenue data available for this timeframe
                  </div>
                )}
              </div>
            </div>

            {/* Daily Orders Bar Chart */}
            <div className="bg-surface-container border border-outline-variant/30 rounded-2xl p-6 shadow-sm flex flex-col gap-4">
              <div className="flex justify-between items-center">
                <div>
                  <h3 className="font-bold text-lg text-on-surface">Order Volume Trend</h3>
                  <p className="text-xs text-on-surface-variant">Daily number of print orders processed</p>
                </div>
                <span className="text-xs bg-primary/10 text-primary border border-primary/30 px-2 py-1 rounded-full">
                  Bar Chart
                </span>
              </div>

              <div className="h-[260px] w-full">
                {orderData?.daily_trend && orderData.daily_trend.length > 0 ? (
                  <ResponsiveContainer width="100%" height="100%">
                    <BarChart data={orderData.daily_trend} margin={{ top: 10, right: 10, left: -20, bottom: 0 }}>
                      <CartesianGrid strokeDasharray="3 3" stroke="rgba(255,255,255,0.05)" />
                      <XAxis dataKey="date" stroke="#888" fontSize={11} tickLine={false} />
                      <YAxis stroke="#888" fontSize={11} tickLine={false} />
                      <Tooltip 
                        contentStyle={{ backgroundColor: '#182032', borderColor: '#334155', borderRadius: '8px', color: '#fff' }}
                        formatter={(val) => [`${val} orders`, 'Orders']}
                      />
                      <Bar dataKey="orders" fill="#8083FF" radius={[4, 4, 0, 0]} />
                    </BarChart>
                  </ResponsiveContainer>
                ) : (
                  <div className="h-full flex items-center justify-center text-sm text-on-surface-variant">
                    No order volume data available for this timeframe
                  </div>
                )}
              </div>
            </div>
          </div>

          {/* Print Options Popularity Breakdown */}
          <div className="bg-surface-container border border-outline-variant/30 rounded-2xl p-6 shadow-sm flex flex-col gap-6">
            <div>
              <h3 className="font-bold text-lg text-on-surface">Print Options Popularity</h3>
              <p className="text-xs text-on-surface-variant">Customer configuration preferences (Color, Paper Size, Sides, Binding)</p>
            </div>

            <div className="grid grid-cols-1 sm:grid-cols-2 lg:grid-cols-4 gap-6">
              {/* Color Split */}
              <div className="bg-black/20 p-4 rounded-xl border border-outline-variant/20 flex flex-col gap-3">
                <span className="text-xs font-semibold text-on-surface-variant uppercase">Color vs B&W</span>
                <div className="flex items-center justify-between text-sm">
                  <span>⬛ B&W: {printOptData?.color_split?.bw_pct || 0}%</span>
                  <span className="text-amber-400">🎨 Color: {printOptData?.color_split?.color_pct || 0}%</span>
                </div>
                <div className="w-full bg-white/10 h-3 rounded-full overflow-hidden flex">
                  <div className="bg-gray-400 h-full" style={{ width: `${printOptData?.color_split?.bw_pct || 100}%` }}></div>
                  <div className="bg-amber-400 h-full" style={{ width: `${printOptData?.color_split?.color_pct || 0}%` }}></div>
                </div>
              </div>

              {/* Paper Size Split */}
              <div className="bg-black/20 p-4 rounded-xl border border-outline-variant/20 flex flex-col gap-3">
                <span className="text-xs font-semibold text-on-surface-variant uppercase">Paper Size</span>
                <div className="flex items-center justify-between text-xs">
                  <span>A4: {printOptData?.size_split?.a4_pct || 0}%</span>
                  <span>A3: {printOptData?.size_split?.a3_pct || 0}%</span>
                  <span>Letter: {printOptData?.size_split?.letter_pct || 0}%</span>
                </div>
                <div className="w-full bg-white/10 h-3 rounded-full overflow-hidden flex">
                  <div className="bg-cyan-400 h-full" style={{ width: `${printOptData?.size_split?.a4_pct || 100}%` }}></div>
                  <div className="bg-purple-400 h-full" style={{ width: `${printOptData?.size_split?.a3_pct || 0}%` }}></div>
                  <div className="bg-amber-400 h-full" style={{ width: `${printOptData?.size_split?.letter_pct || 0}%` }}></div>
                </div>
              </div>

              {/* Sides Split */}
              <div className="bg-black/20 p-4 rounded-xl border border-outline-variant/20 flex flex-col gap-3">
                <span className="text-xs font-semibold text-on-surface-variant uppercase">Print Sides</span>
                <div className="flex items-center justify-between text-sm">
                  <span>Single: {printOptData?.sides_split?.single_pct || 0}%</span>
                  <span className="text-blue-400">Double: {printOptData?.sides_split?.double_pct || 0}%</span>
                </div>
                <div className="w-full bg-white/10 h-3 rounded-full overflow-hidden flex">
                  <div className="bg-gray-400 h-full" style={{ width: `${printOptData?.sides_split?.single_pct || 100}%` }}></div>
                  <div className="bg-blue-400 h-full" style={{ width: `${printOptData?.sides_split?.double_pct || 0}%` }}></div>
                </div>
              </div>

              {/* Binding Split */}
              <div className="bg-black/20 p-4 rounded-xl border border-outline-variant/20 flex flex-col gap-3">
                <span className="text-xs font-semibold text-on-surface-variant uppercase">Binding Options</span>
                <div className="flex items-center justify-between text-xs">
                  <span>None: {printOptData?.binding_split?.none_pct || 0}%</span>
                  <span className="text-yellow-400">Staple: {printOptData?.binding_split?.staple_pct || 0}%</span>
                  <span className="text-green-400">Spiral: {printOptData?.binding_split?.spiral_pct || 0}%</span>
                </div>
                <div className="w-full bg-white/10 h-3 rounded-full overflow-hidden flex">
                  <div className="bg-gray-500 h-full" style={{ width: `${printOptData?.binding_split?.none_pct || 100}%` }}></div>
                  <div className="bg-yellow-400 h-full" style={{ width: `${printOptData?.binding_split?.staple_pct || 0}%` }}></div>
                  <div className="bg-green-400 h-full" style={{ width: `${printOptData?.binding_split?.spiral_pct || 0}%` }}></div>
                </div>
              </div>
            </div>

            {/* Paper Planning Stats */}
            <div className="flex flex-wrap gap-4 pt-4 border-t border-white/5">
              <div className="flex items-center gap-2 bg-surface-container-high px-3 py-1.5 rounded-lg text-sm">
                <span className="text-on-surface-variant">Average Copies per Order:</span>
                <span className="font-bold text-accent">{printOptData?.averages?.avg_copies_per_order || 1.0}</span>
              </div>
              <div className="flex items-center gap-2 bg-surface-container-high px-3 py-1.5 rounded-lg text-sm">
                <span className="text-on-surface-variant">Average Pages per Order:</span>
                <span className="font-bold text-tertiary">{printOptData?.averages?.avg_pages_per_order || 1.0}</span>
              </div>
            </div>
          </div>

          {/* Peak Hours Heatmap & Busiest Days */}
          <div className="grid grid-cols-1 lg:grid-cols-2 gap-6">
            {/* 24-Hour Peak Hours Activity */}
            <div className="bg-surface-container border border-outline-variant/30 rounded-2xl p-6 shadow-sm flex flex-col gap-4">
              <div>
                <h3 className="font-bold text-lg text-on-surface">Busiest Hours Heatmap</h3>
                <p className="text-xs text-on-surface-variant">Order frequency by hour of day (00:00 - 23:00)</p>
              </div>

              <div className="h-[220px] w-full">
                {orderData?.busiest_hours && (
                  <ResponsiveContainer width="100%" height="100%">
                    <BarChart data={orderData.busiest_hours} margin={{ top: 10, right: 10, left: -25, bottom: 0 }}>
                      <CartesianGrid strokeDasharray="3 3" stroke="rgba(255,255,255,0.05)" />
                      <XAxis dataKey="hour" stroke="#888" fontSize={10} tickLine={false} />
                      <YAxis stroke="#888" fontSize={10} tickLine={false} />
                      <Tooltip 
                        contentStyle={{ backgroundColor: '#182032', borderColor: '#334155', borderRadius: '8px', color: '#fff' }}
                        formatter={(val) => [`${val} orders`, 'Peak Hours']}
                      />
                      <Bar dataKey="orders" fill="#FFC107" radius={[2, 2, 0, 0]} />
                    </BarChart>
                  </ResponsiveContainer>
                )}
              </div>
            </div>

            {/* Busiest Days of Week */}
            <div className="bg-surface-container border border-outline-variant/30 rounded-2xl p-6 shadow-sm flex flex-col gap-4">
              <div>
                <h3 className="font-bold text-lg text-on-surface">Busiest Days of Week</h3>
                <p className="text-xs text-on-surface-variant">Order distribution across Monday - Sunday</p>
              </div>

              <div className="h-[220px] w-full">
                {orderData?.busiest_days && (
                  <ResponsiveContainer width="100%" height="100%">
                    <BarChart data={orderData.busiest_days} margin={{ top: 10, right: 10, left: -25, bottom: 0 }}>
                      <CartesianGrid strokeDasharray="3 3" stroke="rgba(255,255,255,0.05)" />
                      <XAxis dataKey="name" stroke="#888" fontSize={11} tickLine={false} />
                      <YAxis stroke="#888" fontSize={10} tickLine={false} />
                      <Tooltip 
                        contentStyle={{ backgroundColor: '#182032', borderColor: '#334155', borderRadius: '8px', color: '#fff' }}
                        formatter={(val) => [`${val} orders`, 'Day Volume']}
                      />
                      <Bar dataKey="orders" fill="#00E5FF" radius={[4, 4, 0, 0]} />
                    </BarChart>
                  </ResponsiveContainer>
                )}
              </div>
            </div>
          </div>

          {/* Marketplace Manuals & Customer Insights */}
          <div className="grid grid-cols-1 lg:grid-cols-3 gap-6">
            {/* Top Selling Manuals (2 cols) */}
            <div className="lg:col-span-2 bg-surface-container border border-outline-variant/30 rounded-2xl p-6 shadow-sm flex flex-col gap-4">
              <div className="flex justify-between items-center">
                <div>
                  <h3 className="font-bold text-lg text-on-surface">Top Selling Manuals</h3>
                  <p className="text-xs text-on-surface-variant">Marketplace sales performance by title</p>
                </div>
                {productData?.low_stock_alerts?.length > 0 && (
                  <span className="text-xs bg-red-500/15 text-red-400 border border-red-500/30 px-3 py-1 rounded-full font-bold flex items-center gap-1">
                    ⚠️ {productData.low_stock_alerts.length} Low Stock
                  </span>
                )}
              </div>

              <div className="overflow-x-auto">
                <table className="w-full text-left border-collapse">
                  <thead>
                    <tr className="border-b border-white/10 text-[0.7rem] uppercase tracking-wider text-on-surface-variant">
                      <th className="pb-3">Title / Subject</th>
                      <th className="pb-3">Branch</th>
                      <th className="pb-3">Price</th>
                      <th className="pb-3">Units Sold</th>
                      <th className="pb-3">Stock</th>
                    </tr>
                  </thead>
                  <tbody>
                    {productData?.top_selling_manuals && productData.top_selling_manuals.length > 0 ? (
                      productData.top_selling_manuals.map((m) => (
                        <tr key={m.product_id} className="border-b border-white/5 hover:bg-white/5 transition-colors text-sm">
                          <td className="py-3 font-semibold text-on-surface">{m.title}</td>
                          <td className="py-3 text-xs text-on-surface-variant">{m.branch}</td>
                          <td className="py-3 font-bold text-accent">₹{m.price}</td>
                          <td className="py-3 font-bold text-tertiary">{m.units_sold}</td>
                          <td className="py-3">
                            <span className={`px-2 py-0.5 rounded text-xs font-bold ${
                              m.stock_count <= 5 ? 'bg-red-500/20 text-red-400 border border-red-500/30' : 'bg-green-500/10 text-green-400'
                            }`}>
                              {m.stock_count} left
                            </span>
                          </td>
                        </tr>
                      ))
                    ) : (
                      <tr>
                        <td colSpan="5" className="py-8 text-center text-xs text-on-surface-variant">
                          No manual products listed or sold in this period
                        </td>
                      </tr>
                    )}
                  </tbody>
                </table>
              </div>
            </div>

            {/* Customer Retention Insights (1 col) */}
            <div className="bg-surface-container border border-outline-variant/30 rounded-2xl p-6 shadow-sm flex flex-col justify-between gap-4">
              <div>
                <h3 className="font-bold text-lg text-on-surface mb-1">Customer Metrics</h3>
                <p className="text-xs text-on-surface-variant mb-6">User acquisition & retention breakdown</p>

                <div className="flex flex-col gap-4">
                  <div className="bg-black/20 p-4 rounded-xl border border-outline-variant/20 flex justify-between items-center">
                    <div>
                      <span className="text-xs text-on-surface-variant block uppercase">Unique Customers</span>
                      <span className="text-2xl font-bold text-primary">{customerData?.total_unique_customers || 0}</span>
                    </div>
                    <span className="material-symbols-outlined text-primary text-3xl opacity-80">group</span>
                  </div>

                  <div className="bg-black/20 p-4 rounded-xl border border-outline-variant/20 flex justify-between items-center">
                    <div>
                      <span className="text-xs text-on-surface-variant block uppercase">New vs Returning</span>
                      <span className="text-sm font-semibold text-on-surface">
                        🆕 {customerData?.new_customers || 0} New • 🔄 {customerData?.returning_customers || 0} Repeat
                      </span>
                    </div>
                  </div>

                  <div className="bg-black/20 p-4 rounded-xl border border-outline-variant/20 flex justify-between items-center">
                    <div>
                      <span className="text-xs text-on-surface-variant block uppercase">Guest Order %</span>
                      <span className="text-xl font-bold text-amber-400">{customerData?.guest_orders_pct || 0}%</span>
                    </div>
                    <span className="text-xs text-on-surface-variant">({customerData?.guest_orders || 0} guest orders)</span>
                  </div>
                </div>
              </div>

              <div className="p-4 bg-tertiary/10 border border-tertiary/20 rounded-xl flex items-center justify-between mt-4">
                <div>
                  <span className="text-xs text-tertiary uppercase font-bold block">Retention Rate</span>
                  <span className="text-2xl font-extrabold text-tertiary">{customerData?.customer_retention_pct || 0}%</span>
                </div>
                <span className="material-symbols-outlined text-tertiary text-3xl">workspace_premium</span>
              </div>
            </div>
          </div>
        </>
      )}
    </div>
  );
};

export default Analytics;
