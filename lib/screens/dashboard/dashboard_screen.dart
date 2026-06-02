import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:intl/intl.dart';
import '../../providers/theme_provider.dart';
import '../../providers/auth_provider.dart';
import '../../providers/business_provider.dart';
import '../../providers/product_provider.dart';
import '../../providers/customer_provider.dart';
import '../../providers/order_provider.dart';
import '../../core/app_theme.dart';
import '../pos/pos_screen.dart';
import '../inventory/product_list_screen.dart';
import '../customers/customer_list_screen.dart';
import '../orders/order_list_screen.dart';
import '../invoices/invoice_list_screen.dart';
import '../settings/settings_screen.dart';
import '../auth/login_screen.dart';

class DashboardScreen extends StatefulWidget {
  const DashboardScreen({super.key});
  @override
  State<DashboardScreen> createState() => _DashboardScreenState();
}

class _DashboardScreenState extends State<DashboardScreen> {
  int _tab = 0;
  final _scaffoldKey = GlobalKey<ScaffoldState>();

  @override
  void initState() {
    super.initState();
    _loadData();
  }

  void _loadData() {
    final bp = context.read<BusinessProvider>();
    if (bp.business != null) {
      context.read<ProductProvider>().loadProducts(bp.business!.id);
      context.read<CustomerProvider>().loadCustomers(bp.business!.id);
      context.read<OrderProvider>().loadOrders(bp.business!.id);
    }
  }

  @override
  Widget build(BuildContext context) {
    final bp = context.watch<BusinessProvider>();
    return Scaffold(
      key: _scaffoldKey,
      appBar: AppBar(
        title: Text(bp.business?.name ?? 'SpiceDesk'),
        actions: [
          IconButton(icon: const Icon(Icons.settings_outlined, size: 20), onPressed: () => Navigator.push(context, MaterialPageRoute(builder: (_) => const SettingsScreen()))),
          IconButton(icon: const Icon(Icons.menu), onPressed: () => _scaffoldKey.currentState?.openEndDrawer()),
        ],
      ),
      drawer: _buildDrawer(context),
      body: IndexedStack(index: _tab, children: [
        _HomeTab(onTabChange: (t) => setState(() => _tab = t)),
        const PosScreen(),
        const ProductListScreen(),
        const CustomerListScreen(),
        const OrderListScreen(),
      ]),
      bottomNavigationBar: NavigationBar(
        selectedIndex: _tab,
        onDestinationSelected: (i) => setState(() => _tab = i),
        destinations: const [
          NavigationDestination(icon: Icon(Icons.home_outlined), selectedIcon: Icon(Icons.home), label: 'Home'),
          NavigationDestination(icon: Icon(Icons.shopping_cart_outlined), selectedIcon: Icon(Icons.shopping_cart), label: 'Sale'),
          NavigationDestination(icon: Icon(Icons.inventory_2_outlined), selectedIcon: Icon(Icons.inventory_2), label: 'Stock'),
          NavigationDestination(icon: Icon(Icons.people_outline), selectedIcon: Icon(Icons.people), label: 'CRM'),
          NavigationDestination(icon: Icon(Icons.receipt_outlined), selectedIcon: Icon(Icons.receipt), label: 'Orders'),
        ],
      ),
    );
  }

