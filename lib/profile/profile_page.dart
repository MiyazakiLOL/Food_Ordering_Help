import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import 'account_settings_page.dart';
import 'addresses_page.dart';
import 'security_settings_page.dart';

class ProfilePage extends StatefulWidget {
  const ProfilePage({super.key});

  @override
  State<ProfilePage> createState() => _ProfilePageState();
}

class _ProfilePageState extends State<ProfilePage> {
  User? get _user => Supabase.instance.client.auth.currentUser;

  Future<void> _openAccount() async {
    await Navigator.of(
      context,
    ).push(MaterialPageRoute(builder: (_) => const AccountSettingsPage()));
    if (!mounted) return;
    setState(() {});
  }

  Future<void> _openSecurity() async {
    await Navigator.of(
      context,
    ).push(MaterialPageRoute(builder: (_) => const SecuritySettingsPage()));
  }

  Future<void> _openAddresses() async {
    await Navigator.of(
      context,
    ).push(MaterialPageRoute(builder: (_) => const AddressesPage()));
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

  String _initials(String name) {
    final parts = name
        .trim()
        .split(RegExp(r'\s+'))
        .where((s) => s.isNotEmpty)
        .toList();

    if (parts.isEmpty) return 'U';

    String firstChar(String s) {
      if (s.characters.isEmpty) return '';
      return s.characters.first.toUpperCase();
    }

    final first = firstChar(parts.first);
    final second = parts.length > 1 ? firstChar(parts[1]) : '';
    final result = '$first$second';
    return result.isEmpty ? 'U' : result;
  }

  @override
  Widget build(BuildContext context) {
    final user = _user;
    final colorScheme = Theme.of(context).colorScheme;

    final name = _displayName(user);
    final initials = _initials(name);

    final sectionShape = RoundedRectangleBorder(
      borderRadius: BorderRadius.circular(16),
      side: BorderSide(
        color: colorScheme.outlineVariant.withValues(alpha: 0.6),
      ),
    );

    return Scaffold(
      appBar: AppBar(
        title: const Text('Profile'),
        actions: [
          IconButton(
            tooltip: 'Đăng xuất',
            onPressed: _signOut,
            icon: const Icon(Icons.logout),
          ),
        ],
      ),
      body: SafeArea(
        child: LayoutBuilder(
          builder: (context, constraints) {
            final maxWidth = constraints.maxWidth;
            final contentWidth = maxWidth > 720 ? 640.0 : maxWidth;

            return ListView(
              padding: const EdgeInsets.symmetric(vertical: 16),
              children: [
                Align(
                  alignment: Alignment.topCenter,
                  child: SizedBox(
                    width: contentWidth,
                    child: Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 16),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.stretch,
                        children: [
                          Card(
                            elevation: 0,
                            child: Padding(
                              padding: const EdgeInsets.all(16),
                              child: Row(
                                children: [
                                  CircleAvatar(
                                    radius: 26,
                                    backgroundColor: colorScheme.primary,
                                    foregroundColor: colorScheme.onPrimary,
                                    child: Text(
                                      initials,
                                      style: const TextStyle(
                                        fontWeight: FontWeight.w900,
                                      ),
                                    ),
                                  ),
                                  const SizedBox(width: 12),
                                  Expanded(
                                    child: Column(
                                      crossAxisAlignment:
                                          CrossAxisAlignment.start,
                                      children: [
                                        Text(
                                          name,
                                          maxLines: 1,
                                          overflow: TextOverflow.ellipsis,
                                          style: const TextStyle(
                                            fontSize: 16,
                                            fontWeight: FontWeight.w900,
                                          ),
                                        ),
                                        const SizedBox(height: 2),
                                        Text(
                                          user?.email ?? '',
                                          maxLines: 1,
                                          overflow: TextOverflow.ellipsis,
                                          style: TextStyle(
                                            color: colorScheme.onSurfaceVariant,
                                            fontWeight: FontWeight.w600,
                                          ),
                                        ),
                                      ],
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ),
                          const SizedBox(height: 12),
                          Card(
                            elevation: 0,
                            color: colorScheme.surface,
                            shape: sectionShape,
                            child: ListTile(
                              onTap: _openAccount,
                              leading: const Icon(Icons.badge_outlined),
                              title: const Text(
                                'Tài khoản',
                                style: TextStyle(fontWeight: FontWeight.w900),
                              ),
                              subtitle: const Text('Cập nhật tên hiển thị'),
                              trailing: const Icon(Icons.chevron_right),
                            ),
                          ),
                          const SizedBox(height: 12),
                          Card(
                            elevation: 0,
                            color: colorScheme.surface,
                            shape: sectionShape,
                            child: ListTile(
                              onTap: _openSecurity,
                              leading: const Icon(Icons.lock_outline),
                              title: const Text(
                                'Bảo mật',
                                style: TextStyle(fontWeight: FontWeight.w900),
                              ),
                              subtitle: const Text('Đổi mật khẩu đăng nhập'),
                              trailing: const Icon(Icons.chevron_right),
                            ),
                          ),
                          const SizedBox(height: 12),
                          Card(
                            elevation: 0,
                            color: colorScheme.surface,
                            shape: sectionShape,
                            child: ListTile(
                              onTap: _openAddresses,
                              leading: const Icon(Icons.location_on_outlined),
                              title: const Text(
                                'Địa chỉ',
                                style: TextStyle(fontWeight: FontWeight.w900),
                              ),
                              subtitle: const Text('Xem và chỉnh sửa địa chỉ'),
                              trailing: const Icon(Icons.chevron_right),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
              ],
            );
          },
        ),
      ),
    );
  }
}
