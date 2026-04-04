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

  Future<List<ShippingAddress>> listMine() async {
    final rows = await _client
        .from('shipping_addresses')
        .select()
        .eq('user_id', _userId)
        .order('created_at', ascending: false);

    final list = (rows as List).cast<Map<String, dynamic>>();
    return list.map(ShippingAddress.fromJson).toList();
  }

  Future<ShippingAddress> create({
    required String address,
    required String phone,
    required String note,
  }) async {
    final row = await _client
        .from('shipping_addresses')
        .insert({
          'user_id': _userId,
          'address': address,
          'phone': phone,
          'note': note,
        })
        .select()
        .single();

    return ShippingAddress.fromJson(row as Map<String, dynamic>);
  }

  Future<ShippingAddress> update({
    required String id,
    required String address,
    required String phone,
    required String note,
  }) async {
    final row = await _client
        .from('shipping_addresses')
        .update({'address': address, 'phone': phone, 'note': note})
        .eq('id', id)
        .eq('user_id', _userId)
        .select()
        .single();

    return ShippingAddress.fromJson(row as Map<String, dynamic>);
  }

  Future<void> delete(String id) async {
    await _client
        .from('shipping_addresses')
        .delete()
        .eq('id', id)
        .eq('user_id', _userId);
  }
}
