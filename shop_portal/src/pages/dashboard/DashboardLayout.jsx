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
    { name: 'Live Queue', path: '/dashboard/queue', icon: 'post_add' },
    { name: 'Orders', path: '/dashboard/orders', icon: 'shopping_cart' },
    { name: 'My Listings', path: '/dashboard/listings', icon: 'inventory_2' },
    { name: 'Pricing', path: '/dashboard/pricing', icon: 'payments' },
    { name: 'Wallet & Payouts', path: '/dashboard/wallet', icon: 'account_balance_wallet' },
    { name: 'Analytics', path: '/dashboard/analytics', icon: 'analytics' },
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
    <div className="bg-background text-on-surface font-body-md antialiased min-h-screen flex overflow-hidden w-full relative">
      {/* Background Atmospheric Effect */}
      <div className="fixed inset-0 pointer-events-none z-[-1]">
        <div className="absolute top-[-10%] right-[-5%] w-[40%] h-[40%] rounded-full bg-primary-container/5 blur-[120px]"></div>
        <div className="absolute bottom-[-10%] left-[-5%] w-[40%] h-[40%] rounded-full bg-secondary-container/5 blur-[120px]"></div>
      </div>

      {/* SideNavBar */}
      <aside className="hidden md:flex flex-col h-full fixed left-0 top-0 w-64 rounded-r-xl bg-glass-surface backdrop-blur-xl border-r border-glass-edge shadow-xl shadow-primary/10 z-50">
        {/* Header */}
        <div className="px-5 py-6 border-b border-glass-edge/20 flex items-center gap-3">
          <div className="w-10 h-10 rounded-full bg-surface-container/80 border border-glass-edge shrink-0 flex items-center justify-center">
            <span className="material-symbols-outlined text-primary text-2xl">storefront</span>
          </div>
          <div>
            <h1 className="font-display font-bold text-on-surface text-sm leading-tight tracking-tight">
              PrintIt Shopkeepers Portal
            </h1>
            <p className="text-[11px] text-on-surface-variant/80 font-medium mt-0.5">
              {shopName || user?.name || user?.owner_name || user?.shop_name || 'PrintTech'}
            </p>
          </div>
        </div>

        {/* Main Navigation */}
        <nav className="flex-1 overflow-y-auto py-5 px-3 space-y-1.5">
          {navItems.map((item) => (
            <NavLink
              key={item.path}
              to={item.path}
              className={({ isActive }) =>
                `relative flex items-center gap-3.5 px-4 py-3 rounded-xl text-sm font-medium transition-all duration-200 group ${
                  isActive
                    ? 'text-primary font-semibold bg-primary/10 border border-primary/40 shadow-[0_0_15px_rgba(96,165,250,0.15)]'
                    : 'text-on-surface-variant/80 hover:text-on-surface hover:bg-glass-edge/20'
                }`
              }
            >
              {({ isActive }) => (
                <>
                  {isActive && <div className="absolute left-0 top-2 bottom-2 w-1 bg-primary rounded-r-full"></div>}
                  <span
                    className={`material-symbols-outlined text-[21px] transition-colors ${
                      isActive ? 'text-primary' : 'text-on-surface-variant group-hover:text-primary'
                    }`}
                  >
                    {item.icon}
                  </span>
                  <span className="text-sm font-medium tracking-wide">{item.name}</span>
                </>
              )}
            </NavLink>
          ))}
        </nav>

        {/* Footer Navigation */}
        <div className="mt-auto px-3 pb-6 pt-4 border-t border-glass-edge/20">
          <NavLink
            to="/dashboard/settings"
            className={({ isActive }) =>
              `flex items-center gap-3.5 px-4 py-2.5 rounded-xl text-sm font-medium transition-colors ${
                isActive ? 'text-primary font-semibold bg-primary/10' : 'text-on-surface-variant/80 hover:text-on-surface hover:bg-glass-edge/20'
              }`
            }
          >
            <span className="material-symbols-outlined text-[21px]">settings</span>
            <span className="text-sm font-medium">Settings</span>
          </NavLink>
        </div>
      </aside>

      {/* Main Content Area */}
      <main className="flex-1 ml-0 md:ml-64 h-screen overflow-y-auto scroll-smooth flex flex-col">
        {/* TopAppBar */}
        <header className="sticky top-0 z-40 bg-surface/90 backdrop-blur-md border-b border-glass-edge/20 px-6 md:px-10 h-16 flex items-center justify-between shrink-0">
          {/* Search Input on Left */}
          <div className="relative w-64 sm:w-80">
            <span className="material-symbols-outlined absolute left-3 top-1/2 -translate-y-1/2 text-on-surface-variant pointer-events-none text-[18px]">search</span>
            <input
              type="text"
              value={searchQuery}
              onChange={(e) => setSearchQuery(e.target.value)}
              placeholder="Search orders, jobs..."
              className="w-full bg-surface-container/60 border border-glass-edge/40 rounded-full py-1.5 pl-9 pr-4 text-xs text-on-surface focus:border-primary focus:ring-1 focus:ring-primary outline-none transition-all placeholder:text-on-surface-variant/50"
            />
          </div>

          {/* Right Header Actions: Bell, LOGOUT button, Profile Avatar */}
          <div className="flex items-center gap-5">
            <button className="p-2 rounded-full text-on-surface-variant hover:text-primary hover:bg-surface-container transition-colors focus:ring-2 focus:ring-primary/50 outline-none cursor-pointer">
              <span className="material-symbols-outlined text-[20px]">notifications</span>
            </button>

            <button
              onClick={handleLogout}
              className="flex items-center gap-1 text-xs font-bold text-on-surface-variant/90 hover:text-error transition-colors px-2 py-1 rounded cursor-pointer uppercase tracking-wider"
            >
              <span>LOGOUT</span>
              <span className="material-symbols-outlined text-[18px]">logout</span>
            </button>

            <div className="w-9 h-9 rounded-full bg-surface-container overflow-hidden border border-glass-edge shrink-0">
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
