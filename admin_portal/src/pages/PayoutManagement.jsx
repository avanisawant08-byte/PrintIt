import React, { useState, useEffect } from 'react';
import api from '../core/api';

const PayoutManagement = () => {
  const [pendingQueue, setPendingQueue] = useState([]);
  const [history, setHistory] = useState([]);
  const [walletsOverview, setWalletsOverview] = useState([]);
  const [isLoading, setIsLoading] = useState(true);
  const [activeTab, setActiveTab] = useState('pending'); // 'pending' | 'history' | 'wallets'

  // Modals
  const [approveModalItem, setApproveModalItem] = useState(null);
  const [rejectModalItem, setRejectModalItem] = useState(null);

  // Form states
  const [utrNumber, setUtrNumber] = useState('');
  const [rejectionReason, setRejectionReason] = useState('');
  const [modalError, setModalError] = useState('');
  const [isSubmitting, setIsSubmitting] = useState(false);

  const fetchData = async () => {
    setIsLoading(true);
    try {
      const [pendingRes, historyRes, walletsRes] = await Promise.all([
        api.get('/admin/payouts/pending'),
        api.get('/admin/payouts/history'),
        api.get('/admin/payouts/wallets')
      ]);

      setPendingQueue(pendingRes.data || []);
      setHistory(historyRes.data || []);
      setWalletsOverview(walletsRes.data || []);
    } catch (err) {
      console.error('Failed to load admin payout data:', err);
    } finally {
      setIsLoading(false);
    }
  };

  useEffect(() => {
    fetchData();
  }, []);

  const handleApproveSubmit = async (e) => {
    e.preventDefault();
    setModalError('');

    if (!utrNumber || !utrNumber.trim()) {
      setModalError('UTR Number is required to confirm bank transfer.');
      return;
    }

    setIsSubmitting(true);
    try {
      await api.put(`/admin/payouts/${approveModalItem.id}/approve`, {
        utrNumber: utrNumber.trim()
      });
      setApproveModalItem(null);
      setUtrNumber('');
      fetchData();
      alert('✅ Payout approved and marked as PROCESSED!');
    } catch (err) {
      setModalError(err.response?.data?.error || 'Failed to approve payout');
    } finally {
      setIsSubmitting(false);
    }
  };

  const handleRejectSubmit = async (e) => {
    e.preventDefault();
    setModalError('');

    if (!rejectionReason || !rejectionReason.trim()) {
      setModalError('Rejection reason is required.');
      return;
    }

    setIsSubmitting(true);
    try {
      await api.put(`/admin/payouts/${rejectModalItem.id}/reject`, {
        rejectionReason: rejectionReason.trim()
      });
      setRejectModalItem(null);
      setRejectionReason('');
      fetchData();
      alert('✅ Withdrawal request rejected and wallet balance restored.');
    } catch (err) {
      setModalError(err.response?.data?.error || 'Failed to reject withdrawal');
    } finally {
      setIsSubmitting(false);
    }
  };

  return (
    <div className="p-4 md:p-8 h-full flex flex-col max-w-7xl mx-auto w-full">
      {/* Page Title */}
      <div className="flex flex-col md:flex-row md:items-center justify-between gap-4 mb-6">
        <div>
          <h1 className="text-2xl font-bold text-on-surface">Admin Payout Management</h1>
          <p className="text-on-surface-variant text-sm">Review shopkeeper withdrawal requests, record UTR transfers, and monitor wallet balances</p>
        </div>
        <button
          onClick={fetchData}
          className="self-start md:self-auto bg-surface-container-high hover:bg-surface-container-highest border border-outline-variant px-4 py-2 rounded-xl text-xs font-semibold text-on-surface flex items-center gap-2"
        >
          <span>Refresh Queue</span>
        </button>
      </div>

      {/* Tabs */}
      <div className="flex border-b border-outline-variant/30 mb-6 gap-6">
        <button
          onClick={() => setActiveTab('pending')}
          className={`pb-3 text-sm font-semibold flex items-center gap-2 border-b-2 transition-colors ${
            activeTab === 'pending'
              ? 'border-primary text-primary'
              : 'border-transparent text-on-surface-variant hover:text-on-surface'
          }`}
        >
          Pending Queue ({pendingQueue.length})
        </button>
        <button
          onClick={() => setActiveTab('history')}
          className={`pb-3 text-sm font-semibold flex items-center gap-2 border-b-2 transition-colors ${
            activeTab === 'history'
              ? 'border-primary text-primary'
              : 'border-transparent text-on-surface-variant hover:text-on-surface'
          }`}
        >
          Payout History ({history.length})
        </button>
        <button
          onClick={() => setActiveTab('wallets')}
          className={`pb-3 text-sm font-semibold flex items-center gap-2 border-b-2 transition-colors ${
            activeTab === 'wallets'
              ? 'border-primary text-primary'
              : 'border-transparent text-on-surface-variant hover:text-on-surface'
          }`}
        >
          Shop Wallets Overview ({walletsOverview.length})
        </button>
      </div>

      {/* TAB 1: PENDING QUEUE */}
      {activeTab === 'pending' && (
        <div className="space-y-4">
          {isLoading ? (
            <div className="p-8 text-center text-on-surface-variant">Loading pending queue...</div>
          ) : pendingQueue.length === 0 ? (
            <div className="bg-surface-container border border-outline-variant/30 rounded-2xl p-8 text-center text-on-surface-variant">
              🎉 No pending withdrawal requests! All payouts are up to date.
            </div>
          ) : (
            <div className="grid grid-cols-1 gap-4">
              {pendingQueue.map((item) => (
                <div
                  key={item.id}
                  className="bg-surface-container border border-outline-variant/30 p-6 rounded-2xl shadow-sm flex flex-col lg:flex-row lg:items-center justify-between gap-6"
                >
                  {/* Left info */}
                  <div className="space-y-3 flex-1">
                    <div className="flex items-center gap-3">
                      <h3 className="font-bold text-lg text-on-surface">{item.shopName}</h3>
                      <span className="bg-amber-500/20 text-amber-400 border border-amber-500/30 px-3 py-0.5 rounded-full text-xs font-bold uppercase">
                        {item.status}
                      </span>
                    </div>

                    <div className="grid grid-cols-1 sm:grid-cols-2 md:grid-cols-3 gap-4 text-xs">
                      <div>
                        <p className="text-on-surface-variant">Requested Amount:</p>
                        <p className="text-xl font-bold text-emerald-400">₹{item.amount.toFixed(2)}</p>
                      </div>
                      <div>
                        <p className="text-on-surface-variant">Requested Date:</p>
                        <p className="font-mono text-on-surface font-semibold">{new Date(item.requestedAt).toLocaleString()}</p>
                      </div>
                      <div>
                        <p className="text-on-surface-variant">Shop Phone:</p>
                        <p className="font-mono text-on-surface">{item.shopPhone || 'N/A'}</p>
                      </div>
                    </div>

                    {/* Bank Details Box */}
                    {item.bankAccount && (
                      <div className="bg-surface-container-high border border-outline-variant/20 p-3 rounded-xl text-xs space-y-1 font-mono">
                        <p className="font-bold text-primary mb-1">🏦 Destination Bank Details:</p>
                        <p className="text-on-surface"><span className="text-on-surface-variant font-sans">Bank:</span> {item.bankAccount.bankName} ({item.bankAccount.accountType || 'savings'})</p>
                        <p className="text-on-surface"><span className="text-on-surface-variant font-sans">Holder:</span> {item.bankAccount.accountHolderName}</p>
                        <p className="text-on-surface"><span className="text-on-surface-variant font-sans">Account No:</span> <strong className="text-emerald-400">{item.bankAccount.accountNumber}</strong></p>
                        <p className="text-on-surface"><span className="text-on-surface-variant font-sans">IFSC Code:</span> {item.bankAccount.ifscCode}</p>
                        {item.bankAccount.upiId && <p className="text-on-surface"><span className="text-on-surface-variant font-sans">UPI ID:</span> {item.bankAccount.upiId}</p>}
                      </div>
                    )}
                  </div>

                  {/* Actions */}
                  <div className="flex lg:flex-col gap-3 min-w-[180px]">
                    <button
                      onClick={() => {
                        setApproveModalItem(item);
                        setUtrNumber('');
                        setModalError('');
                      }}
                      className="flex-1 bg-emerald-600 hover:bg-emerald-500 text-white font-bold py-2.5 px-4 rounded-xl text-sm shadow-md transition-colors"
                    >
                      Approve Payout
                    </button>
                    <button
                      onClick={() => {
                        setRejectModalItem(item);
                        setRejectionReason('');
                        setModalError('');
                      }}
                      className="flex-1 bg-red-500/10 hover:bg-red-500/20 text-red-400 border border-red-500/30 font-bold py-2.5 px-4 rounded-xl text-sm transition-colors"
                    >
                      Reject Request
                    </button>
                  </div>
                </div>
              ))}
            </div>
          )}
        </div>
      )}

      {/* TAB 2: PAYOUT HISTORY */}
      {activeTab === 'history' && (
        <div className="bg-surface-container border border-outline-variant/30 rounded-2xl overflow-x-auto shadow-sm">
          {history.length === 0 ? (
            <div className="p-8 text-center text-on-surface-variant">No processed or rejected payouts in history.</div>
          ) : (
            <table className="w-full text-left border-collapse">
              <thead>
                <tr className="bg-black/30 border-b border-outline-variant/30 text-[0.75rem] uppercase tracking-wider text-on-surface-variant">
                  <th className="p-4">Requested At</th>
                  <th className="p-4">Shop</th>
                  <th className="p-4">Amount</th>
                  <th className="p-4">Bank Account</th>
                  <th className="p-4">Status</th>
                  <th className="p-4">UTR Number / Reason</th>
                  <th className="p-4">Processed Date</th>
                </tr>
              </thead>
              <tbody className="divide-y divide-outline-variant/10 text-sm">
                {history.map((h) => (
                  <tr key={h.id} className="hover:bg-surface-variant/30 transition-colors">
                    <td className="p-4 text-xs font-mono text-on-surface-variant">
                      {new Date(h.requestedAt).toLocaleString()}
                    </td>
                    <td className="p-4 font-semibold text-on-surface">{h.shopName}</td>
                    <td className="p-4 font-bold text-on-surface">₹{h.amount.toFixed(2)}</td>
                    <td className="p-4 text-xs font-mono">
                      {h.bankAccount ? `${h.bankAccount.bankName} (${h.bankAccount.accountNumberMasked})` : '—'}
                    </td>
                    <td className="p-4">
                      <span
                        className={`px-3 py-1 rounded-full text-xs font-bold uppercase ${
                          h.status === 'processed'
                            ? 'bg-emerald-500/20 text-emerald-400 border border-emerald-500/30'
                            : 'bg-red-500/20 text-red-400 border border-red-500/30'
                        }`}
                      >
                        {h.status}
                      </span>
                    </td>
                    <td className="p-4 text-xs font-mono">
                      {h.utrNumber ? (
                        <span className="text-emerald-400 font-bold">UTR: {h.utrNumber}</span>
                      ) : (
                        <span className="text-red-400">{h.rejectionReason || 'N/A'}</span>
                      )}
                    </td>
                    <td className="p-4 text-xs font-mono text-on-surface-variant">
                      {h.processedAt ? new Date(h.processedAt).toLocaleString() : '—'}
                    </td>
                  </tr>
                ))}
              </tbody>
            </table>
          )}
        </div>
      )}

      {/* TAB 3: SHOP WALLETS OVERVIEW */}
      {activeTab === 'wallets' && (
        <div className="bg-surface-container border border-outline-variant/30 rounded-2xl overflow-x-auto shadow-sm">
          {walletsOverview.length === 0 ? (
            <div className="p-8 text-center text-on-surface-variant">No shops found.</div>
          ) : (
            <table className="w-full text-left border-collapse">
              <thead>
                <tr className="bg-black/30 border-b border-outline-variant/30 text-[0.75rem] uppercase tracking-wider text-on-surface-variant">
                  <th className="p-4">Shop Name</th>
                  <th className="p-4">Phone</th>
                  <th className="p-4 text-right">Available Balance</th>
                  <th className="p-4 text-right">Pending Balance</th>
                  <th className="p-4 text-right">Total Earned</th>
                  <th className="p-4 text-right">Total Withdrawn</th>
                </tr>
              </thead>
              <tbody className="divide-y divide-outline-variant/10 text-sm">
                {walletsOverview.map((w) => (
                  <tr key={w.shopId} className="hover:bg-surface-variant/30 transition-colors">
                    <td className="p-4 font-semibold text-on-surface">{w.shopName}</td>
                    <td className="p-4 text-xs font-mono text-on-surface-variant">{w.shopPhone || '—'}</td>
                    <td className="p-4 text-right font-bold text-emerald-400 font-mono">₹{w.availableBalance.toFixed(2)}</td>
                    <td className="p-4 text-right font-bold text-amber-400 font-mono">₹{w.pendingBalance.toFixed(2)}</td>
                    <td className="p-4 text-right font-mono text-on-surface">₹{w.totalEarned.toFixed(2)}</td>
                    <td className="p-4 text-right font-mono text-on-surface-variant">₹{w.totalWithdrawn.toFixed(2)}</td>
                  </tr>
                ))}
              </tbody>
            </table>
          )}
        </div>
      )}

      {/* APPROVE MODAL */}
      {approveModalItem && (
        <div className="fixed inset-0 z-50 bg-black/70 backdrop-blur-sm flex items-center justify-center p-4">
          <div 
            className="bg-surface-container border border-outline-variant/30 rounded-2xl p-6 shadow-2xl max-h-[90vh] overflow-y-auto"
            style={{ width: '100%', maxWidth: '480px', minWidth: '320px' }}
          >
            <h2 className="text-lg font-bold text-on-surface mb-2">Approve Payout Request</h2>
            <p className="text-xs text-on-surface-variant mb-4">
              Enter the bank transfer UTR / Reference number after processing the payout.
            </p>

            {modalError && (
              <div className="bg-red-500/10 border border-red-500/30 text-red-400 text-xs p-3 rounded-xl mb-4">
                {modalError}
              </div>
            )}

            <div className="bg-surface-container-high p-4 rounded-xl text-xs space-y-2 mb-4">
              <p>Shop: <strong className="text-on-surface">{approveModalItem.shopName}</strong></p>
              <p>Amount: <strong className="text-emerald-400 text-sm">₹{approveModalItem.amount.toFixed(2)}</strong></p>
              {approveModalItem.bankAccount && (
                <>
                  <p>Bank: <strong>{approveModalItem.bankAccount.bankName}</strong></p>
                  <p>Account No: <strong className="font-mono text-emerald-400">{approveModalItem.bankAccount.accountNumber}</strong></p>
                  <p>IFSC: <strong className="font-mono">{approveModalItem.bankAccount.ifscCode}</strong></p>
                </>
              )}
            </div>

            <form onSubmit={handleApproveSubmit} className="space-y-4">
              <div>
                <label className="block text-xs font-semibold text-on-surface-variant mb-1">Bank UTR / Transaction Reference Number *</label>
                <input
                  type="text"
                  required
                  value={utrNumber}
                  onChange={(e) => setUtrNumber(e.target.value)}
                  placeholder="e.g. UTR123456789012"
                  className="w-full bg-surface-container-highest border border-outline-variant/50 rounded-xl p-3 text-on-surface text-sm focus:outline-none focus:border-primary font-mono uppercase"
                />
              </div>

              <div className="flex gap-3 pt-2">
                <button
                  type="button"
                  onClick={() => setApproveModalItem(null)}
                  className="flex-1 bg-surface-container-high text-on-surface text-sm py-2.5 rounded-xl font-medium"
                >
                  Cancel
                </button>
                <button
                  type="submit"
                  disabled={isSubmitting}
                  className="flex-1 bg-emerald-600 hover:bg-emerald-500 text-white text-sm py-2.5 rounded-xl font-semibold shadow-md disabled:opacity-50"
                >
                  {isSubmitting ? 'Approving...' : 'Confirm & Mark Processed'}
                </button>
              </div>
            </form>
          </div>
        </div>
      )}

      {/* REJECT MODAL */}
      {rejectModalItem && (
        <div className="fixed inset-0 z-50 bg-black/70 backdrop-blur-sm flex items-center justify-center p-4">
          <div 
            className="bg-surface-container border border-outline-variant/30 rounded-2xl p-6 shadow-2xl max-h-[90vh] overflow-y-auto"
            style={{ width: '100%', maxWidth: '480px', minWidth: '320px' }}
          >
            <h2 className="text-lg font-bold text-on-surface mb-2">Reject Withdrawal Request</h2>
            <p className="text-xs text-on-surface-variant mb-4">
              The requested amount (₹{rejectModalItem.amount.toFixed(2)}) will be restored back to the shopkeeper's wallet.
            </p>

            {modalError && (
              <div className="bg-red-500/10 border border-red-500/30 text-red-400 text-xs p-3 rounded-xl mb-4">
                {modalError}
              </div>
            )}

            <form onSubmit={handleRejectSubmit} className="space-y-4">
              <div>
                <label className="block text-xs font-semibold text-on-surface-variant mb-1">Rejection Reason *</label>
                <textarea
                  required
                  rows="3"
                  value={rejectionReason}
                  onChange={(e) => setRejectionReason(e.target.value)}
                  placeholder="e.g. Incorrect bank account details / IFSC mismatch"
                  className="w-full bg-surface-container-highest border border-outline-variant/50 rounded-xl p-3 text-on-surface text-sm focus:outline-none focus:border-primary"
                />
              </div>

              <div className="flex gap-3 pt-2">
                <button
                  type="button"
                  onClick={() => setRejectModalItem(null)}
                  className="flex-1 bg-surface-container-high text-on-surface text-sm py-2.5 rounded-xl font-medium"
                >
                  Cancel
                </button>
                <button
                  type="submit"
                  disabled={isSubmitting}
                  className="flex-1 bg-red-600 hover:bg-red-500 text-white text-sm py-2.5 rounded-xl font-semibold shadow-md disabled:opacity-50"
                >
                  {isSubmitting ? 'Rejecting...' : 'Reject Request'}
                </button>
              </div>
            </form>
          </div>
        </div>
      )}
    </div>
  );
};

export default PayoutManagement;
