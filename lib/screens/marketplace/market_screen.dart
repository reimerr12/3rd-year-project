import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/router.dart';
import '../../core/theme.dart';
import '../../models/product.dart';
import '../../providers/marketplace_provider.dart';

class MarketScreen extends ConsumerStatefulWidget {
  const MarketScreen({super.key});

  @override
  ConsumerState<MarketScreen> createState() => _MarketScreenState();
}

class _MarketScreenState extends ConsumerState<MarketScreen> {
  static const int _currentTabIndex = 1;

  final TextEditingController _searchController = TextEditingController();
  String _searchQuery = '';

  @override
  void initState() {
    super.initState();
    // Load fresh from Supabase every time screen opens
    Future.microtask(() {
      ref.read(marketplaceProvider.notifier).loadProducts();
      ref.read(marketplaceProvider.notifier).loadCart();
    });
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  void _onTabTapped(int index) {
    if (index == _currentTabIndex) return;
    switch (index) {
      case 0:
        Navigator.pushReplacementNamed(context, AppRouter.home);
        break;
      case 2:
        Navigator.pushReplacementNamed(context, AppRouter.services);
        break;
      case 3:
        Navigator.pushReplacementNamed(context, AppRouter.profile);
        break;
    }
  }

  static const _categories = [
    ('all', 'সব'),
    ('crop', 'ফসল'),
    ('fertilizer', 'সার'),
    ('insecticide', 'কীটনাশক'),
    ('tool', 'সরঞ্জাম'),
    ('other', 'অন্যান্য'),
  ];

  @override
  Widget build(BuildContext context) {
    final state = ref.watch(marketplaceProvider);
    final notifier = ref.read(marketplaceProvider.notifier);
    final cartCount = notifier.cartCount;

    final products = state.products.where((p) {
      if (_searchQuery.isEmpty) return true;
      return p.title.contains(_searchQuery) ||
          (p.description ?? '').contains(_searchQuery);
    }).toList();

    return Scaffold(
      backgroundColor: const Color(0xFFF5F7F5),
      appBar: _buildAppBar(cartCount),
      body: Column(
        children: [
          _buildSearchBar(),
          _buildCategoryChips(state.selectedCategory, notifier),
          Expanded(
            child: state.isLoading
                ? const Center(
                    child:
                        CircularProgressIndicator(color: AppTheme.primaryGreen))
                : state.error != null
                    ? _buildError(state.error!, notifier)
                    : products.isEmpty
                        ? _buildEmpty()
                        : RefreshIndicator(
                            color: AppTheme.primaryGreen,
                            onRefresh: () => notifier.loadProducts(
                                category: state.selectedCategory),
                            child: _buildProductGrid(products, notifier),
                          ),
          ),
        ],
      ),
      bottomNavigationBar: _buildBottomNav(),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => Navigator.pushNamed(context, AppRouter.sellProduct),
        backgroundColor: AppTheme.primaryGreen,
        icon: const Icon(Icons.add, color: Colors.white),
        label: const Text(
          'পণ্য বিক্রি করুন',
          style: TextStyle(color: Colors.white, fontWeight: FontWeight.w600),
        ),
      ),
    );
  }

  PreferredSizeWidget _buildAppBar(int cartCount) {
    return AppBar(
      backgroundColor: AppTheme.primaryGreen,
      elevation: 0,
      automaticallyImplyLeading: false,
      title: const Text(
        'কৃষি বাজার',
        style: TextStyle(
            color: Colors.white, fontWeight: FontWeight.bold, fontSize: 20),
      ),
      actions: [
        Stack(
          children: [
            IconButton(
              icon: const Icon(Icons.shopping_cart_outlined,
                  color: Colors.white, size: 26),
              onPressed: () => Navigator.pushNamed(context, AppRouter.cart),
            ),
            if (cartCount > 0)
              Positioned(
                right: 6,
                top: 6,
                child: Container(
                  padding: const EdgeInsets.all(3),
                  decoration: const BoxDecoration(
                      color: Colors.orange, shape: BoxShape.circle),
                  child: Text('$cartCount',
                      style: const TextStyle(
                          color: Colors.white,
                          fontSize: 10,
                          fontWeight: FontWeight.bold)),
                ),
              ),
          ],
        ),
        const SizedBox(width: 4),
      ],
    );
  }

