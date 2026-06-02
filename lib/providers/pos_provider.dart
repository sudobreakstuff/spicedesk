import 'package:flutter/foundation.dart';
import '../models/product.dart';

class CartItem {
  final Product product;
  int quantity;
  double discount;

  CartItem({
    required this.product,
    this.quantity = 1,
    this.discount = 0,
  });

  double get lineTotal => (product.price * quantity) - discount;
  double get taxAmount => lineTotal * 0.15;
  double get lineTotalWithTax => lineTotal + taxAmount;
}

class PosProvider extends ChangeNotifier {
  final List<CartItem> _items = [];
  double _discount = 0;
  String _paymentMethod = 'Cash';
  String _orderType = 'Walk-in';
  String? _customerId;
  String? _customerName;
  String? _notes;

  List<CartItem> get items => List.unmodifiable(_items);
  int get itemCount => _items.length;
  int get totalQuantity => _items.fold(0, (sum, item) => sum + item.quantity);
  double get discount => _discount;
  String get paymentMethod => _paymentMethod;
  String get orderType => _orderType;
  String? get customerId => _customerId;
  String? get customerName => _customerName;
  String? get notes => _notes;

  double get subtotal => _items.fold(0, (sum, item) => sum + item.lineTotal);
  double get taxAmount => subtotal * 0.15;
  double get total => subtotal + taxAmount - _discount;
  bool get isEmpty => _items.isEmpty;

  void addItem(Product product, {int quantity = 1}) {
    final existingIndex = _items.indexWhere((item) => item.product.id == product.id);
    if (existingIndex != -1) {
      _items[existingIndex].quantity += quantity;
    } else {
      _items.add(CartItem(product: product, quantity: quantity));
    }
    notifyListeners();
  }

  void removeItem(int index) {
    if (index >= 0 && index < _items.length) {
      _items.removeAt(index);
      notifyListeners();
    }
  }

  void updateQuantity(int index, int quantity) {
    if (index >= 0 && index < _items.length) {
      if (quantity <= 0) {
        _items.removeAt(index);
      } else {
        _items[index].quantity = quantity;
      }
      notifyListeners();
    }
  }

  void updateItemDiscount(int index, double discount) {
    if (index >= 0 && index < _items.length) {
      _items[index].discount = discount;
      notifyListeners();
    }
  }

  void setDiscount(double discount) {
    _discount = discount;
    notifyListeners();
  }

  void setPaymentMethod(String method) {
    _paymentMethod = method;
    notifyListeners();
  }

  void setOrderType(String type) {
    _orderType = type;
    notifyListeners();
  }

  void setCustomer(String? id, String? name) {
    _customerId = id;
    _customerName = name;
    notifyListeners();
  }

  void setNotes(String? notes) {
    _notes = notes;
    notifyListeners();
  }

  Map<String, dynamic> toOrderData() {
    return {
      'order_type': _orderType,
      'subtotal': subtotal,
      'tax_amount': taxAmount,
      'discount': _discount,
      'total': total,
      'payment_method': _paymentMethod,
      'customer_id': _customerId,
      'notes': _notes,
    };
  }

  List<Map<String, dynamic>> toOrderItemsData() {
    return _items.map((item) => {
      'product_id': item.product.id,
      'product_name': item.product.name,
      'qty': item.quantity,
      'unit_price': item.product.price,
      'total': item.lineTotal,
    }).toList();
  }

  void clear() {
    _items.clear();
    _discount = 0;
    _paymentMethod = 'Cash';
    _orderType = 'Walk-in';
    _customerId = null;
    _customerName = null;
    _notes = null;
    notifyListeners();
  }
}
