import 'dart:io';
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:path_provider/path_provider.dart';
import 'package:intl/intl.dart';
import '../models/business.dart';
import '../models/invoice.dart';
import '../models/order.dart';
import '../models/customer.dart';

class PdfInvoiceGenerator {
  static final _currencyFormat = NumberFormat.currency(symbol: 'R ', decimalDigits: 2);

  Future<String> generateInvoice({
    required Invoice invoice,
    required Business business,
    required OrderModel order,
    required List<OrderItem> items,
    Customer? customer,
  }) async {
    final pdf = pw.Document();
    final dateStr = DateFormat('dd MMMM yyyy').format(invoice.createdAt);
    final timeStr = DateFormat('HH:mm').format(invoice.createdAt);

    final tableRows = <pw.TableRow>[];

    tableRows.add(
      pw.TableRow(
        decoration: pw.BoxDecoration(color: PdfColor.fromHex('#E67E22')),
        children: [
          _headerCell('Item'),
          _headerCell('Qty'),
          _headerCell('Price'),
          _headerCell('Total'),
        ],
      ),
    );

    for (final item in items) {
      tableRows.add(
        pw.TableRow(
          children: [
            _cell(item.productName, padding: const pw.EdgeInsets.all(8)),
            _cell('${item.qty}', padding: const pw.EdgeInsets.all(8), textAlign: pw.TextAlign.center),
            _cell(_currencyFormat.format(item.unitPrice), padding: const pw.EdgeInsets.all(8), textAlign: pw.TextAlign.right),
            _cell(_currencyFormat.format(item.total), padding: const pw.EdgeInsets.all(8), textAlign: pw.TextAlign.right),
          ],
        ),
      );
    }

    pdf.addPage(
      pw.MultiPage(
        pageFormat: PdfPageFormat.a4,
        margin: const pw.EdgeInsets.all(32),
        build: (pw.Context context) {
          return [
            pw.Row(
              mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
              children: [
                pw.Column(
                  crossAxisAlignment: pw.CrossAxisAlignment.start,
                  children: [
                    pw.Container(
                      padding: const pw.EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                      decoration: pw.BoxDecoration(
                        color: PdfColor.fromHex('#E67E22'),
                        borderRadius: const pw.BorderRadius.all(pw.Radius.circular(4)),
                      ),
                      child: pw.Text('INVOICE', style: pw.TextStyle(color: PdfColors.white, fontSize: 20, fontWeight: pw.FontWeight.bold)),
                    ),
                    pw.SizedBox(height: 12),
                    pw.Text('${business.name}', style: pw.TextStyle(fontSize: 18, fontWeight: pw.FontWeight.bold)),
                    if (business.address != null) ...[
                      pw.SizedBox(height: 2),
                      pw.Text(business.address!, style: pw.TextStyle(fontSize: 10, color: PdfColors.grey)),
                    ],
                    if (business.phone != null) pw.Text('Tel: ${business.phone}', style: pw.TextStyle(fontSize: 10, color: PdfColors.grey)),
                    if (business.email != null) pw.Text('Email: ${business.email}', style: pw.TextStyle(fontSize: 10, color: PdfColors.grey)),
                    if (business.vatNumber != null && business.vatNumber!.isNotEmpty)
                      pw.Text('VAT Reg: ${business.vatNumber}', style: pw.TextStyle(fontSize: 10, color: PdfColors.grey)),
                  ],
                ),
                pw.Column(
                  crossAxisAlignment: pw.CrossAxisAlignment.end,
                  children: [
                    pw.Text('${invoice.invoiceNumber}', style: pw.TextStyle(fontSize: 16, fontWeight: pw.FontWeight.bold)),
                    pw.SizedBox(height: 4),
                    pw.Text('Date: $dateStr', style: const pw.TextStyle(fontSize: 10)),
                    pw.Text('Time: $timeStr', style: const pw.TextStyle(fontSize: 10)),
                    pw.SizedBox(height: 8),
                    pw.Text('Order: ${order.id.substring(0, 8).toUpperCase()}', style: pw.TextStyle(fontSize: 9, color: PdfColors.grey)),
                  ],
                ),
              ],
            ),
            pw.SizedBox(height: 24),
            if (customer != null) ...[
              pw.Container(
                padding: const pw.EdgeInsets.all(10),
                decoration: pw.BoxDecoration(
                  color: PdfColor.fromHex('#FFF8F0'),
                  borderRadius: const pw.BorderRadius.all(pw.Radius.circular(4)),
                ),
                child: pw.Column(
                  crossAxisAlignment: pw.CrossAxisAlignment.start,
                  children: [
                    pw.Text('Bill To:', style: pw.TextStyle(fontWeight: pw.FontWeight.bold, fontSize: 10)),
                    pw.SizedBox(height: 4),
                    pw.Text(customer.name, style: const pw.TextStyle(fontSize: 12)),
                    if (customer.phone != null) pw.Text(customer.phone!, style: pw.TextStyle(fontSize: 10, color: PdfColors.grey)),
                    if (customer.address != null) pw.Text(customer.address!, style: pw.TextStyle(fontSize: 10, color: PdfColors.grey)),
                  ],
                ),
              ),
              pw.SizedBox(height: 16),
            ],
            pw.Table(
              border: pw.TableBorder.all(color: PdfColors.grey300, width: 0.5),
              columnWidths: {
                0: const pw.FlexColumnWidth(3),
                1: const pw.FlexColumnWidth(1),
                2: const pw.FlexColumnWidth(1.5),
                3: const pw.FlexColumnWidth(1.5),
              },
              children: tableRows,
            ),
            pw.SizedBox(height: 20),
            pw.Row(
              mainAxisAlignment: pw.MainAxisAlignment.end,
              children: [
                pw.Column(
                  crossAxisAlignment: pw.CrossAxisAlignment.end,
                  children: [
                    _totalRow('Subtotal', _currencyFormat.format(order.subtotal)),
                    _totalRow('VAT (${(business.vatRate * 100).toStringAsFixed(0)}%)', _currencyFormat.format(order.taxAmount)),
                    if (order.discount > 0) _totalRow('Discount', '-${_currencyFormat.format(order.discount)}'),
                    pw.Divider(height: 1),
                    _totalRow('TOTAL', _currencyFormat.format(order.total), bold: true),
                  ],
                ),
              ],
            ),
            pw.SizedBox(height: 16),
            pw.Row(
              mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
              children: [
                pw.Column(
                  crossAxisAlignment: pw.CrossAxisAlignment.start,
                  children: [
                    pw.Text('Payment Method: ${order.paymentMethod}', style: pw.TextStyle(fontSize: 9, color: PdfColors.grey)),
                    pw.Text('Status: ${invoice.status}', style: pw.TextStyle(fontSize: 9, color: PdfColors.grey)),
                  ],
                ),
                if (business.receiptFooter != null)
                  pw.Text(business.receiptFooter!, style: pw.TextStyle(fontSize: 8, fontStyle: pw.FontStyle.italic, color: PdfColors.grey)),
              ],
            ),
            pw.SizedBox(height: 32),
            pw.Center(
              child: pw.Text('Generated by SpiceDesk — Built by Shahid Singh',
                  style: pw.TextStyle(fontSize: 8, color: PdfColors.grey300)),
            ),
          ];
        },
      ),
    );

    final dir = await getApplicationDocumentsDirectory();
    final invoicesDir = Directory('${dir.path}/invoices');
    if (!await invoicesDir.exists()) {
      await invoicesDir.create(recursive: true);
    }

    final filePath = '${invoicesDir.path}/${invoice.id}.pdf';
    final file = File(filePath);
    await file.writeAsBytes(await pdf.save());
    return filePath;
  }

