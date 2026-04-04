import 'package:supabase_flutter/supabase_flutter.dart';
import 'shipping_address_model.dart';

class ShippingAddressRepository {
  final SupabaseClient _client;

  ShippingAddressRepository({SupabaseClient? client})
    : _client = client ?? Supabase.instance.client;

  String get _userId {
    final user = _client.auth.currentUser;
    if (user == null) {
      throw const AuthException('User is not signed in');
    }
    return user.id;
  }

  // Tên bảng là 'ShippingAddresses' (có viết hoa)
  final String _tableName = 'ShippingAddresses';

  Future<List<ShippingAddress>> listMine() async {
    final rows = await _client
        .from(_tableName)
        .select()
        .eq('user_id', _userId)
        .order('created_at', ascending: false);

    final list = (rows as List).cast<Map<String, dynamic>>();
    return list.map(ShippingAddress.fromJson).toList();
  }

  Future<ShippingAddress> create({
    required String fullAddress,
    required String phoneNumber,
    required String note,
    bool isDefault = false,
  }) async {
    final row = await _client
        .from(_tableName)
        .insert({
          'user_id': _userId,
          'full_address': fullAddress,
          'phone_number': phoneNumber,
          'note': note,
          'is_default': isDefault,
        })
        .select()
        .single();

    return ShippingAddress.fromJson(row as Map<String, dynamic>);
  }

  Future<ShippingAddress> update({
    required String id,
    required String fullAddress,
    required String phoneNumber,
    required String note,
    bool isDefault = false,
  }) async {
    final row = await _client
        .from(_tableName)
        .update({
          'full_address': fullAddress,
          'phone_number': phoneNumber,
          'note': note,
          'is_default': isDefault,
        })
        .eq('id', id)
        .eq('user_id', _userId)
        .select()
        .single();

    return ShippingAddress.fromJson(row as Map<String, dynamic>);
  }

  Future<void> delete(String id) async {
    await _client
        .from(_tableName)
        .delete()
        .eq('id', id)
        .eq('user_id', _userId);
  }
}
