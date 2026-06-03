import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../providers/auth_provider.dart';
import '../../providers/business_provider.dart';
import '../../providers/product_provider.dart';
import '../../providers/customer_provider.dart';
import '../../providers/order_provider.dart';
import '../../providers/theme_provider.dart';
import '../../core/constants.dart';
import '../auth/login_screen.dart';
import '../settings/settings_screen.dart';
import '../pos/pos_screen.dart';
import '../inventory/product_list_screen.dart';
import '../customers/customer_list_screen.dart';
import '../orders/order_list_screen.dart';
import '../invoices/invoice_list_screen.dart';

class DashboardScreen extends StatefulWidget {
  const DashboardScreen({super.key});
  @override
  State<DashboardScreen> createState() => _DashboardScreenState();
}

class _DashboardScreenState extends State<DashboardScreen> {
  int _tab = 0;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final b = context.read<BusinessProvider>().business;
      if (b != null) {
        context.read<ProductProvider>().loadProducts(b.id);
        context.read<CustomerProvider>().loadCustomers(b.id);
        context.read<OrderProvider>().loadOrders(b.id);
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    final bp = context.watch<BusinessProvider>();
    return Scaffold(
      appBar: AppBar(
        title: Text(bp.business?.name ?? 'SpiceDesk'),
        actions: [
          IconButton(icon: const Icon(Icons.settings_outlined), onPressed: () => Navigator.push(context, MaterialPageRoute(builder: (_) => const SettingsScreen()))),
          IconButton(icon: const Icon(Icons.menu), onPressed: () => _scaffoldKey.currentState?.openDrawer()),
        ],
      ),
      drawer: _buildDrawer(context),
      body: IndexedStack(index: _tab, children: const [
        _HomeTab(), PosScreen(), ProductListScreen(), CustomerListScreen(), OrderListScreen(),
      ]),
      bottomNavigationBar: NavigationBar(
        selectedIndex: _tab,
        onDestinationSelected: (i) => setState(() => _tab = i),
        destinations: const [
          NavigationDestination(icon: Icon(Icons.home_outlined), selectedIcon: Icon(Icons.home), label: 'Home'),
          NavigationDestination(icon: Icon(Icons.shopping_cart_outlined), selectedIcon: Icon(Icons.shopping_cart), label: 'Sale'),
          NavigationDestination(icon: Icon(Icons.inventory_2_outlined), selectedIcon: Icon(Icons.inventory_2), label: 'Stock'),
          NavigationDestination(icon: Icon(Icons.people_outline), selectedIcon: Icon(Icons.people), label: 'CRM'),
          NavigationDestination(icon: Icon(Icons.receipt_long_outlined), selectedIcon: Icon(Icons.receipt_long), label: 'Orders'),
        ],
      ),
    );
  }

  final GlobalKey<ScaffoldState> _scaffoldKey = GlobalKey<ScaffoldState>();

  Widget _buildDrawer(BuildContext context) {
    return Drawer(
      child: SafeArea(
        child: Column(children: [
          Container(
            width: double.infinity, padding: const EdgeInsets.fromLTRB(18, 24, 18, 18),
            color: Theme.of(context).colorScheme.primary,
            child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
              const CircleAvatar(radius: 20, backgroundColor: Colors.white24, child: Icon(Icons.spa, color: Colors.white, size: 20)),
              const SizedBox(height: 10),
              Text(context.watch<BusinessProvider>().business?.name ?? 'SpiceDesk', style: const TextStyle(color: Colors.white, fontSize: 16, fontWeight: FontWeight.w600)),
              Text(context.watch<AuthProvider>().userEmail ?? '', style: const TextStyle(color: Colors.white70, fontSize: 12)),
            ]),
          ),
          Expanded(child: ListView(padding: const EdgeInsets.symmetric(vertical: 4), children: [
            _item(Icons.home_outlined, 'Dashboard', () { Navigator.pop(context); setState(() => _tab = 0); }),
            _item(Icons.shopping_cart_outlined, 'New Sale', () { Navigator.pop(context); setState(() => _tab = 1); }),
            _item(Icons.inventory_2_outlined, 'Inventory', () { Navigator.pop(context); setState(() => _tab = 2); }),
            _item(Icons.people_outline, 'Customers', () { Navigator.pop(context); setState(() => _tab = 3); }),
            _item(Icons.receipt_long_outlined, 'Orders', () { Navigator.pop(context); setState(() => _tab = 4); }),
            const Divider(),
            _item(Icons.description_outlined, 'Invoices', () { Navigator.pop(context); Navigator.push(context, MaterialPageRoute(builder: (_) => const InvoiceListScreen())); }),
            _item(Icons.account_balance_wallet_outlined, 'Expenses', () { Navigator.pop(context); _snack('Coming soon'); }),
            _item(Icons.analytics_outlined, 'Reports', () { Navigator.pop(context); _snack('Coming soon'); }),
            const Divider(),
            _item(Icons.settings_outlined, 'Settings', () { Navigator.pop(context); Navigator.push(context, MaterialPageRoute(builder: (_) => const SettingsScreen())); }),
          ])),
          const Divider(),
          ListTile(leading: const Icon(Icons.logout, color: Colors.red), title: const Text('Sign Out', style: TextStyle(color: Colors.red)), onTap: () async {
            await context.read<AuthProvider>().signOut();
            if (context.mounted) Navigator.of(context).pushAndRemoveUntil(MaterialPageRoute(builder: (_) => const LoginScreen()), (r) => false);
          }),
          const Padding(padding: EdgeInsets.all(12), child: Text('Built by Shahid Singh', textAlign: TextAlign.center, style: TextStyle(fontSize: 10, color: Colors.grey))),
        ]),
      ),
    );
  }

  Widget _item(IconData icon, String label, VoidCallback onTap) => ListTile(leading: Icon(icon, size: 20), title: Text(label, style: const TextStyle(fontSize: 13)), onTap: onTap, dense: true, horizontalTitleGap: 12);

  void _snack(String msg) => ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(msg), behavior: SnackBarBehavior.floating, duration: const Duration(seconds: 1)));
}

