import React, { useState, useEffect } from 'react';
import api from '../core/api';

const PrintReviewModal = ({ order, onClose, onApprove }) => {
  const shortId = order?.order_id ? order.order_id.split('-')[0] : '';

  // Parse files
  let files = [];
  try {
    const raw = typeof order?.files === 'string' ? JSON.parse(order.files) : (order?.files || []);
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
  } catch (e) {}

  // Parse initial print options
  let initialOpts = {};
  try {
    initialOpts = typeof order?.print_options === 'string' 
      ? JSON.parse(order.print_options) 
      : (order?.print_options || {});
  } catch (e) {}

  if (Object.keys(initialOpts).length === 0 && files.length > 0 && files[0].print_options) {
    try {
      initialOpts = typeof files[0].print_options === 'string' 
        ? JSON.parse(files[0].print_options) 
        : files[0].print_options;
    } catch (e) {}
  }

  // State for editable print settings
  const [colorMode, setColorMode] = useState(initialOpts.color || 'bw');
  const [copies, setCopies] = useState(Number(initialOpts.copies) || 1);
  const [paperSize, setPaperSize] = useState(initialOpts.size || 'A4');
  const [sides, setSides] = useState(initialOpts.sides || 'single');
  const [orientation, setOrientation] = useState(initialOpts.orientation || 'portrait');
  const [binding, setBinding] = useState(initialOpts.binding || 'none');

  // Connected Agent / Printer state
  const [agentDevice, setAgentDevice] = useState(null);
  const [loadingAgent, setLoadingAgent] = useState(true);
  const [isSubmitting, setIsSubmitting] = useState(false);

  useEffect(() => {
    let isMounted = true;
    const fetchAgentInfo = async () => {
      try {
        const res = await api.get('/shop/agent');
        if (isMounted) {
          setAgentDevice(res.data?.device || null);
          setLoadingAgent(false);
        }
      } catch (err) {
        console.warn('Could not fetch agent info:', err);
        if (isMounted) setLoadingAgent(false);
      }
    };
    fetchAgentInfo();
    return () => { isMounted = false; };
  }, []);

  const handleApprove = async () => {
    setIsSubmitting(true);
    const verifiedOptions = {
      ...initialOpts,
      color: colorMode,
      copies: Math.max(1, copies),
      size: paperSize,
      sides,
      orientation,
      binding
    };

    try {
      await onApprove(order.order_id, verifiedOptions);
      onClose();
    } catch (err) {
      console.error('Approval failed:', err);
      setIsSubmitting(false);
    }
  };

  const isScheduled = initialOpts.pickup_type === 'scheduled' || order?.order_id?.startsWith('S');
  const phoneStr = order?.customer_phone || 'N/A';
  const isAgentOnline = agentDevice && agentDevice.status === 'ONLINE';

  if (!order) return null;

  return (
    <div className="fixed inset-0 z-50 flex items-center justify-center p-4 bg-scrim/80 backdrop-blur-sm animate-fade-in">
      <div 
        className="bg-surface-container rounded-2xl border border-glass-edge shadow-2xl max-w-2xl w-full max-h-[92vh] flex flex-col overflow-hidden text-on-surface"
        onClick={(e) => e.stopPropagation()}
      >
        {/* Header */}
        <div className="p-5 border-b border-outline-variant/60 flex items-center justify-between bg-surface-container-high/40">
          <div className="flex items-center gap-3">
            <div className="w-10 h-10 rounded-xl bg-primary/10 border border-primary/30 flex items-center justify-center text-primary">
              <span className="material-symbols-outlined text-[24px]">verified</span>
            </div>
            <div>
              <div className="flex items-center gap-2">
                <h2 className="text-lg font-bold tracking-tight text-on-surface">Verify &amp; Approve Print Job</h2>
                <span className="font-display font-bold text-primary bg-primary/10 px-2 py-0.5 rounded text-xs">
                  #{shortId}
                </span>
                {order.print_mode === 'secure' && (
                  <span className="inline-flex items-center gap-1 bg-amber-500/15 text-amber-300 border border-amber-500/40 text-[10px] font-bold px-2 py-0.5 rounded-full">
                    <span className="material-symbols-outlined text-[12px]">lock</span>
                    SECURE
                  </span>
                )}
              </div>
              <p className="text-xs text-on-surface-variant">Review customer specifications and target printer before spooling.</p>
            </div>
          </div>
          <button 
            onClick={onClose}
            className="w-8 h-8 rounded-lg hover:bg-surface-variant flex items-center justify-center text-on-surface-variant hover:text-on-surface transition-colors cursor-pointer"
          >
            <span className="material-symbols-outlined text-[20px]">close</span>
          </button>
        </div>

        {/* Scrollable Content */}
        <div className="p-6 overflow-y-auto space-y-6">

          {/* Connected Printer Station Status Banner */}
          <div className={`p-4 rounded-xl border flex items-center justify-between ${
            isAgentOnline 
              ? 'bg-emerald-500/10 border-emerald-500/30' 
              : 'bg-amber-500/10 border-amber-500/30'
          }`}>
            <div className="flex items-center gap-3">
              <div className={`w-9 h-9 rounded-lg flex items-center justify-center ${
                isAgentOnline ? 'bg-emerald-500/20 text-emerald-400' : 'bg-amber-500/20 text-amber-300'
              }`}>
                <span className="material-symbols-outlined text-[20px]">print</span>
              </div>
              <div>
                <div className="flex items-center gap-2">
                  <span className="text-xs font-semibold text-on-surface">Target Printer Station:</span>
                  <span className="text-xs font-bold text-primary">
                    {agentDevice?.device_name || 'Counter-Station-1'}
                  </span>
                  <span className={`inline-flex items-center gap-1 text-[10px] font-bold px-1.5 py-0.5 rounded-full ${
                    isAgentOnline 
                      ? 'bg-emerald-500/20 text-emerald-400' 
                      : 'bg-amber-500/20 text-amber-300'
                  }`}>
                    <span className={`w-1.5 h-1.5 rounded-full ${isAgentOnline ? 'bg-emerald-400 animate-pulse' : 'bg-amber-400'}`}></span>
                    {isAgentOnline ? 'ONLINE' : 'OFFLINE'}
                  </span>
                </div>
                <p className="text-xs text-on-surface-variant mt-0.5">
                  Assigned Hardware: <strong className="text-on-surface">{agentDevice?.selected_printer || 'Default Windows Spooler'}</strong>
                </p>
              </div>
            </div>
            {!isAgentOnline && (
              <span className="text-[11px] text-amber-300/90 font-medium max-w-[180px] text-right">
                Job will queue and print immediately when agent connects.
              </span>
            )}
          </div>

          {/* Customer & Order Metadata */}
          <div className="grid grid-cols-2 sm:grid-cols-3 gap-3 bg-surface-container-high/40 p-4 rounded-xl border border-glass-edge/20 text-xs">
            <div>
              <span className="block text-[10px] font-bold uppercase tracking-wider text-on-surface-variant/80 mb-0.5">CUSTOMER PHONE</span>
              <span className="font-semibold text-on-surface flex items-center gap-1">
                <span className="material-symbols-outlined text-[14px] text-primary">call</span>
                {phoneStr}
              </span>
            </div>
            <div>
              <span className="block text-[10px] font-bold uppercase tracking-wider text-on-surface-variant/80 mb-0.5">SERVICE TYPE</span>
              <span className="font-semibold text-on-surface flex items-center gap-1">
                <span className="material-symbols-outlined text-[14px] text-primary">{isScheduled ? 'schedule' : 'bolt'}</span>
                {isScheduled ? 'Scheduled Pickup' : 'Express ASAP'}
              </span>
            </div>
            <div>
              <span className="block text-[10px] font-bold uppercase tracking-wider text-on-surface-variant/80 mb-0.5">DOCUMENTS</span>
              <span className="font-semibold text-on-surface flex items-center gap-1">
                <span className="material-symbols-outlined text-[14px] text-primary">description</span>
                {files.length > 0 ? `${files.length} file(s)` : '1 file'}
              </span>
            </div>
          </div>

          {/* Customer Instructions if any */}
          {(order.print_instructions || initialOpts.instructions) && (
            <div className="p-3 bg-amber-500/10 border-l-4 border-amber-500 rounded-r-lg text-amber-300 text-xs">
              <span className="font-bold block mb-0.5">Customer Instructions:</span>
              <p className="italic">"{order.print_instructions || initialOpts.instructions}"</p>
            </div>
          )}

          {/* Print Settings Grid */}
          <div className="space-y-4">
            <h3 className="text-xs font-bold uppercase tracking-wider text-primary flex items-center gap-1.5">
              <span className="material-symbols-outlined text-[16px]">tune</span>
              Verify Print Settings
            </h3>

            <div className="grid grid-cols-1 sm:grid-cols-2 gap-4">
              
              {/* Color Mode */}
              <div className="bg-surface-container-high/30 p-3.5 rounded-xl border border-glass-edge/30">
                <label className="block text-xs font-bold text-on-surface mb-2">Color Mode</label>
                <div className="grid grid-cols-2 gap-2">
                  <button
                    type="button"
                    onClick={() => setColorMode('bw')}
                    className={`py-2 px-3 rounded-lg text-xs font-bold flex items-center justify-center gap-1.5 transition-all cursor-pointer ${
                      colorMode === 'bw'
                        ? 'bg-primary text-on-primary shadow-sm'
                        : 'bg-surface-container hover:bg-surface-variant text-on-surface border border-glass-edge/40'
                    }`}
                  >
                    <span className="material-symbols-outlined text-[16px]">contrast</span>
                    Black &amp; White
                  </button>
                  <button
                    type="button"
                    onClick={() => setColorMode('color')}
                    className={`py-2 px-3 rounded-lg text-xs font-bold flex items-center justify-center gap-1.5 transition-all cursor-pointer ${
                      colorMode === 'color'
                        ? 'bg-primary text-on-primary shadow-sm'
                        : 'bg-surface-container hover:bg-surface-variant text-on-surface border border-glass-edge/40'
                    }`}
                  >
                    <span className="material-symbols-outlined text-[16px]">palette</span>
                    Color
                  </button>
                </div>
              </div>

              {/* Number of Copies */}
              <div className="bg-surface-container-high/30 p-3.5 rounded-xl border border-glass-edge/30">
                <label className="block text-xs font-bold text-on-surface mb-2">Number of Copies</label>
                <div className="flex items-center gap-3">
                  <button
                    type="button"
                    onClick={() => setCopies(prev => Math.max(1, prev - 1))}
                    className="w-10 h-9 rounded-lg bg-surface-container hover:bg-surface-variant border border-glass-edge/40 flex items-center justify-center text-on-surface font-bold text-base transition-colors cursor-pointer"
                  >
                    -
                  </button>
                  <input
                    type="number"
                    min="1"
                    max="99"
                    value={copies}
                    onChange={(e) => setCopies(Math.max(1, parseInt(e.target.value) || 1))}
                    className="w-20 text-center py-1.5 bg-surface-container border border-primary/40 rounded-lg text-sm font-bold text-primary focus:outline-none focus:ring-1 focus:ring-primary"
                  />
                  <button
                    type="button"
                    onClick={() => setCopies(prev => prev + 1)}
                    className="w-10 h-9 rounded-lg bg-surface-container hover:bg-surface-variant border border-glass-edge/40 flex items-center justify-center text-on-surface font-bold text-base transition-colors cursor-pointer"
                  >
                    +
                  </button>
                  <span className="text-xs text-on-surface-variant font-medium">sets</span>
                </div>
              </div>

              {/* Sides (Single / Double) */}
              <div className="bg-surface-container-high/30 p-3.5 rounded-xl border border-glass-edge/30">
                <label className="block text-xs font-bold text-on-surface mb-2">Print Sides</label>
                <div className="grid grid-cols-2 gap-2">
                  <button
                    type="button"
                    onClick={() => setSides('single')}
                    className={`py-2 px-3 rounded-lg text-xs font-bold flex items-center justify-center gap-1.5 transition-all cursor-pointer ${
                      sides === 'single'
                        ? 'bg-primary text-on-primary shadow-sm'
                        : 'bg-surface-container hover:bg-surface-variant text-on-surface border border-glass-edge/40'
                    }`}
                  >
                    Single-Sided
                  </button>
                  <button
                    type="button"
                    onClick={() => setSides('double')}
                    className={`py-2 px-3 rounded-lg text-xs font-bold flex items-center justify-center gap-1.5 transition-all cursor-pointer ${
                      sides === 'double'
                        ? 'bg-primary text-on-primary shadow-sm'
                        : 'bg-surface-container hover:bg-surface-variant text-on-surface border border-glass-edge/40'
                    }`}
                  >
                    Double-Sided (Duplex)
                  </button>
                </div>
              </div>

              {/* Paper Size */}
              <div className="bg-surface-container-high/30 p-3.5 rounded-xl border border-glass-edge/30">
                <label className="block text-xs font-bold text-on-surface mb-2">Paper Size</label>
                <select
                  value={paperSize}
                  onChange={(e) => setPaperSize(e.target.value)}
                  className="w-full py-2 px-3 bg-surface-container border border-glass-edge/40 rounded-lg text-xs font-medium text-on-surface focus:outline-none focus:ring-1 focus:ring-primary cursor-pointer"
                >
                  <option value="A4">A4 (Standard 210 × 297 mm)</option>
                  <option value="A3">A3 (297 × 420 mm)</option>
                  <option value="Legal">Legal (8.5 × 14 in)</option>
                  <option value="Letter">Letter (8.5 × 11 in)</option>
                </select>
              </div>

              {/* Orientation */}
              <div className="bg-surface-container-high/30 p-3.5 rounded-xl border border-glass-edge/30">
                <label className="block text-xs font-bold text-on-surface mb-2">Orientation</label>
                <div className="grid grid-cols-2 gap-2">
                  <button
                    type="button"
                    onClick={() => setOrientation('portrait')}
                    className={`py-2 px-3 rounded-lg text-xs font-bold flex items-center justify-center gap-1.5 transition-all cursor-pointer ${
                      orientation === 'portrait'
                        ? 'bg-primary text-on-primary shadow-sm'
                        : 'bg-surface-container hover:bg-surface-variant text-on-surface border border-glass-edge/40'
                    }`}
                  >
                    Portrait
                  </button>
                  <button
                    type="button"
                    onClick={() => setOrientation('landscape')}
                    className={`py-2 px-3 rounded-lg text-xs font-bold flex items-center justify-center gap-1.5 transition-all cursor-pointer ${
                      orientation === 'landscape'
                        ? 'bg-primary text-on-primary shadow-sm'
                        : 'bg-surface-container hover:bg-surface-variant text-on-surface border border-glass-edge/40'
                    }`}
                  >
                    Landscape
                  </button>
                </div>
              </div>

              {/* Binding */}
              <div className="bg-surface-container-high/30 p-3.5 rounded-xl border border-glass-edge/30">
                <label className="block text-xs font-bold text-on-surface mb-2">Binding / Finishing</label>
                <select
                  value={binding}
                  onChange={(e) => setBinding(e.target.value)}
                  className="w-full py-2 px-3 bg-surface-container border border-glass-edge/40 rounded-lg text-xs font-medium text-on-surface focus:outline-none focus:ring-1 focus:ring-primary cursor-pointer"
                >
                  <option value="none">None (Loose sheets)</option>
                  <option value="staple">Corner Staple</option>
                  <option value="spiral">Spiral Binding</option>
                  <option value="soft_cover">Soft Cover Book</option>
                </select>
              </div>

            </div>
          </div>

          {/* Files List */}
          <div className="space-y-2">
            <label className="block text-xs font-bold text-on-surface-variant uppercase tracking-wider">
              File Details
            </label>
            <div className="space-y-2">
              {files.map((file, idx) => (
                <div 
                  key={idx} 
                  className="p-3 bg-surface-container-high/30 rounded-xl border border-glass-edge/20 flex items-center justify-between text-xs"
                >
                  <div className="flex items-center gap-2.5 truncate">
                    <span className="material-symbols-outlined text-[20px] text-primary">picture_as_pdf</span>
                    <span className="font-semibold text-on-surface truncate">{file.name}</span>
                  </div>
                  <div className="flex items-center gap-3 shrink-0 text-on-surface-variant text-[11px]">
                    {file.size && <span>{Math.round(file.size / 1024)} KB</span>}
                    <span className="bg-surface-container px-2 py-0.5 rounded border border-glass-edge/30 font-medium">
                      {file.pages} page{file.pages > 1 ? 's' : ''}
                    </span>
                  </div>
                </div>
              ))}
            </div>
          </div>

        </div>

        {/* Footer Actions */}
        <div className="p-4 border-t border-outline-variant/60 bg-surface-container-high/40 flex items-center justify-between gap-3">
          <button
            type="button"
            onClick={onClose}
            disabled={isSubmitting}
            className="px-4 py-2.5 rounded-xl border border-glass-edge/50 hover:bg-surface-variant text-on-surface font-semibold text-xs transition-all cursor-pointer"
          >
            Cancel
          </button>

          <button
            type="button"
            onClick={handleApprove}
            disabled={isSubmitting}
            className="px-6 py-2.5 rounded-xl bg-primary hover:bg-primary/90 text-on-primary font-bold text-xs flex items-center gap-2 shadow-lg shadow-primary/20 active:scale-[0.98] transition-all cursor-pointer disabled:opacity-50"
          >
            {isSubmitting ? (
              <>
                <span className="w-4 h-4 border-2 border-on-primary border-t-transparent rounded-full animate-spin"></span>
                <span>Spooling to Agent...</span>
              </>
            ) : (
              <>
                <span className="material-symbols-outlined text-[18px]">print</span>
                <span>Approve &amp; Print Document</span>
              </>
            )}
          </button>
        </div>
      </div>
    </div>
  );
};

export default PrintReviewModal;
