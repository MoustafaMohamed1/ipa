import 'package:flutter/material.dart';
import '../../core/network/api_service.dart';
import '../../core/utils/date_utils.dart';
import '../../shared/widgets/loading_widget.dart';
import '../../shared/widgets/empty_widget.dart';
import '../../shared/widgets/error_widget.dart' as app;

class NotificationsScreen extends StatefulWidget {
  const NotificationsScreen({super.key});
  @override
  State<NotificationsScreen> createState() => _NotificationsScreenState();
}

class _NotificationsScreenState extends State<NotificationsScreen> {
  final _api = ApiService();
  List<dynamic> _notifications = [];
  bool _loading = true;
  String? _error;

  @override
  void initState() { super.initState(); _load(); }

  Future<void> _load() async {
    setState(() { _loading = true; _error = null; });
    try {
      final res = await _api.get('/me/notifications');
      _notifications = res.data is List ? res.data : (res.data['items'] ?? []);
    } catch (e) { _error = 'Failed to load data'; debugPrint('Load error: $e'); }
    if (mounted) setState(() => _loading = false);
  }

  Future<void> _markRead(String id) async {
    try {
      await _api.post('/me/notifications/$id/read');
      await _load();
    } catch (e) {
      debugPrint('Failed to mark notification read: $e');
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Notifications')),
      body: _loading ? const LoadingWidget()
        : _error != null ? app.AppErrorWidget(message: _error!, onRetry: _load)
        : _notifications.isEmpty ? const EmptyWidget(icon: Icons.notifications_none, title: 'No notifications', subtitle: 'You\'re all caught up!')
        : RefreshIndicator(
            onRefresh: _load,
            child: ListView.builder(
              padding: const EdgeInsets.all(16),
              itemCount: _notifications.length,
              itemBuilder: (_, i) {
                final n = _notifications[i];
                final isRead = n['readAt'] != null;
                return Card(
                  color: isRead ? null : Colors.blue.shade50,
                  margin: const EdgeInsets.only(bottom: 8),
                  child: ListTile(
                    leading: CircleAvatar(
                      backgroundColor: isRead ? Colors.grey[200] : Colors.blue[100],
                      child: Icon(Icons.notifications, size: 20, color: isRead ? Colors.grey[400] : Colors.blue),
                    ),
                    title: Text(n['announcement']?['title'] ?? 'Notification', style: TextStyle(fontWeight: isRead ? FontWeight.normal : FontWeight.w600)),
                    subtitle: Text(AppDateUtils.timeAgo(n['createdAt']), style: TextStyle(fontSize: 12, color: Colors.grey[500])),
                    onTap: isRead ? null : () => _markRead(n['id']),
                  ),
                );
              },
            ),
          ),
    );
  }
}
