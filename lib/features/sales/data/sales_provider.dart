import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../core/network/supabase_client.dart';
import '../../../features/workspace/domain/workspace_state.dart';

final salesProvider = FutureProvider<List<SaleTransaction>>((ref) async {
  ref.watch(workspaceStateProvider);
  final wsId = ref.watch(workspaceStateProvider).selectedId;
  if (wsId == null) return [];

  final data = await supabase
      .from('sales_transactions')
      .select(
          'id, transaction_number, invoice_number, grand_total, payment_method, created_at, customers(name)')
      .eq('workspace_id', wsId)
      .order('created_at', ascending: false)
      .limit(50);

  return data.map<SaleTransaction>((row) {
    final customer = row['customers'] as Map<String, dynamic>?;
    return SaleTransaction(
      id: row['id'],
      transactionNumber: row['transaction_number'] ?? '',
      invoiceNumber: row['invoice_number'],
      total: (row['grand_total'] as num?)?.toDouble() ?? 0,
      paymentMethod: row['payment_method'] ?? '',
      customerName: customer?['name'],
      createdAt: row['created_at'] != null
          ? DateTime.tryParse(row['created_at']) ?? DateTime.now()
          : DateTime.now(),
    );
  }).toList();
});

final todaySalesProvider = FutureProvider<double>((ref) async {
  ref.watch(workspaceStateProvider);
  final wsId = ref.watch(workspaceStateProvider).selectedId;
  if (wsId == null) return 0;

  final today = DateTime.now().toIso8601String().split('T')[0];
  final data = await supabase
      .from('sales_transactions')
      .select('grand_total')
      .eq('workspace_id', wsId)
      .gte('created_at', '$today 00:00:00')
      .lte('created_at', '$today 23:59:59');

  double total = 0;
  for (final row in data) {
    total += (row['grand_total'] as num?)?.toDouble() ?? 0;
  }
  return total;
});

final dailySalesProvider = FutureProvider<DailySalesReport>((ref) async {
  ref.watch(workspaceStateProvider);
  final wsId = ref.watch(workspaceStateProvider).selectedId;
  if (wsId == null) return DailySalesReport.empty();

  final today = DateTime.now().toIso8601String().split('T')[0];
  final data = await supabase
      .from('sales_transactions')
      .select('grand_total, created_at')
      .eq('workspace_id', wsId)
      .gte('created_at', '$today 00:00:00')
      .order('created_at');

  final hourlyMap = <int, double>{};
  for (int i = 0; i < 24; i++) {
    hourlyMap[i] = 0;
  }

  double totalSales = 0;
  for (final row in data) {
    final total = (row['grand_total'] as num?)?.toDouble() ?? 0;
    totalSales += total;
    final dt = row['created_at'] != null
        ? DateTime.tryParse(row['created_at'] ?? '')
        : null;
    if (dt != null) {
      hourlyMap[dt.hour] = (hourlyMap[dt.hour] ?? 0) + total;
    }
  }

  double totalCost = 0;
  try {
    final costData = await supabase
        .from('sale_items')
        .select('quantity, products!inner(cost_price)')
        .eq('workspace_id', wsId)
        .gte('sales_transactions.created_at', '$today 00:00:00')
        .lte('sales_transactions.created_at', '$today 23:59:59');
    for (final row in costData) {
      final quantity = (row['quantity'] as num?)?.toDouble() ?? 0;
      final costPrice =
          (row['products']?['cost_price'] as num?)?.toDouble() ?? 0;
      totalCost += costPrice * quantity;
    }
  } catch (_) {}

  return DailySalesReport(
    totalSales: totalSales,
    transactionCount: data.length,
    hourlyBreakdown: hourlyMap,
    totalCost: totalCost,
  );
});

