import 'dart:ui';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart' show Brightness;
import 'package:provider/provider.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:intl/intl.dart';
import '../../providers/business_provider.dart';
import '../../providers/theme_provider.dart';
import '../../providers/auth_provider.dart';
import '../../providers/product_provider.dart';
import '../../providers/customer_provider.dart';
import '../../providers/order_provider.dart';
import '../../core/glass_theme.dart';
import '../../core/constants.dart';
import '../pos/pos_screen.dart';
import '../inventory/product_list_screen.dart';
import '../customers/customer_list_screen.dart';
import '../orders/order_list_screen.dart';
import '../invoices/invoice_list_screen.dart';
import '../settings/settings_screen.dart';

class DashboardScreen extends StatefulWidget {
  const DashboardScreen({super.key});
  @override
  State<DashboardScreen> createState() => DashboardScreenState();
}

class DashboardScreenState extends State<DashboardScreen> {
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
    return CupertinoTabScaffold(
      tabBar: CupertinoTabBar(
        activeColor: GlassColors.primary,
        inactiveColor: GlassColors.lightText2,
        backgroundColor: context.isGlassDark ? GlassColors.darkCard : const Color(0xCCF2F2F7),
        border: Border(top: BorderSide(color: context.glassBorder.withValues(alpha: 0.3), width: 0.5)),
        items: const [
          BottomNavigationBarItem(icon: Icon(CupertinoIcons.house_fill), label: 'Home'),
          BottomNavigationBarItem(icon: Icon(CupertinoIcons.cart_fill), label: 'Sale'),
          BottomNavigationBarItem(icon: Icon(CupertinoIcons.cube_box_fill), label: 'Stock'),
          BottomNavigationBarItem(icon: Icon(CupertinoIcons.person_2_fill), label: 'CRM'),
          BottomNavigationBarItem(icon: Icon(CupertinoIcons.doc_text_fill), label: 'Orders'),
        ],
      ),
      tabBuilder: (ctx, index) {
        final child = switch (index) {
          0 => const _HomeTab(),
          1 => const PosScreen(),
          2 => const ProductListScreen(),
          3 => const CustomerListScreen(),
          4 => const OrderListScreen(),
          _ => const _HomeTab(),
        };
        return CupertinoTabView(builder: (_) => child);
      },
    );
  }
}

class _HomeTab extends StatelessWidget {
  const _HomeTab();

  @override
  Widget build(BuildContext context) {
    final bp = context.watch<BusinessProvider>();
    final op = context.watch<OrderProvider>();
    final pp = context.watch<ProductProvider>();
    final cp = context.watch<CustomerProvider>();
    final isDark = context.isGlassDark;
    final fmt = NumberFormat.currency(symbol: 'R ', decimalDigits: 2);

    return CupertinoPageScaffold(
      child: CustomScrollView(
        slivers: [
          CupertinoSliverNavigationBar(
            largeTitle: Text(bp.business?.name ?? 'SpiceDesk'),
            trailing: CupertinoButton(padding: EdgeInsets.zero, child: const Icon(CupertinoIcons.gear_alt), onPressed: () => Navigator.of(context, rootNavigator: true).push(CupertinoPageRoute(builder: (_) => const SettingsScreen()))),
          ),
          SliverPadding(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            sliver: SliverList(delegate: SliverChildListDelegate([
              const SizedBox(height: 8),

              // Stats
              Row(children: [
                Expanded(child: _Stat(title: 'Today', value: fmt.format(op.totalSalesToday), icon: CupertinoIcons.chart_bar_fill, color: GlassColors.primary, isDark: isDark)),
                const SizedBox(width: 10),
                Expanded(child: _Stat(title: 'Orders', value: '${op.totalOrders}', icon: CupertinoIcons.doc_text_fill, color: GlassColors.teal, isDark: isDark)),
              ]),
              const SizedBox(height: 10),
              Row(children: [
                Expanded(child: _Stat(title: 'Products', value: '${pp.totalProducts}', icon: CupertinoIcons.cube_fill, color: GlassColors.warning, isDark: isDark)),
                const SizedBox(width: 10),
                Expanded(child: _Stat(title: 'Customers', value: '${cp.totalCustomers}', icon: CupertinoIcons.person_2_fill, color: GlassColors.purple, isDark: isDark)),
              ]),
              const SizedBox(height: 24),

              // Quick Actions
              Text('Quick Actions'.toUpperCase(), style: TextStyle(fontSize: 12, fontWeight: FontWeight.w600, color: context.glassText2, letterSpacing: 1)),
              const SizedBox(height: 10),
              Row(children: [
                Expanded(child: _Action(CupertinoIcons.cart_fill, 'New Sale', GlassColors.primary, () => Navigator.of(context, rootNavigator: true).push(CupertinoPageRoute(builder: (_) => const PosScreen())))),
                const SizedBox(width: 8),
                Expanded(child: _Action(CupertinoIcons.add_circled_solid, 'Add Product', GlassColors.teal, () => Navigator.of(context, rootNavigator: true).push(CupertinoPageRoute(builder: (_) => const ProductListScreen())))),
                const SizedBox(width: 8),
                Expanded(child: _Action(CupertinoIcons.person_add_solid, 'Add Customer', GlassColors.purple, () => Navigator.of(context, rootNavigator: true).push(CupertinoPageRoute(builder: (_) => const CustomerListScreen())))),
              ]),
              const SizedBox(height: 8),
              Row(children: [
                Expanded(child: _Action(CupertinoIcons.doc_text_fill, 'Invoices', GlassColors.pink, () => Navigator.of(context, rootNavigator: true).push(CupertinoPageRoute(builder: (_) => const InvoiceListScreen())))),
                const SizedBox(width: 8),
                Expanded(child: _Action(CupertinoIcons.money_dollar_circle_fill, 'Expenses', GlassColors.warning, () => _snack(context, 'Coming soon'))),
                const SizedBox(width: 8),
                Expanded(child: _Action(CupertinoIcons.chart_bar_alt_fill, 'Reports', context.glassText2, () => _snack(context, 'Coming soon'))),
              ]),
              const SizedBox(height: 24),

              // Recent
              Text('Recent Orders'.toUpperCase(), style: TextStyle(fontSize: 12, fontWeight: FontWeight.w600, color: context.glassText2, letterSpacing: 1)),
              const SizedBox(height: 10),
              if (op.orders.isEmpty)
                Container(
                  padding: const EdgeInsets.all(24),
                  decoration: context.glassCard,
                  child: Column(children: [
                    Icon(CupertinoIcons.doc_text, size: 32, color: context.glassText3),
                    const SizedBox(height: 8),
                    const Text('No orders yet', style: TextStyle(fontSize: 13, color: GlassColors.lightText2)),
                    const SizedBox(height: 8),
                    CupertinoButton.filled(child: const Text('Make a Sale'), onPressed: () => Navigator.of(context, rootNavigator: true).push(CupertinoPageRoute(builder: (_) => const PosScreen())), sizeStyle: CupertinoButtonSize.small),
                  ]),
                )
              else
                ...op.orders.take(5).map((o) => _OrderRow(o: o, fmt: fmt, isDark: isDark)),
              const SizedBox(height: 80),
            ])),
          ),
        ],
      ),
    );
  }

