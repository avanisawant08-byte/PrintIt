import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../core/api/api_client.dart';
import '../../shared/widgets/ambient_background.dart';
import 'support_provider.dart';
import '../auth/auth_provider.dart';

class TicketDetailScreen extends ConsumerStatefulWidget {
  final String ticketId;

  const TicketDetailScreen({super.key, required this.ticketId});

  @override
  ConsumerState<TicketDetailScreen> createState() => _TicketDetailScreenState();
}

class _TicketDetailScreenState extends ConsumerState<TicketDetailScreen> {
  final _msgController = TextEditingController();
  bool _isSending = false;

  Future<void> _sendMessage() async {
    if (_msgController.text.trim().isEmpty) return;
    
    setState(() => _isSending = true);
    try {
      final dio = ref.read(apiProvider);
      final res = await dio.post('/support/tickets/${widget.ticketId}/messages', data: {
        'message': _msgController.text.trim(),
      });

      if (res.statusCode == 201) {
        _msgController.clear();
        ref.invalidate(ticketDetailProvider(widget.ticketId));
      }
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Failed to send message: $e')));
    } finally {
      if (mounted) setState(() => _isSending = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final detailAsync = ref.watch(ticketDetailProvider(widget.ticketId));
    final authState = ref.watch(authProvider);
    final currentUserId = authState.user?['user_id'];

    return Scaffold(
      extendBodyBehindAppBar: true,
      appBar: AppBar(
        title: detailAsync.when(
          data: (data) => Column(
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              Text(data['ticket_token'], style: TextStyle(color: theme.colorScheme.onSurface, fontWeight: FontWeight.bold, fontSize: 16)),
              Text(data['status'].toString().toUpperCase().replaceAll('_', ' '), style: TextStyle(color: theme.colorScheme.primary, fontSize: 12)),
            ],
          ),
          loading: () => const Text('Loading...'),
          error: (err, st) => const Text('Error'),
        ),
        backgroundColor: theme.colorScheme.surface.withValues(alpha: 0.8),
        elevation: 0,
        centerTitle: true,
      ),
      body: Stack(
        children: [
          const AmbientBackground(),
          SafeArea(
            child: detailAsync.when(
              data: (data) {
                final messages = data['messages'] as List<dynamic>;
                return Column(
                  children: [
                    // Original Issue description
                    Container(
                      padding: const EdgeInsets.all(16),
                      margin: const EdgeInsets.all(16),
                      decoration: BoxDecoration(
                        color: theme.colorScheme.surfaceContainerHighest.withValues(alpha: 0.5),
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(color: theme.colorScheme.outlineVariant),
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text('Subject: ${data['subject']}', style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
                          const SizedBox(height: 8),
                          Text(data['description']),
                        ],
                      ),
                    ),
                    
                    Expanded(
                      child: ListView.builder(
                        padding: const EdgeInsets.symmetric(horizontal: 16),
                        itemCount: messages.length,
                        itemBuilder: (context, index) {
                          final msg = messages[index];
                          final isMe = msg['sender_id'] == currentUserId;
                          final role = msg['sender_role'];
                          
                          return Align(
                            alignment: isMe ? Alignment.centerRight : Alignment.centerLeft,
                            child: Container(
                              margin: const EdgeInsets.only(bottom: 12),
                              padding: const EdgeInsets.all(12),
                              constraints: BoxConstraints(maxWidth: MediaQuery.of(context).size.width * 0.75),
                              decoration: BoxDecoration(
                                color: isMe ? theme.colorScheme.primary : theme.colorScheme.surfaceContainer,
                                borderRadius: BorderRadius.circular(12).copyWith(
                                  bottomRight: isMe ? const Radius.circular(0) : const Radius.circular(12),
                                  bottomLeft: !isMe ? const Radius.circular(0) : const Radius.circular(12),
                                ),
                              ),
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  if (!isMe)
                                    Text(role == 'admin' ? 'Support Admin' : role == 'shop' ? data['shop_name'] : 'System',
                                      style: TextStyle(fontSize: 10, color: theme.colorScheme.primary, fontWeight: FontWeight.bold)),
                                  const SizedBox(height: 4),
                                  Text(
                                    msg['message'],
                                    style: TextStyle(color: isMe ? theme.colorScheme.onPrimary : theme.colorScheme.onSurface),
                                  ),
                                  const SizedBox(height: 4),
                                  Align(
                                    alignment: Alignment.bottomRight,
                                    child: Text(
                                      DateTime.parse(msg['created_at']).toLocal().toString().substring(11, 16),
                                      style: TextStyle(fontSize: 10, color: (isMe ? theme.colorScheme.onPrimary : theme.colorScheme.onSurface).withValues(alpha: 0.6)),
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          );
                        },
                      ),
                    ),
                    
                    // Reply box
                    if (data['status'] != 'closed')
                      Container(
                        padding: const EdgeInsets.all(16),
                        color: theme.colorScheme.surface,
                        child: Row(
                          children: [
                            Expanded(
                              child: TextField(
                                controller: _msgController,
                                decoration: InputDecoration(
                                  hintText: 'Type a reply...',
                                  filled: true,
                                  fillColor: theme.colorScheme.surfaceContainerHighest,
                                  border: OutlineInputBorder(
                                    borderRadius: BorderRadius.circular(24),
                                    borderSide: BorderSide.none,
                                  ),
                                  contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                                ),
                              ),
                            ),
                            const SizedBox(width: 8),
                            CircleAvatar(
                              backgroundColor: theme.colorScheme.primary,
                              child: IconButton(
                                icon: _isSending 
                                  ? const SizedBox(width: 20, height: 20, child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2)) 
                                  : const Icon(Icons.send, color: Colors.white),
                                onPressed: _isSending ? null : _sendMessage,
                              ),
                            ),
                          ],
                        ),
                      ),
                  ],
                );
              },
              loading: () => const Center(child: CircularProgressIndicator()),
              error: (err, st) => Center(child: Text('Error: $err')),
            ),
          ),
        ],
      ),
    );
  }
}
