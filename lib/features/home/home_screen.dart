import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../auth/auth_provider.dart';
import '../../core/network/api_service.dart';

class HomeScreen extends ConsumerStatefulWidget {
  const HomeScreen({super.key});
  @override
  ConsumerState<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends ConsumerState<HomeScreen> {
  final _api = ApiService();
  Map<String, dynamic>? _attendance;
  bool _loading = true;

  @override
  void initState() {
    super.initState();
    _loadData();
  }

  Future<void> _loadData() async {
    setState(() => _loading = true);
    try {
      final res = await _api.get('/me/attendance/today');
      _attendance = res.data;
    } catch (e) {
      debugPrint('Failed to load attendance: $e');
    }
    if (mounted) setState(() => _loading = false);
  }

  @override
  Widget build(BuildContext context) {
    final user = ref.watch(authStateProvider).value;
    return Scaffold(
      appBar: AppBar(
        title: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Welcome back 👋', style: TextStyle(fontSize: 13, color: Colors.grey[500])),
            Text(user?.displayName ?? 'Employee', style: const TextStyle(fontSize: 17, fontWeight: FontWeight.w600)),
          ],
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.notifications_outlined),
            onPressed: () => context.push('/notifications'),
          ),
        ],
      ),
      body: RefreshIndicator(
        onRefresh: _loadData,
        child: ListView(
          padding: const EdgeInsets.all(16),
          children: [
            _buildAttendanceCard(),
            const SizedBox(height: 20),
            _buildQuickActions(context),
            const SizedBox(height: 20),
            _buildMenuGrid(context),
          ],
        ),
      ),
    );
  }

  Widget _buildAttendanceCard() {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                const Icon(Icons.access_time, color: Color(0xFF0B6B4C)),
                const SizedBox(width: 8),
                const Text('Today\'s Attendance', style: TextStyle(fontSize: 15, fontWeight: FontWeight.w600)),
              ],
            ),
            const SizedBox(height: 16),
            if (_loading)
              const Center(child: SizedBox(width: 24, height: 24, child: CircularProgressIndicator(strokeWidth: 2)))
            else if (_attendance == null)
              Text('Unable to load attendance', style: TextStyle(color: Colors.grey[500], fontSize: 13))
            else ...[
              Text(
                _attendance?['event']?['checkInAt'] != null ? 'Checked in' : 'Not checked in',
                style: TextStyle(fontSize: 14, color: _attendance?['event']?['checkInAt'] != null ? const Color(0xFF0B6B4C) : Colors.orange),
              ),
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildQuickActions(BuildContext context) {
    final auth = ref.read(authStateProvider.notifier);
    final actions = <Widget>[];
    if (auth.isModuleEnabled('attendanceEnabled')) {
      actions.add(Expanded(
        child: _ActionButton(icon: Icons.login, label: 'Check In', color: const Color(0xFF0B6B4C), onTap: () => context.go('/attendance')),
      ));
    }
    if (auth.isModuleEnabled('leaveRequestsEnabled')) {
      if (actions.isNotEmpty) actions.add(const SizedBox(width: 12));
      actions.add(Expanded(
        child: _ActionButton(icon: Icons.calendar_today, label: 'Request Leave', color: Colors.blue, onTap: () => context.go('/leaves')),
      ));
    }
    if (actions.isEmpty) return const SizedBox.shrink();
    return Row(children: actions);
  }

  Widget _buildMenuGrid(BuildContext context) {
    final auth = ref.read(authStateProvider.notifier);
    final allItems = [
      if (auth.isModuleEnabled('tasksEnabled'))
        _MenuItem(Icons.check_circle_outline, 'Tasks', '/tasks', Colors.purple),
      if (auth.isModuleEnabled('payslipsEnabled'))
        _MenuItem(Icons.receipt_long, 'Payslips', '/payslips', Colors.orange),
      if (auth.isModuleEnabled('contractsEnabled'))
        _MenuItem(Icons.description_outlined, 'Contracts', '/contracts', Colors.teal),
      if (auth.isModuleEnabled('notificationsEnabled'))
        _MenuItem(Icons.notifications_outlined, 'Notifications', '/notifications', Colors.pink),
    ];
    final items = allItems;
    return GridView.count(
      crossAxisCount: 2,
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      mainAxisSpacing: 12,
      crossAxisSpacing: 12,
      childAspectRatio: 1.4,
      children: items.map((item) => _MenuCard(item: item, onTap: () => context.push(item.route))).toList(),
    );
  }
}

class _MenuItem {
  final IconData icon;
  final String label;
  final String route;
  final Color color;
  _MenuItem(this.icon, this.label, this.route, this.color);
}

class _ActionButton extends StatelessWidget {
  final IconData icon;
  final String label;
  final Color color;
  final VoidCallback onTap;
  const _ActionButton({required this.icon, required this.label, required this.color, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return Material(
      color: color,
      borderRadius: BorderRadius.circular(14),
      child: InkWell(
        borderRadius: BorderRadius.circular(14),
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsets.symmetric(vertical: 16),
          child: Column(
            children: [
              Icon(icon, color: Colors.white, size: 26),
              const SizedBox(height: 6),
              Text(label, style: const TextStyle(color: Colors.white, fontWeight: FontWeight.w600, fontSize: 13)),
            ],
          ),
        ),
      ),
    );
  }
}

class _MenuCard extends StatelessWidget {
  final _MenuItem item;
  final VoidCallback onTap;
  const _MenuCard({required this.item, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return Card(
      child: InkWell(
        borderRadius: BorderRadius.circular(16),
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(color: item.color.withValues(alpha: 0.1), borderRadius: BorderRadius.circular(10)),
                child: Icon(item.icon, color: item.color, size: 22),
              ),
              const SizedBox(height: 10),
              Text(item.label, style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 14)),
            ],
          ),
        ),
      ),
    );
  }
}
