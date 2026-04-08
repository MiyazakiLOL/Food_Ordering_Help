import 'menu_models.dart';
import 'voucher_model.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'dart:convert';

class CartController {
  List<CartItemModel> _items = [];
  VoucherModel? _appliedVoucher;
  double _shippingFee = 0;
  String _orderNote = '';

  static const String _cartKey = 'food_app_cart_items';
  static const String _noteKey = 'food_app_order_note';

  List<CartItemModel> get items => _items;
  VoucherModel? get appliedVoucher => _appliedVoucher;
  double get shippingFee => _shippingFee;
  String get orderNote => _orderNote;

  int get totalItems => _items.fold(0, (sum, e) => sum + e.quantity);
  double get subtotal => _items.fold(0, (sum, e) => sum + e.totalPrice);

  double get discountAmount {
    if (_appliedVoucher == null || subtotal < _appliedVoucher!.minOrderValue) return 0;
    return _appliedVoucher!.calculateDiscount(subtotal).toDouble();
  }

  double get grandTotal => (subtotal + shippingFee - discountAmount).clamp(0, double.infinity);

  Future<void> loadCart() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      _orderNote = prefs.getString(_noteKey) ?? '';
      final cartJson = prefs.getString(_cartKey);
      
      if (cartJson != null) {
        final List<dynamic> decoded = jsonDecode(cartJson);
        _items = decoded.map((item) => CartItemModel.fromJson(item)).toList();
      }
    } catch (e) {
      print('Error loading cart: $e');
    }
  }

  Future<void> saveCart() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString(_noteKey, _orderNote);
      final cartJson = jsonEncode(_items.map((item) => item.toJson()).toList());
      await prefs.setString(_cartKey, cartJson);
    } catch (e) {
      print('Error saving cart: $e');
    }
  }

  void addItem(MenuItemModel menuItem, FoodCustomization customization) {
    final index = _items.indexWhere((e) => e.item.id == menuItem.id && e.customization.summary == customization.summary);

    if (index >= 0) {
      _items[index] = CartItemModel(
        item: menuItem,
        customization: customization,
        quantity: _items[index].quantity + 1,
      );
    } else {
      _items.add(CartItemModel(item: menuItem, customization: customization, quantity: 1));
    }
    saveCart();
  }

  void updateQuantity(int index, int newQuantity) {
    if (newQuantity <= 0) {
      _items.removeAt(index);
    } else {
      _items[index] = CartItemModel(
        item: _items[index].item,
        customization: _items[index].customization,
        quantity: newQuantity,
      );
    }
    saveCart();
  }

  void removeAt(int index) {
    _items.removeAt(index);
    saveCart();
  }

  void updateItem(int index, FoodCustomization newCustomization) {
    if (index >= 0 && index < _items.length) {
      _items[index] = CartItemModel(
        item: _items[index].item,
        customization: newCustomization,
        quantity: _items[index].quantity,
      );
      saveCart();
    }
  }

  void setOrderNote(String note) {
    _orderNote = note;
    saveCart();
  }

  void setShippingFee(double fee) => _shippingFee = fee;
  void applyVoucher(VoucherModel voucher) => _appliedVoucher = voucher;
  void removeVoucher() => _appliedVoucher = null;
  
  void clear() {
    _items.clear();
    _appliedVoucher = null;
    _orderNote = '';
    saveCart();
  }
}
