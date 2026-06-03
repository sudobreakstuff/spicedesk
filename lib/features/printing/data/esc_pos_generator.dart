import 'dart:typed_data';

/// Lightweight ESC/POS command builder — no external dependency needed.
/// Generates raw byte commands for standard ESC/POS thermal receipt printers.
class EscPosGenerator {
  final List<int> _buffer = [];
  static const int _esc = 0x1B;
  static const int _gs = 0x1D;

  EscPosGenerator();

  /// Initialize printer
  void initialize() {
    _buffer.addAll([_esc, 0x40]);
  }

  /// Feed paper n lines
  void feed(int lines) {
    _buffer.addAll([_esc, 0x64, lines.clamp(0, 255)]);
  }

  /// Cut paper (partial cut)
  void cut({bool partial = true}) {
    if (partial) {
      _buffer.addAll([_gs, 0x56, 0x00]); // Partial cut
    } else {
      _buffer.addAll([_gs, 0x56, 0x01]); // Full cut
    }
  }

  /// Set text alignment: 0=left, 1=center, 2=right
  void align(int alignment) {
    _buffer.addAll([_esc, 0x61, alignment.clamp(0, 2)]);
  }

  /// Bold on/off
  void bold(bool on) {
    _buffer.addAll([_esc, 0x45, on ? 1 : 0]);
  }

  /// Double width/height
  void doubleSize({bool width = true, bool height = true}) {
    int val = 0;
    if (width) val |= 0x20;
    if (height) val |= 0x10;
    _buffer.addAll([_gs, 0x21, val]);
  }

  /// Reset text formatting
  void resetFormat() {
    _buffer.addAll([_esc, 0x21, 0x00]);
  }

  /// Print text (plain ASCII)
  void text(String str) {
    _buffer.addAll(str.codeUnits);
  }

  /// Print a separator line
  void separator({String char = '-', int length = 32}) {
    text(char * length);
    newLine();
  }

  /// New line
  void newLine() {
    _buffer.add(0x0A);
  }

  /// Build a receipt from structured data
  void buildReceipt({
    required String storeName,
    required String storeInfo,
    required DateTime date,
    required String transactionNumber,
    required List<ReceiptItem> items,
    required double subtotal,
    required double tax,
    required double total,
    String? paymentMethod,
    String? footer,
  }) {
    initialize();

    // Header
    align(1);
    bold(true);
    doubleSize(width: true, height: true);
    text(storeName);
    newLine();
    resetFormat();
    bold(false);

    doubleSize(width: false, height: false);
    text(storeInfo);
    newLine();
    separator();

    // Date and transaction
    align(0);
    text('Date: ${_formatDate(date)}');
    newLine();
    text('Txn:  $transactionNumber');
    newLine();
    if (paymentMethod != null) {
      text('Paid: $paymentMethod');
      newLine();
    }
    separator();

    // Column headers
    text('Item');
    align(1);
    text('Qty');
    align(2);
    text('Price');
    align(2);
    text('Total');
    newLine();
    separator(char: '-');

    // Items
    for (final item in items) {
      align(0);
      text(_truncate(item.name, 16));
      align(1);
      text('${item.quantity}');
      align(2);
      text(item.unitPrice.toStringAsFixed(2));
      align(2);
      text(item.lineTotal.toStringAsFixed(2));
      newLine();
    }

    separator();

    // Totals
    align(2);
    text('Subtotal: R ${subtotal.toStringAsFixed(2)}');
    newLine();
    if (tax > 0) {
      text('Tax:     R ${tax.toStringAsFixed(2)}');
      newLine();
    }
    bold(true);
    doubleSize(width: true, height: true);
    text('TOTAL:   R ${total.toStringAsFixed(2)}');
    newLine();
    resetFormat();
    bold(false);

    separator();

    // Footer
    if (footer != null) {
      align(1);
      text(footer);
      newLine();
    }
    align(1);
    text('Thank you!');
    newLine();
    text('Made by Shahid Singh');
    newLine();

    // Feed and cut
    feed(3);
    cut();
  }

  String _formatDate(DateTime dt) {
    return '${dt.day.toString().padLeft(2, '0')}/${dt.month.toString().padLeft(2, '0')}/${dt.year} '
        '${dt.hour.toString().padLeft(2, '0')}:${dt.minute.toString().padLeft(2, '0')}';
  }

  String _truncate(String s, int maxLen) {
    return s.length > maxLen ? '${s.substring(0, maxLen - 1)}…' : s;
  }

  /// Convert to Uint8List for sending to printer
  Uint8List toBytes() => Uint8List.fromList(_buffer);
}

class ReceiptItem {
  final String name;
  final int quantity;
  final double unitPrice;
  final double lineTotal;

  const ReceiptItem({
    required this.name,
    required this.quantity,
    required this.unitPrice,
    required this.lineTotal,
  });
}
