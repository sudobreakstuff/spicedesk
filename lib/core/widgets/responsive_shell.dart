import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../core/theme/app_theme.dart';
import '../../core/widgets/app_sidebar.dart';
import '../../features/workspace/domain/workspace_state.dart';

class ResponsiveShell extends ConsumerWidget {
  final Widget child;
  ResponsiveShell({super.key, required this.child});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final width = MediaQuery.of(context).size.width;
    final isWide = width > 850;

    if (isWide) {
      return Row(children: [AppSidebar(), Expanded(child: child)]);
    }

    // Narrow: use bottom nav
    final location = GoRouterState.of(context).matchedLocation;
    int currentIndex;
    if (location.startsWith('/pos')) { currentIndex = 0; }
    else if (location.startsWith('/inventory')) { currentIndex = 1; }
    else if (location.startsWith('/customers')) { currentIndex = 2; }
    else if (location.startsWith('/reports')) { currentIndex = 3; }
    else if (location.startsWith('/dashboard')) { currentIndex = 4; }
    else { currentIndex = 4; }

    final workspace = ref.watch(workspaceStateProvider);

    return Scaffold(
      backgroundColor: SpiceColors.surface,
      appBar: AppBar(
        title: PopupMenuButton<String>(
          offset: Offset(0, 40),
          padding: EdgeInsets.zero,
          color: SpiceColors.surfaceAlt,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
            side: BorderSide(color: SpiceColors.border),
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(workspace.selectedName ?? 'SpiceDesk',
                  style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600, color: SpiceColors.textPrimary)),
              Icon(Icons.arrow_drop_down, color: SpiceColors.textSecondary),
            ],
          ),
          itemBuilder: (_) {
            final workspaces = ref.watch(workspacesProvider).valueOrNull ?? [];
            return [
              PopupMenuItem<String>(
                enabled: false, height: 24,
                child: Text('Switch Workspace',
                    style: TextStyle(fontSize: 11, fontWeight: FontWeight.w600, color: SpiceColors.textSecondary)),
              ),
              PopupMenuDivider(height: 4),
              ...workspaces.map((ws) => PopupMenuItem<String>(
                value: ws['workspace_id'],
                child: Row(children: [
                  Container(
                    width: 28, height: 28,
                    decoration: BoxDecoration(
                      gradient: LinearGradient(colors: [SpiceColors.primary, Color(0xFF818CF8)]),
                      borderRadius: BorderRadius.circular(6),
                    ),
                    child: Icon(Icons.store, color: Colors.white, size: 14),
                  ),
                  SizedBox(width: 8),
                  Expanded(
                    child: Text(ws['name'] ?? '',
                        style: TextStyle(fontSize: 13, color: SpiceColors.textPrimary)),
                  ),
                  if (ws['workspace_id'] == workspace.selectedId)
                    Icon(Icons.check, size: 16, color: SpiceColors.accent),
                ]),
                onTap: () => ref.read(workspaceStateProvider.notifier).selectWorkspace(ws),
              )),
              PopupMenuDivider(height: 4),
              if (workspaces.length < 3)
                PopupMenuItem<String>(
                  child: Row(children: [
                    Icon(Icons.add, size: 16, color: SpiceColors.primary),
                    SizedBox(width: 8),
                    Text('New Workspace', style: TextStyle(fontSize: 13, color: SpiceColors.primary)),
                  ]),
                  onTap: () => context.go('/workspace'),
                ),
              PopupMenuDivider(height: 4),
              PopupMenuItem<String>(
                child: Row(children: [
                  Icon(Icons.settings, size: 16, color: SpiceColors.textSecondary),
                  SizedBox(width: 8),
                  Text('Manage Workspaces', style: TextStyle(fontSize: 13, color: SpiceColors.textSecondary)),
                ]),
                onTap: () => context.go('/workspace'),
              ),
            ];
          },
        ),
        surfaceTintColor: Colors.transparent,
      ),
      body: child,
      drawer: Drawer(
        backgroundColor: SpiceColors.surfaceAlt,
        child: SafeArea(
          child: Column(children: [
            Padding(
              padding: EdgeInsets.fromLTRB(20, 20, 20, 8),
              child: Row(children: [
                Container(
                  width: 36, height: 36,
                  decoration: BoxDecoration(
                    gradient: LinearGradient(colors: [SpiceColors.primary, Color(0xFF818CF8)]),
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: Icon(Icons.store_rounded, color: Colors.white, size: 20),
                ),
                SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text('SpiceDesk',
                          style: TextStyle(fontSize: 16, fontWeight: FontWeight.w700, color: SpiceColors.textPrimary)),
                      Text(workspace.selectedName ?? 'My Store',
                          style: TextStyle(fontSize: 12, color: SpiceColors.textSecondary),
                          overflow: TextOverflow.ellipsis),
                    ],
                  ),
                ),
              ]),
            ),
            Padding(
              padding: EdgeInsets.symmetric(horizontal: 12),
              child: InkWell(
                onTap: () { Navigator.pop(context); context.go('/workspace'); },
                borderRadius: BorderRadius.circular(8),
                child: Container(
                  padding: EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(8),
                    color: SpiceColors.primary.withAlpha(15),
                  ),
                  child: Row(children: [
                    Icon(Icons.swap_horiz, size: 16, color: SpiceColors.primary),
                    SizedBox(width: 8),
                    Text('Switch Workspace',
                        style: TextStyle(fontSize: 13, fontWeight: FontWeight.w600, color: SpiceColors.primary)),
                  ]),
                ),
              ),
            ),
            SizedBox(height: 4),
            Divider(color: SpiceColors.border, height: 1),
            SizedBox(height: 4),
            _drawerItem(context, Icons.point_of_sale, 'POS', '/pos', location),
            _drawerItem(context, Icons.inventory_2, 'Inventory', '/inventory', location),
            _drawerItem(context, Icons.people, 'Customers', '/customers', location),
            _drawerItem(context, Icons.analytics, 'Reports', '/reports', location),
            _drawerItem(context, Icons.description_outlined, 'Pending', '/pending', location),
            _drawerItem(context, Icons.money_off, 'Expenses', '/expenses', location),
            _drawerItem(context, Icons.campaign, 'Marketing', '/marketing', location),
            Spacer(),
            _drawerItem(context, Icons.settings, 'Settings', '/settings', location),
            _drawerItem(context, Icons.info_outline, 'About', '/about', location),
            SizedBox(height: 20),
          ]),
        ),
      ),
      bottomNavigationBar: Container(
        decoration: BoxDecoration(
          color: SpiceColors.surfaceAlt,
          border: Border(top: BorderSide(color: SpiceColors.border, width: 0.5)),
        ),
        child: SafeArea(
          child: SizedBox(
            height: 60,
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceAround,
              children: [
                _navItem(Icons.point_of_sale, 'POS', 0, currentIndex, '/pos', context),
                _navItem(Icons.inventory_2, 'Stock', 1, currentIndex, '/inventory', context),
                _navItem(Icons.dashboard, 'Home', 4, currentIndex, '/dashboard', context),
                _navItem(Icons.analytics, 'Reports', 3, currentIndex, '/reports', context),
                _navItem(Icons.settings, 'Settings', 5, currentIndex, '/settings', context),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _navItem(IconData icon, String label, int index, int current, String path, BuildContext context) {
    final active = index == current;
    return GestureDetector(
      onTap: () => context.go(path),
      child: SizedBox(
        width: 64,
        child: Column(mainAxisAlignment: MainAxisAlignment.center, children: [
          Icon(icon, size: 22, color: active ? SpiceColors.primary : SpiceColors.textSecondary),
          SizedBox(height: 2),
          Text(label, style: TextStyle(fontSize: 10, fontWeight: active ? FontWeight.w600 : FontWeight.w400, color: active ? SpiceColors.primary : SpiceColors.textSecondary)),
        ]),
      ),
    );
  }

  Widget _drawerItem(BuildContext context, IconData icon, String label, String path, String location) {
    final active = location == path;
    return ListTile(
      leading: Icon(icon, color: active ? SpiceColors.primary : SpiceColors.textSecondary, size: 20),
      title: Text(label, style: TextStyle(fontSize: 14, fontWeight: active ? FontWeight.w600 : FontWeight.w400, color: active ? SpiceColors.primary : SpiceColors.textPrimary)),
      selected: active,
      selectedTileColor: SpiceColors.primary.withAlpha(20),
      onTap: () { context.go(path); Navigator.pop(context); },
    );
  }
}
