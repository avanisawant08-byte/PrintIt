import { Routes, Route, Navigate } from 'react-router-dom';
import { useAuth } from './context/AuthContext';

// We will create these pages next
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

const ProtectedRoute = ({ children }) => {
  const { isAuthenticated } = useAuth();
  if (!isAuthenticated) return <Navigate to="/login" replace />;
  return children;
};

function App() {
  return (
    <Routes>
      <Route path="/" element={<Landing />} />
      <Route path="/login" element={<Login />} />
      <Route path="/register" element={<Register />} />
      
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
      </Route>
    </Routes>
  );
}

export default App;
