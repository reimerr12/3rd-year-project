import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../models/product.dart';
import '../services/supabase_service.dart';

// ── Cart item ──────────────────────────────────────────────────
class CartItem {
  final String cartItemId; // Supabase cart_items.id
  final Product product;
  final int quantity;
  const CartItem({
    required this.cartItemId,
    required this.product,
    required this.quantity,
  });
  CartItem copyWith({int? quantity}) => CartItem(
        cartItemId: cartItemId,
        product: product,
        quantity: quantity ?? this.quantity,
      );
}

// ── Order entry ────────────────────────────────────────────────
class OrderEntry {
  final String id;
  final Product product;
  final int quantity;
  final String paymentMethod;
  final String deliveryAddress;
  final String status;
  final DateTime createdAt;

  const OrderEntry({
    required this.id,
    required this.product,
    required this.quantity,
    required this.paymentMethod,
    required this.deliveryAddress,
    required this.status,
    required this.createdAt,
  });

  OrderEntry copyWith({String? status}) => OrderEntry(
        id: id,
        product: product,
        quantity: quantity,
        paymentMethod: paymentMethod,
        deliveryAddress: deliveryAddress,
        status: status ?? this.status,
        createdAt: createdAt,
      );

  double get total => product.price * quantity;

  String get statusBn {
    switch (status) {
      case 'pending':
        return 'অপেক্ষমাণ';
      case 'confirmed':
        return 'নিশ্চিত';
      case 'shipped':
        return 'পাঠানো হয়েছে';
      case 'delivered':
        return 'পৌঁছে গেছে';
      case 'cancelled':
        return 'বাতিল';
      default:
        return status;
    }
  }

  Color get statusColor {
    switch (status) {
      case 'pending':
        return const Color(0xFFF59E0B);
      case 'confirmed':
        return const Color(0xFF3B82F6);
      case 'shipped':
        return const Color(0xFF8B5CF6);
      case 'delivered':
        return const Color(0xFF22C55E);
      case 'cancelled':
        return const Color(0xFFEF4444);
      default:
        return const Color(0xFF9E9E9E);
    }
  }

  IconData get statusIcon {
    switch (status) {
      case 'pending':
        return Icons.hourglass_empty_rounded;
      case 'confirmed':
        return Icons.check_circle_outline_rounded;
      case 'shipped':
        return Icons.local_shipping_outlined;
      case 'delivered':
        return Icons.done_all_rounded;
      case 'cancelled':
        return Icons.cancel_outlined;
      default:
        return Icons.info_outline;
    }
  }
}

// ── State ──────────────────────────────────────────────────────
class MarketplaceState {
  final List<Product> products;
  final List<CartItem> cart;
  final List<OrderEntry> orders;
  final bool isLoading;
  final bool isCartLoading;
  final bool isOrdersLoading;
  final String? error;
  final String selectedCategory;

  const MarketplaceState({
    this.products = const [],
    this.cart = const [],
    this.orders = const [],
    this.isLoading = false,
    this.isCartLoading = false,
    this.isOrdersLoading = false,
    this.error,
    this.selectedCategory = 'all',
  });

  MarketplaceState copyWith({
    List<Product>? products,
    List<CartItem>? cart,
    List<OrderEntry>? orders,
    bool? isLoading,
    bool? isCartLoading,
    bool? isOrdersLoading,
    String? error,
    String? selectedCategory,
  }) =>
      MarketplaceState(
        products: products ?? this.products,
        cart: cart ?? this.cart,
        orders: orders ?? this.orders,
        isLoading: isLoading ?? this.isLoading,
        isCartLoading: isCartLoading ?? this.isCartLoading,
        isOrdersLoading: isOrdersLoading ?? this.isOrdersLoading,
        error: error,
        selectedCategory: selectedCategory ?? this.selectedCategory,
      );
}

// ── Notifier ───────────────────────────────────────────────────
class MarketplaceNotifier extends StateNotifier<MarketplaceState> {
  MarketplaceNotifier() : super(const MarketplaceState()) {
    loadProducts();
  }

  final _service = SupabaseService();

  // ── Products ───────────────────────────────────────────────
  Future<void> loadProducts({String? category}) async {
    state = state.copyWith(isLoading: true, error: null);
    try {
      final raw = await _service.fetchProducts(
        category: (category == null || category == 'all') ? null : category,
      );
      final products = raw.map(_productFromModel).toList();
      state = state.copyWith(products: products, isLoading: false);
    } catch (e) {
      state = state.copyWith(isLoading: false, error: 'পণ্য লোড করা যায়নি');
    }
  }

