import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:google_fonts/google_fonts.dart';
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
import 'product_form_screen_redirect.dart';

class DashboardScreen extends StatefulWidget {
  const DashboardScreen({super.key});
  @override
  State<DashboardScreen> createState() => _DashboardScreenState();
}

class _DashboardScreenState extends State<DashboardScreen> {
  int _tab = 0;

  void switchToTab(int tab) {
    setState(() => _tab = tab);
  }

  @override
  Widget build(BuildContext context) {
    final tm = context.watch<ThemeProvider>();
    final bp = context.watch<BusinessProvider>();
    final business = bp.business;

    return Scaffold(
      appBar: AppBar(
        title: Text(business?.name ?? 'SpiceDesk'),
      ),
      drawer: _Drawer(onNavigate: (index) { Navigator.pop(context); setState(() => _tab = index); }),
      body: _body(),
      bottomNavigationBar: NavigationBar(
        selectedIndex: _tab,
        onDestinationSelected: (i) => setState(() => _tab = i),
        backgroundColor: tm.isDark ? AppColors.surfaceDark : Colors.white,
        indicatorColor: AppColors.orange.withValues(alpha: 0.12),
        destinations: const [
          NavigationDestination(icon: Icon(Icons.home_outlined), selectedIcon: Icon(Icons.home, color: AppColors.orange), label: 'Home'),
          NavigationDestination(icon: Icon(Icons.point_of_sale_outlined), selectedIcon: Icon(Icons.point_of_sale, color: AppColors.orange), label: 'POS'),
          NavigationDestination(icon: Icon(Icons.inventory_2_outlined), selectedIcon: Icon(Icons.inventory_2, color: AppColors.orange), label: 'Stock'),
          NavigationDestination(icon: Icon(Icons.people_outline), selectedIcon: Icon(Icons.people, color: AppColors.orange), label: 'Customers'),
          NavigationDestination(icon: Icon(Icons.receipt_long_outlined), selectedIcon: Icon(Icons.receipt_long, color: AppColors.orange), label: 'Orders'),
        ],
      ),
    );
  }

  Widget _body() => switch (_tab) {
    0 => const _HomeTab(),
    1 => const PosScreen(),
    2 => const ProductListScreen(),
    3 => const CustomerListScreen(),
    4 => const OrderListScreen(),
    _ => const _HomeTab(),
  };
}

class _Drawer extends StatelessWidget {
  final Function(int) onNavigate;
  const _Drawer({required this.onNavigate});

