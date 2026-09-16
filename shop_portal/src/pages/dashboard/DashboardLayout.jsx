import React, { useState } from 'react';
import { Outlet, NavLink, useNavigate, Link } from 'react-router-dom';
import { useAuth } from '../../context/AuthContext';
import NewPrintJobModal from '../../components/NewPrintJobModal';
import OfflineBanner from '../../components/ui/OfflineBanner';
import ThemeToggle from '../../components/ui/ThemeToggle';

const DashboardLayout = () => {
  const { user, shopName, shopCode, logout } = useAuth();
  const navigate = useNavigate();
  const [searchQuery, setSearchQuery] = useState('');
  const [showNewJobModal, setShowNewJobModal] = useState(false);
  const [copiedCode, setCopiedCode] = useState(false);

  const displayCode = shopCode || 'PR8473';

  const handleCopyShopCode = (e) => {
    e?.stopPropagation();
    if (displayCode) {
      navigator.clipboard.writeText(displayCode);
      setCopiedCode(true);
      setTimeout(() => setCopiedCode(false), 2000);
    }
  };

  const navItems = [
    { name: 'Live Queue', path: '/dashboard/queue', icon: 'post_add' },
    { name: 'Orders', path: '/dashboard/orders', icon: 'shopping_cart' },
    { name: 'My Listings', path: '/dashboard/listings', icon: 'inventory_2' },
    { name: 'Pricing', path: '/dashboard/pricing', icon: 'payments' },
    { name: 'Wallet & Payouts', path: '/dashboard/wallet', icon: 'account_balance_wallet' },
    { name: 'Analytics', path: '/dashboard/analytics', icon: 'analytics' },
    { name: 'Print Agent', path: '/dashboard/agent', icon: 'print_connect' },
    { name: 'Support & FAQ', path: '/dashboard/support', icon: 'help_outline' },
  ];

  const handleLogout = () => {
    logout();
    navigate('/');
  };

  const handleCreateJobSubmit = (jobData) => {
    alert(`✅ New Print Job Created Successfully!\nDocument: ${jobData.file ? jobData.file.name : 'Document.pdf'}\nTotal: ₹${jobData.totalPrice}`);
    navigate('/dashboard/queue');
  };

  return (
    <div className="bg-background text-on-surface font-body-md antialiased min-h-screen flex w-full relative">
      {/* SideNavBar - Optimized for all desktop ratios (1366x768, 1080p, 1440p) */}
      <aside className="hidden md:flex flex-col h-screen fixed left-0 top-0 bottom-0 w-60 lg:w-64 bg-glass-surface backdrop-blur-xl border-r border-glass-edge shadow-xl z-50">
        {/* Header */}
        <div className="px-5 py-4 border-b border-glass-edge/20 flex items-center gap-3 shrink-0">
          <div className="w-10 h-10 rounded-xl bg-surface-container border border-glass-edge/40 shrink-0 flex items-center justify-center overflow-hidden p-1 shadow-sm">
            <img src="/logo_cropped.png" alt="PrintIt Logo" className="w-full h-full object-contain" />
          </div>
          <div className="overflow-hidden">
            <h1 className="font-display font-bold text-on-surface text-sm leading-tight tracking-tight truncate">
              PrintIt Shopkeeper
            </h1>
            <p className="text-[11px] text-on-surface-variant/80 font-medium mt-0.5 truncate">
              {shopName || user?.name || user?.owner_name || user?.shop_name || 'PrintTech'}
            </p>
          </div>
        </div>

        {/* Main Navigation */}
        <nav className="flex-1 overflow-y-auto py-3 px-3 space-y-1">
          {navItems.map((item) => (
            <NavLink
              key={item.path}
              to={item.path}
              className={({ isActive }) =>
                `relative flex items-center gap-3 px-3.5 py-2.5 rounded-xl text-xs lg:text-sm font-medium transition-all duration-200 group ${
                  isActive
                    ? 'text-primary font-bold bg-primary/10 border border-primary/40'
                    : 'text-on-surface-variant/80 hover:text-on-surface hover:bg-glass-edge/20'
                }`
              }
            >
              {({ isActive }) => (
                <>
                  {isActive && <div className="absolute left-0 top-2 bottom-2 w-1 bg-primary rounded-r-full"></div>}
                  <span
                    className={`material-symbols-outlined text-[20px] transition-colors ${
                      isActive ? 'text-primary' : 'text-on-surface-variant group-hover:text-primary'
                    }`}
                  >
                    {item.icon}
                  </span>
                  <span className="truncate tracking-wide">{item.name}</span>
                </>
              )}
            </NavLink>
          ))}
        </nav>

        {/* Footer Navigation */}
        <div className="mt-auto px-3 pb-4 pt-3 border-t border-glass-edge/20 space-y-2 shrink-0">
          <NavLink
            to="/dashboard/settings"
            className={({ isActive }) =>
              `flex items-center gap-3 px-3.5 py-2.5 rounded-xl text-xs lg:text-sm font-medium transition-colors ${
                isActive ? 'text-primary font-bold bg-primary/10 border border-primary/40' : 'text-on-surface-variant/80 hover:text-on-surface hover:bg-glass-edge/20'
              }`
            }
          >
            <span className="material-symbols-outlined text-[20px]">settings</span>
            <span>Shop Settings</span>
          </NavLink>

          <div className="pt-2 border-t border-glass-edge/10 px-2 flex flex-wrap gap-x-3 gap-y-1 text-[10px] text-on-surface-variant/60">
            <Link to="/privacy" className="hover:text-primary transition-colors">Privacy</Link>
            <Link to="/terms" className="hover:text-primary transition-colors">Terms</Link>
            <Link to="/refund-policy" className="hover:text-primary transition-colors">Refunds</Link>
            <Link to="/accessibility" className="hover:text-primary transition-colors">A11y</Link>
          </div>
        </div>
      </aside>

      {/* Main Content Area */}
      <div className="flex-1 ml-0 md:ml-60 lg:ml-64 min-h-screen flex flex-col w-full min-w-0">
        <OfflineBanner />

        {/* Top Header Bar */}
        <header className="sticky top-0 z-40 bg-surface/95 backdrop-blur-md border-b border-glass-edge/20 px-4 sm:px-6 lg:px-8 h-16 flex items-center justify-between shrink-0">
          {/* Search Input on Left */}
          <div className="relative w-56 sm:w-72 lg:w-80">
            <span className="material-symbols-outlined absolute left-3 top-1/2 -translate-y-1/2 text-on-surface-variant pointer-events-none text-[18px]">search</span>
            <input
              type="text"
              value={searchQuery}
              onChange={(e) => setSearchQuery(e.target.value)}
              placeholder="Search orders, jobs..."
              className="w-full bg-surface-container/60 border border-glass-edge/40 rounded-full py-1.5 pl-9 pr-4 text-xs text-on-surface focus:border-primary focus:ring-1 focus:ring-primary outline-none transition-all placeholder:text-on-surface-variant/50"
            />
          </div>

          {/* Right Header Actions: Shop Code Pill, Notification Bell, ThemeToggle, Logout button */}
          <div className="flex items-center gap-2 sm:gap-4 shrink-0">
            <ThemeToggle />
            {displayCode && (
              <div 
                onClick={handleCopyShopCode}
                title="Click to copy Short Shop Code for in-store customers"
                className="flex items-center gap-2 px-3 py-1.5 rounded-full bg-surface-container border border-primary/30 hover:border-primary/60 cursor-pointer shadow-sm transition-all group"
              >
                <span className="material-symbols-outlined text-primary text-[17px] group-hover:scale-110 transition-transform">pin</span>
                <div className="flex items-center gap-1.5">
                  <span className="text-[10px] uppercase font-bold text-on-surface-variant hidden sm:inline">Counter Code:</span>
                  <span className="font-mono font-black text-primary text-xs tracking-wider">{displayCode}</span>
                </div>
                <span className="text-[10px] text-on-surface-variant group-hover:text-primary font-medium ml-0.5 flex items-center gap-0.5">
                  <span className="material-symbols-outlined text-[13px]">{copiedCode ? 'check' : 'content_copy'}</span>
                  <span className="hidden md:inline">{copiedCode ? 'Copied!' : 'Copy'}</span>
                </span>
              </div>
            )}

            <button
              onClick={handleLogout}
              className="flex items-center gap-1 text-xs font-bold text-on-surface-variant hover:text-error transition-colors px-2 py-1 rounded cursor-pointer uppercase tracking-wider"
              title="Logout from shopkeeper portal"
            >
              <span className="hidden sm:inline">LOGOUT</span>
              <span className="material-symbols-outlined text-[18px]">logout</span>
            </button>

            <div className="w-9 h-9 rounded-full bg-surface-container overflow-hidden border border-glass-edge shrink-0">
              <img
                alt="Partner Profile Avatar"
                width="36"
                height="36"
                loading="eager"
                decoding="async"
                className="w-full h-full object-cover"
                src="https://lh3.googleusercontent.com/aida-public/AB6AXuAnOR0laNrpSOZQsExvk0rVxT_PFmJFukviA6Vgm9OGL6Y1JAkhl36GswjuFEUrvH0A_DnCy4cb0yp9PweO76qFa28BJrCyVMCXoc2XwPPkpvf_Oh3iAXaQbiRxBqJ743bn6My5qxCTW8MHh9mIPxTgQdpFz_HlMMybfgSelqyoc45D1GdeMCwrk7jQrXi8EhrbE3yyG6FeMG_LbF1Pn1TfsrNkvJArrP4eRhtjnlqRx7WMlXUVHBTBAA"
              />
            </div>
          </div>
        </header>

        {/* Router View Container - Responsive across 1366x768 & 1080p */}
        <main className="flex-1 p-4 sm:p-6 lg:p-8 pb-24 sm:pb-28 w-full max-w-7xl mx-auto flex flex-col min-w-0">
          <Outlet context={{ searchQuery, setSearchQuery, onOpenNewJobModal: () => setShowNewJobModal(true) }} />
        </main>
      </div>

      {/* New Print Job Modal */}
      {showNewJobModal && (
        <NewPrintJobModal
          onClose={() => setShowNewJobModal(false)}
          onSubmitJob={handleCreateJobSubmit}
        />
      )}

      {/* Mobile Bottom Navigation Bar */}
      <footer className="md:hidden fixed bottom-0 left-0 right-0 h-16 bg-glass-surface backdrop-blur-xl border-t border-glass-edge flex justify-around items-center px-2 z-50 overflow-x-auto">
        {navItems.map((item) => (
          <NavLink
            key={item.path}
            to={item.path}
            className={({ isActive }) =>
              `flex flex-col items-center justify-center px-2 py-1 rounded-lg transition-colors flex-shrink-0 ${
                isActive ? 'text-primary font-bold' : 'text-on-surface-variant'
              }`
            }
          >
            <span className="material-symbols-outlined text-[20px]">{item.icon}</span>
            <span className="text-[9px] font-label-sm mt-0.5">{item.name}</span>
          </NavLink>
        ))}
      </footer>
    </div>
  );
};

export default DashboardLayout;
