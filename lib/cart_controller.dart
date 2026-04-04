import 'menu_models.dart';

class CartController {
  final List<CartItemModel> _items = [];

  List<CartItemModel> get items => List.unmodifiable(_items);

  int get totalItems => _items.fold(0, (sum, e) => sum + e.quantity);

  double get grandTotal => _items.fold(0, (sum, e) => sum + e.totalPrice);

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
  }

  void removeAt(int index) {
    if (index < 0 || index >= _items.length) return;
    _items.removeAt(index);
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
