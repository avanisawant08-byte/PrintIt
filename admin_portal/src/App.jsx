import React, { Suspense, lazy } from 'react';
import { Routes, Route, Navigate } from 'react-router-dom';
import { useAuth } from './context/AuthContext';
import ErrorBoundary from './components/ui/ErrorBoundary';

import Login from './pages/Login';

// Defer loading admin sub-views until required
const DashboardLayout = lazy(() => import('./layouts/DashboardLayout'));
const AddShop = lazy(() => import('./pages/shops/AddShop'));
const TicketList = lazy(() => import('./pages/support/TicketList'));
const TicketDetail = lazy(() => import('./pages/support/TicketDetail'));
const PayoutManagement = lazy(() => import('./pages/PayoutManagement'));
const LegalDocuments = lazy(() => import('./pages/legal/LegalDocuments'));
const ProductCatalog = lazy(() => import('./pages/catalog/ProductCatalog'));
const NotFound = lazy(() => import('./pages/NotFound'));
const Forbidden = lazy(() => import('./pages/Forbidden'));

const PageLoader = () => (
  <div className="h-screen w-screen flex items-center justify-center bg-surface text-on-surface">
    <div className="flex flex-col items-center gap-3">
      <div className="w-8 h-8 rounded-full border-2 border-primary border-t-transparent animate-spin" />
      <span className="text-xs text-on-surface-variant font-mono">Loading...</span>
    </div>
  </div>
);

const ProtectedRoute = ({ children }) => {
  const { isAuthenticated, isLoading } = useAuth();
  if (isLoading) return <PageLoader />;
  if (!isAuthenticated) return <Navigate to="/login" replace />;
  return children;
};

function App() {
  return (
    <ErrorBoundary>
      <Suspense fallback={<PageLoader />}>
        <Routes>
          <Route path="/" element={<Navigate to="/login" replace />} />
          <Route path="/login" element={<Login />} />
          <Route path="/403" element={<Forbidden />} />
          
          <Route path="/dashboard" element={<ProtectedRoute><DashboardLayout /></ProtectedRoute>}>
            <Route index element={<Navigate to="/dashboard/shops/add" replace />} />
            <Route path="shops/add" element={<AddShop />} />
            <Route path="catalog" element={<ProductCatalog />} />
            <Route path="payouts" element={<PayoutManagement />} />
            <Route path="support" element={<TicketList />} />
            <Route path="support/:id" element={<TicketDetail />} />
            <Route path="legal" element={<LegalDocuments />} />
          </Route>

          <Route path="*" element={<NotFound />} />
        </Routes>
      </Suspense>
    </ErrorBoundary>
  );
}

export default App;
