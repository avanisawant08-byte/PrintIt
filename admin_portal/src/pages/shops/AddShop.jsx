import React, { useState } from 'react';
import api from '../../core/api';

const AddShop = () => {
  const [formData, setFormData] = useState({
    email: '',
    password: '',
    full_name: '',
    phone: '',
    shop_name: '',
    address: '',
    price_bw: '',
    price_color: ''
  });
  const [isLoading, setIsLoading] = useState(false);
  const [error, setError] = useState('');
  const [success, setSuccess] = useState('');

  const handleChange = (e) => {
    setFormData({
      ...formData,
      [e.target.name]: e.target.value
    });
  };

  const handleSubmit = async (e) => {
    e.preventDefault();
    setIsLoading(true);
    setError('');
    setSuccess('');

    try {
      await api.post('/auth/register-shop', formData);
      setSuccess('Shop registered successfully!');
      setFormData({
        email: '', password: '', full_name: '', phone: '',
        shop_name: '', address: '', price_bw: '', price_color: ''
      });
    } catch (err) {
      setError(err.response?.data?.error || err.message);
    } finally {
      setIsLoading(false);
    }
  };

  return (
    <div className="max-w-4xl mx-auto p-6 md:p-12 space-y-8">
      <div className="bg-surface-container-highest border border-outline-variant/30 rounded-2xl p-8 backdrop-blur-xl shadow-xl">
        <h2 className="text-2xl font-headline-lg font-bold text-primary mb-2">Register New Shop</h2>
        <p className="text-on-surface-variant font-body-sm mb-8">Fill in the details to onboard a new shopkeeper and their shop.</p>
        
        {error && <div className="bg-error-container/20 text-error p-4 rounded-xl mb-6 border border-error/30">{error}</div>}
        {success && <div className="bg-green-500/20 text-green-400 p-4 rounded-xl mb-6 border border-green-500/30 font-bold">{success}</div>}

        <form onSubmit={handleSubmit} className="space-y-6">
          <div className="grid grid-cols-1 md:grid-cols-2 gap-6">
            <div className="space-y-2">
              <label className="text-on-surface-variant text-sm font-semibold">Shopkeeper Full Name</label>
              <input type="text" name="full_name" required value={formData.full_name} onChange={handleChange} className="w-full bg-surface-container border border-outline-variant/50 rounded-xl px-4 py-3 text-on-surface focus:outline-none focus:border-primary transition-colors" placeholder="John Doe" />
            </div>
            <div className="space-y-2">
              <label className="text-on-surface-variant text-sm font-semibold">Shopkeeper Email</label>
              <input type="email" name="email" required value={formData.email} onChange={handleChange} className="w-full bg-surface-container border border-outline-variant/50 rounded-xl px-4 py-3 text-on-surface focus:outline-none focus:border-primary transition-colors" placeholder="shop@example.com" />
            </div>
            <div className="space-y-2">
              <label className="text-on-surface-variant text-sm font-semibold">Password</label>
              <input type="password" name="password" required value={formData.password} onChange={handleChange} className="w-full bg-surface-container border border-outline-variant/50 rounded-xl px-4 py-3 text-on-surface focus:outline-none focus:border-primary transition-colors" placeholder="••••••••" />
            </div>
            <div className="space-y-2">
              <label className="text-on-surface-variant text-sm font-semibold">Phone Number</label>
              <input type="tel" name="phone" value={formData.phone} onChange={handleChange} className="w-full bg-surface-container border border-outline-variant/50 rounded-xl px-4 py-3 text-on-surface focus:outline-none focus:border-primary transition-colors" placeholder="+1234567890" />
            </div>
          </div>

          <hr className="border-outline-variant/30 my-6" />

          <div className="grid grid-cols-1 md:grid-cols-2 gap-6">
            <div className="space-y-2">
              <label className="text-on-surface-variant text-sm font-semibold">Shop Name</label>
              <input type="text" name="shop_name" required value={formData.shop_name} onChange={handleChange} className="w-full bg-surface-container border border-outline-variant/50 rounded-xl px-4 py-3 text-on-surface focus:outline-none focus:border-primary transition-colors" placeholder="Print Shop 101" />
            </div>
            <div className="space-y-2">
              <label className="text-on-surface-variant text-sm font-semibold">Address</label>
              <input type="text" name="address" value={formData.address} onChange={handleChange} className="w-full bg-surface-container border border-outline-variant/50 rounded-xl px-4 py-3 text-on-surface focus:outline-none focus:border-primary transition-colors" placeholder="123 Main St" />
            </div>
            <div className="space-y-2">
              <label className="text-on-surface-variant text-sm font-semibold">B&W Price per page</label>
              <input type="number" step="0.01" name="price_bw" required value={formData.price_bw} onChange={handleChange} className="w-full bg-surface-container border border-outline-variant/50 rounded-xl px-4 py-3 text-on-surface focus:outline-none focus:border-primary transition-colors" placeholder="0.50" />
            </div>
            <div className="space-y-2">
              <label className="text-on-surface-variant text-sm font-semibold">Color Price per page</label>
              <input type="number" step="0.01" name="price_color" required value={formData.price_color} onChange={handleChange} className="w-full bg-surface-container border border-outline-variant/50 rounded-xl px-4 py-3 text-on-surface focus:outline-none focus:border-primary transition-colors" placeholder="2.00" />
            </div>
          </div>

          <div className="pt-6">
            <button type="submit" disabled={isLoading} className="w-full md:w-auto bg-primary text-on-primary px-8 py-3 rounded-xl font-bold shadow-lg hover:-translate-y-0.5 transition-transform disabled:opacity-50">
              {isLoading ? 'Registering...' : 'Register Shop'}
            </button>
          </div>
        </form>
      </div>
    </div>
  );
};

export default AddShop;
