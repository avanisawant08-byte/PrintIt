import { Routes, Route, Navigate } from 'react-router-dom';
import { useAuth } from './context/AuthContext';
import ErrorBoundary from './components/ui/ErrorBoundary';

import Landing from './pages/Landing';
import Login from './pages/Login';
import Register from './pages/Register';
import DashboardLayout from './pages/dashboard/DashboardLayout';
import LiveQueue from './pages/dashboard/LiveQueue';
import Orders from './pages/dashboard/Orders';
import MyListings from './pages/dashboard/MyListings';
import ProductOrders from './pages/dashboard/ProductOrders';
import Pricing from './pages/dashboard/Pricing';
import Wallet from './pages/dashboard/Wallet';
import Analytics from './pages/dashboard/Analytics';
import Settings from './pages/dashboard/Settings';
import Support from './pages/dashboard/Support';

import PrivacyPolicy from './pages/legal/PrivacyPolicy';
import TermsOfService from './pages/legal/TermsOfService';
import RefundCancellationPolicy from './pages/legal/RefundCancellationPolicy';
import SecurityPolicy from './pages/legal/SecurityPolicy';
import AccessibilityStatement from './pages/legal/AccessibilityStatement';

import NotFound from './pages/NotFound';
import Forbidden from './pages/Forbidden';

const ProtectedRoute = ({ children }) => {
  const { isAuthenticated } = useAuth();
  if (!isAuthenticated) return <Navigate to="/login" replace />;
  return children;
};

function App() {
  return (
    <ErrorBoundary>
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
          <Route path="support" element={<Support />} />
        </Route>

        {/* 404 Catch-All Route */}
        <Route path="*" element={<NotFound />} />
      </Routes>
    </ErrorBoundary>
  );
}

export default App;
