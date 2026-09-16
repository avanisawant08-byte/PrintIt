import { useEffect } from 'react';
import { useLocation } from 'react-router-dom';
import { trackPageView } from '../../core/analytics';

const ROUTE_METADATA = {
  '/': {
    title: 'PrintIt Partner Portal — Print Queue & Vendor Management',
    description: 'Manage live print queues, configure automated pricing rules, verify customer pickups, and track daily revenue with the PrintIt Partner Portal.',
  },
  '/login': {
    title: 'Vendor Sign In | PrintIt Partner Portal',
    description: 'Sign in to your PrintIt vendor account to manage customer orders, pickup queues, and printer configurations.',
  },
  '/register': {
    title: 'Register New Shop — Become a PrintIt Partner',
    description: 'Register your campus print store or stationery shop on PrintIt. Grow your orders and offer instant student pickups.',
  },
  '/privacy': {
    title: 'Privacy Policy | PrintIt',
    description: 'Learn how PrintIt collects, processes, and protects personal and store data under applicable data privacy standards.',
  },
  '/terms': {
    title: 'Terms of Service | PrintIt',
    description: 'Read the terms, conditions, and service level guidelines governing use of the PrintIt printing and marketplace platform.',
  },
  '/refund-policy': {
    title: 'Refund & Cancellation Policy | PrintIt',
    description: 'Detailed information regarding customer cancellations, reprint eligibility, and vendor dispute resolutions on PrintIt.',
  },
  '/security': {
    title: 'Security Policy & Data Protection | PrintIt',
    description: 'Understand PrintIt security controls, role-based access, end-to-end tokenized file transfers, and cloud safeguards.',
  },
  '/accessibility': {
    title: 'Accessibility Statement | PrintIt',
    description: 'PrintIt’s commitment to WCAG 2.1 digital accessibility, keyboard navigability, and inclusive interfaces for all users.',
  },
  '/403': {
    title: '403 Forbidden | PrintIt Partner Portal',
    description: 'You do not have administrative authorization to view this restricted partner section.',
  },
  '/dashboard/queue': {
    title: 'Live Order Queue | PrintIt Partner Dashboard',
    description: 'Real-time print job dispatch queue. View incoming documents, trigger prints, and complete customer pickups.',
  },
  '/dashboard/orders': {
    title: 'Order Fulfillment History | PrintIt Partner Dashboard',
    description: 'View, search, and audit past document print jobs, customer details, and fulfillment timestamps.',
  },
  '/dashboard/listings': {
    title: 'Stationery & Inventory Listings | PrintIt Partner Dashboard',
    description: 'Manage store catalog items, academic stationery products, pricing, and stock levels.',
  },
  '/dashboard/product-orders': {
    title: 'Product Orders & Marketplace | PrintIt Partner Dashboard',
    description: 'Track and fulfill customer stationery orders, manuals, and campus retail purchases.',
  },
  '/dashboard/pricing': {
    title: 'Pricing Matrix & Rate Rules | PrintIt Partner Dashboard',
    description: 'Customize per-page print tariffs, monochrome vs. color, double-sided multipliers, and binding charges.',
  },
  '/dashboard/wallet': {
    title: 'Wallet & Payout Settlements | PrintIt Partner Dashboard',
    description: 'Monitor daily earnings, live balance, bank account settlements, and past payout history.',
  },
  '/dashboard/analytics': {
    title: 'Business Analytics & Revenue | PrintIt Partner Dashboard',
    description: 'Track daily order volume, revenue trajectories, top printing hours, and customer trends.',
  },
  '/dashboard/settings': {
    title: 'Shop Profile & Hardware Settings | PrintIt Partner Dashboard',
    description: 'Update shop operational hours, address, pickup instructions, and automated printer configurations.',
  },
  '/dashboard/agent': {
    title: 'Local Print Agent Status | PrintIt Partner Dashboard',
    description: 'Monitor desktop agent status, secure pairing tokens, and direct CUPS/Windows spooler health.',
  },
  '/dashboard/support': {
    title: 'Help Desk & Support Tickets | PrintIt Partner Dashboard',
    description: 'Submit vendor inquiries, report technical printer issues, and chat directly with PrintIt platform operations.',
  }
};

/**
 * Updates head metadata (title, description, OG, canonical) dynamically on route changes.
 */
export default function PageMeta() {
  const location = useLocation();

  useEffect(() => {
    const meta = ROUTE_METADATA[location.pathname] || (
      location.pathname.startsWith('/dashboard')
        ? {
            title: 'Partner Dashboard | PrintIt',
            description: 'PrintIt Partner Dashboard - Manage orders, queues, and store settings.',
          }
        : {
            title: '404 - Page Not Found | PrintIt',
            description: 'The requested page does not exist on the PrintIt platform.',
          }
    );

    // 1. Update Document Title
    document.title = meta.title;

    // 2. Helper to set or create meta tag
    const updateMetaTag = (attributeName, attributeValue, content) => {
      let element = document.querySelector(`meta[${attributeName}="${attributeValue}"]`);
      if (!element) {
        element = document.createElement('meta');
        element.setAttribute(attributeName, attributeValue);
        document.head.appendChild(element);
      }
      element.setAttribute('content', content);
    };

    // 3. Update Standard Meta Description
    updateMetaTag('name', 'description', meta.description);

    // 4. Update Open Graph Meta Tags
    updateMetaTag('property', 'og:title', meta.title);
    updateMetaTag('property', 'og:description', meta.description);
    updateMetaTag('property', 'og:url', window.location.href);

    // Remove any previously set og:image or twitter:image tags
    const existingOgImg = document.querySelector('meta[property="og:image"]');
    if (existingOgImg) existingOgImg.remove();
    const existingTwImg = document.querySelector('meta[name="twitter:image"]');
    if (existingTwImg) existingTwImg.remove();

    // 5. Update Twitter Card Tags
    updateMetaTag('name', 'twitter:card', 'summary');
    updateMetaTag('name', 'twitter:title', meta.title);
    updateMetaTag('name', 'twitter:description', meta.description);

    // 6. Update Canonical Link
    let canonical = document.querySelector('link[rel="canonical"]');
    if (!canonical) {
      canonical = document.createElement('link');
      canonical.setAttribute('rel', 'canonical');
      document.head.appendChild(canonical);
    }
    canonical.setAttribute('href', window.location.origin + location.pathname);

    // 7. Trigger Analytics Page View
    trackPageView(location.pathname);

  }, [location.pathname]);

  return null;
}
