import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../providers/order_provider.dart';
import '../../providers/business_provider.dart';
import '../../models/order.dart';
import '../../core/theme.dart';
import '../../core/constants.dart';

class OrderListScreen extends StatefulWidget {
  const OrderListScreen({super.key});

  @override
  State<OrderListScreen> createState() => _OrderListScreenState();
}

class _OrderListScreenState extends State<OrderListScreen> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) => _loadData());
  }

  void _loadData() {
    final business = context.read<BusinessProvider>().business;
    if (business != null) {
      context.read<OrderProvider>().loadOrders(business.id);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Orders'),
        actions: [
          IconButton(
            icon: const Icon(Icons.filter_alt_outlined),
            onPressed: _showFilterSheet,
          ),
        ],
      ),
      body: _buildList(),
    );
  }

  void _showFilterSheet() {
    final provider = context.read<OrderProvider>();
    showModalBottomSheet(
      context: context,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (ctx) => SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(20),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text('Filter Orders', style: GoogleFonts.poppins(fontSize: 18, fontWeight: FontWeight.w600)),
              const SizedBox(height: 16),
              Text('Status', style: GoogleFonts.poppins(fontWeight: FontWeight.w600, fontSize: 13)),
              const SizedBox(height: 8),
              Wrap(
                spacing: 8,
                children: [
                  ChoiceChip(
                    label: const Text('All'),
                    selected: provider.orders.isEmpty || true,
                    onSelected: (_) { provider.setStatusFilter(null); Navigator.pop(ctx); },
                    selectedColor: AppTheme.spiceOrange.withOpacity(0.2),
                  ),
                  ...AppConstants.orderStatuses.map((s) => ChoiceChip(
                    label: Text(s),
                    selected: provider.orders.any((o) => o.status == s),
                    onSelected: (_) { provider.setStatusFilter(s); Navigator.pop(ctx); },
                    selectedColor: AppTheme.spiceOrange.withOpacity(0.2),
                  )),
                ],
              ),
              const SizedBox(height: 16),
              Text('Order Type', style: GoogleFonts.poppins(fontWeight: FontWeight.w600, fontSize: 13)),
              const SizedBox(height: 8),
              Wrap(
                spacing: 8,
                children: AppConstants.orderTypes.map((t) => ChoiceChip(
                  label: Text(t),
                  selected: false,
                  onSelected: (_) { provider.setTypeFilter(t); Navigator.pop(ctx); },
                  selectedColor: AppTheme.spiceOrange.withOpacity(0.2),
                )).toList(),
              ),
              const SizedBox(height: 16),
              SizedBox(
                width: double.infinity,
                child: OutlinedButton(
                  onPressed: () {
                    provider.clearFilters();
                    Navigator.pop(ctx);
                    _loadData();
                  },
                  child: const Text('Clear Filters'),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildList() {
    return Consumer<OrderProvider>(
      builder: (context, provider, _) {
        if (provider.loading && provider.orders.isEmpty) {
          return const Center(child: CircularProgressIndicator());
        }
        if (provider.orders.isEmpty) {
          return Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(Icons.receipt_long, size: 64, color: Colors.grey[300]),
                const SizedBox(height: 12),
                Text('No orders yet', style: GoogleFonts.poppins(color: Colors.grey[500], fontSize: 16)),
                const SizedBox(height: 4),
                Text('Complete a sale in POS to see orders', style: GoogleFonts.poppins(color: Colors.grey[400], fontSize: 13)),
              ],
            ),
          );
        }

        return ListView.builder(
          padding: const EdgeInsets.all(12),
          itemCount: provider.orders.length,
          itemBuilder: (context, index) {
            final order = provider.orders[index];
            return _OrderCard(order: order);
          },
        );
      },
    );
  }
}

class _OrderCard extends StatefulWidget {
  final OrderModel order;
  const _OrderCard({required this.order});

  @override
  State<_OrderCard> createState() => _OrderCardState();
}

class _OrderCardState extends State<_OrderCard> {
  bool _expanded = false;
  List<OrderItem>? _items;

  Future<void> _loadItems() async {
    final provider = context.read<OrderProvider>();
    _items = await provider.getOrderItems(widget.order.id);
    setState(() {});
  }

  Color _statusColor(String status) {
    switch (status) {
      case 'Completed': return AppTheme.successGreen;
      case 'Cancelled': return AppTheme.dangerRed;
      case 'Pending': return AppTheme.spiceYellow;
      case 'Preparing': return AppTheme.spiceOrange;
      case 'Ready': return Colors.blue;
      case 'Delivered': return AppTheme.spiceBrown;
      default: return Colors.grey;
    }
  }

