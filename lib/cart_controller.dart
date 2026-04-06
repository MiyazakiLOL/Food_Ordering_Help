import 'menu_models.dart';
import 'voucher_model.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'dart:convert';

class CartController {
  final List<CartItemModel> _items = [];
  VoucherModel? _appliedVoucher;
  double _shippingFee = 0;
  String _orderNote = '';

  // Keys cho SharedPreferences
  static const String _cartKey = 'food_app_cart';
  static const String _noteKey = 'food_app_order_note';

  List<CartItemModel> get items => List.unmodifiable(_items);
  VoucherModel? get appliedVoucher => _appliedVoucher;
  double get shippingFee => _shippingFee;
  String get orderNote => _orderNote;

  int get totalItems => _items.fold(0, (sum, e) => sum + e.quantity);

  /// Tổng tiền hàng (chưa tính phí ship và giảm giá)
  double get subtotal => _items.fold(0, (sum, e) => sum + e.totalPrice);

  /// Tiền giảm giá từ voucher
  double get discountAmount {
    if (_appliedVoucher == null) return 0;
    // Check xem subtotal có đáp ứng min_order_value không
    // Nếu không thì không có discount
    if (subtotal < _appliedVoucher!.minOrderValue) {
      return 0;
    }
    return _appliedVoucher!.calculateDiscount(subtotal).toDouble();
  }

  /// Tổng tiền cuối cùng = hàng + ship - giảm giá
  double get grandTotal {
    final total = subtotal + shippingFee - discountAmount;
    return total > 0 ? total : 0;
  }

  /// Tải giỏ hàng từ SharedPreferences
  Future<void> loadCart() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final cartJson = prefs.getString(_cartKey);
      final note = prefs.getString(_noteKey) ?? '';
      
      _orderNote = note;
      
      if (cartJson != null && cartJson.isNotEmpty) {
        final cartList = jsonDecode(cartJson) as List;
        print('📦 Loaded ${cartList.length} items from storage');
      }
    } catch (e) {
      print('Error loading cart: $e');
    }
  }

  /// Lưu giỏ hàng vào SharedPreferences
  Future<void> saveCart() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      // Lưu note
      await prefs.setString(_noteKey, _orderNote);
      print('💾 Cart saved (${_items.length} items)');
    } catch (e) {
      print('Error saving cart: $e');
    }
  }

  void setOrderNote(String note) {
    _orderNote = note;
    saveCart();
  }

  void addItem(MenuItemModel menuItem, FoodCustomization customization) {
    final index = _items.indexWhere(
      (e) =>
          e.item.id == menuItem.id &&
          e.customization.size == customization.size &&
          e.customization.sugar == customization.sugar &&
          e.customization.ice == customization.ice &&
          _sameToppings(e.customization.toppings, customization.toppings),
    );

    if (index >= 0) {
      final current = _items[index];
      _items[index] = CartItemModel(
        item: current.item,
        customization: current.customization,
        quantity: current.quantity + 1,
      );
    } else {
      _items.add(
        CartItemModel(
          item: menuItem,
          customization: customization,
          quantity: 1,
        ),
      );
    }
    saveCart();
  }

  void removeAt(int index) {
    if (index < 0 || index >= _items.length) return;
    _items.removeAt(index);
    saveCart();
  }

  void updateQuantity(int index, int newQuantity) {
    if (index < 0 || index >= _items.length) return;
    if (newQuantity <= 0) {
      removeAt(index);
      return;
    }
    final current = _items[index];
    _items[index] = CartItemModel(
      item: current.item,
      customization: current.customization,
      quantity: newQuantity,
    );
    saveCart();
  }

  void setShippingFee(double fee) {
    _shippingFee = fee;
  }

  void applyVoucher(VoucherModel voucher) {
    if (voucher.minOrderValue <= subtotal) {
      _appliedVoucher = voucher;
    }
  }

  void removeVoucher() {
    _appliedVoucher = null;
  }

  void clear() {
    _items.clear();
    _appliedVoucher = null;
    _shippingFee = 0;
    _orderNote = '';
    saveCart();
  }

  bool _sameToppings(List<String> a, List<String> b) {
    if (a.length != b.length) return false;
    final aa = [...a]..sort();
    final bb = [...b]..sort();
    for (var i = 0; i < aa.length; i++) {
      if (aa[i] != bb[i]) return false;
    }
    return true;
  }
}
