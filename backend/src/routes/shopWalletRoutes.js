const express = require('express');
const router = express.Router();
const auth = require('../middleware/auth');
const shopCheck = require('../middleware/shopCheck');
const shopWalletController = require('../controllers/shopWalletController');

// All shop wallet routes require user auth + shop ownership check
router.use(auth);
router.use(shopCheck);

// Wallet & Ledger
router.get('/wallet', shopWalletController.getWalletDetails);
router.get('/wallet/transactions', shopWalletController.getTransactions);

// Withdrawal Requests
router.post('/wallet/withdraw', shopWalletController.requestWithdrawal);
router.get('/wallet/withdrawals', shopWalletController.getWithdrawals);

// Bank Account Management
router.get('/bank-accounts', shopWalletController.getBankAccounts);
router.post('/bank-accounts', shopWalletController.addBankAccount);
router.put('/bank-accounts/:id/primary', shopWalletController.setPrimaryBankAccount);
router.delete('/bank-accounts/:id', shopWalletController.deleteBankAccount);

module.exports = router;
