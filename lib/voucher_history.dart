import 'package:shared_preferences/shared_preferences.dart';

class VoucherHistory {
  static const String _key = 'used_vouchers_history';

  /// Thêm voucher vào lịch sử
  static Future<void> addToHistory(String code) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final history = prefs.getStringList(_key) ?? [];
      
      // Nếu đã có trong lịch sử, xóa và thêm lại (để hiển thị gần đây nhất)
      history.remove(code);
      history.insert(0, code);
      
      // Lưu tối đa 10 vouchers gần đây
      if (history.length > 10) {
        history.removeRange(10, history.length);
      }
      
      await prefs.setStringList(_key, history);
      print('💳 Added $code to voucher history');
    } catch (e) {
      print('Error adding to history: $e');
    }
  }

  /// Lấy lịch sử vouchers
  static Future<List<String>> getHistory() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      return prefs.getStringList(_key) ?? [];
    } catch (e) {
      print('Error getting history: $e');
      return [];
    }
  }

  /// Xóa lịch sử
  static Future<void> clearHistory() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.remove(_key);
      print('💳 Voucher history cleared');
    } catch (e) {
      print('Error clearing history: $e');
    }
  }
}
