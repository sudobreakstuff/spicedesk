import 'package:flutter/material.dart';
import 'package:flutter_blue_plus/flutter_blue_plus.dart';
import 'package:niim_blue_flutter/niim_blue_flutter.dart';

import 'b21_driver.dart';

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
  String? _lastError;

  bool get isConnected => _connected;
  String? get printerName => _printerName;
  String? get printerModel => _printerModel;
  String? get lastError => _lastError;

  // ── Niimbot B21 ──────────────────────────────────────────

  /// Scan for available Niimbot printers using our own driver
  Future<List<BluetoothDevice>> scanPrinters({Duration timeout = const Duration(seconds: 8)}) async {
    return B21PrinterDriver.scanPrinters(timeout: timeout);
  }

  /// Connect to a Niimbot printer via BluetoothDevice
  Future<PrinterConnectionResult> connect(BluetoothDevice device) async {
    try {
      final b21 = B21PrinterDriver();
      final bleOk = await b21.connect(device);
      if (!bleOk) {
        return PrinterConnectionResult.failure(
            'Failed to establish BLE connection. Make sure the printer is on and in range.');
      }
      debugPrint('SpiceDesk: BLE connected via custom driver');

      _client = NiimbotBluetoothClient();
      _client!.setDevice(device);
      _client!.setDebug(true);

      try {
        final info = await _client!.connect();
        _connected = true;
        _printerName = info.deviceName ?? 'Niimbot Printer';
        debugPrint('SpiceDesk: Library negotiation OK');
      } catch (e) {
        debugPrint('SpiceDesk: Library negotiation warning: $e');
        _connected = true;
        _printerName = device.platformName;
        _lastError = 'Printer connected but print protocol failed — check B21 firmware';
      }

      if (_connected) {
        try {
          await _client!.fetchPrinterInfo();
          final meta = _client!.getModelMetadata();
          _printerModel = meta?.model.name ?? 'Unknown';
          debugPrint('SpiceDesk: Printer model: $_printerModel');
        } catch (_) {
          _printerModel = 'Unknown';
        }

        try {
          _printTask = _client!.createPrintTask(const PrintOptions(
            density: 2,
            totalPages: 5,
          ));
          if (_printTask != null) {
            debugPrint('SpiceDesk: Print task created successfully');
          }
        } catch (_) {
          debugPrint('SpiceDesk: Could not create print task');
        }
      }

      await b21.disconnectSafe();

      if (_connected) {
        return PrinterConnectionResult.success('$_printerName ($_printerModel)');
      }
      return PrinterConnectionResult.failure('Connection succeeded but printer setup failed');

    } catch (e) {
      _connected = false;
      _client = null;
      _printTask = null;
      debugPrint('SpiceDesk: Connection error: $e');

      String message = e.toString();
      if (message.contains('Timeout')) {
        message = 'Printer not responding. Try restarting the B21 and moving it closer.';
      } else if (message.contains('Bluetooth')) {
        message = 'Bluetooth error. Check that Bluetooth is enabled.';
      }
      _lastError = message;

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
    if (_printTask == null) {
      _lastError = 'Printer connected but print protocol failed — check B21 firmware';
      debugPrint('SpiceDesk: Print task is null, cannot print');
      return false;
    }

    try {
      final page = PrintPage(400, 400);

      int y = 18;

      // Header — store name
      await page.addText(
        storeName,
        TextOptions(x: 200, y: y, align: HAlignment.center, fontSize: 20, fontWeight: FontWeight.bold),
      );
      y += 30;

      // Transaction number
      await page.addText(
        'Txn: $transactionNumber',
        TextOptions(x: 200, y: y, align: HAlignment.center, fontSize: 14),
      );
      y += 18;

      // Date
      await page.addText(
        '${date.day}/${date.month}/${date.year} ${date.hour}:${date.minute.toString().padLeft(2, '0')}',
        TextOptions(x: 200, y: y, align: HAlignment.center, fontSize: 14),
      );
      y += 20;

      // Payment method
      if (paymentMethod != null) {
        await page.addText(
          paymentMethod,
          TextOptions(x: 200, y: y, align: HAlignment.center, fontSize: 14),
        );
        y += 18;
      }

      // Divider
      page.addLine(LineOptions(x: 20, y: y, endX: 380, endY: y));
      y += 12;

      // Items
      for (final item in items) {
        await page.addText(
          item.name,
          TextOptions(x: 20, y: y, fontSize: 14),
        );
        await page.addText(
          'x${item.quantity}',
          TextOptions(x: 250, y: y, fontSize: 12),
        );
        await page.addText(
          'R ${item.lineTotal.toStringAsFixed(2)}',
          TextOptions(x: 380, y: y, align: HAlignment.right, fontSize: 14),
        );
        y += 20;
      }

      // Divider
      page.addLine(LineOptions(x: 20, y: y, endX: 380, endY: y));
      y += 12;

      // Total
      await page.addText(
        'TOTAL: R ${total.toStringAsFixed(2)}',
        TextOptions(x: 200, y: y, align: HAlignment.center, fontSize: 22, fontWeight: FontWeight.bold),
      );
      y += 32;

      // Footer
      await page.addText(
        'Thank you!',
        TextOptions(x: 200, y: y, align: HAlignment.center, fontSize: 14),
      );
      y += 20;

      await page.addText(
        'Made by Shahid Singh',
        TextOptions(x: 200, y: y, align: HAlignment.center, fontSize: 12),
      );

      // Encode and print
      final encoded = page.toEncodedImage();

      await _printTask!.printInit();
      await _printTask!.printPage(encoded, 1);
      await _printTask!.waitForFinished();
      await _printTask!.printEnd();

      return true;
    } catch (e) {
      _lastError = e.toString();
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