  static pw.Widget _headerCell(String text) {
    return pw.Container(
      padding: const pw.EdgeInsets.all(8),
      child: pw.Text(text, style: pw.TextStyle(color: PdfColors.white, fontWeight: pw.FontWeight.bold, fontSize: 10), textAlign: pw.TextAlign.center),
    );
  }

  static pw.Widget _cell(String text, {pw.EdgeInsets? padding, pw.TextAlign? textAlign}) {
    return pw.Container(
      padding: padding ?? const pw.EdgeInsets.all(6),
      child: pw.Text(text, style: const pw.TextStyle(fontSize: 10), textAlign: textAlign ?? pw.TextAlign.left),
    );
  }

  static pw.Widget _totalRow(String label, String value, {bool bold = false}) {
    return pw.Padding(
      padding: const pw.EdgeInsets.symmetric(vertical: 2),
      child: pw.Row(
        mainAxisSize: pw.MainAxisSize.min,
        children: [
          pw.SizedBox(
            width: 200,
            child: pw.Text(label, style: pw.TextStyle(fontSize: 10, fontWeight: bold ? pw.FontWeight.bold : null), textAlign: pw.TextAlign.right),
          ),
          pw.SizedBox(width: 16),
          pw.SizedBox(
            width: 100,
            child: pw.Text(value, style: pw.TextStyle(fontSize: 10, fontWeight: bold ? pw.FontWeight.bold : null), textAlign: pw.TextAlign.right),
          ),
        ],
      ),
    );
  }
}
