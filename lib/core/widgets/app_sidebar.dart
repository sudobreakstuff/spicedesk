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
          // Brand header
          Padding(
            padding: const EdgeInsets.fromLTRB(20, 20, 20, 8),
            child: Row(
              children: [
                Container(
                  width: 34,
                  height: 34,
                  decoration: BoxDecoration(
                    gradient: const LinearGradient(
                      colors: [SpiceColors.primary, Color(0xFF818CF8)],
                    ),
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: const Icon(Icons.store_rounded,
                      color: Colors.white, size: 20),
                ),
                const SizedBox(width: 10),
                const Text(
                  'SpiceDesk',
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.w700,
                    color: SpiceColors.textPrimary,
                    letterSpacing: -0.3,
                  ),
                ),
              ],
            ),
          ),

          const SizedBox(height: 4),

          // Workspace selector
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 20),
            child: InkWell(
              onTap: () => context.go('/workspace'),
              borderRadius: BorderRadius.circular(8),
              child: Padding(
                padding: const EdgeInsets.symmetric(vertical: 6, horizontal: 8),
                child: Row(
                  children: [
                    Icon(Icons.business,
                        size: 14, color: SpiceColors.textSecondary),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        workspace.selectedName ?? 'Select Workspace',
                        style: const TextStyle(
                          fontSize: 12,
                          color: SpiceColors.textSecondary,
                        ),
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                    const Icon(Icons.keyboard_arrow_down,
                        size: 14, color: SpiceColors.textSecondary),
                  ],
                ),
              ),
            ),
          ),

          const SizedBox(height: 16),

          // Divider
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 20),
            child: Divider(
                color: SpiceColors.border, height: 1),
          ),

          const SizedBox(height: 12),

          // Navigation
          Expanded(
            child: ListView(
              padding: const EdgeInsets.symmetric(horizontal: 8),
              children: [
                _NavItem(
                  icon: Icons.dashboard_rounded,
                  label: 'Dashboard',
                  path: '/dashboard',
                  active: location.startsWith('/dashboard'),
                ),
                _NavItem(
                  icon: Icons.point_of_sale_rounded,
                  label: 'Point of Sale',
                  path: '/pos',
                  active: location.startsWith('/pos'),
                ),
                _NavItem(
                  icon: Icons.inventory_2_rounded,
                  label: 'Inventory',
                  path: '/inventory',
                  active: location.startsWith('/inventory'),
                ),
                _NavItem(
                  icon: Icons.people_rounded,
                  label: 'Customers',
                  path: '/customers',
                  active: location.startsWith('/customers'),
                ),
                _NavItem(
                  icon: Icons.analytics_rounded,
                  label: 'Reports',
                  path: '/reports',
                  active: location.startsWith('/reports'),
                ),
                _NavItem(
                  icon: Icons.campaign_rounded,
                  label: 'Marketing',
                  path: '/marketing',
                  active: location.startsWith('/marketing'),
                ),
                const SizedBox(height: 16),
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
                  child: Text(
                    'SYSTEM',
                    style: TextStyle(
                      fontSize: 10,
                      color: SpiceColors.textSecondary,
                      fontWeight: FontWeight.w600,
                      letterSpacing: 1.5,
                    ),
                  ),
                ),
                _NavItem(
                  icon: Icons.settings_rounded,
                  label: 'Settings',
                  path: '/settings',
                  active: location.startsWith('/settings'),
                ),
              ],
            ),
          ),

          // User section
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              border: Border(
                top: BorderSide(color: SpiceColors.border, width: 0.5),
              ),
            ),
            child: Row(
              children: [
                CircleAvatar(
                  radius: 14,
                  backgroundColor: SpiceColors.primary.withAlpha(40),
                  child: Text(
                    (user?.email ?? 'U')[0].toUpperCase(),
                    style: const TextStyle(
                      color: SpiceColors.primary,
                      fontSize: 12,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        user?.userMetadata?['name'] ??
                            user?.email?.split('@')[0] ?? 'User',
                        style: const TextStyle(
                          fontSize: 13,
                          color: SpiceColors.textPrimary,
                          fontWeight: FontWeight.w500,
                        ),
                        overflow: TextOverflow.ellipsis,
                      ),
                      Text(
                        workspace.selectedId != null
                            ? workspace.selectedName ?? ''
                            : 'No workspace',
                        style: const TextStyle(
                          fontSize: 11,
                          color: SpiceColors.textSecondary,
                        ),
                        overflow: TextOverflow.ellipsis,
                      ),
                    ],
                  ),
                ),
                PopupMenuButton<String>(
                  offset: const Offset(0, -160),
                  padding: EdgeInsets.zero,
                  color: SpiceColors.surfaceAlt,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                    side: BorderSide(color: SpiceColors.border),
                  ),
                  itemBuilder: (_) => [
                    const PopupMenuItem(
                      value: 'workspace',
                      child: _PopupItem(
                          icon: Icons.swap_horiz,
                          label: 'Switch Workspace'),
                    ),
                    const PopupMenuDivider(height: 0),
                    const PopupMenuItem(
                      enabled: false,
                      height: 28,
                      child: Text('Made by Shahid Singh',
                          style: TextStyle(
                              fontSize: 10,
                              color: SpiceColors.textSecondary)),
                    ),
                    const PopupMenuDivider(height: 0),
                    const PopupMenuItem(
                      value: 'logout',
                      child: _PopupItem(
                          icon: Icons.logout,
                          label: 'Sign Out',
                          color: SpiceColors.danger),
                    ),
                  ],
                  onSelected: (v) {
                    if (v == 'logout') {
                      ref.read(authStateProvider.notifier).logout();
                    } else if (v == 'workspace') {
                      context.go('/workspace');
                    }
                  },
                  child: const Icon(Icons.more_vert,
                      size: 18, color: SpiceColors.textSecondary),
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
                      left: BorderSide(
                          color: SpiceColors.primary, width: 3),
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
                    fontWeight:
                        active ? FontWeight.w600 : FontWeight.w400,
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

class _PopupItem extends StatelessWidget {
  final IconData icon;
  final String label;
  final Color? color;

  const _PopupItem({
    required this.icon,
    required this.label,
    this.color,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Icon(icon, size: 16, color: color ?? SpiceColors.textSecondary),
        const SizedBox(width: 10),
        Text(
          label,
          style: TextStyle(
            fontSize: 13,
            color: color ?? SpiceColors.textPrimary,
          ),
        ),
      ],
    );
  }
}
