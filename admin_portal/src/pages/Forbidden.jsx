import React from 'react';
import { useNavigate } from 'react-router-dom';
import { useAuth } from '../context/AuthContext';

const Forbidden = () => {
  const navigate = useNavigate();
  const { logout } = useAuth();

  const handleSwitch = () => {
    logout();
    navigate('/login');
  };

  return (
    <main
      role="main"
      className="min-h-screen bg-surface-dim text-on-surface flex items-center justify-center p-6 font-body-md"
    >
      <div className="max-w-lg w-full bg-surface border border-outline-variant/30 rounded-2xl p-8 sm:p-12 text-center shadow-2xl">
        <div className="w-20 h-20 rounded-3xl bg-error-container text-on-error-container flex items-center justify-center mx-auto mb-6">
          <span className="material-symbols-outlined text-5xl">gpp_bad</span>
        </div>
        <span className="text-xs uppercase tracking-widest font-bold text-error mb-2 block font-label-md">
          Error 403
        </span>
        <h1 className="text-3xl font-extrabold text-on-surface mb-3">
          Super-Admin Access Required
        </h1>
        <p className="text-sm text-on-surface-variant mb-8 leading-relaxed max-w-sm mx-auto">
          Your current session does not hold super-administrator credentials. Please sign in with an authorized platform administrator account.
        </p>
        <div className="flex justify-center">
          <button
            onClick={handleSwitch}
            className="px-6 py-3 rounded-xl bg-primary text-on-primary text-sm font-bold hover:opacity-90 transition-opacity flex items-center justify-center gap-2 shadow-lg"
          >
            <span className="material-symbols-outlined text-base">login</span>
            <span>Sign In as Admin</span>
          </button>
        </div>
      </div>
    </main>
  );
};

export default Forbidden;
