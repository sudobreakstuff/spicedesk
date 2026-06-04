import 'package:flutter/material.dart';
import 'package:flutter_blue_plus/flutter_blue_plus.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../../core/theme/app_theme.dart';
import '../../../printing/data/printing_service.dart';

class PrinterConnectScreen extends ConsumerStatefulWidget {
  const PrinterConnectScreen({super.key});

  @override
  ConsumerState<PrinterConnectScreen> createState() =>
      _PrinterConnectScreenState();
}

class _PrinterConnectScreenState extends ConsumerState<PrinterConnectScreen> {
  final _printingService = PrintingService();
  List<BluetoothDevice> _devices = [];
  bool _scanning = false;
  bool _connecting = false;
  String? _statusMessage;

  @override
  void initState() {
    super.initState();
    _startScan();
  }

  Future<void> _startScan() async {
    setState(() {
      _scanning = true;
      _devices = [];
      _statusMessage = 'Scanning for printers...';
    });

    try {
      final devices = await _printingService.scanPrinters(
        timeout: const Duration(seconds: 10),
      );

      if (mounted) {
        setState(() {
          _scanning = false;
          _devices = devices;
          _statusMessage =
              devices.isEmpty ? 'No Niimbot printers found' : '${devices.length} device(s) found';
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _scanning = false;
          _statusMessage = 'Scan error: $e';
        });
      }
    }
  }

  Future<void> _connect(BluetoothDevice device) async {
    setState(() {
      _connecting = true;
      _statusMessage = 'Connecting to ${device.platformName}...';
    });

    final result = await _printingService.connect(device);

    if (mounted) {
      setState(() {
        _connecting = false;
        _statusMessage = result.success
            ? 'Connected to ${result.printerName}'
            : 'Connection failed: ${result.error}';
      });

      if (result.success) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Connected to ${result.printerName}'),
            backgroundColor: SpiceColors.accent,
          ),
        );
        Navigator.pop(context, true);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () => context.pop(),
        ),
        title: const Text('Connect Printer'),
        actions: [
          IconButton(
            icon: _scanning
                ? const SizedBox(
                    width: 20,
                    height: 20,
                    child: CircularProgressIndicator(
                        strokeWidth: 2, color: Colors.white),
                  )
                : const Icon(Icons.refresh),
            onPressed: _scanning ? null : _startScan,
          ),
        ],
      ),
      body: Column(
        children: [
          if (_statusMessage != null)
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(12),
              color: SpiceColors.surfaceAlt,
              child: Row(
                children: [
                  if (_scanning)
                    const Padding(
                      padding: EdgeInsets.only(right: 8),
                      child: SizedBox(
                        width: 16,
                        height: 16,
                        child: CircularProgressIndicator(strokeWidth: 2),
                      ),
                    ),
                  Expanded(
                    child: Text(
                      _statusMessage!,
                      style: Theme.of(context).textTheme.bodyMedium,
                    ),
                  ),
                ],
              ),
            ),

          // Currently connected printer
          if (_printingService.isConnected)
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(16),
              color: SpiceColors.accent.withAlpha(30),
              child: Row(
                children: [
                  const Icon(Icons.check_circle, color: SpiceColors.accent),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Text(
                      'Connected: ${_printingService.printerName}',
                      style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                            color: SpiceColors.accent,
                            fontWeight: FontWeight.w600,
                          ),
                    ),
                  ),
                  TextButton(
                    onPressed: () async {
                      await _printingService.disconnect();
                      setState(() {});
                    },
                    child: const Text('Disconnect'),
                  ),
                ],
              ),
            ),

          Expanded(
            child: _devices.isEmpty && !_scanning
                ? Center(
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        const Icon(Icons.bluetooth_disabled,
                            size: 56, color: SpiceColors.textSecondary),
                        const SizedBox(height: 12),
                        Text('No Niimbot printers found',
                            style: Theme.of(context).textTheme.titleMedium),
                        const SizedBox(height: 8),
                        Text(
                            'Make sure your printer is on and Bluetooth is enabled',
                            style: Theme.of(context).textTheme.bodyMedium,
                            textAlign: TextAlign.center),
                        const SizedBox(height: 24),
                        ElevatedButton.icon(
                          onPressed: _startScan,
                          icon: const Icon(Icons.refresh),
                          label: const Text('Scan Again'),
                        ),
                      ],
                    ),
                  )
                : ListView.builder(
                    itemCount: _devices.length,
                    itemBuilder: (context, index) {
                      final device = _devices[index];
                      return ListTile(
                        leading: Container(
                          width: 44,
                          height: 44,
                          decoration: BoxDecoration(
                            color: SpiceColors.primary.withAlpha(30),
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: const Icon(Icons.print,
                              color: SpiceColors.primary),
                        ),
                        title: Text(
                          device.platformName,
                          style: Theme.of(context).textTheme.titleMedium,
                        ),
                        subtitle: Text(
                          device.remoteId.toString(),
                          style: Theme.of(context).textTheme.labelMedium,
                        ),
                        trailing: _connecting
                            ? const SizedBox(
                                width: 20,
                                height: 20,
                                child: CircularProgressIndicator(
                                    strokeWidth: 2),
                              )
                            : ElevatedButton(
                                onPressed: () => _connect(device),
                                style: ElevatedButton.styleFrom(
                                  padding: const EdgeInsets.symmetric(
                                      horizontal: 16, vertical: 8),
                                ),
                                child: const Text('Connect'),
                              ),
                      );
                    },
                  ),
          ),
        ],
      ),
    );
  }
}
