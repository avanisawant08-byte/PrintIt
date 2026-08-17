import React, { useState, useEffect } from 'react';
import api from '../../core/api';

const Wallet = () => {
  const [wallet, setWallet] = useState({
    availableBalance: 0,
    pendingBalance: 0,
    totalEarned: 0,
    totalWithdrawn: 0
  });
  const [bankAccounts, setBankAccounts] = useState([]);
  const [transactions, setTransactions] = useState([]);
  const [withdrawals, setWithdrawals] = useState([]);
  const [isLoading, setIsLoading] = useState(true);
  const [activeTab, setActiveTab] = useState('ledger'); // 'ledger' | 'withdrawals' | 'banks'

  // Modal States
  const [showWithdrawModal, setShowWithdrawModal] = useState(false);
  const [showAddBankModal, setShowAddBankModal] = useState(false);

  // Withdraw Form
  const [withdrawAmount, setWithdrawAmount] = useState('');
  const [selectedBankId, setSelectedBankId] = useState('');
  const [withdrawError, setWithdrawError] = useState('');
  const [isSubmittingWithdraw, setIsSubmittingWithdraw] = useState(false);

  // Bank Form
  const [bankFormData, setBankFormData] = useState({
    accountHolderName: '',
    accountNumber: '',
    confirmAccountNumber: '',
    ifscCode: '',
    bankName: '',
    accountType: 'savings',
    upiId: '',
    isPrimary: false
  });
  const [bankError, setBankError] = useState('');
  const [isSubmittingBank, setIsSubmittingBank] = useState(false);

  // Filters
  const [typeFilter, setTypeFilter] = useState('all');

  const [fetchError, setFetchError] = useState('');

  const fetchData = async () => {
    setIsLoading(true);
    setFetchError('');
    try {
      const [walletRes, bankRes, txRes, withRes] = await Promise.all([
        api.get('/shop/wallet').catch(err => {
          console.error('Error loading /shop/wallet:', err);
          return { data: { availableBalance: 0, pendingBalance: 0, totalEarned: 0, totalWithdrawn: 0 } };
        }),
        api.get('/shop/bank-accounts').catch(err => {
          console.error('Error loading /shop/bank-accounts:', err);
          return { data: [] };
        }),
        api.get(`/shop/wallet/transactions${typeFilter !== 'all' ? `?type=${typeFilter}` : ''}`).catch(err => {
          console.error('Error loading /shop/wallet/transactions:', err);
          return { data: { transactions: [] } };
        }),
        api.get('/shop/wallet/withdrawals').catch(err => {
          console.error('Error loading /shop/wallet/withdrawals:', err);
          return { data: [] };
        })
      ]);

      setWallet(walletRes.data || { availableBalance: 0, pendingBalance: 0, totalEarned: 0, totalWithdrawn: 0 });
      setBankAccounts(Array.isArray(bankRes.data) ? bankRes.data : []);
      setTransactions(txRes.data?.transactions || []);
      setWithdrawals(Array.isArray(withRes.data) ? withRes.data : []);

      const accounts = Array.isArray(bankRes.data) ? bankRes.data : [];
      const primaryBank = accounts.find(b => b.isPrimary) || accounts[0];
      if (primaryBank) {
        setSelectedBankId(primaryBank.id);
      }
    } catch (err) {
      console.error('Failed to load wallet data:', err);
      setFetchError(err.response?.data?.error || err.message || 'Failed to load wallet data');
    } finally {
      setIsLoading(false);
    }
  };

  useEffect(() => {
    fetchData();
  }, [typeFilter]);

  const handleWithdrawSubmit = async (e) => {
    e.preventDefault();
    setWithdrawError('');
    const amt = parseFloat(withdrawAmount);

    if (isNaN(amt) || amt < 100) {
      setWithdrawError('Minimum withdrawal amount is ₹100');
      return;
    }
    if (amt > wallet.availableBalance) {
      setWithdrawError(`Amount exceeds available balance (₹${wallet.availableBalance.toFixed(2)})`);
      return;
    }
    if (!selectedBankId) {
      setWithdrawError('Please select a bank account');
      return;
    }

    setIsSubmittingWithdraw(true);
    try {
      await api.post('/shop/wallet/withdraw', {
        amount: amt,
        bankAccountId: selectedBankId
      });
      setShowWithdrawModal(false);
      setWithdrawAmount('');
      fetchData();
      alert('✅ Withdrawal request submitted successfully!');
    } catch (err) {
      setWithdrawError(err.response?.data?.error || 'Failed to submit withdrawal request');
    } finally {
      setIsSubmittingWithdraw(false);
    }
  };

  const handleAddBankSubmit = async (e) => {
    e.preventDefault();
    setBankError('');

    if (bankFormData.accountNumber !== bankFormData.confirmAccountNumber) {
      setBankError('Account numbers do not match');
      return;
    }

    setIsSubmittingBank(true);
    try {
      await api.post('/shop/bank-accounts', bankFormData);
      setShowAddBankModal(false);
      setBankFormData({
        accountHolderName: '',
        accountNumber: '',
        confirmAccountNumber: '',
        ifscCode: '',
        bankName: '',
        accountType: 'savings',
        upiId: '',
        isPrimary: false
      });
      fetchData();
      alert('✅ Bank account added successfully!');
    } catch (err) {
      setBankError(err.response?.data?.error || 'Failed to add bank account');
    } finally {
      setIsSubmittingBank(false);
    }
  };

  const handleSetPrimaryBank = async (id) => {
    try {
      await api.put(`/shop/bank-accounts/${id}/primary`);
      fetchData();
    } catch (err) {
      alert('Failed to set primary bank account: ' + (err.response?.data?.error || err.message));
    }
  };

  const handleDeleteBank = async (id) => {
    if (!window.confirm('Are you sure you want to remove this bank account?')) return;
    try {
      await api.delete(`/shop/bank-accounts/${id}`);
      fetchData();
    } catch (err) {
      alert('Failed to delete bank account: ' + (err.response?.data?.error || err.message));
    }
  };

  return (
    <div className="p-4 md:p-8 h-full flex flex-col max-w-7xl mx-auto w-full">
      {/* Header & Main Cards */}
      <div className="flex flex-col md:flex-row md:items-center justify-between gap-4 mb-6">
        <div>
          <h1 className="text-2xl font-bold text-on-surface">Shopkeeper Wallet & Payouts</h1>
          <p className="text-on-surface-variant text-sm">Track earnings, transaction history, and request bank withdrawals</p>
        </div>
        <div className="flex gap-3">
          <button
            onClick={() => setShowAddBankModal(true)}
            className="flex items-center gap-2 bg-surface-container-high hover:bg-surface-container-highest border border-outline-variant text-on-surface px-4 py-2 rounded-xl text-sm font-medium transition-colors"
          >
            <span className="material-symbols-outlined text-[18px]">account_balance</span>
            Manage Bank Accounts
          </button>
          <button
            onClick={() => setShowWithdrawModal(true)}
            disabled={wallet.availableBalance < 100}
            className="flex items-center gap-2 bg-primary hover:bg-primary/90 text-on-primary px-5 py-2 rounded-xl text-sm font-semibold shadow-md disabled:opacity-50 transition-colors"
          >
            <span className="material-symbols-outlined text-[18px]">payments</span>
            Request Withdrawal
          </button>
        </div>
      </div>

      {/* Metrics Grid */}
      <div className="grid grid-cols-1 sm:grid-cols-2 lg:grid-cols-4 gap-4 mb-8">
        {/* Available Balance */}
        <div className="bg-surface-container border border-primary/30 p-5 rounded-2xl relative overflow-hidden shadow-sm">
          <div className="flex justify-between items-start mb-2">
            <span className="text-xs font-semibold uppercase tracking-wider text-primary">Available Balance</span>
            <span className="material-symbols-outlined text-primary text-2xl">account_balance_wallet</span>
          </div>
          <div className="text-3xl font-extrabold text-on-surface mb-1">
            ₹{wallet.availableBalance.toFixed(2)}
          </div>
          <p className="text-xs text-on-surface-variant">Ready for immediate withdrawal</p>
        </div>

        {/* Pending Balance */}
        <div className="bg-surface-container border border-outline-variant/30 p-5 rounded-2xl shadow-sm">
          <div className="flex justify-between items-start mb-2">
            <span className="text-xs font-semibold uppercase tracking-wider text-amber-400">Pending Balance</span>
            <span className="material-symbols-outlined text-amber-400 text-2xl">pending</span>
          </div>
          <div className="text-3xl font-extrabold text-on-surface mb-1">
            ₹{wallet.pendingBalance.toFixed(2)}
          </div>
          <p className="text-xs text-on-surface-variant">Earnings awaiting order confirmation</p>
        </div>

        {/* Total Earned */}
        <div className="bg-surface-container border border-outline-variant/30 p-5 rounded-2xl shadow-sm">
          <div className="flex justify-between items-start mb-2">
            <span className="text-xs font-semibold uppercase tracking-wider text-emerald-400">Lifetime Earned</span>
            <span className="material-symbols-outlined text-emerald-400 text-2xl">trending_up</span>
          </div>
          <div className="text-3xl font-extrabold text-on-surface mb-1">
            ₹{wallet.totalEarned.toFixed(2)}
          </div>
          <p className="text-xs text-on-surface-variant">All-time gross credits</p>
        </div>

        {/* Total Withdrawn */}
        <div className="bg-surface-container border border-outline-variant/30 p-5 rounded-2xl shadow-sm">
          <div className="flex justify-between items-start mb-2">
            <span className="text-xs font-semibold uppercase tracking-wider text-sky-400">Total Withdrawn</span>
            <span className="material-symbols-outlined text-sky-400 text-2xl">output</span>
          </div>
          <div className="text-3xl font-extrabold text-on-surface mb-1">
            ₹{wallet.totalWithdrawn.toFixed(2)}
          </div>
          <p className="text-xs text-on-surface-variant">Processed payouts to bank</p>
        </div>
      </div>

      {/* Tabs */}
      <div className="flex border-b border-outline-variant/30 mb-6 gap-6">
        <button
          onClick={() => setActiveTab('ledger')}
          className={`pb-3 text-sm font-semibold flex items-center gap-2 border-b-2 transition-colors ${
            activeTab === 'ledger'
              ? 'border-primary text-primary'
              : 'border-transparent text-on-surface-variant hover:text-on-surface'
          }`}
        >
          <span className="material-symbols-outlined text-[18px]">receipt_long</span>
          Transaction Ledger
        </button>
        <button
          onClick={() => setActiveTab('withdrawals')}
          className={`pb-3 text-sm font-semibold flex items-center gap-2 border-b-2 transition-colors ${
            activeTab === 'withdrawals'
              ? 'border-primary text-primary'
              : 'border-transparent text-on-surface-variant hover:text-on-surface'
          }`}
        >
          <span className="material-symbols-outlined text-[18px]">history</span>
          Withdrawal Requests ({withdrawals.length})
        </button>
        <button
          onClick={() => setActiveTab('banks')}
          className={`pb-3 text-sm font-semibold flex items-center gap-2 border-b-2 transition-colors ${
            activeTab === 'banks'
              ? 'border-primary text-primary'
              : 'border-transparent text-on-surface-variant hover:text-on-surface'
          }`}
        >
          <span className="material-symbols-outlined text-[18px]">account_balance</span>
          Saved Bank Accounts ({bankAccounts.length}/2)
        </button>
      </div>

      {/* Tab 1: Transaction Ledger */}
      {activeTab === 'ledger' && (
        <div className="flex-1 flex flex-col">
          <div className="flex justify-between items-center mb-4">
            <h2 className="text-lg font-semibold text-on-surface">Recent Wallet Transactions</h2>
            <div className="flex items-center gap-2">
              <label className="text-xs text-on-surface-variant">Filter:</label>
              <select
                value={typeFilter}
                onChange={(e) => setTypeFilter(e.target.value)}
                className="bg-surface-container-highest border border-outline-variant/50 rounded-lg text-xs p-2 text-on-surface focus:outline-none focus:border-primary"
              >
                <option value="all">All Types</option>
                <option value="credit">Credit</option>
                <option value="withdrawal">Withdrawal</option>
                <option value="debit">Debit</option>
                <option value="refund">Refund</option>
              </select>
            </div>
          </div>

          <div className="bg-surface-container border border-outline-variant/30 rounded-2xl overflow-x-auto shadow-sm">
            {isLoading ? (
              <div className="p-8 text-center text-on-surface-variant">Loading transactions...</div>
            ) : transactions.length === 0 ? (
              <div className="p-8 text-center text-on-surface-variant">No transaction entries found.</div>
            ) : (
              <table className="w-full text-left border-collapse">
                <thead>
                  <tr className="bg-black/30 border-b border-outline-variant/30 text-[0.75rem] uppercase tracking-wider text-on-surface-variant">
                    <th className="p-4">Date & Time</th>
                    <th className="p-4">Description</th>
                    <th className="p-4">Type</th>
                    <th className="p-4 text-right">Gross Amount</th>
                    <th className="p-4 text-right">Platform Fee</th>
                    <th className="p-4 text-right">Net Credited/Debited</th>
                    <th className="p-4 text-right">Running Balance</th>
                    <th className="p-4 text-center">Status</th>
                  </tr>
                </thead>
                <tbody className="divide-y divide-outline-variant/10 text-sm">
                  {transactions.map((tx) => (
                    <tr key={tx.id} className="hover:bg-surface-variant/30 transition-colors">
                      <td className="p-4 text-xs font-mono text-on-surface-variant">
                        {new Date(tx.createdAt).toLocaleString()}
                      </td>
                      <td className="p-4 font-medium text-on-surface">
                        {tx.description || (tx.type === 'withdrawal' ? 'Withdrawal Request' : 'Order Credit')}
                      </td>
                      <td className="p-4 uppercase text-xs font-bold">
                        <span
                          className={`px-2 py-1 rounded-md ${
                            tx.type === 'credit'
                              ? 'bg-emerald-500/20 text-emerald-400'
                              : tx.type === 'withdrawal'
                              ? 'bg-amber-500/20 text-amber-400'
                              : tx.type === 'refund'
                              ? 'bg-sky-500/20 text-sky-400'
                              : 'bg-red-500/20 text-red-400'
                          }`}
                        >
                          {tx.type}
                        </span>
                      </td>
                      <td className="p-4 text-right font-mono">
                        {tx.grossAmount > 0 ? `₹${tx.grossAmount.toFixed(2)}` : '—'}
                      </td>
                      <td className="p-4 text-right font-mono text-on-surface-variant">
                        {tx.platformFee > 0 ? `₹${tx.platformFee.toFixed(2)}` : '—'}
                      </td>
                      <td className={`p-4 text-right font-mono font-bold ${tx.netAmount >= 0 ? 'text-emerald-400' : 'text-amber-400'}`}>
                        {tx.netAmount >= 0 ? `+₹${tx.netAmount.toFixed(2)}` : `-₹${Math.abs(tx.netAmount).toFixed(2)}`}
                      </td>
                      <td className="p-4 text-right font-mono font-bold text-on-surface">
                        ₹{tx.balanceAfter.toFixed(2)}
                      </td>
                      <td className="p-4 text-center">
                        <span className="text-xs px-2 py-1 rounded-full bg-surface-container-high border border-outline-variant/30 text-on-surface-variant">
                          {tx.status}
                        </span>
                      </td>
                    </tr>
                  ))}
                </tbody>
              </table>
            )}
          </div>
        </div>
      )}

      {/* Tab 2: Withdrawal Requests */}
      {activeTab === 'withdrawals' && (
        <div className="bg-surface-container border border-outline-variant/30 rounded-2xl overflow-x-auto shadow-sm">
          {withdrawals.length === 0 ? (
            <div className="p-8 text-center text-on-surface-variant">No withdrawal requests submitted yet.</div>
          ) : (
            <table className="w-full text-left border-collapse">
              <thead>
                <tr className="bg-black/30 border-b border-outline-variant/30 text-[0.75rem] uppercase tracking-wider text-on-surface-variant">
                  <th className="p-4">Requested At</th>
                  <th className="p-4">Amount</th>
                  <th className="p-4">Bank Account</th>
                  <th className="p-4">Status</th>
                  <th className="p-4">UTR Number / Note</th>
                </tr>
              </thead>
              <tbody className="divide-y divide-outline-variant/10 text-sm">
                {withdrawals.map((w) => (
                  <tr key={w.id} className="hover:bg-surface-variant/30 transition-colors">
                    <td className="p-4 text-xs font-mono text-on-surface-variant">
                      {new Date(w.requestedAt).toLocaleString()}
                    </td>
                    <td className="p-4 font-bold text-on-surface">₹{w.amount.toFixed(2)}</td>
                    <td className="p-4">
                      {w.bankAccount ? (
                        <div>
                          <p className="font-semibold text-xs">{w.bankAccount.bankName}</p>
                          <p className="text-xs font-mono text-on-surface-variant">{w.bankAccount.accountNumberMasked}</p>
                        </div>
                      ) : (
                        <span className="text-xs text-on-surface-variant">—</span>
                      )}
                    </td>
                    <td className="p-4">
                      <span
                        className={`px-3 py-1 rounded-full text-xs font-semibold ${
                          w.status === 'processed'
                            ? 'bg-emerald-500/20 text-emerald-400 border border-emerald-500/30'
                            : w.status === 'pending'
                            ? 'bg-amber-500/20 text-amber-400 border border-amber-500/30'
                            : 'bg-red-500/20 text-red-400 border border-red-500/30'
                        }`}
                      >
                        {w.status.toUpperCase()}
                      </span>
                    </td>
                    <td className="p-4 font-mono text-xs">
                      {w.utrNumber ? (
                        <span className="text-emerald-400 font-bold">UTR: {w.utrNumber}</span>
                      ) : w.rejectionReason ? (
                        <span className="text-red-400">{w.rejectionReason}</span>
                      ) : (
                        <span className="text-on-surface-variant opacity-50">Awaiting processing...</span>
                      )}
                    </td>
                  </tr>
                ))}
              </tbody>
            </table>
          )}
        </div>
      )}

      {/* Tab 3: Saved Bank Accounts */}
      {activeTab === 'banks' && (
        <div className="grid grid-cols-1 md:grid-cols-2 gap-4">
          {bankAccounts.map((acc) => (
            <div
              key={acc.id}
              className={`bg-surface-container border p-5 rounded-2xl relative shadow-sm flex flex-col justify-between ${
                acc.isPrimary ? 'border-primary' : 'border-outline-variant/30'
              }`}
            >
              <div>
                <div className="flex justify-between items-start mb-3">
                  <div className="flex items-center gap-2">
                    <span className="material-symbols-outlined text-primary text-2xl">account_balance</span>
                    <div>
                      <h3 className="font-bold text-on-surface text-base">{acc.bankName}</h3>
                      <p className="text-xs text-on-surface-variant uppercase">{acc.accountType} Account</p>
                    </div>
                  </div>
                  {acc.isPrimary && (
                    <span className="bg-primary/20 text-primary border border-primary/30 px-3 py-1 rounded-full text-xs font-semibold">
                      Primary Payout
                    </span>
                  )}
                </div>

                <div className="space-y-1.5 text-sm my-4 font-mono">
                  <p className="text-on-surface-variant">Holder: <span className="font-semibold text-on-surface">{acc.accountHolderName}</span></p>
                  <p className="text-on-surface-variant">Account No: <span className="font-semibold text-on-surface">{acc.accountNumberMasked}</span></p>
                  <p className="text-on-surface-variant">IFSC Code: <span className="font-semibold text-on-surface">{acc.ifscCode}</span></p>
                  {acc.upiId && <p className="text-on-surface-variant">UPI ID: <span className="font-semibold text-on-surface">{acc.upiId}</span></p>}
                </div>
              </div>

              <div className="flex gap-2 pt-3 border-t border-outline-variant/20">
                {!acc.isPrimary && (
                  <button
                    onClick={() => handleSetPrimaryBank(acc.id)}
                    className="flex-1 bg-surface-container-high hover:bg-surface-container-highest text-on-surface text-xs py-2 rounded-lg font-medium border border-outline-variant/40"
                  >
                    Set as Primary
                  </button>
                )}
                <button
                  onClick={() => handleDeleteBank(acc.id)}
                  className="px-3 bg-red-500/10 hover:bg-red-500/20 text-red-400 text-xs py-2 rounded-lg font-medium border border-red-500/20"
                >
                  Remove
                </button>
              </div>
            </div>
          ))}

          {bankAccounts.length < 2 && (
            <button
              onClick={() => setShowAddBankModal(true)}
              className="border-2 border-dashed border-outline-variant/50 hover:border-primary/50 bg-surface-container/30 hover:bg-surface-container p-6 rounded-2xl flex flex-col items-center justify-center gap-2 text-on-surface-variant hover:text-primary transition-all min-h-[180px]"
            >
              <span className="material-symbols-outlined text-3xl">add_circle</span>
              <span className="font-semibold text-sm">Add New Bank Account</span>
              <span className="text-xs opacity-70">Saved accounts: {bankAccounts.length}/2</span>
            </button>
          )}
        </div>
      )}

      {/* WITHDRAWAL REQUEST MODAL */}
      {showWithdrawModal && (
        <div className="fixed inset-0 z-50 bg-black/70 backdrop-blur-sm flex items-center justify-center p-4">
          <div 
            className="bg-surface-container border border-outline-variant/30 rounded-2xl p-6 shadow-2xl max-h-[90vh] overflow-y-auto"
            style={{ width: '100%', maxWidth: '480px', minWidth: '320px' }}
          >
            <div className="flex justify-between items-center mb-4">
              <h2 className="text-lg font-bold text-on-surface flex items-center gap-2">
                <span className="material-symbols-outlined text-primary">payments</span>
                Request Withdrawal
              </h2>
              <button onClick={() => setShowWithdrawModal(false)} className="text-on-surface-variant hover:text-on-surface">
                <span className="material-symbols-outlined">close</span>
              </button>
            </div>

            {withdrawError && (
              <div className="bg-red-500/10 border border-red-500/30 text-red-400 text-xs p-3 rounded-xl mb-4">
                {withdrawError}
              </div>
            )}

            <form onSubmit={handleWithdrawSubmit} className="space-y-4">
              <div>
                <label className="block text-xs font-semibold text-on-surface-variant mb-1">Available Balance</label>
                <div className="text-xl font-bold text-emerald-400">₹{wallet.availableBalance.toFixed(2)}</div>
              </div>

              <div>
                <label className="block text-xs font-semibold text-on-surface-variant mb-1">Withdrawal Amount (₹)</label>
                <input
                  type="number"
                  min="100"
                  max={wallet.availableBalance}
                  step="1"
                  required
                  value={withdrawAmount}
                  onChange={(e) => setWithdrawAmount(e.target.value)}
                  placeholder="Enter amount (min ₹100)"
                  className="w-full bg-surface-container-highest border border-outline-variant/50 rounded-xl p-3 text-on-surface text-sm focus:outline-none focus:border-primary font-mono"
                />
              </div>

              <div>
                <label className="block text-xs font-semibold text-on-surface-variant mb-1">Select Payout Bank Account</label>
                {bankAccounts.length === 0 ? (
                  <p className="text-xs text-amber-400">No bank accounts saved. Please add a bank account first.</p>
                ) : (
                  <select
                    value={selectedBankId}
                    onChange={(e) => setSelectedBankId(e.target.value)}
                    required
                    className="w-full bg-surface-container-highest border border-outline-variant/50 rounded-xl p-3 text-on-surface text-sm focus:outline-none focus:border-primary"
                  >
                    {bankAccounts.map((b) => (
                      <option key={b.id} value={b.id}>
                        {b.bankName} ({b.accountNumberMasked}) {b.isPrimary ? '— Primary' : ''}
                      </option>
                    ))}
                  </select>
                )}
              </div>

              <div className="bg-surface-container-high p-3 rounded-xl text-xs space-y-1 text-on-surface-variant">
                <p>• Minimum withdrawal: <strong>₹100</strong></p>
                <p>• Payout is processed manually/IMPS by platform admin</p>
                <p>• You will receive a bank UTR number once processed</p>
              </div>

              <div className="flex gap-3 pt-2">
                <button
                  type="button"
                  onClick={() => setShowWithdrawModal(false)}
                  className="flex-1 bg-surface-container-high text-on-surface text-sm py-2.5 rounded-xl font-medium"
                >
                  Cancel
                </button>
                <button
                  type="submit"
                  disabled={isSubmittingWithdraw || bankAccounts.length === 0}
                  className="flex-1 bg-primary text-on-primary text-sm py-2.5 rounded-xl font-semibold hover:bg-primary/90 disabled:opacity-50"
                >
                  {isSubmittingWithdraw ? 'Submitting...' : 'Confirm Request'}
                </button>
              </div>
            </form>
          </div>
        </div>
      )}

      {/* ADD BANK ACCOUNT MODAL */}
      {showAddBankModal && (
        <div className="fixed inset-0 z-50 bg-black/70 backdrop-blur-sm flex items-center justify-center p-4">
          <div 
            className="bg-surface-container border border-outline-variant/30 rounded-2xl p-6 shadow-2xl max-h-[90vh] overflow-y-auto"
            style={{ width: '100%', maxWidth: '580px', minWidth: '340px' }}
          >
            <div className="flex justify-between items-center mb-4">
              <h2 className="text-lg font-bold text-on-surface flex items-center gap-2">
                <span className="material-symbols-outlined text-primary">account_balance</span>
                Add Bank Account
              </h2>
              <button onClick={() => setShowAddBankModal(false)} className="text-on-surface-variant hover:text-on-surface">
                <span className="material-symbols-outlined">close</span>
              </button>
            </div>

            {bankError && (
              <div className="bg-red-500/10 border border-red-500/30 text-red-400 text-xs p-3 rounded-xl mb-4">
                {bankError}
              </div>
            )}

            <form onSubmit={handleAddBankSubmit} className="space-y-4">
              <div>
                <label className="block text-xs font-semibold text-on-surface-variant mb-1">Account Holder Name *</label>
                <input
                  type="text"
                  required
                  value={bankFormData.accountHolderName}
                  onChange={(e) => setBankFormData({ ...bankFormData, accountHolderName: e.target.value })}
                  placeholder="Full name as on bank account"
                  className="w-full bg-surface-container-highest border border-outline-variant/50 rounded-xl p-3 text-on-surface text-sm focus:outline-none focus:border-primary"
                />
              </div>

              <div className="grid grid-cols-1 sm:grid-cols-2 gap-4">
                <div>
                  <label className="block text-xs font-semibold text-on-surface-variant mb-1">Account Number *</label>
                  <input
                    type="password"
                    required
                    value={bankFormData.accountNumber}
                    onChange={(e) => setBankFormData({ ...bankFormData, accountNumber: e.target.value })}
                    placeholder="Enter account number"
                    className="w-full bg-surface-container-highest border border-outline-variant/50 rounded-xl p-3 text-on-surface text-sm focus:outline-none focus:border-primary font-mono"
                  />
                </div>
                <div>
                  <label className="block text-xs font-semibold text-on-surface-variant mb-1">Confirm Account Number *</label>
                  <input
                    type="text"
                    required
                    value={bankFormData.confirmAccountNumber}
                    onChange={(e) => setBankFormData({ ...bankFormData, confirmAccountNumber: e.target.value })}
                    placeholder="Re-enter account number"
                    className="w-full bg-surface-container-highest border border-outline-variant/50 rounded-xl p-3 text-on-surface text-sm focus:outline-none focus:border-primary font-mono"
                  />
                </div>
              </div>

              <div className="grid grid-cols-1 sm:grid-cols-2 gap-4">
                <div>
                  <label className="block text-xs font-semibold text-on-surface-variant mb-1">IFSC Code *</label>
                  <input
                    type="text"
                    required
                    maxLength="11"
                    value={bankFormData.ifscCode}
                    onChange={(e) => setBankFormData({ ...bankFormData, ifscCode: e.target.value.toUpperCase() })}
                    placeholder="e.g. SBIN0001234"
                    className="w-full bg-surface-container-highest border border-outline-variant/50 rounded-xl p-3 text-on-surface text-sm focus:outline-none focus:border-primary font-mono uppercase"
                  />
                </div>
                <div>
                  <label className="block text-xs font-semibold text-on-surface-variant mb-1">Bank Name</label>
                  <input
                    type="text"
                    value={bankFormData.bankName}
                    onChange={(e) => setBankFormData({ ...bankFormData, bankName: e.target.value })}
                    placeholder="e.g. State Bank of India"
                    className="w-full bg-surface-container-highest border border-outline-variant/50 rounded-xl p-3 text-on-surface text-sm focus:outline-none focus:border-primary"
                  />
                </div>
              </div>

              <div className="grid grid-cols-1 sm:grid-cols-2 gap-4">
                <div>
                  <label className="block text-xs font-semibold text-on-surface-variant mb-1">Account Type</label>
                  <select
                    value={bankFormData.accountType}
                    onChange={(e) => setBankFormData({ ...bankFormData, accountType: e.target.value })}
                    className="w-full bg-surface-container-highest border border-outline-variant/50 rounded-xl p-3 text-on-surface text-sm focus:outline-none focus:border-primary"
                  >
                    <option value="savings">Savings</option>
                    <option value="current">Current</option>
                  </select>
                </div>
                <div>
                  <label className="block text-xs font-semibold text-on-surface-variant mb-1">UPI ID (Optional)</label>
                  <input
                    type="text"
                    value={bankFormData.upiId}
                    onChange={(e) => setBankFormData({ ...bankFormData, upiId: e.target.value })}
                    placeholder="name@upi"
                    className="w-full bg-surface-container-highest border border-outline-variant/50 rounded-xl p-3 text-on-surface text-sm focus:outline-none focus:border-primary font-mono"
                  />
                </div>
              </div>

              <div className="flex items-center gap-2 pt-2">
                <input
                  type="checkbox"
                  id="isPrimaryCheck"
                  checked={bankFormData.isPrimary}
                  onChange={(e) => setBankFormData({ ...bankFormData, isPrimary: e.target.checked })}
                  className="rounded border-outline-variant text-primary focus:ring-primary h-4 w-4"
                />
                <label htmlFor="isPrimaryCheck" className="text-xs text-on-surface font-medium cursor-pointer">
                  Set as Primary payout bank account
                </label>
              </div>

              <div className="flex gap-3 pt-4 border-t border-outline-variant/20">
                <button
                  type="button"
                  onClick={() => setShowAddBankModal(false)}
                  className="flex-1 bg-surface-container-high text-on-surface text-sm py-2.5 rounded-xl font-medium"
                >
                  Cancel
                </button>
                <button
                  type="submit"
                  disabled={isSubmittingBank}
                  className="flex-1 bg-primary text-on-primary text-sm py-2.5 rounded-xl font-semibold hover:bg-primary/90 disabled:opacity-50"
                >
                  {isSubmittingBank ? 'Saving...' : 'Save Bank Account'}
                </button>
              </div>
            </form>
          </div>
        </div>
      )}
    </div>
  );
};

export default Wallet;
