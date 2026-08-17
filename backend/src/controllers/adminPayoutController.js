const pool = require('../config/db');

// Lazy DB Table Setup helper
async function ensureWalletTables(client = pool) {
  await client.query(`
    CREATE TABLE IF NOT EXISTS shop_wallets (
      shop_id UUID PRIMARY KEY REFERENCES shops(shop_id) ON DELETE CASCADE,
      available_balance NUMERIC(12, 2) NOT NULL DEFAULT 0.00,
      pending_balance NUMERIC(12, 2) NOT NULL DEFAULT 0.00,
      total_earned NUMERIC(12, 2) NOT NULL DEFAULT 0.00,
      total_withdrawn NUMERIC(12, 2) NOT NULL DEFAULT 0.00,
      updated_at TIMESTAMP WITH TIME ZONE DEFAULT NOW()
    );

    CREATE TABLE IF NOT EXISTS shop_bank_accounts (
      id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
      shop_id UUID NOT NULL REFERENCES shops(shop_id) ON DELETE CASCADE,
      account_holder_name VARCHAR(255) NOT NULL,
      account_number VARCHAR(100) NOT NULL,
      ifsc_code VARCHAR(20) NOT NULL,
      bank_name VARCHAR(255),
      account_type VARCHAR(20) DEFAULT 'savings',
      upi_id VARCHAR(100),
      is_primary BOOLEAN DEFAULT true,
      created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW()
    );

    CREATE TABLE IF NOT EXISTS withdrawal_requests (
      id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
      shop_id UUID NOT NULL REFERENCES shops(shop_id) ON DELETE CASCADE,
      amount NUMERIC(12, 2) NOT NULL,
      net_payout NUMERIC(12, 2) NOT NULL,
      bank_account_id UUID REFERENCES shop_bank_accounts(id) ON DELETE SET NULL,
      status VARCHAR(20) DEFAULT 'pending',
      utr_number VARCHAR(100),
      rejection_reason TEXT,
      processed_by UUID REFERENCES users(user_id) ON DELETE SET NULL,
      requested_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
      processed_at TIMESTAMP WITH TIME ZONE
    );

    CREATE TABLE IF NOT EXISTS shop_wallet_transactions (
      id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
      shop_id UUID NOT NULL REFERENCES shops(shop_id) ON DELETE CASCADE,
      type VARCHAR(20) NOT NULL,
      order_id UUID,
      gross_amount NUMERIC(12, 2) DEFAULT 0.00,
      platform_fee NUMERIC(12, 2) DEFAULT 0.00,
      gst_on_fee NUMERIC(12, 2) DEFAULT 0.00,
      net_amount NUMERIC(12, 2) NOT NULL,
      balance_after NUMERIC(12, 2) NOT NULL,
      status VARCHAR(20) DEFAULT 'confirmed',
      description TEXT,
      created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW()
    );
  `);
}

// GET /api/admin/payouts/pending
exports.getPendingWithdrawals = async (req, res) => {
  try {
    await ensureWalletTables(pool);
    const result = await pool.query(
      `SELECT w.*, s.name as shop_name, s.phone_number as shop_phone, 
              b.account_holder_name, b.account_number, b.ifsc_code, b.bank_name, b.account_type, b.upi_id
       FROM withdrawal_requests w
       JOIN shops s ON w.shop_id = s.shop_id
       LEFT JOIN shop_bank_accounts b ON w.bank_account_id = b.id
       WHERE w.status IN ('pending', 'processing')
       ORDER BY w.requested_at ASC`
    );

    res.json(result.rows.map(w => ({
      id: w.id,
      shopId: w.shop_id,
      shopName: w.shop_name,
      shopPhone: w.shop_phone,
      amount: parseFloat(w.amount),
      netPayout: parseFloat(w.net_payout),
      status: w.status,
      requestedAt: w.requested_at,
      bankAccount: {
        accountHolderName: w.account_holder_name,
        accountNumber: w.account_number,
        accountNumberMasked: w.account_number ? '•••• ' + w.account_number.slice(-4) : '',
        ifscCode: w.ifsc_code,
        bankName: w.bank_name,
        accountType: w.account_type,
        upiId: w.upi_id
      }
    })));
  } catch (err) {
    console.error('Error fetching pending withdrawals:', err);
    res.status(500).json({ error: 'Failed to fetch pending withdrawal queue' });
  }
};