class _HomeTab extends StatelessWidget {
  const _HomeTab();

  @override
  Widget build(BuildContext context) {
    final bp = context.watch<BusinessProvider>();
    final op = context.watch<OrderProvider>();
    final pp = context.watch<ProductProvider>();
    final cp = context.watch<CustomerProvider>();
    final tm = context.watch<ThemeProvider>();
    final fmt = (double v) => 'R ${v.toStringAsFixed(2)}';

    return ListView(padding: const EdgeInsets.all(16), children: [
      Text('Good ${_greet()}', style: const TextStyle(fontSize: 14, color: Colors.grey)),
      const SizedBox(height: 2),
      Text(bp.business?.name ?? 'SpiceDesk', style: const TextStyle(fontSize: 22, fontWeight: FontWeight.w700)),
      const SizedBox(height: 20),
      // Stats
      Row(children: [
        Expanded(child: _Stat(label: 'Today\'s Sales', value: fmt(op.totalSalesToday), icon: Icons.trending_up, color: Colors.green)),
        const SizedBox(width: 10),
        Expanded(child: _Stat(label: 'Orders', value: '${op.totalOrders}', icon: Icons.receipt_long, color: Colors.blue)),
      ]),
      const SizedBox(height: 10),
      Row(children: [
        Expanded(child: _Stat(label: 'Products', value: '${pp.totalProducts}', icon: Icons.inventory_2, color: Colors.orange)),
        const SizedBox(width: 10),
        Expanded(child: _Stat(label: 'Customers', value: '${cp.totalCustomers}', icon: Icons.people, color: Colors.purple)),
      ]),
      const SizedBox(height: 24),
      // Quick Actions
      const Text('Quick Actions', style: TextStyle(fontSize: 12, fontWeight: FontWeight.w600, color: Colors.grey, letterSpacing: 0.5)),
      const SizedBox(height: 10),
      Row(children: [
        Expanded(child: _Act(Icons.shopping_cart, 'New Sale', Colors.blue, () => _t(context, 1))),
        const SizedBox(width: 8),
        Expanded(child: _Act(Icons.add_circle_outline, 'Add Product', Colors.green, () => _t(context, 2))),
      ]),
      const SizedBox(height: 8),
      Row(children: [
        Expanded(child: _Act(Icons.person_add, 'Add Customer', Colors.purple, () => _t(context, 3))),
        const SizedBox(width: 8),
        Expanded(child: _Act(Icons.description_outlined, 'Invoices', Colors.teal, () => Navigator.push(context, MaterialPageRoute(builder: (_) => const InvoiceListScreen())))),
      ]),
      const SizedBox(height: 24),
      // Theme toggle
      const Text('Settings', style: TextStyle(fontSize: 12, fontWeight: FontWeight.w600, color: Colors.grey, letterSpacing: 0.5)),
      const SizedBox(height: 10),
      Card(
        child: SwitchListTile(
          title: const Text('Dark Mode'),
          value: tm.isDark,
          onChanged: (_) => tm.toggle(),
          secondary: Icon(tm.isDark ? Icons.dark_mode : Icons.light_mode),
        ),
      ),
      const SizedBox(height: 80),
    ]);
  }

  String _greet() => switch (DateTime.now().hour) { < 12 => 'Morning', < 17 => 'Afternoon', _ => 'Evening' };
}

void _t(BuildContext context, int tab) {
  final s = context.findAncestorStateOfType<_DashboardScreenState>();
  if (s != null) { s.setState(() { s._tab = tab; }); }
}

class _Stat extends StatelessWidget {
  final String label, value; final IconData icon; final Color color;
  const _Stat({required this.label, required this.value, required this.icon, required this.color});
  @override
  Widget build(BuildContext c) => Card(
    child: Padding(
      padding: const EdgeInsets.all(14),
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [Text(label, style: const TextStyle(fontSize: 11, color: Colors.grey)), Icon(icon, size: 16, color: color)]),
        const SizedBox(height: 6),
        Text(value, style: const TextStyle(fontSize: 20, fontWeight: FontWeight.w700)),
      ]),
    ),
  );
}

class _Act extends StatelessWidget {
  final IconData icon; final String label; final Color color; final VoidCallback onTap;
  const _Act(this.icon, this.label, this.color, this.onTap);
  @override
  Widget build(BuildContext c) => GestureDetector(
    onTap: onTap,
    child: Container(
      padding: const EdgeInsets.symmetric(vertical: 14, horizontal: 8),
      decoration: BoxDecoration(borderRadius: BorderRadius.circular(10), border: Border.all(color: Colors.grey.shade300)),
      child: Column(children: [Icon(icon, color: color, size: 22), const SizedBox(height: 6), Text(label, style: TextStyle(fontSize: 11, fontWeight: FontWeight.w500, color: color), textAlign: TextAlign.center)]),
    ),
  );
}
