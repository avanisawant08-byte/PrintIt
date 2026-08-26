import React, { useState, useEffect } from 'react';
import { useOutletContext } from 'react-router-dom';
import api from '../../core/api';

const Orders = () => {
  const { searchQuery } = useOutletContext() || { searchQuery: '' };
  const [orders, setOrders] = useState([]);
  const [pagination, setPagination] = useState({ page: 1, limit: 50, total_pages: 1 });
  const [isLoading, setIsLoading] = useState(true);

  const fetchOrders = async (page = 1) => {
    setIsLoading(true);
    try {
      const res = await api.get(`/shop/orders?page=${page}&limit=50`);
      setOrders(res.data.data || res.data);
      if (res.data.pagination) setPagination(res.data.pagination);
    } catch (err) {
      alert('Failed to load orders: ' + err.message);
    } finally {
      setIsLoading(false);
    }
  };

  useEffect(() => {
    fetchOrders(1);
  }, []);

  const filteredOrders = orders.filter(o => {
    if (!searchQuery || searchQuery.trim() === '') return true;
    const q = searchQuery.toLowerCase().trim();
    return (
      o.order_id.toLowerCase().includes(q) ||
      (o.customer_phone || '').toLowerCase().includes(q) ||
      (o.status || '').toLowerCase().includes(q)
    );
  });

  return (
    <div className="w-full h-full flex flex-col overflow-hidden bg-background">
      <div className="flex justify-between items-center mb-6 shrink-0">
        <div>
          <h1 className="text-2xl font-bold text-on-surface mb-1">Order History</h1>
          <p className="text-xs text-on-surface-variant">View and track historical print orders</p>
        </div>
        <div className="flex items-center gap-4">
          {pagination.total_pages > 1 && (
            <div className="flex items-center gap-2 text-xs">
              <button 
                onClick={() => fetchOrders(pagination.page - 1)} 
                disabled={pagination.page <= 1}
                className="px-3 py-1 bg-surface-container border border-outline-variant rounded text-on-surface disabled:opacity-50"
              >
                Prev
              </button>
              <span className="text-on-surface-variant">Page {pagination.page} of {pagination.total_pages}</span>
              <button 
                onClick={() => fetchOrders(pagination.page + 1)} 
                disabled={pagination.page >= pagination.total_pages}
                className="px-3 py-1 bg-surface-container border border-outline-variant rounded text-on-surface disabled:opacity-50"
              >
                Next
              </button>
            </div>
          )}
          <button 
            onClick={() => fetchOrders(pagination.page)} 
            className="bg-surface-container-high border border-outline-variant text-on-surface px-4 py-2 rounded-lg text-xs hover:border-primary transition-colors flex items-center gap-1.5"
          >
            <span className="material-symbols-outlined text-[16px]">refresh</span>
            Refresh
          </button>
        </div>
      </div>

      {isLoading ? (
        <div className="flex-1 flex items-center justify-center text-on-surface-variant">
          <div className="flex items-center gap-2">
            <span className="material-symbols-outlined text-primary text-2xl animate-spin">autorenew</span>
            <span>Loading Orders...</span>
          </div>
        </div>
      ) : filteredOrders.length === 0 ? (
        <div className="flex-1 flex items-center justify-center bg-surface-container border border-outline-variant rounded-xl text-on-surface-variant">
          No orders match your search or filter.
        </div>
      ) : (
        <div className="bg-surface-container border border-outline-variant rounded-xl overflow-x-auto">
          <table className="w-full text-left border-collapse font-body-sm text-sm">
            <thead>
              <tr className="bg-surface-container-low border-b border-outline-variant text-[0.75rem] uppercase tracking-wider text-on-surface-variant font-bold">
                <th className="p-4">Order ID</th>
                <th className="p-4">Type</th>
                <th className="p-4">Placed At</th>
                <th className="p-4">Status</th>
                <th className="p-4">Amount</th>
                <th className="p-4">Payment</th>
              </tr>
            </thead>
            <tbody>
              {filteredOrders.map(o => {
                let opts = {};
                try { opts = typeof o.print_options === 'string' ? JSON.parse(o.print_options) : (o.print_options || {}); } catch(e) {}
                const isScheduled = opts.pickup_type === 'scheduled' || o.order_id?.startsWith('S');

                return (
                  <tr key={o.order_id} className="border-b border-outline-variant/30 hover:bg-surface-bright/50 transition-colors">
                    <td className="p-4 font-mono font-semibold text-primary">#{o.order_id.split('-')[0]}</td>
                    <td className="p-4">
                      <span className={`px-2 py-1 rounded text-[0.7rem] font-bold ${
                        isScheduled ? 'bg-cyan-500/15 text-cyan-300 border border-cyan-500/30' : 'bg-amber-500/15 text-amber-300 border border-amber-500/30'
                      }`}>
                        {isScheduled ? '🗓️ Scheduled' : '⚡ Express'}
                      </span>
                    </td>
                    <td className="p-4 text-on-surface-variant">{new Date(o.created_at).toLocaleString()}</td>
                    <td className="p-4">
                      <span className={`px-2 py-1 rounded text-[0.7rem] font-bold uppercase ${
                        o.status === 'ready' ? 'bg-green-500/15 text-green-400' :
                        o.status === 'processing' ? 'bg-yellow-500/15 text-yellow-400' :
                        o.status === 'queued' ? 'bg-blue-500/15 text-blue-400' :
                        'bg-surface-container-highest text-on-surface-variant'
                      }`}>
                        {o.status}
                      </span>
                    </td>
                    <td className="p-4 font-bold text-on-surface">₹{o.amount_total}</td>
                    <td className="p-4">
                      <span className={`text-[11px] font-bold ${o.payment_status === 'captured' ? 'text-green-400' : 'text-amber-400'}`}>
                        {o.payment_status === 'captured' ? 'Paid' : 'Pending'}
                      </span>
                    </td>
                  </tr>
                );
              })}
            </tbody>
          </table>
        </div>
      )}
    </div>
  );
};

export default Orders;
