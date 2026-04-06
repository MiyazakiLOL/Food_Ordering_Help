import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import 'account_settings_page.dart';
import 'addresses_page.dart';
import 'security_settings_page.dart';
import '../my_orders_page.dart';

class ProfilePage extends StatefulWidget {
  const ProfilePage({super.key});

  @override
  State<ProfilePage> createState() => _ProfilePageState();
}

class _ProfilePageState extends State<ProfilePage> {
  User? get _user => Supabase.instance.client.auth.currentUser;

  Future<void> _openAccount() async {
    // Chờ cho đến khi AccountSettingsPage đóng lại
    await Navigator.of(context).push(
      MaterialPageRoute(builder: (_) => const AccountSettingsPage()),
    );
    // Sau khi quay lại, cập nhật lại giao diện
    if (mounted) {
      setState(() {});
    }
  }

  Future<void> _openSecurity() async {
    await Navigator.of(context).push(
      MaterialPageRoute(builder: (_) => const SecuritySettingsPage()),
    );
  }

  Future<void> _openAddresses() async {
    await Navigator.of(context).push(
      MaterialPageRoute(builder: (_) => const AddressesPage()),
    );
  }

  Future<void> _openOrders() async {
    await Navigator.of(context).push(
      MaterialPageRoute(builder: (_) => const MyOrdersPage()),
    );
  }

  Future<void> _signOut() async {
    await Supabase.instance.client.auth.signOut();
    if (!mounted) return;
    Navigator.of(context).pop();
  }

  String _displayName(User? user) {
    final fullName = (user?.userMetadata?['full_name'] ?? '').toString().trim();
    if (fullName.isNotEmpty) return fullName;
    return user?.email?.split('@').first ?? '';
  }

  String _phoneNumber(User? user) {
    return (user?.userMetadata?['phone_number'] ?? 'Chưa cập nhật').toString();
  }

  String _initials(String name) {
    final parts = name.trim().split(RegExp(r'\s+')).where((s) => s.isNotEmpty).toList();
    if (parts.isEmpty) return 'U';
    String firstChar(String s) => s.characters.isEmpty ? '' : s.characters.first.toUpperCase();
    final first = firstChar(parts.first);
    final second = parts.length > 1 ? firstChar(parts[1]) : '';
    return '$first$second'.isEmpty ? 'U' : '$first$second';
  }

  @override
  Widget build(BuildContext context) {
    final user = _user;
    final colorScheme = Theme.of(context).colorScheme;

    final name = _displayName(user);
    final phone = _phoneNumber(user);
    final initials = _initials(name);
    final avatarUrl = user?.userMetadata?['avatar_url'] as String?;

    final sectionShape = RoundedRectangleBorder(
      borderRadius: BorderRadius.circular(16),
      side: BorderSide(color: colorScheme.outlineVariant.withValues(alpha: 0.6)),
    );

    return Scaffold(
      appBar: AppBar(
        title: const Text('Hồ sơ cá nhân'),
        actions: [
          IconButton(
            tooltip: 'Đăng xuất',
            onPressed: _signOut,
            icon: const Icon(Icons.logout),
          ),
        ],
      ),
      body: SafeArea(
        child: ListView(
          padding: const EdgeInsets.symmetric(vertical: 16),
          children: [
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              child: Card(
                elevation: 0,
                child: Padding(
                  padding: const EdgeInsets.all(16),
                  child: Row(
                    children: [
                      CircleAvatar(
                        radius: 35,
                        backgroundColor: colorScheme.primary,
                        foregroundColor: colorScheme.onPrimary,
                        backgroundImage: avatarUrl != null ? NetworkImage(avatarUrl) : null,
                        child: avatarUrl == null
                            ? Text(initials, style: const TextStyle(fontSize: 24, fontWeight: FontWeight.w900))
                            : null,
                      ),
                      const SizedBox(width: 16),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(name, maxLines: 1, overflow: TextOverflow.ellipsis, style: const TextStyle(fontSize: 20, fontWeight: FontWeight.w900)),
                            const SizedBox(height: 4),
                            Row(
                              children: [
                                const Icon(Icons.email_outlined, size: 14),
                                const SizedBox(width: 4),
                                Expanded(child: Text(user?.email ?? '', maxLines: 1, overflow: TextOverflow.ellipsis, style: TextStyle(color: colorScheme.onSurfaceVariant, fontWeight: FontWeight.w500))),
                              ],
                            ),
                            const SizedBox(height: 2),
                            Row(
                              children: [
                                const Icon(Icons.phone_android_outlined, size: 14),
                                const SizedBox(width: 4),
                                Text(phone, style: TextStyle(color: colorScheme.onSurfaceVariant, fontWeight: FontWeight.w500)),
                              ],
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
            const SizedBox(height: 20),
            _buildSectionHeader("Đơn hàng"),
            _buildMenuItem(context, _openOrders, Icons.shopping_bag_outlined, 'Đơn hàng của tôi', 'Theo dõi trạng thái đơn hàng', sectionShape, colorScheme),
            const SizedBox(height: 20),
            _buildSectionHeader("Cài đặt"),
            _buildMenuItem(context, _openAccount, Icons.badge_outlined, 'Thông tin cá nhân', 'Cập nhật tên và ảnh đại diện', sectionShape, colorScheme),
            const SizedBox(height: 12),
            _buildMenuItem(context, _openSecurity, Icons.lock_outline, 'Bảo mật', 'Đổi mật khẩu đăng nhập', sectionShape, colorScheme),
            const SizedBox(height: 12),
            _buildMenuItem(context, _openAddresses, Icons.location_on_outlined, 'Địa chỉ', 'Xem và chỉnh sửa địa chỉ', sectionShape, colorScheme),
          ],
        ),
      ),
    );
  }

  Widget _buildSectionHeader(String title) {
    return Padding(
      padding: const EdgeInsets.only(left: 24, bottom: 8),
      child: Text(title, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 18)),
    );
  }

  Widget _buildMenuItem(BuildContext context, VoidCallback onTap, IconData icon, String title, String subtitle, ShapeBorder shape, ColorScheme colorScheme) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      child: Card(
        elevation: 0,
        color: colorScheme.surface,
        shape: shape,
        child: ListTile(
          onTap: onTap,
          leading: Icon(icon),
          title: Text(title, style: const TextStyle(fontWeight: FontWeight.w900)),
          subtitle: Text(subtitle),
          trailing: const Icon(Icons.chevron_right),
        ),
      ),
    );
  }
}
