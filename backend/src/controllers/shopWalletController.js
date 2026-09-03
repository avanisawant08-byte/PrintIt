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

// Helper: Ensure wallet row exists for a shop
async function ensureWalletExists(client, shopId) {
  await ensureWalletTables(client);
  const check = await client.query(
    'SELECT * FROM shop_wallets WHERE shop_id = $1',
    [shopId]
  );
  if (check.rows.length === 0) {
    const inserted = await client.query(
      `INSERT INTO shop_wallets (shop_id, available_balance, pending_balance, total_earned, total_withdrawn)
       VALUES ($1, 0.00, 0.00, 0.00, 0.00)
       RETURNING *`,
      [shopId]
    );
    return inserted.rows[0];
  }
  return check.rows[0];
}

// GET /api/shop/wallet
exports.getWalletDetails = async (req, res) => {
  const shopId = req.shop_id;
  try {
    const wallet = await ensureWalletExists(pool, shopId);
    res.json({
      availableBalance: parseFloat(wallet.available_balance),
      pendingBalance: parseFloat(wallet.pending_balance),
      totalEarned: parseFloat(wallet.total_earned),
      totalWithdrawn: parseFloat(wallet.total_withdrawn),
      updatedAt: wallet.updated_at
    });
  } catch (err) {
    console.error('Error fetching shop wallet:', err);
    res.status(500).json({ error: 'Failed to fetch wallet details' });
  }
};

// GET /api/shop/wallet/transactions
exports.getTransactions = async (req, res) => {
  const shopId = req.shop_id;
  const page = parseInt(req.query.page) || 1;
  const limit = parseInt(req.query.limit) || 20;
  const offset = (page - 1) * limit;
  const typeFilter = req.query.type;

  try {
    await ensureWalletTables(pool);
    let queryText = 'SELECT * FROM shop_wallet_transactions WHERE shop_id = $1';
    let params = [shopId];

    if (typeFilter && ['credit', 'debit', 'withdrawal', 'refund'].includes(typeFilter)) {
      params.push(typeFilter);
      queryText += ` AND type = $${params.length}`;
    }

    queryText += ' ORDER BY created_at DESC LIMIT $' + (params.length + 1) + ' OFFSET $' + (params.length + 2);
    params.push(limit, offset);

    const txResult = await pool.query(queryText, params);

    let countQuery = 'SELECT COUNT(*) FROM shop_wallet_transactions WHERE shop_id = $1';
    let countParams = [shopId];
    if (typeFilter && ['credit', 'debit', 'withdrawal', 'refund'].includes(typeFilter)) {
      countParams.push(typeFilter);
      countQuery += ' AND type = $2';
    }
    const countResult = await pool.query(countQuery, countParams);

    res.json({
      transactions: txResult.rows.map(tx => ({
        id: tx.id,
        type: tx.type,
        orderId: tx.order_id,
        grossAmount: parseFloat(tx.gross_amount),
        platformFee: parseFloat(tx.platform_fee),
        gstOnFee: parseFloat(tx.gst_on_fee),
        netAmount: parseFloat(tx.net_amount),
        balanceAfter: parseFloat(tx.balance_after),
        status: tx.status,
        description: tx.description,
        createdAt: tx.created_at
      })),
      total: parseInt(countResult.rows[0].count),
      page,
      limit
    });
  } catch (err) {
    console.error('Error fetching transactions:', err);
    res.status(500).json({ error: 'Failed to fetch transaction ledger' });
  }
};

// GET /api/shop/bank-accounts
exports.getBankAccounts = async (req, res) => {
  const shopId = req.shop_id;
  try {
    await ensureWalletTables(pool);
    const result = await pool.query(
      'SELECT * FROM shop_bank_accounts WHERE shop_id = $1 ORDER BY is_primary DESC, created_at DESC',
      [shopId]
    );
    res.json(result.rows.map(acc => ({
      id: acc.id,
      accountHolderName: acc.account_holder_name,
      accountNumberMasked: acc.account_number.length > 4 ? '•••• ' + acc.account_number.slice(-4) : acc.account_number,
      accountNumber: acc.account_number,
      ifscCode: acc.ifsc_code,
      bankName: acc.bank_name,
      accountType: acc.account_type,
      upiId: acc.upi_id,
      isPrimary: acc.is_primary,
      createdAt: acc.created_at
    })));
  } catch (err) {
    console.error('Error fetching bank accounts:', err);
    res.status(500).json({ error: 'Failed to fetch bank accounts' });
  }
};

