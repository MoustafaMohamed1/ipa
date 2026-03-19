import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:dio/dio.dart';
import '../../core/network/api_service.dart';
import 'auth_provider.dart';

class ChangePasswordScreen extends ConsumerStatefulWidget {
  const ChangePasswordScreen({super.key});
  @override
  ConsumerState<ChangePasswordScreen> createState() => _ChangePasswordScreenState();
}

class _ChangePasswordScreenState extends ConsumerState<ChangePasswordScreen> {
  final _currentCtrl = TextEditingController();
  final _newCtrl = TextEditingController();
  final _confirmCtrl = TextEditingController();
  bool _loading = false;
  String? _error;

  String _toUserMessage(Object error) {
    if (error is DioException) {
      final payload = error.response?.data;
      if (payload is Map<String, dynamic>) {
        final nestedError = payload['error'];
        if (nestedError is Map<String, dynamic>) {
          final message = nestedError['message'];
          if (message is String && message.trim().isNotEmpty) {
            return message;
          }
        }

        final message = payload['message'];
        if (message is String && message.trim().isNotEmpty) {
          return message;
        }
      }
    }

    return 'Unable to change password. Please try again.';
  }

  Future<void> _submit() async {
    if (_newCtrl.text.length < 8) {
      setState(() => _error = 'Password must be at least 8 characters');
      return;
    }
    if (_newCtrl.text != _confirmCtrl.text) {
      setState(() => _error = 'Passwords do not match');
      return;
    }
    setState(() { _loading = true; _error = null; });
    try {
      await ApiService().post('/auth/change-initial-password', data: {
        'currentPassword': _currentCtrl.text,
        'newPassword': _newCtrl.text,
      });
      await ref.read(authStateProvider.notifier).refreshSession();
    } catch (e) {
      setState(() => _error = _toUserMessage(e));
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SafeArea(
        child: Center(
          child: SingleChildScrollView(
            padding: const EdgeInsets.all(24),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                const Icon(Icons.lock_reset, size: 56, color: Color(0xFF0B6B4C)),
                const SizedBox(height: 16),
                const Text('Change Your Password', style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold)),
                const SizedBox(height: 8),
                Text('You must change your temporary password before continuing.', textAlign: TextAlign.center, style: TextStyle(color: Colors.grey[600], fontSize: 14)),
                const SizedBox(height: 32),
                TextField(controller: _currentCtrl, obscureText: true, decoration: const InputDecoration(labelText: 'Current Password', prefixIcon: Icon(Icons.lock_outline))),
                const SizedBox(height: 16),
                TextField(controller: _newCtrl, obscureText: true, decoration: const InputDecoration(labelText: 'New Password', prefixIcon: Icon(Icons.lock))),
                const SizedBox(height: 16),
                TextField(controller: _confirmCtrl, obscureText: true, decoration: const InputDecoration(labelText: 'Confirm New Password', prefixIcon: Icon(Icons.lock))),
                if (_error != null) ...[
                  const SizedBox(height: 12),
                  Container(
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(color: Colors.red[50], borderRadius: BorderRadius.circular(8)),
                    child: Row(children: [
                      Icon(Icons.error_outline, color: Colors.red[700], size: 18),
                      const SizedBox(width: 8),
                      Expanded(child: Text(_error!, style: TextStyle(color: Colors.red[700], fontSize: 13))),
                    ]),
                  ),
                ],
                const SizedBox(height: 24),
                ElevatedButton(
                  onPressed: _loading ? null : _submit,
                  child: _loading
                    ? const SizedBox(width: 20, height: 20, child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white))
                    : const Text('Change Password'),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
