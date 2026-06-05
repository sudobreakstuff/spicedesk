import 'dart:async';
import 'package:flutter/foundation.dart';
import 'package:flutter_blue_plus/flutter_blue_plus.dart';

/// Minimal B21 Niimbot printer driver using raw BLE GATT.
class B21PrinterDriver {
  static const _serviceUuid = 'e7810a71-73ae-499d-8c15-faa9aef0c3f2';

  BluetoothDevice? _device;
  BluetoothCharacteristic? _writeChar;
  BluetoothCharacteristic? _notifyChar;
  StreamSubscription? _notifySub;
  bool _connected = false;

  final _responseController = StreamController<NiimbotResponse>.broadcast();
  Uint8List _buffer = Uint8List(0);

  bool get isConnected => _connected;

  /// Scan for Niimbot printers
  static Future<List<BluetoothDevice>> scanPrinters({Duration timeout = const Duration(seconds: 8)}) async {
    final List<BluetoothDevice> printers = [];
    final prefixes = ['NIIMBOT', 'B21', 'D11', 'D110', 'B1', 'B18', 'Niimbot'];

    final sub = FlutterBluePlus.scanResults.listen((results) {
      for (final r in results) {
        final name = r.device.platformName.toUpperCase();
        if (prefixes.any((p) => name.contains(p))) {
          if (!printers.any((d) => d.remoteId == r.device.remoteId)) {
            printers.add(r.device);
          }
        }
      }
    });

    await FlutterBluePlus.startScan(timeout: timeout);
    await Future.delayed(timeout);
    await sub.cancel();
    await FlutterBluePlus.stopScan();
    return printers;
  }

  /// Connect to a B21 printer
  Future<bool> connect(BluetoothDevice device) async {
    try {
      _device = device;

      // Listen for disconnection
      device.connectionState.listen((state) {
        if (state == BluetoothConnectionState.disconnected) {
          _connected = false;
        }
      });

      // Connect with generous timeout
      debugPrint('B21: Connecting to ${device.platformName}...');
      await device.connect(
        timeout: const Duration(seconds: 20),
        autoConnect: false,
      );
      debugPrint('B21: BLE connected, discovering services...');

      // Discover services
      final services = await device.discoverServices();
      
      // Find the Niimbot service
      for (final service in services) {
        if (service.uuid.toString().toLowerCase().contains(_serviceUuid.toLowerCase())) {
          for (final char in service.characteristics) {
            if (char.properties.write || char.properties.writeWithoutResponse) {
              _writeChar = char;
              debugPrint('B21: Found write characteristic: ${char.uuid}');
            }
            if (char.properties.notify) {
              _notifyChar = char;
              debugPrint('B21: Found notify characteristic: ${char.uuid}');
            }
          }
        }
      }

      if (_writeChar == null) {
        debugPrint('B21: Write characteristic not found');
        await device.disconnect();
        return false;
      }

      // Enable notifications
      if (_notifyChar != null) {
        await _notifyChar!.setNotifyValue(true);
        _notifySub = _notifyChar!.lastValueStream.listen(_onNotify);
        debugPrint('B21: Notifications enabled');
      }

      _connected = true;
      debugPrint('B21: Connected successfully');
      return true;

    } catch (e) {
      debugPrint('B21: Connection error: $e');
      _connected = false;
      return false;
    }
  }

  void _onNotify(List<int> data) {
    if (data.isEmpty) return;

    _buffer = Uint8List.fromList([..._buffer, ...data]);

    // Parse packets from buffer
    while (_buffer.length >= 6) {
      // Look for packet header
      int headerPos = -1;
      for (int i = 0; i <= _buffer.length - 2; i++) {
        if (_buffer[i] == 0x55 && _buffer[i + 1] == 0x55) {
          headerPos = i;
          break;
        }
      }

      if (headerPos == -1) break;
      if (headerPos > 0) {
        _buffer = _buffer.sublist(headerPos);
      }
      if (_buffer.length < 6) break;

      final cmdLo = _buffer[2];
      final cmdHi = _buffer[3];
      final dataLenLo = _buffer[4];
      final dataLenHi = _buffer[5];
      final dataLen = dataLenLo | (dataLenHi << 8);

      if (_buffer.length < 6 + dataLen + 2) break; // +2 for checksum

      final data = _buffer.sublist(6, 6 + dataLen);
      _buffer = _buffer.sublist(6 + dataLen + 2);

      _responseController.add(NiimbotResponse(
        command: cmdLo | (cmdHi << 8),
        data: Uint8List.fromList(data),
      ));
    }
  }

