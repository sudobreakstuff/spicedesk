import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../core/theme.dart';
import '../../providers/theme_provider.dart';
import '../../providers/business_provider.dart';
import '../../providers/order_provider.dart';
import '../../providers/product_provider.dart';
import '../../providers/customer_provider.dart';
import '../../models/order.dart';
import '../settings/settings_screen.dart';
import '../pos/pos_screen.dart';
import '../inventory/product_list_screen.dart';
import '../customers/customer_list_screen.dart';
import '../orders/order_list_screen.dart';

class DashboardScreen extends StatefulWidget {
  const DashboardScreen({super.key});

  @override
  State<DashboardScreen> createState() => _DashboardScreenState();
}

class _DashboardScreenState extends State<DashboardScreen> {
  int _tab = 0;

  void _onTabChange(int index) => setState(() => _tab = index);

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final bp = context.read<BusinessProvider>();
      if (bp.business != null) {
        final bid = bp.business!.id;
        context.read<OrderProvider>().loadOrders(bid);
        context.read<ProductProvider>().loadProducts(bid);
        context.read<CustomerProvider>().loadCustomers(bid);
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final bp = context.watch<BusinessProvider>();
    final name = bp.business?.name ?? 'SpiceDesk';

    return Scaffold(
      appBar: AppBar(
        title: Text(name),
        actions: [
          IconButton(icon: const Icon(Icons.settings_outlined), onPressed: () => Navigator.push(context, MaterialPageRoute(builder: (_) => const SettingsScreen()))),
        ],
      ),
      body: IndexedStack(
        index: _tab,
        children: [
          _HomeTab(onTabChange: _onTabChange),
          const PosScreen(),
          const ProductListScreen(),
          const CustomerListScreen(),
          const OrderListScreen(),
        ],
      ),
      bottomNavigationBar: NavigationBar(
        selectedIndex: _tab,
        onDestinationSelected: (i) => setState(() => _tab = i),
        destinations: const [
          NavigationDestination(icon: Icon(Icons.home_outlined), selectedIcon: Icon(Icons.home), label: 'Home'),
          NavigationDestination(icon: Icon(Icons.point_of_sale_outlined), label: 'Sale'),
          NavigationDestination(icon: Icon(Icons.inventory_2_outlined), label: 'Stock'),
          NavigationDestination(icon: Icon(Icons.people_outline), selectedIcon: Icon(Icons.people), label: 'CRM'),
          NavigationDestination(icon: Icon(Icons.receipt_long_outlined), label: 'Orders'),
        ],
      ),
    );
  }
}

class _HomeTab extends StatelessWidget {
  final void Function(int) onTabChange;
  const _HomeTab({required this.onTabChange});

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final bp = context.watch<BusinessProvider>();
    final op = context.watch<OrderProvider>();
    final pp = context.watch<ProductProvider>();
    final cp = context.watch<CustomerProvider>();
    final tp = context.watch<ThemeProvider>();
    final name = bp.business?.name ?? 'SpiceDesk';

    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(name, style: Theme.of(context).textTheme.headlineMedium),
          const SizedBox(height: 4),
          Text('Welcome back!', style: Theme.of(context).textTheme.bodyMedium),
          const SizedBox(height: 20),
          Row(
            children: [
              Expanded(child: _StatCard(label: "Today's Sales", value: '${bp.business?.currencySymbol ?? 'R'} ${op.totalSalesToday.toStringAsFixed(2)}', icon: Icons.trending_up, color: T.s)),
              const SizedBox(width: 12),
              Expanded(child: _StatCard(label: 'Products', value: '${pp.totalProducts}', icon: Icons.inventory_2, color: T.p)),
            ],
          ),
          const SizedBox(height: 12),
          Row(
            children: [
              Expanded(child: _StatCard(label: 'Customers', value: '${cp.totalCustomers}', icon: Icons.people, color: T.w)),
              const SizedBox(width: 12),
              Expanded(child: _StatCard(label: 'Low Stock', value: '${pp.lowStockCount}', icon: Icons.warning_amber_rounded, color: T.e)),
            ],
          ),
          const SizedBox(height: 20),
          const Text('Quick Actions', style: TextStyle(fontSize: 15, fontWeight: FontWeight.w600)),
          const SizedBox(height: 10),
          Row(
            children: [
              Expanded(child: _ActionChip(label: 'New Sale', icon: Icons.add_shopping_cart, color: T.p, onTap: () => onTabChange(1))),
              const SizedBox(width: 10),
              Expanded(child: _ActionChip(label: 'Add Product', icon: Icons.add_box, color: T.s, onTap: () => onTabChange(2))),
              const SizedBox(width: 10),
              Expanded(child: _ActionChip(label: 'Add Customer', icon: Icons.person_add, color: T.w, onTap: () => onTabChange(3))),
            ],
          ),
          const SizedBox(height: 20),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Text('Dark Mode', style: TextStyle(fontSize: 15, fontWeight: FontWeight.w600)),
              Switch(value: tp.isDark, onChanged: (_) => tp.toggle()),
            ],
          ),
          const SizedBox(height: 20),
          const Text('Recent Orders', style: TextStyle(fontSize: 15, fontWeight: FontWeight.w600)),
          const SizedBox(height: 8),
          ...op.orders.take(5).map((o) => _OrderTile(order: o)),
          if (op.orders.isEmpty) Padding(
            padding: const EdgeInsets.symmetric(vertical: 24),
            child: Center(child: Text('No orders yet', style: Theme.of(context).textTheme.bodyMedium)),
          ),
        ],
      ),
    );
  }
}

class _StatCard extends StatelessWidget {
  final String label;
  final String value;
  final IconData icon;
  final Color color;
  const _StatCard({required this.label, required this.value, required this.icon, required this.color});

  @override
  Widget build(BuildContext context) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(14),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Icon(icon, color: color, size: 22),
            const SizedBox(height: 8),
            Text(value, style: const TextStyle(fontSize: 18, fontWeight: FontWeight.w700)),
            const SizedBox(height: 2),
            Text(label, style: Theme.of(context).textTheme.bodySmall),
          ],
        ),
      ),
    );
  }
}

class _ActionChip extends StatelessWidget {
  final String label;
  final IconData icon;
  final Color color;
  final VoidCallback onTap;
  const _ActionChip({required this.label, required this.icon, required this.color, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(10),
      child: Card(
        child: Padding(
          padding: const EdgeInsets.symmetric(vertical: 14, horizontal: 8),
          child: Column(
            children: [
              Icon(icon, color: color, size: 22),
              const SizedBox(height: 6),
              Text(label, style: const TextStyle(fontSize: 11, fontWeight: FontWeight.w600)),
            ],
          ),
        ),
      ),
    );
  }
}

class _OrderTile extends StatelessWidget {
  final OrderModel order;
  const _OrderTile({required this.order});

  @override
  Widget build(BuildContext context) {
    final time = '${order.createdAt.hour.toString().padLeft(2, '0')}:${order.createdAt.minute.toString().padLeft(2, '0')}';
    return ListTile(
      dense: true,
      leading: CircleAvatar(radius: 16, backgroundColor: T.pBg, child: Text('#${order.id.substring(0, 4).toUpperCase()}', style: const TextStyle(fontSize: 10, fontWeight: FontWeight.w700, color: T.p))),
      title: Text('R ${order.total.toStringAsFixed(2)}', style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 13)),
      subtitle: Text('$time · ${order.paymentMethod}', style: Theme.of(context).textTheme.bodySmall),
      trailing: Icon(Icons.chevron_right, color: Theme.of(context).iconTheme.color),
    );
  }
}

