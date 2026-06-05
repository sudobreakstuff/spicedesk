import 'package:flutter/material.dart';
import 'package:flutter_blue_plus/flutter_blue_plus.dart';
import 'package:niim_blue_flutter/niim_blue_flutter.dart';

/// Unified printing service — supports Niimbot B21 (BLE).
class PrintingService {
  static final PrintingService _instance = PrintingService._();
  factory PrintingService() => _instance;
  PrintingService._();

  NiimbotBluetoothClient? _client;
  AbstractPrintTask? _printTask;
  bool _connected = false;
  String? _printerName;
  String? _printerModel;

  bool get isConnected => _connected;
  String? get printerName => _printerName;
  String? get printerModel => _printerModel;

  // ── Niimbot B21 ──────────────────────────────────────────

  /// Scan for available Niimbot printers
  Future<List<BluetoothDevice>> scanPrinters({Duration timeout = const Duration(seconds: 5)}) async {
    return NiimbotBluetoothClient.listDevices(timeout: timeout);
  }

  /// Connect to a Niimbot printer via BluetoothDevice
  Future<PrinterConnectionResult> connect(BluetoothDevice device) async {
    try {
      _client = NiimbotBluetoothClient();
      _client!.setDevice(device);
      _client!.setDebug(true);

      final info = await _client!.connect();
      _connected = true;
      _printerName = info.deviceName ?? 'Niimbot Printer';

      // Fetch detailed printer info
      await _client!.fetchPrinterInfo();
      final meta = _client!.getModelMetadata();
      final modelId = meta?.model;
      _printerModel = modelId?.name ?? 'Unknown';
      
      debugPrint('Niimbot connected: $_printerName (model: $_printerModel)');

      // Create a print task for this printer model
      _printTask = _client!.createPrintTask(const PrintOptions(
        density: 2,
        totalPages: 1,
      ));

      return PrinterConnectionResult.success('$_printerName ($_printerModel)');
    } catch (e) {
      _connected = false;
      _client = null;
      _printTask = null;
      debugPrint('Niimbot connection error: $e');
      
      String message = e.toString();
      if (message.contains('Timeout')) {
        message = 'Printer not responding. Make sure the B21 is turned on and nearby. Try restarting the printer.';
      } else if (message.contains('Bluetooth')) {
        message = 'Bluetooth error. Check that Bluetooth is enabled and the printer is in pairing mode.';
      }
      
      return PrinterConnectionResult.failure(message);
    }
  }

  /// Build and print a receipt on Niimbot printer
  Future<bool> printReceipt({
    required String storeName,
    required String transactionNumber,
    required DateTime date,
    required List<ReceiptLineItem> items,
    required double total,
    String? paymentMethod,
  }) async {
    if (_client == null || !_connected) return false;
    if (_printTask == null) return false;

    try {
      final page = PrintPage(400, 600);

      int y = 20;

      // Header — store name (large, bold, centered)
      await page.addText(
        storeName,
        TextOptions(x: 200, y: y, align: HAlignment.center, fontSize: 28, fontWeight: FontWeight.bold),
      );
      y += 40;

      // Transaction number
      await page.addText(
        'Txn: $transactionNumber',
        TextOptions(x: 200, y: y, align: HAlignment.center, fontSize: 16),
      );
      y += 24;

      // Date
      await page.addText(
        '${date.day}/${date.month}/${date.year} ${date.hour}:${date.minute.toString().padLeft(2, '0')}',
        TextOptions(x: 200, y: y, align: HAlignment.center, fontSize: 16),
      );
      y += 30;

      // Payment method
      if (paymentMethod != null) {
        await page.addText(
          paymentMethod,
          TextOptions(x: 200, y: y, align: HAlignment.center, fontSize: 16),
        );
        y += 24;
      }

      // Divider
      page.addLine(LineOptions(x: 20, y: y, endX: 380, endY: y));
      y += 16;

      // Items
      for (final item in items) {
        await page.addText(
          item.name,
          TextOptions(x: 20, y: y, fontSize: 20),
        );
        await page.addText(
          'x${item.quantity}',
          TextOptions(x: 250, y: y, fontSize: 16),
        );
        await page.addText(
          'R ${item.lineTotal.toStringAsFixed(2)}',
          TextOptions(x: 380, y: y, align: HAlignment.right, fontSize: 20),
        );
        y += 28;
      }

      // Divider
      page.addLine(LineOptions(x: 20, y: y, endX: 380, endY: y));
      y += 16;

      // Total
      await page.addText(
        'TOTAL: R ${total.toStringAsFixed(2)}',
        TextOptions(x: 200, y: y, align: HAlignment.center, fontSize: 32, fontWeight: FontWeight.bold),
      );
      y += 44;

      // Footer
      await page.addText(
        'Thank you!',
        TextOptions(x: 200, y: y, align: HAlignment.center, fontSize: 20),
      );
      y += 28;

      await page.addText(
        'Made by Shahid Singh',
        TextOptions(x: 200, y: y, align: HAlignment.center, fontSize: 16),
      );

      // Encode and print
      final encoded = page.toEncodedImage();

      await _printTask!.printInit();
      await _printTask!.printPage(encoded, 1);
      await _printTask!.waitForFinished();
      await _printTask!.printEnd();

      return true;
    } catch (e) {
      debugPrint('Niimbot print error: $e');
      return false;
    }
  }

  /// Disconnect printer
  Future<void> disconnect() async {
    await _client?.disconnect();
    await _client?.dispose();
    _client = null;
    _printTask = null;
    _connected = false;
    _printerName = null;
    _printerModel = null;
  }
}

class ReceiptLineItem {
  final String name;
  final int quantity;
  final double unitPrice;
  final double lineTotal;

  const ReceiptLineItem({
    required this.name,
    required this.quantity,
    required this.unitPrice,
    required this.lineTotal,
  });
}

class PrinterConnectionResult {
  final bool success;
  final String? printerName;
  final String? error;

  const PrinterConnectionResult._({
    required this.success,
    this.printerName,
    this.error,
  });

  factory PrinterConnectionResult.success(String name) =>
      PrinterConnectionResult._(success: true, printerName: name);

  factory PrinterConnectionResult.failure(String error) =>
      PrinterConnectionResult._(success: false, error: error);
}
