import React, { useState } from 'react';
import { useNavigate, Link } from 'react-router-dom';
import api from '../core/api';

const Register = () => {
  const [formData, setFormData] = useState({
    full_name: '', email: '', phone: '', password: '', 
    shop_name: '', address: '', price_bw: 2, price_color: 10
  });
  const [isLoading, setIsLoading] = useState(false);
  const [error, setError] = useState('');
  const [success, setSuccess] = useState('');
  
  const navigate = useNavigate();

  const handleChange = (e) => {
    setFormData({ ...formData, [e.target.name]: e.target.value });
  };

  const handleRegister = async (e) => {
    e.preventDefault();
    setIsLoading(true);
    setError('');

    try {
      const payload = {
        ...formData,
        price_bw: parseFloat(formData.price_bw),
        price_color: parseFloat(formData.price_color)
      };
      
      await api.post('/auth/register-shop', payload);
      setSuccess('Registration successful! Redirecting to login...');
      setTimeout(() => navigate('/login'), 1500);
    } catch (err) {
      setError(err.response?.data?.error || err.message);
    } finally {
      setIsLoading(false);
    }
  };

  return (
    <div className="flex-1 flex items-center justify-center min-h-screen py-12 px-4">
      <div className="w-full max-w-[650px] bg-surface-container border border-outline-variant/30 rounded-xl p-8 shadow-2xl my-auto">
        <div className="text-center mb-8">
          <h2 className="font-headline-lg text-primary mb-2">Register Your Shop</h2>
          <p className="text-on-surface-variant font-body-sm">Join the PrintIt network and start receiving digital orders</p>
        </div>
        
        {error && <div className="bg-error-container/20 text-error p-3 rounded-lg mb-6 text-sm border border-error/30 text-center">{error}</div>}
        {success && <div className="bg-primary-container/20 text-primary p-3 rounded-lg mb-6 text-sm border border-primary/30 text-center">{success}</div>}

        <form onSubmit={handleRegister} className="flex flex-col gap-6">
          <div>
            <h3 className="text-[0.9rem] text-primary mb-4 uppercase tracking-wider font-semibold">1. Owner Details</h3>
            <div className="flex flex-col gap-4">
              <div>
                <label className="block text-label-md text-on-surface-variant mb-2">Full Name</label>
                <input type="text" name="full_name" required value={formData.full_name} onChange={handleChange} className="w-full bg-surface-container-highest border border-outline-variant/50 rounded-lg px-4 py-3 text-on-surface focus:outline-none focus:border-primary" />
              </div>
              <div className="grid grid-cols-1 sm:grid-cols-2 gap-4">
                <div>
                  <label className="block text-label-md text-on-surface-variant mb-2">Email Address</label>
                  <input type="email" name="email" required value={formData.email} onChange={handleChange} className="w-full bg-surface-container-highest border border-outline-variant/50 rounded-lg px-4 py-3 text-on-surface focus:outline-none focus:border-primary" />
                </div>
                <div>
                  <label className="block text-label-md text-on-surface-variant mb-2">Phone Number</label>
                  <input type="tel" name="phone" required value={formData.phone} onChange={handleChange} className="w-full bg-surface-container-highest border border-outline-variant/50 rounded-lg px-4 py-3 text-on-surface focus:outline-none focus:border-primary" />
                </div>
              </div>
              <div>
                <label className="block text-label-md text-on-surface-variant mb-2">Password</label>
                <input type="password" name="password" required minLength="6" value={formData.password} onChange={handleChange} className="w-full bg-surface-container-highest border border-outline-variant/50 rounded-lg px-4 py-3 text-on-surface focus:outline-none focus:border-primary" />
              </div>
            </div>
          </div>

          <div>
            <h3 className="text-[0.9rem] text-primary mb-4 uppercase tracking-wider font-semibold">2. Shop Information</h3>
            <div className="flex flex-col gap-4">
              <div>
                <label className="block text-label-md text-on-surface-variant mb-2">Shop Name</label>
                <input type="text" name="shop_name" required value={formData.shop_name} onChange={handleChange} className="w-full bg-surface-container-highest border border-outline-variant/50 rounded-lg px-4 py-3 text-on-surface focus:outline-none focus:border-primary" />
              </div>
              <div>
                <label className="block text-label-md text-on-surface-variant mb-2">Physical Address</label>
                <input type="text" name="address" required value={formData.address} onChange={handleChange} className="w-full bg-surface-container-highest border border-outline-variant/50 rounded-lg px-4 py-3 text-on-surface focus:outline-none focus:border-primary" />
              </div>
            </div>
          </div>

          <div>
            <h3 className="text-[0.9rem] text-primary mb-4 uppercase tracking-wider font-semibold">3. Base Pricing (₹ per page)</h3>
            <div className="grid grid-cols-1 sm:grid-cols-2 gap-4">
              <div>
                <label className="block text-label-md text-on-surface-variant mb-2">Black & White (A4)</label>
                <input type="number" name="price_bw" min="0.5" step="0.5" required value={formData.price_bw} onChange={handleChange} className="w-full bg-surface-container-highest border border-outline-variant/50 rounded-lg px-4 py-3 text-on-surface focus:outline-none focus:border-primary" />
              </div>
              <div>
                <label className="block text-label-md text-on-surface-variant mb-2">Colour (A4)</label>
                <input type="number" name="price_color" min="1" step="0.5" required value={formData.price_color} onChange={handleChange} className="w-full bg-surface-container-highest border border-outline-variant/50 rounded-lg px-4 py-3 text-on-surface focus:outline-none focus:border-primary" />
              </div>
            </div>
          </div>

          <button 
            type="submit" 
            disabled={isLoading}
            className="w-full bg-primary text-on-primary font-label-md py-4 rounded-lg mt-4 shadow-lg hover:-translate-y-0.5 transition-transform disabled:opacity-50"
          >
            {isLoading ? 'Registering...' : 'Complete Registration'}
          </button>
        </form>
        
        <p className="text-center text-on-surface-variant font-body-sm mt-8">
          Already registered? <Link to="/login" className="text-primary hover:underline">Sign In</Link>
        </p>
      </div>
    </div>
  );
};

export default Register;
