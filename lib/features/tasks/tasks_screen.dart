import 'package:flutter/material.dart';
import '../../core/network/api_service.dart';
import '../../shared/widgets/loading_widget.dart';
import '../../shared/widgets/empty_widget.dart';
import '../../shared/widgets/error_widget.dart' as app;

class TasksScreen extends StatefulWidget {
  const TasksScreen({super.key});
  @override
  State<TasksScreen> createState() => _TasksScreenState();
}

class _TasksScreenState extends State<TasksScreen> {
  final _api = ApiService();
  List<dynamic> _tasks = [];
  bool _loading = true;
  String? _error;

  @override
  void initState() { super.initState(); _load(); }

  Future<void> _load() async {
    setState(() { _loading = true; _error = null; });
    try {
      final res = await _api.get('/me/tasks');
      final data = res.data;
      _tasks = data is List ? data : (data['items'] ?? []);
    } catch (e) { _error = 'Failed to load tasks'; debugPrint('Tasks error: $e'); }
    if (mounted) setState(() => _loading = false);
  }

  Color _statusColor(String? status) {
    switch (status?.toUpperCase()) {
      case 'COMPLETED': return Colors.green;
      case 'IN_PROGRESS': return Colors.blue;
      case 'OPEN': return Colors.orange;
      default: return Colors.grey;
    }
  }

  Color _priorityColor(String? priority) {
    switch (priority?.toUpperCase()) {
      case 'URGENT': return Colors.red;
      case 'HIGH': return Colors.orange;
      case 'MEDIUM': return Colors.blue;
      default: return Colors.grey;
    }
  }

  void _showStatusDialog(String taskId, String currentStatus) {
    final statuses = ['OPEN', 'IN_PROGRESS', 'COMPLETED'];
    showDialog(
      context: context,
      builder: (ctx) => SimpleDialog(
        title: const Text('Update Status'),
        children: statuses.map((s) => SimpleDialogOption(
          onPressed: () async {
            Navigator.pop(ctx);
            try {
              await _api.patch('/me/tasks/$taskId/status', data: {'status': s});
              await _load();
              if (mounted) ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Status updated to $s')));
            } catch (e) {
              if (mounted) ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Failed: $e'), backgroundColor: Colors.red));
            }
          },
          child: Row(children: [
            Container(width: 12, height: 12, decoration: BoxDecoration(color: _statusColor(s), shape: BoxShape.circle)),
            const SizedBox(width: 12),
            Text(s.replaceAll('_', ' '), style: TextStyle(fontWeight: s == currentStatus ? FontWeight.bold : FontWeight.normal)),
            if (s == currentStatus) ...[const Spacer(), const Icon(Icons.check, size: 18, color: Colors.green)],
          ]),
        )).toList(),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('My Tasks')),
      body: _loading ? const LoadingWidget()
        : _error != null ? app.AppErrorWidget(message: _error!, onRetry: _load)
        : _tasks.isEmpty ? const EmptyWidget(icon: Icons.check_circle_outline, title: 'No tasks assigned', subtitle: 'Tasks assigned to you will appear here')
        : RefreshIndicator(
            onRefresh: _load,
            child: ListView.separated(
              padding: const EdgeInsets.all(16),
              itemCount: _tasks.length,
              separatorBuilder: (_, __) => const SizedBox(height: 8),
              itemBuilder: (_, i) {
                final t = _tasks[i];
                final task = t['task'] ?? t;
                return Card(
                  child: ListTile(
                    contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                    title: Text(task['title'] ?? '—', style: const TextStyle(fontWeight: FontWeight.w600)),
                    subtitle: Text(task['description'] ?? '', maxLines: 2, overflow: TextOverflow.ellipsis, style: TextStyle(color: Colors.grey[600], fontSize: 13)),
                    trailing: Container(
                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                      decoration: BoxDecoration(
                        color: _statusColor(t['status']).withValues(alpha: 0.1),
                        borderRadius: BorderRadius.circular(6),
                      ),
                      child: Text(t['status'] ?? '—', style: TextStyle(color: _statusColor(t['status']), fontSize: 11, fontWeight: FontWeight.w600)),
                    ),
                    leading: Container(
                      width: 4, height: 40,
                      decoration: BoxDecoration(color: _priorityColor(task['priority']), borderRadius: BorderRadius.circular(2)),
                    ),
                    onTap: () => _showStatusDialog(task['id'] ?? t['taskId'], t['status'] ?? ''),
                  ),
                );
              },
            ),
          ),
    );
  }
}