  Widget _buildDrawer(BuildContext context) {
    return Drawer(
      child: SafeArea(
        child: Column(children: [
          Container(
            padding: const EdgeInsets.fromLTRB(20, 40, 20, 20),
            width: double.infinity,
            color: SpiceColors.primary,
            child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
              CircleAvatar(radius: 22, backgroundColor: Colors.white.withValues(alpha: 0.2), child: Text('SD', style: GoogleFonts.inter(fontWeight: FontWeight.w700, color: Colors.white, fontSize: 14))),
              const SizedBox(height: 12),
              Text(context.watch<BusinessProvider>().business?.name ?? 'SpiceDesk', style: GoogleFonts.inter(fontSize: 16, fontWeight: FontWeight.w700, color: Colors.white)),
              const SizedBox(height: 2),
              Text(context.watch<AuthProvider>().userEmail ?? '', style: GoogleFonts.inter(fontSize: 12, color: Colors.white70)),
            ]),
          ),
          Expanded(child: ListView(padding: const EdgeInsets.symmetric(vertical: 4), children: [
            _drawerItem(Icons.home_outlined, 'Dashboard', () { Navigator.pop(context); setState(() => _tab = 0); }),
            _drawerItem(Icons.shopping_cart_outlined, 'New Sale', () { Navigator.pop(context); setState(() => _tab = 1); }),
            _drawerItem(Icons.inventory_2_outlined, 'Inventory', () { Navigator.pop(context); setState(() => _tab = 2); }),
            _drawerItem(Icons.people_outline, 'Customers', () { Navigator.pop(context); setState(() => _tab = 3); }),
            _drawerItem(Icons.receipt_outlined, 'Orders', () { Navigator.pop(context); setState(() => _tab = 4); }),
            const Divider(),
            _drawerItem(Icons.description_outlined, 'Invoices', () { Navigator.pop(context); Navigator.push(context, MaterialPageRoute(builder: (_) => const InvoiceListScreen())); }),
            _drawerItem(Icons.account_balance_wallet_outlined, 'Expenses', () { Navigator.pop(context); ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Coming soon'), behavior: SnackBarBehavior.floating)); }),
            _drawerItem(Icons.analytics_outlined, 'Reports', () { Navigator.pop(context); ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Coming soon'), behavior: SnackBarBehavior.floating)); }),
            const Divider(),
            _drawerItem(Icons.settings_outlined, 'Settings', () { Navigator.pop(context); Navigator.push(context, MaterialPageRoute(builder: (_) => const SettingsScreen())); }),
          ])),
          const Divider(),
          ListTile(
            leading: const Icon(Icons.logout, color: SpiceColors.error, size: 20),
            title: Text('Sign Out', style: GoogleFonts.inter(fontSize: 13, color: SpiceColors.error)),
            onTap: () async {
              await context.read<AuthProvider>().signOut();
              if (context.mounted) {
                Navigator.of(context).pushAndRemoveUntil(MaterialPageRoute(builder: (_) => const LoginScreen()), (r) => false);
              }
            },
          ),
          Padding(
            padding: const EdgeInsets.all(14),
            child: Text('SpiceDesk · Built by Shahid Singh', textAlign: TextAlign.center, style: GoogleFonts.inter(fontSize: 10, color: SpiceColors.textTertiary)),
          ),
        ]),
      ),
    );
  }

  Widget _drawerItem(IconData icon, String label, VoidCallback onTap) {
    return ListTile(leading: Icon(icon, size: 20), title: Text(label, style: GoogleFonts.inter(fontSize: 13, fontWeight: FontWeight.w500)), onTap: onTap, dense: true, horizontalTitleGap: 12);
  }
}

class _HomeTab extends StatelessWidget {
  final ValueChanged<int> onTabChange;
  const _HomeTab({required this.onTabChange});

  @override
  Widget build(BuildContext context) {
    final bp = context.watch<BusinessProvider>();
    final op = context.watch<OrderProvider>();
    final pp = context.watch<ProductProvider>();
    final cp = context.watch<CustomerProvider>();
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final fmt = NumberFormat.currency(symbol: 'R ', decimalDigits: 2);

    return RefreshIndicator(
      onRefresh: () async {
        if (bp.business != null) {
          await op.loadOrders(bp.business!.id);
          await pp.loadProducts(bp.business!.id);
          await cp.loadCustomers(bp.business!.id);
        }
      },
      child: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          // Header
          Text('Good ${_greeting()}', style: GoogleFonts.inter(fontSize: 14, color: SpiceColors.textSecondary)),
          const SizedBox(height: 4),
          Text(bp.business?.name ?? 'Welcome', style: GoogleFonts.inter(fontSize: 22, fontWeight: FontWeight.w700, color: isDark ? SpiceColors.darkText : SpiceColors.textPrimary)),
          const SizedBox(height: 20),

          // Stat grid
          Row(children: [
            Expanded(child: _StatBox(label: 'Today\'s Sales', value: fmt.format(op.totalSalesToday), icon: Icons.trending_up, color: SpiceColors.success)),
            const SizedBox(width: 10),
            Expanded(child: _StatBox(label: 'Orders', value: '${op.totalOrders}', icon: Icons.receipt, color: SpiceColors.primaryLight)),
          ]),
          const SizedBox(height: 10),
          Row(children: [
            Expanded(child: _StatBox(label: 'Products', value: '${pp.totalProducts}', icon: Icons.inventory_2, color: SpiceColors.warning)),
            const SizedBox(width: 10),
            Expanded(child: _StatBox(label: 'Customers', value: '${cp.totalCustomers}', icon: Icons.people, color: Colors.purple.shade600)),
          ]),
          const SizedBox(height: 24),

          // Quick Actions
          Text('Quick Actions', style: GoogleFonts.inter(fontSize: 13, fontWeight: FontWeight.w600, color: SpiceColors.textSecondary, letterSpacing: 0.5)),
          const SizedBox(height: 10),
          Row(children: [
            Expanded(child: _ActionBtn(icon: Icons.shopping_cart, label: 'New Sale', color: SpiceColors.primary, onTap: () => onTabChange(1))),
            const SizedBox(width: 8),
            Expanded(child: _ActionBtn(icon: Icons.add_circle_outline, label: 'Add Product', color: SpiceColors.primaryLight, onTap: () => onTabChange(2))),
            const SizedBox(width: 8),
            Expanded(child: _ActionBtn(icon: Icons.person_add_outlined, label: 'Add Customer', color: Colors.purple.shade600, onTap: () => onTabChange(3))),
          ]),
          const SizedBox(height: 8),
          Row(children: [
            Expanded(child: _ActionBtn(icon: Icons.description_outlined, label: 'Invoices', color: Colors.teal.shade600, onTap: () => Navigator.push(context, MaterialPageRoute(builder: (_) => const InvoiceListScreen())))),
            const SizedBox(width: 8),
            Expanded(child: _ActionBtn(icon: Icons.account_balance_wallet_outlined, label: 'Expenses', color: SpiceColors.warning, onTap: () => _comingSoon(context))),
            const SizedBox(width: 8),
            Expanded(child: _ActionBtn(icon: Icons.analytics_outlined, label: 'Reports', color: SpiceColors.textSecondary, onTap: () => _comingSoon(context))),
          ]),
          const SizedBox(height: 24),

          // Recent Orders
          Text('Recent Orders', style: GoogleFonts.inter(fontSize: 13, fontWeight: FontWeight.w600, color: SpiceColors.textSecondary, letterSpacing: 0.5)),
          const SizedBox(height: 10),
          if (op.orders.isEmpty)
            Container(
              padding: const EdgeInsets.all(32),
              decoration: BoxDecoration(borderRadius: BorderRadius.circular(10), border: Border.all(color: SpiceColors.cardBorder)),
              child: Column(children: [
                Icon(Icons.receipt_long, size: 36, color: SpiceColors.textTertiary),
                const SizedBox(height: 8),
                Text('No orders yet', style: GoogleFonts.inter(fontSize: 13, color: SpiceColors.textSecondary)),
                const SizedBox(height: 6),
                ElevatedButton(onPressed: () => onTabChange(1), style: ElevatedButton.styleFrom(minimumSize: const Size(140, 36)), child: const Text('Make a Sale', style: TextStyle(fontSize: 12))),
              ]),
            )
          else
            ...op.orders.take(5).map((o) => _OrderRow(o: o, fmt: fmt)),
          const SizedBox(height: 24),

          // Quick Settings
          Text('Quick Settings', style: GoogleFonts.inter(fontSize: 13, fontWeight: FontWeight.w600, color: SpiceColors.textSecondary, letterSpacing: 0.5)),
          const SizedBox(height: 10),
          Card(
            child: Column(children: [
              ListTile(
                leading: const Icon(Icons.palette_outlined, size: 20, color: SpiceColors.primaryLight),
                title: Text('Theme', style: GoogleFonts.inter(fontSize: 13, fontWeight: FontWeight.w500)),
                subtitle: Text(context.watch<ThemeProvider>().isDark ? 'Dark' : 'Light', style: GoogleFonts.inter(fontSize: 11, color: SpiceColors.textTertiary)),
                trailing: Switch.adaptive(value: context.watch<ThemeProvider>().isDark, onChanged: (_) => context.read<ThemeProvider>().toggle()),
                contentPadding: const EdgeInsets.symmetric(horizontal: 14),
                dense: true,
              ),
            ]),
          ),

          const SizedBox(height: 80),
        ],
      ),
    );
  }

