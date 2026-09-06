import React, { createContext, useContext, useState, useEffect } from 'react';
import api from '../core/api';

const AuthContext = createContext();

export const useAuth = () => useContext(AuthContext);

export const AuthProvider = ({ children }) => {
  const [token, setToken] = useState(localStorage.getItem('token') || null);
  const [user, setUser] = useState(() => {
    const savedUser = localStorage.getItem('user');
    return savedUser ? JSON.parse(savedUser) : null;
  });
  const [shopName, setShopName] = useState(localStorage.getItem('shopName') || '');
  const [shopCode, setShopCode] = useState(localStorage.getItem('shopCode') || '');
  const [isLoading, setIsLoading] = useState(true);

  useEffect(() => {
    // If authenticated, refresh shop details (name & shop_code)
    if (token) {
      api.get('/shop/profile')
        .then((res) => {
          if (res.data) {
            if (res.data.shop_code) {
              setShopCode(res.data.shop_code);
              localStorage.setItem('shopCode', res.data.shop_code);
            }
            if (res.data.name) {
              setShopName(res.data.name);
              localStorage.setItem('shopName', res.data.name);
            }
          }
        })
        .catch((err) => console.warn('AuthContext profile sync:', err.message))
        .finally(() => setIsLoading(false));
    } else {
      setIsLoading(false);
    }
  }, [token]);

  const login = (tokenData, userData, shopNameData = '', shopCodeData = '') => {
    setToken(tokenData);
    setUser(userData);
    setShopName(shopNameData);
    setShopCode(shopCodeData);
    localStorage.setItem('token', tokenData);
    localStorage.setItem('user', JSON.stringify(userData));
    localStorage.setItem('shopName', shopNameData);
    if (shopCodeData) {
      localStorage.setItem('shopCode', shopCodeData);
    }
  };

  const logout = () => {
    setToken(null);
    setUser(null);
    setShopName('');
    setShopCode('');
    localStorage.removeItem('token');
    localStorage.removeItem('user');
    localStorage.removeItem('shopName');
    localStorage.removeItem('shopCode');
  };

  const value = {
    token,
    user,
    shopName,
    shopCode,
    setShopCode,
    setShopName,
    login,
    logout,
    isAuthenticated: !!token,
  };

  if (isLoading) {
    return <div>Loading...</div>; // Could be a nicer loading state
  }

  return (
    <AuthContext.Provider value={value}>
      {children}
    </AuthContext.Provider>
  );
};
