import 'package:fcm_push_kit/fcm_push_kit.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../services/notification_log.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> with WidgetsBindingObserver {
  final _kit = FcmPushKit.instance;

  AuthorizationStatus? _permission;
  String? _token;
  bool _loadingToken = false;

  // FCM has no API to list subscriptions, so this mirrors what the app did.
  // 'all' is subscribed on startup via FcmPushKitConfig.topics.
  final Map<String, bool> _topics = {
    'all': true,
    'offers': false,
    'news': false,
  };

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    _refresh();
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    super.dispose();
  }

  // Picks up permission changes made in system settings.
  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.resumed) _loadPermission();
  }

  Future<void> _refresh() async {
    if (!_kit.isInitialized) return;
    await Future.wait([_loadPermission(), _loadToken()]);
  }

  Future<void> _loadPermission() async {
    if (!_kit.isInitialized) return;
    final status = await _kit.getPermissionStatus();
    if (mounted) setState(() => _permission = status);
  }

  Future<void> _loadToken() async {
    setState(() => _loadingToken = true);
    final token = await _kit.getToken();
    debugPrint('FCM TOKEN: $token');
    if (mounted) {
      setState(() {
        _token = token;
        _loadingToken = false;
      });
    }
  }

  Future<void> _requestPermission() async {
    await _kit.requestPermission();
    await _refresh();
  }

  Future<void> _copyToken() async {
    final token = _token;
    if (token == null) return;
    await Clipboard.setData(ClipboardData(text: token));
    _snack('FCM token copied to clipboard');
  }

  Future<void> _toggleTopic(String topic, bool subscribe) async {
    setState(() => _topics[topic] = subscribe);
    try {
      subscribe
          ? await _kit.subscribeToTopic(topic)
          : await _kit.unsubscribeFromTopic(topic);
      _snack(
        subscribe ? 'Subscribed to "$topic"' : 'Unsubscribed from "$topic"',
      );
    } catch (e) {
      setState(() => _topics[topic] = !subscribe);
      _snack('Topic update failed: $e');
    }
  }

  Future<void> _sendLocal(
    String title,
    String body,
    Map<String, String> data,
  ) async {
    await _kit.showNotification(title: title, body: body, data: data);
  }

  void _snack(String message) {
    if (!mounted) return;
    ScaffoldMessenger.of(context)
      ..hideCurrentSnackBar()
      ..showSnackBar(SnackBar(content: Text(message)));
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Push Notification Demo'),
        actions: [
          IconButton(
            tooltip: 'Refresh',
            icon: const Icon(Icons.refresh),
            onPressed: _refresh,
          ),
        ],
      ),
      body: RefreshIndicator(
        onRefresh: _refresh,
        child: ListView(
          padding: const EdgeInsets.fromLTRB(16, 8, 16, 24),
          children: [
            _buildStatusCard(),
            _buildTokenCard(),
            _buildTestCard(),
            _buildTopicsCard(),
            _buildActivityCard(),
          ],
        ),
      ),
    );
  }

  Widget _buildStatusCard() {
    final connected = _kit.isInitialized;
    final projectId = connected ? Firebase.app().options.projectId : null;
    final granted =
        _permission == AuthorizationStatus.authorized ||
        _permission == AuthorizationStatus.provisional;

    return _SectionCard(
      icon: Icons.health_and_safety_outlined,
      title: 'Status',
      children: [
        _StatusRow(
          label: 'Firebase',
          value: connected ? 'Connected · $projectId' : 'Not configured',
          ok: connected,
        ),
        _StatusRow(
          label: 'Permission',
          value: _permissionLabel(_permission),
          ok: granted,
          pending:
              _permission == null ||
              _permission == AuthorizationStatus.notDetermined,
        ),
        _StatusRow(
          label: 'Platform',
          value: defaultTargetPlatform.name,
          ok: true,
          neutral: true,
        ),
        if (connected && !granted) ...[
          const SizedBox(height: 8),
          if (_permission == AuthorizationStatus.denied ||
              _permission == AuthorizationStatus.deniedPermanently)
            Text(
              'Notifications are blocked. Enable them in system Settings → '
              'Apps → Push Notification Demo → Notifications.',
              style: Theme.of(context).textTheme.bodySmall,
            ),
          const SizedBox(height: 8),
          FilledButton.icon(
            onPressed: _requestPermission,
            icon: const Icon(Icons.notifications_active_outlined),
            label: const Text('Request permission'),
          ),
        ],
      ],
    );
  }

  Widget _buildTokenCard() {
    final theme = Theme.of(context);
    return _SectionCard(
      icon: Icons.key_outlined,
      title: 'FCM token',
      children: [
        Container(
          width: double.infinity,
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
            color: theme.colorScheme.surfaceContainerHighest,
            borderRadius: BorderRadius.circular(8),
          ),
          child: _loadingToken
              ? const Center(
                  child: SizedBox.square(
                    dimension: 20,
                    child: CircularProgressIndicator(strokeWidth: 2),
                  ),
                )
              : SelectableText(
                  _token ??
                      (_kit.isInitialized
                          ? 'No token yet. Check permission and network, then refresh.'
                          : 'Firebase is not configured.'),
                  maxLines: 4,
                  style: theme.textTheme.bodySmall?.copyWith(
                    fontFamily: 'monospace',
                  ),
                ),
        ),
        const SizedBox(height: 8),
        Text(
          'Paste it in Firebase console → Messaging → New campaign → '
          'Send test message.',
          style: theme.textTheme.bodySmall,
        ),
        const SizedBox(height: 8),
        Row(
          children: [
            Expanded(
              child: FilledButton.icon(
                onPressed: _token == null ? null : _copyToken,
                icon: const Icon(Icons.copy),
                label: const Text('Copy token'),
              ),
            ),
            const SizedBox(width: 8),
            Expanded(
              child: OutlinedButton.icon(
                onPressed: _kit.isInitialized && !_loadingToken
                    ? _loadToken
                    : null,
                icon: const Icon(Icons.refresh),
                label: const Text('Refresh'),
              ),
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildTestCard() {
    final enabled = _kit.isInitialized;
    return _SectionCard(
      icon: Icons.science_outlined,
      title: 'Quick test (no server)',
      children: [
        Text(
          'Shows a notification from the app itself. Tap it to check that '
          'deep links open the right screen.',
          style: Theme.of(context).textTheme.bodySmall,
        ),
        const SizedBox(height: 12),
        _TestButton(
          icon: Icons.receipt_long_outlined,
          label: 'Notification → Details (id 42)',
          onPressed: enabled
              ? () => _sendLocal(
                  'Order #42 shipped',
                  'Tap to see order details',
                  {'route': '/details', 'id': '42'},
                )
              : null,
        ),
        const SizedBox(height: 8),
        _TestButton(
          icon: Icons.person_outline,
          label: 'Notification → Profile',
          onPressed: enabled
              ? () => _sendLocal(
                  'Profile updated',
                  'Tap to view your profile',
                  {'route': '/profile'},
                )
              : null,
        ),
      ],
    );
  }

  Widget _buildTopicsCard() {
    return _SectionCard(
      icon: Icons.campaign_outlined,
      title: 'Topics',
      children: [
        for (final entry in _topics.entries)
          SwitchListTile(
            contentPadding: EdgeInsets.zero,
            title: Text(entry.key),
            subtitle: Text(
              entry.key == 'all'
                  ? 'Broadcasts to every install'
                  : 'Send with target "Topic: ${entry.key}"',
            ),
            value: entry.value,
            onChanged: _kit.isInitialized
                ? (v) => _toggleTopic(entry.key, v)
                : null,
          ),
      ],
    );
  }

  Widget _buildActivityCard() {
    return ListenableBuilder(
      listenable: NotificationLog.instance,
      builder: (context, _) {
        final entries = NotificationLog.instance.entries;
        return _SectionCard(
          icon: Icons.history,
          title: 'Activity',
          trailing: entries.isEmpty
              ? null
              : TextButton(
                  onPressed: NotificationLog.instance.clear,
                  child: const Text('Clear'),
                ),
          children: [
            if (entries.isEmpty)
              Padding(
                padding: const EdgeInsets.symmetric(vertical: 12),
                child: Text(
                  'Nothing yet. Messages received while the app is open and '
                  'notification taps appear here.',
                  style: Theme.of(context).textTheme.bodySmall,
                ),
              )
            else
              for (final entry in entries) _ActivityTile(entry: entry),
          ],
        );
      },
    );
  }

  static String _permissionLabel(AuthorizationStatus? status) =>
      switch (status) {
        AuthorizationStatus.authorized => 'Allowed',
        AuthorizationStatus.provisional => 'Provisional',
        AuthorizationStatus.denied => 'Denied',
        AuthorizationStatus.deniedPermanently => 'Blocked',
        AuthorizationStatus.notDetermined => 'Not asked yet',
        null => 'Unknown',
      };
}

class _SectionCard extends StatelessWidget {
  const _SectionCard({
    required this.icon,
    required this.title,
    required this.children,
    this.trailing,
  });

  final IconData icon;
  final String title;
  final List<Widget> children;
  final Widget? trailing;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Card(
      margin: const EdgeInsets.only(top: 12),
      child: Padding(
        padding: const EdgeInsets.fromLTRB(16, 12, 16, 16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(icon, size: 20, color: theme.colorScheme.primary),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(title, style: theme.textTheme.titleMedium),
                ),
                ?trailing,
              ],
            ),
            const SizedBox(height: 8),
            ...children,
          ],
        ),
      ),
    );
  }
}