  void _comingSoon(BuildContext context) {
    ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Coming soon'), behavior: SnackBarBehavior.floating, duration: Duration(seconds: 1)));
  }

  String _greeting() => switch (DateTime.now().hour) { < 12 => 'Morning', < 17 => 'Afternoon', _ => 'Evening' };
}

class _StatBox extends StatelessWidget {
  final String label, value;
  final IconData icon;
  final Color color;
  const _StatBox({required this.label, required this.value, required this.icon, required this.color});

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: isDark ? SpiceColors.darkCard : SpiceColors.surface,
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: isDark ? SpiceColors.darkBorder : SpiceColors.cardBorder),
      ),
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [
          Text(label, style: GoogleFonts.inter(fontSize: 11, color: SpiceColors.textTertiary, fontWeight: FontWeight.w500)),
          Icon(icon, size: 16, color: color),
        ]),
        const SizedBox(height: 6),
        Text(value, style: GoogleFonts.inter(fontSize: 20, fontWeight: FontWeight.w700, color: isDark ? SpiceColors.darkText : SpiceColors.textPrimary)),
      ]),
    );
  }
}

class _ActionBtn extends StatelessWidget {
  final IconData icon;
  final String label;
  final Color color;
  final VoidCallback onTap;
  const _ActionBtn({required this.icon, required this.label, required this.color, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return Material(
      color: color.withValues(alpha: 0.06),
      borderRadius: BorderRadius.circular(10),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(10),
        child: Padding(
          padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 8),
          child: Column(children: [
            Icon(icon, color: color, size: 22),
            const SizedBox(height: 6),
            Text(label, style: GoogleFonts.inter(fontSize: 11, fontWeight: FontWeight.w500, color: color), textAlign: TextAlign.center, maxLines: 1, overflow: TextOverflow.ellipsis),
          ]),
        ),
      ),
    );
  }
}

