import React, { useState, useEffect } from 'react';
import api from '../../core/api';

const Orders = () => {
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

  return (
    <div className="p-4 md:p-8 h-full flex flex-col">
      <div className="flex justify-between items-center mb-6">
        <h1 className="text-2xl font-bold">Order History</h1>
        <div className="flex items-center gap-4">
          {pagination.total_pages > 1 && (
            <div className="flex items-center gap-2 text-sm">
              <button 
                onClick={() => fetchOrders(pagination.page - 1)} 
                disabled={pagination.page <= 1}
                className="px-3 py-1 bg-surface-container border border-outline-variant rounded disabled:opacity-50"
              >
                Prev
              </button>
              <span className="text-on-surface-variant">Page {pagination.page} of {pagination.total_pages}</span>
              <button 
                onClick={() => fetchOrders(pagination.page + 1)} 
                disabled={pagination.page >= pagination.total_pages}
                className="px-3 py-1 bg-surface-container border border-outline-variant rounded disabled:opacity-50"
              >
                Next
              </button>
            </div>
          )}
          <button onClick={() => fetchOrders(pagination.page)} className="bg-surface-container-highest border border-outline-variant text-on-surface px-4 py-2 rounded-lg text-sm hover:bg-surface-variant transition-colors">
            ↻ Refresh
          </button>
        </div>
      </div>

      {isLoading ? (
        <div className="flex-1 flex items-center justify-center text-on-surface-variant">Loading...</div>
      ) : orders.length === 0 ? (
        <div className="flex-1 flex items-center justify-center bg-surface-container/50 border border-outline-variant/30 rounded-xl text-on-surface-variant">
          No order history available.
        </div>
      ) : (
        <div className="bg-surface-container border border-outline-variant/30 rounded-xl overflow-x-auto">
          <table className="w-full text-left border-collapse">
            <thead>
              <tr className="bg-black/30 border-b border-outline-variant/30 text-[0.75rem] uppercase tracking-wider text-on-surface-variant">
                <th className="p-4">Order ID</th>
                <th className="p-4">Placed At</th>
                <th className="p-4">Status</th>
                <th className="p-4">Amount</th>
                <th className="p-4">Payment</th>
              </tr>
            </thead>
            <tbody>
              {orders.map(o => (
                <tr key={o.order_id} className="border-b border-outline-variant/10 hover:bg-surface-variant/30 transition-colors cursor-pointer">
                  <td className="p-4 font-data-mono font-semibold">#{o.order_id.split('-')[0]}</td>
                  <td className="p-4">{new Date(o.created_at).toLocaleString()}</td>
                  <td className="p-4">
                    <span className={`px-2 py-1 rounded text-[0.7rem] font-bold uppercase ${o.status === 'ready' ? 'bg-green-500/15 text-green-400' : o.status === 'processing' ? 'bg-yellow-500/15 text-yellow-400' : o.status === 'queued' ? 'bg-blue-500/15 text-blue-400' : 'bg-gray-500/15 text-gray-400'}`}>
                      {o.status}
                    </span>
                  </td>
                  <td className="p-4 font-bold text-accent">₹{o.amount_total}</td>
                  <td className="p-4">{o.payment_status === 'captured' ? 'Paid' : 'Pending'}</td>
                </tr>
              ))}
            </tbody>
          </table>
        </div>
      )}
    </div>
  );
};

export default Orders;
