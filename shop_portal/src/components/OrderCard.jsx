import React from 'react';

const OrderCard = ({ order, colType, onStatusUpdate, onPrint, onOpenModal, onReviewAndAccept }) => {
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
  if (files.length > 0 && files[0].print_options) {
    try {
      const fileOpts = typeof files[0].print_options === 'string' ? JSON.parse(files[0].print_options) : files[0].print_options;
      opts = { ...opts, ...fileOpts };
    } catch(e) {}
  }
  if (false) {
    try {
      opts = typeof files[0].print_options === 'string' ? JSON.parse(files[0].print_options) : files[0].print_options;
    } catch(e) {}
  }

  const phoneStr = order.customer_phone || 'N/A';
  const isScheduled = opts.pickup_type === 'scheduled' || order.order_id?.startsWith('S');
  const pickupTypeStr = isScheduled ? 'Scheduled' : 'Express';
  let pickupTimeStr = 'ASAP Pickup';
  if (isScheduled && opts.pickup_time) {
    const pt = new Date(opts.pickup_time);
    pickupTimeStr = pt.toLocaleDateString([], { month: 'short', day: 'numeric' }) + ' ' + pt.toLocaleTimeString([], { hour: '2-digit', minute: '2-digit' });
  }

  const handleAction = async (status, e) => {
    e.stopPropagation();
    if (status === 'processing') {
      if (onReviewAndAccept) {
        onReviewAndAccept(order);
        return;
      }
      onPrint(order.order_id);
    }
    onStatusUpdate(order.order_id, status);
  };

  const handlePrintClick = (e) => {
    e.stopPropagation();
    onPrint(order.order_id);
  };

  return (
    <div 
      className="bg-surface-container backdrop-blur-md rounded-xl border border-glass-edge/40 p-5 hover:border-primary/50 transition-all shadow-sm hover:shadow-md relative group cursor-pointer flex flex-col"
      onClick={() => onOpenModal(order)}
    >
      {/* Card Header */}
      <div className="flex justify-between items-start mb-3">
        <div>
          <div className="flex items-center gap-2 mb-1 flex-wrap">
            <span className="font-display text-xl text-primary font-bold tracking-tight">#{shortId}</span>
            {order.queue_position && colType === 'queued' && (
              <span className="bg-surface-container/80 px-2 py-0.5 rounded text-[11px] text-on-surface-variant font-medium border border-glass-edge/30">
                Pos {order.queue_position}
              </span>
            )}
            <span className="inline-flex items-center gap-1 bg-amber-500/15 text-amber-300 border border-amber-500/40 text-[10px] font-bold px-2 py-0.5 rounded-full shadow-[0_0_8px_rgba(245,158,11,0.2)]">
              <span className="material-symbols-outlined text-[12px]">lock</span>
              SECURE
            </span>
            {order.files_deleted && (
              <span className="inline-flex items-center gap-0.5 bg-emerald-500/15 text-emerald-400 border border-emerald-500/30 text-[9px] font-medium px-1.5 py-0.5 rounded">
                <span className="material-symbols-outlined text-[11px]">delete_sweep</span>
                Erased
              </span>
            )}
          </div>
          <div className="flex items-center gap-1.5 text-on-surface-variant/80 text-xs font-medium">
            <span className="material-symbols-outlined text-[15px]">
              {isScheduled ? 'calendar_today' : 'bolt'}
            </span>
            {pickupTypeStr}
          </div>
        </div>

        <div className="text-right">
          <div className="font-display text-2xl text-on-surface font-extrabold tracking-tight">₹{order.amount_total}</div>
          <div className="flex items-center justify-end gap-1.5 mt-0.5">
            <span className="text-[11px] text-on-surface-variant/70 font-medium">Total</span>
            {order.payment_status && (
              <span className={`text-[9px] font-bold px-1.5 py-0.5 rounded uppercase tracking-wider ${
                order.payment_status === 'captured' 
                  ? 'bg-emerald-500/15 text-emerald-400 border border-emerald-500/30' 
                  : 'bg-amber-500/15 text-amber-400 border border-amber-500/30'
              }`}>
                {order.payment_status === 'captured' ? 'Paid' : 'Unpaid'}
              </span>
            )}
          </div>
        </div>
      </div>

      {/* Divider */}
      <div className="h-px w-full bg-glass-edge/20 mb-4"></div>

      {/* Details Grid */}
      <div className="grid grid-cols-2 gap-y-3.5 gap-x-4 mb-4 text-xs text-on-surface-variant/80">
        <div>
          <span className="block text-[10px] font-semibold uppercase tracking-wider text-outline mb-0.5">COLOR</span>
          <span className="text-on-surface font-medium">{opts.color === 'color' ? 'Color' : 'B&W'}</span>
        </div>
        <div>
          <span className="block text-[10px] font-semibold uppercase tracking-wider text-outline mb-0.5">CONFIG</span>
          <span className="text-on-surface font-medium">{opts.size || 'A4'} {opts.sides === 'double' ? 'Double' : 'Single'}</span>
        </div>
        <div>
          <span className="block text-[10px] font-semibold uppercase tracking-wider text-outline mb-0.5">COPIES</span>
          <span className="text-on-surface font-medium">{opts.copies || 1}</span>
        </div>
        <div>
          <span className="block text-[10px] font-semibold uppercase tracking-wider text-outline mb-0.5">BINDING</span>
          <span className="text-on-surface font-medium">{opts.binding || 'None'}</span>
        </div>
        <div className="col-span-2">
          <span className="block text-[10px] font-semibold uppercase tracking-wider text-outline mb-0.5">CUSTOMER CONTACT</span>
          <div className="flex items-center gap-1.5 text-on-surface font-medium text-xs">
            <span className="material-symbols-outlined text-[15px] text-on-surface-variant">call</span>
            {phoneStr}
          </div>
        </div>
        <div className="col-span-2 bg-surface-container/60 p-2.5 rounded-lg border border-glass-edge/20">
          <span className="block text-[10px] font-semibold uppercase tracking-wider text-outline mb-0.5">PICKUP DETAILS</span>
          <div className="flex items-center gap-2 text-on-surface text-xs font-medium">
            <span className="material-symbols-outlined text-[16px] text-primary">local_shipping</span>
            {isScheduled ? `Scheduled: ${pickupTimeStr}` : 'Express ASAP Pickup'}
          </div>
        </div>
      </div>

      {/* Print Instructions */}
      {(order.print_instructions || opts.instructions) && (
        <div className="mb-4 p-2 bg-amber-500/10 border-l-2 border-amber-500 text-amber-300 text-xs italic rounded-r">
          💬 {order.print_instructions || opts.instructions}
        </div>
      )}

      {/* Actions */}
      <div className="flex items-center gap-3 mt-auto pt-3 border-t border-glass-edge/20">
        {colType === 'queued' && (
          <>
            <button
              onClick={(e) => handleAction('processing', e)}
              className="flex-1 bg-primary hover:bg-primary/90 text-on-primary font-bold text-xs py-2.5 px-3 rounded-lg flex items-center justify-center gap-1.5 active:scale-[0.98] transition-all shadow-sm cursor-pointer"
            >
              <span className="material-symbols-outlined text-[18px]">check</span>
              Accept &amp; Print
            </button>
            <button
              onClick={(e) => handleAction('cancelled', e)}
              className="w-9 h-9 rounded-lg border border-glass-edge/40 text-on-surface-variant/90 hover:text-error hover:border-error/60 flex items-center justify-center hover:bg-error/10 active:scale-95 transition-all shrink-0 cursor-pointer"
              title="Reject Order"
            >
              <span className="material-symbols-outlined text-[18px]">close</span>
            </button>
          </>
        )}

        {colType === 'processing' && (
          <>
            <button
              onClick={handlePrintClick}
              disabled={Boolean(order.files_deleted)}
              className="bg-surface-container border border-glass-edge/40 text-primary px-3 py-2 rounded-lg text-xs font-bold hover:bg-surface-variant active:scale-[0.98] transition-all flex items-center gap-1 cursor-pointer disabled:opacity-40 disabled:cursor-not-allowed"
              title={order.files_deleted ? "Document files have already been permanently erased per privacy policy" : "Print document"}
            >
              <span className="material-symbols-outlined text-[16px]">print</span>
              Print
            </button>
            <button
              onClick={(e) => handleAction('ready', e)}
              className="flex-1 bg-primary hover:bg-primary/90 text-on-primary font-bold text-xs py-2 px-3 rounded-lg flex items-center justify-center gap-1.5 active:scale-[0.98] transition-all shadow-sm cursor-pointer"
            >
              <span className="material-symbols-outlined text-[18px]">check_box</span>
              Mark Ready
            </button>
          </>
        )}

        {colType === 'ready' && (
          <div className="flex items-center gap-2 w-full">
            <button
              type="button"
              onClick={handlePrintClick}
              disabled={Boolean(order.files_deleted)}
              className="bg-surface-container border border-glass-edge/40 text-primary px-3 py-2 rounded-lg text-xs font-bold hover:bg-surface-variant active:scale-[0.98] transition-all flex items-center gap-1 cursor-pointer shrink-0"
              title="Reprint document in case of paper jam, smudge, or error"
            >
              <span className="material-symbols-outlined text-[16px]">print</span>
              Reprint
            </button>
            <button
              type="button"
              onClick={(e) => handleAction('collected', e)}
              className="flex-1 bg-primary hover:bg-primary/90 text-on-primary font-bold text-xs py-2 px-3 rounded-lg flex items-center justify-center gap-1.5 active:scale-[0.98] transition-all shadow-sm cursor-pointer"
            >
              <span className="material-symbols-outlined text-[18px]">how_to_reg</span>
              Handed to Customer
            </button>
          </div>
        )}
      </div>
    </div>
  );
};

export default OrderCard;
