import React, { useState, useEffect } from 'react';
import api from '../../core/api';

const Analytics = () => {
  const [analytics, setAnalytics] = useState({ todayOrders: 0, todayRevenue: 0, totalRevenue: 0 });
  const [isLoading, setIsLoading] = useState(true);

  useEffect(() => {
    const fetchAnalytics = async () => {
      try {
        const res = await api.get('/shop/analytics');
        setAnalytics(res.data);
      } catch (err) {
        console.error('Failed to load analytics:', err);
      } finally {
        setIsLoading(false);
      }
    };
    fetchAnalytics();
  }, []);

  return (
    <div className="p-4 md:p-8 h-full flex flex-col">
      <div className="mb-6">
        <h1 className="text-2xl font-bold">Analytics & Revenue</h1>
      </div>

      {isLoading ? (
        <div className="text-on-surface-variant">Loading data...</div>
      ) : (
        <div className="grid grid-cols-1 md:grid-cols-3 gap-6">
          <div className="bg-surface-container border border-outline-variant/30 rounded-xl p-6 shadow-sm">
            <h3 className="text-on-surface-variant text-sm font-semibold uppercase tracking-wider mb-2">Today's Orders</h3>
            <p className="text-4xl font-display-lg font-bold text-primary">{analytics.todayOrders}</p>
          </div>
          
          <div className="bg-surface-container border border-outline-variant/30 rounded-xl p-6 shadow-sm">
            <h3 className="text-on-surface-variant text-sm font-semibold uppercase tracking-wider mb-2">Today's Revenue</h3>
            <p className="text-4xl font-display-lg font-bold text-green-400">₹{analytics.todayRevenue.toFixed(2)}</p>
          </div>
          
          <div className="bg-surface-container border border-outline-variant/30 rounded-xl p-6 shadow-sm">
            <h3 className="text-on-surface-variant text-sm font-semibold uppercase tracking-wider mb-2">Lifetime Revenue</h3>
            <p className="text-4xl font-display-lg font-bold text-tertiary">₹{analytics.totalRevenue.toFixed(2)}</p>
          </div>
        </div>
      )}
    </div>
  );
};

export default Analytics;
