import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../core/api/api_client.dart';
import '../../shared/widgets/ambient_background.dart';
import '../../shared/widgets/glass_container.dart';
import '../orders/order_history_screen.dart';
import 'support_provider.dart';

class CreateTicketScreen extends ConsumerStatefulWidget {
  final String? initialOrderId;

  const CreateTicketScreen({super.key, this.initialOrderId});

  @override
  ConsumerState<CreateTicketScreen> createState() => _CreateTicketScreenState();
}

class _CreateTicketScreenState extends ConsumerState<CreateTicketScreen> {
  final _formKey = GlobalKey<FormState>();
  final _subjectController = TextEditingController();
  final _descController = TextEditingController();
  final _manualOrderController = TextEditingController();

  static const List<Map<String, dynamic>> issueCategories = [
    {
      'label': 'Print Quality Issue',
      'subtitle': 'Misprint, blurry text, wrong colors, smudged ink',
      'icon': Icons.broken_image_outlined,
    },
    {
      'label': 'Pickup & Order Delay',
      'subtitle': 'Shop closed, order not ready at pickup time',
      'icon': Icons.schedule_outlined,
    },
    {
      'label': 'Wrong Paper or Binding',
      'subtitle': 'Incorrect GSM, size, or binding (staple/spiral)',
      'icon': Icons.menu_book_outlined,
    },
    {
      'label': 'Missing or Blank Pages',
      'subtitle': 'Pages cut off, incomplete print, blank output',
      'icon': Icons.find_in_page_outlined,
    },
    {
      'label': 'Payment & Wallet Issue',
      'subtitle': 'Funds deducted, transaction failed, double charge',
      'icon': Icons.account_balance_wallet_outlined,
    },
    {
      'label': 'Cancellation & Refund Request',
      'subtitle': 'Cancel queued job or dispute completed charge',
      'icon': Icons.currency_rupee_outlined,
    },
    {
      'label': 'General Inquiry / Other',
      'subtitle': 'General question or platform assistance',
      'icon': Icons.help_outline,
    },
  ];

  late String _selectedIssueType;
  String? _selectedOrderId;
  String? _selectedShopId;
  bool _isManualOrderMode = false;
  bool _isSubmitting = false;

  @override
  void initState() {
    super.initState();
    _selectedIssueType = issueCategories.first['label'] as String;

    if (widget.initialOrderId != null && widget.initialOrderId!.isNotEmpty) {
      _selectedOrderId = widget.initialOrderId;
      _manualOrderController.text = widget.initialOrderId!;
      _updateSubjectPrefix();
    }
  }

  @override
  void dispose() {
    _subjectController.dispose();
    _descController.dispose();
    _manualOrderController.dispose();
    super.dispose();
  }

  void _updateSubjectPrefix() {
    final effectiveOrder = _isManualOrderMode ? _manualOrderController.text.trim() : (_selectedOrderId ?? '');
    if (_subjectController.text.isEmpty || _subjectController.text.startsWith('[')) {
      if (effectiveOrder.isNotEmpty && effectiveOrder != '__NONE__') {
        _subjectController.text = '[$_selectedIssueType] Order #$effectiveOrder';
      } else {
        _subjectController.text = '[$_selectedIssueType]';
      }
    }
  }

