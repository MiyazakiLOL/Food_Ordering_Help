import 'package:supabase_flutter/supabase_flutter.dart';

import 'menu_models.dart';

class MenuRepository {
  Future<HomeData> fetchHomeData() async {
    try {
      final supabase = Supabase.instance.client;
      final storesResp = await supabase
          .from('stores')
          .select('id, name, image_url, rating')
          .order('rating', ascending: false)
          .limit(10);

      final featuredResp = await supabase
          .from('menu_items')
          .select(
            'id, store_id, name, description, image_url, price, is_featured',
          )
          .eq('is_featured', true)
          .order('price')
          .limit(20);

      final stores = (storesResp as List)
          .map((e) => StoreModel.fromMap(e as Map<String, dynamic>))
          .toList();

      final items = (featuredResp as List)
          .map((e) => MenuItemModel.fromMap(e as Map<String, dynamic>))
          .toList();

      if (stores.isNotEmpty && items.isNotEmpty) {
        return HomeData(stores: stores, featuredItems: items);
      }
    } catch (_) {
      // Fallback for first-time setup when DB tables are not ready yet.
    }

    return HomeData(stores: _sampleStores, featuredItems: _sampleItems);
  }

  static const List<StoreModel> _sampleStores = [
    StoreModel(
      id: 's1',
      name: 'Trà Sữa Nhà Làm',
      imageUrl:
          'https://images.unsplash.com/photo-1558857563-b371033873b8?auto=format&fit=crop&w=1200&q=80',
      rating: 4.9,
    ),
    StoreModel(
      id: 's2',
      name: 'Bún Đậu 79',
      imageUrl:
          'https://images.unsplash.com/photo-1559847844-5315695dadae?auto=format&fit=crop&w=1200&q=80',
      rating: 4.7,
    ),
    StoreModel(
      id: 's3',
      name: 'Cơm Gà Đà Nẵng',
      imageUrl:
          'https://images.unsplash.com/photo-1516684732162-798a0062be99?auto=format&fit=crop&w=1200&q=80',
      rating: 4.8,
    ),
    StoreModel(
      id: 's4',
      name: 'Phở Bò Gia Truyền',
      imageUrl:
          'https://images.unsplash.com/photo-1582878826629-29b7ad1cdc43?auto=format&fit=crop&w=1200&q=80',
      rating: 4.9,
    ),
    StoreModel(
      id: 's5',
      name: 'Đồ Ăn Vặt Cô Ba',
      imageUrl:
          'https://images.unsplash.com/photo-1504674900247-0877df9cc836?auto=format&fit=crop&w=1200&q=80',
      rating: 4.6,
    ),
  ];