  void _snack(BuildContext ctx, String msg) {
    showCupertinoDialog(context: ctx, builder: (_) => CupertinoAlertDialog(title: const Text('Coming Soon'), content: Text(msg), actions: [CupertinoDialogAction(child: const Text('OK'), onPressed: () => Navigator.pop(ctx))]));
    Future.delayed(const Duration(seconds: 1), () => Navigator.of(ctx).maybePop());
  }
}

void _goTab(int tab, BuildContext c) {
  // Tab switching via dashboard rebuild — handled by onTap in quick actions
}

class _Stat extends StatelessWidget {
  final String title, value; final IconData icon; final Color color; final bool isDark;
  const _Stat({required this.title, required this.value, required this.icon, required this.color, required this.isDark});
  @override
  Widget build(BuildContext c) => Container(
    padding: const EdgeInsets.all(14),
    decoration: GlassTheme.glassCard(isDark).copyWith(boxShadow: [GlassTheme.glassShadow(isDark)]),
    child: ClipRRect(
      borderRadius: BorderRadius.circular(14),
      child: BackdropFilter(filter: ImageFilter.blur(sigmaX: 10, sigmaY: 10), child: SizedBox(
        width: double.infinity,
        child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [
            Text(title, style: TextStyle(fontSize: 11, color: isDark ? GlassColors.darkText2 : GlassColors.lightText2)),
            Icon(icon, size: 16, color: color),
          ]),
          const SizedBox(height: 6),
          Text(value, style: TextStyle(fontSize: 20, fontWeight: FontWeight.w700, color: isDark ? GlassColors.darkText : GlassColors.lightText)),
        ]),
      )),
    ),
  );
}

class _Action extends StatelessWidget {
  final IconData icon; final String label; final Color color; final VoidCallback onTap;
  const _Action(this.icon, this.label, this.color, this.onTap);
  @override
  Widget build(BuildContext c) => GestureDetector(
    onTap: onTap,
    child: Container(
      padding: const EdgeInsets.symmetric(vertical: 14, horizontal: 8),
      decoration: GlassTheme.glassCard(c.isGlassDark),
      child: Column(children: [
        Icon(icon, color: color, size: 22),
        const SizedBox(height: 6),
        Text(label, style: TextStyle(fontSize: 11, fontWeight: FontWeight.w500, color: color), textAlign: TextAlign.center),
      ]),
    ),
  );
}

class _OrderRow extends StatelessWidget {
  final dynamic o; final NumberFormat fmt; final bool isDark;
  const _OrderRow({required this.o, required this.fmt, required this.isDark});
  @override
  Widget build(BuildContext c) {
    final date = DateFormat('dd/MM HH:mm').format(o.createdAt as DateTime);
    final statusColor = (o.status as String) == 'Completed' ? GlassColors.success : (o.status as String) == 'Cancelled' ? GlassColors.error : GlassColors.warning;
    return Container(
      margin: const EdgeInsets.only(bottom: 6),
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
      decoration: GlassTheme.glassCard(isDark),
      child: Row(children: [
        Container(width: 6, height: 6, decoration: BoxDecoration(shape: BoxShape.circle, color: statusColor)),
        const SizedBox(width: 10),
        Expanded(child: Text(o.orderType ?? '', style: TextStyle(fontSize: 13, fontWeight: FontWeight.w500))),
        Text(fmt.format((o.total as num).toDouble()), style: TextStyle(fontSize: 13, fontWeight: FontWeight.w600, color: GlassColors.primary)),
        const SizedBox(width: 10),
        Text(date, style: TextStyle(fontSize: 11, color: isDark ? GlassColors.darkText2 : GlassColors.lightText2)),
      ]),
    );
  }
}
