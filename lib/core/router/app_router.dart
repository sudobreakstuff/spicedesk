import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../features/auth/domain/auth_state.dart';
import '../../features/auth/presentation/screens/login_screen.dart';
import '../../features/workspace/domain/workspace_state.dart';
import '../../features/auth/presentation/screens/register_screen.dart';
import '../../features/dashboard/presentation/screens/home_screen.dart';
import '../../features/pos/presentation/screens/pos_screen.dart';
import '../../features/inventory/presentation/screens/inventory_screen.dart';
import '../../features/reports/presentation/screens/reports_screen.dart';
import '../../features/pending/presentation/screens/pending_screen.dart';
import '../../features/settings/presentation/screens/settings_screen.dart';
import '../../features/customers/presentation/screens/customers_screen.dart';
import '../../features/expenses/presentation/screens/expenses_screen.dart';
import '../../features/about/presentation/screens/about_screen.dart';
import '../../core/widgets/responsive_shell.dart';
import '../../features/workspace/presentation/screens/workspace_screen.dart';

final appRouterProvider = Provider<GoRouter>((ref) {
  final authState = ref.watch(authStateProvider);
  final workspaceState = ref.watch(workspaceStateProvider);

  return GoRouter(
    initialLocation: '/dashboard',
    redirect: (context, state) {
      final isLoggedIn = authState.isAuthenticated;
      final isAuthRoute =
          state.uri.path == '/login' || state.uri.path == '/register';
      final isWorkspaceRoute = state.uri.path == '/workspace';

      if (!isLoggedIn && !isAuthRoute) return '/login';
      if (isLoggedIn && isAuthRoute) return '/dashboard';
      if (isLoggedIn && !isWorkspaceRoute && workspaceState.selectedId == null) {
        return '/workspace';
      }
      return null;
    },
    routes: [
      GoRoute(path: '/login', builder: (_, __) => LoginScreen()),
      GoRoute(path: '/register', builder: (_, __) => RegisterScreen()),
      GoRoute(path: '/workspace', builder: (_, __) => WorkspaceScreen()),
      ShellRoute(
        builder: (_, __, child) => ResponsiveShell(child: child),
        routes: [
          GoRoute(
              path: '/dashboard',
              builder: (_, __) => HomeScreen()),
          GoRoute(path: '/pos', builder: (_, __) => PosScreen()),
          GoRoute(
              path: '/inventory',
              builder: (_, __) => InventoryScreen()),
          GoRoute(
              path: '/reports',
              builder: (_, __) => ReportsScreen()),
          GoRoute(
              path: '/pending',
              builder: (_, __) => PendingOrdersScreen()),
          GoRoute(
              path: '/settings',
              builder: (_, __) => SettingsScreen()),
          GoRoute(
              path: '/customers',
              builder: (_, __) => CustomersScreen()),
          GoRoute(
              path: '/expenses',
              builder: (_, __) => ExpensesScreen()),
          GoRoute(
              path: '/about',
              builder: (_, __) => AboutScreen()),
        ],
      ),
    ],
  );
});
