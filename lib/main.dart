import 'package:flutter/material.dart';
import 'package:flutter/gestures.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import 'cart_controller.dart';
import 'auth/auth_gate.dart';
import 'profile/profile_page.dart';
import 'menu_models.dart';
import 'menu_repository.dart';

String formatPriceVnd(num value) {
  final raw = value.round().toString();
  final buffer = StringBuffer();
  for (var i = 0; i < raw.length; i++) {
    final reverseIndex = raw.length - i;
    buffer.write(raw[i]);
    if (reverseIndex > 1 && reverseIndex % 3 == 1) {
      buffer.write('.');
    }
  }
  return '${buffer.toString()}đ';
}

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  await Supabase.initialize(
    url: 'https://jibbotejwrsknrixwcpj.supabase.co',
    anonKey: 'sb_publishable_z4QPDgf9Q3nq_kqnWj4bTQ_2i0JORHW',
  );

  runApp(const MyApp());
}

class MyApp extends StatefulWidget {
  const MyApp({super.key});
  @override
  State<MyApp> createState() => _MyAppState();
}

class _MyAppState extends State<MyApp> {
  final CartController _cart = CartController();

  void _addToCart(MenuItemModel item, FoodCustomization customization) {
    setState(() {
      _cart.addItem(item, customization);
    });
  }

  void _removeFromCart(int index) {
    setState(() {
      _cart.removeAt(index);
    });
  }

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Food Ordering App',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        useMaterial3: true,
        colorScheme: ColorScheme.fromSeed(seedColor: const Color(0xFF0E9F6E)),
        scaffoldBackgroundColor: const Color(0xFFF6F3E9),
        appBarTheme: const AppBarTheme(
          backgroundColor: Colors.transparent,
          foregroundColor: Color(0xFF1B1B1B),
          elevation: 0,
          scrolledUnderElevation: 0,
        ),
      ),
      home: AuthGate(
        signedIn: HomePage(
          cart: _cart,
          onAddToCart: _addToCart,
          onRemoveFromCart: _removeFromCart,
        ),
      ),
    );
  }
}

class HomePage extends StatefulWidget {
  final CartController cart;
  final void Function(MenuItemModel item, FoodCustomization customization)
  onAddToCart;
  final void Function(int index) onRemoveFromCart;

  const HomePage({
    super.key,
    required this.cart,
    required this.onAddToCart,
    required this.onRemoveFromCart,
  });