  Future<void> _submitTicket() async {
    if (!_formKey.currentState!.validate()) return;

    final finalOrderId = _isManualOrderMode
        ? (_manualOrderController.text.trim().isNotEmpty ? _manualOrderController.text.trim() : null)
        : (_selectedOrderId != null && _selectedOrderId != '__NONE__' ? _selectedOrderId : null);

    setState(() => _isSubmitting = true);
    try {
      final dio = ref.read(apiProvider);
      final res = await dio.post('/support/tickets', data: {
        'issue_type': _selectedIssueType,
        'order_id': finalOrderId,
        'shop_id': _selectedShopId,
        'subject': _subjectController.text.trim(),
        'description': _descController.text.trim(),
      });

      if (res.statusCode == 200 || res.statusCode == 201) {
        ref.invalidate(supportTicketsProvider);
        if (!mounted) return;
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Support ticket submitted successfully. Our team will review it shortly.'),
            backgroundColor: Color(0xFF00C853),
          ),
        );
        context.pop();
      } else {
        final err = res.data?['error'] ?? 'Failed to submit ticket';
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(err)));
        }
      }
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Submission error: $e')));
    } finally {
      if (mounted) setState(() => _isSubmitting = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final ordersAsync = ref.watch(orderHistoryProvider);

    return Scaffold(
      extendBodyBehindAppBar: true,
      appBar: AppBar(
        title: Text(
          'New Support Ticket',
          style: TextStyle(color: theme.colorScheme.onSurface, fontWeight: FontWeight.bold),
        ),
        backgroundColor: Colors.transparent,
        elevation: 0,
        centerTitle: true,
        leading: IconButton(
          icon: Icon(Icons.arrow_back, color: theme.colorScheme.onSurface),
          onPressed: () => context.pop(),
        ),
      ),
      body: Stack(
        children: [
          const AmbientBackground(),
          SafeArea(
            child: SingleChildScrollView(
              padding: const EdgeInsets.all(20),
              child: GlassContainer(
                padding: const EdgeInsets.all(24),
                child: Form(
                  key: _formKey,
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // Header info
                      Row(
                        children: [
                          Container(
                            padding: const EdgeInsets.all(10),
                            decoration: BoxDecoration(
                              color: theme.colorScheme.primary.withValues(alpha: 0.15),
                              borderRadius: BorderRadius.circular(10),
                            ),
                            child: Icon(Icons.support_agent_rounded, color: theme.colorScheme.primary, size: 24),
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  'Issue Details',
                                  style: TextStyle(
                                    color: theme.colorScheme.onSurface,
                                    fontWeight: FontWeight.bold,
                                    fontSize: 16,
                                  ),
                                ),
                                Text(
                                  'Select your issue category and link the affected order.',
                                  style: TextStyle(
                                    color: theme.colorScheme.onSurface.withValues(alpha: 0.6),
                                    fontSize: 12,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 24),

                      // 1. Issue Category Dropdown
                      Text(
                        '1. ISSUE CATEGORY *',
                        style: TextStyle(
                          color: theme.colorScheme.primary,
                          fontSize: 12,
                          fontWeight: FontWeight.bold,
                          letterSpacing: 1.2,
                        ),
                      ),
                      const SizedBox(height: 8),
                      DropdownButtonFormField<String>(
                        initialValue: _selectedIssueType,
                        isExpanded: true,
                        dropdownColor: theme.colorScheme.surface,
                        style: TextStyle(color: theme.colorScheme.onSurface, fontSize: 14),
                        decoration: InputDecoration(
                          filled: true,
                          fillColor: theme.colorScheme.surface.withValues(alpha: 0.5),
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(12),
                            borderSide: BorderSide(color: theme.colorScheme.outlineVariant),
                          ),
                          contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
                        ),
                        items: issueCategories.map((cat) {
                          return DropdownMenuItem<String>(
                            value: cat['label'] as String,
                            child: Row(
                              children: [
                                Icon(cat['icon'] as IconData, size: 18, color: theme.colorScheme.primary),
                                const SizedBox(width: 10),
                                Expanded(
                                  child: Text(
                                    cat['label'] as String,
                                    style: const TextStyle(fontWeight: FontWeight.w600),
                                    overflow: TextOverflow.ellipsis,
                                  ),
                                ),
                              ],
                            ),
                          );
                        }).toList(),
                        onChanged: (val) {
                          if (val != null) {
                            setState(() {
                              _selectedIssueType = val;
                              _updateSubjectPrefix();
                            });
                          }
                        },
                      ),
                      const SizedBox(height: 20),

                      // 2. Order Link Option
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Text(
                            '2. RELATED ORDER',
                            style: TextStyle(
                              color: theme.colorScheme.primary,
                              fontSize: 12,
                              fontWeight: FontWeight.bold,
                              letterSpacing: 1.2,
                            ),
                          ),
                          TextButton(
                            onPressed: () {
                              setState(() {
                                _isManualOrderMode = !_isManualOrderMode;
                                if (_isManualOrderMode) {
                                  _selectedOrderId = null;
                                }
                                _updateSubjectPrefix();
                              });
                            },
                            style: TextButton.styleFrom(
                              padding: const EdgeInsets.symmetric(horizontal: 8),
                              minimumSize: Size.zero,
                              tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                            ),
                            child: Text(
                              _isManualOrderMode ? 'Choose from list' : 'Enter Order ID manually',
                              style: TextStyle(fontSize: 12, color: theme.colorScheme.primary),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 8),

                      if (_isManualOrderMode)
                        TextFormField(
                          controller: _manualOrderController,
                          style: TextStyle(color: theme.colorScheme.onSurface),
                          decoration: InputDecoration(
                            hintText: 'e.g. ORD-1049 or receipt number',
                            hintStyle: TextStyle(color: theme.colorScheme.onSurface.withValues(alpha: 0.5)),
                            filled: true,
                            fillColor: theme.colorScheme.surface.withValues(alpha: 0.5),
                            prefixIcon: Icon(Icons.receipt_long_outlined, color: theme.colorScheme.primary, size: 20),
                            border: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(12),
                              borderSide: BorderSide(color: theme.colorScheme.outlineVariant),
                            ),
                          ),
                          onChanged: (_) => _updateSubjectPrefix(),
                        )
                      else
                        ordersAsync.when(
                          data: (orders) {
                            final validOrders = orders.whereType<Map<String, dynamic>>().toList();

                            final items = <DropdownMenuItem<String>>[
                              DropdownMenuItem<String>(
                                value: '__NONE__',
                                child: Row(
                                  children: [
                                    Icon(Icons.not_interested, size: 16, color: theme.colorScheme.onSurfaceVariant),
                                    const SizedBox(width: 8),
                                    const Text('No specific order / General Inquiry'),
                                  ],
                                ),
                              ),
                              ...validOrders.map((ord) {
                                final id = ord['order_id']?.toString() ?? '';
                                final amount = ord['amount_total']?.toString() ?? '0';
                                final status = ord['status']?.toString().toUpperCase() ?? '';
                                return DropdownMenuItem<String>(
                                  value: id,
                                  child: Text(
                                    '$id • ₹$amount ($status)',
                                    style: const TextStyle(fontWeight: FontWeight.w500),
                                    overflow: TextOverflow.ellipsis,
                                  ),
                                );
                              }),
                            ];

                            // Determine if current selection is valid in list
                            final currentValue = (_selectedOrderId != null &&
                                    (validOrders.any((o) => o['order_id']?.toString() == _selectedOrderId) ||
                                        _selectedOrderId == '__NONE__'))
                                ? _selectedOrderId
                                : '__NONE__';

                            return DropdownButtonFormField<String>(
                              initialValue: currentValue,
                              isExpanded: true,
                              dropdownColor: theme.colorScheme.surface,
                              style: TextStyle(color: theme.colorScheme.onSurface, fontSize: 14),
                              decoration: InputDecoration(
                                filled: true,
                                fillColor: theme.colorScheme.surface.withValues(alpha: 0.5),
                                prefixIcon: Icon(Icons.receipt_long_outlined, color: theme.colorScheme.primary, size: 20),
                                border: OutlineInputBorder(
                                  borderRadius: BorderRadius.circular(12),
                                  borderSide: BorderSide(color: theme.colorScheme.outlineVariant),
                                ),
                                contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
                              ),
                              items: items,
                              onChanged: (val) {
                                setState(() {
                                  _selectedOrderId = val;
                                  if (val != null && val != '__NONE__') {
                                    final matched = validOrders.firstWhere(
                                      (o) => o['order_id']?.toString() == val,
                                      orElse: () => {},
                                    );
                                    _selectedShopId = matched['shop_id']?.toString();
                                  } else {
                                    _selectedShopId = null;
                                  }
                                  _updateSubjectPrefix();
                                });
                              },
                            );
                          },
                          loading: () => Container(
                            padding: const EdgeInsets.all(14),
                            decoration: BoxDecoration(
                              color: theme.colorScheme.surface.withValues(alpha: 0.5),
                              borderRadius: BorderRadius.circular(12),
                            ),
                            child: const Row(
                              children: [
                                SizedBox(width: 16, height: 16, child: CircularProgressIndicator(strokeWidth: 2)),
                                SizedBox(width: 12),
                                Text('Loading your recent orders...', style: TextStyle(fontSize: 13)),
                              ],
                            ),
                          ),
                          error: (err, stack) => TextFormField(
                            controller: _manualOrderController,
                            style: TextStyle(color: theme.colorScheme.onSurface),
                            decoration: InputDecoration(
                              hintText: 'Enter Order ID (e.g. ORD-1049)',
                              hintStyle: TextStyle(color: theme.colorScheme.onSurface.withValues(alpha: 0.5)),
                              filled: true,
                              fillColor: theme.colorScheme.surface.withValues(alpha: 0.5),
                              prefixIcon: Icon(Icons.receipt_long_outlined, color: theme.colorScheme.primary, size: 20),
                              border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                            ),
                            onChanged: (_) => _updateSubjectPrefix(),
                          ),
                        ),
                      const SizedBox(height: 20),

                      // 3. Subject / Title
                      Text(
                        '3. TICKET TITLE *',
                        style: TextStyle(
                          color: theme.colorScheme.primary,
                          fontSize: 12,
                          fontWeight: FontWeight.bold,
                          letterSpacing: 1.2,
                        ),
                      ),
                      const SizedBox(height: 8),
                      TextFormField(
                        controller: _subjectController,
                        style: TextStyle(color: theme.colorScheme.onSurface),
                        decoration: InputDecoration(
                          hintText: 'Brief summary of the issue',
                          hintStyle: TextStyle(color: theme.colorScheme.onSurface.withValues(alpha: 0.5)),
                          filled: true,
                          fillColor: theme.colorScheme.surface.withValues(alpha: 0.5),
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(12),
                            borderSide: BorderSide(color: theme.colorScheme.outlineVariant),
                          ),
                        ),
                        validator: (v) => v == null || v.trim().isEmpty ? 'Ticket title is required' : null,
                      ),
                      const SizedBox(height: 20),

                      // 4. Description
                      Text(
                        '4. DETAILED DESCRIPTION *',
                        style: TextStyle(
                          color: theme.colorScheme.primary,
                          fontSize: 12,
                          fontWeight: FontWeight.bold,
                          letterSpacing: 1.2,
                        ),
                      ),
                      const SizedBox(height: 8),
                      TextFormField(
                        controller: _descController,
                        maxLines: 5,
                        style: TextStyle(color: theme.colorScheme.onSurface),
                        decoration: InputDecoration(
                          hintText: 'Describe the problem clearly (e.g. pages affected, print appearance, or shop response)...',
                          hintStyle: TextStyle(color: theme.colorScheme.onSurface.withValues(alpha: 0.5)),
                          filled: true,
                          fillColor: theme.colorScheme.surface.withValues(alpha: 0.5),
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(12),
                            borderSide: BorderSide(color: theme.colorScheme.outlineVariant),
                          ),
                        ),
                        validator: (v) => v == null || v.trim().isEmpty ? 'Please provide details about your issue' : null,
                      ),
                      const SizedBox(height: 32),

                      // Submit Button
                      SizedBox(
                        width: double.infinity,
                        height: 52,
                        child: ElevatedButton(
                          style: ElevatedButton.styleFrom(
                            backgroundColor: theme.colorScheme.primary,
                            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                            elevation: 0,
                          ),
                          onPressed: _isSubmitting ? null : _submitTicket,
                          child: _isSubmitting
                              ? const SizedBox(
                                  width: 24,
                                  height: 24,
                                  child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2.5),
                                )
                              : Text(
                                  'Submit Support Ticket',
                                  style: TextStyle(
                                    color: theme.colorScheme.onPrimary,
                                    fontWeight: FontWeight.bold,
                                    fontSize: 16,
                                  ),
                                ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
