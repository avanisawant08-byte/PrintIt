import React, { useState } from 'react';

const NewPrintJobModal = ({ onClose, onSubmitJob }) => {
  const [selectedFile, setSelectedFile] = useState(null);
  const [colorMode, setColorMode] = useState('bw'); // 'bw' | 'color'
  const [paperSize, setPaperSize] = useState('A4 Standard');
  const [isDoubleSided, setIsDoubleSided] = useState(true);
  const [copies, setCopies] = useState(1);
  const [pageCount, setPageCount] = useState(4);
  const [pickupType, setPickupType] = useState('express'); // 'express' | 'scheduled'
  const [customerPhone, setCustomerPhone] = useState('');
  const [isSubmitting, setIsSubmitting] = useState(false);

  // Price Calculation Logic
  const pricePerPage = colorMode === 'color' ? 10 : 2;
  const sidesMultiplier = isDoubleSided ? 0.8 : 1.0;
  const totalPrice = (pageCount * pricePerPage * copies * sidesMultiplier).toFixed(2);

  const handleFileChange = (e) => {
    if (e.target.files && e.target.files[0]) {
      setSelectedFile(e.target.files[0]);
    }
  };

  const handleDrop = (e) => {
    e.preventDefault();
    if (e.dataTransfer.files && e.dataTransfer.files[0]) {
      setSelectedFile(e.dataTransfer.files[0]);
    }
  };

  const handleSubmit = (e) => {
    e.preventDefault();
    setIsSubmitting(true);

    const jobData = {
      file: selectedFile,
      colorMode,
      paperSize,
      isDoubleSided,
      copies,
      totalPrice,
      customerPhone,
      pickupType
    };

    setTimeout(() => {
      setIsSubmitting(false);
      if (onSubmitJob) onSubmitJob(jobData);
      onClose();
    }, 600);
  };

  return (
    <div className="fixed inset-0 z-50 bg-black/80 backdrop-blur-md flex items-center justify-center p-4 overflow-y-auto">
      <div 
        className="glass-panel-heavy rounded-2xl w-full max-w-3xl max-h-[92vh] flex flex-col shadow-[0_0_32px_rgba(0,229,255,0.15)] overflow-hidden border border-glass-edge animate-fade-in relative"
        onClick={(e) => e.stopPropagation()}
      >
        {/* Modal Header */}
        <div className="px-6 py-4 border-b border-glass-edge/30 bg-surface-container-low flex justify-between items-center shrink-0">
          <div className="flex items-center gap-2">
            <span className="material-symbols-outlined text-primary-fixed-dim text-2xl">print</span>
            <h2 className="text-xl font-bold text-primary-fixed-dim font-headline-md">Configure & Upload Print Job</h2>
          </div>

          <button
            onClick={onClose}
            className="w-9 h-9 rounded-full bg-surface-container border border-glass-edge text-on-surface-variant hover:text-on-surface flex items-center justify-center transition-colors cursor-pointer"
          >
            <span className="material-symbols-outlined text-xl">close</span>
          </button>
        </div>

        {/* Modal Body */}
        <div className="p-6 overflow-y-auto kanban-col space-y-6 flex-1">
          {/* Upload Section */}
          <section>
            <div 
              onDragOver={(e) => e.preventDefault()}
              onDrop={handleDrop}
              onClick={() => document.getElementById('new-file-input').click()}
              className="glass-panel rounded-xl p-6 border-dashed border-2 border-primary-fixed-dim/30 flex flex-col items-center justify-center text-center transition-all cursor-pointer hover:border-primary-fixed-dim/60 group backdrop-blur-xl bg-white/5 border-glass-border relative"
            >
              <input
                id="new-file-input"
                type="file"
                accept=".pdf,.doc,.docx,.jpg,.png"
                onChange={handleFileChange}
                className="hidden"
              />
              <div className="w-16 h-16 rounded-full bg-primary-fixed-dim/10 flex items-center justify-center mb-3 group-hover:scale-110 transition-transform">
                <span className="material-symbols-outlined text-primary-fixed-dim text-4xl">cloud_upload</span>
              </div>
              <h3 className="text-lg font-bold text-on-surface mb-1">
                {selectedFile ? selectedFile.name : 'Upload Document'}
              </h3>
              <p className="text-xs font-label-md text-on-surface-variant">
                {selectedFile ? `${(selectedFile.size / (1024 * 1024)).toFixed(2)} MB • Ready for config` : 'Drop your file here or browse'}
              </p>
              <p className="text-[10px] uppercase tracking-widest text-on-surface-variant/50 mt-3 font-mono">
                PDF, DOCX, PNG (Max 50MB)
              </p>
            </div>
          </section>

          {/* Preview & Config Bento Grid */}
          <div className="grid grid-cols-1 md:grid-cols-2 gap-6">
            {/* Preview Area */}
            <div className="glass-panel rounded-xl overflow-hidden flex flex-col">
              <div className="px-4 py-2.5 border-b border-glass-edge flex justify-between items-center bg-white/5 font-label-sm text-xs">
                <span className="text-on-surface-variant uppercase tracking-wider">PREVIEW</span>
                <span className="text-primary-fixed-dim font-bold">Page 1 of {pageCount}</span>
              </div>
              <div className="aspect-[3/4] relative p-4 bg-surface-container-low flex items-center justify-center">
                {/* Glassmorphic Document Mockup */}
                <div className="w-full h-full glass-panel rounded-sm shadow-2xl relative overflow-hidden bg-white/5 p-4 flex flex-col justify-between">
                  <div className="space-y-3">
                    <div className="h-4 w-3/4 bg-on-surface/20 rounded"></div>
                    <div className="h-2 w-full bg-on-surface/10 rounded"></div>
                    <div className="h-2 w-full bg-on-surface/10 rounded"></div>
                    <div className="h-2 w-2/3 bg-on-surface/10 rounded"></div>
                    <div className="pt-4 h-28 w-full bg-on-surface/5 rounded flex flex-col items-center justify-center gap-1 border border-glass-edge/20">
                      <span className="material-symbols-outlined text-primary-fixed-dim/40 text-5xl">description</span>
                      <span className="text-[10px] font-mono text-on-surface-variant/60">{selectedFile ? selectedFile.name : 'Document.pdf'}</span>
                    </div>
                    <div className="h-2 w-full bg-on-surface/10 rounded"></div>
                    <div className="h-2 w-1/2 bg-on-surface/10 rounded"></div>
                  </div>
                  {/* Decorative ambient cyan glow */}
                  <div className="absolute -bottom-10 -right-10 w-24 h-24 bg-primary-fixed-dim/10 blur-3xl rounded-full"></div>
                </div>
              </div>
            </div>

            {/* Configuration Area */}
            <div className="space-y-4">
              {/* Customer Contact */}
              <div className="glass-panel rounded-xl p-4">
                <label className="text-xs font-label-sm text-on-surface-variant mb-1 block uppercase tracking-wider">Customer Phone</label>
                <div className="relative">
                  <span className="material-symbols-outlined absolute left-3 top-1/2 -translate-y-1/2 text-on-surface-variant text-[16px]">call</span>
                  <input
                    type="tel"
                    value={customerPhone}
                    onChange={(e) => setCustomerPhone(e.target.value)}
                    placeholder="Enter phone number (optional)"
                    className="w-full bg-surface-container border border-glass-edge rounded-lg py-2 pl-9 pr-3 text-xs font-mono text-on-surface focus:border-primary-fixed-dim outline-none"
                  />
                </div>
              </div>

              {/* Color Mode Toggle */}
              <div className="glass-panel rounded-xl p-4">
                <label className="text-xs font-label-sm text-on-surface-variant mb-2 block uppercase tracking-wider">Color Mode</label>
                <div className="flex p-1 bg-surface-container rounded-lg border border-glass-edge">
                  <button
                    type="button"
                    onClick={() => setColorMode('bw')}
                    className={`flex-1 py-2 text-xs font-label-md rounded-md transition-all cursor-pointer ${
                      colorMode === 'bw'
                        ? 'bg-primary-fixed-dim text-on-primary-container font-bold shadow-lg'
                        : 'text-on-surface-variant hover:text-on-surface'
                    }`}
                  >
                    ⬛ B&W (₹2/page)
                  </button>
                  <button
                    type="button"
                    onClick={() => setColorMode('color')}
                    className={`flex-1 py-2 text-xs font-label-md rounded-md transition-all cursor-pointer ${
                      colorMode === 'color'
                        ? 'bg-primary-fixed-dim text-on-primary-container font-bold shadow-lg'
                        : 'text-on-surface-variant hover:text-on-surface'
                    }`}
                  >
                    🎨 Full Color (₹10/page)
                  </button>
                </div>
              </div>

              {/* Paper Size */}
              <div className="glass-panel rounded-xl p-4">
                <label className="text-xs font-label-sm text-on-surface-variant mb-2 block uppercase tracking-wider">Paper Size</label>
                <select
                  value={paperSize}
                  onChange={(e) => setPaperSize(e.target.value)}
                  className="w-full bg-surface-container border border-glass-edge rounded-lg py-2 px-3 text-xs text-on-surface focus:border-primary-fixed-dim outline-none"
                >
                  <option value="A4 Standard">A4 Standard</option>
                  <option value="A3 Large">A3 Large</option>
                  <option value="Letter">Letter</option>
                  <option value="Legal">Legal</option>
                </select>
              </div>

              {/* Sided & Copies Row */}
              <div className="grid grid-cols-2 gap-4">
                {/* Sided Switch */}
                <div className="glass-panel rounded-xl p-4">
                  <label className="text-xs font-label-sm text-on-surface-variant mb-2 block uppercase tracking-wider">Sides</label>
                  <div className="flex items-center justify-between">
                    <span className="text-xs font-label-md">{isDoubleSided ? 'Double' : 'Single'}</span>
                    <button
                      type="button"
                      onClick={() => setIsDoubleSided(!isDoubleSided)}
                      className={`w-12 h-6 rounded-full relative flex items-center transition-colors cursor-pointer ${
                        isDoubleSided ? 'bg-primary-fixed-dim/30' : 'bg-surface-container'
                      }`}
                    >
                      <div className={`w-5 h-5 bg-primary-fixed-dim rounded-full absolute transition-all shadow-sm ${
                        isDoubleSided ? 'left-6' : 'left-1'
                      }`}></div>
                    </button>
                  </div>
                </div>

                {/* Copies Counter */}
                <div className="glass-panel rounded-xl p-4">
                  <label className="text-xs font-label-sm text-on-surface-variant mb-2 block uppercase tracking-wider">Copies</label>
                  <div className="flex items-center justify-between gap-2">
                    <button
                      type="button"
                      onClick={() => setCopies(Math.max(1, copies - 1))}
                      className="w-8 h-8 rounded-lg bg-surface-container border border-glass-edge flex items-center justify-center hover:bg-glass-edge/20 transition-colors cursor-pointer text-sm font-bold"
                    >
                      -
                    </button>
                    <span className="text-sm font-bold font-mono">{copies}</span>
                    <button
                      type="button"
                      onClick={() => setCopies(copies + 1)}
                      className="w-8 h-8 rounded-lg bg-surface-container border border-glass-edge flex items-center justify-center hover:bg-glass-edge/20 transition-colors cursor-pointer text-sm font-bold"
                    >
                      +
                    </button>
                  </div>
                </div>
              </div>
            </div>
          </div>
        </div>

        {/* Sticky Payment & Submission Footer */}
        <div className="px-6 py-4 border-t border-glass-edge bg-surface-container-low flex flex-wrap items-center justify-between gap-4 shrink-0">
          <div className="flex flex-col">
            <div className="flex items-baseline gap-1">
              <span className="text-2xl font-bold font-mono text-primary-fixed-dim">₹{totalPrice}</span>
              <span className="text-xs font-label-sm text-on-surface-variant">Total Cost</span>
            </div>
            <div className="flex items-center gap-1 text-xs text-status-success font-label-sm mt-0.5">
              <span className="material-symbols-outlined text-sm">timer</span>
              <span>Ready in ~4 mins</span>
            </div>
          </div>

          <div className="flex items-center gap-3">
            <button
              type="button"
              onClick={onClose}
              className="px-4 py-3 glass-panel rounded-xl text-xs font-bold text-on-surface-variant hover:text-on-surface cursor-pointer"
            >
              Cancel
            </button>
            <button
              type="button"
              onClick={handleSubmit}
              disabled={isSubmitting}
              className="pulse-btn px-6 py-3 bg-gradient-to-r from-primary-container to-secondary-container text-on-primary-container font-bold rounded-xl flex items-center gap-2 active:scale-95 transition-transform text-xs cursor-pointer shadow-lg"
            >
              <span>{isSubmitting ? 'Creating Job...' : 'Proceed to Create Job'}</span>
              <span className="material-symbols-outlined text-base">arrow_forward</span>
            </button>
          </div>
        </div>
      </div>
    </div>
  );
};

export default NewPrintJobModal;