class _StatusRow extends StatelessWidget {
  const _StatusRow({
    required this.label,
    required this.value,
    required this.ok,
    this.pending = false,
    this.neutral = false,
  });

  final String label;
  final String value;
  final bool ok;
  final bool pending;
  final bool neutral;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final color = neutral
        ? theme.colorScheme.outline
        : ok
        ? Colors.green.shade600
        : pending
        ? Colors.orange.shade700
        : theme.colorScheme.error;
    final icon = neutral
        ? Icons.info_outline
        : ok
        ? Icons.check_circle
        : pending
        ? Icons.help_outline
        : Icons.cancel;

    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        children: [
          Icon(icon, size: 18, color: color),
          const SizedBox(width: 8),
          SizedBox(
            width: 90,
            child: Text(label, style: theme.textTheme.bodyMedium),
          ),
          Expanded(
            child: Text(
              value,
              textAlign: TextAlign.end,
              overflow: TextOverflow.ellipsis,
              style: theme.textTheme.bodyMedium?.copyWith(
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _TestButton extends StatelessWidget {
  const _TestButton({required this.icon, required this.label, this.onPressed});

  final IconData icon;
  final String label;
  final VoidCallback? onPressed;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: double.infinity,
      child: OutlinedButton.icon(
        onPressed: onPressed,
        icon: Icon(icon),
        label: Text(label),
        style: OutlinedButton.styleFrom(
          alignment: Alignment.centerLeft,
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
        ),
      ),
    );
  }
}

class _ActivityTile extends StatelessWidget {
  const _ActivityTile({required this.entry});

  final NotificationLogEntry entry;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final received = entry.type == LogEntryType.received;
    final time = entry.time;
    final clock = [
      time.hour,
      time.minute,
      time.second,
    ].map((v) => v.toString().padLeft(2, '0')).join(':');
    final heading = received
        ? (entry.title ?? 'Data message')
        : 'Tapped (${entry.source?.name ?? 'unknown'})';
    final details = [
      if (received && entry.body != null) entry.body!,
      if (entry.data.isNotEmpty) entry.data.toString(),
    ].join('\n');

    return ListTile(
      contentPadding: EdgeInsets.zero,
      leading: CircleAvatar(
        backgroundColor: received
            ? theme.colorScheme.primaryContainer
            : theme.colorScheme.tertiaryContainer,
        child: Icon(
          received
              ? Icons.mark_email_unread_outlined
              : Icons.touch_app_outlined,
          size: 20,
        ),
      ),
      title: Text(heading),
      subtitle: details.isEmpty ? null : Text(details),
      trailing: Text(clock, style: theme.textTheme.bodySmall),
    );
  }
}
