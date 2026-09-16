import React, { useState, useEffect } from 'react';
import { Link } from 'react-router-dom';
import { getConsent, setConsent } from '../../core/analytics';

export default function CookieBanner() {
  const [visible, setVisible] = useState(false);

  useEffect(() => {
    // Only show if user hasn't made a choice yet
    const currentConsent = getConsent();
    if (!currentConsent) {
      const timer = setTimeout(() => setVisible(true), 800);
      return () => clearTimeout(timer);
    }
  }, []);

  if (!visible) return null;

  const handleAcceptAll = () => {
    setConsent('all');
    setVisible(false);
  };

  const handleEssentialOnly = () => {
    setConsent('essential');
    setVisible(false);
  };

  return (
    <aside
      role="region"
      aria-label="Cookie and privacy preferences"
      className="fixed bottom-4 left-4 right-4 sm:left-auto sm:right-6 sm:max-w-md z-50 bg-surface-container/95 backdrop-blur-xl border border-outline-variant/40 rounded-2xl p-5 shadow-2xl animate-fade-in text-on-surface"
    >
      <div className="flex items-start gap-3 mb-3">
        <div className="w-9 h-9 rounded-xl bg-primary/10 border border-primary/20 text-primary flex items-center justify-center shrink-0">
          <span className="material-symbols-outlined text-lg">cookie</span>
        </div>
        <div>
          <h2 className="text-sm font-bold text-on-surface">Cookie & Privacy Preferences</h2>
          <p className="text-xs text-on-surface-variant leading-relaxed mt-1">
            We use essential local storage for authentication and print queue syncing. With your consent, we also use privacy-friendly analytics to improve store operations.
          </p>
        </div>
      </div>

      <div className="flex flex-col sm:flex-row items-stretch sm:items-center justify-between gap-2 pt-2 border-t border-outline-variant/20">
        <Link
          to="/privacy"
          className="text-[11px] text-primary hover:underline self-center sm:self-auto py-1"
        >
          Privacy Policy
        </Link>
        <div className="flex items-center gap-2">
          <button
            onClick={handleEssentialOnly}
            className="flex-1 sm:flex-none text-xs px-3.5 py-2 rounded-xl bg-surface-container-highest hover:bg-surface-variant text-on-surface border border-outline-variant/40 font-medium transition-colors"
          >
            Essential Only
          </button>
          <button
            onClick={handleAcceptAll}
            className="flex-1 sm:flex-none text-xs px-4 py-2 rounded-xl bg-primary hover:bg-primary/90 text-on-primary font-semibold shadow transition-all hover:scale-[1.02]"
          >
            Accept All
          </button>
        </div>
      </div>
    </aside>
  );
}
