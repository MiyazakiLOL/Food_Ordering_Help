import 'package:supabase_flutter/supabase_flutter.dart';
import 'voucher_model.dart';

class VoucherRepository {
  final _supabase = Supabase.instance.client;

  /// Tìm và lấy thông tin voucher theo mã
  Future<VoucherModel?> getVoucherByCode(String code) async {
    try {
      final cleanCode = code.trim().toUpperCase();
      print('🔍 Đang tìm voucher: "$cleanCode"');

      // Lấy voucher theo mã, chưa lọc is_active để biết chính xác lỗi
      final response = await _supabase
          .from('Vouchers')
          .select()
          .ilike('code', cleanCode)
          .maybeSingle();

      if (response == null) {
        print('❌ Không tìm thấy mã voucher này trong hệ thống');
        return null;
      }

      final voucher = VoucherModel.fromMap(response);
      
      // Kiểm tra các điều kiện và log ra để debug
      if (!voucher.isActive) {
        print('❌ Voucher "${voucher.code}" đang bị khóa (is_active = false)');
        return null;
      }

      if (!voucher.isValid) {
        print('❌ Voucher "${voucher.code}" đã hết hạn (Hạn: ${voucher.expirationDate})');
        return null;
      }

      print('✅ Voucher hợp lệ: ${voucher.code}');
      return voucher;
    } catch (e) {
      print('❌ Lỗi hệ thống khi tìm voucher: $e');
      return null;
    }
  }

  /// Lấy tất cả voucher đang hoạt động và còn hạn
  Future<List<VoucherModel>> getAllValidVouchers() async {
    try {
      // Lấy toàn bộ để đảm bảo không bị lỗi format ngày tháng khi query
      final response = await _supabase.from('Vouchers').select();

      if (response == null) return [];

      final list = (response as List).map((v) => VoucherModel.fromMap(v)).toList();
      
      // Lọc tại App để đảm bảo tính chính xác của DateTime
      return list.where((v) => v.isValid).toList();
    } catch (e) {
      print('Error fetching vouchers: $e');
      return [];
    }
  }

  /// Gợi ý voucher tốt nhất dựa trên giá trị đơn hàng
  Future<VoucherModel?> suggestBestVoucher(double subtotal) async {
    final vouchers = await getAllValidVouchers();

    final applicable = vouchers
        .where((v) => v.minOrderValue <= subtotal)
        .toList();

    if (applicable.isEmpty) return null;

    // Sắp xếp voucher có số tiền giảm cao nhất lên đầu
    applicable.sort((a, b) => b.discountAmount.compareTo(a.discountAmount));

    return applicable.first;
  }
}