  static const List<MenuItemModel> _sampleItems = [
    MenuItemModel(
      id: 'f1',
      storeId: 's1',
      name: 'Trà Sữa Trân Châu Đường Đen',
      description: 'Vị sữa đậm, trân châu dẻo, uống là mê.',
      imageUrl:
          'https://images.unsplash.com/photo-1558857563-b371033873b8?auto=format&fit=crop&w=1200&q=80',
      price: 39000,
      isFeatured: true,
      category: 'Trà sữa',
      discountPercent: 25,
    ),
    MenuItemModel(
      id: 'f2',
      storeId: 's1',
      name: 'Hồng Trà Kem Cheese',
      description: 'Hồng trà thơm, lớp kem mặn béo gây nghiện.',
      imageUrl:
          'https://images.unsplash.com/photo-1497534446932-c925b458314e?auto=format&fit=crop&w=1200&q=80',
      price: 45000,
      isFeatured: true,
      category: 'Trà sữa',
      discountPercent: 15,
    ),
    MenuItemModel(
      id: 'f3',
      storeId: 's3',
      name: 'Cơm Gà Quay Sốt Cay',
      description: 'Gà giòn da, sốt cay vừa, cơm nóng hổi.',
      imageUrl:
          'https://images.unsplash.com/photo-1516684732162-798a0062be99?auto=format&fit=crop&w=1200&q=80',
      price: 55000,
      isFeatured: true,
      category: 'Cơm',
      discountPercent: 0,
    ),
    MenuItemModel(
      id: 'f4',
      storeId: 's4',
      name: 'Phở Bò Tái Nạm',
      description: 'Nước dùng ngọt thanh, bánh phở mềm dai.',
      imageUrl:
          'https://images.unsplash.com/photo-1582878826629-29b7ad1cdc43?auto=format&fit=crop&w=1200&q=80',
      price: 62000,
      isFeatured: true,
      category: 'Bún',
      discountPercent: 10,
    ),
    MenuItemModel(
      id: 'f5',
      storeId: 's5',
      name: 'Bánh Tráng Trộn Đặc Biệt',
      description: 'Đậm vị me, khô bò, trứng cút và xoài xanh.',
      imageUrl:
          'https://images.unsplash.com/photo-1504754524776-8f4f37790ca0?auto=format&fit=crop&w=1200&q=80',
      price: 30000,
      isFeatured: true,
      category: 'Ăn vặt',
      discountPercent: 30,
    ),
    MenuItemModel(
      id: 'f6',
      storeId: 's2',
      name: 'Bún Đậu Mắm Tôm Combo',
      description: 'Đậu rán giòn, thịt luộc, chả cốm, mắm tôm chuẩn vị.',
      imageUrl:
          'https://images.unsplash.com/photo-1559847844-5315695dadae?auto=format&fit=crop&w=1200&q=80',
      price: 68000,
      isFeatured: true,
      category: 'Bún',
      discountPercent: 0,
    ),
    MenuItemModel(
      id: 'f7',
      storeId: 's3',
      name: 'Cơm Sườn Nướng Mật Ong',
      description: 'Sườn mềm, thơm mùi nướng than, ăn kèm đồ chua.',
      imageUrl:
          'https://images.unsplash.com/photo-1529042410759-befb1204b468?auto=format&fit=crop&w=1200&q=80',
      price: 59000,
      isFeatured: true,
      category: 'Cơm',
      discountPercent: 20,
    ),
    MenuItemModel(
      id: 'f8',
      storeId: 's1',
      name: 'Trà Đào Cam Sả',
      description: 'Mát lạnh, thanh vị trà, topping đào giòn ngon.',
      imageUrl:
          'https://images.unsplash.com/photo-1497534446932-c925b458314e?auto=format&fit=crop&w=1200&q=80',
      price: 42000,
      isFeatured: true,
      category: 'Trà sữa',
      discountPercent: 10,
    ),
    MenuItemModel(
      id: 'f9',
      storeId: 's5',
      name: 'Khoai Tây Lắc Phô Mai',
      description: 'Khoai chiên vàng, lắc đều phô mai béo thơm.',
      imageUrl:
          'https://images.unsplash.com/photo-1576107232684-1279f390859f?auto=format&fit=crop&w=1200&q=80',
      price: 35000,
      isFeatured: true,
      category: 'Ăn vặt',
      discountPercent: 15,
    ),
    MenuItemModel(
      id: 'f10',
      storeId: 's4',
      name: 'Bún Bò Huế Đặc Biệt',
      description: 'Nước lèo đậm đà, sợi bún to, chả và giò đầy đặn.',
      imageUrl:
          'https://images.unsplash.com/photo-1625937753309-8f0d8b0f31eb?auto=format&fit=crop&w=1200&q=80',
      price: 70000,
      isFeatured: true,
      category: 'Bún',
      discountPercent: 5,
    ),
    MenuItemModel(
      id: 'f11',
      storeId: 's2',
      name: 'Nem Chua Rán Hà Nội',
      description: 'Giòn rụm bên ngoài, chấm tương ớt cực cuốn.',
      imageUrl:
          'https://images.unsplash.com/photo-1600891964599-f61ba0e24092?auto=format&fit=crop&w=1200&q=80',
      price: 45000,
      isFeatured: true,
      category: 'Ăn vặt',
      discountPercent: 10,
    ),
    MenuItemModel(
      id: 'f12',
      storeId: 's5',
      name: 'Bánh Gạo Cay Tokbokki',
      description: 'Sốt cay ngọt Hàn Quốc, phô mai kéo sợi.',
      imageUrl:
          'https://images.unsplash.com/photo-1546069901-ba9599a7e63c?auto=format&fit=crop&w=1200&q=80',
      price: 52000,
      isFeatured: true,
      category: 'Ăn vặt',
      discountPercent: 20,
    ),
    MenuItemModel(
      id: 'f13',
      storeId: 's3',
      name: 'Mì Ý Sốt Bò Bằm',
      description: 'Sợi mì dai vừa, sốt cà chua bò bằm đậm vị.',
      imageUrl:
          'https://images.unsplash.com/photo-1621996346565-e3dbc646d9a9?auto=format&fit=crop&w=1200&q=80',
      price: 64000,
      isFeatured: true,
      category: 'Ăn vặt',
      discountPercent: 0,
    ),
    MenuItemModel(
      id: 'f14',
      storeId: 's4',
      name: 'Gỏi Cuốn Tôm Thịt',
      description: 'Rau tươi, tôm thịt đầy đặn, nước chấm đậu phộng.',
      imageUrl:
          'https://images.unsplash.com/photo-1569718212165-3a8278d5f624?auto=format&fit=crop&w=1200&q=80',
      price: 38000,
      isFeatured: true,
      category: 'Ăn vặt',
      discountPercent: 8,
    ),
    MenuItemModel(
      id: 'f15',
      storeId: 's1',
      name: 'Matcha Latte Kem Sữa',
      description: 'Matcha thơm dịu, kem sữa béo mượt.',
      imageUrl:
          'https://images.unsplash.com/photo-1515823064-d6e0c04616a7?auto=format&fit=crop&w=1200&q=80',
      price: 49000,
      isFeatured: true,
      category: 'Trà sữa',
      discountPercent: 12,
    ),
    MenuItemModel(
      id: 'f16',
      storeId: 's5',
      name: 'Há Cảo Tôm Hấp',
      description: 'Vỏ mỏng mềm, nhân tôm ngọt tự nhiên.',
      imageUrl:
          'https://images.unsplash.com/photo-1546069901-ba9599a7e63c?auto=format&fit=crop&w=1200&q=80',
      price: 47000,
      isFeatured: true,
      category: 'Ăn vặt',
      discountPercent: 5,
    ),
  ];
}
