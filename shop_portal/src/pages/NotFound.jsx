import React from 'react';
import { useNavigate, Link } from 'react-router-dom';

const NotFound = () => {
  const navigate = useNavigate();

  return (
    <main
      role="main"
      className="min-h-screen bg-background text-on-background flex flex-col justify-between p-4 sm:p-6"
    >
      <header className="w-full max-w-4xl mx-auto flex items-center justify-between py-4">
        <Link to="/" className="flex items-center gap-3 group">
          <img
            src="/logo_cropped.png"
            alt="PrintIt Logo"
            className="w-9 h-9 object-contain rounded-xl shadow group-hover:scale-105 transition-transform"
          />
          <span className="font-display-lg text-lg font-bold text-on-surface">PrintIt Partner</span>
        </Link>
        <Link
          to="/login"
          className="text-xs font-semibold text-on-surface-variant hover:text-primary transition-colors"
        >
          Sign In &rarr;
        </Link>
      </header>

      <div className="flex-1 flex items-center justify-center py-8">
        <div className="max-w-lg w-full bg-surface-container/90 backdrop-blur-xl border border-outline-variant/30 rounded-3xl p-8 sm:p-12 text-center shadow-2xl relative overflow-hidden">
          {/* Subtle Ambient Glow */}
          <div className="absolute -top-24 left-1/2 -translate-x-1/2 w-64 h-64 bg-primary/15 rounded-full blur-3xl pointer-events-none" />

          {/* Glowing Icon Container */}
          <div className="relative w-20 h-20 rounded-2xl bg-surface-container-highest text-primary flex items-center justify-center mx-auto mb-6 shadow-inner border border-outline-variant/20">
            <span className="material-symbols-outlined text-4xl text-primary animate-pulse">search_off</span>
          </div>

          <div className="inline-flex items-center gap-2 px-3.5 py-1 rounded-full bg-primary/10 border border-primary/25 text-primary text-xs font-mono font-semibold tracking-wider uppercase mb-3">
            Error 404
          </div>

          <h1 className="text-3xl sm:text-4xl font-extrabold text-on-surface mb-3 font-display-lg tracking-tight">
            Page Not Found
          </h1>

          <p className="text-sm sm:text-base text-on-surface-variant mb-8 leading-relaxed max-w-md mx-auto">
            The partner page or queue you are attempting to reach has either been moved, renamed, or is temporarily offline.
          </p>

          <div className="flex flex-col sm:flex-row gap-3 justify-center mb-6">
            <button
              onClick={() => navigate(-1)}
              className="px-5 py-3 rounded-xl bg-surface-container-highest border border-outline-variant text-on-surface text-sm font-medium hover:bg-surface-variant transition-colors flex items-center justify-center gap-2 shadow-sm"
            >
              <span className="material-symbols-outlined text-base">arrow_back</span>
              <span>Go Back</span>
            </button>
            <Link
              to="/"
              className="px-6 py-3 rounded-xl bg-primary text-on-primary text-sm font-semibold hover:opacity-90 transition-opacity flex items-center justify-center gap-2 shadow-lg hover:shadow-primary/25"
            >
              <span className="material-symbols-outlined text-base">home</span>
              <span>Partner Home</span>
            </Link>
          </div>

          <div className="pt-6 border-t border-outline-variant/20 flex flex-wrap items-center justify-center gap-4 text-xs text-on-surface-variant">
            <span>Need assistance?</span>
            <Link to="/dashboard/support" className="text-primary hover:underline font-medium">
              Vendor Support
            </Link>
            <span>&bull;</span>
            <Link to="/terms" className="hover:text-on-surface transition-colors">
              Platform Terms
            </Link>
          </div>
        </div>
      </div>

      <footer className="w-full max-w-4xl mx-auto text-center py-4 text-xs text-on-surface-variant/70">
        &copy; {new Date().getFullYear()} PrintIt Platform. All rights reserved.
      </footer>
    </main>
  );
};

export default NotFound;