// POST /api/shop/bank-accounts
exports.addBankAccount = async (req, res) => {
  const shopId = req.shop_id;
  const { accountHolderName, accountNumber, ifscCode, bankName, accountType, upiId, isPrimary } = req.body;

  if (!accountHolderName || !accountNumber || !ifscCode) {
    return res.status(400).json({ error: 'Account holder name, account number, and IFSC code are required' });
  }

  const client = await pool.connect();
  try {
    await client.query('BEGIN');

    // Limit to max 2 accounts
    const countCheck = await client.query(
      'SELECT COUNT(*) FROM shop_bank_accounts WHERE shop_id = $1',
      [shopId]
    );
    if (parseInt(countCheck.rows[0].count) >= 2) {
      await client.query('ROLLBACK');
      return res.status(400).json({ error: 'Maximum limit of 2 saved bank accounts reached' });
    }

    const setPrimary = isPrimary || parseInt(countCheck.rows[0].count) === 0;

    if (setPrimary) {
      await client.query(
        'UPDATE shop_bank_accounts SET is_primary = false WHERE shop_id = $1',
        [shopId]
      );
    }

    const result = await client.query(
      `INSERT INTO shop_bank_accounts 
        (shop_id, account_holder_name, account_number, ifsc_code, bank_name, account_type, upi_id, is_primary)
       VALUES ($1, $2, $3, $4, $5, $6, $7, $8)
       RETURNING *`,
      [
        shopId,
        accountHolderName.trim(),
        accountNumber.trim(),
        ifscCode.trim().toUpperCase(),
        bankName ? bankName.trim() : 'Bank',
        accountType || 'savings',
        upiId ? upiId.trim() : null,
        setPrimary
      ]
    );

    await client.query('COMMIT');
    const acc = result.rows[0];
    res.status(201).json({
      id: acc.id,
      accountHolderName: acc.account_holder_name,
      accountNumberMasked: '•••• ' + acc.account_number.slice(-4),
      accountNumber: acc.account_number,
      ifscCode: acc.ifsc_code,
      bankName: acc.bank_name,
      accountType: acc.account_type,
      upiId: acc.upi_id,
      isPrimary: acc.is_primary,
      createdAt: acc.created_at
    });
  } catch (err) {
    await client.query('ROLLBACK');
    console.error('Error adding bank account:', err);
    res.status(500).json({ error: 'Failed to add bank account' });
  } finally {
    client.release();
  }
};

// PUT /api/shop/bank-accounts/:id/primary
exports.setPrimaryBankAccount = async (req, res) => {
  const shopId = req.shop_id;
  const { id } = req.params;

  const client = await pool.connect();
  try {
    await client.query('BEGIN');

    const check = await client.query(
      'SELECT id FROM shop_bank_accounts WHERE id = $1 AND shop_id = $2',
      [id, shopId]
    );
    if (check.rows.length === 0) {
      await client.query('ROLLBACK');
      return res.status(404).json({ error: 'Bank account not found' });
    }

    await client.query(
      'UPDATE shop_bank_accounts SET is_primary = false WHERE shop_id = $1',
      [shopId]
    );
    await client.query(
      'UPDATE shop_bank_accounts SET is_primary = true WHERE id = $1 AND shop_id = $2',
      [id, shopId]
    );

    await client.query('COMMIT');
    res.json({ message: 'Primary bank account updated' });
  } catch (err) {
    await client.query('ROLLBACK');
    console.error('Error updating primary bank account:', err);
    res.status(500).json({ error: 'Failed to set primary bank account' });
  } finally {
    client.release();
  }
};

// DELETE /api/shop/bank-accounts/:id
exports.deleteBankAccount = async (req, res) => {
  const shopId = req.shop_id;
  const { id } = req.params;

  const client = await pool.connect();
  try {
    await client.query('BEGIN');

    // Check active withdrawal
    const pendingCheck = await client.query(
      `SELECT id FROM withdrawal_requests 
       WHERE bank_account_id = $1 AND status IN ('pending', 'processing')`,
      [id]
    );
    if (pendingCheck.rows.length > 0) {
      await client.query('ROLLBACK');
      return res.status(400).json({ error: 'Cannot delete bank account with a pending withdrawal request' });
    }

    const delResult = await client.query(
      'DELETE FROM shop_bank_accounts WHERE id = $1 AND shop_id = $2 RETURNING is_primary',
      [id, shopId]
    );

    if (delResult.rows.length === 0) {
      await client.query('ROLLBACK');
      return res.status(404).json({ error: 'Bank account not found' });
    }

    // If deleted account was primary, set another remaining account as primary
    if (delResult.rows[0].is_primary) {
      await client.query(
        `UPDATE shop_bank_accounts 
         SET is_primary = true 
         WHERE id = (SELECT id FROM shop_bank_accounts WHERE shop_id = $1 ORDER BY created_at DESC LIMIT 1)`,
        [shopId]
      );
    }

    await client.query('COMMIT');
    res.json({ message: 'Bank account removed' });
  } catch (err) {
    await client.query('ROLLBACK');
    console.error('Error deleting bank account:', err);
    res.status(500).json({ error: 'Failed to delete bank account' });
  } finally {
    client.release();
  }
};

