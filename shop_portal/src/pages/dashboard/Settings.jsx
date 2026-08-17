import React, { useState, useEffect } from 'react';
import api from '../../core/api';
import { useAuth } from '../../context/AuthContext';

const Settings = () => {
  const { shopName } = useAuth();
  const [shopStatus, setShopStatus] = useState(null);
  const [isLoading, setIsLoading] = useState(true);
  const [isUpdating, setIsUpdating] = useState(false);

  const fetchStatus = async () => {
    setIsLoading(true);
    try {
      const res = await api.get('/shop/status');
      if (res.data.length > 0) {
        setShopStatus(res.data[0]);
      }
    } catch (err) {
      alert('Failed to load shop status: ' + err.message);
    } finally {
      setIsLoading(false);
    }
  };

  useEffect(() => {
    fetchStatus();
  }, []);

  const handleToggleOpen = async () => {
    if (!shopStatus) return;
    setIsUpdating(true);
    try {
      const newStatus = shopStatus.is_open ? false : true;
      await api.patch('/shop/status', { is_open: newStatus });
      setShopStatus({ ...shopStatus, is_open: newStatus });
    } catch (err) {
      alert('Failed to update status: ' + err.message);
    } finally {
      setIsUpdating(false);
    }
  };

  return (
    <div className="p-4 md:p-8 h-full flex flex-col max-w-[600px] mx-auto w-full">
      <div className="mb-8 text-center">
        <h1 className="text-3xl font-display-lg font-bold mb-2">Shop Settings</h1>
        <p className="text-on-surface-variant font-body-sm">Manage {shopName}'s operations and details</p>
      </div>

      {isLoading ? (
        <div className="text-center text-on-surface-variant mt-10">Loading settings...</div>
      ) : shopStatus ? (
        <div className="bg-surface-container border border-outline-variant/30 p-8 rounded-2xl shadow-xl flex flex-col gap-8">
          
          <div className="flex items-center justify-between p-4 bg-surface-container-highest rounded-xl border border-outline-variant/50">
            <div>
              <h2 className="text-lg font-bold text-on-surface">Store Status</h2>
              <p className="text-sm text-on-surface-variant mt-1">
                Currently {shopStatus.is_open ? <span className="text-green-500 font-bold">Accepting Orders</span> : <span className="text-red-500 font-bold">Closed</span>}
              </p>
            </div>
            
            <button
              onClick={handleToggleOpen}
              disabled={isUpdating}
              className={`w-16 h-8 rounded-full relative transition-all ${shopStatus.is_open ? 'bg-green-500' : 'bg-surface-variant'} ${isUpdating ? 'opacity-50' : ''}`}
            >
              <div className={`absolute top-1 w-6 h-6 bg-white rounded-full transition-all shadow-md ${shopStatus.is_open ? 'left-[calc(100%-28px)]' : 'left-1'}`}></div>
            </button>
          </div>
          
          <div className="pt-6 border-t border-outline-variant/30 flex flex-col gap-4">
            <h3 className="font-semibold text-primary uppercase tracking-wider text-sm">Shop Details</h3>
            <div className="grid grid-cols-[100px_1fr] gap-2 text-sm">
              <div className="text-on-surface-variant">Shop ID</div>
              <div className="font-data-mono">{shopStatus.id}</div>
              
              <div className="text-on-surface-variant">Owner ID</div>
              <div className="font-data-mono">{shopStatus.owner_id}</div>
              
              <div className="text-on-surface-variant">Address</div>
              <div>{shopStatus.address || 'N/A'}</div>
              
              <div className="text-on-surface-variant">Joined</div>
              <div>{new Date(shopStatus.created_at).toLocaleDateString()}</div>
            </div>
          </div>
          
        </div>
      ) : (
        <div className="text-center text-on-surface-variant">No shop profile found.</div>
      )}
    </div>
  );
};

export default Settings;
