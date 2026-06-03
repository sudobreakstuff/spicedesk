import 'package:flutter/foundation.dart';
import '../models/product.dart';

class CartItem {
  final Product product;
  int quantity;
  CartItem({required this.product, this.quantity = 1});
  double get lineTotal => product.price * quantity;
}

class PosProvider extends ChangeNotifier {
  final List<CartItem> _items = [];
  double _discount = 0;
  String _payment = 'Cash', _type = 'Walk-in';

  List<CartItem> get items => List.unmodifiable(_items);
  int get itemCount => _items.length;
  int get totalQuantity => _items.fold(0, (s, i) => s + i.quantity);
  double get discount => _discount;
  String get paymentMethod => _payment;
  String get orderType => _type;
  double get subtotal => _items.fold(0, (s, i) => s + i.lineTotal);
  double get taxAmount => subtotal * 0.15;
  double get total => subtotal + taxAmount - _discount;
  bool get isEmpty => _items.isEmpty;

  void addItem(Product p, {int qty = 1}) {
    final i = _items.indexWhere((x) => x.product.id == p.id);
    if (i != -1) { _items[i].quantity += qty; } else { _items.add(CartItem(product: p, quantity: qty)); }
    notifyListeners();
  }

  void removeItem(int i) { if (i >= 0 && i < _items.length) { _items.removeAt(i); notifyListeners(); } }
  void updateQuantity(int i, int q) {
    if (i < 0 || i >= _items.length) return;
    if (q <= 0) { _items.removeAt(i); } else { _items[i].quantity = q; }
    notifyListeners();
  }

  void setDiscount(double d) { _discount = d; notifyListeners(); }
  void setPaymentMethod(String m) { _payment = m; notifyListeners(); }
  void setOrderType(String t) { _type = t; notifyListeners(); }

  List<Map<String, dynamic>> toOrderItemsData() => _items.map((i) => {
    'product_id': i.product.id, 'product_name': i.product.name,
    'qty': i.quantity, 'unit_price': i.product.price, 'total': i.lineTotal,
  }).toList();

  void clear() { _items.clear(); _discount = 0; _payment = 'Cash'; _type = 'Walk-in'; notifyListeners(); }
}