// POST /api/shop/wallet/withdraw
exports.requestWithdrawal = async (req, res) => {
  const shopId = req.shop_id;
  const { amount, bankAccountId } = req.body;

  const numericAmount = parseFloat(amount);
  if (!numericAmount || numericAmount < 100) {
    return res.status(400).json({ error: 'Minimum withdrawal amount is ₹100' });
  }

  if (!bankAccountId) {
    return res.status(400).json({ error: 'Selected bank account is required' });
  }

  const client = await pool.connect();
  try {
    await client.query('BEGIN');

    // 1. Verify bank account belongs to shop
    const bankCheck = await client.query(
      'SELECT * FROM shop_bank_accounts WHERE id = $1 AND shop_id = $2',
      [bankAccountId, shopId]
    );
    if (bankCheck.rows.length === 0) {
      await client.query('ROLLBACK');
      return res.status(400).json({ error: 'Invalid or unassociated bank account' });
    }

    // 2. Lock & verify wallet balance
    const walletRes = await client.query(
      'SELECT available_balance FROM shop_wallets WHERE shop_id = $1 FOR UPDATE',
      [shopId]
    );

    if (walletRes.rows.length === 0) {
      await client.query('ROLLBACK');
      return res.status(400).json({ error: 'Wallet not initialized' });
    }

    const currentBalance = parseFloat(walletRes.rows[0].available_balance);
    if (currentBalance < numericAmount) {
      await client.query('ROLLBACK');
      return res.status(400).json({ 
        error: `Insufficient wallet balance. Available: ₹${currentBalance.toFixed(2)}` 
      });
    }

    // 3. Deduct available balance
    const newBalance = currentBalance - numericAmount;
    await client.query(
      'UPDATE shop_wallets SET available_balance = $1, updated_at = NOW() WHERE shop_id = $2',
      [newBalance, shopId]
    );

    // 4. Create withdrawal request
    const reqRes = await client.query(
      `INSERT INTO withdrawal_requests (shop_id, amount, net_payout, bank_account_id, status)
       VALUES ($1, $2, $3, $4, 'pending')
       RETURNING *`,
      [shopId, numericAmount, numericAmount, bankAccountId]
    );

    const withdrawalReq = reqRes.rows[0];

    // 5. Create transaction entry
    await client.query(
      `INSERT INTO shop_wallet_transactions 
        (shop_id, type, gross_amount, platform_fee, gst_on_fee, net_amount, balance_after, status, description)
       VALUES ($1, 'withdrawal', $2, 0.00, 0.00, $3, $4, 'pending', $5)`,
      [
        shopId,
        numericAmount,
        -numericAmount,
        newBalance,
        `Withdrawal request #${withdrawalReq.id.slice(0, 8)}`
      ]
    );

    await client.query('COMMIT');

    res.status(201).json({
      message: 'Withdrawal request submitted successfully',
      withdrawal: {
        id: withdrawalReq.id,
        amount: parseFloat(withdrawalReq.amount),
        status: withdrawalReq.status,
        requestedAt: withdrawalReq.requested_at
      },
      newAvailableBalance: newBalance
    });
  } catch (err) {
    await client.query('ROLLBACK');
    console.error('Error requesting withdrawal:', err);
    res.status(500).json({ error: 'Failed to submit withdrawal request' });
  } finally {
    client.release();
  }
};

// GET /api/shop/wallet/withdrawals
exports.getWithdrawals = async (req, res) => {
  const shopId = req.shop_id;
  try {
    await ensureWalletTables(pool);
    const result = await pool.query(
      `SELECT w.*, b.account_holder_name, b.account_number, b.bank_name, b.ifsc_code
       FROM withdrawal_requests w
       LEFT JOIN shop_bank_accounts b ON w.bank_account_id = b.id
       WHERE w.shop_id = $1
       ORDER BY w.requested_at DESC`,
      [shopId]
    );

    res.json(result.rows.map(w => ({
      id: w.id,
      amount: parseFloat(w.amount),
      netPayout: parseFloat(w.net_payout),
      status: w.status,
      utrNumber: w.utr_number,
      rejectionReason: w.rejection_reason,
      requestedAt: w.requested_at,
      processedAt: w.processed_at,
      bankAccount: w.account_number ? {
        bankName: w.bank_name,
        accountHolderName: w.account_holder_name,
        accountNumberMasked: '•••• ' + w.account_number.slice(-4),
        ifscCode: w.ifsc_code
      } : null
    })));
  } catch (err) {
    console.error('Error fetching shop withdrawals:', err);
    res.status(500).json({ error: 'Failed to fetch withdrawal requests' });
  }
};
