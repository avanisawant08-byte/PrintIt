import React from 'react';

const OrderDetailModal = ({ order, onClose, onStatusUpdate, onPrint }) => {
  if (!order) return null;

  const shortId = order.order_id.split('-')[0];
  
  let files = [];
  try {
    const raw = typeof order.files === 'string' ? JSON.parse(order.files) : (order.files || []);
    files = raw.map(entry => {
      if (!entry) return null;
      if (entry.file_info && typeof entry.file_info === 'object') {
        return { 
          name: entry.file_info.original_name || entry.file_info.name || 'Document.pdf',
          size: entry.file_info.size,
          pages: entry.file_info.pages || 1,
          print_options: entry.print_options,
          print_instructions: entry.print_instructions
        };
      }
      return {
        name: entry.original_name || entry.name || 'Document.pdf',
        pages: entry.pages || 1,
        print_options: entry.print_options,
        print_instructions: entry.print_instructions
      };
    }).filter(Boolean);
  } catch(e) {}

  let opts = {};
  try {
    opts = typeof order.print_options === 'string' ? JSON.parse(order.print_options) : (order.print_options || {});
  } catch(e) {}

  const isScheduled = opts.pickup_type === 'scheduled' || order.order_id?.startsWith('S');
  let pickupTimeStr = 'ASAP Pickup';
  if (isScheduled && opts.pickup_time) {
    const pt = new Date(opts.pickup_time);
    pickupTimeStr = pt.toLocaleDateString([], { month: 'short', day: 'numeric', year: 'numeric' }) + ' at ' + pt.toLocaleTimeString([], { hour: '2-digit', minute: '2-digit' });
  }

  // Circular progress calculations
  const getProgressOffset = () => {
    if (order.status === 'queued') return 188;
    if (order.status === 'processing') return 96;
    if (order.status === 'ready' || order.status === 'collected') return 0;
    return 283;
  };

  return (
    <div className="fixed inset-0 z-50 flex items-center justify-center p-4 bg-black/75 backdrop-blur-sm animate-fade-in">
      <div 
        className="bg-surface-container border border-outline-variant rounded-2xl w-full max-w-2xl max-h-[90vh] flex flex-col shadow-[0_0_32px_rgba(56,189,248,0.15)] overflow-hidden"
        onClick={(e) => e.stopPropagation()}
      >
        {/* Header */}
        <div className="p-6 border-b border-outline-variant bg-surface-container-low flex justify-between items-center shrink-0">
          <div>
            <div className="flex items-center gap-3">
              <h3 className="font-display-lg text-2xl font-bold text-primary">#{shortId}</h3>
              <span className={`px-2.5 py-0.5 rounded-full text-xs font-bold uppercase tracking-wide border ${
                order.status === 'queued' ? 'bg-primary/20 text-primary border-primary/30' :
                order.status === 'processing' ? 'bg-yellow-500/20 text-yellow-300 border-yellow-500/30' :
                order.status === 'ready' ? 'bg-green-500/20 text-green-300 border-green-500/30' :
                'bg-surface-container-highest text-on-surface-variant border-outline-variant'
              }`}>
                {order.status}
              </span>
              {order.queue_position && order.status === 'queued' && (
                <span className="bg-surface-bright border border-outline-variant px-2.5 py-0.5 rounded text-xs font-mono text-on-surface-variant">
                  Queue Pos #{order.queue_position}
                </span>
              )}
            </div>
            <p className="text-xs text-on-surface-variant mt-1">
              Placed on {new Date(order.created_at).toLocaleString()}
            </p>
          </div>

          <button 
            onClick={onClose}
            className="w-9 h-9 rounded-full bg-surface-bright border border-outline-variant text-on-surface-variant hover:text-on-surface flex items-center justify-center transition-colors cursor-pointer"
          >
            <span className="material-symbols-outlined text-[20px]">close</span>
          </button>
        </div>

        {/* Content */}
        <div className="p-6 overflow-y-auto kanban-col flex flex-col gap-6">
          {/* Quick Stats Grid */}
          <div className="grid grid-cols-2 sm:grid-cols-4 gap-4">
            <div className="bg-surface-bright p-3.5 rounded-xl border border-outline-variant">
              <span className="block text-[10px] uppercase font-bold text-outline tracking-wider mb-1">Total Price</span>
              <span className="text-xl font-bold text-on-surface font-mono">₹{order.amount_total}</span>
              <span className={`block text-[10px] font-semibold mt-0.5 ${order.payment_status === 'captured' ? 'text-green-400' : 'text-amber-400'}`}>
                {order.payment_status === 'captured' ? '✓ Payment Captured' : '⌛ Pending Payment'}
              </span>
            </div>

            <div className="bg-surface-bright p-3.5 rounded-xl border border-outline-variant">
              <span className="block text-[10px] uppercase font-bold text-outline tracking-wider mb-1">Color Mode</span>
              <span className="text-sm font-semibold text-on-surface">
                {opts.color === 'color' ? '🎨 Full Color' : '⬛ Black & White'}
              </span>
              <span className="block text-[10px] text-on-surface-variant mt-0.5">
                {opts.sides === 'double' ? 'Double Sided' : 'Single Sided'}
              </span>
            </div>

            <div className="bg-surface-bright p-3.5 rounded-xl border border-outline-variant">
              <span className="block text-[10px] uppercase font-bold text-outline tracking-wider mb-1">Paper & Copies</span>
              <span className="text-sm font-semibold text-on-surface">
                {opts.size || 'A4'} • {opts.copies || 1} {opts.copies > 1 ? 'copies' : 'copy'}
              </span>
              <span className="block text-[10px] text-on-surface-variant mt-0.5">
                Binding: {opts.binding || 'None'}
              </span>
            </div>

            <div className="bg-surface-bright p-3.5 rounded-xl border border-outline-variant">
              <span className="block text-[10px] uppercase font-bold text-outline tracking-wider mb-1">Customer Phone</span>
              <span className="text-sm font-semibold text-on-surface flex items-center gap-1 font-mono">
                <span className="material-symbols-outlined text-[14px] text-primary">call</span>
                {order.customer_phone || 'N/A'}
              </span>
              <span className="block text-[10px] text-on-surface-variant mt-0.5">Direct contact</span>
            </div>
          </div>

          {/* Stitch Project 3 Progress Ring & Live Tracking */}
          <div className="grid grid-cols-1 sm:grid-cols-2 gap-6 items-center">
            {/* Circular Progress Indicator */}
            <div className="relative flex flex-col items-center justify-center p-6 bg-surface-bright/50 rounded-xl border border-outline-variant">
              <div className="absolute inset-0 flex items-center justify-center animate-pulse-glow">
                <div className="w-36 h-36 rounded-full bg-primary-container/10 blur-2xl"></div>
              </div>
              <div className="relative w-40 h-40 flex items-center justify-center glass-panel rounded-full border-2 border-primary-container/20">
                <svg className="absolute inset-0 w-full h-full" viewBox="0 0 100 100">
                  <circle className="text-glass-border" cx="50" cy="50" fill="none" r="45" stroke="currentColor" strokeWidth="2"></circle>
                  <circle
                    className="text-primary-container progress-ring-circle"
                    cx="50"
                    cy="50"
                    fill="none"
                    r="45"
                    stroke="currentColor"
                    strokeDasharray="283"
                    strokeDashoffset={getProgressOffset()}
                    strokeWidth="3"
                  ></circle>
                </svg>
                <div className="text-center z-10">
                  <p className="text-[10px] font-label-sm uppercase text-on-surface-variant font-bold">Queue Pos</p>
                  <p className="text-3xl font-extrabold text-primary-container drop-shadow-[0_0_12px_rgba(0,229,255,0.6)] font-mono">
                    #{order.queue_position || '1'}
                  </p>
                  <p className="text-xs font-label-md text-on-surface mt-0.5">~ 4 mins left</p>
                </div>
              </div>
            </div>

            {/* Status Timeline */}
            <div className="glass-panel p-5 rounded-xl border border-outline-variant space-y-4">
              <h4 className="text-xs font-bold uppercase tracking-wider text-outline">Order Live Timeline</h4>
              <div className="relative space-y-5">
                <div className="absolute left-3.5 top-2 bottom-2 w-0.5 bg-glass-border"></div>

                {/* Step 1 */}
                <div className="flex items-start gap-3">
                  <div className={`relative z-10 flex items-center justify-center w-7 h-7 rounded-full text-xs ${order.status !== 'cancelled' ? 'bg-primary-container text-on-primary-container font-bold' : 'bg-surface-container border text-on-surface-variant'}`}>
                    <span className="material-symbols-outlined text-[16px]">check</span>
                  </div>
                  <div>
                    <p className="text-xs font-bold text-on-surface">Queued</p>
                    <p className="text-[10px] text-on-surface-variant">Order placed {new Date(order.created_at).toLocaleTimeString()}</p>
                  </div>
                </div>

                {/* Step 2 */}
                <div className="flex items-start gap-3">
                  <div className={`relative z-10 flex items-center justify-center w-7 h-7 rounded-full text-xs ${['processing', 'ready', 'collected'].includes(order.status) ? 'bg-primary-container text-on-primary-container shadow-[0_0_15px_rgba(0,229,255,0.4)] font-bold' : 'bg-surface-container border text-on-surface-variant'}`}>
                    <span className={`material-symbols-outlined text-[16px] ${order.status === 'processing' ? 'animate-spin' : ''}`}>sync</span>
                  </div>
                  <div>
                    <p className={`text-xs font-bold ${order.status === 'processing' ? 'text-primary' : 'text-on-surface'}`}>Processing</p>
                    <p className="text-[10px] text-on-surface-variant">Preparing document files for print</p>
                  </div>
                </div>

                {/* Step 3 */}
                <div className="flex items-start gap-3">
                  <div className={`relative z-10 flex items-center justify-center w-7 h-7 rounded-full text-xs ${['ready', 'collected'].includes(order.status) ? 'bg-primary-container text-on-primary-container font-bold' : 'bg-surface-container border text-on-surface-variant'}`}>
                    <span className="material-symbols-outlined text-[16px]">qr_code_2</span>
                  </div>
                  <div>
                    <p className={`text-xs font-bold ${order.status === 'ready' ? 'text-primary' : 'text-on-surface'}`}>Ready for Pickup</p>
                    <p className="text-[10px] text-on-surface-variant">Customer notified for collection</p>
                  </div>
                </div>

                {/* Step 4 */}
                <div className="flex items-start gap-3">
                  <div className={`relative z-10 flex items-center justify-center w-7 h-7 rounded-full text-xs ${order.status === 'collected' ? 'bg-emerald-500 text-white font-bold' : 'bg-surface-container border text-on-surface-variant'}`}>
                    <span className="material-symbols-outlined text-[16px]">done_all</span>
                  </div>
                  <div>
                    <p className={`text-xs font-bold ${order.status === 'collected' ? 'text-emerald-400' : 'text-on-surface'}`}>Handed to Customer</p>
                    <p className="text-[10px] text-on-surface-variant">Transaction completed</p>
                  </div>
                </div>
              </div>
            </div>
          </div>

          {/* Pickup Details Banner */}
          <div className="bg-surface-container-high border border-outline-variant p-4 rounded-xl flex items-start gap-3">
            <span className="material-symbols-outlined text-primary text-2xl mt-0.5">local_shipping</span>
            <div>
              <h4 className="text-sm font-bold text-on-surface">
                {isScheduled ? 'Scheduled Pickup Order' : 'Express Immediate Pickup'}
              </h4>
              <p className="text-xs text-on-surface-variant mt-0.5">
                {isScheduled ? `Scheduled for: ${pickupTimeStr}` : 'Customer will pick up as soon as ready.'}
              </p>
            </div>
          </div>

          {/* Special Instructions */}
          {(order.print_instructions || opts.instructions) && (
            <div className="bg-amber-500/10 border border-amber-500/30 p-4 rounded-xl text-amber-300 text-xs">
              <div className="font-bold flex items-center gap-1.5 mb-1 text-sm">
                <span className="material-symbols-outlined text-[18px]">chat</span>
                Customer Print Instructions
              </div>
              <p className="leading-relaxed">{order.print_instructions || opts.instructions}</p>
            </div>
          )}

          {/* Attached Files List */}
          <div>
            <h4 className="text-xs font-bold uppercase tracking-wider text-outline mb-3 flex items-center gap-2">
              <span className="material-symbols-outlined text-[16px]">description</span>
              Attached Documents ({files.length})
            </h4>
            <div className="flex flex-col gap-2">
              {files.length === 0 ? (
                <div className="p-4 bg-surface-bright rounded-lg border border-outline-variant text-xs text-on-surface-variant text-center">
                  No explicit file metadata attached to this order.
                </div>
              ) : (
                files.map((f, idx) => (
                  <div key={idx} className="bg-surface-bright border border-outline-variant p-3 rounded-lg flex items-center justify-between gap-4">
                    <div className="flex items-center gap-3 overflow-hidden">
                      <span className="material-symbols-outlined text-primary text-xl">picture_as_pdf</span>
                      <div className="truncate">
                        <p className="text-sm font-semibold text-on-surface truncate">{f.name}</p>
                        <p className="text-[11px] text-on-surface-variant">{f.pages} pages</p>
                      </div>
                    </div>

                    <button
                      onClick={() => onPrint(order.order_id, true)}
                      className="px-3 py-1.5 bg-primary-container text-on-primary-container font-semibold rounded text-xs hover:bg-primary transition-colors flex items-center gap-1.5 shrink-0 cursor-pointer"
                    >
                      <span className="material-symbols-outlined text-[16px]">download</span>
                      Download
                    </button>
                  </div>
                ))
              )}
            </div>
          </div>

          {/* Help Action Button */}
          <button 
            onClick={() => alert(`Connecting to Support Agent for Order #${shortId}...`)}
            className="w-full py-3 rounded-xl glass-panel border border-glass-edge flex items-center justify-center gap-2 hover:bg-glass-bg-light transition-all active:scale-[0.98] text-xs font-label-md cursor-pointer"
          >
            <span className="material-symbols-outlined text-on-surface-variant text-base">support_agent</span>
            <span className="text-on-surface font-semibold">Need help with your order?</span>
          </button>
        </div>

        {/* Footer Actions */}
        <div className="p-4 border-t border-outline-variant bg-surface-container-low flex flex-wrap items-center justify-between gap-3 shrink-0">
          <div className="flex items-center gap-2">
            <button
              onClick={() => onPrint(order.order_id, true)}
              className="px-4 py-2 bg-surface-bright border border-outline-variant text-primary rounded-lg text-xs font-semibold hover:border-primary transition-colors flex items-center gap-1.5 cursor-pointer"
            >
              <span className="material-symbols-outlined text-[16px]">download</span>
              Download PDF
            </button>
            <button
              onClick={() => onPrint(order.order_id, false)}
              className="px-4 py-2 bg-surface-bright border border-outline-variant text-on-surface rounded-lg text-xs font-semibold hover:border-primary transition-colors flex items-center gap-1.5 cursor-pointer"
            >
              <span className="material-symbols-outlined text-[16px]">print</span>
              Print Document
            </button>
          </div>

          <div className="flex items-center gap-2">
            {order.status === 'queued' && (
              <>
                <button
                  onClick={() => { onStatusUpdate(order.order_id, 'processing'); onClose(); }}
                  className="px-4 py-2 bg-primary-container text-on-primary-container font-bold rounded-lg text-xs hover:bg-primary transition-colors flex items-center gap-1.5 shadow cursor-pointer active:scale-95"
                >
                  <span className="material-symbols-outlined text-[16px]">download_done</span>
                  Accept & DL
                </button>
                <button
                  onClick={() => { onStatusUpdate(order.order_id, 'cancelled'); onClose(); }}
                  className="px-3 py-2 bg-error/10 border border-error/30 text-error font-semibold rounded-lg text-xs hover:bg-error/20 transition-colors flex items-center gap-1 cursor-pointer active:scale-95"
                >
                  <span className="material-symbols-outlined text-[16px]">close</span>
                  Reject Order
                </button>
              </>
            )}

            {order.status === 'processing' && (
              <button
                onClick={() => { onStatusUpdate(order.order_id, 'ready'); onClose(); }}
                className="px-4 py-2 bg-primary-container text-on-primary-container font-bold rounded-lg text-xs hover:bg-primary transition-colors flex items-center gap-1.5 shadow cursor-pointer active:scale-95"
              >
                <span className="material-symbols-outlined text-[16px]">check_box</span>
                Mark Ready for Pickup
              </button>
            )}

            {order.status === 'ready' && (
              <button
                onClick={() => { onStatusUpdate(order.order_id, 'collected'); onClose(); }}
                className="px-4 py-2 bg-primary-container text-on-primary-container font-bold rounded-lg text-xs hover:bg-primary transition-colors flex items-center gap-1.5 shadow cursor-pointer active:scale-95"
              >
                <span className="material-symbols-outlined text-[16px]">how_to_reg</span>
                Mark Handed to Customer
              </button>
            )}

            <button
              onClick={onClose}
              className="px-4 py-2 bg-surface-container-highest border border-outline-variant text-on-surface-variant rounded-lg text-xs font-medium hover:text-on-surface cursor-pointer"
            >
              Close
            </button>
          </div>
        </div>
      </div>
    </div>
  );
};

export default OrderDetailModal;
