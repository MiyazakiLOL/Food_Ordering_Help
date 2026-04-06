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

  Map<String, dynamic> toJson() => {
    'id': id,
    'name': name,
    'image_url': imageUrl,
    'rating': rating,
  };
}

class MenuItemModel {
  final String id;
  final String categoryId;
  final String storeId;
  final String name;
  final String description;
  final String imageUrl;
  final double price;
  final bool isAvailable;
  final String categoryName;

  const MenuItemModel({
    required this.id,
    required this.categoryId,
    required this.storeId,
    required this.name,
    required this.description,
    required this.imageUrl,
    required this.price,
    required this.isAvailable,
    required this.categoryName,
  });

  factory MenuItemModel.fromMap(Map<String, dynamic> map) {
    final categoryData = map['Categories'];
    String catName = 'Món ăn';
    if (categoryData != null && categoryData['name'] != null) {
      catName = categoryData['name'].toString();
    }

    return MenuItemModel(
      id: map['id'].toString(),
      categoryId: (map['category_id'] ?? '').toString(),
      storeId: (map['store_id'] ?? '').toString(),
      name: (map['name'] ?? 'Món ăn').toString(),
      description: (map['description'] ?? '').toString(),
      imageUrl: (map['image_url'] ?? '').toString().isEmpty 
          ? 'https://images.unsplash.com/photo-1504674900247-0877df9cc836?auto=format&fit=crop&w=1200&q=80'
          : map['image_url'].toString(),
      price: (map['price'] ?? 0).toDouble(),
      isAvailable: map['is_available'] ?? true,
      categoryName: catName,
    );
  }

  Map<String, dynamic> toJson() => {
    'id': id,
    'category_id': categoryId,
    'store_id': storeId,
    'name': name,
    'description': description,
    'image_url': imageUrl,
    'price': price,
    'is_available': isAvailable,
    'Categories': {'name': categoryName},
  };

  double get originalPrice => price;
  int get discountPercent => 0;
  String get category => categoryName;
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

  Map<String, dynamic> toJson() => {
    'size': size,
    'sugar': sugar,
    'ice': ice,
    'toppings': toppings,
  };

  factory FoodCustomization.fromJson(Map<String, dynamic> json) => FoodCustomization(
    size: json['size'],
    sugar: json['sugar'],
    ice: json['ice'],
    toppings: List<String>.from(json['toppings']),
  );
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

  Map<String, dynamic> toJson() => {
    'item': item.toJson(),
    'customization': customization.toJson(),
    'quantity': quantity,
  };

  factory CartItemModel.fromJson(Map<String, dynamic> json) => CartItemModel(
    item: MenuItemModel.fromMap(json['item']),
    customization: FoodCustomization.fromJson(json['customization']),
    quantity: json['quantity'],
  );
}
