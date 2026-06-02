class AppConstants {
  static const String dbName = 'spicedesk.db';
  static const int dbVersion = 1;

  static const List<String> defaultProductCategories = [
    'Samosas',
    'Bhajias',
    'Pakoras',
    'Chaat',
    'Sweets',
    'Beverages',
    'Snacks',
    'Other',
  ];

  static const List<String> defaultExpenseCategories = [
    'Ingredients',
    'Packaging',
    'Rent',
    'Electricity',
    'Water',
    'Transport',
    'Salaries',
    'Marketing',
    'Maintenance',
    'Other',
  ];

  static const List<String> paymentMethods = [
    'Cash',
    'Card',
    'EFT',
    'Other',
  ];

  static const List<String> orderTypes = [
    'Walk-in',
    'WhatsApp',
    'Phone Call',
    'Other',
  ];

  static const List<String> orderStatuses = [
    'Pending',
    'Confirmed',
    'Preparing',
    'Ready',
    'Delivered',
    'Completed',
    'Cancelled',
  ];

  static const List<String> invoiceStatuses = [
    'Draft',
    'Sent',
    'Paid',
    'Cancelled',
  ];

  static String formatCurrency(double amount, {String symbol = 'R'}) {
    return '$symbol ${amount.toStringAsFixed(2)}';
  }
}
