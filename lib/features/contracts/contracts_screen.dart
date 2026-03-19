import 'package:flutter/material.dart';
import '../../core/network/api_service.dart';
import '../../core/utils/date_utils.dart';
import '../../shared/widgets/loading_widget.dart';
import '../../shared/widgets/empty_widget.dart';
import '../../shared/widgets/error_widget.dart' as app;

class ContractsScreen extends StatefulWidget {
  const ContractsScreen({super.key});
  @override
  State<ContractsScreen> createState() => _ContractsScreenState();
}

class _ContractsScreenState extends State<ContractsScreen> {
  final _api = ApiService();
  List<dynamic> _contracts = [];
  bool _loading = true;
  String? _error;

  @override
  void initState() { super.initState(); _load(); }

  Future<void> _load() async {
    setState(() { _loading = true; _error = null; });
    try {
      final res = await _api.get('/me/contracts');
      _contracts = res.data is List ? res.data : (res.data['items'] ?? []);
    } catch (e) { _error = 'Failed to load data'; debugPrint('Load error: $e'); }
    if (mounted) setState(() => _loading = false);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('My Contracts')),
      body: _loading ? const LoadingWidget()
        : _error != null ? app.AppErrorWidget(message: _error!, onRetry: _load)
        : _contracts.isEmpty ? const EmptyWidget(icon: Icons.description_outlined, title: 'No contracts', subtitle: 'Your employment contracts will appear here')
        : RefreshIndicator(
            onRefresh: _load,
            child: ListView.builder(
              padding: const EdgeInsets.all(16),
              itemCount: _contracts.length,
              itemBuilder: (_, i) {
                final c = _contracts[i];
                return Card(
                  margin: const EdgeInsets.only(bottom: 8),
                  child: ListTile(
                    leading: Container(
                      width: 44, height: 44,
                      decoration: BoxDecoration(color: Colors.teal.withValues(alpha: 0.1), borderRadius: BorderRadius.circular(10)),
                      child: const Icon(Icons.description, color: Colors.teal),
                    ),
                    title: Text(c['title'] ?? 'Contract', style: const TextStyle(fontWeight: FontWeight.w600)),
                    subtitle: Text('${c['type'] ?? ''} · ${AppDateUtils.formatDate(c['effectiveFrom'])} → ${AppDateUtils.formatDate(c['effectiveTo'])}', style: TextStyle(fontSize: 12, color: Colors.grey[600])),
                    trailing: Text(c['status'] ?? '', style: TextStyle(fontSize: 11, color: Colors.grey[600], fontWeight: FontWeight.w600)),
                  ),
                );
              },
            ),
          ),
    );
  }
}
