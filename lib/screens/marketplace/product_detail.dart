import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/router.dart';
import '../../core/theme.dart';
import '../../models/product.dart';
import '../../providers/lang_provider.dart';
import '../../providers/marketplace_provider.dart';

String _t(bool bn, String bangla, String english) => bn ? bangla : english;

String _price(bool bn, double amount) =>
    bn ? '৳${amount.toStringAsFixed(0)}' : 'Taka ${amount.toStringAsFixed(0)}';

String _categoryLabel(bool bn, String category) {
  if (bn) {
    switch (category) {
      case 'crop':
        return 'ফসল';
      case 'fertilizer':
        return 'সার';
      case 'insecticide':
        return 'কীটনাশক';
      case 'tool':
        return 'সরঞ্জাম';
      default:
        return 'অন্যান্য';
    }
  } else {
    switch (category) {
      case 'crop':
        return 'Crops';
      case 'fertilizer':
        return 'Fertilizer';
      case 'insecticide':
        return 'Insecticide';
      case 'tool':
        return 'Tools';
      default:
        return 'Other';
    }
  }
}

class ProductDetailScreen extends ConsumerStatefulWidget {
  const ProductDetailScreen({super.key});

  @override
  ConsumerState<ProductDetailScreen> createState() =>
      _ProductDetailScreenState();
}

class _ProductDetailScreenState extends ConsumerState<ProductDetailScreen> {
  int _currentImage = 0;
  int _qty = 1;
  bool _addedToCart = false;

  @override
  Widget build(BuildContext context) {
    final bn = ref.watch(langProvider);
    final product = ModalRoute.of(context)!.settings.arguments as Product?;

    if (product == null) {
      return Scaffold(
        appBar: AppBar(backgroundColor: AppTheme.primaryGreen),
        body: Center(
            child: Text(_t(bn, 'পণ্য পাওয়া যায়নি', 'Product not found'))),
      );
    }

    final notifier = ref.read(marketplaceProvider.notifier);
    final cartCount = notifier.cartCount;

    return Scaffold(
      backgroundColor: Colors.white,
      body: CustomScrollView(
        slivers: [
          _buildSliverAppBar(product, cartCount),
          SliverToBoxAdapter(
            child: _buildBody(product, notifier, bn),
          ),
        ],
      ),
      bottomNavigationBar: _buildBottomBar(product, notifier, bn),
    );
  }

