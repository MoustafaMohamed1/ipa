import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../features/auth/auth_provider.dart';

class AppShell extends ConsumerWidget {
  final Widget child;
  const AppShell({super.key, required this.child});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final user = ref.watch(authStateProvider).value;
    final access = user?.mobileAccess ?? {};

    final destinations = <NavigationDestination>[
      const NavigationDestination(icon: Icon(Icons.home_outlined), selectedIcon: Icon(Icons.home), label: 'Home'),
    ];
    final routes = <String>['/'];

    if (access['attendanceEnabled'] != false) {
      destinations.add(const NavigationDestination(icon: Icon(Icons.fingerprint_outlined), selectedIcon: Icon(Icons.fingerprint), label: 'Attendance'));
      routes.add('/attendance');
    }
    if (access['tasksEnabled'] != false) {
      destinations.add(const NavigationDestination(icon: Icon(Icons.check_circle_outline), selectedIcon: Icon(Icons.check_circle), label: 'Tasks'));
      routes.add('/tasks');
    }
    if (access['leaveRequestsEnabled'] != false) {
      destinations.add(const NavigationDestination(icon: Icon(Icons.calendar_today_outlined), selectedIcon: Icon(Icons.calendar_today), label: 'Leaves'));
      routes.add('/leaves');
    }
    destinations.add(const NavigationDestination(icon: Icon(Icons.person_outline), selectedIcon: Icon(Icons.person), label: 'Profile'));
    routes.add('/profile');

    int currentIndex = 0;
    final loc = GoRouterState.of(context).matchedLocation;
    for (int i = 0; i < routes.length; i++) {
      if (routes[i] == '/' ? loc == '/' : loc.startsWith(routes[i])) {
        currentIndex = i;
        break;
      }
    }

    return Scaffold(
      body: child,
      bottomNavigationBar: NavigationBar(
        selectedIndex: currentIndex,
        onDestinationSelected: (i) => context.go(routes[i]),
        destinations: destinations,
      ),
    );
  }
}