// PUT /api/admin/payouts/:id/approve
exports.approveWithdrawal = async (req, res) => {
  const { id } = req.params;
  const { utrNumber } = req.body;

  if (!utrNumber || !utrNumber.trim()) {
    return res.status(400).json({ error: 'UTR number is required to approve payout' });
  }

  const client = await pool.connect();
  try {
    await client.query('BEGIN');

    // 1. Fetch withdrawal request
    const reqResult = await client.query(
      'SELECT * FROM withdrawal_requests WHERE id = $1 FOR UPDATE',
      [id]
    );

    if (reqResult.rows.length === 0) {
      await client.query('ROLLBACK');
      return res.status(404).json({ error: 'Withdrawal request not found' });
    }

    const withdrawal = reqResult.rows[0];

    if (withdrawal.status !== 'pending' && withdrawal.status !== 'processing') {
      await client.query('ROLLBACK');
      return res.status(400).json({ error: `Cannot approve request with status '${withdrawal.status}'` });
    }

    // 2. Update request status to processed
    await client.query(
      `UPDATE withdrawal_requests 
       SET status = 'processed', utr_number = $1, processed_by = $2, processed_at = NOW()
       WHERE id = $3`,
      [utrNumber.trim(), req.user.user_id, id]
    );

    // 3. Update shop_wallets total_withdrawn
    await client.query(
      `UPDATE shop_wallets 
       SET total_withdrawn = total_withdrawn + $1, updated_at = NOW()
       WHERE shop_id = $2`,
      [withdrawal.amount, withdrawal.shop_id]
    );

    // 4. Update transaction status in ledger if matching
    await client.query(
      `UPDATE shop_wallet_transactions
       SET status = 'confirmed', description = $1
       WHERE shop_id = $2 AND type = 'withdrawal' AND status = 'pending' AND net_amount = $3`,
      [`Withdrawal processed (UTR: ${utrNumber.trim()})`, withdrawal.shop_id, -parseFloat(withdrawal.amount)]
    );

    await client.query('COMMIT');
    res.json({ 
      message: 'Withdrawal approved and marked as processed', 
      utrNumber: utrNumber.trim() 
    });
  } catch (err) {
    await client.query('ROLLBACK');
    console.error('Error approving withdrawal:', err);
    res.status(500).json({ error: 'Failed to approve withdrawal request' });
  } finally {
    client.release();
  }
};

// PUT /api/admin/payouts/:id/reject
exports.rejectWithdrawal = async (req, res) => {
  const { id } = req.params;
  const { rejectionReason } = req.body;

  if (!rejectionReason || !rejectionReason.trim()) {
    return res.status(400).json({ error: 'Rejection reason is required' });
  }

  const client = await pool.connect();
  try {
    await client.query('BEGIN');

    // 1. Fetch withdrawal request
    const reqResult = await client.query(
      'SELECT * FROM withdrawal_requests WHERE id = $1 FOR UPDATE',
      [id]
    );

    if (reqResult.rows.length === 0) {
      await client.query('ROLLBACK');
      return res.status(404).json({ error: 'Withdrawal request not found' });
    }

    const withdrawal = reqResult.rows[0];

    if (withdrawal.status !== 'pending' && withdrawal.status !== 'processing') {
      await client.query('ROLLBACK');
      return res.status(400).json({ error: `Cannot reject request with status '${withdrawal.status}'` });
    }

    const refundAmount = parseFloat(withdrawal.amount);

    // 2. Update request status to rejected
    await client.query(
      `UPDATE withdrawal_requests 
       SET status = 'rejected', rejection_reason = $1, processed_by = $2, processed_at = NOW()
       WHERE id = $3`,
      [rejectionReason.trim(), req.user.user_id, id]
    );

    // 3. Restore shop available balance
    const walletRes = await client.query(
      `UPDATE shop_wallets 
       SET available_balance = available_balance + $1, updated_at = NOW()
       WHERE shop_id = $2
       RETURNING available_balance`,
      [refundAmount, withdrawal.shop_id]
    );

    const newBalance = parseFloat(walletRes.rows[0].available_balance);

    // 4. Add refund entry to transaction ledger
    await client.query(
      `INSERT INTO shop_wallet_transactions 
        (shop_id, type, gross_amount, platform_fee, gst_on_fee, net_amount, balance_after, status, description)
       VALUES ($1, 'refund', $2, 0.00, 0.00, $2, $3, 'confirmed', $4)`,
      [
        withdrawal.shop_id,
        refundAmount,
        newBalance,
        `Refund for rejected withdrawal request #${id.slice(0, 8)} (${rejectionReason.trim()})`
      ]
    );

    await client.query('COMMIT');
    res.json({ message: 'Withdrawal request rejected and balance restored to shopkeeper' });
  } catch (err) {
    await client.query('ROLLBACK');
    console.error('Error rejecting withdrawal:', err);
    res.status(500).json({ error: 'Failed to reject withdrawal request' });
  } finally {
    client.release();
  }
};

