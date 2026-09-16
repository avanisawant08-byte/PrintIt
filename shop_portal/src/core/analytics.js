/**
 * Privacy-compliant analytics module for PrintIt Partner Portal.
 * Respects user cookie/tracking consent stored in localStorage.
 */

const CONSENT_STORAGE_KEY = 'printit_cookie_consent';

export const getConsent = () => {
  try {
    return localStorage.getItem(CONSENT_STORAGE_KEY) || null;
  } catch {
    return null;
  }
};

export const setConsent = (value) => {
  try {
    localStorage.setItem(CONSENT_STORAGE_KEY, value);
    if (value === 'all') {
      initAnalytics();
    }
  } catch (err) {
    console.warn('[Analytics] Could not persist consent:', err);
  }
};

export const hasAnalyticsConsent = () => {
  return getConsent() === 'all';
};

/**
 * Initializes analytics tracking (e.g. Google Analytics or lightweight internal telemetry)
 */
export const initAnalytics = () => {
  if (!hasAnalyticsConsent()) return;

  const gaId = window.ENV?.VITE_GA_ID || import.meta.env?.VITE_GA_ID;
  if (gaId && !window.dataLayer) {
    window.dataLayer = window.dataLayer || [];
    function gtag() { window.dataLayer.push(arguments); }
    window.gtag = gtag;
    gtag('js', new Date());
    gtag('config', gaId, { anonymize_ip: true, send_page_view: false });

    const script = document.createElement('script');
    script.async = true;
    script.src = `https://www.googletagmanager.com/gtag/js?id=${gaId}`;
    document.head.appendChild(script);
    console.log('[Analytics] Google Analytics initialized with ID:', gaId);
  }
};

/**
 * Tracks route / page view changes
 */
export const trackPageView = (path) => {
  if (!hasAnalyticsConsent()) return;

  if (window.gtag) {
    window.gtag('event', 'page_view', {
      page_path: path,
      page_title: document.title,
      page_location: window.location.href,
    });
  }

  // Developer logging in non-production
  if (import.meta.env?.DEV) {
    console.log('[Analytics] Page View:', path, document.title);
  }
};

/**
 * Tracks custom user interactions and conversion goals
 */
export const trackEvent = (eventName, params = {}) => {
  if (!hasAnalyticsConsent()) return;

  if (window.gtag) {
    window.gtag('event', eventName, params);
  }

  if (import.meta.env?.DEV) {
    console.log('[Analytics] Custom Event:', eventName, params);
  }
};

// Automatically attempt initialization on load if user previously granted consent
if (typeof window !== 'undefined' && hasAnalyticsConsent()) {
  initAnalytics();
}
