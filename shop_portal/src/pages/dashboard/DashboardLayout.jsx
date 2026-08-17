import React, { useState, useEffect } from 'react';
import { Outlet, NavLink, useNavigate } from 'react-router-dom';
import { useAuth } from '../../context/AuthContext';

const DashboardLayout = () => {
  const { user, shopName, logout } = useAuth();
  const navigate = useNavigate();
  const [time, setTime] = useState(new Date());

  useEffect(() => {
    const timer = setInterval(() => setTime(new Date()), 1000);
    return () => clearInterval(timer);
  }, []);

  const navItems = [
    { name: 'Live Queue', path: '/dashboard/queue', icon: 'view_list' },
    { name: 'Orders', path: '/dashboard/orders', icon: 'receipt_long' },
    { name: 'My Listings', path: '/dashboard/listings', icon: 'inventory' },
    { name: 'Product Orders', path: '/dashboard/product-orders', icon: 'shopping_cart' },
    { name: 'Pricing', path: '/dashboard/pricing', icon: 'payments' },
    { name: 'Wallet & Payouts', path: '/dashboard/wallet', icon: 'account_balance_wallet' },
    { name: 'Analytics', path: '/dashboard/analytics', icon: 'analytics' },
    { name: 'Settings', path: '/dashboard/settings', icon: 'settings' },
  ];

  const handleLogout = () => {
    logout();
    navigate('/');
  };

  return (
    <div className="flex-1 flex flex-col h-screen overflow-hidden">
      {/* Top Navigation Bar */}
      <header className="bg-surface-dim text-on-surface flex justify-between items-center px-container-padding py-md w-full sticky top-0 z-50 border-b border-outline-variant/30">
        <div className="flex items-center gap-md">
          <span className="font-headline-lg text-[20px] font-bold text-on-surface">
            PrintIt | <span className="font-normal opacity-70">Shop Portal</span>
          </span>
          <div className="h-6 w-[1px] bg-outline-variant mx-sm hidden sm:block"></div>
          <div className="hidden sm:flex items-center gap-sm bg-surface-container-high px-sm py-xs rounded-lg">
            <span className="text-tertiary material-symbols-outlined text-[18px]" style={{ fontVariationSettings: "'FILL' 1" }}>bolt</span>
            <span className="font-label-md text-label-md text-tertiary">EXPRESS MODE</span>
            <button className="w-8 h-4 bg-tertiary rounded-full relative ml-xs">
              <div className="absolute right-0.5 top-0.5 w-3 h-3 bg-on-tertiary rounded-full"></div>
            </button>
          </div>
        </div>

        {/* Desktop Nav */}
        <nav className="hidden lg:flex items-center gap-lg">
          {navItems.map(item => (
            <NavLink 
              key={item.path}
              to={item.path} 
              className={({ isActive }) => `flex items-center gap-sm cursor-pointer transition-colors ${isActive ? 'text-primary' : 'text-on-surface-variant hover:text-on-surface'}`}
            >
              <span className="material-symbols-outlined">{item.icon}</span>
              <span className="font-label-md text-label-md">{item.name}</span>
            </NavLink>
          ))}
        </nav>

        <div className="flex items-center gap-md">
          <div className="hidden md:flex flex-col items-end px-md border-l border-outline-variant/30">
            <p className="font-data-mono text-[14px] text-primary">{time.toLocaleTimeString()}</p>
            <p className="font-label-md text-[8px] tracking-[0.2em] opacity-40">UTC SYNC</p>
          </div>
          <div className="flex items-center gap-sm">
            <div className="text-right hidden sm:block">
              <p className="font-label-md text-[10px] leading-none opacity-50 uppercase">{shopName || 'Shop'}</p>
              <p className="font-body-sm text-body-sm font-semibold">{user?.full_name}</p>
            </div>
            <span className="material-symbols-outlined text-primary" style={{ fontVariationSettings: "'FILL' 1" }}>account_circle</span>
          </div>
          <button 
            onClick={handleLogout}
            className="bg-surface-container-highest hover:bg-error-container hover:text-on-error-container transition-all px-md py-xs rounded-lg font-label-md text-label-md border border-outline-variant"
          >
            LOGOUT
          </button>
        </div>
      </header>

      {/* Main Content */}
      <main className="flex-1 overflow-y-auto">
        <Outlet />
      </main>

      {/* Mobile Bottom Navigation */}
      <footer className="lg:hidden flex justify-around items-center px-md pb-md pt-sm bg-surface-container-lowest shadow-lg border-t border-outline-variant/20 overflow-x-auto">
        {navItems.map(item => (
          <NavLink 
            key={item.path}
            to={item.path} 
            className={({ isActive }) => `flex flex-col items-center justify-center flex-shrink-0 px-4 py-2 rounded-xl transition-colors ${isActive ? 'bg-primary-container text-on-primary-container' : 'text-outline hover:text-on-surface'}`}
          >
            <span className="material-symbols-outlined">{item.icon}</span>
            <span className="font-label-md text-[10px] mt-1">{item.name}</span>
          </NavLink>
        ))}
      </footer>
    </div>
  );
};

export default DashboardLayout;