final weeklySalesProvider = FutureProvider<WeeklySalesReport>((ref) async {
  ref.watch(workspaceStateProvider);
  final wsId = ref.watch(workspaceStateProvider).selectedId;
  if (wsId == null) return WeeklySalesReport.empty();

  final now = DateTime.now();
  final startOfRange =
      DateTime(now.year, now.month, now.day).subtract(Duration(days: 6));
  final startStr = startOfRange.toIso8601String().split('T')[0];

  final data = await supabase
      .from('sales_transactions')
      .select('grand_total, created_at')
      .eq('workspace_id', wsId)
      .gte('created_at', '$startStr 00:00:00')
      .order('created_at');

  const dayLabels = ['Mon', 'Tue', 'Wed', 'Thu', 'Fri', 'Sat', 'Sun'];
  final dailyMap = <String, double>{};
  for (final label in dayLabels) {
    dailyMap[label] = 0;
  }

  double totalSales = 0;
  for (final row in data) {
    final total = (row['grand_total'] as num?)?.toDouble() ?? 0;
    totalSales += total;
    final dt = row['created_at'] != null
        ? DateTime.tryParse(row['created_at'] ?? '')
        : null;
    if (dt != null) {
      dailyMap[dayLabels[dt.weekday - 1]] =
          (dailyMap[dayLabels[dt.weekday - 1]] ?? 0) + total;
    }
  }

  String bestDay = 'Mon';
  double bestTotal = 0;
  for (final entry in dailyMap.entries) {
    if (entry.value > bestTotal) {
      bestTotal = entry.value;
      bestDay = entry.key;
    }
  }

  final todayStr = now.toIso8601String().split('T')[0];
  double totalCost = 0;
  try {
    final costData = await supabase
        .from('sale_items')
        .select('quantity, products!inner(cost_price)')
        .eq('workspace_id', wsId)
        .gte('sales_transactions.created_at', '$startStr 00:00:00')
        .lte('sales_transactions.created_at', '$todayStr 23:59:59');
    for (final row in costData) {
      final quantity = (row['quantity'] as num?)?.toDouble() ?? 0;
      final costPrice =
          (row['products']?['cost_price'] as num?)?.toDouble() ?? 0;
      totalCost += costPrice * quantity;
    }
  } catch (_) {}

  return WeeklySalesReport(
    totalSales: totalSales,
    avgPerDay: totalSales / 7,
    bestDay: bestDay,
    transactionCount: data.length,
    dailyBreakdown: dailyMap,
    totalCost: totalCost,
  );
});

final monthlySalesProvider = FutureProvider<MonthlySalesReport>((ref) async {
  ref.watch(workspaceStateProvider);
  final wsId = ref.watch(workspaceStateProvider).selectedId;
  if (wsId == null) return MonthlySalesReport.empty();

  final now = DateTime.now();
  final startOfMonth = DateTime(now.year, now.month, 1);
  final startStr = startOfMonth.toIso8601String().split('T')[0];

  final data = await supabase
      .from('sales_transactions')
      .select('grand_total, created_at')
      .eq('workspace_id', wsId)
      .gte('created_at', '$startStr 00:00:00')
      .order('created_at');

  final daysInMonth = DateTime(now.year, now.month + 1, 0).day;
  final numWeeks = (daysInMonth / 7).ceil();
  final weeklyMap = <String, double>{};
  for (int w = 1; w <= numWeeks; w++) {
    weeklyMap['Week $w'] = 0;
  }

  double totalSales = 0;
  for (final row in data) {
    final total = (row['grand_total'] as num?)?.toDouble() ?? 0;
    totalSales += total;
    final dt = row['created_at'] != null
        ? DateTime.tryParse(row['created_at'] ?? '')
        : null;
    if (dt != null) {
      final weekNum = ((dt.day - 1) ~/ 7) + 1;
      final key = 'Week $weekNum';
      weeklyMap[key] = (weeklyMap[key] ?? 0) + total;
    }
  }

  final todayStr = now.toIso8601String().split('T')[0];
  double totalCost = 0;
  try {
    final costData = await supabase
        .from('sale_items')
        .select('quantity, products!inner(cost_price)')
        .eq('workspace_id', wsId)
        .gte('sales_transactions.created_at', '$startStr 00:00:00')
        .lte('sales_transactions.created_at', '$todayStr 23:59:59');
    for (final row in costData) {
      final quantity = (row['quantity'] as num?)?.toDouble() ?? 0;
      final costPrice =
          (row['products']?['cost_price'] as num?)?.toDouble() ?? 0;
      totalCost += costPrice * quantity;
    }
  } catch (_) {}

  return MonthlySalesReport(
    totalSales: totalSales,
    avgPerWeek: numWeeks > 0 ? totalSales / numWeeks : 0,
    dailyAverage: daysInMonth > 0 ? totalSales / daysInMonth : 0,
    transactionCount: data.length,
    weeklyBreakdown: weeklyMap,
    totalCost: totalCost,
  );
});

