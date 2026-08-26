import React from 'react';

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
      onPrint(order.order_id, true);
    }
    onStatusUpdate(order.order_id, status);
  };

  const handlePrintClick = (e) => {
    e.stopPropagation();
    onPrint(order.order_id, false);
  };

  return (
    <div 
      className="bg-surface-bright rounded-lg border border-outline-variant p-5 hover:border-primary/50 transition-colors shadow-[0_4px_12px_rgba(0,0,0,0.1)] relative group cursor-pointer flex flex-col"
      onClick={() => onOpenModal(order)}
    >
      {/* Card Header */}
      <div className="flex justify-between items-start mb-4">
        <div>
          <div className="flex items-center gap-2 mb-1">
            <span className="font-title-md text-title-md text-primary font-bold">#{shortId}</span>
            {order.queue_position && colType === 'queued' && (
              <span className="bg-surface-container px-2 py-0.5 rounded text-xs text-on-surface-variant border border-outline-variant">
                Pos {order.queue_position}
              </span>
            )}
          </div>
          <div className="flex items-center gap-1 text-on-surface-variant text-xs">
            <span className="material-symbols-outlined text-[14px]">
              {isScheduled ? 'event' : 'bolt'}
            </span>
            {pickupTypeStr}
          </div>
        </div>

        <div className="text-right">
          <div className="font-title-md text-title-md text-on-surface font-bold">₹{order.amount_total}</div>
          <div className="flex items-center justify-end gap-1.5 mt-0.5">
            <span className="text-xs text-on-surface-variant">Total</span>
            {order.payment_status && (
              <span className={`text-[10px] font-bold px-1.5 py-0.5 rounded uppercase ${
                order.payment_status === 'captured' 
                  ? 'bg-green-500/20 text-green-300 border border-green-500/30' 
                  : 'bg-amber-500/20 text-amber-300 border border-amber-500/30'
              }`}>
                {order.payment_status === 'captured' ? 'Paid' : 'Unpaid'}
              </span>
            )}
          </div>
        </div>
      </div>

      {/* Divider */}
      <div className="h-px w-full bg-outline-variant mb-4"></div>

      {/* Details Grid */}
      <div className="grid grid-cols-2 gap-y-3 gap-x-4 mb-5 font-body-sm text-body-sm text-on-surface-variant">
        <div>
          <span className="block text-[10px] uppercase tracking-wider text-outline mb-0.5">Color</span>
          <span className="text-on-surface font-medium">{opts.color === 'color' ? 'Color' : 'B&W'}</span>
        </div>
        <div>
          <span className="block text-[10px] uppercase tracking-wider text-outline mb-0.5">Config</span>
          <span className="text-on-surface font-medium">{opts.size || 'A4'} {opts.sides === 'double' ? 'Double' : 'Single'}</span>
        </div>
        <div>
          <span className="block text-[10px] uppercase tracking-wider text-outline mb-0.5">Copies</span>
          <span className="text-on-surface font-medium">{opts.copies || 1}</span>
        </div>
        <div>
          <span className="block text-[10px] uppercase tracking-wider text-outline mb-0.5">Binding</span>
          <span className="text-on-surface font-medium">{opts.binding || 'None'}</span>
        </div>
        <div className="col-span-2">
          <span className="block text-[10px] uppercase tracking-wider text-outline mb-0.5">Customer Contact</span>
          <div className="flex items-center gap-1 text-on-surface font-medium">
            <span className="material-symbols-outlined text-[14px]">call</span>
            {phoneStr}
          </div>
        </div>
        <div className="col-span-2 bg-surface-container-highest p-2 rounded border border-outline-variant">
          <span className="block text-[10px] uppercase tracking-wider text-outline mb-0.5">Pickup Details</span>
          <div className="flex items-center gap-2 text-on-surface text-sm">
            <span className="material-symbols-outlined text-[16px] text-primary">local_shipping</span>
            {isScheduled ? `Scheduled: ${pickupTimeStr}` : 'Express ASAP Pickup'}
          </div>
        </div>
      </div>

      {/* Print Instructions */}
      {(order.print_instructions || opts.instructions) && (
        <div className="mb-4 p-2 bg-amber-500/10 border-l-2 border-amber-500 text-amber-300 text-xs italic">
          💬 {order.print_instructions || opts.instructions}
        </div>
      )}

      {/* Actions */}
      <div className="flex items-center gap-3 mt-auto pt-4 border-t border-outline-variant">
        {colType === 'queued' && (
          <>
            <button
              onClick={(e) => handleAction('processing', e)}
              className="flex-1 bg-primary-container text-on-primary-container font-label-md text-label-md py-2 rounded flex items-center justify-center gap-2 hover:bg-primary active:scale-[0.98] transition-all font-bold cursor-pointer"
            >
              <span className="material-symbols-outlined text-[18px]">download_done</span>
              Accept &amp; DL
            </button>
            <button
              onClick={(e) => handleAction('cancelled', e)}
              className="w-10 h-10 rounded border border-error/50 text-error flex items-center justify-center hover:bg-error/10 hover:border-error active:scale-95 transition-all shrink-0 cursor-pointer"
              title="Reject Order"
            >
              <span className="material-symbols-outlined">close</span>
            </button>
          </>
        )}

        {colType === 'processing' && (
          <>
            <button
              onClick={handlePrintClick}
              className="bg-surface-container border border-outline-variant text-primary px-3 py-2 rounded text-xs font-bold hover:bg-surface-variant active:scale-[0.98] transition-all flex items-center gap-1 cursor-pointer"
            >
              <span className="material-symbols-outlined text-[16px]">print</span>
              Print
            </button>
            <button
              onClick={(e) => handleAction('ready', e)}
              className="flex-1 bg-primary-container text-on-primary-container font-label-md text-label-md py-2 px-3 rounded flex items-center justify-center gap-1.5 hover:bg-primary active:scale-[0.98] transition-all font-bold cursor-pointer"
            >
              <span className="material-symbols-outlined text-[18px]">check_box</span>
              Mark Ready
            </button>
          </>
        )}

        {colType === 'ready' && (
          <button
            onClick={(e) => handleAction('collected', e)}
            className="flex-1 bg-primary-container text-on-primary-container font-label-md text-label-md py-2 px-3 rounded flex items-center justify-center gap-1.5 hover:bg-primary active:scale-[0.98] transition-all font-bold cursor-pointer"
          >
            <span className="material-symbols-outlined text-[18px]">how_to_reg</span>
            Handed to Customer
          </button>
        )}
      </div>
    </div>
  );
};

export default OrderCard;
