import React from 'react';
import { Outlet, NavLink, useNavigate } from 'react-router-dom';
import { useAuth } from '../context/AuthContext';

const DashboardLayout = () => {
  const { user, logout } = useAuth();
  const navigate = useNavigate();

  const navItems = [
    { name: 'Add Shop', path: '/dashboard/shops/add', icon: 'add_business' },
    { name: 'Payout Management', path: '/dashboard/payouts', icon: 'payments' },
    { name: 'Support Tickets', path: '/dashboard/support', icon: 'support_agent' },
  ];

  const handleLogout = () => {
    logout();
    navigate('/login');
  };

  return (
    <div className="flex-1 flex flex-col h-screen overflow-hidden bg-background font-body-md">
      {/* Top Navigation Bar */}
      <header className="bg-surface-dim text-on-surface flex justify-between items-center px-container-padding py-md w-full sticky top-0 z-50 border-b border-outline-variant/30">
        <div className="flex items-center gap-md">
          <span className="font-headline-lg text-[20px] font-bold text-primary px-4">
            PrintIt | <span className="font-normal opacity-70 text-on-surface">Admin Portal</span>
          </span>
        </div>

        {/* Desktop Nav */}
        <nav className="hidden lg:flex items-center gap-lg">
          {navItems.map(item => (
            <NavLink 
              key={item.path}
              to={item.path} 
              className={({ isActive }) => `flex items-center gap-sm cursor-pointer transition-colors font-semibold ${isActive ? 'text-primary' : 'text-on-surface-variant hover:text-on-surface'}`}
            >
              <span>{item.name}</span>
            </NavLink>
          ))}
        </nav>

        <div className="flex items-center gap-md px-4">
          <div className="flex items-center gap-sm">
            <div className="text-right hidden sm:block">
              <p className="font-label-md text-[10px] leading-none opacity-50 uppercase">Administrator</p>
              <p className="font-body-sm text-body-sm font-semibold">{user?.full_name}</p>
            </div>
          </div>
          <button 
            onClick={handleLogout}
            className="bg-surface-container-highest hover:bg-error-container hover:text-on-error-container transition-all px-4 py-2 rounded-lg font-label-md text-sm border border-outline-variant font-bold"
          >
            LOGOUT
          </button>
        </div>
      </header>

      {/* Main Content */}
      <main className="flex-1 overflow-y-auto bg-surface">
        <Outlet />
      </main>

      {/* Mobile Bottom Navigation */}
      <footer className="lg:hidden flex justify-around items-center px-md pb-md pt-sm bg-surface-container-lowest shadow-lg border-t border-outline-variant/20 overflow-x-auto">
        {navItems.map(item => (
          <NavLink 
            key={item.path}
            to={item.path} 
            className={({ isActive }) => `flex flex-col items-center justify-center flex-shrink-0 px-4 py-2 rounded-xl transition-colors font-semibold ${isActive ? 'bg-primary-container text-on-primary-container' : 'text-outline hover:text-on-surface'}`}
          >
            <span className="text-sm mt-1">{item.name}</span>
          </NavLink>
        ))}
      </footer>
    </div>
  );
};

export default DashboardLayout;
