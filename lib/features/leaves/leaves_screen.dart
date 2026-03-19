import 'package:flutter/material.dart';
import '../../core/network/api_service.dart';
import '../../core/utils/date_utils.dart';
import '../../shared/widgets/loading_widget.dart';
import '../../shared/widgets/empty_widget.dart';
import '../../shared/widgets/error_widget.dart' as app;

class LeavesScreen extends StatefulWidget {
  const LeavesScreen({super.key});
  @override
  State<LeavesScreen> createState() => _LeavesScreenState();
}

class _LeavesScreenState extends State<LeavesScreen> with SingleTickerProviderStateMixin {
  late TabController _tabCtrl;
  final _api = ApiService();
  List<dynamic> _requests = [];
  List<dynamic> _balances = [];
  bool _loading = true;
  String? _error;

  @override
  void initState() {
    super.initState();
    _tabCtrl = TabController(length: 2, vsync: this);
    _load();
  }

  Future<void> _load() async {
    setState(() { _loading = true; _error = null; });
    try {
      final reqs = await _api.get('/me/leaves/requests');
      final bals = await _api.get('/me/leaves/balance');
      _requests = reqs.data is List ? reqs.data : (reqs.data['items'] ?? []);
      _balances = bals.data is List ? bals.data : (bals.data['items'] ?? []);
    } catch (e) { _error = 'Failed to load data'; debugPrint('Load error: $e'); }
    if (mounted) setState(() => _loading = false);
  }

  String _leaveTypeName(String? typeId) {
    if (typeId == null) return 'Leave';
    final match = _balances.where((b) => b['leaveTypeId'] == typeId);
    return match.isNotEmpty ? (match.first['name'] ?? 'Leave') : 'Leave';
  }

  void _showRequestDialog() {
    final startCtrl = TextEditingController();
    final endCtrl = TextEditingController();
    final reasonCtrl = TextEditingController();
    String? selectedType = _balances.isNotEmpty ? _balances[0]['leaveTypeId'] : null;

    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Request Leave'),
        content: SingleChildScrollView(
          child: Column(mainAxisSize: MainAxisSize.min, children: [
            if (_balances.isNotEmpty) DropdownButtonFormField<String>(
              initialValue: selectedType,
              decoration: const InputDecoration(labelText: 'Leave Type'),
              items: _balances.map<DropdownMenuItem<String>>((b) =>
                DropdownMenuItem(value: b['leaveTypeId'] as String?, child: Text(b['name'] ?? '—'))).toList(),
              onChanged: (v) => selectedType = v,
            ),
            const SizedBox(height: 12),
            TextField(controller: startCtrl, decoration: const InputDecoration(labelText: 'Start (YYYY-MM-DD)')),
            const SizedBox(height: 12),
            TextField(controller: endCtrl, decoration: const InputDecoration(labelText: 'End (YYYY-MM-DD)')),
            const SizedBox(height: 12),
            TextField(controller: reasonCtrl, decoration: const InputDecoration(labelText: 'Reason'), maxLines: 2),
          ]),
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('Cancel')),
          FilledButton(
            onPressed: () async {
              if (startCtrl.text.isEmpty || endCtrl.text.isEmpty) return;
              Navigator.pop(ctx);
              try {
                await _api.post('/me/leaves/request', data: {
                  'leaveTypeId': selectedType,
                  'fromDate': startCtrl.text,
                  'toDate': endCtrl.text,
                });
                await _load();
                if (mounted) ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Leave request submitted')));
              } catch (e) {
                if (mounted) ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Failed: $e'), backgroundColor: Colors.red));
              }
            },
            child: const Text('Submit'),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Leaves'),
        bottom: TabBar(controller: _tabCtrl, tabs: const [Tab(text: 'My Requests'), Tab(text: 'Balances')]),
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => _showRequestDialog(),
        icon: const Icon(Icons.add),
        label: const Text('Request Leave'),
      ),
      body: _loading ? const LoadingWidget()
        : _error != null ? app.AppErrorWidget(message: _error!, onRetry: _load)
        : TabBarView(
        controller: _tabCtrl,
        children: [
          _requests.isEmpty
            ? const EmptyWidget(icon: Icons.calendar_today, title: 'No leave requests')
            : RefreshIndicator(
                onRefresh: _load,
                child: ListView.builder(
                  padding: const EdgeInsets.all(16),
                  itemCount: _requests.length,
                  itemBuilder: (_, i) {
                    final r = _requests[i];
                    return Card(
                      margin: const EdgeInsets.only(bottom: 8),
                      child: ListTile(
                        title: Text('${_leaveTypeName(r['leaveTypeId'])} — ${r['days']} days'),
                        subtitle: Text('${AppDateUtils.formatDate(r['fromDate'])} → ${AppDateUtils.formatDate(r['toDate'])}'),
                        trailing: _StatusChip(r['status'] ?? ''),
                      ),
                    );
                  },
                ),
              ),
          _balances.isEmpty
            ? const EmptyWidget(icon: Icons.account_balance, title: 'No balance data')
            : RefreshIndicator(
                onRefresh: _load,
                child: ListView.builder(
                  padding: const EdgeInsets.all(16),
                  itemCount: _balances.length,
                  itemBuilder: (_, i) {
                    final b = _balances[i];
                    return Card(
                      margin: const EdgeInsets.only(bottom: 8),
                      child: ListTile(
                        title: Text(b['name'] ?? 'Leave Type'),
                        trailing: Text('${b['balanceDays'] ?? 0} days', style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
                      ),
                    );
                  },
                ),
              ),
        ],
      ),
    );
  }
}

class _StatusChip extends StatelessWidget {
  final String status;
  const _StatusChip(this.status);

  Color get _color {
    switch (status.toUpperCase()) {
      case 'APPROVED': return Colors.green;
      case 'REJECTED': return Colors.red;
      case 'PENDING': return Colors.orange;
      default: return Colors.grey;
    }
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(color: _color.withValues(alpha: 0.1), borderRadius: BorderRadius.circular(6)),
      child: Text(status, style: TextStyle(color: _color, fontSize: 11, fontWeight: FontWeight.w600)),
    );
  }
}
