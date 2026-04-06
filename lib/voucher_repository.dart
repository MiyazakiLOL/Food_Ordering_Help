import 'package:supabase_flutter/supabase_flutter.dart';
import 'voucher_model.dart';

class VoucherRepository {
  final _supabase = Supabase.instance.client;

  /// Tìm và lấy thông tin voucher theo mã
  Future<VoucherModel?> getVoucherByCode(String code) async {
    try {
      print('🔍 Searching for voucher: $code');

      final allVouchers = await _supabase.from('Vouchers').select();

      print('📋 Total vouchers in DB: ${allVouchers.length}');

      final matchingVouchers = allVouchers.where((v) {
        final dbCode = (v['code'] ?? '').toString().toUpperCase().trim();
        final searchCode = code.toUpperCase().trim();
        return dbCode == searchCode;
      }).toList();

      if (matchingVouchers.isEmpty) {
        print('❌ Voucher not found');
        return null;
      }

      final voucher = VoucherModel.fromMap(matchingVouchers[0]);
      print('✅ Voucher found: ${voucher.code}, valid: ${voucher.isValid}');

      return voucher.isValid ? voucher : null;
    } catch (e) {
      print('❌ Error fetching voucher: $e');
      return null;
    }
  }

  /// Lấy tất cả voucher hợp lệ
  Future<List<VoucherModel>> getAllValidVouchers() async {
    try {
      final response = await _supabase.from('Vouchers').select();

      if (response.isEmpty) return [];

      final vouchers = (response as List)
          .map((v) => VoucherModel.fromMap(v))
          .where((v) => v.isValid)
          .toList();

      return vouchers;
    } catch (e) {
      print('Error fetching vouchers: $e');
      return [];
    }
  }

  /// Gợi ý voucher tốt nhất dựa trên giỏ hàng
  Future<VoucherModel?> suggestBestVoucher(double subtotal) async {
    final vouchers = await getAllValidVouchers();

    final applicable = vouchers
        .where((v) => v.minOrderValue <= subtotal)
        .toList();

    if (applicable.isEmpty) return null;

    applicable.sort((a, b) {
      final discountA = a.calculateDiscount(subtotal);
      final discountB = b.calculateDiscount(subtotal);
      return discountB.compareTo(discountA);
    });

    return applicable.first;
  }
}