  @override
  State<HomePage> createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> {
  final MenuRepository _repository = MenuRepository();
  final ScrollController _storeScrollController = ScrollController();
  static const List<String> _categories = [
    'Tất cả',
    'Trà sữa',
    'Cơm',
    'Bún',
    'Ăn vặt',
  ];
  late Future<HomeData> _homeFuture;
  String? _selectedStoreId;
  String _selectedCategory = 'Tất cả';

  @override
  void initState() {
    super.initState();
    _homeFuture = _repository.fetchHomeData();
  }

  @override
  void dispose() {
    _storeScrollController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        toolbarHeight: 78,
        centerTitle: false,
        iconTheme: const IconThemeData(color: Colors.white),
        titleSpacing: 16,
        title: const Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              'Chọn món ngon hôm nay',
              style: TextStyle(
                color: Colors.white,
                fontSize: 24,
                fontWeight: FontWeight.w900,
                height: 1.0,
              ),
            ),
            SizedBox(height: 3),
            Text(
              'Đặt nhanh món bạn thích, nhìn rõ và dễ chọn hơn',
              style: TextStyle(
                color: Colors.white70,
                fontSize: 12,
                fontWeight: FontWeight.w600,
              ),
            ),
          ],
        ),
        flexibleSpace: Container(
          decoration: const BoxDecoration(
            gradient: LinearGradient(
              colors: [Color(0xFF0E9F6E), Color(0xFF0F766E)],
              begin: Alignment.centerLeft,
              end: Alignment.centerRight,
            ),
          ),
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.person_outline, color: Colors.white),
            onPressed: () {
              Navigator.push(
                context,
                MaterialPageRoute(builder: (_) => const ProfilePage()),
              );
            },
          ),
          IconButton(
            icon: Badge(
              isLabelVisible: widget.cart.totalItems > 0,
              label: Text(widget.cart.totalItems.toString()),
              child: const Icon(
                Icons.shopping_cart_outlined,
                color: Colors.white,
              ),
            ),
            onPressed: () {
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (_) => CartPage(
                    cart: widget.cart,
                    onRemoveAt: widget.onRemoveFromCart,
                  ),
                ),
              ).then((_) => setState(() {}));
            },
          ),
        ],
      ),
      body: FutureBuilder<HomeData>(
        future: _homeFuture,
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }

          if (snapshot.hasError) {
            return Center(
              child: Text('Không thể tải dữ liệu: ${snapshot.error}'),
            );
          }

          final data = snapshot.data;
          if (data == null) {
            return const Center(child: Text('Không có dữ liệu để hiển thị'));
          }
          final byStore = _selectedStoreId == null
              ? data.featuredItems
              : data.featuredItems
                    .where((item) => item.storeId == _selectedStoreId)
                    .toList();
          final displayedItems = _selectedCategory == 'Tất cả'
              ? byStore
              : byStore
                    .where((item) => item.category == _selectedCategory)
                    .toList();
          final dealItems = data.featuredItems
              .where((item) => item.discountPercent > 0)
              .take(6)
              .toList();

          return RefreshIndicator(
            onRefresh: () async {
              final fresh = _repository.fetchHomeData();
              setState(() {
                _homeFuture = fresh;
                _selectedStoreId = null;
                _selectedCategory = 'Tất cả';
              });
              await fresh;
            },
            child: ListView(
              physics: const AlwaysScrollableScrollPhysics(),
              padding: const EdgeInsets.all(16),
              children: [
                Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(20),
                    gradient: const LinearGradient(
                      colors: [Color(0xFF0E9F6E), Color(0xFFF59E0B)],
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                    ),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withValues(alpha: 0.1),
                        blurRadius: 16,
                        offset: const Offset(0, 8),
                      ),
                    ],
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text(
                        'Trùm deal ngon hôm nay',
                        style: TextStyle(
                          color: Colors.white,
                          fontSize: 20,
                          fontWeight: FontWeight.w800,
                        ),
                      ),
                      const SizedBox(height: 4),
                      const Text(
                        'Ăn ngon - giao nhanh - giảm đến 30%',
                        style: TextStyle(
                          color: Colors.white,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                      const SizedBox(height: 10),
                      SizedBox(
                        height: 76,
                        child: ListView.separated(
                          scrollDirection: Axis.horizontal,
                          itemCount: dealItems.length,
                          separatorBuilder: (_, _) => const SizedBox(width: 8),
                          itemBuilder: (context, index) {
                            final deal = dealItems[index];
                            return _DealFoodItem(item: deal);
                          },
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 20),
                const Text(
                  'Quán ăn nổi bật',
                  style: TextStyle(fontSize: 20, fontWeight: FontWeight.w700),
                ),
                const SizedBox(height: 12),
                Row(
                  children: [
                    const Icon(Icons.swipe, size: 18, color: Color(0xFF6B7280)),
                    const SizedBox(width: 6),
                    const Text(
                      'Vuốt ngang để xem thêm quán',
                      style: TextStyle(color: Color(0xFF6B7280)),
                    ),
                    const Spacer(),
                    if (_selectedStoreId != null)
                      TextButton(
                        onPressed: () =>
                            setState(() => _selectedStoreId = null),
                        child: const Text('Xem tất cả'),
                      ),
                  ],
                ),
                const SizedBox(height: 8),
                SizedBox(
                  height: 205,
                  child: ScrollConfiguration(
                    behavior: const MaterialScrollBehavior().copyWith(
                      dragDevices: {
                        PointerDeviceKind.touch,
                        PointerDeviceKind.mouse,
                        PointerDeviceKind.trackpad,
                      },
                    ),
                    child: ListView.separated(
                      controller: _storeScrollController,
                      scrollDirection: Axis.horizontal,
                      physics: const BouncingScrollPhysics(),
                      itemCount: data.stores.length,
                      separatorBuilder: (_, _) => const SizedBox(width: 12),
                      itemBuilder: (context, index) {
                        final store = data.stores[index];
                        return _StoreCard(
                          store: store,
                          selected: store.id == _selectedStoreId,
                          onTap: () {
                            setState(() {
                              _selectedStoreId = _selectedStoreId == store.id
                                  ? null
                                  : store.id;
                            });
                          },
                        );
                      },
                    ),
                  ),
                ),
                const SizedBox(height: 24),
                const Text(
                  'Món ăn hot',
                  style: TextStyle(fontSize: 20, fontWeight: FontWeight.w700),
                ),
                const SizedBox(height: 10),
                SizedBox(
                  height: 38,
                  child: ListView.separated(
                    scrollDirection: Axis.horizontal,
                    itemCount: _categories.length,
                    separatorBuilder: (_, _) => const SizedBox(width: 8),
                    itemBuilder: (context, index) {
                      final category = _categories[index];
                      return ChoiceChip(
                        label: Text(category),
                        selected: _selectedCategory == category,
                        onSelected: (_) {
                          setState(() {
                            _selectedCategory = category;
                          });
                        },
                      );
                    },
                  ),
                ),
                if (_selectedStoreId != null)
                  Padding(
                    padding: const EdgeInsets.only(top: 8),
                    child: Text(
                      'Đang lọc theo quán đã chọn • ${_selectedCategory.toLowerCase()}',
                      style: TextStyle(
                        color: Colors.teal.shade800,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
                const SizedBox(height: 12),
                if (displayedItems.isEmpty)
                  const Padding(
                    padding: EdgeInsets.symmetric(vertical: 24),
                    child: Center(child: Text('Quán này chưa có món nổi bật.')),
                  )
                else
                  ...displayedItems.map(
                    (item) => Padding(
                      padding: const EdgeInsets.only(bottom: 12),
                      child: _FoodCard(
                        item: item,
                        onQuickAdd: () {
                          widget.onAddToCart(
                            item,
                            const FoodCustomization(
                              size: 'M',
                              sugar: '70%',
                              ice: '70%',
                              toppings: [],
                            ),
                          );
                          ScaffoldMessenger.of(context).showSnackBar(
                            SnackBar(
                              content: Text(
                                'Đã thêm ${item.name} vào giỏ hàng',
                              ),
                              duration: const Duration(milliseconds: 900),
                            ),
                          );
                          setState(() {});
                        },
                        onTap: () async {
                          await Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (_) => FoodDetailPage(
                                item: item,
                                onAddToCart: widget.onAddToCart,
                              ),
                            ),
                          );
                          setState(() {});
                        },
                      ),
                    ),
                  ),
              ],
            ),
          );
        },
      ),
    );
  }
}

