class StoreModel {
  final String id;
  final String name;
  final String imageUrl;
  final double rating;

  const StoreModel({
    required this.id,
    required this.name,
    required this.imageUrl,
    required this.rating,
  });

  factory StoreModel.fromMap(Map<String, dynamic> map) {
    final url = (map['image_url'] ?? '').toString();
    return StoreModel(
      id: map['id'].toString(),
      name: (map['name'] ?? 'Cửa hàng').toString(),
      imageUrl: _normalizeStoreImage(url),
      rating: (map['rating'] ?? 4.5).toDouble(),
    );
  }

  static String _normalizeStoreImage(String url) {
    if (url.isEmpty || url.contains('source.unsplash.com')) {
      return 'https://images.unsplash.com/photo-1517248135467-4c7edcad34c4?auto=format&fit=crop&w=1200&q=80';
    }
    return url;
  }
}

class MenuItemModel {
  final String id;
  final String storeId;
  final String name;
  final String description;
  final String imageUrl;
  final double price;
  final bool isFeatured;
  final String category;
  final int discountPercent;

  const MenuItemModel({
    required this.id,
    required this.storeId,
    required this.name,
    required this.description,
    required this.imageUrl,
    required this.price,
    required this.isFeatured,
    required this.category,
    required this.discountPercent,
  });

  factory MenuItemModel.fromMap(Map<String, dynamic> map) {
    final name = (map['name'] ?? 'Món ăn').toString();
    final rawCategory = (map['category'] ?? '').toString();
    final category = rawCategory.isEmpty ? _inferCategory(name) : rawCategory;
    return MenuItemModel(
      id: map['id'].toString(),
      storeId: (map['store_id'] ?? '').toString(),
      name: name,
      description: (map['description'] ?? '').toString(),
      imageUrl: _normalizeFoodImage(
        (map['image_url'] ?? '').toString(),
        category,
      ),
      price: (map['price'] ?? 0).toDouble(),
      isFeatured: (map['is_featured'] ?? false) as bool,
      category: category,
      discountPercent: _toInt(map['discount_percent']),
    );
  }

  double get originalPrice {
    if (discountPercent <= 0) return price;
    return price / (1 - (discountPercent / 100));
  }

  static int _toInt(dynamic value) {
    if (value is int) return value;
    if (value is double) return value.round();
    if (value is String) return int.tryParse(value) ?? 0;
    return 0;
  }

  static String _inferCategory(String name) {
    final n = name.toLowerCase();
    if (n.contains('trà') || n.contains('sữa') || n.contains('matcha')) {
      return 'Trà sữa';
    }
    if (n.contains('cơm')) return 'Cơm';
    if (n.contains('bún') || n.contains('phở') || n.contains('mì')) {
      return 'Bún';
    }
    return 'Ăn vặt';
  }

  static String _normalizeFoodImage(String url, String category) {
    if (url.isNotEmpty && !url.contains('source.unsplash.com')) {
      return url;
    }

    switch (category) {
      case 'Trà sữa':
        return 'https://images.unsplash.com/photo-1558857563-b371033873b8?auto=format&fit=crop&w=1200&q=80';
      case 'Cơm':
        return 'https://images.unsplash.com/photo-1516684732162-798a0062be99?auto=format&fit=crop&w=1200&q=80';
      case 'Bún':
        return 'https://images.unsplash.com/photo-1582878826629-29b7ad1cdc43?auto=format&fit=crop&w=1200&q=80';
      default:
        return 'https://images.unsplash.com/photo-1504674900247-0877df9cc836?auto=format&fit=crop&w=1200&q=80';
    }
  }
}

class HomeData {
  final List<StoreModel> stores;
  final List<MenuItemModel> featuredItems;

  const HomeData({required this.stores, required this.featuredItems});
}

class FoodCustomization {
  final String size;
  final String sugar;
  final String ice;
  final List<String> toppings;

  const FoodCustomization({
    required this.size,
    required this.sugar,
    required this.ice,
    required this.toppings,
  });

  double get extraPrice {
    final sizeExtra = size == 'L' ? 7000 : 0;
    final toppingExtra = toppings.length * 5000;
    return (sizeExtra + toppingExtra).toDouble();
  }

  String get summary {
    final toppingsText = toppings.isEmpty ? 'Không thêm' : toppings.join(', ');
    return 'Size $size | Đường: $sugar | Đá: $ice | Topping: $toppingsText';
  }
}

class CartItemModel {
  final MenuItemModel item;
  final FoodCustomization customization;
  final int quantity;

  const CartItemModel({
    required this.item,
    required this.customization,
    required this.quantity,
  });

  double get unitPrice => item.price + customization.extraPrice;
  double get totalPrice => unitPrice * quantity;
}