  Widget _buildSearchBar() {
    return Container(
      color: AppTheme.primaryGreen,
      padding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
      child: TextField(
        controller: _searchController,
        onChanged: (v) => setState(() => _searchQuery = v),
        style: const TextStyle(fontSize: 14),
        decoration: InputDecoration(
          hintText: 'পণ্য খুঁজুন...',
          hintStyle: TextStyle(color: Colors.grey.shade500, fontSize: 14),
          prefixIcon: const Icon(Icons.search, color: Colors.grey, size: 20),
          suffixIcon: _searchQuery.isNotEmpty
              ? IconButton(
                  icon: const Icon(Icons.clear, color: Colors.grey, size: 18),
                  onPressed: () {
                    _searchController.clear();
                    setState(() => _searchQuery = '');
                  },
                )
              : null,
          filled: true,
          fillColor: Colors.white,
          contentPadding:
              const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
          border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: BorderSide.none),
        ),
      ),
    );
  }

  Widget _buildCategoryChips(String selected, MarketplaceNotifier notifier) {
    return Container(
      height: 48,
      color: Colors.white,
      child: ListView.separated(
        scrollDirection: Axis.horizontal,
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        itemCount: _categories.length,
        separatorBuilder: (_, __) => const SizedBox(width: 8),
        itemBuilder: (_, i) {
          final (key, label) = _categories[i];
          final isSelected = selected == key;
          return GestureDetector(
            onTap: () => notifier.setCategory(key),
            child: AnimatedContainer(
              duration: const Duration(milliseconds: 200),
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
              decoration: BoxDecoration(
                color:
                    isSelected ? AppTheme.primaryGreen : Colors.grey.shade100,
                borderRadius: BorderRadius.circular(20),
                border: Border.all(
                  color:
                      isSelected ? AppTheme.primaryGreen : Colors.grey.shade300,
                ),
              ),
              child: Text(
                label,
                style: TextStyle(
                  color: isSelected ? Colors.white : Colors.grey.shade700,
                  fontWeight: isSelected ? FontWeight.w600 : FontWeight.normal,
                  fontSize: 13,
                ),
              ),
            ),
          );
        },
      ),
    );
  }

  Widget _buildProductGrid(
      List<Product> products, MarketplaceNotifier notifier) {
    return GridView.builder(
      padding: const EdgeInsets.fromLTRB(12, 12, 12, 100),
      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 2,
        childAspectRatio: 0.72,
        crossAxisSpacing: 10,
        mainAxisSpacing: 10,
      ),
      itemCount: products.length,
      itemBuilder: (_, i) => _ProductCard(
        product: products[i],
        onAddToCart: () => notifier.addToCart(products[i]),
        onTap: () => Navigator.pushNamed(
          context,
          AppRouter.productDetail,
          arguments: products[i],
        ),
      ),
    );
  }

  Widget _buildEmpty() {
    return Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(Icons.search_off, size: 64, color: Colors.grey.shade400),
          const SizedBox(height: 12),
          Text('কোনো পণ্য পাওয়া যায়নি',
              style: TextStyle(color: Colors.grey.shade600, fontSize: 16)),
        ],
      ),
    );
  }

  Widget _buildError(String error, MarketplaceNotifier notifier) {
    return Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(Icons.error_outline, size: 64, color: Colors.grey.shade400),
          const SizedBox(height: 12),
          Text(error,
              style: TextStyle(color: Colors.grey.shade600, fontSize: 16)),
          const SizedBox(height: 16),
          ElevatedButton.icon(
            onPressed: () => notifier.loadProducts(),
            style: ElevatedButton.styleFrom(
              backgroundColor: AppTheme.primaryGreen,
              foregroundColor: Colors.white,
              shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12)),
            ),
            icon: const Icon(Icons.refresh),
            label: const Text('আবার চেষ্টা করুন'),
          ),
        ],
      ),
    );
  }

  Widget _buildBottomNav() {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: const BorderRadius.only(
          topLeft: Radius.circular(24),
          topRight: Radius.circular(24),
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.08),
            blurRadius: 10,
            offset: const Offset(0, -4),
          ),
        ],
      ),
      child: ClipRRect(
        borderRadius: const BorderRadius.only(
          topLeft: Radius.circular(24),
          topRight: Radius.circular(24),
        ),
        child: BottomNavigationBar(
          currentIndex: _currentTabIndex,
          onTap: _onTabTapped,
          type: BottomNavigationBarType.fixed,
          selectedItemColor: AppTheme.primaryGreen,
          unselectedItemColor: const Color(0xFF9E9E9E),
          selectedLabelStyle:
              const TextStyle(fontWeight: FontWeight.w600, fontSize: 10),
          unselectedLabelStyle: const TextStyle(fontSize: 10),
          backgroundColor: Colors.white,
          elevation: 0,
          items: const [
            BottomNavigationBarItem(
                icon: Icon(Icons.home_outlined), label: 'হোম'),
            BottomNavigationBarItem(
                icon: Icon(Icons.store_outlined), label: 'বাজার'),
            BottomNavigationBarItem(
                icon: Icon(Icons.miscellaneous_services_outlined),
                label: 'সেবা'),
            BottomNavigationBarItem(
                icon: Icon(Icons.person_outline), label: 'প্রোফাইল'),
          ],
        ),
      ),
    );
  }
}

