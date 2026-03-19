import 'package:dio/dio.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../core/network/api_client.dart';
import '../../core/network/api_service.dart';

class AuthUser {
  final String id;
  final String email;
  final String? firstName;
  final String? lastName;
  final String? tenantId;
  final bool mustChangePassword;
  final Map<String, bool> mobileAccess;

  AuthUser({
    required this.id,
    required this.email,
    this.firstName,
    this.lastName,
    this.tenantId,
    this.mustChangePassword = false,
    this.mobileAccess = const {},
  });

  String get displayName {
    final parts = [firstName, lastName].where((p) => p != null && p.isNotEmpty);
    return parts.isNotEmpty ? parts.join(' ') : email;
  }

  String get initials {
    if (firstName != null && firstName!.isNotEmpty) {
      final l = lastName != null && lastName!.isNotEmpty ? lastName![0] : '';
      return '${firstName![0]}$l'.toUpperCase();
    }
    return email[0].toUpperCase();
  }

  factory AuthUser.fromJson(Map<String, dynamic> json, {String? tenantId}) {
    final mobileAccess = <String, bool>{};
    if (json['mobileAccess'] != null && json['mobileAccess'] is Map) {
      (json['mobileAccess'] as Map).forEach((k, v) {
        if (v is bool) mobileAccess[k.toString()] = v;
      });
    }
    return AuthUser(
      id: json['id'] ?? '',
      email: json['email'] ?? '',
      firstName: json['firstName'],
      lastName: json['lastName'],
      tenantId: tenantId,
      mustChangePassword: json['mustChangePassword'] == true,
      mobileAccess: mobileAccess,
    );
  }
}

final authStateProvider = StateNotifierProvider<AuthNotifier, AsyncValue<AuthUser?>>((ref) {
  return AuthNotifier();
});

class AuthNotifier extends StateNotifier<AsyncValue<AuthUser?>> {
  AuthNotifier() : super(const AsyncValue.data(null)) {
    _tryRestoreSession();
  }

  final _api = ApiService();
  final _client = ApiClient();

  Future<void> _tryRestoreSession() async {
    final token = await _client.getAccessToken();
    if (token == null) return;
    try {
      final res = await _api.get('/auth/me');
      final user = AuthUser.fromJson(
        res.data['user'],
        tenantId: res.data['session']?['tenantId'],
      );
      state = AsyncValue.data(AuthUser(
        id: user.id,
        email: user.email,
        firstName: user.firstName,
        lastName: user.lastName,
        tenantId: user.tenantId,
        mustChangePassword: res.data['mustChangePassword'] == true,
        mobileAccess: _parseMobileAccess(res.data['mobileAccess']),
      ));
    } catch (_) {
      await _client.clearTokens();
    }
  }

  Future<String?> login(String email, String password) async {
    state = const AsyncValue.loading();
    try {
      final deviceId = 'tenovia-mobile-${DateTime.now().millisecondsSinceEpoch}';
      final res = await ApiClient().dio.post(
        '/auth/login',
        data: {'email': email, 'password': password, 'deviceId': deviceId},
        options: Options(headers: {'Content-Type': 'application/json'}),
      );
      final tokens = res.data['tokens'];
      await _client.saveTokens(tokens['accessToken'], tokens['refreshToken'], deviceId);

      final meRes = await _api.get('/auth/me');
      final user = AuthUser.fromJson(
        meRes.data['user'],
        tenantId: meRes.data['session']?['tenantId'],
      );
      state = AsyncValue.data(AuthUser(
        id: user.id,
        email: user.email,
        firstName: user.firstName,
        lastName: user.lastName,
        tenantId: user.tenantId,
        mustChangePassword: meRes.data['mustChangePassword'] == true,
        mobileAccess: _parseMobileAccess(meRes.data['mobileAccess']),
      ));
      return null;
    } catch (e) {
      state = const AsyncValue.data(null);
      if (e is DioException && e.response != null) {
        final msg = e.response?.data?['error']?['message'];
        return msg ?? 'Login failed';
      }
      return 'Connection error. Please try again.';
    }
  }

  Future<void> logout() async {
    try { await _api.post('/auth/logout'); } catch (e) { debugPrint('Logout API call failed: $e'); }
    await _client.clearTokens();
    state = const AsyncValue.data(null);
  }

  Future<void> refreshSession() async {
    try {
      final res = await _api.get('/auth/me');
      final user = AuthUser(
        id: res.data['user']['id'] ?? '',
        email: res.data['user']['email'] ?? '',
        firstName: res.data['user']['firstName'],
        lastName: res.data['user']['lastName'],
        tenantId: res.data['session']?['tenantId'],
        mustChangePassword: res.data['mustChangePassword'] == true,
        mobileAccess: _parseMobileAccess(res.data['mobileAccess']),
      );
      state = AsyncValue.data(user);
    } catch (e) {
      debugPrint('Session refresh failed: $e');
    }
  }

  bool isModuleEnabled(String key) {
    final user = state.value;
    if (user == null) return false;
    return user.mobileAccess[key] ?? false;
  }

  static Map<String, bool> _parseMobileAccess(dynamic data) {
    final result = <String, bool>{};
    if (data is Map) {
      data.forEach((k, v) { if (v is bool) result[k.toString()] = v; });
    }
    return result;
  }
}
