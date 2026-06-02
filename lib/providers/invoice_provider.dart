import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:share_plus/share_plus.dart';
import 'package:url_launcher/url_launcher.dart';
import '../models/invoice.dart';
import '../models/order.dart';
import '../models/customer.dart';
import '../models/business.dart';
import '../services/invoice_service.dart';

class InvoiceProvider extends ChangeNotifier {
  final InvoiceService _service;
  List<Invoice> _invoices = [];
  bool _loading = false;
  String? _error;

  InvoiceProvider(this._service);

  List<Invoice> get invoices => _invoices;
  bool get loading => _loading;
  String? get error => _error;
  int get totalInvoices => _invoices.length;

  Future<void> loadInvoices(String businessId) async {
    _loading = true;
    _error = null;
    notifyListeners();
    try {
      _invoices = await _service.getInvoices(businessId);
    } catch (e) {
      _error = e.toString();
    }
    _loading = false;
    notifyListeners();
  }

  Future<Invoice?> createFromOrder({
    required String businessId,
    required String invoicePrefix,
    required String orderId,
    String? customerId,
  }) async {
    _loading = true;
    notifyListeners();
    try {
      final invoice = await _service.createFromOrder(
        businessId: businessId,
        invoicePrefix: invoicePrefix,
        orderId: orderId,
        customerId: customerId,
      );
      if (invoice != null) _invoices.insert(0, invoice);
      _loading = false;
      notifyListeners();
      return invoice;
    } catch (e) {
      _error = e.toString();
      _loading = false;
      notifyListeners();
      return null;
    }
  }

  Future<String?> generatePdf({
    required Invoice invoice,
    required Business business,
    required OrderModel order,
    required List<OrderItem> items,
    Customer? customer,
  }) async {
    try {
      final path = await _service.generatePdf(
        invoice: invoice,
        business: business,
        order: order,
        items: items,
        customer: customer,
      );
      final index = _invoices.indexWhere((i) => i.id == invoice.id);
      if (index != -1) {
        _invoices[index] = _invoices[index].copyWith(status: 'Sent', pdfPath: path);
        notifyListeners();
      }
      return path;
    } catch (e) {
      _error = e.toString();
      notifyListeners();
      return null;
    }
  }

  Future<void> updateStatus(String invoiceId, String status) async {
    await _service.updateStatus(invoiceId, status);
    final index = _invoices.indexWhere((i) => i.id == invoiceId);
    if (index != -1) {
      _invoices[index] = _invoices[index].copyWith(status: status);
      notifyListeners();
    }
  }

  Future<void> shareInvoice(String pdfPath) async {
    if (pdfPath.isEmpty) return;
    final file = File(pdfPath);
    if (await file.exists()) {
      await Share.shareXFiles([XFile(pdfPath)], text: 'Invoice from SpiceDesk');
    }
  }

  Future<void> shareViaWhatsApp(String pdfPath, {String? phoneNumber}) async {
    if (pdfPath.isEmpty) return;
    final message = Uri.encodeComponent('Invoice from SpiceDesk');
    final number = phoneNumber?.replaceAll(RegExp(r'[^\d]'), '') ?? '';
    final uri = Uri.parse('https://wa.me/$number?text=$message');
    if (await canLaunchUrl(uri)) {
      await launchUrl(uri, mode: LaunchMode.externalApplication);
    }
  }

  Future<void> openPdf(String pdfPath) async {
    if (pdfPath.isEmpty) return;
    final file = File(pdfPath);
    if (await file.exists()) {
      await Share.shareXFiles([XFile(pdfPath)], text: 'Invoice');
    }
  }

  void clearError() {
    _error = null;
    notifyListeners();
  }
}
