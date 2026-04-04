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

  late final TextEditingController _addressController;
  late final TextEditingController _phoneController;
  late final TextEditingController _noteController;
  bool _isDefault = false;
  bool _loading = false;

  @override
  void initState() {
    super.initState();
    _addressController = TextEditingController(text: widget.initial?.fullAddress);
    _phoneController = TextEditingController(text: widget.initial?.phoneNumber);
    _noteController = TextEditingController(text: widget.initial?.note);
    _isDefault = widget.initial?.isDefault ?? false;
  }

  @override
  void dispose() {
    _addressController.dispose();
    _phoneController.dispose();
    _noteController.dispose();
    super.dispose();
  }

  Future<void> _save() async {
    final address = _addressController.text.trim();
    final phone = _phoneController.text.trim();
    final note = _noteController.text.trim();

    if (address.isEmpty || phone.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Vui lòng nhập địa chỉ và số điện thoại')),
      );
      return;
    }

    setState(() => _loading = true);
    try {
      final saved = widget.initial == null
          ? await _repo.create(
              fullAddress: address,
              phoneNumber: phone,
              note: note,
              isDefault: _isDefault,
            )
          : await _repo.update(
              id: widget.initial!.id,
              fullAddress: address,
              phoneNumber: phone,
              note: note,
              isDefault: _isDefault,
            );

      if (!mounted) return;
      Navigator.of(context).pop(saved);
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Lỗi khi lưu địa chỉ: $e')),
      );
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
            TextField(
              controller: _noteController,
              decoration: const InputDecoration(
                labelText: 'Ghi chú cho shipper',
                hintText: 'Ví dụ: Để ở bảo vệ, gọi trước khi đến...',
                border: OutlineInputBorder(),
                prefixIcon: Icon(Icons.note_alt_outlined),
              ),
              maxLines: 2,
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
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                ),
                child: _loading
                    ? const CircularProgressIndicator(color: Colors.white)
                    : const Text('LƯU ĐỊA CHỈ', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
