import React, { useState } from 'react';
import { useNavigate, Link } from 'react-router-dom';
import { useAuth } from '../context/AuthContext';
import api from '../core/api';
import { trackEvent } from '../core/analytics';

const Login = () => {
  const [email, setEmail] = useState('');
  const [password, setPassword] = useState('');
  const [fieldErrors, setFieldErrors] = useState({});
  const [isLoading, setIsLoading] = useState(false);
  const [error, setError] = useState('');
  const isSessionExpired = typeof window !== 'undefined' && window.location.search.includes('expired=true');
  
  const navigate = useNavigate();
  const { login } = useAuth();

  const validate = () => {
    const errors = {};
    const emailRegex = /^[^\s@]+@[^\s@]+\.[^\s@]+$/;
    if (!email.trim()) {
      errors.email = 'Email address is required';
    } else if (!emailRegex.test(email.trim())) {
      errors.email = 'Please enter a valid email address';
    }

    if (!password) {
      errors.password = 'Password is required';
    } else if (password.length < 6) {
      errors.password = 'Password must be at least 6 characters';
    }

    setFieldErrors(errors);
    return Object.keys(errors).length === 0;
  };

  const handleLogin = async (e) => {
    e.preventDefault();
    setError('');

    if (!validate()) {
      return;
    }

    setIsLoading(true);

    try {
      const res = await api.post('/auth/login', { email: email.trim(), password });
      const { token, user } = res.data;
      
      if (user.role !== 'shopkeeper') {
        setError('Access denied. This account does not have shop owner permissions.');
        setIsLoading(false);
        return;
      }
      
      // Immediately save token and user state
      login(token, user, '');
      trackEvent('vendor_login_success', { user_id: user.user_id });

      // Attempt to fetch shop details to display shop name & short shop code
      try {
        const shopsRes = await api.get('/public/shops');
        const shopsList = Array.isArray(shopsRes.data) ? shopsRes.data : (shopsRes.data?.data || []);
        const myShop = shopsList.find(s => s.owner_id === user.user_id);
        if (myShop?.name) {
          login(token, user, myShop.name, myShop.shop_code || '');
        }
      } catch (e) {
        console.warn('Could not fetch shop name for header:', e.message);
      }
      
      navigate('/dashboard/queue');
    } catch (err) {
      const serverError = err.response?.data;
      const errorMsg = serverError?.details 
        ? `${serverError.error}: ${serverError.details}`
        : (serverError?.error || err.message || 'Unable to connect to service. Please try again.');
      setError(errorMsg);
      trackEvent('vendor_login_failed', { reason: errorMsg });
    } finally {
      setIsLoading(false);
    }
  };

  return (
    <div className="flex-1 flex items-center justify-center min-h-screen min-h-[100dvh] p-4 sm:p-6 bg-background text-on-background">
      <div className="w-full max-w-[420px] bg-surface-container border border-outline-variant/30 rounded-2xl p-6 sm:p-8 shadow-2xl relative">
        <div className="text-center mb-6 sm:mb-8 flex flex-col items-center">
          <Link to="/" className="inline-block focus:outline-none focus:ring-2 focus:ring-primary rounded-xl mb-3">
            <img
              src="/logo_cropped.png"
              alt="PrintIt Logo - Campus Printing Platform"
              className="w-14 h-14 object-contain rounded-xl drop-shadow-md hover:scale-105 transition-transform"
            />
          </Link>
          <h1 className="font-headline-lg text-primary mb-1 text-2xl font-bold leading-tight min-h-[32px]">
            Welcome Back
          </h1>
          <p className="text-on-surface-variant text-xs sm:text-sm min-h-[20px]">
            Sign in to manage your campus print queue
          </p>
        </div>
        
        {isSessionExpired && (
          <div role="status" aria-live="polite" className="bg-amber-500/15 text-amber-300 p-3.5 rounded-xl mb-5 text-xs sm:text-sm border border-amber-500/30 text-center flex items-center justify-center gap-2">
            <span className="material-symbols-outlined text-base text-amber-400">info</span>
            <span>Your session has expired. Please sign in again.</span>
          </div>
        )}

        {error && (
          <div role="alert" className="bg-rose-500/15 text-rose-300 p-3.5 rounded-xl mb-5 text-xs sm:text-sm border border-rose-500/30 flex items-start gap-2.5">
            <span className="material-symbols-outlined text-base text-rose-400 shrink-0 mt-0.5">error</span>
            <span className="leading-snug">{error}</span>
          </div>
        )}

        <form onSubmit={handleLogin} noValidate className="flex flex-col gap-4">
          <div>
            <label htmlFor="login-email" className="block text-xs font-semibold text-on-surface-variant mb-1.5 uppercase tracking-wider">
              Email Address
            </label>
            <div className="relative">
              <input 
                id="login-email"
                type="email" 
                required
                disabled={isLoading}
                value={email}
                aria-invalid={!!fieldErrors.email}
                aria-describedby={fieldErrors.email ? 'email-error' : undefined}
                onChange={e => {
                  setEmail(e.target.value);
                  if (fieldErrors.email) setFieldErrors(prev => ({ ...prev, email: '' }));
                }}
                className={`w-full bg-surface-container-highest border rounded-xl px-4 py-3 text-sm text-on-surface focus:outline-none transition-all disabled:opacity-60 ${
                  fieldErrors.email 
                    ? 'border-rose-500/80 focus:border-rose-500 focus:ring-2 focus:ring-rose-500/20' 
                    : 'border-outline-variant/50 focus:border-primary focus:ring-2 focus:ring-primary/20'
                }`}
                placeholder="owner@shop.com"
                autoComplete="email"
              />
              {fieldErrors.email && (
                <span className="material-symbols-outlined text-rose-400 absolute right-3 top-3 text-lg pointer-events-none">
                  warning
                </span>
              )}
            </div>
            {fieldErrors.email && (
              <p id="email-error" role="alert" className="text-xs text-rose-400 mt-1.5 flex items-center gap-1">
                <span>{fieldErrors.email}</span>
              </p>
            )}
          </div>

          <div>
            <div className="flex items-center justify-between mb-1.5">
              <label htmlFor="login-password" className="block text-xs font-semibold text-on-surface-variant uppercase tracking-wider">
                Password
              </label>
            </div>
            <div className="relative">
              <input 
                id="login-password"
                type="password" 
                required
                disabled={isLoading}
                value={password}
                aria-invalid={!!fieldErrors.password}
                aria-describedby={fieldErrors.password ? 'password-error' : undefined}
                onChange={e => {
                  setPassword(e.target.value);
                  if (fieldErrors.password) setFieldErrors(prev => ({ ...prev, password: '' }));
                }}
                className={`w-full bg-surface-container-highest border rounded-xl px-4 py-3 text-sm text-on-surface focus:outline-none transition-all disabled:opacity-60 ${
                  fieldErrors.password 
                    ? 'border-rose-500/80 focus:border-rose-500 focus:ring-2 focus:ring-rose-500/20' 
                    : 'border-outline-variant/50 focus:border-primary focus:ring-2 focus:ring-primary/20'
                }`}
                placeholder="••••••••"
                autoComplete="current-password"
              />
              {fieldErrors.password && (
                <span className="material-symbols-outlined text-rose-400 absolute right-3 top-3 text-lg pointer-events-none">
                  warning
                </span>
              )}
            </div>
            {fieldErrors.password && (
              <p id="password-error" role="alert" className="text-xs text-rose-400 mt-1.5 flex items-center gap-1">
                <span>{fieldErrors.password}</span>
              </p>
            )}
          </div>
          
          <button 
            type="submit" 
            disabled={isLoading}
            className="w-full min-h-[48px] bg-primary text-on-primary font-semibold text-sm sm:text-base py-3.5 rounded-xl mt-3 shadow-lg hover:shadow-primary/30 hover:-translate-y-0.5 active:scale-95 transition-all disabled:opacity-50 disabled:pointer-events-none flex items-center justify-center gap-2"
          >
            {isLoading ? (
              <>
                <div className="w-5 h-5 border-2 border-on-primary border-t-transparent rounded-full animate-spin" />
                <span>Verifying credentials...</span>
              </>
            ) : (
              <span>Access Dashboard</span>
            )}
          </button>
        </form>
        
        <div className="mt-8 pt-6 border-t border-outline-variant/20 text-center">
          <p className="text-on-surface-variant text-xs sm:text-sm mb-3">
            New print vendor?{' '}
            <Link to="/register" className="text-primary font-semibold hover:underline">
              Register your shop
            </Link>
          </p>
          <div className="flex items-center justify-center gap-4 text-xs text-on-surface-variant/70">
            <Link to="/privacy" className="hover:text-primary transition-colors">Privacy Policy</Link>
            <span>•</span>
            <Link to="/terms" className="hover:text-primary transition-colors">Terms of Service</Link>
          </div>
        </div>
      </div>
    </div>
  );
};

export default Login;
