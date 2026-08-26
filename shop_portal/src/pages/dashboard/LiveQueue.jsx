import React, { useState, useEffect } from 'react';
import { useOutletContext } from 'react-router-dom';
import api from '../../core/api';
import OrderCard from '../../components/OrderCard';
import OrderDetailModal from '../../components/OrderDetailModal';

const getPickupType = (order) => {
  if (!order) return 'express';
  let opts = {};
  try {
    opts = typeof order.print_options === 'string' ? JSON.parse(order.print_options) : (order.print_options || {});
  } catch(e) {}
  if (!opts.pickup_type && order.files) {
    try {
      const files = typeof order.files === 'string' ? JSON.parse(order.files) : order.files;
      if (Array.isArray(files) && files[0]?.print_options) {
        const fileOpts = typeof files[0].print_options === 'string' ? JSON.parse(files[0].print_options) : files[0].print_options;
        if (fileOpts.pickup_type) opts.pickup_type = fileOpts.pickup_type;
      }
    } catch(e) {}
  }
  if (opts.pickup_type === 'scheduled' || order.order_id?.startsWith('S')) {
    return 'scheduled';
  }
  return 'express';
};

const LiveQueue = () => {
  const { searchQuery } = useOutletContext() || { searchQuery: '' };
  const [orders, setOrders] = useState([]);
  const [isLoading, setIsLoading] = useState(true);
  const [lastUpdated, setLastUpdated] = useState(new Date());
  const [activeTab, setActiveTab] = useState('all'); // 'express' | 'scheduled' | 'all'
  const [selectedOrder, setSelectedOrder] = useState(null);
  const [showFilterMenu, setShowFilterMenu] = useState(false);
  const [colorFilter, setColorFilter] = useState('all'); // 'all' | 'bw' | 'color'

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
    try {
      if (isDownload) {
        const response = await api.get(`/shop/orders/${orderId}/files/0/proxy`, {
          responseType: 'blob'
        });
        
        const blob = new Blob([response.data]);
        const blobUrl = window.URL.createObjectURL(blob);
        const a = document.createElement('a');
        a.style.display = 'none';
        a.href = blobUrl;
        
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

  // Filter orders by search, tabs, and color options
  const filteredOrders = orders.filter(order => {
    // Search Filter
    if (searchQuery && searchQuery.trim() !== '') {
      const q = searchQuery.toLowerCase().trim();
      const orderIdMatch = order.order_id.toLowerCase().includes(q);
      const phoneMatch = (order.customer_phone || '').toLowerCase().includes(q);
      const statusMatch = (order.status || '').toLowerCase().includes(q);
      if (!orderIdMatch && !phoneMatch && !statusMatch) return false;
    }

    // Tab filter
    const pickupType = getPickupType(order);
    if (activeTab === 'express' && pickupType !== 'express') return false;
    if (activeTab === 'scheduled' && pickupType !== 'scheduled') return false;

    // Color filter
    if (colorFilter !== 'all') {
      let opts = {};
      try {
        opts = typeof order.print_options === 'string' ? JSON.parse(order.print_options) : (order.print_options || {});
      } catch(e) {}
      if (colorFilter === 'color' && opts.color !== 'color') return false;
      if (colorFilter === 'bw' && opts.color === 'color') return false;
    }

    return true;
  });

  const sortOrders = (list) => {
    return [...list].sort((a, b) => {
      if (activeTab === 'scheduled') {
        let optsA = {}, optsB = {};
        try { optsA = typeof a.print_options === 'string' ? JSON.parse(a.print_options) : (a.print_options || {}); } catch(e) {}
        try { optsB = typeof b.print_options === 'string' ? JSON.parse(b.print_options) : (b.print_options || {}); } catch(e) {}
        const timeA = optsA.pickup_time ? new Date(optsA.pickup_time).getTime() : new Date(a.created_at).getTime();
        const timeB = optsB.pickup_time ? new Date(optsB.pickup_time).getTime() : new Date(b.created_at).getTime();
        return timeA - timeB;
      }
      return (a.queue_position || 999) - (b.queue_position || 999);
    });
  };

  const queued = sortOrders(filteredOrders.filter(o => o.status === 'queued'));
  const processing = sortOrders(filteredOrders.filter(o => o.status === 'processing'));
  const ready = sortOrders(filteredOrders.filter(o => o.status === 'ready'));

  return (
    <div className="w-full h-full flex flex-col overflow-hidden bg-background relative z-0">
      {/* Page Header */}
      <div className="flex flex-col md:flex-row justify-between md:items-end mb-6 shrink-0 gap-4">
        <div>
          <h2 className="font-display-lg text-display-lg text-on-surface mb-2 font-extrabold text-3xl md:text-4xl">Order Workflow</h2>
          <p className="font-body-sm text-body-sm text-on-surface-variant">Manage incoming and processing print jobs.</p>
        </div>

        <div className="flex flex-wrap items-center gap-3">
          {/* Quick Tab Filters */}
          <div className="flex items-center gap-1 p-1 bg-surface-container-high border border-outline-variant rounded-lg">
            <button
              onClick={() => setActiveTab('all')}
              className={`px-3 py-1.5 rounded font-label-md text-xs font-semibold transition-all ${
                activeTab === 'all'
                  ? 'bg-primary-container text-on-primary-container font-bold shadow'
                  : 'text-on-surface-variant hover:text-on-surface'
              }`}
            >
              All
            </button>

            <button
              onClick={() => setActiveTab('express')}
              className={`px-3 py-1.5 rounded font-label-md text-xs font-semibold transition-all ${
                activeTab === 'express'
                  ? 'bg-primary-container text-on-primary-container font-bold shadow'
                  : 'text-on-surface-variant hover:text-on-surface'
              }`}
            >
              ⚡ Express
            </button>

            <button
              onClick={() => setActiveTab('scheduled')}
              className={`px-3 py-1.5 rounded font-label-md text-xs font-semibold transition-all ${
                activeTab === 'scheduled'
                  ? 'bg-primary-container text-on-primary-container font-bold shadow'
                  : 'text-on-surface-variant hover:text-on-surface'
              }`}
            >
              🗓️ Scheduled
            </button>
          </div>

          {/* Filter Dropdown */}
          <div className="relative">
            <button 
              onClick={() => setShowFilterMenu(!showFilterMenu)}
              className={`flex items-center gap-2 px-4 py-2 bg-surface-container-high border border-outline-variant rounded-lg font-label-md text-label-md text-on-surface hover:border-primary transition-colors ${colorFilter !== 'all' ? 'border-primary text-primary' : ''}`}
            >
              <span className="material-symbols-outlined text-[18px]">filter_list</span>
              Filter {colorFilter !== 'all' ? `(${colorFilter.toUpperCase()})` : ''}
            </button>

            {showFilterMenu && (
              <div className="absolute right-0 mt-2 w-48 bg-surface-container-high border border-outline-variant rounded-xl shadow-xl p-2 z-30">
                <span className="block px-3 py-1 text-[10px] font-bold text-outline uppercase tracking-wider">Color Filter</span>
                <button
                  onClick={() => { setColorFilter('all'); setShowFilterMenu(false); }}
                  className={`w-full text-left px-3 py-1.5 text-xs rounded hover:bg-surface-variant ${colorFilter === 'all' ? 'text-primary font-bold' : 'text-on-surface'}`}
                >
                  All Colors
                </button>
                <button
                  onClick={() => { setColorFilter('bw'); setShowFilterMenu(false); }}
                  className={`w-full text-left px-3 py-1.5 text-xs rounded hover:bg-surface-variant ${colorFilter === 'bw' ? 'text-primary font-bold' : 'text-on-surface'}`}
                >
                  Black & White
                </button>
                <button
                  onClick={() => { setColorFilter('color'); setShowFilterMenu(false); }}
                  className={`w-full text-left px-3 py-1.5 text-xs rounded hover:bg-surface-variant ${colorFilter === 'color' ? 'text-primary font-bold' : 'text-on-surface'}`}
                >
                  Full Color
                </button>
              </div>
            )}
          </div>

          {/* Refresh Button */}
          <button
            onClick={() => fetchOrders(true)}
            className="p-2 bg-surface-container-high border border-outline-variant rounded-lg text-on-surface hover:border-primary transition-colors flex items-center justify-center"
            title="Refresh Orders"
          >
            <span className="material-symbols-outlined text-[18px]">refresh</span>
          </button>

          {/* Queue Live Indicator */}
          <div className="px-4 py-2 bg-surface-container-high border border-outline-variant rounded-lg font-label-md text-label-md text-on-surface flex items-center gap-2">
            <span className="w-2 h-2 rounded-full bg-primary animate-pulse"></span>
            Queue Live
          </div>
        </div>
      </div>

      {isLoading ? (
        <div className="flex-1 flex items-center justify-center text-on-surface-variant">
          <div className="flex flex-col items-center gap-2">
            <span className="material-symbols-outlined text-primary text-3xl animate-spin">autorenew</span>
            <span className="font-body-sm text-sm">Loading Order Workflow...</span>
          </div>
        </div>
      ) : (
        /* Kanban Board Area */
        <div className="flex-1 grid grid-cols-1 md:grid-cols-3 gap-gutter overflow-hidden pb-2">
          {/* Column 1: New Orders */}
          <div className="flex flex-col bg-surface-container rounded-xl border border-outline-variant shadow-[inset_0_0_20px_rgba(13,28,45,0.5)] overflow-hidden">
            {/* Column Header */}
            <div className="p-4 border-b border-outline-variant bg-surface-container-low flex justify-between items-center shrink-0">
              <div className="flex items-center gap-2">
                <span className="material-symbols-outlined text-primary">inbox</span>
                <h3 className="font-title-md text-title-md text-on-surface font-semibold text-base">New Orders</h3>
              </div>
              <span className="bg-primary/20 text-primary font-label-md text-label-md px-2 py-1 rounded-full border border-primary/30">
                {queued.length}
              </span>
            </div>

            {/* Column Content */}
            <div className="flex-1 p-4 overflow-y-auto kanban-col flex flex-col gap-4">
              {queued.length === 0 ? (
                <div className="flex-1 flex flex-col items-center justify-center text-center opacity-60 py-12">
                  <div className="w-16 h-16 rounded-full bg-surface-container-highest flex items-center justify-center mb-4 border border-outline-variant">
                    <span className="material-symbols-outlined text-[32px] text-outline">inbox</span>
                  </div>
                  <p className="font-body-sm text-body-sm text-on-surface-variant max-w-[200px]">
                    No new orders in this queue
                  </p>
                </div>
              ) : (
                queued.map(order => (
                  <OrderCard
                    key={order.order_id}
                    order={order}
                    colType="queued"
                    onStatusUpdate={handleStatusUpdate}
                    onPrint={handlePrint}
                    onOpenModal={setSelectedOrder}
                  />
                ))
              )}
            </div>
          </div>

          {/* Column 2: Processing */}
          <div className="flex flex-col bg-surface-container rounded-xl border border-outline-variant shadow-[inset_0_0_20px_rgba(13,28,45,0.5)] overflow-hidden">
            {/* Column Header */}
            <div className="p-4 border-b border-outline-variant bg-surface-container-low flex justify-between items-center shrink-0">
              <div className="flex items-center gap-2">
                <span className="material-symbols-outlined text-outline">autorenew</span>
                <h3 className="font-title-md text-title-md text-on-surface font-semibold text-base">Processing</h3>
              </div>
              <span className="bg-surface-container-highest text-on-surface-variant font-label-md text-label-md px-2 py-1 rounded-full border border-outline-variant">
                {processing.length}
              </span>
            </div>

            {/* Column Content */}
            <div className="flex-1 p-4 overflow-y-auto kanban-col flex flex-col gap-4">
              {processing.length === 0 ? (
                <div className="flex-1 p-4 kanban-col flex flex-col items-center justify-center text-center opacity-60">
                  <div className="w-16 h-16 rounded-full bg-surface-container-highest flex items-center justify-center mb-4 border border-outline-variant">
                    <span className="material-symbols-outlined text-[32px] text-outline">print_disabled</span>
                  </div>
                  <p className="font-body-sm text-body-sm text-on-surface-variant max-w-[200px]">
                    No active processing in this queue
                  </p>
                </div>
              ) : (
                processing.map(order => (
                  <OrderCard
                    key={order.order_id}
                    order={order}
                    colType="processing"
                    onStatusUpdate={handleStatusUpdate}
                    onPrint={handlePrint}
                    onOpenModal={setSelectedOrder}
                  />
                ))
              )}
            </div>
          </div>

          {/* Column 3: Ready for Pickup */}
          <div className="flex flex-col bg-surface-container rounded-xl border border-outline-variant shadow-[inset_0_0_20px_rgba(13,28,45,0.5)] overflow-hidden">
            {/* Column Header */}
            <div className="p-4 border-b border-outline-variant bg-surface-container-low flex justify-between items-center shrink-0">
              <div className="flex items-center gap-2">
                <span className="material-symbols-outlined text-outline">inventory</span>
                <h3 className="font-title-md text-title-md text-on-surface font-semibold text-base">Ready for Pickup</h3>
              </div>
              <span className="bg-surface-container-highest text-on-surface-variant font-label-md text-label-md px-2 py-1 rounded-full border border-outline-variant">
                {ready.length}
              </span>
            </div>

            {/* Column Content */}
            <div className="flex-1 p-4 overflow-y-auto kanban-col flex flex-col gap-4">
              {ready.length === 0 ? (
                <div className="flex-1 p-4 kanban-col flex flex-col items-center justify-center text-center opacity-60">
                  <div className="w-16 h-16 rounded-full bg-surface-container-highest flex items-center justify-center mb-4 border border-outline-variant">
                    <span className="material-symbols-outlined text-[32px] text-outline">check_box_outline_blank</span>
                  </div>
                  <p className="font-body-sm text-body-sm text-on-surface-variant max-w-[200px]">
                    No orders ready in this queue
                  </p>
                </div>
              ) : (
                ready.map(order => (
                  <OrderCard
                    key={order.order_id}
                    order={order}
                    colType="ready"
                    onStatusUpdate={handleStatusUpdate}
                    onPrint={handlePrint}
                    onOpenModal={setSelectedOrder}
                  />
                ))
              )}
            </div>
          </div>
        </div>
      )}

      {/* Detail Modal */}
      {selectedOrder && (
        <OrderDetailModal
          order={selectedOrder}
          onClose={() => setSelectedOrder(null)}
          onStatusUpdate={handleStatusUpdate}
          onPrint={handlePrint}
        />
      )}
    </div>
  );
};

export default LiveQueue;