  @override
  Widget build(BuildContext context) {
    final bp = context.watch<BusinessProvider>();
    final ap = context.watch<AuthProvider>();

    return Drawer(
      child: SafeArea(
        child: Column(
          children: [
            Container(
              width: double.infinity,
              padding: const EdgeInsets.fromLTRB(20, 24, 20, 20),
              decoration: BoxDecoration(
                gradient: const LinearGradient(colors: [AppColors.orange, AppColors.brown]),
              ),
              child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                Container(width: 48, height: 48, decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(14)),
                    child: const Icon(Icons.spa_rounded, size: 28, color: AppColors.orange)),
                const SizedBox(height: 14),
                Text(bp.business?.name ?? 'SpiceDesk', style: GoogleFonts.playfairDisplay(fontSize: 20, fontWeight: FontWeight.bold, color: Colors.white)),
                const SizedBox(height: 2),
                Text(ap.userEmail ?? '', style: GoogleFonts.poppins(fontSize: 12, color: Colors.white.withValues(alpha: 0.8))),
              ]),
            ),
            Expanded(
              child: ListView(padding: const EdgeInsets.symmetric(vertical: 8), children: [
                _item(Icons.dashboard_outlined, 'Dashboard', () => onNavigate(0)),
                _item(Icons.point_of_sale_outlined, 'Point of Sale', () => onNavigate(1)),
                _item(Icons.inventory_2_outlined, 'Inventory', () => onNavigate(2)),
                _item(Icons.people_outline, 'Customers', () => onNavigate(3)),
                _item(Icons.receipt_long_outlined, 'Orders', () => onNavigate(4)),
                const Divider(),
                _item(Icons.description_outlined, 'Invoices', () { Navigator.pop(context); Navigator.push(context, MaterialPageRoute(builder: (_) => const InvoiceListScreen())); }),
                _item(Icons.money_off_outlined, 'Expenses', () { Navigator.pop(context); _showComingSoon(context, 'Expenses'); }),
                _item(Icons.account_balance_outlined, 'Bank Accounts', () { Navigator.pop(context); _showComingSoon(context, 'Bank'); }),
                _item(Icons.bar_chart_outlined, 'Reports', () { Navigator.pop(context); _showComingSoon(context, 'Reports'); }),
                const Divider(),
                _item(Icons.settings_outlined, 'Settings', () { Navigator.pop(context); Navigator.push(context, MaterialPageRoute(builder: (_) => const SettingsScreen())); }),
              ]),
            ),
            const Divider(),
            ListTile(
              leading: const Icon(Icons.logout, color: AppColors.red),
              title: Text('Sign Out', style: GoogleFonts.poppins(color: AppColors.red)),
              onTap: () async {
                await ap.signOut();
                if (context.mounted) Navigator.of(context).pushNamedAndRemoveUntil('/login', (route) => false);
              },
            ),
            Padding(
              padding: const EdgeInsets.all(14),
              child: Text('Built by Shahid Singh', textAlign: TextAlign.center, style: GoogleFonts.poppins(fontSize: 10, color: Colors.grey.shade500, fontStyle: FontStyle.italic)),
            ),
          ],
        ),
      ),
    );
  }

  Widget _item(IconData icon, String title, VoidCallback onTap) {
    return ListTile(
      leading: Icon(icon),
      title: Text(title, style: GoogleFonts.poppins(fontSize: 14, fontWeight: FontWeight.w500)),
      onTap: onTap, dense: true,
    );
  }

  void _showComingSoon(BuildContext context, String feature) {
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('$feature — coming soon'), behavior: SnackBarBehavior.floating));
  }
}

class _HomeTab extends StatelessWidget {
  const _HomeTab();

