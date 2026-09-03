const express = require('express');
const router = express.Router();
const auth = require('../middleware/auth');
const roleCheck = require('../middleware/roleCheck');
const adminPayoutController = require('../controllers/adminPayoutController');

// All admin payout routes require user auth + admin role check
router.use(auth);
router.use(roleCheck('admin'));

router.get('/pending', adminPayoutController.getPendingWithdrawals);
router.put('/:id/approve', adminPayoutController.approveWithdrawal);
router.put('/:id/reject', adminPayoutController.rejectWithdrawal);
router.get('/history', adminPayoutController.getPayoutHistory);
router.get('/wallets', adminPayoutController.getAllShopWallets);

module.exports = router;