final totalTransactionsProvider = FutureProvider<int>((ref) async {
  ref.watch(workspaceStateProvider);
  final wsId = ref.watch(workspaceStateProvider).selectedId;
  if (wsId == null) return 0;

  final data = await supabase
      .from('sales_transactions')
      .select('id')
      .eq('workspace_id', wsId);

  return data.length;
});

class SaleTransaction {
  final String id;
  final String transactionNumber;
  final String? invoiceNumber;
  final double total;
  final String paymentMethod;
  final String? customerName;
  final DateTime createdAt;

  SaleTransaction({
    required this.id,
    required this.transactionNumber,
    this.invoiceNumber,
    required this.total,
    required this.paymentMethod,
    this.customerName,
    required this.createdAt,
  });
}

class DailySalesReport {
  final double totalSales;
  final int transactionCount;
  final Map<int, double> hourlyBreakdown;
  final double totalCost;

  DailySalesReport({
    required this.totalSales,
    required this.transactionCount,
    required this.hourlyBreakdown,
    this.totalCost = 0,
  });

  factory DailySalesReport.empty() => DailySalesReport(
        totalSales: 0,
        transactionCount: 0,
        hourlyBreakdown: {for (int i = 0; i < 24; i++) i: 0.0},
        totalCost: 0,
      );

  double get averageOrderValue =>
      transactionCount > 0 ? totalSales / transactionCount : 0;

  double get totalProfit => totalSales - totalCost;
  double get profitMargin =>
      totalSales > 0 ? (totalProfit / totalSales * 100) : 0;

  int get topHour => (hourlyBreakdown.entries.toList()
        ..sort((a, b) => b.value.compareTo(a.value)))
      .first
      .key;
}

class WeeklySalesReport {
  final double totalSales;
  final double avgPerDay;
  final String bestDay;
  final int transactionCount;
  final Map<String, double> dailyBreakdown;
  final double totalCost;

  WeeklySalesReport({
    required this.totalSales,
    required this.avgPerDay,
    required this.bestDay,
    required this.transactionCount,
    required this.dailyBreakdown,
    this.totalCost = 0,
  });

  factory WeeklySalesReport.empty() => WeeklySalesReport(
        totalSales: 0,
        avgPerDay: 0,
        bestDay: 'Mon',
        transactionCount: 0,
        dailyBreakdown: {},
        totalCost: 0,
      );

  double get totalProfit => totalSales - totalCost;
  double get profitMargin =>
      totalSales > 0 ? (totalProfit / totalSales * 100) : 0;
}

class MonthlySalesReport {
  final double totalSales;
  final double avgPerWeek;
  final double dailyAverage;
  final int transactionCount;
  final Map<String, double> weeklyBreakdown;
  final double totalCost;

  MonthlySalesReport({
    required this.totalSales,
    required this.avgPerWeek,
    required this.dailyAverage,
    required this.transactionCount,
    required this.weeklyBreakdown,
    this.totalCost = 0,
  });