  @override
  Widget build(BuildContext context) {
    final tm = context.watch<ThemeProvider>();
    final bp = context.watch<BusinessProvider>();
    final orderProvider = context.watch<OrderProvider>();
    final productProvider = context.watch<ProductProvider>();
    final customerProvider = context.watch<CustomerProvider>();
    final business = bp.business;
    final isDark = tm.isDark;

    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Text(_greeting(), style: GoogleFonts.poppins(fontSize: 14, color: isDark ? Colors.grey.shade400 : Colors.grey.shade600)),
        Text(business?.name ?? 'Welcome', style: GoogleFonts.playfairDisplay(fontSize: 26, fontWeight: FontWeight.bold, color: isDark ? Colors.white : AppColors.brownDark)),
        const SizedBox(height: 20),
        Row(children: [
          Expanded(child: _statCard(context, 'Today\'s Sales', 'R ${orderProvider.totalSalesToday.toStringAsFixed(2)}', Icons.trending_up, AppColors.orange)),
          const SizedBox(width: 10),
          Expanded(child: _statCard(context, 'Orders', '${orderProvider.totalOrders}', Icons.receipt_long, Colors.teal)),
        ]),
        const SizedBox(height: 10),
        Row(children: [
          Expanded(child: _statCard(context, 'Products', '${productProvider.totalProducts}', Icons.inventory_2, Colors.blue)),
          const SizedBox(width: 10),
          Expanded(child: _statCard(context, 'Customers', '${customerProvider.totalCustomers}', Icons.people, Colors.purple)),
        ]),
        const SizedBox(height: 20),
        Text('Quick Actions', style: GoogleFonts.poppins(fontSize: 16, fontWeight: FontWeight.w600, color: isDark ? Colors.white : AppColors.brownDark)),
        const SizedBox(height: 10),
        Wrap(spacing: 8, runSpacing: 8, children: [
          _quickAction(Icons.point_of_sale, 'New Sale', AppColors.orange, () {
            _switchTab(context, 1);
          }),
          _quickAction(Icons.add_shopping_cart, 'Add Product', Colors.blue, () {
            Navigator.push(context, MaterialPageRoute(builder: (_) => const ProductFormScreenRedirect()));
          }),
          _quickAction(Icons.person_add, 'Add Customer', Colors.purple, () {
            _switchTab(context, 3);
          }),
          _quickAction(Icons.money_off, 'Add Expense', AppColors.red, () {
            ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Expenses — coming soon'), behavior: SnackBarBehavior.floating));
          }),
          _quickAction(Icons.description, 'New Invoice', Colors.teal, () {
            Navigator.push(context, MaterialPageRoute(builder: (_) => const InvoiceListScreen()));
          }),
          _quickAction(Icons.bar_chart, 'Reports', AppColors.brown, () {
            ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Reports — coming soon'), behavior: SnackBarBehavior.floating));
          }),
        ]),
        const SizedBox(height: 24),
        Text('Quick Settings', style: GoogleFonts.poppins(fontSize: 16, fontWeight: FontWeight.w600, color: isDark ? Colors.white : AppColors.brownDark)),
        const SizedBox(height: 10),
        Card(
          child: Column(children: [
            _settingsTile(Icons.palette, 'Theme', AppThemeModeExt.label(tm.mode), () {
              Navigator.push(context, MaterialPageRoute(builder: (_) => const SettingsScreen()));
            }),
            const Divider(height: 1, indent: 56),
            _settingsTile(Icons.store, 'Shop', business?.name ?? 'Not set', () {
              Navigator.push(context, MaterialPageRoute(builder: (_) => const SettingsScreen()));
            }),
            const Divider(height: 1, indent: 56),
            _settingsTile(Icons.policy, 'VAT Rate', '${((business?.vatRate ?? 0.15) * 100).toStringAsFixed(0)}%', () {
              Navigator.push(context, MaterialPageRoute(builder: (_) => const SettingsScreen()));
            }),
          ]),
        ),
        const SizedBox(height: 32),
      ]),
    );
  }

  String _greeting() => switch (DateTime.now().hour) { < 12 => 'Good Morning', < 17 => 'Good Afternoon', _ => 'Good Evening' };

  Widget _statCard(BuildContext context, String label, String value, IconData icon, Color color) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: isDark ? AppColors.cardDark : Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: isDark ? AppColors.surfaceDark : Colors.grey.shade200),
      ),
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [
          Text(label, style: GoogleFonts.poppins(fontSize: 12, color: Colors.grey.shade500)),
          Icon(icon, size: 18, color: color),
        ]),
        const SizedBox(height: 8),
        Text(value, style: GoogleFonts.poppins(fontSize: 22, fontWeight: FontWeight.bold, color: isDark ? Colors.white : AppColors.brownDark)),
      ]),
    );
  }

  Widget _quickAction(IconData icon, String label, Color color, VoidCallback onTap) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(14),
        child: Container(
          width: 100,
          padding: const EdgeInsets.symmetric(vertical: 14, horizontal: 6),
          decoration: BoxDecoration(color: color.withValues(alpha: 0.08), borderRadius: BorderRadius.circular(14)),
          child: Column(children: [
            Icon(icon, color: color, size: 24),
            const SizedBox(height: 6),
            Text(label, textAlign: TextAlign.center, style: GoogleFonts.poppins(fontSize: 11, fontWeight: FontWeight.w500, color: color)),
          ]),
        ),
      ),
    );
  }

  Widget _settingsTile(IconData icon, String title, String subtitle, VoidCallback onTap) {
    return ListTile(
      leading: CircleAvatar(radius: 18, backgroundColor: AppColors.orange.withValues(alpha: 0.1), child: Icon(icon, size: 18, color: AppColors.orange)),
      title: Text(title, style: GoogleFonts.poppins(fontWeight: FontWeight.w500, fontSize: 14)),
      subtitle: Text(subtitle, style: GoogleFonts.poppins(fontSize: 12, color: Colors.grey)),
      trailing: const Icon(Icons.chevron_right, size: 18),
      onTap: onTap,
    );
  }
}

void _switchTab(BuildContext context, int tab) {
  final state = context.findAncestorStateOfType<_DashboardScreenState>();
  state?.switchToTab(tab);
}
