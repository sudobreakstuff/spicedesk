import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../features/auth/presentation/screens/login_screen.dart';
import '../../features/auth/presentation/screens/register_screen.dart';
import '../../features/dashboard/presentation/screens/home_screen.dart';
import '../../features/pos/presentation/screens/pos_screen.dart';
import '../../features/inventory/presentation/screens/inventory_screen.dart';
import '../../features/reports/presentation/screens/reports_screen.dart';
import '../../features/settings/presentation/screens/settings_screen.dart';
import '../../features/settings/presentation/screens/printer_connect_screen.dart';
import '../../features/workspace/presentation/screens/workspace_screen.dart';
import '../../features/customers/presentation/screens/customers_screen.dart';
import '../../features/marketing/presentation/screens/marketing_screen.dart';
import '../../core/widgets/app_sidebar.dart';

final appRouterProvider = Provider<GoRouter>((ref) {
  return GoRouter(
    initialLocation: '/dashboard',
    routes: [
      GoRoute(path: '/login', builder: (_, __) => const LoginScreen()),
      GoRoute(path: '/register', builder: (_, __) => const RegisterScreen()),
      GoRoute(path: '/workspace', builder: (_, __) => const WorkspaceScreen()),
      GoRoute(
          path: '/printer-connect',
          builder: (_, __) => const PrinterConnectScreen()),
      ShellRoute(
        builder: (_, __, child) => Row(
          children: [
            const AppSidebar(),
            Expanded(child: child),
          ],
        ),
        routes: [
          GoRoute(
              path: '/dashboard',
              builder: (_, __) => const HomeScreen()),
          GoRoute(path: '/pos', builder: (_, __) => const PosScreen()),
          GoRoute(
              path: '/inventory',
              builder: (_, __) => const InventoryScreen()),
          GoRoute(
              path: '/reports',
              builder: (_, __) => const ReportsScreen()),
          GoRoute(
              path: '/settings',
              builder: (_, __) => const SettingsScreen()),
          GoRoute(
              path: '/customers',
              builder: (_, __) => const CustomersScreen()),
          GoRoute(
              path: '/marketing',
              builder: (_, __) => const MarketingScreen()),
        ],
      ),
    ],
  );
});
