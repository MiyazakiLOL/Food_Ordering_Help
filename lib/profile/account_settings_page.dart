import 'dart:io';
import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:image_picker/image_picker.dart';

class AccountSettingsPage extends StatefulWidget {
  const AccountSettingsPage({super.key});

  @override
  State<AccountSettingsPage> createState() => _AccountSettingsPageState();
}

class _AccountSettingsPageState extends State<AccountSettingsPage> {
  final _nameController = TextEditingController();
  bool _saving = false;
  String? _avatarUrl;
  final ImagePicker _picker = ImagePicker();

  User? get _user => Supabase.instance.client.auth.currentUser;

  @override
  void initState() {
    super.initState();
    final user = _user;
    _nameController.text = (user?.userMetadata?['full_name'] ?? '').toString();
    _avatarUrl = user?.userMetadata?['avatar_url'] as String?;
  }

  @override
  void dispose() {
    _nameController.dispose();
    super.dispose();
  }

  Future<void> _pickAndUploadImage() async {
    final XFile? image = await _picker.pickImage(
      source: ImageSource.gallery,
      imageQuality: 50, // Giảm dung lượng ảnh
    );

    if (image == null) return;

    setState(() => _saving = true);

    try {
      final file = File(image.path);
      final fileExt = image.path.split('.').last;
      final fileName = '${DateTime.now().toIso8601String()}.$fileExt';
      final filePath = '${_user!.id}/$fileName';

      // 1. Tải ảnh lên Supabase Storage (Bucket: 'avatars')
      await Supabase.instance.client.storage.from('avatars').upload(
            filePath,
            file,
            fileOptions: const FileOptions(upsert: true),
          );

      // 2. Lấy URL công khai của ảnh vừa tải lên
      final String publicUrl = Supabase.instance.client.storage
          .from('avatars')
          .getPublicUrl(filePath);

      // 3. Cập nhật avatar_url vào Metadata của User
      await Supabase.instance.client.auth.updateUser(
        UserAttributes(data: {'avatar_url': publicUrl}),
      );

      setState(() => _avatarUrl = publicUrl);

      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Đã cập nhật ảnh đại diện')),
      );
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Lỗi tải ảnh: $e')),
      );
    } finally {
      if (mounted) setState(() => _saving = false);
    }
  }

  Future<void> _saveName() async {
    final name = _nameController.text.trim();
    setState(() => _saving = true);
    try {
      await Supabase.instance.client.auth.updateUser(
        UserAttributes(data: {'full_name': name}),
      );
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Đã cập nhật tên')),
      );
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Lỗi: $e')),
      );
    } finally {
      if (mounted) setState(() => _saving = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;

    return Scaffold(
      appBar: AppBar(title: const Text('Tài khoản')),
      body: SafeArea(
        child: ListView(
          padding: const EdgeInsets.all(16),
          children: [
            // Avatar Section
            Center(
              child: Stack(
                children: [
                  CircleAvatar(
                    radius: 60,
                    backgroundColor: colorScheme.primaryContainer,
                    backgroundImage: _avatarUrl != null ? NetworkImage(_avatarUrl!) : null,
                    child: _avatarUrl == null
                        ? Icon(Icons.person, size: 60, color: colorScheme.primary)
                        : null,
                  ),
                  Positioned(
                    bottom: 0,
                    right: 0,
                    child: CircleAvatar(
                      backgroundColor: colorScheme.primary,
                      radius: 20,
                      child: IconButton(
                        icon: const Icon(Icons.camera_alt, size: 20, color: Colors.white),
                        onPressed: _saving ? null : _pickAndUploadImage,
                      ),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 32),
            Card(
              elevation: 0,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(16),
                side: BorderSide(color: colorScheme.outlineVariant),
              ),
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    const Text('Tên hiển thị', style: TextStyle(fontWeight: FontWeight.bold)),
                    const SizedBox(height: 12),
                    TextField(
                      controller: _nameController,
                      decoration: const InputDecoration(
                        border: OutlineInputBorder(),
                        prefixIcon: Icon(Icons.person_outline),
                      ),
                    ),
                    const SizedBox(height: 16),
                    FilledButton(
                      onPressed: _saving ? null : _saveName,
                      child: _saving 
                        ? const SizedBox(width: 20, height: 20, child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white))
                        : const Text('Lưu thay đổi'),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
