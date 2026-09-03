import React, { useState, useEffect, useRef } from 'react';
import api from '../../core/api';
import { useAuth } from '../../context/AuthContext';
import { QRCodeSVG, QRCodeCanvas } from 'qrcode.react';

const MASTER_CAPABILITIES = [
  { id: 'books', name: 'Book Printing', icon: 'book', desc: 'Book printing & perfect binding' },
  { id: 'spiral_binding', name: 'Spiral Binding', icon: 'auto_stories', desc: 'Spiral & comb binding' },
  { id: 'lamination', name: 'Lamination', icon: 'layers', desc: 'Document lamination' },
  { id: 'large_format', name: 'Large Format', icon: 'aspect_ratio', desc: 'A3, banners & posters' },
  { id: 'id_cards', name: 'ID Cards', icon: 'badge', desc: 'PVC & paper ID card printing' },
  { id: 'notebooks', name: 'Notebooks', icon: 'menu_book', desc: 'Custom notebooks & pads' },
  { id: 'bulk_printing', name: 'Bulk Printing', icon: 'print', desc: 'High-volume discount print' },
  { id: 'same_day', name: 'Same Day Express', icon: 'bolt', desc: 'Priority same-day pickup' }
];

const Settings = () => {
  const { shopName } = useAuth();
  const [profile, setProfile] = useState(null);
  const [capabilities, setCapabilities] = useState([]);
  const [isLoading, setIsLoading] = useState(true);
  const [isSaving, setIsSaving] = useState(false);
  const [successMsg, setSuccessMsg] = useState('');
  const [copied, setCopied] = useState(false);
  const qrCanvasRef = useRef(null);

  // Form states
  const [name, setName] = useState('');
  const [phone, setPhone] = useState('');
  const [address, setAddress] = useState('');
  const [priceBw, setPriceBw] = useState('');
  const [priceColor, setPriceColor] = useState('');
  const [openingTime, setOpeningTime] = useState('09:00');
  const [closingTime, setClosingTime] = useState('21:00');
  const [isOpen, setIsOpen] = useState(true);

  const fetchShopProfile = async () => {
    setIsLoading(true);
    try {
      const res = await api.get('/shop/profile');
      const data = res.data;
      setProfile(data);
      setName(data.name || '');
      setPhone(data.phone || '');
      setAddress(data.address || '');
      setPriceBw(data.price_bw || '');
      setPriceColor(data.price_color || '');
      setOpeningTime(data.opening_time || '09:00');
      setClosingTime(data.closing_time || '21:00');
      setIsOpen(data.is_open !== undefined ? data.is_open : true);

      if (data.capabilities && Array.isArray(data.capabilities)) {
        setCapabilities(data.capabilities);
      } else {
        fetchCapabilities();
      }
    } catch (err) {
      console.warn('Profile fetch fallback to status:', err.message);
      try {
        const statusRes = await api.get('/shop/status');
        const st = statusRes.data;
        setIsOpen(st.is_open !== undefined ? st.is_open : true);
        setOpeningTime(st.opening_time || '09:00');
        setClosingTime(st.closing_time || '21:00');
        fetchCapabilities();
      } catch (stErr) {
        console.error('Failed to load shop settings:', stErr);
      }
    } finally {
      setIsLoading(false);
    }
  };

  const fetchCapabilities = async () => {
    try {
      const res = await api.get('/shop/capabilities');
      setCapabilities(res.data || []);
    } catch (e) {
      console.error('Failed to load capabilities:', e);
    }
  };

  useEffect(() => {
    fetchShopProfile();
  }, []);

  const handleToggleOpen = async () => {
    const newStatus = !isOpen;
    setIsOpen(newStatus);
    try {
      await api.patch('/shop/status', { is_open: newStatus });
      setSuccessMsg(`Store status updated to ${newStatus ? 'OPEN' : 'CLOSED'}`);
      setTimeout(() => setSuccessMsg(''), 3000);
    } catch (err) {
      alert('Failed to update status: ' + err.message);
      setIsOpen(!newStatus);
    }
  };

  const handleSaveProfile = async (e) => {
    e.preventDefault();
    setIsSaving(true);
    try {
      await api.patch('/shop/profile', {
        name,
        phone,
        address,
        price_bw: parseFloat(priceBw) || 0,
        price_color: parseFloat(priceColor) || 0,
        opening_time: openingTime,
        closing_time: closingTime,
        is_open: isOpen
      });

      setSuccessMsg('Shop settings & details saved successfully!');
      setTimeout(() => setSuccessMsg(''), 4000);
    } catch (err) {
      alert('Failed to save settings: ' + err.message);
    } finally {
      setIsSaving(false);
    }
  };

  const handleToggleCapability = async (capId) => {
    const isPresent = capabilities.includes(capId);
    try {
      if (isPresent) {
        await api.delete(`/shop/capabilities/${capId}`);
        setCapabilities(capabilities.filter(c => c !== capId));
      } else {
        await api.post('/shop/capabilities', { capability: capId });
        setCapabilities([...capabilities, capId]);
      }
    } catch (err) {
      alert('Failed to update capability: ' + err.message);
    }
  };

  // Direct In-Store QR URL
  const shopId = profile?.shop_id || profile?.id || '8473b134-01c6-46b1-9746-4befaaa5fd46';
  const host = (window.location.hostname === 'localhost' || window.location.hostname === '127.0.0.1')
    ? '192.168.0.103'
    : window.location.hostname;
  const customerBaseUrl = 
    import.meta.env.VITE_CUSTOMER_APP_URL || 
    (window.location.port === '5173'
      ? `${window.location.protocol}//${host}:8080`
      : `${window.location.origin}`);
  const qrDirectUrl = `${customerBaseUrl}/#/upload-document/${shopId}`;

  const handleCopyLink = () => {
    navigator.clipboard.writeText(qrDirectUrl);
    setCopied(true);
    setTimeout(() => setCopied(false), 2500);
  };

  const handleDownloadQR = () => {
    const canvas = document.getElementById('shop-qr-canvas');
    if (canvas) {
      const url = canvas.toDataURL('image/png');
      const a = document.createElement('a');
      a.href = url;
      a.download = `PrintIt-QR-${name || 'Shop'}.png`;
      a.click();
    }
  };

  const handlePrintQRStand = () => {
    window.print();
  };

  return (
    <div className="p-4 md:p-8 h-full flex flex-col max-w-[900px] mx-auto w-full gap-8 overflow-y-auto">
      {/* Header */}
      <div className="flex justify-between items-start border-b border-outline-variant/30 pb-6">
        <div>
          <h1 className="text-3xl font-bold text-on-surface">Shop Settings</h1>
          <p className="text-sm text-on-surface-variant mt-1">Manage counter QR stands, operating hours, store status, and pricing</p>
        </div>
        {successMsg && (
          <div className="bg-green-500/15 border border-green-500/30 text-green-300 px-4 py-2 rounded-xl text-sm font-medium animate-fade-in">
            ✓ {successMsg}
          </div>
        )}
      </div>

      {isLoading ? (
        <div className="flex items-center justify-center py-20">
          <div className="w-8 h-8 border-4 border-primary border-t-transparent rounded-full animate-spin"></div>
        </div>
      ) : (
        <div className="flex flex-col gap-8">

          {/* Section 1: In-Store Counter QR Stand */}
          <div className="bg-gradient-to-br from-primary/10 via-surface-container to-surface-container border border-primary/30 p-6 md:p-8 rounded-3xl shadow-xl flex flex-col md:flex-row items-center gap-8">
            {/* QR Visual */}
            <div className="bg-white p-4 rounded-2xl shadow-2xl flex flex-col items-center justify-center shrink-0 border-4 border-primary">
              <QRCodeSVG
                value={qrDirectUrl}
                size={160}
                level="H"
                includeMargin={true}
              />
              <div style={{ display: 'none' }}>
                <QRCodeCanvas
                  id="shop-qr-canvas"
                  value={qrDirectUrl}
                  size={400}
                  level="H"
                  includeMargin={true}
                />
              </div>
              <span className="text-[10px] font-extrabold text-black uppercase tracking-wider mt-2">Scan & Print Direct</span>
            </div>

            {/* QR Details & Action */}
            <div className="flex-1 space-y-4 text-center md:text-left">
              <div>
                <span className="text-xs font-bold text-primary uppercase tracking-widest bg-primary/10 px-2.5 py-1 rounded-full border border-primary/20">
                  Counter QR Code Stand
                </span>
                <h2 className="text-2xl font-black text-on-surface mt-2">Instant File Upload QR</h2>
                <p className="text-xs text-on-surface-variant leading-relaxed mt-1">
                  Customers scan this QR code with their phone camera to open the web app directly on your shop's upload page — bypassing shop selection.
                </p>
              </div>

              <div className="bg-black/30 border border-outline-variant/30 rounded-xl p-2.5 flex items-center justify-between text-xs text-on-surface-variant font-mono break-all">
                <span className="truncate pr-2">{qrDirectUrl}</span>
                <button
                  type="button"
                  onClick={handleCopyLink}
                  className="px-3 py-1.5 bg-primary text-on-primary font-bold rounded-lg text-xs hover:bg-primary/90 shrink-0 cursor-pointer"
                >
                  {copied ? 'Copied!' : 'Copy'}
                </button>
              </div>

              <div className="flex flex-wrap gap-3 justify-center md:justify-start">
                <button
                  type="button"
                  onClick={handleDownloadQR}
                  className="px-4 py-2 bg-surface-container-high hover:bg-surface-container-highest border border-outline-variant/30 text-on-surface rounded-xl font-bold text-xs flex items-center gap-2 cursor-pointer transition-all"
                >
                  <span className="material-symbols-outlined text-sm">download</span>
                  <span>Download High-Res QR</span>
                </button>
                <button
                  type="button"
                  onClick={handlePrintQRStand}
                  className="px-4 py-2 bg-primary text-on-primary font-bold text-xs rounded-xl flex items-center gap-2 hover:bg-primary/90 cursor-pointer shadow-lg shadow-primary/20 transition-all"
                >
                  <span className="material-symbols-outlined text-sm">print</span>
                  <span>Print Stand Card</span>
                </button>
              </div>
            </div>
          </div>

          {/* Section 2: Quick Status Toggle */}
          <div className="bg-surface-container border border-outline-variant/30 p-6 rounded-2xl shadow-sm flex items-center justify-between">
            <div className="flex items-center gap-4">
              <div className={`w-3.5 h-3.5 rounded-full ${isOpen ? 'bg-green-500 animate-pulse' : 'bg-red-500'}`} />
              <div>
                <h2 className="text-lg font-bold text-on-surface">Store Live Status</h2>
                <p className="text-xs text-on-surface-variant">
                  {isOpen ? 'Your shop is accepting customer print jobs' : 'Your shop is marked closed to new orders'}
                </p>
              </div>
            </div>
            <button
              onClick={handleToggleOpen}
              className={`px-6 py-2.5 rounded-xl font-bold text-sm transition-all cursor-pointer ${
                isOpen 
                  ? 'bg-red-500/15 border border-red-500/30 text-red-400 hover:bg-red-500/25' 
                  : 'bg-green-500/15 border border-green-500/30 text-green-400 hover:bg-green-500/25'
              }`}
            >
              {isOpen ? 'Close Store' : 'Open Store'}
            </button>
          </div>

          {/* Section 3: Shop Profile & Defaults Form */}
          <form onSubmit={handleSaveProfile} className="bg-surface-container border border-outline-variant/30 p-6 rounded-2xl shadow-sm flex flex-col gap-6">
            <div>
              <h2 className="text-lg font-bold text-on-surface">Shop Profile & Operating Hours</h2>
              <p className="text-sm text-on-surface-variant mt-1">Configure your contact details and default pricing rules</p>
            </div>

            <div className="grid grid-cols-1 md:grid-cols-2 gap-6">
              <div className="flex flex-col gap-2">
                <label className="text-xs font-semibold text-on-surface-variant">Shop Display Name</label>
                <input
                  type="text"
                  value={name}
                  onChange={e => setName(e.target.value)}
                  placeholder="e.g. PrintTech Campus Branch"
                  className="bg-black/30 border border-outline-variant/40 rounded-xl px-4 py-2.5 text-on-surface text-sm focus:border-primary outline-none"
                  required
                />
              </div>

              <div className="flex flex-col gap-2">
                <label className="text-xs font-semibold text-on-surface-variant">Contact Phone Number</label>
                <input
                  type="tel"
                  value={phone}
                  onChange={e => setPhone(e.target.value)}
                  placeholder="+91 98765 43210"
                  className="bg-black/30 border border-outline-variant/40 rounded-xl px-4 py-2.5 text-on-surface text-sm focus:border-primary outline-none"
                  required
                />
              </div>

              <div className="flex flex-col gap-2 md:col-span-2">
                <label className="text-xs font-semibold text-on-surface-variant">Shop Physical Address</label>
                <input
                  type="text"
                  value={address}
                  onChange={e => setAddress(e.target.value)}
                  placeholder="e.g. Near Engineering Building Gate 2, Campus"
                  className="bg-black/30 border border-outline-variant/40 rounded-xl px-4 py-2.5 text-on-surface text-sm focus:border-primary outline-none"
                  required
                />
              </div>

              <div className="flex flex-col gap-2">
                <label className="text-xs font-semibold text-on-surface-variant">Default Black & White (₹ / page)</label>
                <input
                  type="number"
                  step="0.10"
                  value={priceBw}
                  onChange={e => setPriceBw(e.target.value)}
                  placeholder="2.00"
                  className="bg-black/30 border border-outline-variant/40 rounded-xl px-4 py-2.5 text-on-surface text-sm focus:border-primary outline-none"
                  required
                />
              </div>

              <div className="flex flex-col gap-2">
                <label className="text-xs font-semibold text-on-surface-variant">Default Full Color (₹ / page)</label>
                <input
                  type="number"
                  step="0.10"
                  value={priceColor}
                  onChange={e => setPriceColor(e.target.value)}
                  placeholder="10.00"
                  className="bg-black/30 border border-outline-variant/40 rounded-xl px-4 py-2.5 text-on-surface text-sm focus:border-primary outline-none"
                  required
                />
              </div>

              <div className="flex flex-col gap-2">
                <label className="text-xs font-semibold text-on-surface-variant">Opening Time</label>
                <input
                  type="time"
                  value={openingTime}
                  onChange={e => setOpeningTime(e.target.value)}
                  className="bg-black/30 border border-outline-variant/40 rounded-xl px-4 py-2.5 text-on-surface text-sm focus:border-primary outline-none"
                />
              </div>

              <div className="flex flex-col gap-2">
                <label className="text-xs font-semibold text-on-surface-variant">Closing Time</label>
                <input
                  type="time"
                  value={closingTime}
                  onChange={e => setClosingTime(e.target.value)}
                  className="bg-black/30 border border-outline-variant/40 rounded-xl px-4 py-2.5 text-on-surface text-sm focus:border-primary outline-none"
                />
              </div>
            </div>

            <div className="flex justify-end pt-4 border-t border-white/5">
              <button
                type="submit"
                disabled={isSaving}
                className="bg-primary text-on-primary font-bold px-6 py-2.5 rounded-xl hover:bg-primary/90 transition-all text-sm disabled:opacity-50 cursor-pointer"
              >
                {isSaving ? 'Saving Changes...' : 'Save Settings'}
              </button>
            </div>
          </form>

          {/* Section 4: Service Capabilities Manager */}
          <div className="bg-surface-container border border-outline-variant/30 p-6 rounded-2xl shadow-sm flex flex-col gap-6">
            <div>
              <h2 className="text-lg font-bold text-on-surface">Service Capabilities</h2>
              <p className="text-sm text-on-surface-variant mt-1">Tag the printing and binding services your shop provides for customer search filtering</p>
            </div>

            <div className="grid grid-cols-1 sm:grid-cols-2 md:grid-cols-4 gap-4">
              {MASTER_CAPABILITIES.map(cap => {
                const isActive = capabilities.includes(cap.id);
                return (
                  <button
                    key={cap.id}
                    type="button"
                    onClick={() => handleToggleCapability(cap.id)}
                    className={`p-4 rounded-xl border text-left flex flex-col gap-2 transition-all cursor-pointer ${
                      isActive 
                        ? 'bg-primary-container/30 border-primary text-on-surface shadow-md' 
                        : 'bg-black/20 border-outline-variant/20 text-on-surface-variant hover:border-outline-variant hover:text-on-surface'
                    }`}
                  >
                    <div className="flex justify-between items-center">
                      <span className={`material-symbols-outlined text-2xl ${isActive ? 'text-primary' : 'opacity-50'}`}>{cap.icon}</span>
                      <span className={`text-xs px-2 py-0.5 rounded-full font-bold uppercase ${
                        isActive ? 'bg-primary text-on-primary' : 'bg-white/10'
                      }`}>
                        {isActive ? 'Active' : 'Off'}
                      </span>
                    </div>
                    <span className="font-bold text-sm">{cap.name}</span>
                    <span className="text-xs opacity-70 leading-tight">{cap.desc}</span>
                  </button>
                );
              })}
            </div>
          </div>

          {/* Section 5: System Information */}
          {profile && (
            <div className="bg-surface-container/60 border border-outline-variant/20 p-6 rounded-2xl text-xs text-on-surface-variant flex flex-col gap-3">
              <h3 className="font-bold uppercase tracking-wider text-on-surface text-sm">System Identifiers</h3>
              <div className="grid grid-cols-1 sm:grid-cols-2 gap-4 font-data-mono">
                <div>Shop ID: <span className="text-on-surface">{profile.shop_id || profile.id || 'N/A'}</span></div>
                <div>Owner ID: <span className="text-on-surface">{profile.owner_id || 'N/A'}</span></div>
              </div>
            </div>
          )}

        </div>
      )}
    </div>
  );
};

export default Settings;
