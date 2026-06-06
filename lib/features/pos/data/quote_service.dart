import 'dart:ui';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../core/network/supabase_client.dart';
import '../../../features/workspace/domain/workspace_state.dart';
import 'pos_service.dart';

final createQuoteAction = Provider<Future<QuoteResult> Function({
  required List<SaleItemInput> items,
  String? customerId,
})>((ref) {
  return ({
    required List<SaleItemInput> items,
    String? customerId,
  }) async {
    final wsId = ref.read(workspaceStateProvider).selectedId;
    if (wsId == null) throw Exception('No workspace selected');

    final user = supabase.auth.currentUser;
    final subtotal = items.fold<double>(0, (sum, i) => sum + (i.unitPrice * i.quantity));
    final taxTotal = 0.0;

    final existing = await supabase
        .from('quotes')
        .select('quote_number')
        .eq('workspace_id', wsId)
        .order('created_at', ascending: false)
        .limit(1);

    int nextNum = 1;
    if (existing.isNotEmpty) {
      final lastNum = existing.first['quote_number'] as String?;
      if (lastNum != null && lastNum.startsWith('QTE-')) {
        final numPart = int.tryParse(lastNum.substring(4));
        if (numPart != null) nextNum = numPart + 1;
      }
    }
    final quoteNumber = 'QTE-${nextNum.toString().padLeft(4, '0')}';

    final result = await supabase.from('quotes').insert({
      'workspace_id': wsId,
      'quote_number': quoteNumber,
      'customer_id': customerId,
      'subtotal': subtotal,
      'tax_total': taxTotal,
      'total': subtotal + taxTotal,
      'status': 'draft',
      'valid_until': DateTime.now().add(Duration(days: 30)).toIso8601String(),
      'notes': null,
      'created_by': user?.id,
    }).select().single();

    final quoteId = result['id'] as String;

    for (final item in items) {
      final lineTotal = item.unitPrice * item.quantity;
      await supabase.from('quote_items').insert({
        'workspace_id': wsId,
        'quote_id': quoteId,
        'product_id': (item.productId != null && item.productId!.isNotEmpty) ? item.productId : null,
        'product_name': item.productName,
        'quantity': item.quantity,
        'unit_price': item.unitPrice,
        'line_total': lineTotal,
      });
    }

    return QuoteResult(
      quoteNumber: quoteNumber,
      total: subtotal + taxTotal,
      validUntil: DateTime.now().add(Duration(days: 30)),
    );
  };
});

final pendingQuotesProvider = FutureProvider<List<PendingQuote>>((ref) async {
  ref.watch(workspaceStateProvider);
  final wsId = ref.watch(workspaceStateProvider).selectedId;
  if (wsId == null) return [];

  final data = await supabase
      .from('quotes')
      .select('id, quote_number, total, status, created_at, customer_id, customers(name)')
      .eq('workspace_id', wsId)
      .neq('status', 'accepted')
      .neq('status', 'rejected')
      .order('created_at', ascending: false)
      .limit(5);

  return data.map<PendingQuote>((row) {
    final customer = row['customers'] as Map<String, dynamic>?;
    return PendingQuote(
      id: row['id'],
      quoteNumber: row['quote_number'] ?? '',
      total: (row['total'] as num?)?.toDouble() ?? 0,
      status: row['status'] ?? 'draft',
      customerName: customer?['name'],
      createdAt: row['created_at'] != null
          ? DateTime.tryParse(row['created_at'] ?? '') ?? DateTime.now()
          : DateTime.now(),
    );
  }).toList();
});

class QuoteResult {
  final String quoteNumber;
  final double total;
  final DateTime validUntil;

  QuoteResult({
    required this.quoteNumber,
    required this.total,
    required this.validUntil,
  });
}

class PendingQuote {
  final String id;
  final String quoteNumber;
  final double total;
  final String status;
  final String? customerName;
  final DateTime createdAt;

  PendingQuote({
    required this.id,
    required this.quoteNumber,
    required this.total,
    required this.status,
    this.customerName,
    required this.createdAt,
  });

  String get displayStatus {
    switch (status) {
      case 'draft':
        return 'Draft';
      case 'sent':
        return 'Sent';
      case 'accepted':
        return 'Accepted';
      case 'rejected':
        return 'Rejected';
      default:
        return status[0].toUpperCase() + status.substring(1);
    }
  }

  Color get statusColor {
    switch (status) {
      case 'draft':
        return Color(0xFF8B949E);
      case 'sent':
        return Color(0xFF6366F1);
      case 'accepted':
        return Color(0xFF238636);
      case 'rejected':
        return Color(0xFFDA3633);
      default:
        return Color(0xFF8B949E);
    }
  }
}
