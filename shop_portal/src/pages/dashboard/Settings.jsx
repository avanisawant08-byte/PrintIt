import React, { useState, useEffect } from 'react';
import api from '../../core/api';
import { useAuth } from '../../context/AuthContext';

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
      // 1. Try profile endpoint
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
      // Fallback if profile endpoint fails
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

  return (
    <div className="p-4 md:p-8 h-full flex flex-col max-w-[900px] mx-auto w-full gap-8 overflow-y-auto">
      {/* Header */}
      <div className="flex justify-between items-start border-b border-outline-variant/30 pb-6">
        <div>
          <h1 className="text-3xl font-bold text-on-surface">Shop Settings</h1>
          <p className="text-sm text-on-surface-variant mt-1">Manage operating hours, store status, pricing defaults, and service capabilities</p>
        </div>
        {successMsg && (
          <div className="bg-green-500/15 border border-green-500/30 text-green-300 px-4 py-2 rounded-xl text-sm font-medium animate-fade-in">
            ✓ {successMsg}
          </div>
        )}
      </div>

      {isLoading ? (
        <div className="flex-1 flex items-center justify-center text-on-surface-variant py-20">
          <div className="flex flex-col items-center gap-3">
            <div className="w-8 h-8 border-4 border-primary border-t-transparent rounded-full animate-spin"></div>
            <span>Loading shop settings...</span>
          </div>
        </div>
      ) : (
        <div className="flex flex-col gap-8 pb-12">
          
          {/* Section 1: Store Open/Closed Live Status */}
          <div className="bg-surface-container border border-outline-variant/30 p-6 rounded-2xl shadow-sm flex flex-col md:flex-row justify-between items-start md:items-center gap-6">
            <div>
              <div className="flex items-center gap-3">
                <h2 className="text-lg font-bold text-on-surface">Store Live Status</h2>
                <span className={`px-3 py-0.5 rounded-full text-xs font-bold uppercase border ${
                  isOpen ? 'bg-green-500/15 text-green-400 border-green-500/30' : 'bg-red-500/15 text-red-400 border-red-500/30'
                }`}>
                  {isOpen ? '🟢 OPEN FOR ORDERS' : '🔴 CLOSED'}
                </span>
              </div>
              <p className="text-sm text-on-surface-variant mt-1">
                Toggle your store status. When closed, customers cannot place new express orders at your shop.
              </p>
            </div>

            <button
              type="button"
              onClick={handleToggleOpen}
              className={`px-6 py-3 rounded-xl font-bold text-sm transition-all flex items-center gap-2 ${
                isOpen 
                  ? 'bg-green-500/20 text-green-300 border border-green-500/40 hover:bg-green-500/30' 
                  : 'bg-red-500/20 text-red-300 border border-red-500/40 hover:bg-red-500/30'
              }`}
            >
              <span className="material-symbols-outlined">{isOpen ? 'store' : 'storefront'}</span>
              <span>{isOpen ? 'Turn Off (Close Store)' : 'Turn On (Open Store)'}</span>
            </button>
          </div>

          {/* Section 2: Shop Profile & Contact Details */}
          <form onSubmit={handleSaveProfile} className="bg-surface-container border border-outline-variant/30 p-6 rounded-2xl shadow-sm flex flex-col gap-6">
            <h2 className="text-lg font-bold text-on-surface border-b border-white/5 pb-3">Business Information & Operating Hours</h2>

            <div className="grid grid-cols-1 md:grid-cols-2 gap-6">
              {/* Shop Name */}
              <div className="flex flex-col gap-2">
                <label className="text-xs font-semibold uppercase tracking-wider text-on-surface-variant">Shop Name</label>
                <input
                  type="text"
                  value={name}
                  onChange={e => setName(e.target.value)}
                  className="bg-black/30 border border-outline-variant/40 rounded-xl px-4 py-2.5 text-on-surface text-sm focus:border-primary outline-none"
                  placeholder="e.g. Campus Print Hub"
                  required
                />
              </div>

              {/* Contact Phone */}
              <div className="flex flex-col gap-2">
                <label className="text-xs font-semibold uppercase tracking-wider text-on-surface-variant">Contact Phone Number</label>
                <input
                  type="text"
                  value={phone}
                  onChange={e => setPhone(e.target.value)}
                  className="bg-black/30 border border-outline-variant/40 rounded-xl px-4 py-2.5 text-on-surface text-sm focus:border-primary outline-none"
                  placeholder="e.g. +91 9876543210"
                />
              </div>

              {/* Address */}
              <div className="flex flex-col gap-2 md:col-span-2">
                <label className="text-xs font-semibold uppercase tracking-wider text-on-surface-variant">Shop Address</label>
                <input
                  type="text"
                  value={address}
                  onChange={e => setAddress(e.target.value)}
                  className="bg-black/30 border border-outline-variant/40 rounded-xl px-4 py-2.5 text-on-surface text-sm focus:border-primary outline-none"
                  placeholder="e.g. Gate 2, Main Campus Avenue"
                />
              </div>

              {/* Operating Hours */}
              <div className="flex flex-col gap-2">
                <label className="text-xs font-semibold uppercase tracking-wider text-on-surface-variant">Opening Time</label>
                <input
                  type="time"
                  value={openingTime}
                  onChange={e => setOpeningTime(e.target.value)}
                  className="bg-black/30 border border-outline-variant/40 rounded-xl px-4 py-2.5 text-on-surface text-sm focus:border-primary outline-none"
                />
              </div>

              <div className="flex flex-col gap-2">
                <label className="text-xs font-semibold uppercase tracking-wider text-on-surface-variant">Closing Time</label>
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
                className="bg-primary text-on-primary font-bold px-6 py-2.5 rounded-xl hover:bg-primary/90 transition-all text-sm disabled:opacity-50"
              >
                {isSaving ? 'Saving Changes...' : 'Save Settings'}
              </button>
            </div>
          </form>

          {/* Section 3: Service Capabilities Manager */}
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

          {/* Section 4: System Information */}
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
