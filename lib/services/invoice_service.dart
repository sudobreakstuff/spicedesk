import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:uuid/uuid.dart';
import '../models/invoice.dart';
import '../models/business.dart';
import '../models/order.dart';
import '../models/customer.dart';
import '../services/database_service.dart';
import '../services/pdf_invoice_generator.dart';

class InvoiceService {
  final SupabaseClient? _supabase;
  final _uuid = const Uuid();
  final PdfInvoiceGenerator _pdfGenerator = PdfInvoiceGenerator();

  InvoiceService({SupabaseClient? supabase}) : _supabase = supabase;

  Future<List<Invoice>> getInvoices(String businessId) async {
    final results = await DatabaseService.query(
      'invoices',
      where: 'business_id = ?',
      whereArgs: [businessId],
      orderBy: 'created_at DESC',
    );
    return results.map((e) => Invoice.fromMap(e)).toList();
  }

  Future<Invoice?> getInvoice(String invoiceId) async {
    final results = await DatabaseService.query(
      'invoices',
      where: 'id = ?',
      whereArgs: [invoiceId],
      limit: 1,
    );
    if (results.isNotEmpty) return Invoice.fromMap(results.first);
    return null;
  }

  Future<Invoice> createInvoice({
    required String businessId,
    String? orderId,
    String? customerId,
    required String invoiceNumber,
  }) async {
    final invoice = Invoice(
      id: _uuid.v4(),
      businessId: businessId,
      orderId: orderId,
      customerId: customerId,
      invoiceNumber: invoiceNumber,
      status: 'Draft',
      createdAt: DateTime.now(),
    );

    await DatabaseService.insert('invoices', invoice.toMap());

    final client = _supabase;
    if (client != null) {
      try { await client.from('invoices').upsert(invoice.toMap()); } catch (_) {}
    }

    return invoice;
  }

  Future<String> generatePdf({
    required Invoice invoice,
    required Business business,
    required OrderModel order,
    required List<OrderItem> items,
    Customer? customer,
  }) async {
    final path = await _pdfGenerator.generateInvoice(
      invoice: invoice,
      business: business,
      order: order,
      items: items,
      customer: customer,
    );

    final updated = invoice.copyWith(pdfPath: path, status: 'Sent');
    await DatabaseService.update('invoices', updated.toMap(), where: 'id = ?', whereArgs: [invoice.id]);

    final client = _supabase;
    if (client != null) {
      try { await client.from('invoices').upsert(updated.toMap()); } catch (_) {}
    }

    return path;
  }

  Future<void> updateStatus(String invoiceId, String status) async {
    await DatabaseService.update('invoices', {'status': status}, where: 'id = ?', whereArgs: [invoiceId]);

    final client = _supabase;
    if (client != null) {
      try { await client.from('invoices').update({'status': status}).eq('id', invoiceId); } catch (_) {}
    }
  }

  Future<String> generateInvoiceNumber(String prefix) async {
    final now = DateTime.now();
    final year = now.year.toString().substring(2);
    final month = now.month.toString().padLeft(2, '0');
    final day = now.day.toString().padLeft(2, '0');
    final random = _uuid.v4().substring(0, 4).toUpperCase();
    return '$prefix-$year$month$day-$random';
  }

  Future<Invoice?> createFromOrder({
    required String businessId,
    required String invoicePrefix,
    required String orderId,
    String? customerId,
  }) async {
    final invoiceNumber = await generateInvoiceNumber(invoicePrefix);
    return createInvoice(
      businessId: businessId,
      orderId: orderId,
      customerId: customerId,
      invoiceNumber: invoiceNumber,
    );
  }
}
