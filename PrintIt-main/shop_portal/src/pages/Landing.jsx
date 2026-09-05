import React from 'react';
import { useNavigate, Link } from 'react-router-dom';

const Landing = () => {
  const navigate = useNavigate();

  return (
    <div className="flex flex-col min-h-[90vh] justify-between">
      <main className="flex-1 flex items-center justify-center p-4 sm:p-6">
        <div className="max-w-[640px] text-center p-8 sm:p-12 bg-surface-container rounded-2xl border border-outline-variant/30 shadow-2xl">
          <div className="inline-block px-3 py-1 rounded-full bg-primary/10 border border-primary/20 text-primary text-xs font-label-md uppercase tracking-wider mb-6">
            Vendor Operations & Queue Management
          </div>
          <h1 className="font-display-lg text-4xl sm:text-5xl font-extrabold mb-4 text-transparent bg-clip-text bg-gradient-to-br from-tertiary to-primary">
            Partner Portal
          </h1>
          <p className="text-on-surface-variant text-base sm:text-lg leading-relaxed mb-8 max-w-md mx-auto">
            Manage your live print queue, set custom pricing rules, verify customer pickups, and track your revenue.
          </p>
          <div className="flex flex-col sm:flex-row gap-4 justify-center">
            <button 
              onClick={() => navigate('/login')}
              className="bg-primary text-on-primary font-label-md px-8 py-3.5 rounded-xl shadow-lg hover:-translate-y-0.5 transition-transform"
            >
              Sign In to Dashboard
            </button>
            <button 
              onClick={() => navigate('/register')}
              className="bg-surface-container-highest text-on-surface border border-outline-variant hover:bg-surface-variant font-label-md px-8 py-3.5 rounded-xl transition-colors"
            >
              Register New Shop
            </button>
          </div>
        </div>
      </main>

      <footer className="border-t border-outline-variant/20 py-6 px-4 text-center text-xs text-on-surface-variant">
        <div className="max-w-4xl mx-auto flex flex-col sm:flex-row items-center justify-between gap-4">
          <p>© {new Date().getFullYear()} PrintIt Platform. All rights reserved.</p>
          <div className="flex flex-wrap items-center justify-center gap-4 sm:gap-6">
            <Link to="/privacy" className="hover:text-primary transition-colors">Privacy Policy</Link>
            <Link to="/terms" className="hover:text-primary transition-colors">Terms of Service</Link>
            <Link to="/refund-policy" className="hover:text-primary transition-colors">Refund & Cancellation</Link>
            <Link to="/security" className="hover:text-primary transition-colors">Security</Link>
            <Link to="/accessibility" className="hover:text-primary transition-colors">Accessibility</Link>
          </div>
        </div>
      </footer>
    </div>
  );
};

export default Landing;

