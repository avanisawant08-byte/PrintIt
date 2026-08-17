import React, { useState, useEffect } from 'react';
import api from '../../core/api';
import OrderCard from '../../components/OrderCard';

const LiveQueue = () => {
  const [orders, setOrders] = useState([]);
  const [isLoading, setIsLoading] = useState(true);
  const [lastUpdated, setLastUpdated] = useState(new Date());

  const fetchOrders = async (showLoader = false) => {
    if (showLoader) setIsLoading(true);
    try {
      const res = await api.get('/shop/orders?limit=100');
      setOrders(res.data.data || res.data);
      setLastUpdated(new Date());
    } catch (err) {
      console.error('Failed to fetch orders:', err);
    } finally {
      if (showLoader) setIsLoading(false);
    }
  };

  useEffect(() => {
    fetchOrders(true);
    const interval = setInterval(() => fetchOrders(), 10000); // 10s poll
    return () => clearInterval(interval);
  }, []);

  const handleStatusUpdate = async (orderId, newStatus) => {
    try {
      await api.patch(`/shop/orders/${orderId}/status`, { status: newStatus });
      fetchOrders();
    } catch (err) {
      alert('Failed to update status: ' + err.message);
    }
  };

  const handlePrint = async (orderId, isDownload = false) => {
    // Port of the printing logic (using signed URL)
    try {
      if (isDownload) {
        // Fetch via backend proxy to avoid CORS
        const response = await api.get(`/shop/orders/${orderId}/files/0/proxy`, {
          responseType: 'blob'
        });
        
        const blob = new Blob([response.data]);
        const blobUrl = window.URL.createObjectURL(blob);
        const a = document.createElement('a');
        a.style.display = 'none';
        a.href = blobUrl;
        
        // Try to get original filename from content-disposition
        let filename = `print_order_${orderId.split('-')[0]}.pdf`;
        const contentDisposition = response.headers['content-disposition'];
        if (contentDisposition) {
          const match = contentDisposition.match(/filename="?([^"]+)"?/);
          if (match && match[1]) filename = match[1];
        }
        
        a.download = filename;
        document.body.appendChild(a);
        a.click();
        
        window.URL.revokeObjectURL(blobUrl);
        document.body.removeChild(a);
        return;
      }

      // Standard view/print flow
      const res = await api.get(`/shop/orders/${orderId}/files/0/download-url`);
      const url = res.data.download_url;
      const newWin = window.open(url, '_blank');
      if (!newWin) {
        alert('Popup blocked. Click ok to download directly.');
        window.location.href = url;
      }
    } catch (err) {
      alert('Print failed: ' + err.message);
    }
  };

  const queued = orders.filter(o => o.status === 'queued').sort((a,b) => (a.queue_position || 999) - (b.queue_position || 999));
  const processing = orders.filter(o => o.status === 'processing');
  const ready = orders.filter(o => o.status === 'ready');

  return (
    <div className="p-4 md:p-8 h-full flex flex-col">
      <div className="flex justify-between items-end mb-6">
        <div>
          <h1 className="text-2xl font-bold mb-1">Order Workflow</h1>
          <p className="text-sm text-on-surface-variant">Auto-refreshes every 10 seconds. Updated at {lastUpdated.toLocaleTimeString()}</p>
        </div>
        <button onClick={() => fetchOrders(true)} className="bg-surface-container-highest border border-outline-variant text-on-surface px-4 py-2 rounded-lg text-sm hover:bg-surface-variant transition-colors">
          ↻ Force Refresh
        </button>
      </div>

      {isLoading ? (
        <div className="flex-1 flex items-center justify-center text-on-surface-variant">
          Loading Queue...
        </div>
      ) : (
        <div className="flex-1 flex flex-col md:flex-row gap-6 overflow-x-auto pb-6">
          {/* Queued */}
          <div className="flex-1 min-w-[340px] max-w-[450px] bg-black/15 border border-outline-variant/50 rounded-xl p-5 flex flex-col gap-4">
            <div className="flex justify-between items-center pb-4 border-b border-dashed border-outline-variant/50">
              <h2 className="text-blue-500 font-semibold text-lg flex items-center gap-2">New Orders <span className="bg-white/10 px-2 py-0.5 rounded-full text-sm">{queued.length}</span></h2>
            </div>
            <div className="flex flex-col gap-4 overflow-y-auto pr-2 custom-scrollbar">
              {queued.length === 0 ? <p className="text-center text-on-surface-variant text-sm py-8">No new orders</p> : 
               queued.map(o => <OrderCard key={o.order_id} order={o} colType="queued" onStatusUpdate={handleStatusUpdate} onPrint={handlePrint} onOpenModal={()=>{}} />)}
            </div>
          </div>
          
          {/* Processing */}
          <div className="flex-1 min-w-[340px] max-w-[450px] bg-black/15 border border-outline-variant/50 rounded-xl p-5 flex flex-col gap-4">
            <div className="flex justify-between items-center pb-4 border-b border-dashed border-outline-variant/50">
              <h2 className="text-yellow-500 font-semibold text-lg flex items-center gap-2">Processing <span className="bg-white/10 px-2 py-0.5 rounded-full text-sm">{processing.length}</span></h2>
            </div>
            <div className="flex flex-col gap-4 overflow-y-auto pr-2 custom-scrollbar">
              {processing.length === 0 ? <p className="text-center text-on-surface-variant text-sm py-8">No active processing</p> : 
               processing.map(o => <OrderCard key={o.order_id} order={o} colType="processing" onStatusUpdate={handleStatusUpdate} onPrint={handlePrint} onOpenModal={()=>{}} />)}
            </div>
          </div>

          {/* Ready */}
          <div className="flex-1 min-w-[340px] max-w-[450px] bg-black/15 border border-outline-variant/50 rounded-xl p-5 flex flex-col gap-4">
            <div className="flex justify-between items-center pb-4 border-b border-dashed border-outline-variant/50">
              <h2 className="text-green-500 font-semibold text-lg flex items-center gap-2">Ready for Pickup <span className="bg-white/10 px-2 py-0.5 rounded-full text-sm">{ready.length}</span></h2>
            </div>
            <div className="flex flex-col gap-4 overflow-y-auto pr-2 custom-scrollbar">
              {ready.length === 0 ? <p className="text-center text-on-surface-variant text-sm py-8">No orders ready</p> : 
               ready.map(o => <OrderCard key={o.order_id} order={o} colType="ready" onStatusUpdate={handleStatusUpdate} onPrint={handlePrint} onOpenModal={()=>{}} />)}
            </div>
          </div>
        </div>
      )}
    </div>
  );
};

export default LiveQueue;