class _StoreCard extends StatelessWidget {
  final StoreModel store;
  final bool selected;
  final VoidCallback onTap;

  const _StoreCard({
    required this.store,
    required this.selected,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(16),
      child: Container(
        width: 220,
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(16),
          color: const Color(0xFFFFFBF1),
          border: Border.all(
            color: selected ? const Color(0xFF0E9F6E) : const Color(0xFFFFE4B5),
            width: selected ? 2 : 1,
          ),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.08),
              blurRadius: 12,
              offset: const Offset(0, 6),
            ),
          ],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            ClipRRect(
              borderRadius: const BorderRadius.vertical(
                top: Radius.circular(16),
              ),
              child: Image.network(
                store.imageUrl,
                height: 120,
                width: double.infinity,
                fit: BoxFit.cover,
                errorBuilder: (_, _, _) => Container(
                  height: 120,
                  color: Colors.grey.shade200,
                  alignment: Alignment.center,
                  child: const Icon(Icons.storefront_outlined),
                ),
              ),
            ),
            Padding(
              padding: const EdgeInsets.all(12),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    store.name,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(fontWeight: FontWeight.w700),
                  ),
                  const SizedBox(height: 4),
                  Row(
                    children: [
                      const Icon(Icons.star, color: Colors.amber, size: 16),
                      const SizedBox(width: 4),
                      Text(store.rating.toStringAsFixed(1)),
                      const Spacer(),
                      if (selected)
                        const Icon(
                          Icons.check_circle,
                          color: Color(0xFF0E9F6E),
                          size: 18,
                        ),
                    ],
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

class _HeroBanner extends StatelessWidget {
  final List<MenuItemModel> dealItems;

  const _HeroBanner({required this.dealItems});

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 290,
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(28),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.14),
            blurRadius: 24,
            offset: const Offset(0, 12),
          ),
        ],
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(28),
        child: Stack(
          fit: StackFit.expand,
          children: [
            Positioned.fill(
              child: Image.network(
                dealItems.isNotEmpty ? dealItems.first.imageUrl : '',
                fit: BoxFit.cover,
                errorBuilder: (_, _, _) => Container(
                  decoration: const BoxDecoration(
                    gradient: LinearGradient(
                      colors: [Color(0xFF0E9F6E), Color(0xFFF59E0B)],
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                    ),
                  ),
                ),
              ),
            ),
            Container(color: Colors.black.withValues(alpha: 0.38)),
            Container(
              decoration: const BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topCenter,
                  end: Alignment.bottomCenter,
                  colors: [Color(0x55000000), Color(0xCC000000)],
                ),
              ),
            ),
            Padding(
              padding: const EdgeInsets.all(18),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 12,
                          vertical: 8,
                        ),
                        decoration: BoxDecoration(
                          color: Colors.white.withValues(alpha: 0.18),
                          borderRadius: BorderRadius.circular(999),
                          border: Border.all(
                            color: Colors.white.withValues(alpha: 0.22),
                          ),
                        ),
                        child: const Text(
                          'Trùm deal ngon hôm nay',
                          style: TextStyle(
                            color: Colors.white,
                            fontWeight: FontWeight.w800,
                            fontSize: 13,
                          ),
                        ),
                      ),
                      const Spacer(),
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 10,
                          vertical: 8,
                        ),
                        decoration: BoxDecoration(
                          color: const Color(0xFFE11D48),
                          borderRadius: BorderRadius.circular(999),
                        ),
                        child: const Text(
                          'Giảm đến 30%',
                          style: TextStyle(
                            color: Colors.white,
                            fontWeight: FontWeight.w800,
                            fontSize: 12,
                          ),
                        ),
                      ),
                    ],
                  ),
                  const Spacer(),
                  const Text(
                    'Chọn món ngon hôm nay',
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 32,
                      fontWeight: FontWeight.w900,
                      height: 1.05,
                    ),
                  ),
                  const SizedBox(height: 8),
                  const Text(
                    'Món đẹp mắt, giá rõ ràng, đặt nhanh trong vài chạm.',
                    style: TextStyle(
                      color: Colors.white70,
                      fontSize: 13,
                      fontWeight: FontWeight.w500,
                      height: 1.3,
                    ),
                  ),
                  const SizedBox(height: 14),
                  Row(
                    children: const [
                      _HeroStatChip(label: 'Giao nhanh'),
                      SizedBox(width: 8),
                      _HeroStatChip(label: 'Ảnh món thật'),
                      SizedBox(width: 8),
                      _HeroStatChip(label: 'Deal hot mỗi ngày'),
                    ],
                  ),
                  const SizedBox(height: 14),
                  SizedBox(
                    height: 78,
                    child: ListView.separated(
                      scrollDirection: Axis.horizontal,
                      itemCount: dealItems.length,
                      separatorBuilder: (_, _) => const SizedBox(width: 8),
                      itemBuilder: (context, index) {
                        final deal = dealItems[index];
                        return _DealFoodItem(item: deal);
                      },
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

class _HeroStatChip extends StatelessWidget {
  final String label;

  const _HeroStatChip({required this.label});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 7),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.16),
        borderRadius: BorderRadius.circular(999),
        border: Border.all(color: Colors.white.withValues(alpha: 0.16)),
      ),
      child: Text(
        label,
        style: const TextStyle(
          color: Colors.white,
          fontSize: 12,
          fontWeight: FontWeight.w700,
        ),
      ),
    );
  }
}

