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
  const [showFilterDropdown, setShowFilterDropdown] = useState(false);

  const fetchData = async () => {
    setIsLoading(true);
    try {
      const [walletRes, bankRes, txRes, withRes] = await Promise.all([
        api.get('/shop/wallet').catch(() => ({ data: { availableBalance: 0, pendingBalance: 0, totalEarned: 0, totalWithdrawn: 0 } })),
        api.get('/shop/bank-accounts').catch(() => ({ data: [] })),
        api.get(`/shop/wallet/transactions${typeFilter !== 'all' ? `?type=${typeFilter}` : ''}`).catch(() => ({ data: { transactions: [] } })),
        api.get('/shop/wallet/withdrawals').catch(() => ({ data: [] }))
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
    <div className="w-full flex flex-col space-y-8">
      {/* Summary Cards Grid */}
      <section className="grid grid-cols-1 md:grid-cols-2 lg:grid-cols-4 gap-6">
        {/* Card 1: Available Balance */}
        <div className="glass-panel p-6 rounded-xl flex flex-col gap-2 relative overflow-hidden group hover:glow-active transition-all duration-500">
          <div className="absolute -right-4 -top-4 w-24 h-24 bg-primary/5 rounded-full blur-xl group-hover:bg-primary/10 transition-colors"></div>
          <span className="text-label-md font-label-md text-on-surface-variant">Available Balance</span>
          <div className="text-headline-lg font-headline-lg font-bold text-primary mt-1">
            ₹{wallet.availableBalance.toFixed(2)}
          </div>
          <div className="mt-4">
            <button
              onClick={() => setShowWithdrawModal(true)}
              disabled={wallet.availableBalance < 100}
              className="w-full bg-primary hover:bg-primary-container text-on-primary font-label-md text-label-md py-2.5 px-4 rounded-lg transition-all duration-200 flex items-center justify-center gap-2 shadow-[0_0_15px_rgba(96,165,250,0.3)] cursor-pointer font-bold active:scale-[0.98] disabled:opacity-50"
            >
              <span className="material-symbols-outlined text-sm">payments</span>
              Request Withdrawal
            </button>
          </div>
        </div>

        {/* Card 2: Pending Balance */}
        <div className="glass-panel p-6 rounded-xl flex flex-col gap-2">
          <span className="text-label-md font-label-md text-on-surface-variant">Pending Balance</span>
          <div className="text-headline-lg font-headline-lg font-bold text-on-surface mt-1">
            ₹{wallet.pendingBalance.toFixed(2)}
          </div>
          <p className="text-label-sm font-label-sm text-on-surface-variant/70 mt-auto pt-4">
            Clearing in 2-3 business days
          </p>
        </div>

        {/* Card 3: Lifetime Earned */}
        <div className="glass-panel p-6 rounded-xl flex flex-col gap-2">
          <span className="text-label-md font-label-md text-on-surface-variant">Lifetime Earned</span>
          <div className="text-headline-lg font-headline-lg font-bold text-on-surface mt-1">
            ₹{wallet.totalEarned.toFixed(2)}
          </div>
          <p className="text-label-sm font-label-sm text-on-surface-variant/70 mt-auto pt-4">
            Since Jan 2023
          </p>
        </div>

        {/* Card 4: Total Withdrawn */}
        <div className="glass-panel p-6 rounded-xl flex flex-col gap-2">
          <span className="text-label-md font-label-md text-on-surface-variant">Total Withdrawn</span>
          <div className="text-headline-lg font-headline-lg font-bold text-on-surface mt-1">
            ₹{wallet.totalWithdrawn.toFixed(2)}
          </div>
          <p className="text-label-sm font-label-sm text-on-surface-variant/70 mt-auto pt-4">
            To linked accounts
          </p>
        </div>
      </section>

      {/* Main Content Area with Tabs */}
      <section className="glass-panel rounded-xl overflow-hidden flex flex-col min-h-[500px]">
        {/* Tab Navigation */}
        <div className="border-b border-glass-edge/30 px-2 flex overflow-x-auto hide-scrollbar">
          <button
            onClick={() => setActiveTab('ledger')}
            className={`px-6 py-4 font-label-md text-label-md whitespace-nowrap transition-colors flex items-center gap-2 cursor-pointer ${
              activeTab === 'ledger'
                ? 'text-primary border-b-2 border-primary font-bold bg-primary/5'
                : 'text-on-surface-variant hover:text-on-surface border-b-2 border-transparent hover:bg-glass-edge/10'
            }`}
          >
            <span className="material-symbols-outlined text-sm">receipt_long</span>
            Transaction Ledger
          </button>

          <button
            onClick={() => setActiveTab('withdrawals')}
            className={`px-6 py-4 font-label-md text-label-md whitespace-nowrap transition-colors flex items-center gap-2 cursor-pointer ${
              activeTab === 'withdrawals'
                ? 'text-primary border-b-2 border-primary font-bold bg-primary/5'
                : 'text-on-surface-variant hover:text-on-surface border-b-2 border-transparent hover:bg-glass-edge/10'
            }`}
          >
            <span className="material-symbols-outlined text-sm">schedule</span>
            Withdrawal Requests ({withdrawals.length})
          </button>

          <button
            onClick={() => setActiveTab('banks')}
            className={`px-6 py-4 font-label-md text-label-md whitespace-nowrap transition-colors flex items-center gap-2 cursor-pointer ${
              activeTab === 'banks'
                ? 'text-primary border-b-2 border-primary font-bold bg-primary/5'
                : 'text-on-surface-variant hover:text-on-surface border-b-2 border-transparent hover:bg-glass-edge/10'
            }`}
          >
            <span className="material-symbols-outlined text-sm">account_balance</span>
            Saved Bank Accounts ({bankAccounts.length}/2)
          </button>
        </div>

        {/* Tab 1: Transaction Ledger */}
        {activeTab === 'ledger' && (
          <div className="p-6 flex-1 flex flex-col">
            {/* Header & Controls */}
            <div className="flex flex-col sm:flex-row justify-between items-start sm:items-center gap-4 mb-6">
              <h3 className="text-body-lg font-body-lg font-semibold text-on-surface">Recent Wallet Transactions</h3>
              <div className="flex items-center gap-3 w-full sm:w-auto">
                <div className="relative">
                  <button
                    onClick={() => setShowFilterDropdown(!showFilterDropdown)}
                    className="glass-panel hover:bg-glass-edge/20 text-on-surface-variant text-label-md font-label-md py-2 px-4 rounded-lg flex items-center gap-2 transition-colors border border-glass-edge cursor-pointer"
                  >
                    <span className="material-symbols-outlined text-sm">filter_list</span>
                    Filter: {typeFilter === 'all' ? 'All' : typeFilter.toUpperCase()}
                    <span className="material-symbols-outlined text-sm ml-2">expand_more</span>
                  </button>

                  {showFilterDropdown && (
                    <div className="absolute right-0 mt-2 w-44 glass-panel-heavy rounded-xl p-2 z-30 shadow-2xl">
                      {['all', 'credit', 'withdrawal', 'debit', 'refund'].map((t) => (
                        <button
                          key={t}
                          onClick={() => { setTypeFilter(t); setShowFilterDropdown(false); }}
                          className={`w-full text-left px-3 py-1.5 text-xs font-label-md rounded hover:bg-glass-edge/20 ${typeFilter === t ? 'text-primary font-bold' : 'text-on-surface-variant'}`}
                        >
                          {t === 'all' ? 'All Types' : t.toUpperCase()}
                        </button>
                      ))}
                    </div>
                  )}
                </div>

                <button
                  onClick={() => setActiveTab('banks')}
                  className="glass-panel text-primary border-primary/30 hover:bg-primary/10 text-label-md font-label-md py-2 px-4 rounded-lg flex items-center gap-2 transition-colors cursor-pointer"
                >
                  <span className="material-symbols-outlined text-sm">add_circle</span>
                  Manage Bank Accounts
                </button>
              </div>
            </div>

            {/* Content Table / Empty State */}
            {isLoading ? (
              <div className="flex-1 flex items-center justify-center py-16 text-on-surface-variant">
                <div className="flex items-center gap-2">
                  <span className="material-symbols-outlined text-primary text-2xl animate-spin">autorenew</span>
                  <span className="font-label-md text-xs">Loading ledger entries...</span>
                </div>
              </div>
            ) : transactions.length === 0 ? (
              <div className="flex-1 flex flex-col items-center justify-center py-16 text-center bg-surface-container/20 rounded-lg border border-dashed border-glass-edge/30">
                <div className="w-16 h-16 rounded-full bg-surface-container flex items-center justify-center mb-4 border border-glass-edge">
                  <span className="material-symbols-outlined text-3xl text-outline">history_toggle_off</span>
                </div>
                <h4 className="text-body-lg font-body-lg text-on-surface mb-2 font-semibold">No transaction entries found.</h4>
                <p className="text-body-md font-body-md text-on-surface-variant/70 max-w-md text-sm">
                  Your transaction history will appear here once you process orders or initiate withdrawals.
                </p>
              </div>
            ) : (
              <div className="bg-surface-container/40 border border-glass-edge/30 rounded-xl overflow-x-auto">
                <table className="w-full text-left border-collapse font-label-md text-xs">
                  <thead>
                    <tr className="bg-black/30 border-b border-glass-edge/20 uppercase tracking-wider text-on-surface-variant font-bold">
                      <th className="p-4">Date & Time</th>
                      <th className="p-4">Description</th>
                      <th className="p-4">Type</th>
                      <th className="p-4 text-right">Gross</th>
                      <th className="p-4 text-right">Fee</th>
                      <th className="p-4 text-right">Net Amount</th>
                      <th className="p-4 text-right">Balance</th>
                      <th className="p-4 text-center">Status</th>
                    </tr>
                  </thead>
                  <tbody className="divide-y divide-glass-edge/10">
                    {transactions.map((tx) => (
                      <tr key={tx.id} className="hover:bg-glass-edge/10 transition-colors">
                        <td className="p-4 font-mono text-on-surface-variant">
                          {new Date(tx.createdAt).toLocaleString()}
                        </td>
                        <td className="p-4 font-semibold text-on-surface">
                          {tx.description || (tx.type === 'withdrawal' ? 'Withdrawal Request' : 'Order Credit')}
                        </td>
                        <td className="p-4 uppercase font-bold">
                          <span
                            className={`px-2 py-1 rounded text-[10px] ${
                              tx.type === 'credit'
                                ? 'bg-emerald-500/20 text-emerald-400 border border-emerald-500/30'
                                : tx.type === 'withdrawal'
                                ? 'bg-amber-500/20 text-amber-400 border border-amber-500/30'
                                : 'bg-red-500/20 text-red-400 border border-red-500/30'
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
                          <span className="text-[10px] px-2 py-0.5 rounded-full bg-surface-container border border-glass-edge text-on-surface-variant uppercase">
                            {tx.status}
                          </span>
                        </td>
                      </tr>
                    ))}
                  </tbody>
                </table>
              </div>
            )}
          </div>
        )}

        {/* Tab 2: Withdrawal Requests */}
        {activeTab === 'withdrawals' && (
          <div className="p-6 flex-1 flex flex-col">
            <h3 className="text-body-lg font-body-lg font-semibold text-on-surface mb-6">Withdrawal Requests History</h3>
            {withdrawals.length === 0 ? (
              <div className="flex-1 flex flex-col items-center justify-center py-16 text-center bg-surface-container/20 rounded-lg border border-dashed border-glass-edge/30">
                <div className="w-16 h-16 rounded-full bg-surface-container flex items-center justify-center mb-4 border border-glass-edge">
                  <span className="material-symbols-outlined text-3xl text-outline">schedule</span>
                </div>
                <h4 className="text-body-lg font-body-lg text-on-surface mb-2 font-semibold">No withdrawal requests submitted yet.</h4>
                <p className="text-body-md font-body-md text-on-surface-variant/70 max-w-md text-sm">
                  Click "Request Withdrawal" to transfer available funds to your linked bank account.
                </p>
              </div>
            ) : (
              <div className="bg-surface-container/40 border border-glass-edge/30 rounded-xl overflow-x-auto">
                <table className="w-full text-left border-collapse font-label-md text-xs">
                  <thead>
                    <tr className="bg-black/30 border-b border-glass-edge/20 uppercase tracking-wider text-on-surface-variant font-bold">
                      <th className="p-4">Requested At</th>
                      <th className="p-4">Amount</th>
                      <th className="p-4">Bank Account</th>
                      <th className="p-4">Status</th>
                      <th className="p-4">UTR Number / Details</th>
                    </tr>
                  </thead>
                  <tbody className="divide-y divide-glass-edge/10">
                    {withdrawals.map((w) => (
                      <tr key={w.id} className="hover:bg-glass-edge/10 transition-colors">
                        <td className="p-4 font-mono text-on-surface-variant">
                          {new Date(w.requestedAt).toLocaleString()}
                        </td>
                        <td className="p-4 font-bold text-primary">₹{w.amount.toFixed(2)}</td>
                        <td className="p-4">
                          {w.bankAccount ? (
                            <div>
                              <p className="font-semibold text-on-surface">{w.bankAccount.bankName}</p>
                              <p className="text-[10px] font-mono text-on-surface-variant">{w.bankAccount.accountNumberMasked}</p>
                            </div>
                          ) : (
                            <span className="text-on-surface-variant opacity-50">—</span>
                          )}
                        </td>
                        <td className="p-4">
                          <span
                            className={`px-2.5 py-1 rounded-full text-[10px] font-bold uppercase tracking-wider ${
                              w.status === 'processed'
                                ? 'bg-emerald-500/20 text-emerald-400 border border-emerald-500/30'
                                : w.status === 'pending'
                                ? 'bg-amber-500/20 text-amber-400 border border-amber-500/30'
                                : 'bg-red-500/20 text-red-400 border border-red-500/30'
                            }`}
                          >
                            {w.status}
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
              </div>
            )}
          </div>
        )}

        {/* Tab 3: Saved Bank Accounts */}
        {activeTab === 'banks' && (
          <div className="p-6 flex-1 flex flex-col gap-6">
            <div className="flex justify-between items-center">
              <h3 className="text-body-lg font-body-lg font-semibold text-on-surface">Saved Bank Accounts ({bankAccounts.length}/2)</h3>
              {bankAccounts.length < 2 && (
                <button
                  onClick={() => setShowAddBankModal(true)}
                  className="glass-panel text-primary border-primary/30 hover:bg-primary/10 text-label-md font-label-md py-2 px-4 rounded-lg flex items-center gap-2 transition-colors cursor-pointer"
                >
                  <span className="material-symbols-outlined text-sm">add</span>
                  Add Bank Account
                </button>
              )}
            </div>

            <div className="grid grid-cols-1 md:grid-cols-2 gap-6">
              {bankAccounts.map((acc) => (
                <div
                  key={acc.id}
                  className={`glass-panel p-6 rounded-xl relative flex flex-col justify-between transition-all ${
                    acc.isPrimary ? 'border-primary shadow-[0_0_20px_rgba(96,165,250,0.15)]' : 'border-glass-edge'
                  }`}
                >
                  <div>
                    <div className="flex justify-between items-start mb-4">
                      <div className="flex items-center gap-3">
                        <div className="w-10 h-10 rounded-lg bg-surface-container flex items-center justify-center border border-glass-edge">
                          <span className="material-symbols-outlined text-primary">account_balance</span>
                        </div>
                        <div>
                          <h4 className="font-bold text-on-surface text-base">{acc.bankName}</h4>
                          <p className="text-label-sm font-label-sm text-on-surface-variant uppercase">{acc.accountType} Account</p>
                        </div>
                      </div>
                      {acc.isPrimary && (
                        <span className="bg-primary/20 text-primary border border-primary/30 px-3 py-1 rounded-full text-[10px] font-bold uppercase tracking-wider">
                          Primary Payout
                        </span>
                      )}
                    </div>

                    <div className="space-y-2 text-xs font-mono my-4 text-on-surface-variant bg-surface-container/50 p-4 rounded-lg border border-glass-edge/20">
                      <p>Account Holder: <span className="font-semibold text-on-surface">{acc.accountHolderName}</span></p>
                      <p>Account No: <span className="font-semibold text-on-surface">{acc.accountNumberMasked}</span></p>
                      <p>IFSC Code: <span className="font-semibold text-on-surface">{acc.ifscCode}</span></p>
                      {acc.upiId && <p>UPI ID: <span className="font-semibold text-on-surface">{acc.upiId}</span></p>}
                    </div>
                  </div>

                  <div className="flex gap-3 pt-3 border-t border-glass-edge/20">
                    {!acc.isPrimary && (
                      <button
                        onClick={() => handleSetPrimaryBank(acc.id)}
                        className="flex-1 glass-panel hover:bg-glass-edge/20 text-on-surface text-xs font-label-md py-2 rounded-lg transition-colors border border-glass-edge cursor-pointer"
                      >
                        Set as Primary
                      </button>
                    )}
                    <button
                      onClick={() => handleDeleteBank(acc.id)}
                      className="px-4 bg-error/10 hover:bg-error/20 text-error text-xs font-label-md py-2 rounded-lg transition-colors border border-error/20 cursor-pointer"
                    >
                      Remove
                    </button>
                  </div>
                </div>
              ))}

              {bankAccounts.length < 2 && (
                <button
                  onClick={() => setShowAddBankModal(true)}
                  className="border-2 border-dashed border-glass-edge/40 hover:border-primary/50 bg-glass-surface/20 hover:bg-glass-surface p-6 rounded-xl flex flex-col items-center justify-center gap-2 text-on-surface-variant hover:text-primary transition-all min-h-[220px] cursor-pointer"
                >
                  <span className="material-symbols-outlined text-3xl">add_circle</span>
                  <span className="font-semibold text-sm">Add New Bank Account</span>
                  <span className="text-xs text-on-surface-variant/70">Saved accounts: {bankAccounts.length}/2</span>
                </button>
              )}
            </div>
          </div>
        )}
      </section>

      {/* WITHDRAWAL REQUEST MODAL */}
      {showWithdrawModal && (
        <div className="fixed inset-0 z-50 bg-black/75 backdrop-blur-md flex items-center justify-center p-4">
          <div 
            className="glass-panel-heavy rounded-2xl p-6 shadow-[0_0_32px_rgba(96,165,250,0.15)] max-h-[90vh] overflow-y-auto w-full max-w-md border border-glass-edge animate-fade-in"
            onClick={(e) => e.stopPropagation()}
          >
            <div className="flex justify-between items-center mb-6">
              <h3 className="text-headline-md font-bold text-primary text-xl flex items-center gap-2">
                <span className="material-symbols-outlined text-primary">payments</span>
                Request Withdrawal
              </h3>
              <button 
                onClick={() => setShowWithdrawModal(false)} 
                className="w-8 h-8 rounded-full bg-surface-container border border-glass-edge text-on-surface-variant hover:text-on-surface flex items-center justify-center transition-colors cursor-pointer"
              >
                <span className="material-symbols-outlined text-lg">close</span>
              </button>
            </div>

            {withdrawError && (
              <div className="bg-error/10 border border-error/30 text-error text-xs p-3 rounded-lg mb-4 font-label-md">
                {withdrawError}
              </div>
            )}

            <form onSubmit={handleWithdrawSubmit} className="space-y-4 font-label-md text-xs">
              <div>
                <label className="block text-on-surface-variant mb-1 font-semibold uppercase tracking-wider">Available Balance</label>
                <div className="text-2xl font-bold text-primary font-mono">₹{wallet.availableBalance.toFixed(2)}</div>
              </div>

              <div>
                <label className="block text-on-surface-variant mb-1 font-semibold uppercase tracking-wider">Withdrawal Amount (₹)</label>
                <input
                  type="number"
                  min="100"
                  max={wallet.availableBalance}
                  step="1"
                  required
                  value={withdrawAmount}
                  onChange={(e) => setWithdrawAmount(e.target.value)}
                  placeholder="Enter amount (min ₹100)"
                  className="w-full bg-surface-container border border-glass-edge rounded-xl p-3 text-on-surface text-sm focus:outline-none focus:border-primary font-mono"
                />
              </div>

              <div>
                <label className="block text-on-surface-variant mb-1 font-semibold uppercase tracking-wider">Select Payout Bank Account</label>
                {bankAccounts.length === 0 ? (
                  <p className="text-xs text-amber-400">No bank accounts saved. Please add a bank account first.</p>
                ) : (
                  <select
                    value={selectedBankId}
                    onChange={(e) => setSelectedBankId(e.target.value)}
                    required
                    className="w-full bg-surface-container border border-glass-edge rounded-xl p-3 text-on-surface text-xs focus:outline-none focus:border-primary"
                  >
                    {bankAccounts.map((b) => (
                      <option key={b.id} value={b.id}>
                        {b.bankName} ({b.accountNumberMasked}) {b.isPrimary ? '— Primary' : ''}
                      </option>
                    ))}
                  </select>
                )}
              </div>

              <div className="bg-surface-container/60 border border-glass-edge/30 p-3 rounded-xl space-y-1 text-on-surface-variant text-[11px]">
                <p>• Minimum withdrawal: <strong>₹100</strong></p>
                <p>• Payout is processed manually/IMPS by platform admin</p>
                <p>• Bank UTR number is provided upon confirmation</p>
              </div>

              <div className="flex gap-3 pt-4 border-t border-glass-edge/20">
                <button
                  type="button"
                  onClick={() => setShowWithdrawModal(false)}
                  className="flex-1 glass-panel text-on-surface text-xs py-3 rounded-xl font-bold cursor-pointer"
                >
                  Cancel
                </button>
                <button
                  type="submit"
                  disabled={isSubmittingWithdraw || bankAccounts.length === 0}
                  className="flex-1 bg-primary hover:bg-primary-container text-on-primary text-xs py-3 rounded-xl font-bold transition-all shadow-[0_0_15px_rgba(96,165,250,0.3)] disabled:opacity-50 cursor-pointer active:scale-[0.98]"
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
        <div className="fixed inset-0 z-50 bg-black/75 backdrop-blur-md flex items-center justify-center p-4">
          <div 
            className="glass-panel-heavy rounded-2xl p-6 shadow-[0_0_32px_rgba(96,165,250,0.15)] max-h-[90vh] overflow-y-auto w-full max-w-lg border border-glass-edge animate-fade-in"
            onClick={(e) => e.stopPropagation()}
          >
            <div className="flex justify-between items-center mb-6">
              <h3 className="text-headline-md font-bold text-primary text-xl flex items-center gap-2">
                <span className="material-symbols-outlined text-primary">account_balance</span>
                Add Bank Account
              </h3>
              <button 
                onClick={() => setShowAddBankModal(false)} 
                className="w-8 h-8 rounded-full bg-surface-container border border-glass-edge text-on-surface-variant hover:text-on-surface flex items-center justify-center transition-colors cursor-pointer"
              >
                <span className="material-symbols-outlined text-lg">close</span>
              </button>
            </div>

            {bankError && (
              <div className="bg-error/10 border border-error/30 text-error text-xs p-3 rounded-lg mb-4 font-label-md">
                {bankError}
              </div>
            )}

            <form onSubmit={handleAddBankSubmit} className="space-y-4 font-label-md text-xs">
              <div>
                <label className="block text-on-surface-variant mb-1 font-semibold uppercase tracking-wider">Account Holder Name *</label>
                <input
                  type="text"
                  required
                  value={bankFormData.accountHolderName}
                  onChange={(e) => setBankFormData({ ...bankFormData, accountHolderName: e.target.value })}
                  placeholder="Full name as on bank account"
                  className="w-full bg-surface-container border border-glass-edge rounded-xl p-3 text-on-surface text-sm focus:outline-none focus:border-primary"
                />
              </div>

              <div className="grid grid-cols-1 sm:grid-cols-2 gap-4">
                <div>
                  <label className="block text-on-surface-variant mb-1 font-semibold uppercase tracking-wider">Account Number *</label>
                  <input
                    type="password"
                    required
                    value={bankFormData.accountNumber}
                    onChange={(e) => setBankFormData({ ...bankFormData, accountNumber: e.target.value })}
                    placeholder="Enter account number"
                    className="w-full bg-surface-container border border-glass-edge rounded-xl p-3 text-on-surface text-sm focus:outline-none focus:border-primary font-mono"
                  />
                </div>
                <div>
                  <label className="block text-on-surface-variant mb-1 font-semibold uppercase tracking-wider">Confirm Account *</label>
                  <input
                    type="text"
                    required
                    value={bankFormData.confirmAccountNumber}
                    onChange={(e) => setBankFormData({ ...bankFormData, confirmAccountNumber: e.target.value })}
                    placeholder="Re-enter account number"
                    className="w-full bg-surface-container border border-glass-edge rounded-xl p-3 text-on-surface text-sm focus:outline-none focus:border-primary font-mono"
                  />
                </div>
              </div>

              <div className="grid grid-cols-1 sm:grid-cols-2 gap-4">
                <div>
                  <label className="block text-on-surface-variant mb-1 font-semibold uppercase tracking-wider">IFSC Code *</label>
                  <input
                    type="text"
                    required
                    maxLength="11"
                    value={bankFormData.ifscCode}
                    onChange={(e) => setBankFormData({ ...bankFormData, ifscCode: e.target.value.toUpperCase() })}
                    placeholder="e.g. SBIN0001234"
                    className="w-full bg-surface-container border border-glass-edge rounded-xl p-3 text-on-surface text-sm focus:outline-none focus:border-primary font-mono uppercase"
                  />
                </div>
                <div>
                  <label className="block text-on-surface-variant mb-1 font-semibold uppercase tracking-wider">Bank Name</label>
                  <input
                    type="text"
                    value={bankFormData.bankName}
                    onChange={(e) => setBankFormData({ ...bankFormData, bankName: e.target.value })}
                    placeholder="e.g. State Bank of India"
                    className="w-full bg-surface-container border border-glass-edge rounded-xl p-3 text-on-surface text-sm focus:outline-none focus:border-primary"
                  />
                </div>
              </div>

              <div className="grid grid-cols-1 sm:grid-cols-2 gap-4">
                <div>
                  <label className="block text-on-surface-variant mb-1 font-semibold uppercase tracking-wider">Account Type</label>
                  <select
                    value={bankFormData.accountType}
                    onChange={(e) => setBankFormData({ ...bankFormData, accountType: e.target.value })}
                    className="w-full bg-surface-container border border-glass-edge rounded-xl p-3 text-on-surface text-xs focus:outline-none focus:border-primary"
                  >
                    <option value="savings">Savings</option>
                    <option value="current">Current</option>
                  </select>
                </div>
                <div>
                  <label className="block text-on-surface-variant mb-1 font-semibold uppercase tracking-wider">UPI ID (Optional)</label>
                  <input
                    type="text"
                    value={bankFormData.upiId}
                    onChange={(e) => setBankFormData({ ...bankFormData, upiId: e.target.value })}
                    placeholder="name@upi"
                    className="w-full bg-surface-container border border-glass-edge rounded-xl p-3 text-on-surface text-sm focus:outline-none focus:border-primary font-mono"
                  />
                </div>
              </div>

              <div className="flex items-center gap-2 pt-2">
                <input
                  type="checkbox"
                  id="isPrimaryCheck"
                  checked={bankFormData.isPrimary}
                  onChange={(e) => setBankFormData({ ...bankFormData, isPrimary: e.target.checked })}
                  className="rounded border-glass-edge text-primary focus:ring-primary h-4 w-4"
                />
                <label htmlFor="isPrimaryCheck" className="text-xs text-on-surface font-medium cursor-pointer">
                  Set as Primary payout bank account
                </label>
              </div>

              <div className="flex gap-3 pt-4 border-t border-glass-edge/20">
                <button
                  type="button"
                  onClick={() => setShowAddBankModal(false)}
                  className="flex-1 glass-panel text-on-surface text-xs py-3 rounded-xl font-bold cursor-pointer"
                >
                  Cancel
                </button>
                <button
                  type="submit"
                  disabled={isSubmittingBank}
                  className="flex-1 bg-primary hover:bg-primary-container text-on-primary text-xs py-3 rounded-xl font-bold transition-all shadow-[0_0_15px_rgba(96,165,250,0.3)] disabled:opacity-50 cursor-pointer active:scale-[0.98]"
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
