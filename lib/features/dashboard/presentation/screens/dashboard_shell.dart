import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../../core/widgets/glass_widgets.dart';
import '../../../../core/theme/app_theme.dart';
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
    final displayName =
        user?.userMetadata?['name'] as String? ?? user?.email ?? 'User';
    final initials = _initials(displayName);

    return GlassScaffold(
      appBar: GlassAppBar(
        leading: Padding(
          padding: const EdgeInsets.only(left: 12),
          child: PopupMenuButton<String>(
            offset: const Offset(0, 48),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(16),
            ),
            color: SpiceColors.surfaceAlt,
            itemBuilder: (ctx) => [
              PopupMenuItem(
                enabled: false,
                height: 56,
                child: Row(
                  children: [
                    Container(
                      width: 40,
                      height: 40,
                      decoration: BoxDecoration(
                        gradient: const LinearGradient(
                          colors: [SpiceColors.primary, Color(0xFFA78BFA)],
                          begin: Alignment.topLeft,
                          end: Alignment.bottomRight,
                        ),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      alignment: Alignment.center,
                      child: Text(
                        initials,
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 15,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            displayName,
                            style: const TextStyle(
                              color: SpiceColors.textPrimary,
                              fontWeight: FontWeight.w600,
                              fontSize: 14,
                            ),
                            overflow: TextOverflow.ellipsis,
                          ),
                          const SizedBox(height: 2),
                          Text(
                            user?.email ?? '',
                            style: const TextStyle(
                              color: SpiceColors.textSecondary,
                              fontSize: 12,
                            ),
                            overflow: TextOverflow.ellipsis,
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
              const PopupMenuDivider(height: 1),
              const PopupMenuItem(
                enabled: false,
                height: 32,
                child: Text(
                  'Made by Shahid Singh',
                  style: TextStyle(
                    color: SpiceColors.textSecondary,
                    fontSize: 11,
                  ),
                ),
              ),
              const PopupMenuDivider(height: 1),
              PopupMenuItem(
                value: 'signout',
                child: const Row(
                  children: [
                    Icon(Icons.logout_rounded,
                        color: SpiceColors.danger, size: 18),
                    SizedBox(width: 10),
                    Text('Sign Out',
                        style: TextStyle(color: SpiceColors.danger)),
                  ],
                ),
                onTap: () => ref.read(authStateProvider.notifier).logout(),
              ),
            ],
            child: Container(
              width: 38,
              height: 38,
              decoration: BoxDecoration(
                gradient: const LinearGradient(
                  colors: [SpiceColors.primary, Color(0xFFA78BFA)],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                ),
                borderRadius: BorderRadius.circular(12),
              ),
              alignment: Alignment.center,
              child: Text(
                initials,
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 14,
                  fontWeight: FontWeight.w700,
                ),
              ),
            ),
          ),
        ),
        title: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(workspace.selectedName ?? 'SpiceDesk'),
            if (workspace.selectedId != null) ...[
              const SizedBox(width: 8),
              Container(
                padding: const EdgeInsets.symmetric(
                    horizontal: 8, vertical: 3),
                decoration: BoxDecoration(
                  color: SpiceColors.accent.withAlpha(25),
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(
                    color: SpiceColors.accent.withAlpha(60),
                    width: 0.5,
                  ),
                ),
                child: const Text(
                  'ACTIVE',
                  style: TextStyle(
                    color: SpiceColors.accent,
                    fontSize: 9,
                    fontWeight: FontWeight.w700,
                    letterSpacing: 1.2,
                  ),
                ),
              ),
            ],
          ],
        ),
        actions: [
          if (workspace.selectedId != null)
            IconButton(
              icon: const Icon(Icons.swap_horiz),
              tooltip: 'Switch workspace',
              onPressed: () => context.go('/workspace'),
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

  String _initials(String name) {
    final parts = name.trim().split(RegExp(r'\s+'));
    if (parts.length >= 2) {
      return '${parts[0][0]}${parts[1][0]}'.toUpperCase();
    }
    return name.isNotEmpty ? name[0].toUpperCase() : '?';
  }
}
