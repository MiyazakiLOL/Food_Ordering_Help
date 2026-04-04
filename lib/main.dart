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
    'Cà phê',
    'Đồ ăn vặt',
    'Thức ăn nhanh',
    'Sinh tố & Nước ép',
  ];
  
  late Future<HomeData> _homeFuture;
  String? _selectedStoreId;
  String _selectedCategory = 'Tất cả';
  int _currentPage = 0;
  final int _pageSize = 10;

  @override
  void initState() {
    super.initState();
    _loadData();
  }

  void _loadData() {
    setState(() {
      _homeFuture = _repository.fetchHomeData(page: _currentPage, pageSize: _pageSize);
    });
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
              _currentPage = 0;
              _loadData();
              setState(() {
                _selectedStoreId = null;
                _selectedCategory = 'Tất cả';
              });
              await _homeFuture;
            },
            child: ListView(
              physics: const AlwaysScrollableScrollPhysics(),
              padding: const EdgeInsets.all(16),
              children: [
                // Banner Deals
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
                            return _DealFoodItem(item: dealItems[index]);
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
                
                // Danh sách sản phẩm
                if (displayedItems.isEmpty)
                  const Padding(
                    padding: EdgeInsets.symmetric(vertical: 24),
                    child: Center(child: Text('Không có món ăn phù hợp.')),
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
                              content: Text('Đã thêm ${item.name} vào giỏ hàng'),
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

                // Pagination Controls
                const SizedBox(height: 20),
                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    IconButton(
                      onPressed: _currentPage > 0 
                        ? () { 
                            _currentPage--; 
                            _loadData(); 
                          } 
                        : null,
                      icon: const Icon(Icons.chevron_left),
                      style: IconButton.styleFrom(
                        backgroundColor: Colors.white,
                        disabledBackgroundColor: Colors.grey.shade200,
                      ),
                    ),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(20),
                      ),
                      child: Text(
                        'Trang ${_currentPage + 1}',
                        style: const TextStyle(fontWeight: FontWeight.bold),
                      ),
                    ),
                    IconButton(
                      onPressed: displayedItems.length == _pageSize 
                        ? () { 
                            _currentPage++; 
                            _loadData(); 
                          } 
                        : null,
                      icon: const Icon(Icons.chevron_right),
                      style: IconButton.styleFrom(
                        backgroundColor: Colors.white,
                        disabledBackgroundColor: Colors.grey.shade200,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 40),
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
    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        width: 155,
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(
            color: selected ? const Color(0xFF0E9F6E) : Colors.transparent,
            width: 2.5,
          ),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.05),
              blurRadius: 10,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            ClipRRect(
              borderRadius: const BorderRadius.vertical(top: Radius.circular(14)),
              child: Image.network(
                store.imageUrl,
                height: 100,
                width: double.infinity,
                fit: BoxFit.cover,
                errorBuilder: (_, __, ___) => Container(
                  height: 100,
                  color: Colors.grey.shade200,
                  child: const Icon(Icons.storefront, color: Colors.grey),
                ),
              ),
            ),
            Padding(
              padding: const EdgeInsets.all(10),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    store.name,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(fontWeight: FontWeight.w700, fontSize: 14),
                  ),
                  const SizedBox(height: 4),
                  Row(
                    children: [
                      const Icon(Icons.star, size: 14, color: Color(0xFFF59E0B)),
                      const SizedBox(width: 4),
                      Text(
                        store.rating.toString(),
                        style: TextStyle(
                          color: Colors.grey.shade700,
                          fontSize: 12,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                      const Spacer(),
                      const Text(
                        '• 1.5km',
                        style: TextStyle(color: Colors.grey, fontSize: 11),
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

class _FoodCard extends StatelessWidget {
  final MenuItemModel item;
  final VoidCallback onTap;
  final VoidCallback onQuickAdd;

  const _FoodCard({
    required this.item,
    required this.onTap,
    required this.onQuickAdd,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(20),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.04),
              blurRadius: 12,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        child: Row(
          children: [
            ClipRRect(
              borderRadius: BorderRadius.circular(16),
              child: Image.network(
                item.imageUrl,
                width: 95,
                height: 95,
                fit: BoxFit.cover,
                errorBuilder: (_, __, ___) => Container(
                  width: 95,
                  height: 95,
                  color: Colors.grey.shade100,
                  child: const Icon(Icons.fastfood, color: Colors.grey),
                ),
              ),
            ),
            const SizedBox(width: 14),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    item.name,
                    style: const TextStyle(
                      fontWeight: FontWeight.w700,
                      fontSize: 16,
                      color: Color(0xFF1F2937),
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    item.description,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: TextStyle(color: Colors.grey.shade500, fontSize: 13),
                  ),
                  const SizedBox(height: 8),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        formatPriceVnd(item.price),
                        style: const TextStyle(
                          fontWeight: FontWeight.w800,
                          fontSize: 17,
                          color: Color(0xFF0E9F6E),
                        ),
                      ),
                      IconButton.filled(
                        onPressed: onQuickAdd,
                        icon: const Icon(Icons.add, size: 20),
                        style: IconButton.styleFrom(
                          backgroundColor: const Color(0xFF0E9F6E),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12),
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
      width: 140,
      padding: const EdgeInsets.all(8),
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.15),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Colors.white24),
      ),
      child: Row(
        children: [
          ClipRRect(
            borderRadius: BorderRadius.circular(10),
            child: Image.network(
              item.imageUrl,
              width: 50,
              height: 50,
              fit: BoxFit.cover,
            ),
          ),
          const SizedBox(width: 8),
          Expanded(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  item.name,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(
                    color: Colors.white,
                    fontWeight: FontWeight.bold,
                    fontSize: 12,
                  ),
                ),
                Text(
                  formatPriceVnd(item.price),
                  style: const TextStyle(
                    color: Color(0xFFFFD700),
                    fontSize: 11,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class FoodDetailPage extends StatefulWidget {
  final MenuItemModel item;
  final void Function(MenuItemModel item, FoodCustomization customization) onAddToCart;

  const FoodDetailPage({
    super.key,
    required this.item,
    required this.onAddToCart,
  });

  @override
  State<FoodDetailPage> createState() => _FoodDetailPageState();
}

class _FoodDetailPageState extends State<FoodDetailPage> {
  String _selectedSize = 'M';
  String _selectedSugar = '70%';
  String _selectedIce = '70%';
  final List<String> _selectedToppings = [];

  void _toggleTopping(String topping) {
    setState(() {
      if (_selectedToppings.contains(topping)) {
        _selectedToppings.remove(topping);
      } else {
        _selectedToppings.add(topping);
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    final extraPrice = _selectedSize == 'L' ? 7000 : 0;
    final toppingsPrice = _selectedToppings.length * 5000;
    final totalPrice = widget.item.price + extraPrice + toppingsPrice;

    return Scaffold(
      extendBodyBehindAppBar: true, // Cho phép body tràn lên dưới AppBar
      appBar: AppBar(
        leading: Padding(
          padding: const EdgeInsets.all(8.0),
          child: CircleAvatar(
            backgroundColor: Colors.black.withOpacity(0.3),
            child: IconButton(
              icon: const Icon(Icons.arrow_back, color: Colors.white),
              onPressed: () => Navigator.pop(context),
            ),
          ),
        ),
        backgroundColor: Colors.transparent,
        elevation: 0,
      ),
      body: CustomScrollView(
        slivers: [
          SliverToBoxAdapter(
            child: Stack(
              children: [
                Image.network(
                  widget.item.imageUrl,
                  height: 300,
                  width: double.infinity,
                  fit: BoxFit.cover,
                ),
              ],
            ),
          ),
          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.all(20),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    widget.item.name,
                    style: const TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    widget.item.description,
                    style: const TextStyle(color: Colors.grey, fontSize: 15),
                  ),
                  const Divider(height: 40),
                  
                  _sectionTitle('Chọn Size'),
                  Wrap(
                    spacing: 12,
                    children: ['S', 'M', 'L'].map((s) => ChoiceChip(
                      label: Text('Size $s'),
                      selected: _selectedSize == s,
                      onSelected: (_) => setState(() => _selectedSize = s),
                    )).toList(),
                  ),
                  
                  const SizedBox(height: 24),
                  _sectionTitle('Mức đường'),
                  Wrap(
                    spacing: 12,
                    children: ['0%', '30%', '50%', '70%', '100%'].map((s) => ChoiceChip(
                      label: Text(s),
                      selected: _selectedSugar == s,
                      onSelected: (_) => setState(() => _selectedSugar = s),
                    )).toList(),
                  ),
                  
                  const SizedBox(height: 24),
                  _sectionTitle('Mức đá'),
                  Wrap(
                    spacing: 12,
                    children: ['Không đá', '50%', '100%'].map((s) => ChoiceChip(
                      label: Text(s),
                      selected: _selectedIce == s,
                      onSelected: (_) => setState(() => _selectedIce = s),
                    )).toList(),
                  ),
                  
                  const SizedBox(height: 24),
                  _sectionTitle('Topping (+5k)'),
                  Wrap(
                    spacing: 12,
                    children: ['Trân châu', 'Thạch vải', 'Kem Cheese'].map((t) => FilterChip(
                      label: Text(t),
                      selected: _selectedToppings.contains(t),
                      onSelected: (_) => _toggleTopping(t),
                    )).toList(),
                  ),
                  
                  const SizedBox(height: 100),
                ],
              ),
            ),
          ),
        ],
      ),
      bottomSheet: Container(
        padding: const EdgeInsets.all(20),
        decoration: const BoxDecoration(
          color: Colors.white,
          boxShadow: [BoxShadow(color: Colors.black12, blurRadius: 10)],
        ),
        child: Row(
          children: [
            Text(
              formatPriceVnd(totalPrice),
              style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold, color: Color(0xFF0E9F6E)),
            ),
            const Spacer(),
            ElevatedButton(
              onPressed: () {
                widget.onAddToCart(
                  widget.item,
                  FoodCustomization(
                    size: _selectedSize,
                    sugar: _selectedSugar,
                    ice: _selectedIce,
                    toppings: _selectedToppings,
                  ),
                );
                Navigator.pop(context);
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFF0E9F6E),
                foregroundColor: Colors.white,
              ),
              child: const Text('THÊM VÀO GIỎ'),
            ),
          ],
        ),
      ),
    );
  }

  Widget _sectionTitle(String title) => Padding(
    padding: const EdgeInsets.only(bottom: 12),
    child: Text(
      title,
      style: const TextStyle(fontSize: 17, fontWeight: FontWeight.bold),
    ),
  );
}

class CartPage extends StatelessWidget {
  final CartController cart;
  final Function(int) onRemoveAt;
  const CartPage({super.key, required this.cart, required this.onRemoveAt});
  @override
  Widget build(BuildContext context) => Scaffold(appBar: AppBar(title: const Text('Giỏ hàng')));
}