class _DealFoodItem extends StatelessWidget {
  final MenuItemModel item;

  const _DealFoodItem({required this.item});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 250,
      padding: const EdgeInsets.all(8),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.18),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Row(
        children: [
          ClipRRect(
            borderRadius: BorderRadius.circular(10),
            child: Image.network(
              item.imageUrl,
              width: 56,
              height: 56,
              fit: BoxFit.cover,
              errorBuilder: (_, _, _) => Container(
                width: 56,
                height: 56,
                color: Colors.white24,
                alignment: Alignment.center,
                child: const Icon(Icons.image, color: Colors.white),
              ),
            ),
          ),
          const SizedBox(width: 8),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Text(
                  item.name,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(
                    color: Colors.white,
                    fontWeight: FontWeight.w700,
                  ),
                ),
                const SizedBox(height: 2),
                Row(
                  children: [
                    Flexible(
                      child: Text(
                        formatPriceVnd(item.price),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: const TextStyle(
                          color: Colors.white,
                          fontWeight: FontWeight.w800,
                        ),
                      ),
                    ),
                    const SizedBox(width: 6),
                    Flexible(
                      child: Text(
                        formatPriceVnd(item.originalPrice),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: const TextStyle(
                          color: Colors.white70,
                          decoration: TextDecoration.lineThrough,
                        ),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _FoodCard extends StatelessWidget {
  final MenuItemModel item;
  final VoidCallback onQuickAdd;
  final VoidCallback onTap;

  const _FoodCard({
    required this.item,
    required this.onQuickAdd,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(16),
      child: Ink(
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(16),
          color: const Color(0xFFFFF7ED),
          border: Border.all(color: const Color(0xFFFFD7A8)),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.05),
              blurRadius: 10,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        child: Row(
          children: [
            ClipRRect(
              borderRadius: const BorderRadius.horizontal(
                left: Radius.circular(16),
              ),
              child: Stack(
                children: [
                  Image.network(
                    item.imageUrl,
                    height: 130,
                    width: 115,
                    fit: BoxFit.cover,
                    errorBuilder: (_, _, _) => Container(
                      height: 130,
                      width: 115,
                      color: Colors.grey.shade200,
                      alignment: Alignment.center,
                      child: const Icon(Icons.fastfood),
                    ),
                  ),
                  if (item.discountPercent > 0)
                    Positioned(
                      left: 6,
                      top: 6,
                      child: Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 8,
                          vertical: 4,
                        ),
                        decoration: BoxDecoration(
                          color: const Color(0xFFE11D48),
                          borderRadius: BorderRadius.circular(999),
                        ),
                        child: Text(
                          'Giảm ${item.discountPercent}%',
                          style: const TextStyle(
                            color: Colors.white,
                            fontSize: 11,
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                      ),
                    ),
                ],
              ),
            ),
            Expanded(
              child: Padding(
                padding: const EdgeInsets.all(12),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      item.name,
                      style: const TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                    const SizedBox(height: 6),
                    Text(
                      item.description,
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                    ),
                    const SizedBox(height: 8),
                    Wrap(
                      spacing: 8,
                      crossAxisAlignment: WrapCrossAlignment.center,
                      children: [
                        Text(
                          formatPriceVnd(item.price),
                          style: const TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.w700,
                            color: Color(0xFF0E9F6E),
                          ),
                        ),
                        if (item.discountPercent > 0)
                          Text(
                            formatPriceVnd(item.originalPrice),
                            style: const TextStyle(
                              fontSize: 13,
                              color: Color(0xFF6B7280),
                              decoration: TextDecoration.lineThrough,
                            ),
                          ),
                      ],
                    ),
                    const SizedBox(height: 8),
                    Align(
                      alignment: Alignment.centerLeft,
                      child: FilledButton.icon(
                        style: FilledButton.styleFrom(
                          visualDensity: VisualDensity.compact,
                          backgroundColor: const Color(0xFF0E9F6E),
                        ),
                        onPressed: onQuickAdd,
                        icon: const Icon(Icons.add_shopping_cart, size: 18),
                        label: const Text('Thêm nhanh'),
                      ),
                    ),
                  ],
                ),
              ),
            ),
            const Padding(
              padding: EdgeInsets.only(right: 12),
              child: Icon(Icons.arrow_forward_ios, size: 16),
            ),
          ],
        ),
      ),
    );
  }
}

class FoodDetailPage extends StatefulWidget {
  final MenuItemModel item;
  final void Function(MenuItemModel item, FoodCustomization customization)
  onAddToCart;

  const FoodDetailPage({
    super.key,
    required this.item,
    required this.onAddToCart,
  });

  @override
  State<FoodDetailPage> createState() => _FoodDetailPageState();
}

class _FoodDetailPageState extends State<FoodDetailPage> {
  String _size = 'M';
  String _sugar = '70%';
  String _ice = '70%';
  final Set<String> _toppings = <String>{};

  final List<String> _sizeOptions = const ['M', 'L'];
  final List<String> _sugarOptions = const ['100%', '70%', '50%', '30%', '0%'];
  final List<String> _iceOptions = const ['100%', '70%', '50%', '30%', '0%'];
  final List<String> _toppingOptions = const [
    'Trân châu đen',
    'Trân châu trắng',
    'Pudding',
    'Thạch phô mai',
  ];

  @override
  Widget build(BuildContext context) {
    final current = FoodCustomization(
      size: _size,
      sugar: _sugar,
      ice: _ice,
      toppings: _toppings.toList(),
    );
    final finalPrice = widget.item.price + current.extraPrice;

    return Scaffold(
      appBar: AppBar(title: Text(widget.item.name)),
      body: ListView(
        children: [
          Image.network(
            widget.item.imageUrl,
            height: 260,
            fit: BoxFit.cover,
            errorBuilder: (_, _, _) => Container(
              height: 260,
              color: Colors.grey.shade200,
              alignment: Alignment.center,
              child: const Icon(Icons.image_not_supported_outlined, size: 42),
            ),
          ),
          Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  widget.item.name,
                  style: const TextStyle(
                    fontSize: 24,
                    fontWeight: FontWeight.w800,
                  ),
                ),
                const SizedBox(height: 8),
                Text(widget.item.description),
                const SizedBox(height: 10),
                Text(
                  'Giá: ${formatPriceVnd(finalPrice)}',
                  style: const TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.w700,
                    color: Color(0xFF0E9F6E),
                  ),
                ),
                const SizedBox(height: 18),
                _optionGroup(
                  title: 'Chọn size',
                  values: _sizeOptions,
                  selected: _size,
                  onChanged: (v) => setState(() => _size = v),
                ),
                _optionGroup(
                  title: 'Độ đường',
                  values: _sugarOptions,
                  selected: _sugar,
                  onChanged: (v) => setState(() => _sugar = v),
                ),
                _optionGroup(
                  title: 'Lượng đá',
                  values: _iceOptions,
                  selected: _ice,
                  onChanged: (v) => setState(() => _ice = v),
                ),
                const SizedBox(height: 8),
                const Text(
                  'Topping (+5,000đ / món)',
                  style: TextStyle(fontWeight: FontWeight.w700),
                ),
                const SizedBox(height: 8),
                Wrap(
                  spacing: 8,
                  children: _toppingOptions
                      .map(
                        (top) => FilterChip(
                          label: Text(top),
                          selected: _toppings.contains(top),
                          onSelected: (selected) {
                            setState(() {
                              if (selected) {
                                _toppings.add(top);
                              } else {
                                _toppings.remove(top);
                              }
                            });
                          },
                        ),
                      )
                      .toList(),
                ),
              ],
            ),
          ),
        ],
      ),
      bottomNavigationBar: SafeArea(
        minimum: const EdgeInsets.all(12),
        child: FilledButton.icon(
          style: FilledButton.styleFrom(
            padding: const EdgeInsets.symmetric(vertical: 14),
          ),
          onPressed: () {
            widget.onAddToCart(widget.item, current);
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(content: Text('Đã thêm món vào giỏ hàng')),
            );
            Navigator.pop(context);
          },
          icon: const Icon(Icons.add_shopping_cart),
          label: const Text('Thêm vào giỏ'),
        ),
      ),
    );
  }

  Widget _optionGroup({
    required String title,
    required List<String> values,
    required String selected,
    required ValueChanged<String> onChanged,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(title, style: const TextStyle(fontWeight: FontWeight.w700)),
        const SizedBox(height: 8),
        Wrap(
          spacing: 8,
          children: values
              .map(
                (value) => ChoiceChip(
                  label: Text(value),
                  selected: selected == value,
                  onSelected: (_) => onChanged(value),
                ),
              )
              .toList(),
        ),
        const SizedBox(height: 14),
      ],
    );
  }
}