  Widget _buildSliverAppBar(Product product, int cartCount) {
    return SliverAppBar(
      expandedHeight: 300,
      pinned: true,
      backgroundColor: AppTheme.primaryGreen,
      foregroundColor: Colors.white,
      leading: IconButton(
        icon: const Icon(Icons.arrow_back),
        onPressed: () => Navigator.pop(context),
      ),
      actions: [
        Stack(
          children: [
            IconButton(
              icon: const Icon(Icons.shopping_cart_outlined),
              onPressed: () => Navigator.pushNamed(context, AppRouter.cart),
            ),
            if (cartCount > 0)
              Positioned(
                right: 6,
                top: 6,
                child: Container(
                  padding: const EdgeInsets.all(3),
                  decoration: const BoxDecoration(
                    color: Colors.orange,
                    shape: BoxShape.circle,
                  ),
                  child: Text(
                    '$cartCount',
                    style: const TextStyle(
                        color: Colors.white,
                        fontSize: 10,
                        fontWeight: FontWeight.bold),
                  ),
                ),
              ),
          ],
        ),
      ],
      flexibleSpace: FlexibleSpaceBar(
        background: Stack(
          fit: StackFit.expand,
          children: [
            product.images.isNotEmpty
                ? Image.network(
                    product.images[_currentImage],
                    fit: BoxFit.cover,
                    loadingBuilder: (_, child, progress) => progress == null
                        ? child
                        : Container(
                            color: Colors.grey.shade200,
                            child: const Center(
                              child: CircularProgressIndicator(
                                  color: AppTheme.primaryGreen),
                            ),
                          ),
                    errorBuilder: (_, __, ___) => Container(
                      color: Colors.grey.shade200,
                      child: const Icon(Icons.image_outlined,
                          size: 60, color: Colors.grey),
                    ),
                  )
                : Container(color: Colors.grey.shade200),
            Positioned(
              top: 0,
              left: 0,
              right: 0,
              height: 100,
              child: Container(
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    begin: Alignment.topCenter,
                    end: Alignment.bottomCenter,
                    colors: [
                      Colors.black.withValues(alpha: 0.4),
                      Colors.transparent,
                    ],
                  ),
                ),
              ),
            ),
            if (product.images.length > 1)
              Positioned(
                bottom: 12,
                left: 0,
                right: 0,
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: List.generate(product.images.length, (i) {
                    final active = i == _currentImage;
                    return GestureDetector(
                      onTap: () => setState(() => _currentImage = i),
                      child: AnimatedContainer(
                        duration: const Duration(milliseconds: 250),
                        margin: const EdgeInsets.symmetric(horizontal: 3),
                        width: active ? 20 : 8,
                        height: 8,
                        decoration: BoxDecoration(
                          color: active
                              ? Colors.white
                              : Colors.white.withValues(alpha: 0.5),
                          borderRadius: BorderRadius.circular(4),
                        ),
                      ),
                    );
                  }),
                ),
              ),
          ],
        ),
      ),
    );
  }

  Widget _buildBody(Product product, MarketplaceNotifier notifier, bool bn) {
    return Padding(
      padding: const EdgeInsets.all(20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // ── Title row ─────────────────────────────────────────
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Expanded(
                child: Text(
                  product.title,
                  style: const TextStyle(
                    fontSize: 22,
                    fontWeight: FontWeight.bold,
                    color: Color(0xFF1A1A1A),
                  ),
                ),
              ),
              const SizedBox(width: 12),
              Container(
                padding:
                    const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                decoration: BoxDecoration(
                  color: AppTheme.primaryGreen.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Text(
                  _categoryLabel(bn, product.category),
                  style: const TextStyle(
                    color: AppTheme.primaryGreen,
                    fontWeight: FontWeight.w600,
                    fontSize: 13,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),

          // ── Price ──────────────────────────────────────────────
          Row(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              Text(
                _price(bn, product.price),
                style: const TextStyle(
                  fontSize: 28,
                  fontWeight: FontWeight.bold,
                  color: AppTheme.primaryGreen,
                ),
              ),
              const SizedBox(width: 6),
              Padding(
                padding: const EdgeInsets.only(bottom: 4),
                child: Text(
                  '/ ${product.unit}',
                  style: TextStyle(
                    fontSize: 15,
                    color: Colors.grey.shade600,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),

          // ── Info chips ─────────────────────────────────────────
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: [
              if (product.division != null)
                _InfoChip(
                  icon: Icons.location_on_outlined,
                  label: product.division!,
                ),
              _InfoChip(
                icon: Icons.inventory_2_outlined,
                label: _t(bn, 'স্টক: ${product.stock} ${product.unit}',
                    'Stock: ${product.stock} ${product.unit}'),
                color: product.inStock ? AppTheme.primaryGreen : Colors.red,
              ),
            ],
          ),
          const SizedBox(height: 20),

          Divider(color: Colors.grey.shade200),
          const SizedBox(height: 12),

          // ── Description ────────────────────────────────────────
          Text(
            _t(bn, 'পণ্যের বিবরণ', 'Product Description'),
            style: const TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.bold,
              color: Color(0xFF1A1A1A),
            ),
          ),
          const SizedBox(height: 8),
          Text(
            product.description ??
                _t(bn, 'বিবরণ পাওয়া যায়নি।', 'No description available.'),
            style: TextStyle(
              fontSize: 14,
              color: Colors.grey.shade700,
              height: 1.6,
            ),
          ),
          const SizedBox(height: 24),

          // ── Quantity selector ──────────────────────────────────
          Text(
            _t(bn, 'পরিমাণ নির্বাচন করুন', 'Select Quantity'),
            style: const TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.bold,
              color: Color(0xFF1A1A1A),
            ),
          ),
          const SizedBox(height: 12),
          Row(
            children: [
              _QtyButton(
                icon: Icons.remove,
                onTap: () {
                  if (_qty > 1) setState(() => _qty--);
                },
              ),
              Container(
                width: 56,
                alignment: Alignment.center,
                child: Text(
                  '$_qty',
                  style: const TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
              _QtyButton(
                icon: Icons.add,
                onTap: () {
                  if (_qty < product.stock) setState(() => _qty++);
                },
              ),
              const SizedBox(width: 16),
              Text(
                '${_t(bn, 'মোট:', 'Total:')} ${_price(bn, product.price * _qty)}',
                style: const TextStyle(
                  color: AppTheme.primaryGreen,
                  fontWeight: FontWeight.bold,
                  fontSize: 16,
                ),
              ),
            ],
          ),
          const SizedBox(height: 32),
        ],
      ),
    );
  }

  Widget _buildBottomBar(
      Product product, MarketplaceNotifier notifier, bool bn) {
    return Container(
      padding: const EdgeInsets.fromLTRB(16, 12, 16, 28),
      decoration: BoxDecoration(
        color: Colors.white,
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.06),
            blurRadius: 12,
            offset: const Offset(0, -4),
          ),
        ],
      ),
      child: Row(
        children: [
          Expanded(
            child: OutlinedButton.icon(
              onPressed: product.inStock
                  ? () {
                      for (var i = 0; i < _qty; i++) {
                        notifier.addToCart(product);
                      }
                      setState(() => _addedToCart = true);
                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(
                          content: Text(_t(
                            bn,
                            '${product.title} কার্টে যোগ হয়েছে',
                            '${product.title} added to cart',
                          )),
                          backgroundColor: AppTheme.primaryGreen,
                          behavior: SnackBarBehavior.floating,
                          duration: const Duration(seconds: 2),
                        ),
                      );
                    }
                  : null,
              style: OutlinedButton.styleFrom(
                foregroundColor: AppTheme.primaryGreen,
                side: const BorderSide(color: AppTheme.primaryGreen),
                padding: const EdgeInsets.symmetric(vertical: 14),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(14),
                ),
              ),
              icon: Icon(
                _addedToCart
                    ? Icons.check_circle_outline
                    : Icons.add_shopping_cart_outlined,
                size: 18,
              ),
              label: Text(
                _addedToCart
                    ? _t(bn, 'যোগ হয়েছে', 'Added')
                    : _t(bn, 'কার্টে যোগ', 'Add to Cart'),
              ),
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: ElevatedButton(
              onPressed: product.inStock
                  ? () {
                      for (var i = 0; i < _qty; i++) {
                        notifier.addToCart(product);
                      }
                      Navigator.pushNamed(context, AppRouter.cart);
                    }
                  : null,
              style: ElevatedButton.styleFrom(
                backgroundColor: AppTheme.primaryGreen,
                foregroundColor: Colors.white,
                disabledBackgroundColor: Colors.grey.shade300,
                padding: const EdgeInsets.symmetric(vertical: 14),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(14),
                ),
              ),
              child: Text(
                product.inStock
                    ? _t(bn, 'এখনই কিনুন', 'Buy Now')
                    : _t(bn, 'স্টক নেই', 'Out of Stock'),
                style: const TextStyle(
                  fontSize: 15,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

// ── Helpers ───────────────────────────────────────────────────
class _InfoChip extends StatelessWidget {
  final IconData icon;
  final String label;
  final Color color;

  const _InfoChip({
    required this.icon,
    required this.label,
    this.color = const Color(0xFF555555),
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.08),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: color.withValues(alpha: 0.2)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 14, color: color),
          const SizedBox(width: 4),
          Text(
            label,
            style: TextStyle(
              color: color,
              fontSize: 12,
              fontWeight: FontWeight.w500,
            ),
          ),
        ],
      ),
    );
  }
}

class _QtyButton extends StatelessWidget {
  final IconData icon;
  final VoidCallback onTap;

  const _QtyButton({required this.icon, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.all(8),
        decoration: BoxDecoration(
          border: Border.all(color: Colors.grey.shade300),
          borderRadius: BorderRadius.circular(8),
        ),
        child: Icon(icon, size: 18, color: AppTheme.primaryGreen),
      ),
    );
  }
}
