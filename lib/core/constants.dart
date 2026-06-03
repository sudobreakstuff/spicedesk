class AppConstants {
  static const paymentMethods = ['Cash', 'Card', 'EFT', 'Other'];
  static const orderTypes = ['Walk-in', 'WhatsApp', 'Phone Call', 'Other'];

  static String formatCurrency(double amount) {
    return 'R ${amount.toStringAsFixed(2)}';
  }
}
