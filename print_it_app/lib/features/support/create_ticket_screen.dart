import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../core/api/api_client.dart';
import '../../shared/widgets/ambient_background.dart';
import '../../shared/widgets/glass_container.dart';
import 'support_provider.dart';

class CreateTicketScreen extends ConsumerStatefulWidget {
  const CreateTicketScreen({super.key});

  @override
  ConsumerState<CreateTicketScreen> createState() => _CreateTicketScreenState();
}

class _CreateTicketScreenState extends ConsumerState<CreateTicketScreen> {
  final _formKey = GlobalKey<FormState>();
  final _subjectController = TextEditingController();
  final _descController = TextEditingController();
  String? _selectedShopId;
  bool _isSubmitting = false;

  Future<void> _submitTicket() async {
    if (!_formKey.currentState!.validate()) return;
    
    setState(() => _isSubmitting = true);
    try {
      final dio = ref.read(apiProvider);
      final res = await dio.post('/support/tickets', data: {
        'subject': _subjectController.text,
        'description': _descController.text,
        'shop_id': _selectedShopId,
      });

      if (res.statusCode == 201) {
        ref.invalidate(supportTicketsProvider);
        if (!mounted) return;
        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Ticket created successfully')));
        context.pop();
      }
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Failed to create ticket: $e')));
    } finally {
      if (mounted) setState(() => _isSubmitting = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Scaffold(
      extendBodyBehindAppBar: true,
      appBar: AppBar(
        title: Text('New Support Ticket', style: TextStyle(color: theme.colorScheme.onSurface, fontWeight: FontWeight.bold)),
        backgroundColor: Colors.transparent,
        elevation: 0,
        centerTitle: true,
      ),
      body: Stack(
        children: [
          const AmbientBackground(),
          SafeArea(
            child: SingleChildScrollView(
              padding: const EdgeInsets.all(20),
              child: GlassContainer(
                padding: const EdgeInsets.all(20),
                child: Form(
                  key: _formKey,
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text('Subject', style: TextStyle(color: theme.colorScheme.primary, fontWeight: FontWeight.bold)),
                      const SizedBox(height: 8),
                      TextFormField(
                        controller: _subjectController,
                        style: TextStyle(color: theme.colorScheme.onSurface),
                        decoration: InputDecoration(
                          hintText: 'Briefly describe the issue',
                          hintStyle: TextStyle(color: theme.colorScheme.onSurface.withValues(alpha: 0.5)),
                          filled: true,
                          fillColor: theme.colorScheme.surface.withValues(alpha: 0.5),
                          border: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide.none),
                        ),
                        validator: (v) => v == null || v.isEmpty ? 'Subject is required' : null,
                      ),
                      const SizedBox(height: 20),

                      Text('Description', style: TextStyle(color: theme.colorScheme.primary, fontWeight: FontWeight.bold)),
                      const SizedBox(height: 8),
                      TextFormField(
                        controller: _descController,
                        maxLines: 5,
                        style: TextStyle(color: theme.colorScheme.onSurface),
                        decoration: InputDecoration(
                          hintText: 'Provide details about your issue...',
                          hintStyle: TextStyle(color: theme.colorScheme.onSurface.withValues(alpha: 0.5)),
                          filled: true,
                          fillColor: theme.colorScheme.surface.withValues(alpha: 0.5),
                          border: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide.none),
                        ),
                        validator: (v) => v == null || v.isEmpty ? 'Description is required' : null,
                      ),
                      const SizedBox(height: 32),
                      
                      SizedBox(
                        width: double.infinity,
                        height: 50,
                        child: ElevatedButton(
                          style: ElevatedButton.styleFrom(
                            backgroundColor: theme.colorScheme.primary,
                            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                          ),
                          onPressed: _isSubmitting ? null : _submitTicket,
                          child: _isSubmitting
                              ? const CircularProgressIndicator(color: Colors.white)
                              : Text('Submit Ticket', style: TextStyle(color: theme.colorScheme.onPrimary, fontWeight: FontWeight.bold, fontSize: 16)),
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
