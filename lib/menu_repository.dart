import 'package:supabase_flutter/supabase_flutter.dart';
import 'menu_models.dart';

class MenuRepository {
  final _supabase = Supabase.instance.client;

  Future<HomeData> fetchHomeData({
    int page = 0,
    int pageSize = 10,
    String? storeId,
    String? category,
  }) async {
    try {
      // 1. Lấy danh sách cửa hàng
      final storesResp = await _supabase
          .from('Stores')
          .select('id, name, image_url, rating')
          .order('rating', ascending: false)
          .limit(10);

      // 2. Xây dựng truy vấn cho sản phẩm
      // Sử dụng !inner khi lọc theo bảng liên kết (Categories) để loại bỏ các sản phẩm không thuộc category đó
      String selectStr = 'id, category_id, store_id, name, description, price, image_url, is_available, Categories(name)';
      if (category != null && category != 'Tất cả' && category.isNotEmpty) {
        selectStr = 'id, category_id, store_id, name, description, price, image_url, is_available, Categories!inner(name)';
      }

      var query = _supabase
          .from('Products')
          .select(selectStr)
          .eq('is_available', true);

      // Lọc theo cửa hàng nếu có
      if (storeId != null && storeId.isNotEmpty) {
        query = query.eq('store_id', storeId);
      }

      // Lọc theo danh mục nếu có (ngoại trừ 'Tất cả')
      if (category != null && category != 'Tất cả' && category.isNotEmpty) {
        query = query.eq('Categories.name', category);
      }

      // 3. Thực hiện phân trang dựa trên kết quả đã lọc
      final int from = page * pageSize;
      final int to = from + pageSize - 1;
      
      final productsResp = await query
          .order('name', ascending: true)
          .range(from, to);

      final stores = (storesResp as List)
          .map((e) => StoreModel.fromMap(e as Map<String, dynamic>))
          .toList();

      final items = (productsResp as List)
          .map((e) => MenuItemModel.fromMap(e as Map<String, dynamic>))
          .toList();

      return HomeData(stores: stores, featuredItems: items);
    } catch (e) {
      print('Lỗi fetchHomeData: $e');
      return HomeData(stores: [], featuredItems: []);
    }
  }
}
