import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import '../../shared/widgets/ambient_background.dart';
import '../../shared/widgets/glass_container.dart';

class NotFoundScreen extends StatelessWidget {
  final String? uri;

  const NotFoundScreen({super.key, this.uri});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    final canPop = Navigator.of(context).canPop();

    void goBack() {
      if (Navigator.of(context).canPop()) {
        Navigator.of(context).pop();
      } else {
        try {
          context.go('/home');
        } catch (_) {
          Navigator.of(context).pushReplacementNamed('/home');
        }
      }
    }

    void goHome() {
      try {
        context.go('/home');
      } catch (_) {
        Navigator.of(context).pushReplacementNamed('/home');
      }
    }

    return Scaffold(
      extendBodyBehindAppBar: true,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        leading: IconButton(
          icon: Icon(Icons.arrow_back, color: theme.colorScheme.onSurface),
          onPressed: goBack,
        ),
      ),
      body: Stack(
        children: [
          const AmbientBackground(),
          SafeArea(
            child: Center(
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 24.0),
                child: GlassContainer(
                  padding: const EdgeInsets.all(32.0),
                  borderRadius: 24,
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Container(
                        padding: const EdgeInsets.all(20),
                        decoration: BoxDecoration(
                          color: theme.colorScheme.primary.withValues(alpha: 0.1),
                          shape: BoxShape.circle,
                        ),
                        child: Icon(
                          Icons.explore_off_rounded,
                          size: 56,
                          color: theme.colorScheme.primary,
                        ),
                      ),
                      const SizedBox(height: 24),
                      Text(
                        '404 - Page Not Found',
                        style: theme.textTheme.headlineMedium?.copyWith(
                          fontWeight: FontWeight.bold,
                          color: theme.colorScheme.onSurface,
                        ),
                      ),
                      const SizedBox(height: 12),
                      Text(
                        uri != null && uri!.isNotEmpty
                            ? 'The screen or route "$uri" could not be found or has moved.'
                            : 'The screen or destination you are looking for does not exist.',
                        textAlign: TextAlign.center,
                        style: theme.textTheme.bodyMedium?.copyWith(
                          color: theme.colorScheme.onSurface.withValues(alpha: 0.7),
                        ),
                      ),
                      const SizedBox(height: 32),
                      Row(
                        children: [
                          if (canPop)
                            Expanded(
                              child: OutlinedButton(
                                onPressed: goBack,
                                style: OutlinedButton.styleFrom(
                                  padding: const EdgeInsets.symmetric(vertical: 14),
                                  shape: RoundedRectangleBorder(
                                    borderRadius: BorderRadius.circular(12),
                                  ),
                                ),
                                child: const Text('Go Back'),
                              ),
                            ),
                          if (canPop) const SizedBox(width: 12),
                          Expanded(
                            child: ElevatedButton(
                              onPressed: goHome,
                              style: ElevatedButton.styleFrom(
                                backgroundColor: theme.colorScheme.primary,
                                foregroundColor: Colors.white,
                                padding: const EdgeInsets.symmetric(vertical: 14),
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(12),
                                ),
                              ),
                              child: const Text(
                                'Return Home',
                                style: TextStyle(fontWeight: FontWeight.bold),
                              ),
                            ),
                          ),
                        ],
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
