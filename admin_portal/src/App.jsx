import React from 'react';
import { Routes, Route, Navigate } from 'react-router-dom';
import { useAuth } from './context/AuthContext';

import Login from './pages/Login';
import DashboardLayout from './layouts/DashboardLayout';
import AddShop from './pages/shops/AddShop';
import TicketList from './pages/support/TicketList';
import TicketDetail from './pages/support/TicketDetail';
import PayoutManagement from './pages/PayoutManagement';

const ProtectedRoute = ({ children }) => {
  const { isAuthenticated, isLoading } = useAuth();
  if (isLoading) return <div className="h-screen w-screen flex items-center justify-center bg-surface text-on-surface">Loading...</div>;
  if (!isAuthenticated) return <Navigate to="/login" replace />;
  return children;
};

function App() {
  return (
    <Routes>
      <Route path="/" element={<Navigate to="/login" replace />} />
      <Route path="/login" element={<Login />} />
      
      <Route path="/dashboard" element={<ProtectedRoute><DashboardLayout /></ProtectedRoute>}>
        <Route index element={<Navigate to="/dashboard/shops/add" replace />} />
        <Route path="shops/add" element={<AddShop />} />
        <Route path="payouts" element={<PayoutManagement />} />
        <Route path="support" element={<TicketList />} />
        <Route path="support/:id" element={<TicketDetail />} />
      </Route>
    </Routes>
  );
}

export default App;