// ── Product Card ───────────────────────────────────────────────
class _ProductCard extends StatelessWidget {
  final Product product;
  final VoidCallback onAddToCart;
  final VoidCallback onTap;

  const _ProductCard({
    required this.product,
    required this.onAddToCart,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(16),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.06),
              blurRadius: 8,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            ClipRRect(
              borderRadius:
                  const BorderRadius.vertical(top: Radius.circular(16)),
              child: AspectRatio(
                aspectRatio: 1.2,
                child: Stack(
                  fit: StackFit.expand,
                  children: [
                    product.primaryImage != null
                        ? Image.network(
                            product.primaryImage!,
                            fit: BoxFit.cover,
                            loadingBuilder: (_, child, progress) =>
                                progress == null
                                    ? child
                                    : Container(
                                        color: Colors.grey.shade100,
                                        child: const Center(
                                          child: CircularProgressIndicator(
                                              strokeWidth: 2,
                                              color: AppTheme.primaryGreen),
                                        ),
                                      ),
                            errorBuilder: (_, __, ___) => _imageFallback(),
                          )
                        : _imageFallback(),
                    if (product.division != null)
                      Positioned(
                        top: 6,
                        right: 6,
                        child: Container(
                          padding: const EdgeInsets.symmetric(
                              horizontal: 6, vertical: 3),
                          decoration: BoxDecoration(
                            color: Colors.black.withValues(alpha: 0.55),
                            borderRadius: BorderRadius.circular(6),
                          ),
                          child: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              const Icon(Icons.location_on,
                                  color: Colors.white, size: 9),
                              const SizedBox(width: 2),
                              Text(product.division!,
                                  style: const TextStyle(
                                      color: Colors.white,
                                      fontSize: 9,
                                      fontWeight: FontWeight.w500)),
                            ],
                          ),
                        ),
                      ),
                    if (!product.inStock)
                      Positioned(
                        top: 6,
                        left: 6,
                        child: Container(
                          padding: const EdgeInsets.symmetric(
                              horizontal: 6, vertical: 3),
                          decoration: BoxDecoration(
                            color: Colors.red.shade400,
                            borderRadius: BorderRadius.circular(6),
                          ),
                          child: const Text('স্টক নেই',
                              style: TextStyle(
                                  color: Colors.white,
                                  fontSize: 9,
                                  fontWeight: FontWeight.bold)),
                        ),
                      ),
                  ],
                ),
              ),
            ),
            Expanded(
              child: Padding(
                padding: const EdgeInsets.fromLTRB(10, 8, 10, 6),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 8, vertical: 2),
                      decoration: BoxDecoration(
                        color: AppTheme.primaryGreen.withValues(alpha: 0.1),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Text(product.categoryBn,
                          style: const TextStyle(
                              color: AppTheme.primaryGreen,
                              fontSize: 10,
                              fontWeight: FontWeight.w600)),
                    ),
                    const SizedBox(height: 4),
                    Text(product.title,
                        style: const TextStyle(
                            fontWeight: FontWeight.w600, fontSize: 13),
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis),
                    const Spacer(),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      crossAxisAlignment: CrossAxisAlignment.end,
                      children: [
                        Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text('৳${product.price.toStringAsFixed(0)}',
                                style: const TextStyle(
                                    color: AppTheme.primaryGreen,
                                    fontWeight: FontWeight.bold,
                                    fontSize: 14)),
                            Text('/${product.unit}',
                                style: TextStyle(
                                    color: Colors.grey.shade500, fontSize: 10)),
                          ],
                        ),
                        GestureDetector(
                          onTap: product.inStock ? onAddToCart : null,
                          child: Container(
                            padding: const EdgeInsets.all(6),
                            decoration: BoxDecoration(
                              color: product.inStock
                                  ? AppTheme.primaryGreen
                                  : Colors.grey.shade300,
                              borderRadius: BorderRadius.circular(8),
                            ),
                            child: Icon(Icons.add,
                                color: product.inStock
                                    ? Colors.white
                                    : Colors.grey.shade500,
                                size: 16),
                          ),
                        ),
                      ],
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

  Widget _imageFallback() => Container(
        color: Colors.grey.shade100,
        child: Center(
            child: Icon(Icons.image_outlined,
                color: Colors.grey.shade400, size: 36)),
      );
}
