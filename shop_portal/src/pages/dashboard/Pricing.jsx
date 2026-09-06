import React, { useState, useEffect } from 'react';
import api from '../../core/api';

const Pricing = () => {
  const [rules, setRules] = useState([]);
  const [isLoading, setIsLoading] = useState(true);
  const [loadError, setLoadError] = useState('');
  const [formData, setFormData] = useState({
    color: 'bw', size: 'A4', sides: 'single', price_per_page: '', binding_staple_price: 5, binding_spiral_price: 30
  });

  const fetchRules = async () => {
    setIsLoading(true);
    setLoadError('');
    try {
      const res = await api.get('/shop/pricing');
      setRules(res.data);
    } catch (err) {
      console.error('Failed to load pricing rules:', err);
      setLoadError(err.response?.data?.error || err.message || 'Failed to load pricing rules');
    } finally {
      setIsLoading(false);
    }
  };

  useEffect(() => {
    fetchRules();
  }, []);

  const handleChange = (e) => {
    setFormData({ ...formData, [e.target.name]: e.target.value });
  };

  const handleAdd = async (e) => {
    e.preventDefault();
    try {
      await api.post('/shop/pricing', {
        ...formData,
        price_per_page: parseFloat(formData.price_per_page),
        binding_staple_price: parseFloat(formData.binding_staple_price),
        binding_spiral_price: parseFloat(formData.binding_spiral_price),
      });
      fetchRules();
      setFormData({ ...formData, price_per_page: '' });
    } catch (err) {
      alert('Failed to add rule: ' + err.message);
    }
  };

  const handleDelete = async (id) => {
    if(!window.confirm('Delete this rule?')) return;
    try {
      await api.delete(`/shop/pricing/${id}`);
      fetchRules();
    } catch (err) {
      alert('Failed to delete rule: ' + err.message);
    }
  };

  return (
    <div className="w-full flex flex-col gap-6">
      <div>
        <h1 className="text-2xl font-bold mb-1 text-on-surface">Pricing Rules</h1>
        <p className="text-xs text-on-surface-variant mb-6">Define base rates for single/double side, color modes, and binding addons</p>
        
        <div className="bg-surface-container border border-outline-variant/30 p-6 rounded-2xl mb-6 shadow-sm">
          <h2 className="text-base font-bold mb-4 text-primary flex items-center gap-2">
            <span className="material-symbols-outlined text-[18px]">add_circle</span>
            Add Custom Pricing Rule
          </h2>
          <form onSubmit={handleAdd} className="flex flex-col gap-4">
            <div className="grid grid-cols-2 md:grid-cols-3 gap-4">
              <div>
                <label className="block text-label-md text-on-surface-variant mb-1">Color Mode</label>
                <select name="color" value={formData.color} onChange={handleChange} className="w-full bg-surface-container-highest border border-outline-variant/50 rounded-lg p-2 text-on-surface focus:outline-none focus:border-primary">
                  <option value="bw">Black & White</option>
                  <option value="color">Full Color</option>
                </select>
              </div>
              <div>
                <label className="block text-label-md text-on-surface-variant mb-1">Paper Size</label>
                <select name="size" value={formData.size} onChange={handleChange} className="w-full bg-surface-container-highest border border-outline-variant/50 rounded-lg p-2 text-on-surface focus:outline-none focus:border-primary">
                  <option value="A4">A4</option>
                  <option value="A3">A3</option>
                  <option value="Letter">Letter</option>
                </select>
              </div>
              <div>
                <label className="block text-label-md text-on-surface-variant mb-1">Sides</label>
                <select name="sides" value={formData.sides} onChange={handleChange} className="w-full bg-surface-container-highest border border-outline-variant/50 rounded-lg p-2 text-on-surface focus:outline-none focus:border-primary">
                  <option value="single">Single Sided</option>
                  <option value="double">Double Sided</option>
                </select>
              </div>
              <div>
                <label className="block text-label-md text-on-surface-variant mb-1">Price / Page (₹)</label>
                <input type="number" name="price_per_page" min="0.5" step="0.5" required value={formData.price_per_page} onChange={handleChange} className="w-full bg-surface-container-highest border border-outline-variant/50 rounded-lg p-2 text-on-surface focus:outline-none focus:border-primary" />
              </div>
              <div>
                <label className="block text-label-md text-on-surface-variant mb-1">Staple Price (₹)</label>
                <input type="number" name="binding_staple_price" min="0" step="1" required value={formData.binding_staple_price} onChange={handleChange} className="w-full bg-surface-container-highest border border-outline-variant/50 rounded-lg p-2 text-on-surface focus:outline-none focus:border-primary" />
              </div>
              <div>
                <label className="block text-label-md text-on-surface-variant mb-1">Spiral Price (₹)</label>
                <input type="number" name="binding_spiral_price" min="0" step="1" required value={formData.binding_spiral_price} onChange={handleChange} className="w-full bg-surface-container-highest border border-outline-variant/50 rounded-lg p-2 text-on-surface focus:outline-none focus:border-primary" />
              </div>
            </div>
            <button type="submit" className="bg-primary text-on-primary px-6 py-2 rounded-lg font-medium hover:bg-primary-hover self-start mt-2">
              Add Rule
            </button>
          </form>
        </div>
      </div>

      {loadError && (
        <div className="bg-rose-500/15 border border-rose-500/30 text-rose-300 p-4 rounded-xl flex items-center justify-between gap-4">
          <div className="flex items-center gap-2 text-xs font-semibold">
            <span className="material-symbols-outlined text-lg">error</span>
            <span>{loadError}</span>
          </div>
          <button
            onClick={fetchRules}
            className="px-3 py-1.5 bg-rose-500/20 hover:bg-rose-500/30 text-rose-200 rounded-lg text-xs font-bold transition-colors"
          >
            Retry
          </button>
        </div>
      )}

      <div className="flex-1 overflow-x-auto">
        {isLoading ? (
          <div className="text-on-surface-variant text-center mt-10">Loading rules...</div>
        ) : rules.length === 0 ? (
          <div className="bg-surface-container/50 border border-outline-variant/30 rounded-xl p-8 text-center text-on-surface-variant">
            No custom pricing rules defined.
          </div>
        ) : (
          <div className="bg-surface-container border border-outline-variant/30 rounded-2xl overflow-x-auto shadow-sm">
            <table className="w-full text-left border-collapse min-w-[640px]">
              <thead>
                <tr className="bg-black/30 border-b border-outline-variant/30 text-[0.75rem] uppercase tracking-wider text-on-surface-variant">
                  <th className="p-4">Mode</th>
                  <th className="p-4">Size</th>
                  <th className="p-4">Sides</th>
                  <th className="p-4">Price/Pg</th>
                  <th className="p-4">Staple</th>
                  <th className="p-4">Spiral</th>
                  <th className="p-4"></th>
                </tr>
              </thead>
              <tbody>
                {rules.map(r => (
                  <tr key={r.id} className="border-b border-outline-variant/10 hover:bg-surface-variant/30 transition-colors">
                    <td className="p-4 font-medium">{r.color}</td>
                    <td className="p-4">{r.size}</td>
                    <td className="p-4">{r.sides}</td>
                    <td className="p-4 font-bold text-accent">₹{r.price_per_page}</td>
                    <td className="p-4">₹{r.binding_staple_price}</td>
                    <td className="p-4">₹{r.binding_spiral_price}</td>
                    <td className="p-4">
                      <button onClick={() => handleDelete(r.id)} className="border border-red-500/30 text-red-400 px-3 py-1 rounded text-sm hover:bg-red-500/10">Delete</button>
                    </td>
                  </tr>
                ))}
              </tbody>
            </table>
          </div>
        )}
      </div>
    </div>
  );
};

export default Pricing;
