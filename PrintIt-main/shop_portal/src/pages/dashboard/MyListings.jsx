import React, { useState, useEffect } from 'react';
import api from '../../core/api';

const MyListings = () => {
  const [inventory, setInventory] = useState([]);
  const [loading, setLoading] = useState(true);
  const [selectedCategory, setSelectedCategory] = useState('All');
  const [searchQuery, setSearchQuery] = useState('');
  
  // Modal states
  const [showCatalogModal, setShowCatalogModal] = useState(false);
  const [catalogItems, setCatalogItems] = useState([]);
  const [catalogLoading, setCatalogLoading] = useState(false);
  const [catalogSearch, setCatalogSearch] = useState('');
  const [catalogCategory, setCatalogCategory] = useState('All');
  
  // Stock adding modal
  const [selectedProduct, setSelectedProduct] = useState(null);
  const [stockPrice, setStockPrice] = useState('');
  const [stockQuantity, setStockQuantity] = useState('10');
  const [isSubmitting, setIsSubmitting] = useState(false);

  // Quick edit price modal
  const [editingItem, setEditingItem] = useState(null);
  const [newPrice, setNewPrice] = useState('');

  const categories = ['All', 'Books', 'Manuals', 'Notes', 'Forms', 'Other'];

  useEffect(() => {
    fetchInventory();
  }, [selectedCategory]);

  const fetchInventory = async () => {
    setLoading(true);
    try {
      const res = await api.get(`/shop/inventory?category=${selectedCategory}&search=${encodeURIComponent(searchQuery)}`);
      setInventory(res.data.inventory || []);
    } catch (err) {
      console.error('Error fetching inventory:', err);
    } finally {
      setLoading(false);
    }
  };

  const fetchMasterCatalog = async () => {
    setCatalogLoading(true);
    try {
      const res = await api.get(`/shop/inventory/catalog?category=${catalogCategory}&search=${encodeURIComponent(catalogSearch)}`);
      setCatalogItems(res.data.catalog || []);
    } catch (err) {
      console.error('Error fetching catalog:', err);
    } finally {
      setCatalogLoading(false);
    }
  };

  useEffect(() => {
    if (showCatalogModal) {
      fetchMasterCatalog();
    }
  }, [showCatalogModal, catalogCategory, catalogSearch]);

  const handleStockUpdate = async (inventoryId, delta) => {
    try {
      await api.patch(`/shop/inventory/${inventoryId}/stock`, { delta });
      // Optimistic update
      setInventory(prev => prev.map(item => {
        if (item.inventory_id === inventoryId) {
          const newCount = Math.max(0, parseInt(item.stock_count, 10) + delta);
          return { ...item, stock_count: newCount, is_available: newCount > 0 };
        }
        return item;
      }));
    } catch (err) {
      console.error('Error adjusting stock:', err);
      alert('Failed to update stock');
      fetchInventory();
    }
  };

  const handleSavePrice = async (e) => {
    e.preventDefault();
    if (!editingItem || !newPrice) return;
    try {
      await api.patch(`/shop/inventory/${editingItem.inventory_id}/price`, { price: parseFloat(newPrice) });
      setInventory(prev => prev.map(item => item.inventory_id === editingItem.inventory_id ? { ...item, price: newPrice } : item));
      setEditingItem(null);
    } catch (err) {
      alert('Failed to update price');
    }
  };

  const handleDeleteItem = async (inventoryId, title) => {
    if (!window.confirm(`Remove "${title}" from your shop inventory?`)) return;
    try {
      await api.delete(`/shop/inventory/${inventoryId}`);
      setInventory(prev => prev.filter(item => item.inventory_id !== inventoryId));
    } catch (err) {
      alert('Failed to remove item');
    }
  };

  const handleAddToInventory = async (e) => {
    e.preventDefault();
    if (!selectedProduct) return;
    setIsSubmitting(true);
    try {
      await api.post('/shop/inventory', {
        product_id: selectedProduct.product_id,
        price: parseFloat(stockPrice),
        stock_count: parseInt(stockQuantity, 10)
      });
      setSelectedProduct(null);
      setStockPrice('');
      setStockQuantity('10');
      setShowCatalogModal(false);
      fetchInventory();
    } catch (err) {
      alert(err.response?.data?.error || 'Failed to add item to inventory');
    } finally {
      setIsSubmitting(false);
    }
  };

  // Stats calculation
  const totalItems = inventory.length;
  const inStockItems = inventory.filter(i => i.stock_count > 0).length;
  const outOfStockItems = inventory.filter(i => i.stock_count === 0).length;

  return (
    <div className="p-lg max-w-[1280px] mx-auto min-h-screen">
      {/* Header */}
      <div className="flex flex-col sm:flex-row justify-between items-start sm:items-center gap-4 mb-lg">
        <div>
          <h1 className="font-display-sm text-display-sm font-bold text-on-surface flex items-center gap-3">
            <span className="material-symbols-outlined text-primary text-3xl">storefront</span>
            Store Inventory & Listings
          </h1>
          <p className="text-body-sm text-on-surface-variant mt-1">
            Manage your shop's stock of books, manuals, notes, and college forms.
          </p>
        </div>

        <button
          onClick={() => setShowCatalogModal(true)}
          className="bg-primary hover:bg-primary/90 text-on-primary px-5 py-2.5 rounded-xl font-label-lg flex items-center gap-2 shadow-sm transition-all shrink-0"
        >
          <span className="material-symbols-outlined text-[20px]">add_shopping_cart</span>
          Add from Master Catalog
        </button>
      </div>

      {/* Quick Metrics */}
      <div className="grid grid-cols-1 sm:grid-cols-3 gap-4 mb-lg">
        <div className="bg-surface-container border border-outline-variant/30 rounded-2xl p-4 flex items-center gap-4">
          <div className="w-12 h-12 rounded-xl bg-primary/10 text-primary flex items-center justify-center">
            <span className="material-symbols-outlined text-2xl">inventory_2</span>
          </div>
          <div>
            <p className="text-xs uppercase font-bold tracking-wider text-on-surface-variant">Total Titles</p>
            <p className="text-2xl font-black text-on-surface">{totalItems}</p>
          </div>
        </div>

        <div className="bg-surface-container border border-outline-variant/30 rounded-2xl p-4 flex items-center gap-4">
          <div className="w-12 h-12 rounded-xl bg-emerald-500/10 text-emerald-500 flex items-center justify-center">
            <span className="material-symbols-outlined text-2xl">check_circle</span>
          </div>
          <div>
            <p className="text-xs uppercase font-bold tracking-wider text-on-surface-variant">In Stock</p>
            <p className="text-2xl font-black text-emerald-500">{inStockItems}</p>
          </div>
        </div>

        <div className="bg-surface-container border border-outline-variant/30 rounded-2xl p-4 flex items-center gap-4">
          <div className="w-12 h-12 rounded-xl bg-rose-500/10 text-rose-500 flex items-center justify-center">
            <span className="material-symbols-outlined text-2xl">error_outline</span>
          </div>
          <div>
            <p className="text-xs uppercase font-bold tracking-wider text-on-surface-variant">Out of Stock</p>
            <p className="text-2xl font-black text-rose-500">{outOfStockItems}</p>
          </div>
        </div>
      </div>

      {/* Filters & Search */}
      <div className="bg-surface-container border border-outline-variant/30 rounded-2xl p-4 mb-lg flex flex-col md:flex-row justify-between items-center gap-4">
        {/* Category Pills */}
        <div className="flex items-center gap-2 overflow-x-auto w-full md:w-auto pb-1 md:pb-0">
          {categories.map(cat => (
            <button
              key={cat}
              onClick={() => setSelectedCategory(cat)}
              className={`px-4 py-1.5 rounded-full text-xs font-semibold whitespace-nowrap transition-colors ${
                selectedCategory === cat
                  ? 'bg-primary text-on-primary'
                  : 'bg-surface-container-high text-on-surface-variant hover:bg-outline-variant/20'
              }`}
            >
              {cat}
            </button>
          ))}
        </div>

        {/* Search input */}
        <div className="flex items-center gap-2 w-full md:w-80">
          <div className="relative flex-1">
            <span className="material-symbols-outlined absolute left-3 top-2.5 text-on-surface-variant text-[18px]">search</span>
            <input
              type="text"
              placeholder="Search by title, subject..."
              value={searchQuery}
              onChange={(e) => setSearchQuery(e.target.value)}
              onKeyDown={(e) => e.key === 'Enter' && fetchInventory()}
              className="w-full bg-surface-container-high pl-9 pr-3 py-2 text-xs rounded-xl border border-outline-variant/40 focus:border-primary outline-none text-on-surface"
            />
          </div>
          <button
            onClick={fetchInventory}
            className="px-3 py-2 bg-surface-container-high hover:bg-outline-variant/20 rounded-xl text-xs font-semibold text-on-surface border border-outline-variant/40"
          >
            Search
          </button>
        </div>
      </div>

      {/* Inventory Listings Grid */}
      {loading ? (
        <div className="flex items-center justify-center py-20 text-on-surface-variant">
          <span className="material-symbols-outlined animate-spin text-3xl text-primary mr-2">autorenew</span>
          <span>Loading inventory items...</span>
        </div>
      ) : inventory.length === 0 ? (
        <div className="bg-surface-container border border-outline-variant/30 rounded-3xl p-12 text-center text-on-surface-variant flex flex-col items-center">
          <div className="w-16 h-16 rounded-full bg-surface-container-highest flex items-center justify-center mb-4 text-on-surface-variant">
            <span className="material-symbols-outlined text-3xl">inventory_2</span>
          </div>
          <h3 className="text-lg font-bold text-on-surface mb-1">No items found in your inventory</h3>
          <p className="text-xs max-w-sm mb-6">
            Tap the button below to browse standard manuals, books, and forms from the Master Catalog and set your stock & price.
          </p>
          <button
            onClick={() => setShowCatalogModal(true)}
            className="bg-primary text-on-primary px-5 py-2.5 rounded-xl text-xs font-bold flex items-center gap-2"
          >
            <span className="material-symbols-outlined text-[18px]">add_shopping_cart</span>
            Add from Master Catalog
          </button>
        </div>
      ) : (
        <div className="grid grid-cols-1 md:grid-cols-2 lg:grid-cols-3 gap-6">
          {inventory.map(item => {
            const isOutOfStock = parseInt(item.stock_count, 10) === 0;
            const isLowStock = !isOutOfStock && parseInt(item.stock_count, 10) <= 3;

            return (
              <div
                key={item.inventory_id}
                className={`bg-surface-container border rounded-2xl overflow-hidden flex flex-col transition-all hover:border-primary/50 ${
                  isOutOfStock ? 'border-rose-500/30 opacity-80' : 'border-outline-variant/30'
                }`}
              >
                {/* Image & Category Banner */}
                <div className="relative h-40 bg-surface-container-highest flex items-center justify-center overflow-hidden">
                  {item.cover_photo_url ? (
                    <img src={item.cover_photo_url} alt={item.title} className="w-full h-full object-cover" />
                  ) : (
                    <span className="material-symbols-outlined text-5xl text-on-surface-variant/40">menu_book</span>
                  )}
                  <span className="absolute top-3 left-3 bg-black/70 backdrop-blur-md text-white text-[10px] font-bold uppercase tracking-wider px-2.5 py-1 rounded-full">
                    {item.category}
                  </span>
                  <div className="absolute top-3 right-3">
                    {isOutOfStock ? (
                      <span className="bg-rose-500 text-white text-[10px] font-bold px-2 py-0.5 rounded-md shadow">
                        Out of Stock
                      </span>
                    ) : isLowStock ? (
                      <span className="bg-amber-500 text-black text-[10px] font-bold px-2 py-0.5 rounded-md shadow">
                        Low Stock ({item.stock_count})
                      </span>
                    ) : (
                      <span className="bg-emerald-500 text-white text-[10px] font-bold px-2 py-0.5 rounded-md shadow">
                        {item.stock_count} Available
                      </span>
                    )}
                  </div>
                </div>

                {/* Content */}
                <div className="p-4 flex-1 flex flex-col justify-between">
                  <div>
                    <h3 className="font-bold text-on-surface text-base line-clamp-1 mb-1">{item.title}</h3>
                    <p className="text-xs text-on-surface-variant font-medium">
                      {item.branch || 'General'} {item.semester ? `• Sem ${item.semester}` : ''}
                    </p>
                    {item.subject && (
                      <p className="text-xs text-on-surface-variant/80 mt-0.5">Subject: {item.subject}</p>
                    )}
                  </div>

                  {/* Price & Stock Adjustment Section */}
                  <div className="mt-4 pt-3 border-t border-outline-variant/30">
                    <div className="flex items-center justify-between mb-3">
                      <div className="flex items-center gap-1.5">
                        <span className="text-xs text-on-surface-variant">Your Price:</span>
                        <span className="font-extrabold text-base text-primary">₹{item.price}</span>
                        <button
                          onClick={() => {
                            setEditingItem(item);
                            setNewPrice(item.price);
                          }}
                          className="text-on-surface-variant hover:text-primary material-symbols-outlined text-[16px]"
                          title="Edit Price"
                        >
                          edit
                        </button>
                      </div>

                      <button
                        onClick={() => handleDeleteItem(item.inventory_id, item.title)}
                        className="text-rose-400 hover:text-rose-500 material-symbols-outlined text-[18px]"
                        title="Remove from inventory"
                      >
                        delete
                      </button>
                    </div>

                    {/* Stock stepper controls */}
                    <div className="bg-surface-container-high p-2 rounded-xl flex items-center justify-between">
                      <span className="text-xs font-semibold text-on-surface-variant">Adjust Stock:</span>
                      <div className="flex items-center gap-1.5">
                        <button
                          onClick={() => handleStockUpdate(item.inventory_id, -1)}
                          disabled={item.stock_count <= 0}
                          className="w-7 h-7 bg-surface-container rounded-lg flex items-center justify-center font-bold text-on-surface hover:bg-outline-variant/30 disabled:opacity-40"
                        >
                          -
                        </button>
                        <span className="w-8 text-center font-black text-sm text-on-surface">{item.stock_count}</span>
                        <button
                          onClick={() => handleStockUpdate(item.inventory_id, 1)}
                          className="w-7 h-7 bg-surface-container rounded-lg flex items-center justify-center font-bold text-on-surface hover:bg-outline-variant/30"
                        >
                          +
                        </button>
                        <button
                          onClick={() => handleStockUpdate(item.inventory_id, 10)}
                          className="bg-primary/10 hover:bg-primary/20 text-primary text-[10px] font-bold px-2 py-1.5 rounded-lg ml-1"
                        >
                          +10
                        </button>
                      </div>
                    </div>
                  </div>
                </div>
              </div>
            );
          })}
        </div>
      )}

      {/* Master Catalog Browser Modal */}
      {showCatalogModal && (
        <div className="fixed inset-0 bg-black/70 backdrop-blur-sm flex items-center justify-center z-50 p-4">
          <div className="bg-surface border border-outline-variant/40 rounded-3xl p-6 w-full max-w-3xl max-h-[88vh] flex flex-col shadow-2xl">
            <div className="flex justify-between items-center pb-4 border-b border-outline-variant/30 shrink-0">
              <div>
                <h2 className="text-xl font-bold text-on-surface flex items-center gap-2">
                  <span className="material-symbols-outlined text-primary">menu_book</span>
                  Master Product Catalog
                </h2>
                <p className="text-xs text-on-surface-variant">Select an item to add to your shop inventory</p>
              </div>
              <button
                onClick={() => {
                  setShowCatalogModal(false);
                  setSelectedProduct(null);
                }}
                className="text-on-surface-variant hover:text-on-surface material-symbols-outlined"
              >
                close
              </button>
            </div>

            {/* Modal Filters */}
            <div className="py-4 flex flex-col sm:flex-row gap-3 shrink-0">
              <div className="flex-1 relative">
                <span className="material-symbols-outlined absolute left-3 top-2.5 text-on-surface-variant text-[18px]">search</span>
                <input
                  type="text"
                  placeholder="Search catalog by title, subject..."
                  value={catalogSearch}
                  onChange={(e) => setCatalogSearch(e.target.value)}
                  className="w-full bg-surface-container-high pl-9 pr-3 py-2 text-xs rounded-xl border border-outline-variant/40 focus:border-primary outline-none text-on-surface"
                />
              </div>
              <select
                value={catalogCategory}
                onChange={(e) => setCatalogCategory(e.target.value)}
                className="bg-surface-container-high px-3 py-2 text-xs rounded-xl border border-outline-variant/40 focus:border-primary outline-none text-on-surface"
              >
                {categories.map(c => <option key={c} value={c}>{c}</option>)}
              </select>
            </div>

            {/* Catalog Items List */}
            <div className="flex-1 overflow-y-auto space-y-3 pr-1">
              {catalogLoading ? (
                <div className="py-12 text-center text-on-surface-variant flex items-center justify-center">
                  <span className="material-symbols-outlined animate-spin text-2xl text-primary mr-2">autorenew</span>
                  <span>Fetching catalog...</span>
                </div>
              ) : catalogItems.length === 0 ? (
                <div className="py-12 text-center text-on-surface-variant">
                  No catalog products found. Contact administrator to add new college titles.
                </div>
              ) : (
                catalogItems.map(prod => (
                  <div
                    key={prod.product_id}
                    className="p-4 rounded-2xl bg-surface-container border border-outline-variant/30 flex flex-col sm:flex-row items-start sm:items-center justify-between gap-4 hover:border-primary/40 transition-colors"
                  >
                    <div className="flex items-center gap-3">
                      <div className="w-12 h-12 rounded-xl bg-surface-container-highest shrink-0 flex items-center justify-center overflow-hidden">
                        {prod.cover_photo_url ? (
                          <img src={prod.cover_photo_url} alt="" className="w-full h-full object-cover" />
                        ) : (
                          <span className="material-symbols-outlined text-on-surface-variant">book</span>
                        )}
                      </div>
                      <div>
                        <div className="flex items-center gap-2">
                          <span className="text-xs font-bold text-on-surface">{prod.title}</span>
                          <span className="text-[10px] bg-secondary-container text-on-secondary-container px-2 py-0.5 rounded-full font-bold">
                            {prod.category}
                          </span>
                        </div>
                        <p className="text-[11px] text-on-surface-variant mt-0.5">
                          {prod.branch} • {prod.course_type} {prod.semester && `• Sem ${prod.semester}`}
                        </p>
                      </div>
                    </div>

                    <div className="shrink-0 flex items-center gap-3 w-full sm:w-auto justify-end">
                      {prod.is_stocked ? (
                        <div className="text-right">
                          <span className="text-[11px] bg-emerald-500/10 text-emerald-500 font-bold px-2 py-1 rounded-md">
                            Already Stocked (₹{prod.current_price}, {prod.current_stock} qty)
                          </span>
                        </div>
                      ) : (
                        <button
                          onClick={() => {
                            setSelectedProduct(prod);
                            setStockPrice('45');
                            setStockQuantity('10');
                          }}
                          className="bg-primary hover:bg-primary/90 text-on-primary text-xs font-bold px-4 py-2 rounded-xl flex items-center gap-1 shadow-sm"
                        >
                          <span className="material-symbols-outlined text-[16px]">add</span>
                          Stock This Item
                        </button>
                      )}
                    </div>
                  </div>
                ))
              )}
            </div>

            {/* Bottom selected product form */}
            {selectedProduct && (
              <form onSubmit={handleAddToInventory} className="mt-4 pt-4 border-t border-outline-variant/30 bg-surface-container p-4 rounded-2xl">
                <div className="text-xs font-bold text-on-surface mb-3 flex items-center justify-between">
                  <span>Set Price & Stock for: <strong className="text-primary">{selectedProduct.title}</strong></span>
                  <button type="button" onClick={() => setSelectedProduct(null)} className="text-on-surface-variant hover:text-on-surface">Cancel</button>
                </div>
                <div className="grid grid-cols-2 gap-3 mb-3">
                  <div>
                    <label className="block text-[11px] font-semibold text-on-surface-variant mb-1">Your Selling Price (₹) *</label>
                    <input
                      required
                      type="number"
                      step="0.5"
                      min="0"
                      value={stockPrice}
                      onChange={(e) => setStockPrice(e.target.value)}
                      placeholder="e.g. 45"
                      className="w-full bg-surface-container-high px-3 py-2 text-xs rounded-xl border border-outline-variant/40 focus:border-primary outline-none text-on-surface font-bold"
                    />
                  </div>
                  <div>
                    <label className="block text-[11px] font-semibold text-on-surface-variant mb-1">Stock Count (Copies) *</label>
                    <input
                      required
                      type="number"
                      min="1"
                      value={stockQuantity}
                      onChange={(e) => setStockQuantity(e.target.value)}
                      placeholder="e.g. 10"
                      className="w-full bg-surface-container-high px-3 py-2 text-xs rounded-xl border border-outline-variant/40 focus:border-primary outline-none text-on-surface font-bold"
                    />
                  </div>
                </div>
                <button
                  type="submit"
                  disabled={isSubmitting}
                  className="w-full bg-primary hover:bg-primary/90 text-on-primary py-2.5 rounded-xl text-xs font-bold shadow transition-all disabled:opacity-50"
                >
                  {isSubmitting ? 'Saving...' : 'Confirm & Add to Shop Inventory'}
                </button>
              </form>
            )}
          </div>
        </div>
      )}

      {/* Edit Price Modal */}
      {editingItem && (
        <div className="fixed inset-0 bg-black/60 backdrop-blur-sm flex items-center justify-center z-50 p-4">
          <div className="bg-surface border border-outline-variant/30 rounded-2xl p-6 w-full max-w-sm shadow-xl">
            <h3 className="font-bold text-on-surface text-base mb-1">Update Price</h3>
            <p className="text-xs text-on-surface-variant mb-4">{editingItem.title}</p>
            <form onSubmit={handleSavePrice} className="space-y-4">
              <div>
                <label className="block text-xs font-semibold text-on-surface-variant mb-1">New Price (₹)</label>
                <input
                  required
                  type="number"
                  step="0.5"
                  value={newPrice}
                  onChange={(e) => setNewPrice(e.target.value)}
                  className="w-full bg-surface-container px-3 py-2 text-sm rounded-xl border border-outline-variant/40 focus:border-primary outline-none text-on-surface font-bold"
                />
              </div>
              <div className="flex gap-2">
                <button
                  type="button"
                  onClick={() => setEditingItem(null)}
                  className="flex-1 py-2 text-xs rounded-xl bg-surface-container hover:bg-outline-variant/20 text-on-surface font-bold"
                >
                  Cancel
                </button>
                <button
                  type="submit"
                  className="flex-1 py-2 text-xs rounded-xl bg-primary text-on-primary font-bold shadow"
                >
                  Save Price
                </button>
              </div>
            </form>
          </div>
        </div>
      )}
    </div>
  );
};

export default MyListings;
