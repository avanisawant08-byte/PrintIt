import React, { useState } from 'react';
import { useNavigate, Link } from 'react-router-dom';
import api from '../core/api';
import { trackEvent } from '../core/analytics';

const Register = () => {
  const [formData, setFormData] = useState({
    full_name: '', email: '', phone: '', password: '', 
    shop_name: '', address: '', price_bw: 2, price_color: 10
  });
  const [fieldErrors, setFieldErrors] = useState({});
  const [isLoading, setIsLoading] = useState(false);
  const [error, setError] = useState('');
  const [success, setSuccess] = useState('');
  
  const navigate = useNavigate();

  const handleChange = (e) => {
    const { name, value } = e.target;
    setFormData(prev => ({ ...prev, [name]: value }));
    if (fieldErrors[name]) {
      setFieldErrors(prev => ({ ...prev, [name]: '' }));
    }
  };

  const validate = () => {
    const errors = {};
    if (!formData.full_name.trim()) errors.full_name = 'Full name is required';
    
    const emailRegex = /^[^\s@]+@[^\s@]+\.[^\s@]+$/;
    if (!formData.email.trim()) {
      errors.email = 'Email address is required';
    } else if (!emailRegex.test(formData.email.trim())) {
      errors.email = 'Please enter a valid email address';
    }

    if (!formData.phone.trim()) {
      errors.phone = 'Phone number is required';
    } else if (!/^\+?[\d\s-]{10,15}$/.test(formData.phone.trim())) {
      errors.phone = 'Enter a valid 10-digit phone number';
    }

    if (!formData.password) {
      errors.password = 'Password is required';
    } else if (formData.password.length < 6) {
      errors.password = 'Password must be at least 6 characters';
    }

    if (!formData.shop_name.trim()) errors.shop_name = 'Shop name is required';
    if (!formData.address.trim()) errors.address = 'Store address is required';

    setFieldErrors(errors);
    return Object.keys(errors).length === 0;
  };

  const handleRegister = async (e) => {
    e.preventDefault();
    setError('');
    setSuccess('');

    if (!validate()) {
      return;
    }

    setIsLoading(true);
    trackEvent('vendor_register_attempt', { shop_name: formData.shop_name });

    try {
      const payload = {
        ...formData,
        email: formData.email.trim(),
        price_bw: parseFloat(formData.price_bw),
        price_color: parseFloat(formData.price_color)
      };
      
      await api.post('/auth/register-shop', payload);
      setSuccess('Shop registered successfully! Redirecting you to sign in...');
      trackEvent('vendor_register_success', { shop_name: formData.shop_name });
      setTimeout(() => navigate('/login'), 1500);
    } catch (err) {
      const serverError = err.response?.data;
      const errorMsg = serverError?.details 
        ? `${serverError.error}: ${serverError.details}` 
        : (serverError?.error || err.message || 'Registration failed. Please try again.');
      setError(errorMsg);
      trackEvent('vendor_register_failed', { reason: errorMsg });
    } finally {
      setIsLoading(false);
    }
  };

  const getInputClass = (fieldName) => {
    return `w-full bg-surface-container-highest border rounded-xl px-4 py-3 text-sm text-on-surface focus:outline-none transition-all disabled:opacity-60 ${
      fieldErrors[fieldName]
        ? 'border-rose-500/80 focus:border-rose-500 focus:ring-2 focus:ring-rose-500/20'
        : 'border-outline-variant/50 focus:border-primary focus:ring-2 focus:ring-primary/20'
    }`;
  };

  return (
    <div className="flex-1 flex items-center justify-center min-h-screen min-h-[100dvh] py-8 sm:py-12 px-4 sm:px-6 bg-background text-on-background">
      <div className="w-full max-w-[660px] bg-surface-container border border-outline-variant/30 rounded-2xl p-6 sm:p-10 shadow-2xl my-auto relative">
        <div className="text-center mb-6 sm:mb-8 flex flex-col items-center">
          <Link to="/" className="inline-block focus:outline-none focus:ring-2 focus:ring-primary rounded-xl mb-3">
            <img
              src="/logo_cropped.png"
              alt="PrintIt Logo - Campus Printing Platform"
              className="w-14 h-14 object-contain rounded-xl drop-shadow-md hover:scale-105 transition-transform"
            />
          </Link>
          <h1 className="font-headline-lg text-primary text-2xl sm:text-3xl font-bold tracking-tight mb-1">
            Register Your Shop
          </h1>
          <p className="text-on-surface-variant text-xs sm:text-sm">
            Join the PrintIt vendor network and receive automated campus orders
          </p>
        </div>
        
        {error && (
          <div role="alert" className="bg-rose-500/15 text-rose-300 p-3.5 rounded-xl mb-6 text-xs sm:text-sm border border-rose-500/30 flex items-start gap-2.5">
            <span className="material-symbols-outlined text-base text-rose-400 shrink-0 mt-0.5">error</span>
            <span className="leading-snug">{error}</span>
          </div>
        )}

        {success && (
          <div role="status" className="bg-emerald-500/15 text-emerald-300 p-3.5 rounded-xl mb-6 text-xs sm:text-sm border border-emerald-500/30 flex items-start gap-2.5">
            <span className="material-symbols-outlined text-base text-emerald-400 shrink-0 mt-0.5">check_circle</span>
            <span className="leading-snug">{success}</span>
          </div>
        )}

        <form onSubmit={handleRegister} noValidate className="flex flex-col gap-6">
          {/* Section 1: Owner Details */}
          <div>
            <div className="flex items-center gap-2 mb-3 pb-1 border-b border-outline-variant/20">
              <span className="w-5 h-5 rounded-full bg-primary/20 text-primary text-xs flex items-center justify-center font-bold font-mono">1</span>
              <h2 className="text-xs font-bold text-primary uppercase tracking-wider">Owner Profile</h2>
            </div>
            
            <div className="flex flex-col gap-3.5">
              <div>
                <label className="block text-xs font-semibold text-on-surface-variant mb-1.5 uppercase tracking-wider">
                  Full Name
                </label>
                <input 
                  type="text" 
                  name="full_name" 
                  required
                  disabled={isLoading}
                  value={formData.full_name} 
                  onChange={handleChange} 
                  className={getInputClass('full_name')}
                  placeholder="Rahul Sharma" 
                />
                {fieldErrors.full_name && (
                  <p role="alert" className="text-xs text-rose-400 mt-1 flex items-center gap-1">{fieldErrors.full_name}</p>
                )}
              </div>

              <div className="grid grid-cols-1 sm:grid-cols-2 gap-3.5">
                <div>
                  <label className="block text-xs font-semibold text-on-surface-variant mb-1.5 uppercase tracking-wider">
                    Email Address
                  </label>
                  <input 
                    type="email" 
                    name="email" 
                    required
                    disabled={isLoading}
                    value={formData.email} 
                    onChange={handleChange} 
                    className={getInputClass('email')}
                    placeholder="owner@shop.com" 
                  />
                  {fieldErrors.email && (
                    <p role="alert" className="text-xs text-rose-400 mt-1 flex items-center gap-1">{fieldErrors.email}</p>
                  )}
                </div>
                <div>
                  <label className="block text-xs font-semibold text-on-surface-variant mb-1.5 uppercase tracking-wider">
                    Phone Number
                  </label>
                  <input 
                    type="tel" 
                    name="phone" 
                    required
                    disabled={isLoading}
                    value={formData.phone} 
                    onChange={handleChange} 
                    className={getInputClass('phone')}
                    placeholder="9876543210" 
                  />
                  {fieldErrors.phone && (
                    <p role="alert" className="text-xs text-rose-400 mt-1 flex items-center gap-1">{fieldErrors.phone}</p>
                  )}
                </div>
              </div>

              <div>
                <label className="block text-xs font-semibold text-on-surface-variant mb-1.5 uppercase tracking-wider">
                  Password (min. 6 characters)
                </label>
                <input 
                  type="password" 
                  name="password" 
                  required
                  disabled={isLoading}
                  value={formData.password} 
                  onChange={handleChange} 
                  className={getInputClass('password')}
                  placeholder="••••••••" 
                />
                {fieldErrors.password && (
                  <p role="alert" className="text-xs text-rose-400 mt-1 flex items-center gap-1">{fieldErrors.password}</p>
                )}
              </div>
            </div>
          </div>

          {/* Section 2: Shop Information */}
          <div>
            <div className="flex items-center gap-2 mb-3 pb-1 border-b border-outline-variant/20">
              <span className="w-5 h-5 rounded-full bg-primary/20 text-primary text-xs flex items-center justify-center font-bold font-mono">2</span>
              <h2 className="text-xs font-bold text-primary uppercase tracking-wider">Shop Information</h2>
            </div>
            
            <div className="flex flex-col gap-3.5">
              <div>
                <label className="block text-xs font-semibold text-on-surface-variant mb-1.5 uppercase tracking-wider">
                  Shop Name
                </label>
                <input 
                  type="text" 
                  name="shop_name" 
                  required
                  disabled={isLoading}
                  value={formData.shop_name} 
                  onChange={handleChange} 
                  className={getInputClass('shop_name')}
                  placeholder="Campus Xerox & Print Hub" 
                />
                {fieldErrors.shop_name && (
                  <p role="alert" className="text-xs text-rose-400 mt-1 flex items-center gap-1">{fieldErrors.shop_name}</p>
                )}
              </div>
              <div>
                <label className="block text-xs font-semibold text-on-surface-variant mb-1.5 uppercase tracking-wider">
                  Store Address / Campus Landmark
                </label>
                <input 
                  type="text" 
                  name="address" 
                  required
                  disabled={isLoading}
                  value={formData.address} 
                  onChange={handleChange} 
                  className={getInputClass('address')}
                  placeholder="Gate 2, Academic Block A, University Campus" 
                />
                {fieldErrors.address && (
                  <p role="alert" className="text-xs text-rose-400 mt-1 flex items-center gap-1">{fieldErrors.address}</p>
                )}
              </div>
            </div>
          </div>

          {/* Section 3: Base Pricing */}
          <div>
            <div className="flex items-center gap-2 mb-3 pb-1 border-b border-outline-variant/20">
              <span className="w-5 h-5 rounded-full bg-primary/20 text-primary text-xs flex items-center justify-center font-bold font-mono">3</span>
              <h2 className="text-xs font-bold text-primary uppercase tracking-wider">Default Rate Card (₹ per page)</h2>
            </div>
            
            <div className="grid grid-cols-1 sm:grid-cols-2 gap-3.5">
              <div>
                <label className="block text-xs font-semibold text-on-surface-variant mb-1.5 uppercase tracking-wider">
                  Black & White (A4)
                </label>
                <input 
                  type="number" 
                  name="price_bw" 
                  min="0.5" 
                  step="0.5" 
                  required
                  disabled={isLoading}
                  value={formData.price_bw} 
                  onChange={handleChange} 
                  className="w-full bg-surface-container-highest border border-outline-variant/50 rounded-xl px-4 py-3 text-sm text-on-surface focus:outline-none focus:border-primary focus:ring-2 focus:ring-primary/20" 
                />
              </div>
              <div>
                <label className="block text-xs font-semibold text-on-surface-variant mb-1.5 uppercase tracking-wider">
                  Colour (A4)
                </label>
                <input 
                  type="number" 
                  name="price_color" 
                  min="1" 
                  step="0.5" 
                  required
                  disabled={isLoading}
                  value={formData.price_color} 
                  onChange={handleChange} 
                  className="w-full bg-surface-container-highest border border-outline-variant/50 rounded-xl px-4 py-3 text-sm text-on-surface focus:outline-none focus:border-primary focus:ring-2 focus:ring-primary/20" 
                />
              </div>
            </div>
          </div>

          <p className="text-xs text-on-surface-variant text-center my-1 leading-relaxed">
            By completing registration, you agree to PrintIt's{' '}
            <Link to="/terms" className="text-primary font-semibold hover:underline">Terms of Service</Link>{' '}
            and{' '}
            <Link to="/privacy" className="text-primary font-semibold hover:underline">Privacy Policy</Link>.
          </p>

          <button 
            type="submit" 
            disabled={isLoading}
            className="w-full min-h-[48px] bg-primary text-on-primary font-semibold text-sm sm:text-base py-3.5 rounded-xl shadow-lg hover:shadow-primary/30 hover:-translate-y-0.5 active:scale-95 transition-all disabled:opacity-50 disabled:pointer-events-none flex items-center justify-center gap-2 cursor-pointer"
          >
            {isLoading ? (
              <>
                <div className="w-5 h-5 border-2 border-on-primary border-t-transparent rounded-full animate-spin" />
                <span>Creating your partner account...</span>
              </>
            ) : (
              <span>Complete Shop Registration</span>
            )}
          </button>
        </form>
        
        <p className="text-center text-on-surface-variant text-xs sm:text-sm mt-6 pt-4 border-t border-outline-variant/20">
          Already registered?{' '}
          <Link to="/login" className="text-primary font-semibold hover:underline">
            Sign In to Dashboard
          </Link>
        </p>
      </div>
    </div>
  );
};

export default Register;
