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
  const [isLoading, setIsLoading] = useState(true);

  useEffect(() => {
    // If we have a token but missing user details (or just as a check)
    // For now we just trust the localStorage state. 
    setIsLoading(false);
  }, []);

  const login = (tokenData, userData, shopNameData = '') => {
    setToken(tokenData);
    setUser(userData);
    setShopName(shopNameData);
    localStorage.setItem('token', tokenData);
    localStorage.setItem('user', JSON.stringify(userData));
    localStorage.setItem('shopName', shopNameData);
  };

  const logout = () => {
    setToken(null);
    setUser(null);
    setShopName('');
    localStorage.removeItem('token');
    localStorage.removeItem('user');
    localStorage.removeItem('shopName');
  };

  const value = {
    token,
    user,
    shopName,
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
