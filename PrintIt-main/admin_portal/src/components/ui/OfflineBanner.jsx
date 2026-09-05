import React, { useState, useEffect } from 'react';

const OfflineBanner = () => {
  const [isOffline, setIsOffline] = useState(
    typeof navigator !== 'undefined' ? !navigator.onLine : false
  );

  useEffect(() => {
    const handleOnline = () => setIsOffline(false);
    const handleOffline = () => setIsOffline(true);

    window.addEventListener('online', handleOnline);
    window.addEventListener('offline', handleOffline);

    return () => {
      window.removeEventListener('online', handleOnline);
      window.removeEventListener('offline', handleOffline);
    };
  }, []);

  if (!isOffline) return null;

  return (
    <div
      role="alert"
      aria-live="assertive"
      className="bg-amber-500/90 text-slate-950 px-4 py-2 text-center text-xs sm:text-sm font-semibold flex items-center justify-center gap-2 sticky top-0 z-50 shadow-md backdrop-blur-md"
    >
      <span className="material-symbols-outlined text-lg">wifi_off</span>
      <span>Administrator console is offline. Verify your network connection before approving payouts.</span>
      <button
        onClick={() => window.location.reload()}
        className="ml-3 underline hover:no-underline font-bold"
      >
        Retry
      </button>
    </div>
  );
};

export default OfflineBanner;