  factory MonthlySalesReport.empty() => MonthlySalesReport(
        totalSales: 0,
        avgPerWeek: 0,
        dailyAverage: 0,
        transactionCount: 0,
        weeklyBreakdown: {},
        totalCost: 0,
      );

  double get totalProfit => totalSales - totalCost;
  double get profitMargin =>
      totalSales > 0 ? (totalProfit / totalSales * 100) : 0;
}

final profitProvider = FutureProvider<ProfitReport>((ref) async {
  ref.watch(workspaceStateProvider);
  final wsId = ref.watch(workspaceStateProvider).selectedId;
  if (wsId == null) return ProfitReport.zero();

  final data = await supabase
      .from('sale_items')
      .select('quantity, unit_price, line_total, products!inner(cost_price)')
      .eq('workspace_id', wsId);

  double totalRevenue = 0;
  double totalCost = 0;
  int totalItems = 0;

  for (final row in data) {
    final lineTotal = (row['line_total'] as num?)?.toDouble() ?? 0;
    final quantity = (row['quantity'] as num?)?.toDouble() ?? 0;
    final costPrice =
        (row['products']?['cost_price'] as num?)?.toDouble() ?? 0;

    totalRevenue += lineTotal;
    totalCost += costPrice * quantity;
    totalItems += 1;
  }

  return ProfitReport(
    totalRevenue: totalRevenue,
    totalCost: totalCost,
    totalProfit: totalRevenue - totalCost,
    profitMargin: totalRevenue > 0
        ? ((totalRevenue - totalCost) / totalRevenue * 100)
        : 0,
    totalItemsSold: totalItems,
  );
});

class ProfitReport {
  final double totalRevenue;
  final double totalCost;
  final double totalProfit;
  final double profitMargin;
  final int totalItemsSold;

  ProfitReport({
    required this.totalRevenue,
    required this.totalCost,
    required this.totalProfit,
    required this.profitMargin,
    required this.totalItemsSold,
  });

  factory ProfitReport.zero() => ProfitReport(
        totalRevenue: 0,
        totalCost: 0,
        totalProfit: 0,
        profitMargin: 0,
        totalItemsSold: 0,
      );
}

final bestSellersProvider = FutureProvider<List<BestSeller>>((ref) async {
  ref.watch(workspaceStateProvider);
  final wsId = ref.watch(workspaceStateProvider).selectedId;
  if (wsId == null) return [];

  final data = await supabase
      .from('sale_items')
      .select('product_id, product_name, quantity, line_total')
      .eq('workspace_id', wsId);

  final Map<String, BestSeller> grouped = {};
  for (final row in data) {
    final pid = row['product_id'] as String;
    final qty = (row['quantity'] as num?)?.toDouble() ?? 0;
    final revenue = (row['line_total'] as num?)?.toDouble() ?? 0;

    if (grouped.containsKey(pid)) {
      grouped[pid] = BestSeller(
        productId: pid,
        productName: row['product_name'] ?? grouped[pid]!.productName,
        totalQuantity: grouped[pid]!.totalQuantity + qty,
        totalRevenue: grouped[pid]!.totalRevenue + revenue,
      );
    } else {
      grouped[pid] = BestSeller(
        productId: pid,
        productName: row['product_name'] ?? 'Unknown',
        totalQuantity: qty,
        totalRevenue: revenue,
      );
    }
  }

  final sorted = grouped.values.toList()
    ..sort((a, b) => b.totalQuantity.compareTo(a.totalQuantity));

  return sorted.take(5).toList();
});

class BestSeller {
  final String productId;
  final String productName;
  final double totalQuantity;
  final double totalRevenue;

  BestSeller({
    required this.productId,
    required this.productName,
    required this.totalQuantity,
    required this.totalRevenue,
  });
}
