import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../shared/widgets/ambient_background.dart';
import '../../shared/widgets/glass_container.dart';

class HelpSupportScreen extends ConsumerWidget {
  const HelpSupportScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return Scaffold(
      extendBodyBehindAppBar: true,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        title: Text('Help & Support', style: TextStyle(color: Theme.of(context).colorScheme.onSurface, fontWeight: FontWeight.bold)),
        centerTitle: true,
      ),
      body: Stack(
        children: [
          const AmbientBackground(),
          SafeArea(
            child: SingleChildScrollView(
              padding: const EdgeInsets.all(20),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  _buildSectionTitle(context, 'Frequently Asked Questions'),
                  const SizedBox(height: 16),
                  _buildFaqItem(
                    context,
                    question: 'How do I track my order?',
                    answer: 'You can track the live status of your document by navigating to "Order History" and tapping on an active order. It will show whether it is in queue, printing, or ready for pickup.',
                  ),
                  _buildFaqItem(
                    context,
                    question: 'What are the supported payment methods?',
                    answer: 'We support all major payment methods including Credit/Debit cards, UPI, and various mobile wallets securely via Razorpay. You can also add money to your in-app Wallet for quicker checkouts.',
                  ),
                  _buildFaqItem(
                    context,
                    question: 'How does Express Pickup work?',
                    answer: 'When you select Express Pickup, your print job is prioritized to the top of the shopkeeper\'s queue. This ensures the fastest possible turnaround time for urgent documents.',
                  ),
                  _buildFaqItem(
                    context,
                    question: 'What happens if a print fails?',
                    answer: 'If there is an issue with the printer or your document is corrupted, the shopkeeper will mark it as failed and the amount will be immediately refunded to your Print It wallet.',
                  ),
                  
                  const SizedBox(height: 32),
                  _buildSectionTitle(context, 'My Tickets'),
                  const SizedBox(height: 16),
                  GlassContainer(
                    padding: const EdgeInsets.all(20),
                    child: Column(
                      children: [
                        ListTile(
                          leading: Icon(Icons.confirmation_num, color: Theme.of(context).colorScheme.primary),
                          title: Text('View My Tickets', style: TextStyle(color: Theme.of(context).colorScheme.onSurface, fontWeight: FontWeight.bold)),
                          trailing: Icon(Icons.chevron_right, color: Theme.of(context).colorScheme.onSurface),
                          onTap: () => context.push('/my-tickets'),
                        ),
                        Divider(color: Theme.of(context).colorScheme.outlineVariant),
                        ListTile(
                          leading: Icon(Icons.add_circle_outline, color: Theme.of(context).colorScheme.primary),
                          title: Text('Create New Ticket', style: TextStyle(color: Theme.of(context).colorScheme.onSurface, fontWeight: FontWeight.bold)),
                          trailing: Icon(Icons.chevron_right, color: Theme.of(context).colorScheme.onSurface),
                          onTap: () => context.push('/create-ticket'),
                        ),
                      ],
                    ),
                  ),

                  const SizedBox(height: 32),
                  _buildSectionTitle(context, 'Contact Us'),
                  const SizedBox(height: 16),
                  GlassContainer(
                    padding: const EdgeInsets.all(20),
                    child: Column(
                      children: [
                        _buildContactRow(context, Icons.email_outlined, 'support@printit.com'),
                      ],
                    ),
                  ),

                  const SizedBox(height: 40),
                  Center(
                    child: Text(
                      'PrintIt\nVersion 1.0.0',
                      textAlign: TextAlign.center,
                      style: TextStyle(
                        color: Theme.of(context).colorScheme.onSurface.withValues(alpha: 0.5),
                        fontSize: 14,
                      ),
                    ),
                  ),
                  const SizedBox(height: 20),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSectionTitle(BuildContext context, String title) {
    return Text(
      title,
      style: TextStyle(
        color: Theme.of(context).colorScheme.primary,
        fontSize: 20,
        fontWeight: FontWeight.bold,
      ),
    );
  }

  Widget _buildFaqItem(BuildContext context, {required String question, required String answer}) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 16.0),
      child: GlassContainer(
        padding: const EdgeInsets.all(0),
        child: Theme(
          data: Theme.of(context).copyWith(dividerColor: Colors.transparent),
          child: ExpansionTile(
            collapsedIconColor: Theme.of(context).colorScheme.primary,
            iconColor: Theme.of(context).colorScheme.primary,
            title: Text(
              question,
              style: TextStyle(
                color: Theme.of(context).colorScheme.onSurface,
                fontWeight: FontWeight.w600,
                fontSize: 16,
              ),
            ),
            children: [
              Padding(
                padding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
                child: Text(
                  answer,
                  style: TextStyle(
                    color: Theme.of(context).colorScheme.onSurface.withValues(alpha: 0.8),
                    height: 1.5,
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildContactRow(BuildContext context, IconData icon, String text) {
    return Row(
      children: [
        Container(
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
            color: Theme.of(context).colorScheme.primary.withValues(alpha: 0.1),
            shape: BoxShape.circle,
          ),
          child: Icon(icon, color: Theme.of(context).colorScheme.primary, size: 20),
        ),
        const SizedBox(width: 16),
        Expanded(
          child: Text(
            text,
            style: TextStyle(
              color: Theme.of(context).colorScheme.onSurface,
              fontSize: 16,
              fontWeight: FontWeight.w500,
            ),
          ),
        ),
      ],
    );
  }
}