// GET /api/admin/payouts/history
exports.getPayoutHistory = async (req, res) => {
  try {
    await ensureWalletTables(pool);
    const result = await pool.query(
      `SELECT w.*, s.name as shop_name, s.phone_number as shop_phone, 
              b.account_holder_name, b.account_number, b.bank_name
       FROM withdrawal_requests w
       JOIN shops s ON w.shop_id = s.shop_id
       LEFT JOIN shop_bank_accounts b ON w.bank_account_id = b.id
       WHERE w.status IN ('processed', 'rejected', 'failed')
       ORDER BY w.processed_at DESC NULLS LAST, w.requested_at DESC`
    );

    res.json(result.rows.map(w => ({
      id: w.id,
      shopId: w.shop_id,
      shopName: w.shop_name,
      shopPhone: w.shop_phone,
      amount: parseFloat(w.amount),
      netPayout: parseFloat(w.net_payout),
      status: w.status,
      utrNumber: w.utr_number,
      rejectionReason: w.rejection_reason,
      requestedAt: w.requested_at,
      processedAt: w.processed_at,
      bankAccount: {
        accountHolderName: w.account_holder_name,
        accountNumberMasked: w.account_number ? '•••• ' + w.account_number.slice(-4) : '',
        bankName: w.bank_name
      }
    })));
  } catch (err) {
    console.error('Error fetching payout history:', err);
    res.status(500).json({ error: 'Failed to fetch payout history' });
  }
};

// GET /api/admin/payouts/wallets
exports.getAllShopWallets = async (req, res) => {
  try {
    await ensureWalletTables(pool);
    const result = await pool.query(
      `SELECT s.shop_id, s.name as shop_name, s.phone_number as shop_phone,
              COALESCE(w.available_balance, 0.00) as available_balance,
              COALESCE(w.pending_balance, 0.00) as pending_balance,
              COALESCE(w.total_earned, 0.00) as total_earned,
              COALESCE(w.total_withdrawn, 0.00) as total_withdrawn,
              w.updated_at
       FROM shops s
       LEFT JOIN shop_wallets w ON s.shop_id = w.shop_id
       ORDER BY w.available_balance DESC NULLS LAST, s.name ASC`
    );

    res.json(result.rows.map(row => ({
      shopId: row.shop_id,
      shopName: row.shop_name,
      shopPhone: row.shop_phone,
      availableBalance: parseFloat(row.available_balance),
      pendingBalance: parseFloat(row.pending_balance),
      totalEarned: parseFloat(row.total_earned),
      totalWithdrawn: parseFloat(row.total_withdrawn),
      updatedAt: row.updated_at
    })));
  } catch (err) {
    console.error('Error fetching shop wallets overview:', err);
    res.status(500).json({ error: 'Failed to fetch shop wallets overview' });
  }
};
