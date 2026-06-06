import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../core/theme/app_theme.dart';
import '../../core/widgets/app_sidebar.dart';

class ResponsiveShell extends ConsumerWidget {
  final Widget child;
  const ResponsiveShell({super.key, required this.child});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final width = MediaQuery.of(context).size.width;
    final isWide = width > 850;

    if (isWide) {
      return Row(children: [const AppSidebar(), Expanded(child: child)]);
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

    return Scaffold(
      backgroundColor: SpiceColors.surface,
      appBar: AppBar(
        title: const Text('SpiceDesk'),
        surfaceTintColor: Colors.transparent,
      ),
      body: child,
      drawer: Drawer(
        backgroundColor: SpiceColors.surfaceAlt,
        child: SafeArea(
          child: Column(children: [
            const Padding(
              padding: EdgeInsets.all(20),
              child: Text('SpiceDesk', style: TextStyle(fontSize: 20, fontWeight: FontWeight.w700, color: SpiceColors.textPrimary)),
            ),
            const Divider(color: SpiceColors.border),
            _drawerItem(context, Icons.point_of_sale, 'POS', '/pos', location),
            _drawerItem(context, Icons.inventory_2, 'Inventory', '/inventory', location),
            _drawerItem(context, Icons.people, 'Customers', '/customers', location),
            _drawerItem(context, Icons.analytics, 'Reports', '/reports', location),
            _drawerItem(context, Icons.description_outlined, 'Pending', '/pending', location),
            _drawerItem(context, Icons.money_off, 'Expenses', '/expenses', location),
            _drawerItem(context, Icons.campaign, 'Marketing', '/marketing', location),
            const Spacer(),
            _drawerItem(context, Icons.settings, 'Settings', '/settings', location),
            _drawerItem(context, Icons.info_outline, 'About', '/about', location),
            const SizedBox(height: 20),
          ]),
        ),
      ),
      bottomNavigationBar: Container(
        decoration: BoxDecoration(
          color: SpiceColors.surfaceAlt,
          border: const Border(top: BorderSide(color: SpiceColors.border, width: 0.5)),
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
          const SizedBox(height: 2),
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
