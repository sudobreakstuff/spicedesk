import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../features/auth/domain/auth_state.dart';
import '../../features/workspace/domain/workspace_state.dart';
import '../theme/app_theme.dart';

class AppSidebar extends ConsumerWidget {
  const AppSidebar({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final location = GoRouterState.of(context).matchedLocation;
    final user = ref.watch(authStateProvider).user;
    final workspace = ref.watch(workspaceStateProvider);

    return Container(
      width: 220,
      decoration: BoxDecoration(
        color: SpiceColors.surfaceAlt,
        border: Border(
          right: BorderSide(color: SpiceColors.border, width: 0.5),
        ),
      ),
      child: Column(
        children: [
          Container(
            padding: const EdgeInsets.fromLTRB(20, 20, 20, 12),
            decoration: BoxDecoration(
              border: Border(
                bottom: BorderSide(color: SpiceColors.border, width: 0.5),
              ),
            ),
            child: Row(
              children: [
                Container(
                  width: 32,
                  height: 32,
                  decoration: BoxDecoration(
                    gradient: const LinearGradient(
                      colors: [SpiceColors.primary, Color(0xFF818CF8)],
                    ),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: const Icon(Icons.store_rounded,
                      color: Colors.white, size: 18),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: Tooltip(
                    message: workspace.selectedId != null
                        ? 'Switch workspace'
                        : 'Select a workspace',
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'SpiceDesk',
                  style: TextStyle(
                    fontSize: 15,
                    fontWeight: FontWeight.w700,
                    color: SpiceColors.textPrimary,
                    letterSpacing: -0.3,
                  ),
                ),
                Text(
                  workspace.selectedName ?? 'My Store',
                  style: const TextStyle(
                    fontSize: 11,
                    color: SpiceColors.textSecondary,
                  ),
                  overflow: TextOverflow.ellipsis,
                ),
              ],
            ),
                  ),
                ),
              ],
            ),
          ),

          const SizedBox(height: 8),

          Expanded(
            child: ListView(
              padding: const EdgeInsets.symmetric(horizontal: 8),
              children: [
                _NavItem(
                  icon: Icons.dashboard_rounded,
                  label: 'Dashboard',
                  path: '/dashboard',
                  active: location == '/dashboard',
                ),
                _NavItem(
                  icon: Icons.point_of_sale_rounded,
                  label: 'Point of Sale',
                  path: '/pos',
                  active: location == '/pos',
                ),
                _NavItem(
                  icon: Icons.inventory_2_rounded,
                  label: 'Inventory',
                  path: '/inventory',
                  active: location == '/inventory',
                ),
                _NavItem(
                  icon: Icons.money_off_rounded,
                  label: 'Expenses',
                  path: '/expenses',
                  active: location == '/expenses',
                ),
                _NavItem(
                  icon: Icons.people_rounded,
                  label: 'Customers',
                  path: '/customers',
                  active: location == '/customers',
                ),
                _NavItem(
                  icon: Icons.analytics_rounded,
                  label: 'Reports',
                  path: '/reports',
                  active: location == '/reports',
                ),
                _NavItem(
                  icon: Icons.campaign_rounded,
                  label: 'Marketing',
                  path: '/marketing',
                  active: location == '/marketing',
                ),
                const SizedBox(height: 12),
                Padding(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
                  child: Text(
                    'SYSTEM',
                    style: TextStyle(
                      fontSize: 10,
                      color: SpiceColors.textSecondary,
                      fontWeight: FontWeight.w600,
                      letterSpacing: 1.2,
                    ),
                  ),
                ),
                _NavItem(
                  icon: Icons.settings_rounded,
                  label: 'Settings',
                  path: '/settings',
                  active: location.startsWith('/settings'),
                ),
                _NavItem(
                  icon: Icons.info_outline_rounded,
                  label: 'About',
                  path: '/about',
                  active: location == '/about',
                ),
              ],
            ),
          ),

          Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
            decoration: BoxDecoration(
              border: Border(
                top: BorderSide(color: SpiceColors.border, width: 0.5),
              ),
            ),
            child: Row(
              children: [
                CircleAvatar(
                  radius: 12,
                  backgroundColor: SpiceColors.primary.withAlpha(40),
                  child: Text(
                    (user?.email ?? 'U')[0].toUpperCase(),
                    style: const TextStyle(
                      color: SpiceColors.primary,
                      fontSize: 11,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    user?.email?.split('@')[0] ?? 'User',
                    style: const TextStyle(
                      fontSize: 12,
                      color: SpiceColors.textPrimary,
                      fontWeight: FontWeight.w500,
                    ),
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
                const Text(
                  'v1.2',
                  style: TextStyle(
                    fontSize: 10,
                    color: SpiceColors.textSecondary,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _NavItem extends StatelessWidget {
  final IconData icon;
  final String label;
  final String path;
  final bool active;

  const _NavItem({
    required this.icon,
    required this.label,
    required this.path,
    required this.active,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 2),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: () => context.go(path),
          borderRadius: BorderRadius.circular(8),
          child: AnimatedContainer(
            duration: const Duration(milliseconds: 200),
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
            decoration: BoxDecoration(
              color: active
                  ? SpiceColors.primary.withAlpha(20)
                  : Colors.transparent,
              borderRadius: BorderRadius.circular(8),
              border: active
                  ? Border(
                      left: BorderSide(color: SpiceColors.primary, width: 3),
                    )
                  : null,
            ),
            child: Row(
              children: [
                Icon(
                  icon,
                  size: 18,
                  color: active
                      ? SpiceColors.primary
                      : SpiceColors.textSecondary,
                ),
                const SizedBox(width: 12),
                Text(
                  label,
                  style: TextStyle(
                    fontSize: 13,
                    fontWeight: active ? FontWeight.w600 : FontWeight.w400,
                    color: active
                        ? SpiceColors.primary
                        : SpiceColors.textSecondary,
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
