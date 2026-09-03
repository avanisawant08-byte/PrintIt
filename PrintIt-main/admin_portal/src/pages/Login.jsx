import React, { useState } from 'react';
import { useNavigate } from 'react-router-dom';
import { useAuth } from '../context/AuthContext';
import api from '../core/api';

const Login = () => {
  const [email, setEmail] = useState('');
  const [password, setPassword] = useState('');
  const [isLoading, setIsLoading] = useState(false);
  const [error, setError] = useState('');
  
  const navigate = useNavigate();
  const { login } = useAuth();

  const handleLogin = async (e) => {
    e.preventDefault();
    setIsLoading(true);
    setError('');

    try {
      const res = await api.post('/auth/login', { email, password });
      const { token, user } = res.data;
      
      if (user.role !== 'admin') {
        setError('Access denied. Not an admin account.');
        setIsLoading(false);
        return;
      }
      
      login(token, user);
      navigate('/dashboard/shops/add');
    } catch (err) {
      const serverError = err.response?.data;
      const errorMsg = serverError?.details 
        ? `${serverError.error}: ${serverError.details}`
        : (serverError?.error || err.message);
      setError(errorMsg);
    } finally {
      setIsLoading(false);
    }
  };

  return (
    <div className="flex-1 flex items-center justify-center min-h-[100vh] bg-surface">
      <div className="w-full max-w-[400px] bg-surface-container border border-outline-variant/30 rounded-xl p-8 shadow-2xl">
        <div className="text-center mb-8">
          <h2 className="font-headline-lg text-primary mb-2 text-2xl font-bold">Admin Portal</h2>
          <p className="text-on-surface-variant font-body-sm">Sign in to manage system operations</p>
        </div>
        
        {error && (
          <div className="bg-error-container/20 text-error p-3 rounded-lg mb-6 text-sm border border-error/30 text-center">
            {error}
          </div>
        )}

        <form onSubmit={handleLogin} className="flex flex-col gap-4">
          <div>
            <label className="block text-label-md text-on-surface-variant mb-2">Email Address</label>
            <input 
              type="email" 
              required
              value={email}
              onChange={e => setEmail(e.target.value)}
              className="w-full bg-surface-container-highest border border-outline-variant/50 rounded-lg px-4 py-3 text-on-surface focus:outline-none focus:border-primary focus:ring-1 focus:ring-primary transition-colors"
              placeholder="admin@printit.com"
            />
          </div>
          <div>
            <label className="block text-label-md text-on-surface-variant mb-2">Password</label>
            <input 
              type="password" 
              required
              value={password}
              onChange={e => setPassword(e.target.value)}
              className="w-full bg-surface-container-highest border border-outline-variant/50 rounded-lg px-4 py-3 text-on-surface focus:outline-none focus:border-primary focus:ring-1 focus:ring-primary transition-colors"
              placeholder="••••••••"
            />
          </div>
          
          <button 
            type="submit" 
            disabled={isLoading}
            className="w-full bg-primary text-on-primary font-label-md py-4 rounded-lg mt-4 shadow-lg hover:-translate-y-0.5 transition-transform disabled:opacity-50 flex items-center justify-center font-bold"
          >
            {isLoading ? 'Signing In...' : 'Secure Login'}
          </button>
        </form>
      </div>
    </div>
  );
};

export default Login;
