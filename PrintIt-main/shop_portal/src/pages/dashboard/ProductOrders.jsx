import React, { useState, useEffect } from 'react';
import api from '../../core/api';

const ProductOrders = () => {
  const [orders, setOrders] = useState([]);
  const [loading, setLoading] = useState(true);
  const [activeTab, setActiveTab] = useState('confirmed');

  useEffect(() => {
    fetchOrders();
  }, []);

  const fetchOrders = async () => {
    try {
      const res = await api.get('/shop/product-orders?limit=500');
      setOrders(res.data.data || res.data);
    } catch (err) {
      console.error('Error fetching product orders', err);
    } finally {
      setLoading(false);
    }
  };

  const handleMarkCollected = async (id) => {
    try {
      await api.patch(`/shop/product-orders/${id}/collect`);
      fetchOrders();
    } catch (err) {
      console.error('Error marking as collected', err);
      alert('Failed to update order status');
    }
  };

  const filteredOrders = orders.filter(o => {
    if (activeTab === 'confirmed') return o.status === 'confirmed';
    if (activeTab === 'history') return o.status === 'collected' || o.status === 'cancelled';
    return true;
  });

  if (loading) return <div className="p-lg">Loading...</div>;

  return (
    <div className="p-lg max-w-[1152px] mx-auto h-full flex flex-col">
      <div className="flex justify-between items-center mb-md">
        <h1 className="font-display-sm text-display-sm text-on-surface">Product Orders</h1>
      </div>

      <div className="flex gap-4 border-b border-outline-variant/30 mb-lg">
        <button 
          onClick={() => setActiveTab('confirmed')}
          className={`pb-2 font-label-md transition-colors ${activeTab === 'confirmed' ? 'border-b-2 border-primary text-primary' : 'text-on-surface-variant hover:text-on-surface'}`}
        >
          Pending Pickup
        </button>
        <button 
          onClick={() => setActiveTab('history')}
          className={`pb-2 font-label-md transition-colors ${activeTab === 'history' ? 'border-b-2 border-primary text-primary' : 'text-on-surface-variant hover:text-on-surface'}`}
        >
          History
        </button>
      </div>

      <div className="flex-1 overflow-y-auto pr-2 flex flex-col gap-md">
        {filteredOrders.map(order => (
          <div key={order.order_id} className="bg-surface-container rounded-2xl p-md border border-outline-variant/30 flex flex-col sm:flex-row gap-md items-start sm:items-center">
            {order.cover_photo_url ? (
              <img src={order.cover_photo_url} alt="Cover" className="w-20 h-24 object-cover rounded-xl" />
            ) : (
              <div className="w-20 h-24 bg-surface-container-highest rounded-xl flex items-center justify-center">
                <span className="material-symbols-outlined opacity-30">book</span>
              </div>
            )}
            
            <div className="flex-1">
              <div className="flex items-center gap-2 mb-1">
                <span className="font-data-mono text-[12px] bg-secondary-container text-on-secondary-container px-2 py-0.5 rounded">#{order.order_id.substring(0, 8)}</span>
                <span className="font-label-md text-on-surface-variant text-[12px]">{new Date(order.created_at).toLocaleString()}</span>
              </div>
              <h3 className="font-title-lg font-bold">{order.title}</h3>
              <p className="text-on-surface-variant text-body-sm mt-1">
                <span className="font-semibold text-on-surface">Qty: {order.quantity}</span> • Total: ₹{order.amount_total}
              </p>
              <div className="mt-2 text-body-sm bg-surface-container-highest p-2 rounded-lg inline-block">
                <p><span className="text-on-surface-variant">Customer:</span> {order.customer_name || 'Guest'}</p>
                <p><span className="text-on-surface-variant">Phone:</span> {order.customer_phone || order.guest_phone || 'N/A'}</p>
              </div>
            </div>

            <div className="flex flex-col gap-2 min-w-[120px] shrink-0">
              <span className={`text-center font-label-sm px-3 py-1 rounded-full ${
                order.status === 'confirmed' ? 'bg-primary/20 text-primary' : 
                order.status === 'collected' ? 'bg-success/20 text-success' : 'bg-error/20 text-error'
              }`}>
                {order.status.toUpperCase()}
              </span>
              
              {order.status === 'confirmed' && (
                <button 
                  onClick={() => handleMarkCollected(order.order_id)}
                  className="bg-primary text-on-primary px-4 py-2 rounded-lg font-label-md w-full"
                >
                  Mark Collected
                </button>
              )}
            </div>
          </div>
        ))}

        {filteredOrders.length === 0 && (
          <div className="py-xl text-center text-on-surface-variant mt-10">
            <span className="material-symbols-outlined text-[48px] opacity-50 mb-4 block">receipt_long</span>
            <p>No orders found in this category.</p>
          </div>
        )}
      </div>
    </div>
  );
};

export default ProductOrders;
