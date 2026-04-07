import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import 'shipping_address_model.dart';
import 'shipping_address_repository.dart';

class AddressFormPage extends StatefulWidget {
  final ShippingAddress? initial;

  const AddressFormPage({super.key, this.initial});

  @override
  State<AddressFormPage> createState() => _AddressFormPageState();
}

class _AddressFormPageState extends State<AddressFormPage> {
  final _repo = ShippingAddressRepository();

  late final TextEditingController _recipientController;
  late final TextEditingController _addressController;
  late final TextEditingController _phoneController;
  bool _isDefault = false;
  bool _loading = false;

  @override
  void initState() {
    super.initState();
    _recipientController = TextEditingController(
      text: widget.initial?.recipientName,
    );
    _addressController = TextEditingController(
      text: widget.initial?.fullAddress,
    );
    _phoneController = TextEditingController(text: widget.initial?.phoneNumber);
    _isDefault = widget.initial?.isDefault ?? false;
  }

  @override
  void dispose() {
    _recipientController.dispose();
    _addressController.dispose();
    _phoneController.dispose();
    super.dispose();
  }

  Future<void> _save() async {
    final recipientName = _recipientController.text.trim();
    final address = _addressController.text.trim();
    final phone = _phoneController.text.trim();

    if (recipientName.isEmpty || address.isEmpty || phone.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Vui lòng nhập người nhận, địa chỉ và số điện thoại'),
        ),
      );
      return;
    }

    setState(() => _loading = true);
    try {
      final saved = widget.initial == null
          ? await _repo.create(
              recipientName: recipientName,
              fullAddress: address,
              phoneNumber: phone,
              isDefault: _isDefault,
            )
          : await _repo.update(
              id: widget.initial!.id,
              recipientName: recipientName,
              fullAddress: address,
              phoneNumber: phone,
              isDefault: _isDefault,
            );

      if (!mounted) return;
      Navigator.of(context).pop(saved);
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text('Lỗi khi lưu địa chỉ: $e')));
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final isEdit = widget.initial != null;

    return Scaffold(
      appBar: AppBar(title: Text(isEdit ? 'Sửa địa chỉ' : 'Thêm địa chỉ')),
      body: SafeArea(
        child: ListView(
          padding: const EdgeInsets.all(16),
          children: [
            TextField(
              controller: _recipientController,
              decoration: const InputDecoration(
                labelText: 'Người nhận',
                hintText: 'Họ tên người nhận hàng',
                border: OutlineInputBorder(),
                prefixIcon: Icon(Icons.person_outline),
              ),
            ),
            const SizedBox(height: 16),
            TextField(
              controller: _addressController,
              decoration: const InputDecoration(
                labelText: 'Địa chỉ chi tiết',
                border: OutlineInputBorder(),
                prefixIcon: Icon(Icons.location_on_outlined),
              ),
              minLines: 2,
              maxLines: 4,
            ),
            const SizedBox(height: 16),
            TextField(
              controller: _phoneController,
              keyboardType: TextInputType.phone,
              decoration: const InputDecoration(
                labelText: 'Số điện thoại nhận hàng',
                border: OutlineInputBorder(),
                prefixIcon: Icon(Icons.phone_android_outlined),
              ),
            ),
            const SizedBox(height: 16),
            SwitchListTile(
              title: const Text('Đặt làm địa chỉ mặc định'),
              value: _isDefault,
              activeColor: const Color(0xFF0E9F6E),
              onChanged: (val) => setState(() => _isDefault = val),
            ),
            const SizedBox(height: 24),
            SizedBox(
              height: 52,
              child: ElevatedButton(
                onPressed: _loading ? null : _save,
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFF0E9F6E),
                  foregroundColor: Colors.white,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
                child: _loading
                    ? const CircularProgressIndicator(color: Colors.white)
                    : const Text(
                        'LƯU ĐỊA CHỈ',
                        style: TextStyle(
                          fontWeight: FontWeight.bold,
                          fontSize: 16,
                        ),
                      ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
