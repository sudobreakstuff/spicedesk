import 'package:uuid/uuid.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../models/invoice.dart';
import '../models/business.dart';
import '../models/order.dart';
import '../models/customer.dart';
import 'database_service.dart';
import 'pdf_invoice_generator.dart';

class InvoiceService {
  final SupabaseClient? _supabase;
  final _uuid = const Uuid();
  final PdfInvoiceGenerator _pdfGenerator = PdfInvoiceGenerator();
  InvoiceService({SupabaseClient? supabase}) : _supabase = supabase;

  Future<List<Invoice>> getInvoices(String businessId) async {
    final rows = await DatabaseService.query('SELECT * FROM invoices WHERE business_id = ? ORDER BY created_at DESC', [businessId]);
    return rows.map((r) => Invoice.fromMap(r)).toList();
  }

  Future<Invoice?> getInvoice(String id) async {
    final rows = await DatabaseService.query('SELECT * FROM invoices WHERE id = ?', [id]);
    if (rows.isEmpty) return null;
    return Invoice.fromMap(rows.first);
  }

  Future<Invoice> createInvoice({required String businessId, String? orderId, String? customerId, required String invoiceNumber, required String status}) async {
    final id = _uuid.v4();
    final now = DateTime.now();
    final invoice = Invoice(id: id, businessId: businessId, orderId: orderId, customerId: customerId, invoiceNumber: invoiceNumber, status: status, createdAt: now);
    await DatabaseService.insert('invoices', invoice.toMap());
    final supabase = _supabase;
    if (supabase != null) { try { await supabase.from('invoices').insert(invoice.toMap()); } catch (_) {} }
    return invoice;
  }

  Future<String> generatePdf({required Invoice invoice, required Business business, OrderModel? order, required List<OrderItem> items, Customer? customer}) async {
    final pdfPath = await _pdfGenerator.generateInvoice(invoice: invoice, business: business, order: order, items: items, customer: customer);
    final updated = invoice.copyWith(pdfPath: pdfPath);
    await DatabaseService.update('invoices', updated.toMap(), where: 'id = ?', whereArgs: [invoice.id]);
    return pdfPath;
  }

  Future<void> updateStatus(String id, String status) async {
    await DatabaseService.update('invoices', {'status': status}, where: 'id = ?', whereArgs: [id]);
    final supabase = _supabase;
    if (supabase != null) { try { await supabase.from('invoices').update({'status': status}).eq('id', id); } catch (_) {} }
  }

  Future<String> generateInvoiceNumber(String? prefix) async {
    final now = DateTime.now();
    final year = now.year.toString().substring(2);
    final month = now.month.toString().padLeft(2, '0');
    final rows = await DatabaseService.query('SELECT COUNT(*) as count FROM invoices WHERE created_at LIKE ?', ['${now.year}-${now.month.toString().padLeft(2, '0')}%']);
    final count = ((rows.first['count'] as num?)?.toInt() ?? 0) + 1;
    final seq = count.toString().padLeft(4, '0');
    final pre = (prefix != null && prefix.isNotEmpty) ? '$prefix-' : 'INV-';
    return '$pre$year$month-$seq';
  }

  Future<Invoice> createFromOrder({required String businessId, required String invoicePrefix, required String orderId, String? customerId}) async {
    final number = await generateInvoiceNumber(invoicePrefix);
    return createInvoice(businessId: businessId, orderId: orderId, customerId: customerId, invoiceNumber: number, status: 'Draft');
  }
}
