import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../features/auth/login_screen.dart';
import '../../features/auth/change_password_screen.dart';
import '../../features/home/home_screen.dart';
import '../../features/attendance/attendance_screen.dart';
import '../../features/tasks/tasks_screen.dart';
import '../../features/leaves/leaves_screen.dart';
import '../../features/payroll/payslips_screen.dart';
import '../../features/contracts/contracts_screen.dart';
import '../../features/notifications/notifications_screen.dart';
import '../../features/profile/profile_screen.dart';
import '../../features/auth/auth_provider.dart';
import '../../shared/widgets/app_shell.dart';

final routerProvider = Provider<GoRouter>((ref) {
  final authState = ref.watch(authStateProvider);

  return GoRouter(
    initialLocation: '/login',
    redirect: (context, state) {
      final authUser = authState.value;
      final isLoggedIn = authUser != null;
      final isLoginRoute = state.matchedLocation == '/login';
      final isChangePasswordRoute = state.matchedLocation == '/change-password';

      if (!isLoggedIn && !isLoginRoute) return '/login';
      if (isLoggedIn && isLoginRoute) return authUser.mustChangePassword ? '/change-password' : '/';
      if (isLoggedIn && authUser.mustChangePassword && !isChangePasswordRoute) return '/change-password';
      if (isLoggedIn && !authUser.mustChangePassword && isChangePasswordRoute) return '/';
      return null;
    },
    routes: [
      GoRoute(path: '/login', builder: (_, __) => const LoginScreen()),
      GoRoute(path: '/change-password', builder: (_, __) => const ChangePasswordScreen()),
      ShellRoute(
        builder: (_, __, child) => AppShell(child: child),
        routes: [
          GoRoute(path: '/', builder: (_, __) => const HomeScreen()),
          GoRoute(path: '/attendance', builder: (_, __) => const AttendanceScreen()),
          GoRoute(path: '/tasks', builder: (_, __) => const TasksScreen()),
          GoRoute(path: '/leaves', builder: (_, __) => const LeavesScreen()),
          GoRoute(path: '/payslips', builder: (_, __) => const PayslipsScreen()),
          GoRoute(path: '/contracts', builder: (_, __) => const ContractsScreen()),
          GoRoute(path: '/notifications', builder: (_, __) => const NotificationsScreen()),
          GoRoute(path: '/profile', builder: (_, __) => const ProfileScreen()),
        ],
      ),
    ],
  );
});
