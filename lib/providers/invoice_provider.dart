import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:share_plus/share_plus.dart';
import 'package:url_launcher/url_launcher.dart';
import '../models/invoice.dart';
import '../models/business.dart';
import '../models/order.dart';
import '../models/customer.dart';
import '../services/invoice_service.dart';

class InvoiceProvider extends ChangeNotifier {
  final InvoiceService _svc;
  List<Invoice> _invoices = [];
  bool _loading = false;
  String? _error;

  InvoiceProvider(this._svc);

  List<Invoice> get invoices => _invoices;
  bool get loading => _loading;
  String? get error => _error;

  Future<void> loadInvoices(String bizId) async {
    _loading = true; notifyListeners();
    _invoices = await _svc.getInvoices(bizId);
    _loading = false; notifyListeners();
  }

  Future<Invoice?> createFromOrder({required String businessId, required String invoicePrefix, required String orderId, String? customerId}) async {
    try {
      final inv = await _svc.createFromOrder(businessId: businessId, invoicePrefix: invoicePrefix, orderId: orderId, customerId: customerId);
      if (inv != null) _invoices.insert(0, inv);
      notifyListeners(); return inv;
    } catch (e) { _error = e.toString(); notifyListeners(); return null; }
  }

  Future<String?> generatePdf({required Invoice invoice, required Business business, required OrderModel order, required List<OrderItem> items, Customer? customer}) async {
    try {
      final path = await _svc.generatePdf(invoice: invoice, business: business, order: order, items: items, customer: customer);
      final i = _invoices.indexWhere((x) => x.id == invoice.id);
      if (i != -1) _invoices[i] = _invoices[i].copyWith(status: 'Sent', pdfPath: path);
      notifyListeners(); return path;
    } catch (e) { _error = e.toString(); notifyListeners(); return null; }
  }

  Future<void> updateStatus(String id, String status) async {
    await _svc.updateStatus(id, status);
    final i = _invoices.indexWhere((x) => x.id == id);
    if (i != -1) _invoices[i] = _invoices[i].copyWith(status: status); notifyListeners();
  }

  Future<void> shareInvoice(String path) async {
    if (path.isNotEmpty && File(path).existsSync()) await Share.shareXFiles([XFile(path)]);
  }

  Future<void> shareViaWhatsApp(String path, {String? phone}) async {
    final uri = Uri.parse('https://wa.me/${phone ?? ''}?text=Invoice');
    if (await canLaunchUrl(uri)) await launchUrl(uri, mode: LaunchMode.externalApplication);
  }

  Future<void> openPdf(String path) async {
    if (path.isNotEmpty && File(path).existsSync()) await Share.shareXFiles([XFile(path)]);
  }
}
