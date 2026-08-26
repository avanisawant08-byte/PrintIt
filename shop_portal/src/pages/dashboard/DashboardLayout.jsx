import React, { useState } from 'react';
import { Outlet, NavLink, useNavigate, useLocation } from 'react-router-dom';
import { useAuth } from '../../context/AuthContext';
import NewPrintJobModal from '../../components/NewPrintJobModal';

const DashboardLayout = () => {
  const { user, shopName, logout } = useAuth();
  const navigate = useNavigate();
  const location = useLocation();
  const [searchQuery, setSearchQuery] = useState('');
  const [showNewJobModal, setShowNewJobModal] = useState(false);

  const navItems = [
    { name: 'Live Queue', path: '/dashboard/queue', icon: 'queue_play_next' },
    { name: 'Orders', path: '/dashboard/orders', icon: 'shopping_bag' },
    { name: 'My Listings', path: '/dashboard/listings', icon: 'list_alt' },
    { name: 'Product Orders', path: '/dashboard/product-orders', icon: 'shopping_cart' },
    { name: 'Pricing', path: '/dashboard/pricing', icon: 'payments' },
    { name: 'Wallet & Payouts', path: '/dashboard/wallet', icon: 'account_balance_wallet' },
    { name: 'Analytics', path: '/dashboard/analytics', icon: 'leaderboard' },
    { name: 'Settings', path: '/dashboard/settings', icon: 'settings' },
  ];

  const handleLogout = () => {
    logout();
    navigate('/');
  };

  const getPageTitle = () => {
    const currentPath = location.pathname;
    if (currentPath.includes('/wallet')) return 'Shopkeeper Wallet & Payouts';
    if (currentPath.includes('/queue')) return 'Order Workflow & Live Queue';
    if (currentPath.includes('/orders')) return 'Order History & Status';
    if (currentPath.includes('/listings')) return 'My Products & Listings';
    if (currentPath.includes('/pricing')) return 'Pricing & Catalog';
    if (currentPath.includes('/analytics')) return 'Performance Analytics';
    if (currentPath.includes('/settings')) return 'Shop Settings';
    return 'Shopkeeper Portal';
  };

  const handleCreateJobSubmit = (jobData) => {
    alert(`✅ New Print Job Created Successfully!\nDocument: ${jobData.file ? jobData.file.name : 'Document.pdf'}\nTotal: ₹${jobData.totalPrice}`);
    navigate('/dashboard/queue');
  };

  return (
    <div className="bg-background text-on-surface font-body-md antialiased min-h-screen flex overflow-hidden w-full relative">
      {/* Background Atmospheric Effect */}
      <div className="fixed inset-0 pointer-events-none z-[-1]">
        <div className="absolute top-[-10%] right-[-5%] w-[40%] h-[40%] rounded-full bg-primary-container/5 blur-[120px]"></div>
        <div className="absolute bottom-[-10%] left-[-5%] w-[40%] h-[40%] rounded-full bg-secondary-container/5 blur-[120px]"></div>
      </div>

      {/* SideNavBar */}
      <aside className="hidden md:flex flex-col h-full fixed left-0 top-0 w-64 rounded-r-xl bg-glass-surface backdrop-blur-xl border-r border-glass-edge shadow-xl shadow-primary/10 z-50">
        {/* Header */}
        <div className="px-6 py-6 border-b border-glass-edge/20 flex items-center gap-4">
          <div className="w-10 h-10 rounded-lg bg-surface-container flex items-center justify-center border border-glass-edge shrink-0">
            <span className="material-symbols-outlined text-primary text-2xl">storefront</span>
          </div>
          <div>
            <h1 className="text-headline-md font-display font-bold text-primary text-xl leading-tight">
              Shopkeeper Pro
            </h1>
            <p className="text-label-sm font-label-sm text-on-surface-variant">
              {shopName || 'Merchant Portal'}
            </p>
          </div>
        </div>

        {/* Main Navigation */}
        <nav className="flex-1 overflow-y-auto py-6 px-2 space-y-1">
          {navItems.map((item) => (
            <NavLink
              key={item.path}
              to={item.path}
              className={({ isActive }) =>
                `relative flex items-center gap-3 px-4 py-3 rounded-lg font-medium transition-all duration-300 group ${
                  isActive
                    ? 'text-primary font-bold bg-primary/10 scale-[0.99] opacity-90'
                    : 'text-on-surface-variant/70 hover:text-on-surface hover:bg-glass-edge/20 hover:backdrop-blur-2xl'
                }`
              }
            >
              {({ isActive }) => (
                <>
                  {isActive && <div className="nav-indicator"></div>}
                  <span
                    className={`material-symbols-outlined text-[20px] transition-colors ${
                      isActive ? 'text-primary' : 'group-hover:text-primary'
                    }`}
                    style={{ fontVariationSettings: isActive ? "'FILL' 1" : "'FILL' 0" }}
                  >
                    {item.icon}
                  </span>
                  <span className="text-label-md font-label-md">{item.name}</span>
                </>
              )}
            </NavLink>
          ))}
        </nav>

        {/* Footer Navigation */}
        <div className="mt-auto px-2 pb-6 pt-4 border-t border-glass-edge/20 space-y-2">
          <button
            onClick={() => setShowNewJobModal(true)}
            className="w-full bg-primary hover:bg-primary-container text-on-primary font-label-md text-label-md py-2.5 px-4 rounded-lg transition-colors flex items-center justify-center gap-2 shadow-[0_0_15px_rgba(96,165,250,0.3)] font-bold cursor-pointer active:scale-[0.98]"
          >
            <span className="material-symbols-outlined text-sm">add</span>
            New Print Job
          </button>

          <button
            onClick={handleLogout}
            className="w-full flex items-center justify-center gap-2 px-4 py-2.5 text-error hover:bg-error/10 hover:text-error transition-colors rounded-lg font-label-md text-label-md border border-error/20 cursor-pointer active:scale-[0.98]"
          >
            <span className="material-symbols-outlined text-sm">logout</span>
            Logout
          </button>
        </div>
      </aside>

      {/* Main Content Area */}
      <main className="flex-1 ml-0 md:ml-64 h-screen overflow-y-auto scroll-smooth flex flex-col">
        {/* TopAppBar */}
        <header className="sticky top-0 z-40 bg-surface/80 backdrop-blur-md border-b border-glass-edge/20 px-4 md:px-margin-desktop h-20 flex items-center justify-between shrink-0">
          <div>
            <h2 className="text-headline-md font-headline-md font-bold text-primary text-xl md:text-2xl">
              {getPageTitle()}
            </h2>
          </div>

          <div className="flex items-center gap-4">
            {/* Search Input */}
            <div className="relative w-48 sm:w-64 hidden sm:block">
              <span className="material-symbols-outlined absolute left-3 top-1/2 -translate-y-1/2 text-on-surface-variant pointer-events-none text-[18px]">search</span>
              <input
                type="text"
                value={searchQuery}
                onChange={(e) => setSearchQuery(e.target.value)}
                placeholder="Search orders, jobs..."
                className="w-full bg-surface-container border border-glass-edge rounded-full py-1.5 pl-9 pr-4 text-xs font-label-sm text-on-surface focus:border-primary focus:ring-1 focus:ring-primary outline-none transition-all placeholder:text-outline"
              />
            </div>

            <button className="p-2 rounded-full text-on-surface-variant hover:text-primary hover:bg-surface-container transition-colors focus:ring-2 focus:ring-primary/50 outline-none cursor-pointer">
              <span className="material-symbols-outlined text-[20px]">notifications</span>
            </button>

            <button className="p-2 rounded-full text-on-surface-variant hover:text-primary hover:bg-surface-container transition-colors focus:ring-2 focus:ring-primary/50 outline-none cursor-pointer">
              <span className="material-symbols-outlined text-[20px]">chat_bubble</span>
            </button>

            <div className="w-10 h-10 rounded-full bg-surface-container overflow-hidden border border-glass-edge shrink-0 hidden sm:block">
              <img
                alt="User Avatar"
                className="w-full h-full object-cover"
                src="https://lh3.googleusercontent.com/aida-public/AB6AXuAnOR0laNrpSOZQsExvk0rVxT_PFmJFukviA6Vgm9OGL6Y1JAkhl36GswjuFEUrvH0A_DnCy4cb0yp9PweO76qFa28BJrCyVMCXoc2XwPPkpvf_Oh3iAXaQbiRxBqJ743bn6My5qxCTW8MHh9mIPxTgQdpFz_HlMMybfgSelqyoc45D1GdeMCwrk7jQrXi8EhrbE3yyG6FeMG_LbF1Pn1TfsrNkvJArrP4eRhtjnlqRx7WMlXUVHBTBAA"
              />
            </div>
          </div>
        </header>

        {/* Router View Container */}
        <div className="flex-1 p-4 md:p-margin-desktop md:pt-8 w-full max-w-7xl mx-auto flex flex-col">
          <Outlet context={{ searchQuery, setSearchQuery, onOpenNewJobModal: () => setShowNewJobModal(true) }} />
        </div>
      </main>

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
