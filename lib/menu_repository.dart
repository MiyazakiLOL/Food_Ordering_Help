import 'package:supabase_flutter/supabase_flutter.dart';
import 'menu_models.dart';

class MenuRepository {
  Future<HomeData> fetchHomeData({int page = 0, int pageSize = 10}) async {
    try {
      final supabase = Supabase.instance.client;
      
      // 1. Lấy danh sách cửa hàng (giữ nguyên hoặc cũng có thể phân trang nếu cần)
      final storesResp = await supabase
          .from('Stores')
          .select('id, name, image_url, rating')
          .order('rating', ascending: false)
          .limit(10);

      // 2. Tính toán range cho phân trang sản phẩm
      final int from = page * pageSize;
      final int to = from + pageSize - 1;

      // 3. Lấy danh sách sản phẩm có phân trang
      final productsResp = await supabase
          .from('Products')
          .select('id, category_id, store_id, name, description, price, image_url, is_available, Categories(name)')
          .eq('is_available', true)
          .range(from, to); // Dùng range để phân trang trong Supabase

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
