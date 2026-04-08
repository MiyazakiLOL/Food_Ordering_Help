import 'package:flutter/material.dart';
import 'package:flutter/gestures.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import 'cart_controller.dart';
import 'auth/auth_gate.dart';
import 'profile/profile_page.dart';
import 'menu_models.dart';
import 'menu_repository.dart';
import 'voucher_repository.dart';
import 'voucher_history.dart';
import 'order_repository.dart';
import 'order_detail_page.dart';
import 'profile/shipping_address_model.dart';
import 'profile/shipping_address_repository.dart';
import 'profile/addresses_page.dart';
import 'app_strings.dart';

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

  @override
  void initState() {
    super.initState();
    // Vẫn giữ nguyên setState ở đây vì nó chỉ chạy 1 lần lúc khởi động
    _cart.loadCart().then((_) => setState(() {}));
  }

  // SỬA Ở ĐÂY: Xóa bỏ setState
  void _addToCart(MenuItemModel item, FoodCustomization customization) {
    _cart.addItem(item, customization);
  }

  // SỬA Ở ĐÂY: Xóa bỏ setState
  void _removeFromCart(int index) {
    _cart.removeAt(index);
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
    AppStrings.allCategory,
    'Trà sữa',
    'Cà phê',
    'Đồ ăn vặt',
    'Thức ăn nhanh',
    'Sinh tố & Nước ép',
  ];
  
  HomeData? _data;
  bool _isLoading = true;
  String? _error;

  String? _selectedStoreId;
  String _selectedCategory = AppStrings.allCategory;
  int _currentPage = 0;
  final int _pageSize = 10;

  @override
  void initState() {
    super.initState();
    _loadData();
  }

  Future<void> _loadData({bool silent = false}) async {
    if (!silent) {
      setState(() {
        _isLoading = true;
        _error = null;
      });
    }
    
    try {
      final newData = await _repository.fetchHomeData(
        page: _currentPage, 
        pageSize: _pageSize,
        storeId: _selectedStoreId,
        category: _selectedCategory,
      );
      if (mounted) {
        setState(() {
          _data = newData;
          _isLoading = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _error = e.toString();
          _isLoading = false;
        });
      }
    }
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
              AppStrings.homeTitle,
              style: TextStyle(
                color: Colors.white,
                fontSize: 24,
                fontWeight: FontWeight.w900,
                height: 1.0,
              ),
            ),
            SizedBox(height: 3),
            Text(
              AppStrings.homeSubtitle,
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
      body: _isLoading && _data == null
          ? const Center(child: CircularProgressIndicator())
          : _error != null && _data == null
              ? Center(child: Text('${AppStrings.loadDataError}: $_error'))
              : _buildContent(),
    );
  }

  Widget _buildContent() {
    if (_data == null) return const Center(child: Text(AppStrings.noData));

    final data = _data!;
    final displayedItems = data.featuredItems;
    final dealItems = data.featuredItems
        .where((item) => item.discountPercent > 0)
        .take(6)
        .toList();

    return RefreshIndicator(
      onRefresh: () async {
        _currentPage = 0;
        await _loadData(silent: true);
      },
      child: Stack(
        children: [
          ListView(
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
                      color: Colors.black.withOpacity(0.1),
                      blurRadius: 16,
                      offset: const Offset(0, 8),
                    ),
                  ],
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      AppStrings.hotDeals,
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: 20,
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                    const SizedBox(height: 4),
                    const Text(
                      AppStrings.dealSubtitle,
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
                AppStrings.featuredStores,
                style: TextStyle(fontSize: 20, fontWeight: FontWeight.w700),
              ),
              const SizedBox(height: 12),
              Row(
                children: [
                  const Icon(Icons.swipe, size: 18, color: Color(0xFF6B7280)),
                  const SizedBox(width: 6),
                  const Text(
                    AppStrings.swipeHint,
                    style: TextStyle(color: Color(0xFF6B7280)),
                  ),
                  const Spacer(),
                  if (_selectedStoreId != null)
                    TextButton(
                      onPressed: () {
                        setState(() {
                          _selectedStoreId = null;
                          _currentPage = 0;
                        });
                        _loadData(silent: true);
                      },
                      child: const Text(AppStrings.viewAll),
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
                            _selectedStoreId = _selectedStoreId == store.id ? null : store.id;
                            _currentPage = 0;
                          });
                          _loadData(silent: true);
                        },
                      );
                    },
                  ),
                ),
              ),
              const SizedBox(height: 24),
              const Text(
                AppStrings.hotFood,
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
                          _currentPage = 0;
                        });
                        _loadData(silent: true);
                      },
                    );
                  },
                ),
              ),
              const SizedBox(height: 12),
              
              if (displayedItems.isEmpty)
                const Padding(
                  padding: EdgeInsets.symmetric(vertical: 24),
                  child: Center(child: Text(AppStrings.noFoodMatch)),
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
                            content: Text('${AppStrings.addedToCart} ${item.name}'),
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

              const SizedBox(height: 20),
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  IconButton(
                    onPressed: _currentPage > 0 
                      ? () { 
                          _currentPage--; 
                          _loadData(silent: true); 
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
                      '${AppStrings.pageLabel} ${_currentPage + 1}',
                      style: const TextStyle(fontWeight: FontWeight.bold),
                    ),
                  ),
                  IconButton(
                    onPressed: displayedItems.length == _pageSize 
                      ? () { 
                          _currentPage++; 
                          _loadData(silent: true); 
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
          if (_isLoading)
            Container(
              color: Colors.white.withOpacity(0.3),
              child: const Center(child: CircularProgressIndicator()),
            ),
        ],
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
              color: Colors.black.withOpacity(0.05),
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
              color: Colors.black.withOpacity(0.04),
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
      extendBodyBehindAppBar: true, 
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

class CartPage extends StatefulWidget {
  final CartController cart;
  final Function(int) onRemoveAt;
  
  const CartPage({
    super.key,
    required this.cart,
    required this.onRemoveAt,
  });

  @override
  State<CartPage> createState() => _CartPageState();
}

class _CartPageState extends State<CartPage> {
  final VoucherRepository _voucherRepository = VoucherRepository();
  final OrderRepository _orderRepository = OrderRepository();
  final ShippingAddressRepository _addressRepository = ShippingAddressRepository();
  
  final TextEditingController _voucherController = TextEditingController();
  String? _voucherError;
  bool _isApplyingVoucher = false;
  bool _isPlacingOrder = false;
  final double _shippingFee = 20000; 
  late Future<List<String>> _voucherHistoryFuture;
  ShippingAddress? _selectedAddress;

  @override
  void initState() {
    super.initState();
    widget.cart.setShippingFee(_shippingFee);
    _voucherHistoryFuture = VoucherHistory.getHistory();
    _loadDefaultAddress();
  }

  Future<void> _loadDefaultAddress() async {
    try {
      final addresses = await _addressRepository.listMine();
      if (addresses.isNotEmpty) {
        setState(() {
          _selectedAddress = addresses.firstWhere((a) => a.isDefault, orElse: () => addresses.first);
        });
      }
    } catch (e) {
      print('Error loading address: $e');
    }
  }

  @override
  void dispose() {
    _voucherController.dispose();
    super.dispose();
  }

  Future<void> _applyVoucher() async {
    final code = _voucherController.text.trim().toUpperCase();
    if (code.isEmpty) {
      setState(() => _voucherError = 'Vui lòng nhập mã giảm giá');
      return;
    }

    setState(() => _isApplyingVoucher = true);

    try {
      final voucher = await _voucherRepository.getVoucherByCode(code);

      if (!mounted) return;

      if (voucher == null) {
        setState(() {
          _voucherError = 'Mã giảm giá không hợp lệ hoặc đã hết hạn';
          _isApplyingVoucher = false;
        });
        return;
      }

      if (widget.cart.subtotal < voucher.minOrderValue) {
        setState(() {
          _voucherError =
              'Đơn hàng phải từ ${formatPriceVnd(voucher.minOrderValue)} trở lên';
          _isApplyingVoucher = false;
        });
        return;
      }

      setState(() {
        widget.cart.applyVoucher(voucher);
        _voucherError = null;
        _voucherController.clear();
        _isApplyingVoucher = false;
      });

      await VoucherHistory.addToHistory(code);
      
      setState(() {
        _voucherHistoryFuture = VoucherHistory.getHistory();
      });

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Áp dụng voucher thành công - ${voucher.description}'),
          backgroundColor: Colors.green,
        ),
      );
    } catch (e) {
      setState(() {
        _voucherError = 'Lỗi khi kiểm tra voucher';
        _isApplyingVoucher = false;
      });
    }
  }

  Future<void> _placeOrder() async {
    if (_selectedAddress == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Vui lòng chọn địa chỉ giao hàng')),
      );
      return;
    }

    setState(() => _isPlacingOrder = true);

    try {
      final itemsData = widget.cart.items.map((item) => {
        'product_id': item.item.id,
        'quantity': item.quantity,
        'unit_price': item.unitPrice,
      }).toList();

      final orderId = await _orderRepository.createOrder(
        shippingAddressId: _selectedAddress!.id,
        voucherId: widget.cart.appliedVoucher?.id,
        note: widget.cart.orderNote,
        shippingFee: widget.cart.shippingFee,
        totalAmount: widget.cart.grandTotal,
        items: itemsData,
      );

      if (!mounted) return;

      widget.cart.clear();
      
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Đặt hàng thành công!'), backgroundColor: Colors.green),
      );

      Navigator.pushReplacement(
        context,
        MaterialPageRoute(builder: (_) => OrderDetailPage(orderId: orderId)),
      );
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Lỗi khi đặt hàng: $e')),
      );
    } finally {
      if (mounted) setState(() => _isPlacingOrder = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final items = widget.cart.items;

    return Scaffold(
      appBar: AppBar(
        title: const Text(AppStrings.cartTitle),
        backgroundColor: const Color(0xFF0E9F6E),
        foregroundColor: Colors.white,
      ),
      body: items.isEmpty
          ? const Center(
              child: Text(AppStrings.cartEmpty),
            )
          : Column(
              children: [
                Expanded(
                  child: SingleChildScrollView(
                    child: Column(
                      children: [
                        ListView.builder(
                          shrinkWrap: true,
                          physics: const NeverScrollableScrollPhysics(),
                          itemCount: items.length,
                          itemBuilder: (context, index) {
                            final item = items[index];
                            return _CartItemTile(
                              item: item,
                              onRemove: () {
                                setState(() => widget.onRemoveAt(index));
                              },
                              onQuantityChanged: (newQuantity) {
                                setState(() =>
                                    widget.cart.updateQuantity(index, newQuantity));
                              },
                              onEditCustomization: (newCustomization) {
                                setState(() =>
                                    widget.cart.updateItem(index, newCustomization));
                              },
                            );
                          },
                        ),
                        Padding(
                          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              const Text(
                                AppStrings.noteLabel,
                                style: TextStyle(
                                  fontSize: 13,
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                              const SizedBox(height: 6),
                              TextField(
                                onChanged: (value) {
                                  widget.cart.setOrderNote(value);
                                },
                                maxLines: 2,
                                decoration: InputDecoration(
                                  isDense: true,
                                  hintText: AppStrings.noteHint,
                                  border: OutlineInputBorder(
                                    borderRadius: BorderRadius.circular(8),
                                  ),
                                  contentPadding: const EdgeInsets.symmetric(
                                    horizontal: 12,
                                    vertical: 10,
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ),
                        // Shipping Address Section
                        Padding(
                          padding: const EdgeInsets.all(16),
                          child: InkWell(
                            onTap: () async {
                              final selected = await Navigator.push<ShippingAddress>(
                                context,
                                MaterialPageRoute(builder: (_) => const AddressesPage()),
                              );
                              if (selected != null) {
                                setState(() {
                                  _selectedAddress = selected;
                                });
                              }
                              // Đã sửa: Không tự động gọi _loadDefaultAddress() khi nhấn nút Back (selected == null)
                            },
                            child: Container(
                              padding: const EdgeInsets.all(12),
                              decoration: BoxDecoration(
                                color: Colors.white,
                                borderRadius: BorderRadius.circular(12),
                                border: Border.all(color: Colors.grey.shade300),
                              ),
                              child: Row(
                                children: [
                                  const Icon(Icons.location_on, color: Color(0xFF0E9F6E)),
                                  const SizedBox(width: 12),
                                  Expanded(
                                    child: Column(
                                      crossAxisAlignment: CrossAxisAlignment.start,
                                      children: [
                                        const Text(
                                          AppStrings.shippingAddress,
                                          style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13),
                                        ),
                                        Text(
                                          _selectedAddress?.fullAddress ?? AppStrings.noAddressSelected,
                                          maxLines: 1,
                                          overflow: TextOverflow.ellipsis,
                                          style: TextStyle(color: Colors.grey.shade800, fontSize: 13, fontWeight: FontWeight.w500),
                                        ),
                                        if (_selectedAddress != null)
                                          Text(
                                            '${_selectedAddress!.recipientName} • ${_selectedAddress!.phoneNumber}',
                                            style: TextStyle(color: Colors.grey.shade600, fontSize: 12),
                                          ),
                                      ],
                                    ),
                                  ),
                                  const Icon(Icons.chevron_right, size: 20),
                                ],
                              ),
                            ),
                          ),
                        ),
                        Padding(
                          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              const Divider(height: 8),
                              const SizedBox(height: 8),
                              const Text(
                                AppStrings.voucherLabel,
                                style: TextStyle(
                                  fontSize: 13,
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                              const SizedBox(height: 6),
                              if (widget.cart.appliedVoucher != null) ...[
                                Container(
                                  padding: const EdgeInsets.all(16),
                                  decoration: BoxDecoration(
                                    color: widget.cart.subtotal < widget.cart.appliedVoucher!.minOrderValue
                                        ? Colors.orange.shade50
                                        : widget.cart.appliedVoucher!.isExpiringSoon
                                            ? Colors.yellow.shade50
                                            : Colors.green.shade50,
                                    borderRadius: BorderRadius.circular(12),
                                    border: Border.all(
                                      color: widget.cart.subtotal < widget.cart.appliedVoucher!.minOrderValue
                                          ? Colors.orange.shade300
                                          : widget.cart.appliedVoucher!.isExpiringSoon
                                              ? Colors.yellow.shade300
                                              : Colors.green.shade300,
                                    ),
                                  ),
                                  child: Row(
                                    children: [
                                      Expanded(
                                        child: Column(
                                          crossAxisAlignment: CrossAxisAlignment.start,
                                          children: [
                                            Text(
                                              widget.cart.appliedVoucher!.code,
                                              style: const TextStyle(
                                                fontWeight: FontWeight.bold,
                                                fontSize: 14,
                                              ),
                                            ),
                                            Text(
                                              widget.cart.appliedVoucher!.description,
                                              style: const TextStyle(
                                                color: Colors.black54,
                                                fontSize: 12,
                                              ),
                                            ),
                                            const SizedBox(height: 4),
                                            Row(
                                              children: [
                                                Icon(
                                                  Icons.schedule,
                                                  size: 12,
                                                  color: widget.cart.appliedVoucher!.isExpiringSoon
                                                      ? Colors.red
                                                      : Colors.grey,
                                                ),
                                                const SizedBox(width: 4),
                                                Text(
                                                  widget.cart.appliedVoucher!.expirationText,
                                                  style: TextStyle(
                                                    fontSize: 11,
                                                    color: widget.cart.appliedVoucher!.isExpiringSoon
                                                        ? Colors.red
                                                        : Colors.grey,
                                                    fontWeight: widget.cart.appliedVoucher!.isExpiringSoon
                                                        ? FontWeight.w600
                                                        : FontWeight.normal,
                                                  ),
                                                ),
                                              ],
                                            ),
                                            if (widget.cart.subtotal < widget.cart.appliedVoucher!.minOrderValue)
                                              Padding(
                                                padding: const EdgeInsets.only(top: 6),
                                                child: Text(
                                                  '⚠️ Đơn hàng phải từ ${formatPriceVnd(widget.cart.appliedVoucher!.minOrderValue)} để dùng',
                                                  style: const TextStyle(
                                                    color: Colors.orange,
                                                    fontSize: 11,
                                                    fontWeight: FontWeight.w600,
                                                  ),
                                                ),
                                              ),
                                          ],
                                        ),
                                      ),
                                      TextButton(
                                        onPressed: () {
                                          setState(() {
                                            widget.cart.removeVoucher();
                                            _voucherError = null;
                                          });
                                        },
                                        child: const Text('Xóa'),
                                      ),
                                    ],
                                  ),
                                ),
                              ] else ...[
                                SizedBox(
                                  width: double.infinity,
                                  child: Column(
                                    children: [
                                      Row(
                                        children: [
                                          Expanded(
                                            child: TextField(
                                              controller: _voucherController,
                                              decoration: InputDecoration(
                                                isDense: true,
                                                hintText: 'Vd: FREESHIP, GIAM20K...',
                                                border: OutlineInputBorder(
                                                  borderRadius: BorderRadius.circular(8),
                                                ),
                                                errorText: _voucherError,
                                                contentPadding: const EdgeInsets.symmetric(
                                                  horizontal: 12,
                                                  vertical: 10,
                                                ),
                                              ),
                                              textCapitalization:
                                                  TextCapitalization.characters,
                                            ),
                                          ),
                                          const SizedBox(width: 8),
                                          ElevatedButton(
                                            onPressed: _isApplyingVoucher ? null : _applyVoucher,
                                            style: ElevatedButton.styleFrom(
                                              backgroundColor: const Color(0xFF0E9F6E),
                                              foregroundColor: Colors.white,
                                              padding: const EdgeInsets.symmetric(
                                                horizontal: 14,
                                                vertical: 8,
                                              ),
                                            ),
                                            child: _isApplyingVoucher
                                                ? const SizedBox(
                                                    width: 16,
                                                    height: 16,
                                                    child: CircularProgressIndicator(
                                                      strokeWidth: 2,
                                                      valueColor:
                                                          AlwaysStoppedAnimation<Color>(
                                                            Colors.white,
                                                          ),
                                                    ),
                                                  )
                                                : const Text(
                                                    AppStrings.applyLabel,
                                                    style: TextStyle(fontSize: 12),
                                                  ),
                                          ),
                                        ],
                                      ),
                                      const SizedBox(height: 8),
                                      SizedBox(
                                        width: double.infinity,
                                        child: TextButton.icon(
                                          onPressed: _isApplyingVoucher
                                              ? null
                                              : () async {
                                                  setState(() => _isApplyingVoucher = true);
                                                  final bestVoucher = await _voucherRepository
                                                      .suggestBestVoucher(widget.cart.subtotal);
                                                  if (bestVoucher != null) {
                                                    widget.cart.applyVoucher(bestVoucher);
                                                    ScaffoldMessenger.of(context).showSnackBar(
                                                      SnackBar(
                                                        content: Text(
                                                          '✨ Đã áp dụng voucher tốt nhất: ${bestVoucher.code}',
                                                        ),
                                                        backgroundColor: Colors.blue,
                                                      ),
                                                    );
                                                    setState(() {
                                                      _voucherError = null;
                                                      _isApplyingVoucher = false;
                                                    });
                                                  } else {
                                                    setState(() {
                                                      _voucherError = 'Không có voucher nào phù hợp';
                                                      _isApplyingVoucher = false;
                                                    });
                                                  }
                                                },
                                          icon: const Icon(Icons.lightbulb_outline),
                                          label: const Text(AppStrings.suggestVoucher),
                                          style: TextButton.styleFrom(
                                            foregroundColor: const Color(0xFF0E9F6E),
                                          ),
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                              ],
                              const SizedBox(height: 14),
                              FutureBuilder<List<String>>(
                                future: _voucherHistoryFuture,
                                builder: (context, snapshot) {
                                  if (!snapshot.hasData || snapshot.data!.isEmpty) {
                                    return const SizedBox.shrink();
                                  }
                                  final history = snapshot.data!;
                                  return Column(
                                    crossAxisAlignment: CrossAxisAlignment.start,
                                    children: [
                                      const Text(
                                        AppStrings.recentVouchers,
                                        style: TextStyle(
                                          fontSize: 12,
                                          fontWeight: FontWeight.w600,
                                          color: Colors.grey,
                                        ),
                                      ),
                                      const SizedBox(height: 6),
                                      Wrap(
                                        spacing: 6,
                                        children: history.take(4).map((code) {
                                          return GestureDetector(
                                            onTap: () {
                                              _voucherController.text = code;
                                              _applyVoucher();
                                            },
                                            child: Container(
                                              padding: const EdgeInsets.symmetric(
                                                horizontal: 10,
                                                vertical: 6,
                                              ),
                                              decoration: BoxDecoration(
                                                color: Colors.blue.shade50,
                                                border: Border.all(
                                                  color: Colors.blue.shade200,
                                                ),
                                                borderRadius: BorderRadius.circular(8),
                                              ),
                                              child: Text(
                                                code,
                                                style: const TextStyle(
                                                  fontSize: 11,
                                                  fontWeight: FontWeight.w600,
                                                  color: Colors.blue,
                                                ),
                                              ),
                                            ),
                                          );
                                        }).toList(),
                                      ),
                                    ],
                                  );
                                },
                              ),
                          ],
                        ),
                        ),
                      ],
                    ),
                  ),
                ),
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: Colors.grey.shade50,
                    border: Border(
                      top: BorderSide(color: Colors.grey.shade200),
                    ),
                  ),
                  child: Column(
                    children: [
                      ExpansionTile(
                        title: const Text(
                          AppStrings.pricingDetails,
                          style: TextStyle(
                            fontSize: 12,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                        children: [
                          const SizedBox(height: 8),
                          ...widget.cart.items.map((item) {
                            final basePrice = item.item.price;
                            final customExtra = item.customization.extraPrice;
                            return Padding(
                              padding: const EdgeInsets.only(bottom: 8),
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    '${item.item.name} × ${item.quantity}',
                                    style: const TextStyle(
                                      fontSize: 13,
                                      fontWeight: FontWeight.w600,
                                    ),
                                  ),
                                  Padding(
                                    padding: const EdgeInsets.only(left: 16, top: 4),
                                    child: Column(
                                      crossAxisAlignment: CrossAxisAlignment.start,
                                      children: [
                                        Row(
                                          mainAxisAlignment:
                                              MainAxisAlignment.spaceBetween,
                                          children: [
                                            const Text(
                                              AppStrings.basePrice,
                                              style: TextStyle(
                                                fontSize: 12,
                                                color: Colors.grey,
                                              ),
                                            ),
                                            Text(
                                              '${formatPriceVnd(basePrice)} × ${item.quantity}',
                                              style: const TextStyle(
                                                fontSize: 12,
                                                color: Colors.grey,
                                              ),
                                            ),
                                          ],
                                        ),
                                        if (customExtra > 0) ...[
                                          Row(
                                            mainAxisAlignment:
                                                MainAxisAlignment.spaceBetween,
                                            children: [
                                              const Text(
                                                'Size + Topping',
                                                style: TextStyle(
                                                  fontSize: 12,
                                                  color: Colors.grey,
                                                ),
                                              ),
                                              Text(
                                                '${formatPriceVnd(customExtra)} × ${item.quantity}',
                                                style: const TextStyle(
                                                  fontSize: 12,
                                                  color: Colors.grey,
                                                ),
                                              ),
                                            ],
                                          ),
                                        ],
                                        Row(
                                          mainAxisAlignment:
                                              MainAxisAlignment.spaceBetween,
                                          children: [
                                            const Text(
                                              'Thành tiền',
                                              style: TextStyle(
                                                fontSize: 12,
                                                fontWeight: FontWeight.w600,
                                                color: Colors.black87,
                                              ),
                                            ),
                                            Text(
                                              formatPriceVnd(item.totalPrice),
                                              style: const TextStyle(
                                                fontSize: 12,
                                                fontWeight: FontWeight.w600,
                                                color: Color(0xFF0E9F6E),
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
                          }),
                          const Divider(height: 8),
                        ],
                      ),
                      const SizedBox(height: 6),
                      _PricingRow(
                        label: AppStrings.subtotal,
                        value: formatPriceVnd(widget.cart.subtotal),
                      ),
                      const SizedBox(height: 4),
                      _PricingRow(
                        label: AppStrings.shippingFee,
                        value: formatPriceVnd(_shippingFee),
                      ),
                      if (widget.cart.appliedVoucher != null) ...[
                        const SizedBox(height: 4),
                        _PricingRow(
                          label: 'Giảm giá (${widget.cart.appliedVoucher!.code})',
                          value: '-${formatPriceVnd(widget.cart.discountAmount)}',
                          valueColor: Colors.green,
                        ),
                      ],
                      const Divider(height: 8),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          const Text(
                            AppStrings.totalPayment,
                            style: TextStyle(
                              fontSize: 14,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          Text(
                            formatPriceVnd(widget.cart.grandTotal),
                            style: const TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.bold,
                              color: Color(0xFF0E9F6E),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 8),
                      SizedBox(
                        width: double.infinity,
                        child: ElevatedButton(
                          onPressed: _isPlacingOrder ? null : _placeOrder,
                          style: ElevatedButton.styleFrom(
                            backgroundColor: const Color(0xFF0E9F6E),
                            foregroundColor: Colors.white,
                            padding: const EdgeInsets.symmetric(vertical: 10),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(12),
                            ),
                          ),
                          child: _isPlacingOrder
                              ? const SizedBox(width: 20, height: 20, child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2))
                              : const Text(
                            AppStrings.placeOrder,
                            style: TextStyle(
                              fontSize: 14,
                              fontWeight: FontWeight.bold,
                              letterSpacing: 0.5,
                            ),
                          ),
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

class _CartItemTile extends StatelessWidget {
  final CartItemModel item;
  final VoidCallback onRemove;
  final Function(int) onQuantityChanged;
  final Function(FoodCustomization) onEditCustomization;

  const _CartItemTile({
    required this.item,
    required this.onRemove,
    required this.onQuantityChanged,
    required this.onEditCustomization,
  });

  @override
  Widget build(BuildContext context) {
    return Dismissible(
      key: Key(
        '${item.item.id}_${item.customization.size}_${item.customization.sugar}_${item.customization.ice}',
      ),
      direction: DismissDirection.endToStart,
      onDismissed: (_) => onRemove(),
      background: Container(
        alignment: Alignment.centerRight,
        padding: const EdgeInsets.only(right: 20),
        color: Colors.red,
        child: const Icon(Icons.delete, color: Colors.white),
      ),
      child: GestureDetector(
        onTap: () {
          showGeneralDialog(
            context: context,
            barrierLabel: MaterialLocalizations.of(context).modalBarrierDismissLabel,
            barrierColor: Colors.black.withOpacity(0.5),
            transitionDuration: const Duration(milliseconds: 300),
            pageBuilder: (context, animation1, animation2) {
              return _EditCustomizationDialog(
                item: item.item,
                initialCustomization: item.customization,
                onSave: (newCustomization) {
                  onEditCustomization(newCustomization);
                  Navigator.pop(context);
                },
              );
            },
            transitionBuilder: (context, animation1, animation2, child) {
              return ScaleTransition(
                scale: Tween<double>(begin: 0.5, end: 1.0).animate(
                  CurvedAnimation(parent: animation1, curve: Curves.easeOutBack),
                ),
                child: FadeTransition(
                  opacity: animation1,
                  child: child,
                ),
              );
            },
          );
        },
        child: Container(
          margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: Colors.grey.shade200),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  ClipRRect(
                    borderRadius: BorderRadius.circular(8),
                    child: Image.network(
                      item.item.imageUrl,
                      width: 80,
                      height: 80,
                      fit: BoxFit.cover,
                      errorBuilder: (_, __, ___) => Container(
                        width: 80,
                        height: 80,
                        color: Colors.grey.shade200,
                        child: const Icon(Icons.fastfood),
                      ),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          item.item.name,
                          style: const TextStyle(
                            fontWeight: FontWeight.bold,
                            fontSize: 14,
                          ),
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis,
                        ),
                        const SizedBox(height: 4),
                        Text(
                          formatPriceVnd(item.unitPrice),
                          style: const TextStyle(
                            color: Color(0xFF0E9F6E),
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ],
                    ),
                  ),
                  Column(
                    children: [
                      IconButton(
                        onPressed: onRemove,
                        icon: const Icon(Icons.close, size: 20),
                        padding: EdgeInsets.zero,
                        constraints: const BoxConstraints(),
                      ),
                    ],
                  ),
                ],
              ),
              const SizedBox(height: 8),
              Text(
                item.customization.summary,
                style: const TextStyle(
                  fontSize: 12,
                  color: Colors.grey,
                ),
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
              ),
              const SizedBox(height: 12),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Container(
                    decoration: BoxDecoration(
                      border: Border.all(color: Colors.grey.shade300),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Row(
                      children: [
                        IconButton(
                          onPressed: item.quantity > 1
                              ? () => onQuantityChanged(item.quantity - 1)
                              : null,
                          icon: const Icon(Icons.remove, size: 18),
                          padding: EdgeInsets.zero,
                          constraints: const BoxConstraints(
                            minWidth: 32,
                            minHeight: 32,
                          ),
                        ),
                        SizedBox(
                          width: 40,
                          child: Center(
                            child: Text(
                              item.quantity.toString(),
                              style: const TextStyle(fontWeight: FontWeight.bold),
                            ),
                          ),
                        ),
                        IconButton(
                          onPressed: () => onQuantityChanged(item.quantity + 1),
                          icon: const Icon(Icons.add, size: 18),
                          padding: EdgeInsets.zero,
                          constraints: const BoxConstraints(
                            minWidth: 32,
                            minHeight: 32,
                          ),
                        ),
                      ],
                    ),
                  ),
                  Text(
                    formatPriceVnd(item.totalPrice),
                    style: const TextStyle(
                      fontWeight: FontWeight.bold,
                      fontSize: 14,
                      color: Color(0xFF0E9F6E),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _EditCustomizationDialog extends StatefulWidget {
  final MenuItemModel item;
  final FoodCustomization initialCustomization;
  final Function(FoodCustomization) onSave;

  const _EditCustomizationDialog({
    required this.item,
    required this.initialCustomization,
    required this.onSave,
  });

  @override
  State<_EditCustomizationDialog> createState() => _EditCustomizationDialogState();
}

class _EditCustomizationDialogState extends State<_EditCustomizationDialog> {
  late String _selectedSize;
  late String _selectedSugar;
  late String _selectedIce;
  late List<String> _selectedToppings;

  @override
  void initState() {
    super.initState();
    _selectedSize = widget.initialCustomization.size;
    _selectedSugar = widget.initialCustomization.sugar;
    _selectedIce = widget.initialCustomization.ice;
    _selectedToppings = List.from(widget.initialCustomization.toppings);
  }

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

    return Dialog(
      insetPadding: const EdgeInsets.all(16),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: SingleChildScrollView(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisSize: MainAxisSize.min,
          children: [
            Stack(
              children: [
                Image.network(
                  widget.item.imageUrl,
                  height: 200,
                  width: double.infinity,
                  fit: BoxFit.cover,
                  errorBuilder: (_, __, ___) => Container(
                    height: 200,
                    color: Colors.grey.shade200,
                    child: const Icon(Icons.fastfood),
                  ),
                ),
                Positioned(
                  top: 10,
                  right: 10,
                  child: CircleAvatar(
                    backgroundColor: Colors.black.withOpacity(0.5),
                    child: IconButton(
                      icon: const Icon(Icons.close, color: Colors.white),
                      onPressed: () => Navigator.pop(context),
                    ),
                  ),
                ),
              ],
            ),
            Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    widget.item.name,
                    style: const TextStyle(fontSize: 22, fontWeight: FontWeight.bold),
                  ),
                  const SizedBox(height: 12),
                  _sectionTitle('Chọn Size'),
                  Wrap(
                    spacing: 12,
                    children: ['S', 'M', 'L'].map((s) => ChoiceChip(
                      label: Text('Size $s'),
                      selected: _selectedSize == s,
                      onSelected: (_) => setState(() => _selectedSize = s),
                    )).toList(),
                  ),
                  const SizedBox(height: 16),
                  _sectionTitle('Mức đường'),
                  Wrap(
                    spacing: 12,
                    children: ['0%', '30%', '50%', '70%', '100%'].map((s) => ChoiceChip(
                      label: Text(s),
                      selected: _selectedSugar == s,
                      onSelected: (_) => setState(() => _selectedSugar = s),
                    )).toList(),
                  ),
                  const SizedBox(height: 16),
                  _sectionTitle('Mức đá'),
                  Wrap(
                    spacing: 12,
                    children: ['Không đá', '50%', '100%'].map((s) => ChoiceChip(
                      label: Text(s),
                      selected: _selectedIce == s,
                      onSelected: (_) => setState(() => _selectedIce = s),
                    )).toList(),
                  ),
                  const SizedBox(height: 16),
                  _sectionTitle('Topping (+5k)'),
                  Wrap(
                    spacing: 12,
                    children: ['Trân châu', 'Thạch vải', 'Kem Cheese'].map((t) => FilterChip(
                      label: Text(t),
                      selected: _selectedToppings.contains(t),
                      onSelected: (_) => _toggleTopping(t),
                    )).toList(),
                  ),
                  const SizedBox(height: 20),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        formatPriceVnd(totalPrice),
                        style: const TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                          color: Color(0xFF0E9F6E),
                        ),
                      ),
                      ElevatedButton(
                        onPressed: () {
                          widget.onSave(
                            FoodCustomization(
                              size: _selectedSize,
                              sugar: _selectedSugar,
                              ice: _selectedIce,
                              toppings: _selectedToppings,
                            ),
                          );
                        },
                        style: ElevatedButton.styleFrom(
                          backgroundColor: const Color(0xFF0E9F6E),
                          foregroundColor: Colors.white,
                        ),
                        child: const Text('CẬP NHẬT'),
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

  Widget _sectionTitle(String title) => Padding(
    padding: const EdgeInsets.only(bottom: 10),
    child: Text(
      title,
      style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w700),
    ),
  );
}

class _PricingRow extends StatelessWidget {
  final String label;
  final String value;
  final Color valueColor;

  const _PricingRow({
    required this.label,
    required this.value,
    this.valueColor = Colors.black,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(
          label,
          style: const TextStyle(fontSize: 14),
        ),
        Text(
          value,
          style: TextStyle(
            fontWeight: FontWeight.w600,
            color: valueColor,
          ),
        ),
      ],
    );
  }
}
