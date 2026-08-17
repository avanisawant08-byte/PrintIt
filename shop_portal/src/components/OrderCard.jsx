import React from 'react';
import api from '../core/api';

const OrderCard = ({ order, colType, onStatusUpdate, onPrint, onOpenModal }) => {
  const shortId = order.order_id.split('-')[0];
  
  let files = [];
  try {
    const raw = typeof order.files === 'string' ? JSON.parse(order.files) : (order.files || []);
    files = raw.map(entry => {
      if (!entry) return null;
      if (entry.file_info && typeof entry.file_info === 'object') {
        return { ...entry.file_info, print_options: entry.print_options, print_instructions: entry.print_instructions };
      }
      return entry;
    }).filter(e => e !== null);
  } catch(e) {}

  let opts = {};
  try {
    opts = typeof order.print_options === 'string' ? JSON.parse(order.print_options) : (order.print_options || {});
  } catch(e) {}
  if (Object.keys(opts).length === 0 && files.length > 0 && files[0].print_options) {
    try {
      opts = typeof files[0].print_options === 'string' ? JSON.parse(files[0].print_options) : files[0].print_options;
    } catch(e) {}
  }

  const phoneStr = order.customer_phone || 'N/A';
  const pickupTypeStr = opts.pickup_type === 'scheduled' ? '🗓️ Scheduled' : '⚡ Express';
  let pickupTimeStr = 'ASAP';
  if (opts.pickup_type === 'scheduled' && opts.pickup_time) {
    const pt = new Date(opts.pickup_time);
    pickupTimeStr = pt.toLocaleDateString([], { month: 'short', day: 'numeric' }) + ' ' + pt.toLocaleTimeString([], {hour: '2-digit', minute:'2-digit'});
  }

  const handleAction = async (status, e) => {
    e.stopPropagation();
    if (status === 'processing') {
      // First download/print, then mark processing
      onPrint(order.order_id, true);
    }
    onStatusUpdate(order.order_id, status);
  };

  return (
    <div 
      className="bg-surface-container/80 backdrop-blur-md border border-outline-variant/30 rounded-xl p-4 transition-all hover:-translate-y-1 hover:shadow-xl hover:border-outline-variant cursor-pointer flex flex-col gap-4"
      onClick={() => onOpenModal(order)}
    >
      <div className="flex justify-between items-start">
        <div>
          <div className="font-data-mono text-[1.1rem] font-bold tracking-wider">#{shortId}</div>
          {order.queue_position && colType === 'queued' && (
            <span className="text-[0.75rem] text-on-surface-variant bg-black/30 px-2 py-0.5 rounded">Pos {order.queue_position}</span>
          )}
        </div>
        <div className="font-bold text-accent text-lg">₹{order.amount_total}</div>
      </div>
      
      <div className="grid grid-cols-2 gap-3 bg-black/20 p-3 rounded-lg">
        <div className="flex flex-col"><span className="text-[0.7rem] text-on-surface-variant uppercase tracking-wider mb-0.5">Color</span><span className="text-sm font-medium">{opts.color === 'color' ? '🎨 Full Color' : '⬛ B&W'}</span></div>
        <div className="flex flex-col"><span className="text-[0.7rem] text-on-surface-variant uppercase tracking-wider mb-0.5">Config</span><span className="text-sm font-medium">{opts.size || 'A4'} • {opts.sides || 'Single'}</span></div>
        <div className="flex flex-col"><span className="text-[0.7rem] text-on-surface-variant uppercase tracking-wider mb-0.5">Copies</span><span className="text-sm font-medium">{opts.copies || 1}</span></div>
        <div className="flex flex-col"><span className="text-[0.7rem] text-on-surface-variant uppercase tracking-wider mb-0.5">Binding</span><span className="text-sm font-medium">{opts.binding || 'None'}</span></div>
        <div className="flex flex-col"><span className="text-[0.7rem] text-on-surface-variant uppercase tracking-wider mb-0.5">Phone</span><span className="text-sm font-medium">📞 {phoneStr}</span></div>
        <div className="flex flex-col"><span className="text-[0.7rem] text-on-surface-variant uppercase tracking-wider mb-0.5">Pickup</span><span className="text-sm font-medium">{pickupTypeStr}</span></div>
        <div className="flex flex-col col-span-2"><span className="text-[0.7rem] text-on-surface-variant uppercase tracking-wider mb-0.5">Pickup Time</span><span className="text-sm font-medium">⏰ {pickupTimeStr}</span></div>
      </div>

      {order.print_instructions && (
        <div className="mt-2 p-2 bg-yellow-500/10 border-l-2 border-yellow-500 text-yellow-400 text-xs italic">
          💬 {order.print_instructions}
        </div>
      )}

      <div className="flex justify-between items-center">
        <button 
          onClick={(e) => { e.stopPropagation(); onPrint(order.order_id); }}
          className="bg-green-500/15 text-green-400 px-3 py-1.5 rounded-lg text-sm font-medium hover:bg-green-500/25 transition-colors"
        >
          🖨️ Print
        </button>
        {order.payment_status === 'captured' 
          ? <span className="bg-green-500/15 text-green-400 border border-green-500/30 px-2 py-1 rounded text-[0.65rem] font-bold uppercase tracking-wider">Paid</span>
          : <span className="bg-yellow-500/15 text-yellow-400 border border-yellow-500/30 px-2 py-1 rounded text-[0.65rem] font-bold uppercase tracking-wider">Unpaid</span>
        }
      </div>

      <div className="flex gap-2 mt-2">
        {colType === 'queued' && (
          <>
            <button onClick={(e) => handleAction('processing', e)} className="flex-1 bg-yellow-500/15 text-yellow-400 border border-yellow-500/30 p-2 rounded-lg font-semibold text-sm hover:bg-yellow-500/25 hover:-translate-y-px transition-all">⚙️ Accept & DL</button>
            <button onClick={(e) => handleAction('cancelled', e)} className="flex-[0.4] bg-red-500/10 text-red-400 border border-red-500/20 p-2 rounded-lg font-semibold text-sm hover:bg-red-500/20 transition-colors">✕</button>
          </>
        )}
        {colType === 'processing' && (
          <button onClick={(e) => handleAction('ready', e)} className="flex-1 bg-green-500/15 text-green-400 border border-green-500/30 p-2 rounded-lg font-semibold text-sm hover:bg-green-500/25 hover:-translate-y-px transition-all">📦 Mark as Ready</button>
        )}
        {colType === 'ready' && (
          <button onClick={(e) => handleAction('collected', e)} className="flex-1 bg-white/10 text-white p-2 rounded-lg font-semibold text-sm hover:bg-white/20 transition-colors">✓ Handed to Customer</button>
        )}
      </div>
    </div>
  );
};

export default OrderCard;
