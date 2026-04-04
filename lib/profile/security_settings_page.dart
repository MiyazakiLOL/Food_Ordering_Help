import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

class SecuritySettingsPage extends StatefulWidget {
  const SecuritySettingsPage({super.key});

  @override
  State<SecuritySettingsPage> createState() => _SecuritySettingsPageState();
}

class _SecuritySettingsPageState extends State<SecuritySettingsPage> {
  final _newPasswordController = TextEditingController();
  final _confirmPasswordController = TextEditingController();

  bool _saving = false;
  bool _showNewPassword = false;
  bool _showConfirmPassword = false;

  @override
  void dispose() {
    _newPasswordController.dispose();
    _confirmPasswordController.dispose();
    super.dispose();
  }

  Future<void> _changePassword() async {
    final newPassword = _newPasswordController.text;
    final confirm = _confirmPasswordController.text;

    if (newPassword.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Vui lòng nhập mật khẩu mới')),
      );
      return;
    }

    if (newPassword != confirm) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Mật khẩu xác nhận không khớp')),
      );
      return;
    }

    setState(() => _saving = true);
    try {
      await Supabase.instance.client.auth.updateUser(
        UserAttributes(password: newPassword),
      );

      if (!mounted) return;
      _newPasswordController.clear();
      _confirmPasswordController.clear();
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text('Đã đổi mật khẩu')));
    } on AuthException catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text(e.message)));
    } catch (_) {
      if (!mounted) return;
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text('Đổi mật khẩu thất bại')));
    } finally {
      if (mounted) setState(() => _saving = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;

    return Scaffold(
      appBar: AppBar(title: const Text('Bảo mật')),
      body: SafeArea(
        child: ListView(
          padding: const EdgeInsets.all(16),
          children: [
            Card(
              elevation: 0,
              color: colorScheme.surface,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(16),
                side: BorderSide(
                  color: colorScheme.outlineVariant.withValues(alpha: 0.6),
                ),
              ),
              child: Column(
                children: [
                  const ListTile(
                    leading: Icon(Icons.lock_outline),
                    title: Text(
                      'Đổi mật khẩu',
                      style: TextStyle(fontWeight: FontWeight.w900),
                    ),
                    subtitle: Text('Cập nhật mật khẩu đăng nhập'),
                  ),
                  const Divider(height: 1),
                  Padding(
                    padding: const EdgeInsets.all(16),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        TextField(
                          controller: _newPasswordController,
                          obscureText: !_showNewPassword,
                          decoration: InputDecoration(
                            labelText: 'Mật khẩu mới',
                            prefixIcon: const Icon(Icons.lock_outline),
                            border: const OutlineInputBorder(),
                            filled: true,
                            fillColor: colorScheme.surface,
                            suffixIcon: IconButton(
                              tooltip: _showNewPassword
                                  ? 'Ẩn mật khẩu'
                                  : 'Hiện mật khẩu',
                              onPressed: () {
                                setState(() {
                                  _showNewPassword = !_showNewPassword;
                                });
                              },
                              icon: Icon(
                                _showNewPassword
                                    ? Icons.visibility_off_outlined
                                    : Icons.visibility_outlined,
                              ),
                            ),
                          ),
                        ),
                        const SizedBox(height: 12),
                        TextField(
                          controller: _confirmPasswordController,
                          obscureText: !_showConfirmPassword,
                          decoration: InputDecoration(
                            labelText: 'Nhập lại mật khẩu mới',
                            prefixIcon: const Icon(Icons.lock_reset_outlined),
                            border: const OutlineInputBorder(),
                            filled: true,
                            fillColor: colorScheme.surface,
                            suffixIcon: IconButton(
                              tooltip: _showConfirmPassword
                                  ? 'Ẩn mật khẩu'
                                  : 'Hiện mật khẩu',
                              onPressed: () {
                                setState(() {
                                  _showConfirmPassword = !_showConfirmPassword;
                                });
                              },
                              icon: Icon(
                                _showConfirmPassword
                                    ? Icons.visibility_off_outlined
                                    : Icons.visibility_outlined,
                              ),
                            ),
                          ),
                        ),
                        const SizedBox(height: 12),
                        SizedBox(
                          height: 44,
                          child: FilledButton.tonal(
                            onPressed: _saving ? null : _changePassword,
                            child: _saving
                                ? const SizedBox(
                                    width: 18,
                                    height: 18,
                                    child: CircularProgressIndicator(
                                      strokeWidth: 2,
                                    ),
                                  )
                                : const Text('Đổi mật khẩu'),
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