  /// Send a command and wait for response
  Future<NiimbotResponse?> sendCommand(int command, {Uint8List? data, Duration timeout = const Duration(seconds: 5), int retries = 1}) async {
    if (_writeChar == null) return null;

    for (int attempt = 0; attempt <= retries; attempt++) {
      if (attempt > 0) {
        debugPrint('B21: Retry $attempt for cmd=0x${command.toRadixString(16)}');
        await Future.delayed(const Duration(milliseconds: 50));
      }

      final result = await _sendRaw(command, data: data, timeout: timeout);
      if (result != null) return result;
    }
    debugPrint('B21: All retries failed for cmd=0x${command.toRadixString(16)}');
    return null;
  }

  Future<NiimbotResponse?> _sendRaw(int command, {Uint8List? data, Duration timeout = const Duration(seconds: 5)}) async {
    if (_writeChar == null) return null;

    final cmdData = data ?? Uint8List(0);
    final cmdLo = command & 0xFF;
    final cmdHi = (command >> 8) & 0xFF;
    final lenLo = cmdData.length & 0xFF;
    final lenHi = (cmdData.length >> 8) & 0xFF;

    final packet = Uint8List(6 + cmdData.length + 2);
    packet[0] = 0x55;
    packet[1] = 0x55;
    packet[2] = cmdLo;
    packet[3] = cmdHi;
    packet[4] = lenLo;
    packet[5] = lenHi;
    packet.setAll(6, cmdData);

    int checksum = 0;
    for (int i = 0; i < 6 + cmdData.length; i++) {
      checksum += packet[i];
    }
    checksum &= 0xFFFF;
    packet[6 + cmdData.length] = checksum & 0xFF;
    packet[6 + cmdData.length + 1] = (checksum >> 8) & 0xFF;

    debugPrint('B21: Sending cmd=0x${command.toRadixString(16)} len=${cmdData.length}');

    final completer = Completer<NiimbotResponse?>();
    StreamSubscription? sub;

    sub = _responseController.stream.listen((response) {
      if (response.command == command || response.command == 0) {
        completer.complete(response);
      }
    });

    try {
      await _writeChar!.write(packet, withoutResponse: false);
      final result = await completer.future.timeout(timeout, onTimeout: () {
        debugPrint('B21: Timeout waiting for response to cmd=0x${command.toRadixString(16)}');
        return null;
      });
      return result;
    } catch (e) {
      debugPrint('B21: Send error: $e');
      return null;
    } finally {
      sub.cancel();
    }
  }

  /// Print a test page
  Future<bool> printTestPage() async {
    if (!_connected) return false;

    try {
      final status = await sendCommand(0x0C, retries: 2);
      debugPrint('B21: Status response: ${status?.data}');

      await sendCommand(0x10, data: Uint8List.fromList([0x01]), retries: 2);
      await Future.delayed(const Duration(milliseconds: 50));

      debugPrint('B21: Test print commands sent');
      return true;
    } catch (e) {
      debugPrint('B21: Test print error: $e');
      _lastError = e.toString();
      return false;
    }
  }

  String? _lastError;
  String? get lastError => _lastError;

  Future<void> disconnectSafe() async {
    _connected = false;
    await _notifySub?.cancel();
    _notifySub = null;
    _writeChar = null;
    _notifyChar = null;
  }

  Future<void> disconnect() async {
    _connected = false;
    await _notifySub?.cancel();
    _notifySub = null;
    await _device?.disconnect();
    _device = null;
    _writeChar = null;
    _notifyChar = null;
  }
}

class NiimbotResponse {
  final int command;
  final Uint8List data;

  const NiimbotResponse({required this.command, required this.data});
}
