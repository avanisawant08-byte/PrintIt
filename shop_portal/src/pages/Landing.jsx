import React, { useState, useEffect } from 'react';
import { useNavigate, Link } from 'react-router-dom';
import { trackEvent } from '../core/analytics';

const Landing = () => {
  const navigate = useNavigate();
  const [showStickyCta, setShowStickyCta] = useState(false);

  useEffect(() => {
    const heroBtn = document.getElementById('cta-register-btn');
    if (!heroBtn) return;

    // Use IntersectionObserver to toggle sticky bar when hero CTA leaves viewport
    const observer = new IntersectionObserver(
      ([entry]) => {
        // Show sticky bar only when hero button is not intersecting (scrolled past)
        setShowStickyCta(!entry.isIntersecting);
      },
      { threshold: 0.1 }
    );

    observer.observe(heroBtn);
    return () => observer.disconnect();
  }, []);

  const handleRegisterClick = (source = 'hero') => {
    trackEvent('cta_click_register', { source });
    navigate('/register');
  };

  const handleSignInClick = (source = 'hero') => {
    trackEvent('cta_click_signin', { source });
    navigate('/login');
  };

  return (
    <div className="flex flex-col min-h-screen min-h-[100dvh] justify-between bg-background text-on-background selection:bg-primary/20 selection:text-primary overflow-x-hidden relative pb-16 sm:pb-0">
      {/* Above-the-Fold Header */}
      <header className="w-full max-w-6xl mx-auto px-4 sm:px-6 py-4 flex items-center justify-between z-10">
        <Link to="/" className="flex items-center gap-2.5 sm:gap-3 group">
          <img
            src="/logo_cropped.png"
            alt="PrintIt Logo - Campus Printing Network"
            className="w-9 h-9 sm:w-10 sm:h-10 object-contain rounded-2xl shadow-md group-hover:scale-105 transition-transform"
          />
          <div className="flex flex-col">
            <span className="font-display-lg text-lg sm:text-xl font-bold tracking-tight text-on-surface leading-tight">PrintIt</span>
            <span className="text-[10px] uppercase font-mono tracking-widest text-primary font-semibold -mt-0.5">Partner Network</span>
          </div>
        </Link>
        <div className="flex items-center gap-2 sm:gap-3">
          <button
            onClick={() => handleSignInClick('header')}
            className="min-h-[44px] text-xs sm:text-sm font-semibold text-on-surface-variant hover:text-on-surface px-3 py-2 rounded-xl transition-colors"
          >
            Sign In
          </button>
          <button
            onClick={() => handleRegisterClick('header')}
            className="min-h-[44px] bg-primary hover:bg-primary/90 text-on-primary text-xs sm:text-sm font-semibold px-3.5 sm:px-4 py-2 rounded-xl shadow transition-all hover:-translate-y-0.5 active:scale-95"
          >
            Register Shop
          </button>
        </div>
      </header>

      {/* Main Hero Section — Strictly Above The Fold */}
      <main className="flex-1 flex items-center justify-center px-4 sm:px-6 py-4 sm:py-6">
        <div className="max-w-2xl w-full text-center relative">
          {/* Subtle Ambient Radial Glow */}
          <div className="absolute -top-16 left-1/2 -translate-x-1/2 w-72 sm:w-80 h-72 sm:h-80 bg-primary/15 rounded-full blur-3xl pointer-events-none" />

          <div className="relative bg-surface-container/90 backdrop-blur-xl border border-outline-variant/30 rounded-2xl sm:rounded-3xl p-5 sm:p-10 shadow-2xl">
            {/* Top Category Badge */}
            <div className="inline-flex items-center gap-2 px-3 py-1 rounded-full bg-primary/10 border border-primary/20 text-primary text-[11px] sm:text-xs font-semibold uppercase tracking-wider mb-4 sm:mb-5">
              <span className="w-2 h-2 rounded-full bg-primary animate-ping" />
              <span>Campus Printing & Marketplace Platform</span>
            </div>

            {/* Main Headline */}
            <h1 className="font-display-lg text-2xl xs:text-3xl sm:text-5xl font-black text-on-surface tracking-tight leading-[1.18] mb-3 sm:mb-4">
              Eliminate Queues.{' '}
              <span className="text-transparent bg-clip-text bg-gradient-to-r from-blue-400 via-indigo-300 to-teal-300">
                Maximize Print Revenue.
              </span>
            </h1>

            {/* Sub-Headline */}
            <p className="text-on-surface-variant text-xs sm:text-base leading-relaxed mb-5 sm:mb-6 max-w-lg mx-auto">
              Connect your campus print shop to thousands of students. Accept pre-configured document jobs, verify instant pickups, and automate daily payouts.
            </p>

            {/* Prominent Above-The-Fold CTA Buttons */}
            <div className="flex flex-col sm:flex-row gap-3 justify-center mb-5 sm:mb-6">
              <button
                id="cta-register-btn"
                onClick={() => handleRegisterClick('hero')}
                className="min-h-[48px] bg-primary text-on-primary font-semibold text-sm sm:text-base px-6 sm:px-8 py-3.5 rounded-xl shadow-lg hover:shadow-primary/30 hover:-translate-y-0.5 active:scale-95 transition-all flex items-center justify-center gap-2 group"
              >
                <span>Register Your Shop</span>
                <span className="material-symbols-outlined text-lg group-hover:translate-x-1 transition-transform">arrow_forward</span>
              </button>
              <button
                id="cta-signin-btn"
                onClick={() => handleSignInClick('hero')}
                className="min-h-[48px] bg-surface-container-highest text-on-surface border border-outline-variant/60 hover:bg-surface-variant font-semibold text-sm sm:text-base px-6 sm:px-7 py-3.5 rounded-xl transition-all flex items-center justify-center gap-2 active:scale-95"
              >
                <span className="material-symbols-outlined text-lg">dashboard</span>
                <span>Open Dashboard</span>
              </button>
            </div>

            {/* Trust Badges & Value Points (Immediate Fold Visibility) */}
            <div className="pt-4 sm:pt-5 border-t border-outline-variant/20 grid grid-cols-3 gap-1 sm:gap-2 text-center">
              <div className="flex flex-col items-center">
                <span className="text-primary font-bold text-[11px] sm:text-sm flex items-center gap-1">
                  ⚡ Zero Wait
                </span>
                <span className="text-[10px] sm:text-[11px] text-on-surface-variant/80">Pre-paid queue</span>
              </div>
              <div className="flex flex-col items-center">
                <span className="text-emerald-400 font-bold text-[11px] sm:text-sm flex items-center gap-1">
                  🔒 OTP Pickup
                </span>
                <span className="text-[10px] sm:text-[11px] text-on-surface-variant/80">Zero mix-up</span>
              </div>
              <div className="flex flex-col items-center">
                <span className="text-cyan-400 font-bold text-[11px] sm:text-sm flex items-center gap-1">
                  💸 Payouts
                </span>
                <span className="text-[10px] sm:text-[11px] text-on-surface-variant/80">Direct bank credit</span>
              </div>
            </div>
          </div>
        </div>
      </main>

      {/* Sticky Mobile CTA Bar (Visible only on mobile viewports when hero CTA is scrolled past) */}
      <div
        className={`fixed bottom-0 left-0 right-0 z-40 bg-surface-container/95 backdrop-blur-xl border-t border-outline-variant/40 px-4 py-3 sm:hidden shadow-2xl transition-all duration-300 ${
          showStickyCta ? 'translate-y-0 opacity-100 pointer-events-auto' : 'translate-y-full opacity-0 pointer-events-none'
        }`}
        style={{ paddingBottom: 'calc(0.75rem + env(safe-area-inset-bottom, 0px))' }}
      >
        <div className="flex items-center justify-between gap-3">
          <div className="flex items-center gap-2 overflow-hidden">
            <img src="/logo_cropped.png" alt="PrintIt" className="w-8 h-8 rounded-lg object-contain shrink-0" />
            <div className="truncate">
              <div className="text-xs font-bold text-on-surface truncate">PrintIt Partner</div>
              <div className="text-[10px] text-primary truncate">Start accepting orders</div>
            </div>
          </div>
          <div className="flex items-center gap-2 shrink-0">
            <button
              onClick={() => handleSignInClick('sticky_mobile')}
              className="min-h-[40px] text-xs font-semibold px-3 py-2 rounded-xl bg-surface-container-highest border border-outline-variant/40 text-on-surface"
            >
              Sign In
            </button>
            <button
              onClick={() => handleRegisterClick('sticky_mobile')}
              className="min-h-[40px] text-xs font-semibold px-3.5 py-2 rounded-xl bg-primary text-on-primary shadow"
            >
              Register
            </button>
          </div>
        </div>
      </div>

      {/* Footer */}
      <footer className="border-t border-outline-variant/20 py-4 px-4 text-center text-xs text-on-surface-variant">
        <div className="max-w-5xl mx-auto flex flex-col sm:flex-row items-center justify-between gap-3">
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