class _OrderRow extends StatelessWidget {
  final dynamic o;
  final NumberFormat fmt;
  const _OrderRow({required this.o, required this.fmt});

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final date = DateFormat('dd/MM HH:mm').format(o.createdAt as DateTime);
    final statusColor = (o.status as String) == 'Completed' ? SpiceColors.success : (o.status as String) == 'Cancelled' ? SpiceColors.error : SpiceColors.warning;
    return Container(
      margin: const EdgeInsets.only(bottom: 4),
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
      decoration: BoxDecoration(color: isDark ? SpiceColors.darkCard : SpiceColors.surface, borderRadius: BorderRadius.circular(8), border: Border.all(color: isDark ? SpiceColors.darkBorder : SpiceColors.cardBorder)),
      child: Row(children: [
        Container(width: 6, height: 6, decoration: BoxDecoration(shape: BoxShape.circle, color: statusColor)),
        const SizedBox(width: 10),
        Expanded(child: Text((o.orderType as String?) ?? '', style: GoogleFonts.inter(fontSize: 13, fontWeight: FontWeight.w500, color: isDark ? SpiceColors.darkText : SpiceColors.textPrimary))),
        Text(fmt.format((o.total as num).toDouble()), style: GoogleFonts.inter(fontSize: 13, fontWeight: FontWeight.w600, color: SpiceColors.primary)),
        const SizedBox(width: 12),
        Text(date, style: GoogleFonts.inter(fontSize: 11, color: SpiceColors.textTertiary)),
      ]),
    );
  }
}