  void setCategory(String category) {
    state = state.copyWith(selectedCategory: category);
    loadProducts(category: category);
  }

  List<Product> get filteredProducts => state.products;

  // ── Cart ───────────────────────────────────────────────────
  Future<void> loadCart() async {
    state = state.copyWith(isCartLoading: true);
    try {
      final raw = await _service.fetchCart();
      final cartItems = raw
          .where((item) => item.product != null)
          .map((item) => CartItem(
                cartItemId: item.id,
                product: _productFromModel(item.product!),
                quantity: item.quantity,
              ))
          .toList();
      state = state.copyWith(cart: cartItems, isCartLoading: false);
    } catch (e) {
      state = state.copyWith(isCartLoading: false);
    }
  }

  Future<void> addToCart(Product product) async {
    if (!product.inStock) return;

    // Optimistic update
    final idx = state.cart.indexWhere((e) => e.product.id == product.id);
    if (idx >= 0) {
      final updated = [...state.cart];
      updated[idx] = updated[idx].copyWith(quantity: updated[idx].quantity + 1);
      state = state.copyWith(cart: updated);
    } else {
      // Use empty string for cartItemId until Supabase responds
      state = state.copyWith(cart: [
        ...state.cart,
        CartItem(cartItemId: '', product: product, quantity: 1),
      ]);
    }

    // Persist to Supabase then reload to get real cartItemId
    try {
      await _service.addToCart(productId: product.id, quantity: 1);
      await loadCart();
    } catch (_) {
      await loadCart();
    }
  }

  Future<void> removeFromCart(String productId) async {
    final matches = state.cart.where((e) => e.product.id == productId).toList();
    if (matches.isEmpty) return;
    final item = matches.first;
    if (item.cartItemId.isEmpty) return;

    // Optimistic update
    state = state.copyWith(
      cart: state.cart.where((e) => e.product.id != productId).toList(),
    );
    try {
      await _service.removeFromCart(item.cartItemId);
    } catch (_) {
      await loadCart();
    }
  }

  Future<void> updateQuantity(String productId, int delta) async {
    final idx = state.cart.indexWhere((e) => e.product.id == productId);
    if (idx < 0) return;
    final current = state.cart[idx];
    final newQty = (current.quantity + delta).clamp(1, 9999);

    // Optimistic update
    final updated = [...state.cart];
    updated[idx] = current.copyWith(quantity: newQty);
    state = state.copyWith(cart: updated);

    try {
      await _service.updateCartQuantity(
        cartItemId: current.cartItemId,
        quantity: newQty,
      );
    } catch (_) {
      await loadCart();
    }
  }

  Future<void> clearCart() async {
    state = state.copyWith(cart: []);
    try {
      await _service.clearCart();
    } catch (_) {
      await loadCart();
    }
  }

  // ── Orders ─────────────────────────────────────────────────
  Future<void> loadOrders() async {
    state = state.copyWith(isOrdersLoading: true);
    try {
      // fetchMyOrders returns OrderModel list (no nested product).
      // We build a product map from current state.products for matching,
      // then fetch any missing products individually.
      final raw = await _service.fetchMyOrders();
      final productMap = {for (final p in state.products) p.id: p};

      final orders = <OrderEntry>[];
      for (final o in raw) {
        // Try to find product in already-loaded list
        var product = productMap[o.productId];

        // If not found (e.g. different category loaded), fetch from Supabase
        if (product == null) {
          try {
            final pm = await _service.fetchProductById(o.productId);
            product = _productFromModel(pm);
          } catch (_) {
            // Product deleted — create a placeholder
            product = Product(
              id: o.productId,
              sellerId: o.sellerId,
              title: 'পণ্য পাওয়া যায়নি',
              category: 'other',
              price: o.total / o.quantity,
              unit: '',
              stock: 0,
              images: const [],
              isActive: false,
              createdAt: o.createdAt,
            );
          }
        }

        orders.add(OrderEntry(
          id: o.id,
          product: product,
          quantity: o.quantity,
          paymentMethod: o.paymentMethod ?? 'cash',
          deliveryAddress: o.deliveryAddress ?? '',
          status: o.status,
          createdAt: o.createdAt,
        ));
      }

      state = state.copyWith(orders: orders, isOrdersLoading: false);
    } catch (e) {
      state = state.copyWith(isOrdersLoading: false);
    }
  }

