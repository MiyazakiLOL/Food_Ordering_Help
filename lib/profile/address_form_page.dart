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

  bool _loading = false;

  String _friendlySaveError(Object error) {
    if (error is AuthException) {
      return 'Phiên đăng nhập đã hết hạn. Vui lòng đăng nhập lại.';
    }

    if (error is PostgrestException) {
      final code = (error.code ?? '').toString();
      final message = error.message.toString().toLowerCase();
      final details = (error.details ?? '').toString().toLowerCase();
      final combined = '$message $details';

      if (code == 'PGRST205' || combined.contains('could not find the table')) {
        return 'Chưa tạo bảng địa chỉ trên Supabase (shipping_addresses).';
      }

      if (combined.contains('row-level security') || combined.contains('rls')) {
        return 'Bị chặn quyền truy cập (RLS). Hãy tạo policy cho bảng địa chỉ.';
      }

      if (combined.contains('permission denied')) {
        return 'Không đủ quyền để lưu địa chỉ. Hãy kiểm tra policy/quyền DB.';
      }

      if (combined.contains('column') && combined.contains('does not exist')) {
        return 'Cấu trúc bảng địa chỉ chưa đúng (thiếu/sai tên cột).';
      }

      return 'Không thể lưu địa chỉ. Hãy kiểm tra cấu hình Supabase.';
    }

    return 'Lưu địa chỉ thất bại';
  }

  @override
  void initState() {
    super.initState();
    _addressController = TextEditingController(text: widget.initial?.address);
    _phoneController = TextEditingController(text: widget.initial?.phone);
    _noteController = TextEditingController(text: widget.initial?.note);
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
          ? await _repo.create(address: address, phone: phone, note: note)
          : await _repo.update(
              id: widget.initial!.id,
              address: address,
              phone: phone,
              note: note,
            );

      if (!mounted) return;
      Navigator.of(context).pop(saved);
    } catch (e, st) {
      if (!mounted) return;
      debugPrint('Save address failed: $e');
      debugPrintStack(stackTrace: st);
      final message = _friendlySaveError(e);
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text(message)));
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
              textCapitalization: TextCapitalization.sentences,
              decoration: const InputDecoration(
                labelText: 'Địa chỉ (phòng trọ, toà, ...)',
                border: OutlineInputBorder(),
              ),
              minLines: 2,
              maxLines: 4,
            ),
            const SizedBox(height: 12),
            TextField(
              controller: _phoneController,
              keyboardType: TextInputType.phone,
              decoration: const InputDecoration(
                labelText: 'Số điện thoại',
                border: OutlineInputBorder(),
              ),
            ),
            const SizedBox(height: 12),
            TextField(
              controller: _noteController,
              textCapitalization: TextCapitalization.sentences,
              decoration: const InputDecoration(
                labelText: 'Lời nhắn (tuỳ chọn)',
                hintText: 'Ví dụ: Đến cổng KTX gọi mình xuống lấy',
                border: OutlineInputBorder(),
              ),
              minLines: 2,
              maxLines: 4,
            ),
            const SizedBox(height: 16),
            SizedBox(
              height: 48,
              child: ElevatedButton(
                onPressed: _loading ? null : _save,
                child: _loading
                    ? const SizedBox(
                        width: 18,
                        height: 18,
                        child: CircularProgressIndicator(strokeWidth: 2),
                      )
                    : const Text('Lưu'),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
