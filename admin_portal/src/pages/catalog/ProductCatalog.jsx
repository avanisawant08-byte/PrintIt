import React, { useState, useEffect } from 'react';
import api from '../../core/api';

const ProductCatalog = () => {
  const [products, setProducts] = useState([]);
  const [loading, setLoading] = useState(true);
  const [selectedCategory, setSelectedCategory] = useState('All');
  const [searchQuery, setSearchQuery] = useState('');
  
  // Modal states
  const [showModal, setShowModal] = useState(false);
  const [editingProduct, setEditingProduct] = useState(null);
  const [formData, setFormData] = useState({
    title: '',
    description: '',
    category: 'Manuals',
    branch: 'Computer Science',
    course_type: 'Degree',
    semester: '3rd',
    subject: '',
    author: '',
    isbn: '',
    cover_photo_url: ''
  });
  const [isSubmitting, setIsSubmitting] = useState(false);

  const categories = ['All', 'Books', 'Manuals', 'Notes', 'Forms', 'Other'];
  const formCategories = ['Books', 'Manuals', 'Notes', 'Forms', 'Other'];
  const branches = ['Computer Science', 'Information Technology', 'Mechanical', 'Civil', 'Electrical', 'Electronics', 'Chemical', 'First Year (Common)', 'General'];
  const courseTypes = ['Degree', 'Diploma', 'Autonomous', 'Other'];
  const semesters = ['1st', '2nd', '3rd', '4th', '5th', '6th', '7th', '8th', 'All'];

  useEffect(() => {
    fetchProducts();
  }, [selectedCategory]);

  const fetchProducts = async () => {
    setLoading(true);
    try {
      const res = await api.get(`/admin/products?category=${selectedCategory}&search=${encodeURIComponent(searchQuery)}`);
      setProducts(res.data.products || []);
    } catch (err) {
      console.error('Error fetching admin products:', err);
    } finally {
      setLoading(false);
    }
  };

  const handleOpenAdd = () => {
    setEditingProduct(null);
    setFormData({
      title: '',
      description: '',
      category: 'Manuals',
      branch: 'Computer Science',
      course_type: 'Degree',
      semester: '3rd',
      subject: '',
      author: '',
      isbn: '',
      cover_photo_url: ''
    });
    setShowModal(true);
  };

  const handleOpenEdit = (prod) => {
    setEditingProduct(prod);
    setFormData({
      title: prod.title || '',
      description: prod.description || '',
      category: prod.category || 'Manuals',
      branch: prod.branch || 'Computer Science',
      course_type: prod.course_type || 'Degree',
      semester: prod.semester || '3rd',
      subject: prod.subject || '',
      author: prod.author || '',
      isbn: prod.isbn || '',
      cover_photo_url: prod.cover_photo_url || ''
    });
    setShowModal(true);
  };

  const handleSubmit = async (e) => {
    e.preventDefault();
    setIsSubmitting(true);
    try {
      if (editingProduct) {
        await api.put(`/admin/products/${editingProduct.product_id}`, formData);
        alert('Product updated successfully');
      } else {
        await api.post('/admin/products', formData);
        alert('Product added to master catalog');
      }
      setShowModal(false);
      fetchProducts();
    } catch (err) {
      alert(err.response?.data?.error || 'Failed to save product');
    } finally {
      setIsSubmitting(false);
    }
  };

  const handleToggleStatus = async (id) => {
    try {
      const res = await api.patch(`/admin/products/${id}/toggle`);
      setProducts(prev => prev.map(p => p.product_id === id ? { ...p, is_active: res.data.product.is_active } : p));
    } catch (err) {
      alert('Failed to toggle status');
    }
  };

  const handleDelete = async (id, title) => {
    if (!window.confirm(`Are you sure you want to delete "${title}"?`)) return;
    try {
      await api.delete(`/admin/products/${id}`);
      setProducts(prev => prev.filter(p => p.product_id !== id));
      alert('Item removed from catalog');
    } catch (err) {
      alert(err.response?.data?.error || 'Failed to delete');
    }
  };

  return (
    <div className="flex-1 overflow-y-auto p-6 max-w-7xl mx-auto w-full">
      {/* Header */}
      <div className="flex flex-col sm:flex-row justify-between items-start sm:items-center gap-4 mb-6">
        <div>
          <h1 className="text-2xl font-bold text-on-surface flex items-center gap-2">
            <span className="material-symbols-outlined text-primary text-3xl">menu_book</span>
            Master Product Catalog
          </h1>
          <p className="text-xs text-on-surface-variant mt-1">
            Centrally curate college manuals, textbooks, notes, and forms. Registered print shops can attach their stock and pricing to these items.
          </p>
        </div>

        <button
          onClick={handleOpenAdd}
          className="bg-primary hover:bg-primary/90 text-on-primary px-5 py-2.5 rounded-xl text-xs font-bold flex items-center gap-2 shadow-sm transition-all"
        >
          <span className="material-symbols-outlined text-[18px]">add</span>
          New Catalog Item
        </button>
      </div>

      {/* Filters bar */}
      <div className="bg-surface-container border border-outline-variant/30 rounded-2xl p-4 mb-6 flex flex-col md:flex-row justify-between items-center gap-4">
        <div className="flex items-center gap-2 overflow-x-auto w-full md:w-auto pb-1 md:pb-0">
          {categories.map(c => (
            <button
              key={c}
              onClick={() => setSelectedCategory(c)}
              className={`px-4 py-1.5 rounded-full text-xs font-semibold whitespace-nowrap transition-colors ${
                selectedCategory === c
                  ? 'bg-primary text-on-primary'
                  : 'bg-surface-container-high text-on-surface-variant hover:bg-outline-variant/20'
              }`}
            >
              {c}
            </button>
          ))}
        </div>

        <div className="flex items-center gap-2 w-full md:w-80">
          <input
            type="text"
            placeholder="Search by title, subject, author..."
            value={searchQuery}
            onChange={(e) => setSearchQuery(e.target.value)}
            onKeyDown={(e) => e.key === 'Enter' && fetchProducts()}
            className="w-full bg-surface-container-high px-3 py-2 text-xs rounded-xl border border-outline-variant/40 focus:border-primary outline-none text-on-surface"
          />
          <button
            onClick={fetchProducts}
            className="px-3 py-2 bg-surface-container-high hover:bg-outline-variant/20 rounded-xl text-xs font-semibold text-on-surface border border-outline-variant/40"
          >
            Search
          </button>
        </div>
      </div>

      {/* Table */}
      {loading ? (
        <div className="flex items-center justify-center py-20 text-on-surface-variant">
          <span className="material-symbols-outlined animate-spin text-3xl text-primary mr-2">autorenew</span>
          <span>Loading master catalog...</span>
        </div>
      ) : products.length === 0 ? (
        <div className="bg-surface-container border border-outline-variant/30 rounded-2xl p-12 text-center text-on-surface-variant">
          <span className="material-symbols-outlined text-4xl mb-2 opacity-50">menu_book</span>
          <p className="font-semibold text-sm">No catalog products found</p>
        </div>
      ) : (
        <div className="bg-surface-container border border-outline-variant/30 rounded-2xl overflow-x-auto shadow-sm">
          <table className="w-full text-left border-collapse text-xs min-w-[850px]">
            <thead>
              <tr className="bg-surface-container-low border-b border-outline-variant/30 text-[0.75rem] uppercase tracking-wider text-on-surface-variant font-bold">
                <th className="p-4">Item Details</th>
                <th className="p-4">Category</th>
                <th className="p-4">Target Course & Sem</th>
                <th className="p-4">Stocking Shops</th>
                <th className="p-4">Price Range</th>
                <th className="p-4">Status</th>
                <th className="p-4 text-right">Actions</th>
              </tr>
            </thead>
            <tbody className="divide-y divide-outline-variant/20">
              {products.map(p => (
                <tr key={p.product_id} className="hover:bg-surface-bright/40 transition-colors">
                  <td className="p-4">
                    <div className="flex items-center gap-3">
                      <div className="w-10 h-10 rounded-lg bg-surface-container-highest flex items-center justify-center overflow-hidden shrink-0">
                        {p.cover_photo_url ? (
                          <img src={p.cover_photo_url} alt="" className="w-full h-full object-cover" />
                        ) : (
                          <span className="material-symbols-outlined text-base text-on-surface-variant">book</span>
                        )}
                      </div>
                      <div>
                        <p className="font-bold text-on-surface text-sm">{p.title}</p>
                        <p className="text-[11px] text-on-surface-variant">{p.subject || 'General'} {p.author && `• by ${p.author}`}</p>
                      </div>
                    </div>
                  </td>

                  <td className="p-4">
                    <span className="bg-secondary-container text-on-secondary-container px-2.5 py-1 rounded-full font-bold text-[10px]">
                      {p.category}
                    </span>
                  </td>

                  <td className="p-4 text-on-surface-variant">
                    <p className="font-medium text-on-surface">{p.branch}</p>
                    <p className="text-[11px]">{p.course_type} {p.semester && `(Sem ${p.semester})`}</p>
                  </td>

                  <td className="p-4">
                    <span className="font-bold text-primary text-sm">
                      {p.stocking_shops_count || 0}
                    </span>
                    <span className="text-on-surface-variant text-[11px] ml-1">shops</span>
                  </td>

                  <td className="p-4">
                    {parseFloat(p.min_price) > 0 ? (
                      <span className="font-bold text-on-surface">
                        ₹{p.min_price} {parseFloat(p.max_price) > parseFloat(p.min_price) && `- ₹${p.max_price}`}
                      </span>
                    ) : (
                      <span className="text-on-surface-variant italic">No stock active</span>
                    )}
                  </td>

                  <td className="p-4">
                    <button
                      onClick={() => handleToggleStatus(p.product_id)}
                      className={`px-2.5 py-1 rounded-full text-[10px] font-bold uppercase transition-colors ${
                        p.is_active
                          ? 'bg-emerald-500/15 text-emerald-400 border border-emerald-500/30'
                          : 'bg-rose-500/15 text-rose-400 border border-rose-500/30'
                      }`}
                    >
                      {p.is_active ? 'Active' : 'Inactive'}
                    </button>
                  </td>

                  <td className="p-4 text-right">
                    <div className="flex items-center justify-end gap-2">
                      <button
                        onClick={() => handleOpenEdit(p)}
                        className="p-1.5 rounded-lg bg-surface-container-high hover:bg-outline-variant/30 text-on-surface"
                        title="Edit Details"
                      >
                        <span className="material-symbols-outlined text-[16px]">edit</span>
                      </button>
                      <button
                        onClick={() => handleDelete(p.product_id, p.title)}
                        className="p-1.5 rounded-lg bg-rose-500/10 hover:bg-rose-500/20 text-rose-400"
                        title="Delete Product"
                      >
                        <span className="material-symbols-outlined text-[16px]">delete</span>
                      </button>
                    </div>
                  </td>
                </tr>
              ))}
            </tbody>
          </table>
        </div>
      )}

      {/* Add / Edit Product Modal */}
      {showModal && (
        <div className="fixed inset-0 bg-black/70 backdrop-blur-sm flex items-center justify-center z-50 p-4">
          <div 
            className="bg-surface border border-outline-variant/40 rounded-3xl p-6 w-full max-h-[90vh] overflow-y-auto shadow-2xl"
            style={{ maxWidth: '640px' }}
          >
            <div className="flex justify-between items-center pb-4 border-b border-outline-variant/30 mb-4">
              <h2 className="text-lg font-bold text-on-surface flex items-center gap-2">
                <span className="material-symbols-outlined text-primary">edit_note</span>
                {editingProduct ? 'Edit Catalog Item' : 'New Master Catalog Item'}
              </h2>
              <button onClick={() => setShowModal(false)} className="text-on-surface-variant hover:text-on-surface material-symbols-outlined">
                close
              </button>
            </div>

            <form onSubmit={handleSubmit} className="space-y-4 text-xs">
              <div>
                <label className="block font-bold text-on-surface mb-1">Item Title *</label>
                <input
                  required
                  value={formData.title}
                  onChange={(e) => setFormData({ ...formData, title: e.target.value })}
                  placeholder="e.g. Data Structures & Algorithms Lab Manual"
                  className="w-full bg-surface-container-high px-3 py-2.5 rounded-xl border border-outline-variant/40 focus:border-primary outline-none text-on-surface font-medium"
                />
              </div>

              <div className="grid grid-cols-2 gap-3">
                <div>
                  <label className="block font-bold text-on-surface mb-1">Category *</label>
                  <select
                    value={formData.category}
                    onChange={(e) => setFormData({ ...formData, category: e.target.value })}
                    className="w-full bg-surface-container-high px-3 py-2 rounded-xl border border-outline-variant/40 focus:border-primary outline-none text-on-surface"
                  >
                    {formCategories.map(c => <option key={c} value={c}>{c}</option>)}
                  </select>
                </div>

                <div>
                  <label className="block font-bold text-on-surface mb-1">Branch</label>
                  <select
                    value={formData.branch}
                    onChange={(e) => setFormData({ ...formData, branch: e.target.value })}
                    className="w-full bg-surface-container-high px-3 py-2 rounded-xl border border-outline-variant/40 focus:border-primary outline-none text-on-surface"
                  >
                    {branches.map(b => <option key={b} value={b}>{b}</option>)}
                  </select>
                </div>
              </div>

              <div className="grid grid-cols-2 gap-3">
                <div>
                  <label className="block font-bold text-on-surface mb-1">Course Type</label>
                  <select
                    value={formData.course_type}
                    onChange={(e) => setFormData({ ...formData, course_type: e.target.value })}
                    className="w-full bg-surface-container-high px-3 py-2 rounded-xl border border-outline-variant/40 focus:border-primary outline-none text-on-surface"
                  >
                    {courseTypes.map(ct => <option key={ct} value={ct}>{ct}</option>)}
                  </select>
                </div>

                <div>
                  <label className="block font-bold text-on-surface mb-1">Semester</label>
                  <select
                    value={formData.semester}
                    onChange={(e) => setFormData({ ...formData, semester: e.target.value })}
                    className="w-full bg-surface-container-high px-3 py-2 rounded-xl border border-outline-variant/40 focus:border-primary outline-none text-on-surface"
                  >
                    {semesters.map(s => <option key={s} value={s}>{s}</option>)}
                  </select>
                </div>
              </div>

              <div className="grid grid-cols-2 gap-3">
                <div>
                  <label className="block font-bold text-on-surface mb-1">Subject</label>
                  <input
                    value={formData.subject}
                    onChange={(e) => setFormData({ ...formData, subject: e.target.value })}
                    placeholder="e.g. Data Structures"
                    className="w-full bg-surface-container-high px-3 py-2 rounded-xl border border-outline-variant/40 focus:border-primary outline-none text-on-surface"
                  />
                </div>

                <div>
                  <label className="block font-bold text-on-surface mb-1">Author / Publisher</label>
                  <input
                    value={formData.author}
                    onChange={(e) => setFormData({ ...formData, author: e.target.value })}
                    placeholder="e.g. Dept of Computer Eng"
                    className="w-full bg-surface-container-high px-3 py-2 rounded-xl border border-outline-variant/40 focus:border-primary outline-none text-on-surface"
                  />
                </div>
              </div>

              <div>
                <label className="block font-bold text-on-surface mb-1">Cover Photo URL (Optional)</label>
                <input
                  value={formData.cover_photo_url}
                  onChange={(e) => setFormData({ ...formData, cover_photo_url: e.target.value })}
                  placeholder="https://..."
                  className="w-full bg-surface-container-high px-3 py-2 rounded-xl border border-outline-variant/40 focus:border-primary outline-none text-on-surface"
                />
              </div>

              <div>
                <label className="block font-bold text-on-surface mb-1">Description (Optional)</label>
                <textarea
                  rows={3}
                  value={formData.description}
                  onChange={(e) => setFormData({ ...formData, description: e.target.value })}
                  placeholder="Details, included experiments, syllabus version..."
                  className="w-full bg-surface-container-high px-3 py-2 rounded-xl border border-outline-variant/40 focus:border-primary outline-none text-on-surface"
                />
              </div>

              <div className="flex gap-2 pt-3">
                <button
                  type="button"
                  onClick={() => setShowModal(false)}
                  className="flex-1 py-2.5 rounded-xl bg-surface-container hover:bg-outline-variant/20 text-on-surface font-bold"
                >
                  Cancel
                </button>
                <button
                  type="submit"
                  disabled={isSubmitting}
                  className="flex-1 py-2.5 rounded-xl bg-primary hover:bg-primary/90 text-on-primary font-bold shadow disabled:opacity-50"
                >
                  {isSubmitting ? 'Saving...' : editingProduct ? 'Update Product' : 'Create Catalog Product'}
                </button>
              </div>
            </form>
          </div>
        </div>
      )}
    </div>
  );
};

export default ProductCatalog;
