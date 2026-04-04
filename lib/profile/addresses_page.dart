import 'package:flutter/material.dart';

import 'address_form_page.dart';
import 'shipping_address_model.dart';
import 'shipping_address_repository.dart';

class AddressesPage extends StatefulWidget {
  const AddressesPage({super.key});

  @override
  State<AddressesPage> createState() => _AddressesPageState();
}

class _AddressesPageState extends State<AddressesPage> {
  final _repo = ShippingAddressRepository();

  bool _loading = false;
  List<ShippingAddress> _addresses = const [];

  @override
  void initState() {
    super.initState();
    _reload();
  }

  Future<void> _reload() async {
    setState(() => _loading = true);
    try {
      final items = await _repo.listMine();
      if (!mounted) return;
      setState(() {
        _addresses = items;
      });
    } catch (_) {
      if (!mounted) return;
      setState(() {
        _addresses = const [];
      });
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  Future<void> _add() async {
    final saved = await Navigator.of(context).push<ShippingAddress>(
      MaterialPageRoute(builder: (_) => const AddressFormPage()),
    );

    if (!mounted || saved == null) return;
    await _reload();
  }

  Future<void> _edit(ShippingAddress address) async {
    final saved = await Navigator.of(context).push<ShippingAddress>(
      MaterialPageRoute(builder: (_) => AddressFormPage(initial: address)),
    );

    if (!mounted || saved == null) return;
    await _reload();
  }

  Future<void> _delete(ShippingAddress address) async {
    final ok = await showDialog<bool>(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: const Text('Xoá địa chỉ?'),
          content: const Text('Địa chỉ sẽ bị xoá khỏi danh sách đã lưu.'),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(false),
              child: const Text('Huỷ'),
            ),
            FilledButton(
              onPressed: () => Navigator.of(context).pop(true),
              child: const Text('Xoá'),
            ),
          ],
        );
      },
    );

    if (ok != true) return;

    try {
      await _repo.delete(address.id);
      if (!mounted) return;
      await _reload();
    } catch (_) {
      if (!mounted) return;
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text('Xoá địa chỉ thất bại')));
    }
  }

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Địa chỉ'),
        actions: [
          IconButton(
            tooltip: 'Thêm địa chỉ',
            onPressed: _add,
            icon: const Icon(Icons.add_location_alt_outlined),
          ),
        ],
      ),
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
                  ListTile(
                    leading: const Icon(Icons.location_on_outlined),
                    title: const Text(
                      'Địa chỉ đã lưu',
                      style: TextStyle(fontWeight: FontWeight.w900),
                    ),
                    subtitle: Text(
                      _loading
                          ? 'Đang tải...'
                          : (_addresses.isEmpty
                                ? 'Chưa có địa chỉ'
                                : '${_addresses.length} địa chỉ'),
                    ),
                    trailing: FilledButton.tonalIcon(
                      onPressed: _add,
                      icon: const Icon(Icons.add_location_alt_outlined),
                      label: const Text('Thêm'),
                    ),
                  ),
                  const Divider(height: 1),
                  Padding(
                    padding: const EdgeInsets.all(16),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        if (_loading)
                          const Padding(
                            padding: EdgeInsets.symmetric(vertical: 16),
                            child: Center(child: CircularProgressIndicator()),
                          )
                        else if (_addresses.isEmpty)
                          Padding(
                            padding: const EdgeInsets.symmetric(vertical: 6),
                            child: Text(
                              'Chưa có địa chỉ nào. Nhấn Thêm để tạo mới.',
                              style: TextStyle(
                                color: colorScheme.onSurfaceVariant,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                          )
                        else
                          ..._addresses.map(
                            (a) => Padding(
                              padding: const EdgeInsets.only(top: 8),
                              child: Card(
                                elevation: 0,
                                color: colorScheme.surface,
                                child: ListTile(
                                  onTap: () => _edit(a),
                                  leading: Icon(
                                    Icons.home_outlined,
                                    color: a.isDefault ? Colors.green : null,
                                  ),
                                  title: Text(
                                    a.fullAddress, // Đã sửa từ a.address
                                    maxLines: 2,
                                    overflow: TextOverflow.ellipsis,
                                    style: const TextStyle(
                                      fontWeight: FontWeight.w800,
                                    ),
                                  ),
                                  subtitle: Text(
                                    [
                                      a.phoneNumber, // Đã sửa từ a.phone
                                      if (a.note.trim().isNotEmpty) a.note,
                                      if (a.isDefault) 'Mặc định',
                                    ].join('\n'),
                                  ),
                                  isThreeLine: true,
                                  trailing: Row(
                                    mainAxisSize: MainAxisSize.min,
                                    children: [
                                      IconButton(
                                        tooltip: 'Sửa',
                                        onPressed: () => _edit(a),
                                        icon: const Icon(Icons.edit_outlined),
                                      ),
                                      IconButton(
                                        tooltip: 'Xoá',
                                        onPressed: () => _delete(a),
                                        icon: const Icon(Icons.delete_outline),
                                      ),
                                    ],
                                  ),
                                ),
                              ),
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
