import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../../core/widgets/glass_widgets.dart';
import '../../../auth/domain/auth_state.dart';
import '../../../workspace/domain/workspace_state.dart';

class DashboardShell extends ConsumerWidget {
  final Widget child;

  const DashboardShell({super.key, required this.child});

  int _currentIndex(BuildContext context) {
    final location = GoRouterState.of(context).matchedLocation;
    if (location.startsWith('/pos')) return 1;
    if (location.startsWith('/inventory')) return 2;
    if (location.startsWith('/reports')) return 3;
    if (location.startsWith('/settings')) return 4;
    return 0;
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final user = ref.watch(authStateProvider).user;
    final workspace = ref.watch(workspaceStateProvider);

    return GlassScaffold(
      appBar: GlassAppBar(
        title: Text(workspace.selectedName ?? 'SpiceDesk'),
        actions: [
          if (workspace.selectedId != null)
            IconButton(
              icon: const Icon(Icons.swap_horiz),
              tooltip: 'Switch workspace',
              onPressed: () => context.go('/workspace'),
            ),
          PopupMenuButton(
            itemBuilder: (context) => <PopupMenuEntry<void>>[
              PopupMenuItem(
                child: Text(user?.email ?? 'User'),
                enabled: false,
              ),
              const PopupMenuDivider(),
              const PopupMenuItem(
                child: Text('Made by Shahid Singh'),
                enabled: false,
              ),
              const PopupMenuDivider(),
              PopupMenuItem(
                child: const Text('Sign Out'),
                onTap: () => ref.read(authStateProvider.notifier).logout(),
              ),
            ],
          ),
        ],
      ),
      body: child,
      bottomNavigationBar: GlassBottomBar(
        currentIndex: _currentIndex(context),
        onTap: (index) {
          switch (index) {
            case 0:
              context.go('/dashboard');
            case 1:
              context.go('/pos');
            case 2:
              context.go('/inventory');
            case 3:
              context.go('/reports');
            case 4:
              context.go('/settings');
          }
        },
        items: const [
          GlassBottomBarItem(icon: Icons.dashboard_rounded, label: 'Home'),
          GlassBottomBarItem(icon: Icons.point_of_sale_rounded, label: 'POS'),
          GlassBottomBarItem(
              icon: Icons.inventory_2_rounded, label: 'Stock'),
          GlassBottomBarItem(
              icon: Icons.analytics_rounded, label: 'Reports'),
          GlassBottomBarItem(icon: Icons.settings_rounded, label: 'Settings'),
        ],
      ),
    );
  }
}