  @override
  Widget build(BuildContext context) {
    final order = widget.order;
    return Card(
      margin: const EdgeInsets.only(bottom: 8),
      child: InkWell(
        onTap: () {
          setState(() {
            _expanded = !_expanded;
            if (_expanded && _items == null) _loadItems();
          });
        },
        borderRadius: BorderRadius.circular(16),
        child: Padding(
          padding: const EdgeInsets.all(12),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                    decoration: BoxDecoration(
                      color: _statusColor(order.status).withOpacity(0.1),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Text(
                      order.status,
                      style: GoogleFonts.poppins(
                        fontSize: 11,
                        fontWeight: FontWeight.w600,
                        color: _statusColor(order.status),
                      ),
                    ),
                  ),
                  const SizedBox(width: 8),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                    decoration: BoxDecoration(
                      color: Colors.grey.shade100,
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Text(
                      order.orderType,
                      style: GoogleFonts.poppins(fontSize: 11, color: Colors.grey[700]),
                    ),
                  ),
                  const Spacer(),
                  Text(
                    AppConstants.formatCurrency(order.total),
                    style: GoogleFonts.poppins(
                      fontWeight: FontWeight.bold,
                      fontSize: 16,
                      color: AppTheme.spiceOrange,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 6),
              Row(
                children: [
                  Icon(Icons.payment, size: 14, color: Colors.grey[500]),
                  const SizedBox(width: 4),
                  Text(order.paymentMethod,
                      style: GoogleFonts.poppins(fontSize: 12, color: Colors.grey[600])),
                  const Spacer(),
                  Text(
                    _formatDate(order.createdAt),
                    style: GoogleFonts.poppins(fontSize: 11, color: Colors.grey[500]),
                  ),
                ],
              ),
              if (_expanded && _items != null) ...[
                const Divider(height: 16),
                ...?_items?.map((item) => Padding(
                  padding: const EdgeInsets.symmetric(vertical: 3),
                  child: Row(
                    children: [
                      Expanded(
                        child: Text(item.productName,
                            style: GoogleFonts.poppins(fontSize: 13)),
                      ),
                      Text('x${item.qty}',
                          style: GoogleFonts.poppins(fontSize: 12, color: Colors.grey[600])),
                      const SizedBox(width: 12),
                      Text(AppConstants.formatCurrency(item.total),
                          style: GoogleFonts.poppins(fontSize: 13, fontWeight: FontWeight.w500)),
                    ],
                  ),
                )),
                const SizedBox(height: 6),
                Row(
                  children: [
                    Expanded(
                      child: _StatusActionButton(
                        order: order,
                        label: 'Complete',
                        color: AppTheme.successGreen,
                        onTap: () => context.read<OrderProvider>().updateStatus(order.id, 'Completed'),
                      ),
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: _StatusActionButton(
                        order: order,
                        label: 'Cancel',
                        color: AppTheme.dangerRed,
                        onTap: () => context.read<OrderProvider>().updateStatus(order.id, 'Cancelled'),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 4),
                SizedBox(
                  width: double.infinity,
                  child: OutlinedButton.icon(
                    onPressed: () => _shareViaWhatsApp(order),
                    icon: const Icon(Icons.whatshot, size: 16, color: Color(0xFF25D366)),
                    label: const Text('Share via WhatsApp', style: TextStyle(fontSize: 13)),
                    style: OutlinedButton.styleFrom(
                      minimumSize: const Size(double.infinity, 36),
                    ),
                  ),
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }

  void _shareViaWhatsApp(OrderModel order) async {
    final provider = context.read<OrderProvider>();
    final items = await provider.getOrderItems(order.id);

    final message = 'SpiceDesk Order\n'
        '${'─' * 20}\n'
        'Order: ${order.id.substring(0, 8).toUpperCase()}\n'
        'Date: ${_formatDate(order.createdAt)}\n'
        'Type: ${order.orderType}\n'
        '${'─' * 20}\n'
        '${items.map((i) => '${i.productName} x${i.qty} = ${AppConstants.formatCurrency(i.total)}').join('\n')}\n'
        '${'─' * 20}\n'
        'Subtotal: ${AppConstants.formatCurrency(order.subtotal)}\n'
        'VAT (15%): ${AppConstants.formatCurrency(order.taxAmount)}\n'
        'Total: ${AppConstants.formatCurrency(order.total)}\n'
        'Payment: ${order.paymentMethod}';

    final uri = Uri.parse('https://wa.me/?text=${Uri.encodeComponent(message)}');
    if (await canLaunchUrl(uri)) {
      await launchUrl(uri, mode: LaunchMode.externalApplication);
    }
  }

  String _formatDate(DateTime dt) {
    return '${dt.day.toString().padLeft(2, '0')}/${dt.month.toString().padLeft(2, '0')}/${dt.year} ${dt.hour.toString().padLeft(2, '0')}:${dt.minute.toString().padLeft(2, '0')}';
  }
}

class _StatusActionButton extends StatelessWidget {
  final OrderModel order;
  final String label;
  final Color color;
  final VoidCallback onTap;

  const _StatusActionButton({
    required this.order,
    required this.label,
    required this.color,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: 32,
      child: OutlinedButton(
        onPressed: onTap,
        style: OutlinedButton.styleFrom(
          foregroundColor: color,
          side: BorderSide(color: color.withOpacity(0.3)),
          padding: EdgeInsets.zero,
          minimumSize: const Size(0, 32),
        ),
        child: Text(label, style: const TextStyle(fontSize: 12)),
      ),
    );
  }
}
