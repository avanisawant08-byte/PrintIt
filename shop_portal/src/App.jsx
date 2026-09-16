import React, { Suspense, lazy } from 'react';
import { Routes, Route, Navigate } from 'react-router-dom';
import { useAuth } from './context/AuthContext';
import ErrorBoundary from './components/ui/ErrorBoundary';

import Landing from './pages/Landing';
import PageMeta from './components/common/PageMeta';
import CookieBanner from './components/common/CookieBanner';

// Defer loading scripts until needed to minimize initial JavaScript bundle size
const Login = lazy(() => import('./pages/Login'));
const Register = lazy(() => import('./pages/Register'));
const DashboardLayout = lazy(() => import('./pages/dashboard/DashboardLayout'));
const LiveQueue = lazy(() => import('./pages/dashboard/LiveQueue'));
const Orders = lazy(() => import('./pages/dashboard/Orders'));
const MyListings = lazy(() => import('./pages/dashboard/MyListings'));
const ProductOrders = lazy(() => import('./pages/dashboard/ProductOrders'));
const Pricing = lazy(() => import('./pages/dashboard/Pricing'));
const Wallet = lazy(() => import('./pages/dashboard/Wallet'));
const Analytics = lazy(() => import('./pages/dashboard/Analytics'));
const Settings = lazy(() => import('./pages/dashboard/Settings'));
const PrintAgent = lazy(() => import('./pages/dashboard/PrintAgent'));
const Support = lazy(() => import('./pages/dashboard/Support'));

const PrivacyPolicy = lazy(() => import('./pages/legal/PrivacyPolicy'));
const TermsOfService = lazy(() => import('./pages/legal/TermsOfService'));
const RefundCancellationPolicy = lazy(() => import('./pages/legal/RefundCancellationPolicy'));
const SecurityPolicy = lazy(() => import('./pages/legal/SecurityPolicy'));
const AccessibilityStatement = lazy(() => import('./pages/legal/AccessibilityStatement'));

const NotFound = lazy(() => import('./pages/NotFound'));
const Forbidden = lazy(() => import('./pages/Forbidden'));

const PageLoader = () => (
  <div className="min-h-screen flex items-center justify-center bg-background text-on-surface">
    <div className="flex flex-col items-center gap-3">
      <div className="w-8 h-8 rounded-full border-2 border-primary border-t-transparent animate-spin" />
      <span className="text-xs text-on-surface-variant font-mono">Loading...</span>
    </div>
  </div>
);

const ProtectedRoute = ({ children }) => {
  const { isAuthenticated } = useAuth();
  if (!isAuthenticated) return <Navigate to="/login" replace />;
  return children;
};

function App() {
  return (
    <ErrorBoundary>
      <PageMeta />
      <CookieBanner />
      <Suspense fallback={<PageLoader />}>
        <Routes>
          <Route path="/" element={<Landing />} />
          <Route path="/login" element={<Login />} />
          <Route path="/register" element={<Register />} />

          {/* Public Legal & Policy Pages */}
          <Route path="/privacy" element={<PrivacyPolicy />} />
          <Route path="/terms" element={<TermsOfService />} />
          <Route path="/refund-policy" element={<RefundCancellationPolicy />} />
          <Route path="/security" element={<SecurityPolicy />} />
          <Route path="/accessibility" element={<AccessibilityStatement />} />
          <Route path="/403" element={<Forbidden />} />
          
          {/* Protected Dashboard Routes */}
          <Route path="/dashboard" element={<ProtectedRoute><DashboardLayout /></ProtectedRoute>}>
            <Route index element={<Navigate to="/dashboard/queue" replace />} />
            <Route path="queue" element={<LiveQueue />} />
            <Route path="orders" element={<Orders />} />
            <Route path="listings" element={<MyListings />} />
            <Route path="product-orders" element={<ProductOrders />} />
            <Route path="pricing" element={<Pricing />} />
            <Route path="wallet" element={<Wallet />} />
            <Route path="analytics" element={<Analytics />} />
            <Route path="settings" element={<Settings />} />
            <Route path="agent" element={<PrintAgent />} />
            <Route path="support" element={<Support />} />
          </Route>

          {/* 404 Catch-All Route */}
          <Route path="*" element={<NotFound />} />
        </Routes>
      </Suspense>
    </ErrorBoundary>
  );
}

export default App;
