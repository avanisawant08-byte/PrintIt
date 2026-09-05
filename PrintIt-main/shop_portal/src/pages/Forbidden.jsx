import React from 'react';
import { useNavigate, Link } from 'react-router-dom';
import { useAuth } from '../context/AuthContext';

const Forbidden = () => {
  const navigate = useNavigate();
  const { logout } = useAuth();

  const handleSwitchAccount = () => {
    logout();
    navigate('/login');
  };

  return (
    <main
      role="main"
      className="min-h-screen bg-background text-on-background flex items-center justify-center p-6"
    >
      <div className="max-w-lg w-full bg-surface-container border border-outline-variant/30 rounded-2xl p-8 sm:p-12 text-center shadow-2xl">
        <div className="w-20 h-20 rounded-3xl bg-error-container/30 text-error flex items-center justify-center mx-auto mb-6 shadow-inner">
          <span className="material-symbols-outlined text-5xl">lock</span>
        </div>
        <span className="text-xs uppercase tracking-widest font-bold text-error mb-2 block font-label-md">
          Error 403
        </span>
        <h1 className="text-3xl font-extrabold text-on-surface mb-3 font-display-lg">
          Access Restricted
        </h1>
        <p className="text-sm text-on-surface-variant mb-8 leading-relaxed max-w-sm mx-auto">
          You do not possess the required vendor authorization privileges to view this portal area.
        </p>
        <div className="flex flex-col sm:flex-row gap-3 justify-center">
          <button
            onClick={handleSwitchAccount}
            className="px-6 py-3 rounded-xl bg-primary text-on-primary text-sm font-medium hover:opacity-90 transition-opacity flex items-center justify-center gap-2 shadow-lg"
          >
            <span className="material-symbols-outlined text-base">switch_account</span>
            <span>Sign In with Vendor Account</span>
          </button>
          <Link
            to="/"
            className="px-6 py-3 rounded-xl bg-surface-container-highest border border-outline-variant text-on-surface text-sm font-medium hover:bg-surface-variant transition-colors flex items-center justify-center gap-2"
          >
            <span>Portal Home</span>
          </Link>
        </div>
      </div>
    </main>
  );
};

export default Forbidden;
