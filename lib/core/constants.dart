class AppConstants {
  static const dbName = 'spicedesk.db';
  static const dbVersion = 1;

  static const defaultProductCategories = ['Samosas', 'Bhajias', 'Pakoras', 'Sweets', 'Beverages', 'Snacks', 'Meals', 'Other'];
  static const defaultExpenseCategories = ['Ingredients', 'Packaging', 'Rent', 'Utilities', 'Transport', 'Salaries', 'Marketing', 'Other'];

  static const paymentMethods = ['Cash', 'Card', 'EFT', 'Other'];
  static const orderTypes = ['Walk-in', 'WhatsApp', 'Phone Call', 'Other'];
  static const orderStatuses = ['Pending', 'Confirmed', 'Preparing', 'Ready', 'Delivered', 'Completed', 'Cancelled'];

  static String formatCurrency(double amount) {
    return 'R ${amount.toStringAsFixed(2)}';
  }
}