  // placeOrdersFromCart() in SupabaseService handles payment/address
  // via placeOrder() per item. We pass them through our own loop.
  Future<List<OrderEntry>> placeOrders({
    required String paymentMethod,
    required String deliveryAddress,
  }) async {
    final cart = state.cart;
    if (cart.isEmpty) throw Exception('Cart is empty');

    final placed = <OrderEntry>[];

    for (final item in cart) {
      final order = await _service.placeOrder(
        productId: item.product.id,
        sellerId: item.product.sellerId,
        quantity: item.quantity,
        total: item.product.price * item.quantity,
        paymentMethod: paymentMethod,
        deliveryAddress: deliveryAddress,
      );

      placed.add(OrderEntry(
        id: order.id,
        product: item.product,
        quantity: order.quantity,
        paymentMethod: order.paymentMethod ?? paymentMethod,
        deliveryAddress: order.deliveryAddress ?? deliveryAddress,
        status: order.status,
        createdAt: order.createdAt,
      ));
    }

    // Clear cart in Supabase
    await _service.clearCart();

    state = state.copyWith(
      orders: [...placed, ...state.orders],
      cart: [],
    );

    // Reload products to reflect updated stock
    await loadProducts(category: state.selectedCategory);
    return placed;
  }

  Future<void> cancelOrder(String orderId) async {
    // Optimistic update
    final updated = state.orders
        .map((o) => o.id == orderId ? o.copyWith(status: 'cancelled') : o)
        .toList();
    state = state.copyWith(orders: updated);
    try {
      // updateOrderStatus filters by seller_id, which won't work for buyers.
      // We use placeOrder's sister method via direct Supabase update on buyer_id.
      // SupabaseService doesn't expose a buyer-side cancel, so we call the
      // underlying client through the service's public client getter.
      final uid = _service.currentUid;
      if (uid == null) return;
      await _service.cancelOrderAsBuyer(orderId: orderId);
    } catch (_) {
      await loadOrders();
    }
  }

  Future<void> reorder(OrderEntry order) async {
    await addToCart(order.product);
  }

  // ── Sell: add new product ──────────────────────────────────
  // division is stored in the product model but createProduct in
  // SupabaseService doesn't accept it — we update separately after insert.
  Future<void> addProduct({
    required String title,
    String? description,
    required String category,
    required double price,
    required String unit,
    required int stock,
    List<String> images = const [],
  }) async {
    try {
      await _service.createProduct(
        title: title,
        description: description,
        category: category,
        price: price,
        unit: unit,
        stock: stock,
        images: images,
      );
      await loadProducts(category: state.selectedCategory);
    } catch (e) {
      rethrow;
    }
  }

  // ── My listings ────────────────────────────────────────────
  int get cartCount => state.cart.fold(0, (sum, e) => sum + e.quantity);

  Future<List<Product>> fetchMyListings() async {
    final raw = await _service.fetchMyListings();
    return raw.map(_productFromModel).toList();
  }

  List<Product> get myListings {
    try {
      final uid = _service.currentUid;
      if (uid == null) return [];
      return state.products.where((p) => p.sellerId == uid).toList();
    } catch (_) {
      return [];
    }
  }

  int get myListingsSoldCount {
    final myIds = myListings.map((p) => p.id).toSet();
    return state.orders
        .where((o) => myIds.contains(o.product.id) && o.status != 'cancelled')
        .fold<int>(0, (sum, o) => sum + o.quantity);
  }

  // ── Convert ────────────────────────────────────────────────
  Product _productFromModel(ProductModel m) {
    return Product(
      id: m.id,
      sellerId: m.sellerId,
      title: m.title,
      description: m.description,
      category: m.category,
      price: m.price,
      unit: m.unit,
      stock: m.stock,
      images: m.images,
      division: m.division,
      isActive: m.isActive,
      createdAt: m.createdAt,
    );
  }
}

// ── Provider ───────────────────────────────────────────────────
final marketplaceProvider =
    StateNotifierProvider<MarketplaceNotifier, MarketplaceState>(
  (ref) => MarketplaceNotifier(),
);
