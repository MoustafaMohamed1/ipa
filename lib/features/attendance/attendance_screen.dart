import 'package:flutter/material.dart';
import '../../core/network/api_service.dart';
import '../../core/utils/date_utils.dart';

class AttendanceScreen extends StatefulWidget {
  const AttendanceScreen({super.key});
  @override
  State<AttendanceScreen> createState() => _AttendanceScreenState();
}

class _AttendanceScreenState extends State<AttendanceScreen> {
  final _api = ApiService();
  Map<String, dynamic>? _data;
  bool _loading = true;
  bool _actionLoading = false;
  String? _error;

  @override
  void initState() { super.initState(); _load(); }

  Future<void> _load() async {
    setState(() { _loading = true; _error = null; });
    try {
      final res = await _api.get('/me/attendance/today');
      _data = res.data;
    } catch (e) { _error = 'Failed to load attendance'; }
    if (mounted) setState(() => _loading = false);
  }

  Future<void> _checkIn() async {
    setState(() => _actionLoading = true);
    try {
      await _api.post('/me/attendance/check-in', data: {'method': 'gps'});
      await _load();
    } catch (e) {
      if (mounted) ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Check-in failed'), backgroundColor: Colors.red));
    }
    if (mounted) setState(() => _actionLoading = false);
  }

  Future<void> _checkOut() async {
    setState(() => _actionLoading = true);
    try {
      await _api.post('/me/attendance/check-out', data: {'method': 'gps'});
      await _load();
    } catch (e) {
      if (mounted) ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Check-out failed'), backgroundColor: Colors.red));
    }
    if (mounted) setState(() => _actionLoading = false);
  }

  @override
  Widget build(BuildContext context) {
    final event = _data?['event'] ?? _data?['openEvent'];
    final checkedIn = event?['checkInAt'] != null;
    final checkedOut = event?['checkOutAt'] != null;

    return Scaffold(
      appBar: AppBar(title: const Text('Attendance')),
      body: _loading
        ? const Center(child: CircularProgressIndicator())
        : _error != null
          ? Center(child: Column(mainAxisSize: MainAxisSize.min, children: [
              Text(_error!, style: TextStyle(color: Colors.grey[600])),
              TextButton(onPressed: _load, child: const Text('Retry')),
            ]))
          : RefreshIndicator(
              onRefresh: _load,
              child: ListView(
                padding: const EdgeInsets.all(16),
                children: [
                  Card(
                    child: Padding(
                      padding: const EdgeInsets.all(24),
                      child: Column(
                        children: [
                          Icon(
                            checkedIn ? Icons.check_circle : Icons.radio_button_unchecked,
                            size: 64,
                            color: checkedIn ? const Color(0xFF0B6B4C) : Colors.grey[300],
                          ),
                          const SizedBox(height: 16),
                          Text(
                            checkedOut ? 'Checked Out' : checkedIn ? 'Checked In' : 'Not Checked In',
                            style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
                          ),
                          if (checkedIn) ...[
                            const SizedBox(height: 8),
                            Text('Check-in: ${AppDateUtils.formatTime(event?['checkInAt'])}', style: TextStyle(color: Colors.grey[600])),
                          ],
                          if (checkedOut) ...[
                            const SizedBox(height: 4),
                            Text('Check-out: ${AppDateUtils.formatTime(event?['checkOutAt'])}', style: TextStyle(color: Colors.grey[600])),
                          ],
                          const SizedBox(height: 24),
                          if (!checkedOut)
                            SizedBox(
                              width: double.infinity,
                              child: ElevatedButton.icon(
                                onPressed: _actionLoading ? null : (checkedIn ? _checkOut : _checkIn),
                                icon: Icon(checkedIn ? Icons.logout : Icons.login),
                                label: Text(_actionLoading ? 'Processing...' : checkedIn ? 'Check Out' : 'Check In'),
                              ),
                            ),
                        ],
                      ),
                    ),
                  ),
                ],
              ),
            ),
    );
  }
}
