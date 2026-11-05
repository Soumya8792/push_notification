import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

/// Target of `{"route": "/details", "id": "..."}` notifications.
class DetailsScreen extends StatelessWidget {
  const DetailsScreen({super.key, required this.params});

  final Map<String, String> params;

  @override
  Widget build(BuildContext context) {
    return _DeepLinkScaffold(
      title: 'Order details',
      icon: Icons.receipt_long,
      color: Colors.green,
      headline: 'Opened from a notification',
      params: params,
    );
  }
}

/// Target of `{"route": "/profile"}` notifications.
class ProfileScreen extends StatelessWidget {
  const ProfileScreen({super.key, required this.params});

  final Map<String, String> params;

  @override
  Widget build(BuildContext context) {
    return _DeepLinkScaffold(
      title: 'Profile',
      icon: Icons.person,
      color: Colors.purple,
      headline: 'Profile screen',
      params: params,
    );
  }
}

class _DeepLinkScaffold extends StatelessWidget {
  const _DeepLinkScaffold({
    required this.title,
    required this.icon,
    required this.color,
    required this.headline,
    required this.params,
  });

  final String title;
  final IconData icon;
  final Color color;
  final String headline;
  final Map<String, String> params;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Scaffold(
      appBar: AppBar(
        title: Text(title),
        leading: BackButton(onPressed: () => context.go('/')),
      ),
      body: ListView(
        padding: const EdgeInsets.all(24),
        children: [
          const SizedBox(height: 24),
          CircleAvatar(
            radius: 44,
            backgroundColor: color.withValues(alpha: 0.12),
            child: Icon(icon, size: 44, color: color),
          ),
          const SizedBox(height: 16),
          Text(
            headline,
            textAlign: TextAlign.center,
            style: theme.textTheme.titleLarge,
          ),
          const SizedBox(height: 4),
          Text(
            'Deep link navigation worked.',
            textAlign: TextAlign.center,
            style: theme.textTheme.bodyMedium?.copyWith(
              color: theme.colorScheme.outline,
            ),
          ),
          const SizedBox(height: 24),
          Card(
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text('Payload data', style: theme.textTheme.titleSmall),
                  const SizedBox(height: 8),
                  if (params.isEmpty)
                    Text('No extra data', style: theme.textTheme.bodySmall)
                  else
                    for (final entry in params.entries)
                      Padding(
                        padding: const EdgeInsets.symmetric(vertical: 4),
                        child: Row(
                          children: [
                            Text(entry.key, style: theme.textTheme.bodyMedium),
                            const Spacer(),
                            Text(
                              entry.value,
                              style: theme.textTheme.bodyMedium?.copyWith(
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                          ],
                        ),
                      ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 24),
          FilledButton.icon(
            onPressed: () => context.go('/'),
            icon: const Icon(Icons.home_outlined),
            label: const Text('Back to home'),
          ),
        ],
      ),
    );
  }
}