class CartPage extends StatefulWidget {
  final CartController cart;
  final void Function(int index) onRemoveAt;

  const CartPage({super.key, required this.cart, required this.onRemoveAt});

  @override
  State<CartPage> createState() => _CartPageState();
}

class _CartPageState extends State<CartPage> {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Giỏ hàng')),
      body: widget.cart.items.isEmpty
          ? const Center(child: Text('Giỏ hàng đang trống'))
          : ListView.builder(
              padding: const EdgeInsets.all(16),
              itemCount: widget.cart.items.length,
              itemBuilder: (context, index) {
                final cartItem = widget.cart.items[index];
                return Card(
                  margin: const EdgeInsets.only(bottom: 12),
                  child: ListTile(
                    title: Text(cartItem.item.name),
                    subtitle: Text(
                      '${cartItem.customization.summary}\nSL: ${cartItem.quantity}',
                    ),
                    isThreeLine: true,
                    trailing: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      crossAxisAlignment: CrossAxisAlignment.end,
                      children: [
                        Text(
                          formatPriceVnd(cartItem.totalPrice),
                          style: const TextStyle(fontWeight: FontWeight.w700),
                        ),
                        TextButton(
                          onPressed: () {
                            widget.onRemoveAt(index);
                            setState(() {});
                          },
                          child: const Text('Xóa'),
                        ),
                      ],
                    ),
                  ),
                );
              },
            ),
      bottomNavigationBar: SafeArea(
        minimum: const EdgeInsets.all(16),
        child: Row(
          children: [
            Expanded(
              child: Text(
                'Tổng: ${formatPriceVnd(widget.cart.grandTotal)}',
                style: const TextStyle(
                  fontSize: 20,
                  fontWeight: FontWeight.w800,
                ),
              ),
            ),
            FilledButton(
              onPressed: widget.cart.items.isEmpty ? null : () {},
              child: const Text('Đặt hàng'),
            ),
          ],
        ),
      ),
    );
  }
}
