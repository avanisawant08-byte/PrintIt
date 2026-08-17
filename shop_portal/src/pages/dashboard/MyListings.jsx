import React, { useState, useEffect } from 'react';
import api from '../../core/api';

const MyListings = () => {
  const [products, setProducts] = useState([]);
  const [loading, setLoading] = useState(true);
  const [showModal, setShowModal] = useState(false);
  const [formData, setFormData] = useState({
    title: '', description: '', branch: '', course_type: '', semester: '', subject: '', price: '', stock_count: '', cover_photo_url: ''
  });

  const branches = ['Computer Science', 'Mechanical', 'Civil', 'Electrical', 'Electronics', 'Chemical', 'Other'];
  const courseTypes = ['Engineering', 'Polytechnic'];
  const semesters = ['1st', '2nd', '3rd', '4th', '5th', '6th', '7th', '8th'];

  useEffect(() => {
    fetchProducts();
  }, []);

  const fetchProducts = async () => {
    try {
      const res = await api.get('/shop/products');
      setProducts(res.data.data || res.data);
    } catch (err) {
      console.error('Error fetching products', err);
    } finally {
      setLoading(false);
    }
  };

  const handleChange = (e) => setFormData({ ...formData, [e.target.name]: e.target.value });

  const handleSubmit = async (e) => {
    e.preventDefault();
    try {
      await api.post('/shop/products', formData);
      setShowModal(false);
      setFormData({ title: '', description: '', branch: '', course_type: '', semester: '', subject: '', price: '', stock_count: '', cover_photo_url: '' });
      fetchProducts();
    } catch (err) {
      console.error('Error saving product', err);
      alert('Failed to save product');
    }
  };

  const handleStockUpdate = async (id, currentStock, change) => {
    try {
      await api.patch(`/shop/products/${id}/stock`, { stock_count: parseInt(currentStock) + change });
      fetchProducts();
    } catch (err) {
      console.error('Error updating stock', err);
    }
  };

  const handleToggleActive = async (id, currentActive) => {
    try {
      await api.patch(`/shop/products/${id}/stock`, { is_active: !currentActive });
      fetchProducts();
    } catch (err) {
      console.error('Error toggling active', err);
    }
  };

  if (loading) return <div className="p-lg">Loading...</div>;

  return (
    <div className="p-lg max-w-[1152px] mx-auto">
      <div className="flex justify-between items-center mb-lg">
        <h1 className="font-display-sm text-display-sm text-on-surface">My Listings</h1>
        <button 
          onClick={() => setShowModal(true)}
          className="bg-primary text-on-primary px-4 py-2 rounded-lg font-label-md flex items-center gap-2"
        >
          <span className="material-symbols-outlined">add</span>
          Add New Manual
        </button>
      </div>

      <div className="grid grid-cols-1 md:grid-cols-2 lg:grid-cols-3 gap-md">
        {products.map(product => (
          <div key={product.product_id} className={`bg-surface-container rounded-2xl p-md border border-outline-variant/30 flex flex-col ${!product.is_active ? 'opacity-60' : ''}`}>
            {product.cover_photo_url && (
              <img src={product.cover_photo_url} alt="Cover" className="w-full h-40 object-cover rounded-xl mb-4" />
            )}
            <div className="flex-1">
              <div className="flex justify-between items-start">
                <h3 className="font-title-lg font-bold">{product.title}</h3>
                <span className="font-label-md bg-secondary-container text-on-secondary-container px-2 py-1 rounded-md text-[10px]">₹{product.price}</span>
              </div>
              <p className="text-on-surface-variant text-body-sm mt-1">{product.branch} • {product.course_type}</p>
              <p className="text-on-surface-variant text-body-sm mb-4">{product.subject} {product.semester && `(${product.semester} Sem)`}</p>
            </div>
            
            <div className="flex items-center justify-between border-t border-outline-variant/30 pt-4 mt-auto">
              <div className="flex items-center gap-2">
                <span className="font-label-md text-on-surface-variant">Stock:</span>
                <button onClick={() => handleStockUpdate(product.product_id, product.stock_count, -1)} className="w-6 h-6 bg-surface-container-highest rounded flex items-center justify-center hover:bg-outline-variant/30">-</button>
                <span className="font-title-md w-8 text-center">{product.stock_count}</span>
                <button onClick={() => handleStockUpdate(product.product_id, product.stock_count, 1)} className="w-6 h-6 bg-surface-container-highest rounded flex items-center justify-center hover:bg-outline-variant/30">+</button>
                <button onClick={() => handleStockUpdate(product.product_id, product.stock_count, 10)} className="ml-2 text-[10px] bg-primary/10 text-primary px-2 py-1 rounded">+10</button>
              </div>
              <button 
                onClick={() => handleToggleActive(product.product_id, product.is_active)}
                className={`text-[12px] px-3 py-1 rounded-full ${product.is_active ? 'bg-success/20 text-success' : 'bg-error/20 text-error'}`}
              >
                {product.is_active ? 'Active' : 'Inactive'}
              </button>
            </div>
          </div>
        ))}
        {products.length === 0 && (
          <div className="col-span-full py-xl text-center text-on-surface-variant">
            <span className="material-symbols-outlined text-[48px] opacity-50 mb-4 block">inventory_2</span>
            <p>No manuals listed yet.</p>
          </div>
        )}
      </div>

      {showModal && (
        <div className="fixed inset-0 bg-black/50 flex items-center justify-center z-50 p-4">
          <div className="bg-surface rounded-2xl p-lg w-full max-w-[512px] max-h-[90vh] overflow-y-auto">
            <div className="flex justify-between items-center mb-lg">
              <h2 className="font-title-lg">Add New Manual</h2>
              <button onClick={() => setShowModal(false)} className="material-symbols-outlined text-on-surface-variant">close</button>
            </div>
            <form onSubmit={handleSubmit} className="flex flex-col gap-md">
              <div>
                <label className="block font-label-md mb-1">Title *</label>
                <input required name="title" value={formData.title} onChange={handleChange} className="w-full bg-surface-container p-3 rounded-xl border border-outline-variant/30 focus:border-primary outline-none" />
              </div>
              <div className="grid grid-cols-2 gap-md">
                <div>
                  <label className="block font-label-md mb-1">Course Type *</label>
                  <select required name="course_type" value={formData.course_type} onChange={handleChange} className="w-full bg-surface-container p-3 rounded-xl border border-outline-variant/30 focus:border-primary outline-none">
                    <option value="" disabled hidden>Select Course Type</option>
                    {courseTypes.map(c => <option key={c} value={c}>{c}</option>)}
                  </select>
                </div>
                <div>
                  <label className="block font-label-md mb-1">Branch *</label>
                  <select required name="branch" value={formData.branch} onChange={handleChange} className="w-full bg-surface-container p-3 rounded-xl border border-outline-variant/30 focus:border-primary outline-none">
                    <option value="" disabled hidden>Select Branch</option>
                    {branches.map(b => <option key={b} value={b}>{b}</option>)}
                  </select>
                </div>
              </div>
              <div className="grid grid-cols-2 gap-md">
                <div>
                  <label className="block font-label-md mb-1">Semester</label>
                  <select name="semester" value={formData.semester} onChange={handleChange} className="w-full bg-surface-container p-3 rounded-xl border border-outline-variant/30 focus:border-primary outline-none">
                    <option value="" disabled hidden>N/A</option>
                    {semesters.map(s => <option key={s} value={s}>{s}</option>)}
                  </select>
                </div>
                <div>
                  <label className="block font-label-md mb-1">Subject</label>
                  <input name="subject" value={formData.subject} onChange={handleChange} className="w-full bg-surface-container p-3 rounded-xl border border-outline-variant/30 focus:border-primary outline-none" />
                </div>
              </div>
              <div className="grid grid-cols-2 gap-md">
                <div>
                  <label className="block font-label-md mb-1">Price (₹) *</label>
                  <input required type="number" step="0.01" name="price" value={formData.price} onChange={handleChange} className="w-full bg-surface-container p-3 rounded-xl border border-outline-variant/30 focus:border-primary outline-none" />
                </div>
                <div>
                  <label className="block font-label-md mb-1">Initial Stock *</label>
                  <input required type="number" name="stock_count" value={formData.stock_count} onChange={handleChange} className="w-full bg-surface-container p-3 rounded-xl border border-outline-variant/30 focus:border-primary outline-none" />
                </div>
              </div>
              <div>
                <label className="block font-label-md mb-1">Description</label>
                <textarea name="description" value={formData.description} onChange={handleChange} rows="2" className="w-full bg-surface-container p-3 rounded-xl border border-outline-variant/30 focus:border-primary outline-none"></textarea>
              </div>
              <div>
                <label className="block font-label-md mb-1">Cover Photo URL (Optional)</label>
                <input name="cover_photo_url" value={formData.cover_photo_url} onChange={handleChange} placeholder="https://..." className="w-full bg-surface-container p-3 rounded-xl border border-outline-variant/30 focus:border-primary outline-none" />
              </div>
              <button type="submit" className="w-full bg-primary text-on-primary p-4 rounded-xl font-label-lg mt-sm">Save Manual</button>
            </form>
          </div>
        </div>
      )}
    </div>
  );
};

export default MyListings;
