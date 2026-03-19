import 'package:flutter/material.dart';
import '../../core/network/api_service.dart';
import '../../core/utils/date_utils.dart';
import '../../shared/widgets/loading_widget.dart';
import '../../shared/widgets/empty_widget.dart';
import '../../shared/widgets/error_widget.dart' as app;

class PayslipsScreen extends StatefulWidget {
  const PayslipsScreen({super.key});
  @override
  State<PayslipsScreen> createState() => _PayslipsScreenState();
}

class _PayslipsScreenState extends State<PayslipsScreen> {
  final _api = ApiService();
  List<dynamic> _payslips = [];
  bool _loading = true;
  String? _error;

  @override
  void initState() { super.initState(); _load(); }

  Future<void> _load() async {
    setState(() { _loading = true; _error = null; });
    try {
      final res = await _api.get('/me/payslips');
      _payslips = res.data is List ? res.data : (res.data['items'] ?? []);
    } catch (e) { _error = 'Failed to load data'; debugPrint('Load error: $e'); }
    if (mounted) setState(() => _loading = false);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Payslips')),
      body: _loading ? const LoadingWidget()
        : _error != null ? app.AppErrorWidget(message: _error!, onRetry: _load)
        : _payslips.isEmpty ? const EmptyWidget(icon: Icons.receipt_long, title: 'No payslips', subtitle: 'Your payslips will appear here')
        : RefreshIndicator(
            onRefresh: _load,
            child: ListView.builder(
              padding: const EdgeInsets.all(16),
              itemCount: _payslips.length,
              itemBuilder: (_, i) {
                final p = _payslips[i];
                return Card(
                  margin: const EdgeInsets.only(bottom: 8),
                  child: ListTile(
                    leading: Container(
                      width: 44, height: 44,
                      decoration: BoxDecoration(color: Colors.green.withValues(alpha: 0.1), borderRadius: BorderRadius.circular(10)),
                      child: const Icon(Icons.receipt_long, color: Colors.green),
                    ),
                    title: Text('${p['currency'] ?? 'SAR'} ${p['netAmount'] ?? '0.00'}', style: const TextStyle(fontWeight: FontWeight.bold)),
                    subtitle: Text(AppDateUtils.formatDate(p['createdAt'])),
                    trailing: _StatusBadge(p['status'] ?? ''),
                  ),
                );
              },
            ),
          ),
    );
  }
}

class _StatusBadge extends StatelessWidget {
  final String status;
  const _StatusBadge(this.status);

  @override
  Widget build(BuildContext context) {
    final color = status.toUpperCase() == 'PUBLISHED' ? Colors.green : Colors.grey;
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(color: color.withValues(alpha: 0.1), borderRadius: BorderRadius.circular(6)),
      child: Text(status, style: TextStyle(color: color, fontSize: 11, fontWeight: FontWeight.w600)),
    );
  }
}
