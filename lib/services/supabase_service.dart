import 'package:supabase_flutter/supabase_flutter.dart' hide AuthState;
import 'dart:io';

// ------------------------
// Models
// ------------------------

class AppUser {
  final String id;
  final String? email;
  final String? phone;
  final String name;
  final String role;
  final String? division;
  final String? district;
  final String langPref; // 'bn' | 'en'
  final String? avatarUrl;

  const AppUser({
    required this.id,
    this.email,
    this.phone,
    required this.name,
    required this.role,
    this.division,
    this.district,
    this.langPref = 'bn',
    this.avatarUrl,
  });

  factory AppUser.fromMap(Map<String, dynamic> profile, User authUser) {
    return AppUser(
      id: authUser.id,
      email: authUser.email,
      phone: authUser.phone,
      name: profile['name'] as String? ?? '',
      role: profile['role'] as String? ?? 'farmer',
      division: profile['division'] as String?,
      district: profile['district'] as String?,
      langPref: profile['lang_pref'] as String? ?? 'bn',
      avatarUrl: profile['avatar_url'] as String?,
    );
  }
}

class ProductModel {
  final String id;
  final String sellerId;
  final String title;
  final String? description;
  final String category;
  final double price;
  final String unit;
  final int stock;
  final List<String> images;
  final String? division;
  final bool isActive;
  final DateTime createdAt;

  const ProductModel({
    required this.id,
    required this.sellerId,
    required this.title,
    this.description,
    required this.category,
    required this.price,
    required this.unit,
    required this.stock,
    required this.images,
    this.division,
    required this.isActive,
    required this.createdAt,
  });

  factory ProductModel.fromMap(Map<String, dynamic> map) {
    return ProductModel(
      id: map['id'] as String,
      sellerId: map['seller_id'] as String,
      title: map['title'] as String,
      description: map['description'] as String?,
      category: map['category'] as String? ?? 'other',
      price: (map['price'] as num).toDouble(),
      unit: map['unit'] as String? ?? '',
      stock: map['stock'] as int? ?? 0,
      images: List<String>.from(map['images'] as List? ?? []),
      isActive: map['is_active'] as bool? ?? true,
      division: map['division'] as String?,
      createdAt: DateTime.parse(map['created_at'] as String),
    );
  }
}

class CartItemModel {
  final String id;
  final String userId;
  final String productId;
  final int quantity;
  final ProductModel? product;

  const CartItemModel({
    required this.id,
    required this.userId,
    required this.productId,
    required this.quantity,
    this.product,
  });

  factory CartItemModel.fromMap(Map<String, dynamic> map) {
    return CartItemModel(
      id: map['id'] as String,
      userId: map['user_id'] as String,
      productId: map['product_id'] as String,
      quantity: map['quantity'] as int? ?? 1,
      product: map['products'] != null
          ? ProductModel.fromMap(map['products'] as Map<String, dynamic>)
          : null,
    );
  }
}

class OrderModel {
  final String id;
  final String buyerId;
  final String sellerId;
  final String productId;
  final int quantity;
  final double total;
  final String status;
  final String? paymentMethod;
  final String? deliveryAddress;
  final String? notes;
  final DateTime? paidAt;
  final DateTime createdAt;

  const OrderModel({
    required this.id,
    required this.buyerId,
    required this.sellerId,
    required this.productId,
    required this.quantity,
    required this.total,
    required this.status,
    this.paymentMethod,
    this.deliveryAddress,
    this.notes,
    this.paidAt,
    required this.createdAt,
  });

  factory OrderModel.fromMap(Map<String, dynamic> map) {
    return OrderModel(
      id: map['id'] as String,
      buyerId: map['buyer_id'] as String,
      sellerId: map['seller_id'] as String,
      productId: map['product_id'] as String,
      quantity: map['quantity'] as int? ?? 1,
      total: (map['total'] as num).toDouble(),
      status: map['status'] as String? ?? 'pending',
      paymentMethod: map['payment_method'] as String?,
      deliveryAddress: map['delivery_address'] as String?,
      notes: map['notes'] as String?,
      paidAt: map['paid_at'] != null
          ? DateTime.parse(map['paid_at'] as String)
          : null,
      createdAt: DateTime.parse(map['created_at'] as String),
    );
  }
}

class EquipmentModel {
  final String id;
  final String ownerId;
  final String name;
  final String? description;
  final String type;
  final List<String> images;
  final double ratePerDay;
  final String? division;
  final String? locationText;
  final int minBookingDays;
  final bool available;
  final DateTime createdAt;
  final String? ownerPhone;

  const EquipmentModel({
    required this.id,
    required this.ownerId,
    required this.name,
    this.description,
    required this.type,
    required this.images,
    required this.ratePerDay,
    this.division,
    this.locationText,
    required this.minBookingDays,
    required this.available,
    required this.createdAt,
    this.ownerPhone,
  });

  factory EquipmentModel.fromMap(Map<String, dynamic> map) {
    String? ownerPhone;
    if (map['profiles'] != null) {
      ownerPhone =
          (map['profiles'] as Map<String, dynamic>)['phone'] as String?;
    }

    return EquipmentModel(
      id: map['id'] as String,
      ownerId: map['owner_id'] as String,
      name: map['name'] as String,
      description: map['description'] as String?,
      type: map['type'] as String? ?? 'other',
      images: List<String>.from(map['images'] as List? ?? []),
      ratePerDay: (map['rate_per_day'] as num).toDouble(),
      division: map['division'] as String?,
      locationText: map['location_text'] as String?,
      minBookingDays: map['min_booking_days'] as int? ?? 1,
      available: map['available'] as bool? ?? true,
      createdAt: DateTime.parse(map['created_at'] as String),
      ownerPhone: ownerPhone,
    );
  }
}

class BookingModel {
  final String id;
  final String renterId;
  final String equipmentId;
  final DateTime startDate;
  final DateTime endDate;
  final String status;
  final String paymentStatus;
  final String? paymentMethod;
  final double totalCost;
  final String? notes;
  final DateTime createdAt;
  final EquipmentModel? equipment;

  const BookingModel({
    required this.id,
    required this.renterId,
    required this.equipmentId,
    required this.startDate,
    required this.endDate,
    required this.status,
    required this.paymentStatus,
    this.paymentMethod,
    required this.totalCost,
    this.notes,
    required this.createdAt,
    this.equipment,
  });

  int get durationDays => endDate.difference(startDate).inDays + 1;

  factory BookingModel.fromMap(Map<String, dynamic> map) {
    return BookingModel(
      id: map['id'] as String,
      renterId: map['renter_id'] as String,
      equipmentId: map['equipment_id'] as String,
      startDate: DateTime.parse(map['start_date'] as String),
      endDate: DateTime.parse(map['end_date'] as String),
      status: map['status'] as String? ?? 'pending',
      paymentStatus: map['payment_status'] as String? ?? 'pending',
      paymentMethod: map['payment_method'] as String?,
      totalCost: (map['total_cost'] as num).toDouble(),
      notes: map['notes'] as String?,
      createdAt: DateTime.parse(map['created_at'] as String),
      equipment: map['equipment'] != null
          ? EquipmentModel.fromMap(map['equipment'] as Map<String, dynamic>)
          : null,
    );
  }
}
//-----------
// DOCTORS
//-----------

class DoctorModel {
  final String id;
  final String name;
  final String phone;
  final String? email;
  final String? specialization;
  final String? district;
  final String? division;
  final List<String> availableDays;
  final String? availableHours;
  final DateTime createdAt;

  const DoctorModel({
    required this.id,
    required this.name,
    required this.phone,
    this.email,
    this.specialization,
    this.district,
    this.division,
    required this.availableDays,
    this.availableHours,
    required this.createdAt,
  });

  factory DoctorModel.fromMap(Map<String, dynamic> map) {
    return DoctorModel(
      id: map['id'] as String,
      name: map['name'] as String,
      phone: map['phone'] as String,
      email: map['email'] as String?,
      specialization: map['specialization'] as String?,
      district: map['district'] as String?,
      division: map['division'] as String?,
      availableDays: List<String>.from(map['available_days'] as List? ?? []),
      availableHours: map['available_hours'] as String?,
      createdAt: DateTime.parse(map['created_at'] as String),
    );
  }
}

// ---------------------------------------------------------------------------
// SupabaseService — singleton
// ---------------------------------------------------------------------------

class SupabaseService {
  SupabaseService._();
  static final SupabaseService instance = SupabaseService._();

  // Factory constructor so callers can write SupabaseService() anywhere
  // and always get the singleton without needing to know about .instance.
  factory SupabaseService() => instance;

  SupabaseClient get _client => Supabase.instance.client;

  String get _uid {
    final id = _client.auth.currentUser?.id;
    if (id == null) throw Exception('SupabaseService: no authenticated user');
    return id;
  }

  String? get currentUid => _client.auth.currentUser?.id;

  // =========================================================================
  // AUTH
  // =========================================================================

  // --- Phone OTP ---

  Future<void> requestPhoneOtp(String phone) async {
    await _client.auth.signInWithOtp(phone: phone);
  }

  Future<AppUser?> verifyPhoneOtp(String phone, String token) async {
    final res = await _client.auth.verifyOTP(
      phone: phone,
      token: token,
      type: OtpType.sms,
    );
    if (res.user == null) throw Exception('OTP verification failed');
    return _fetchProfileOrNull(res.user!);
  }

  // --- Email OTP ---

  Future<void> requestEmailOtp(String email) async {
    await _client.auth.signInWithOtp(
      email: email,
      shouldCreateUser: true, // creates account on first send
    );
  }

  Future<AppUser?> verifyEmailOtp(String email, String token) async {
    final res = await _client.auth.verifyOTP(
      email: email,
      token: token,
      type: OtpType.email,
    );
    if (res.user == null) throw Exception('Email OTP verification failed');
    return _fetchProfileOrNull(res.user!);
  }

  // --- Session ---

  Future<void> signOut() async {
    await _client.auth.signOut();
  }

  Future<AppUser?> currentAppUser() async {
    final authUser = _client.auth.currentUser;
    if (authUser == null) return null;
    return _fetchProfileOrNull(authUser);
  }

  /// Emits AppUser? whenever auth state changes (sign-in, sign-out,
  /// token refresh). auth_provider.dart listens to this.
  Stream<AppUser?> get authStateChanges {
    return _client.auth.onAuthStateChange.asyncMap((event) async {
      final user = event.session?.user;
      if (user == null) return null;
      return _fetchProfileOrNull(user);
    });
  }

  // =========================================================================
  // PROFILE
  // =========================================================================

  Future<AppUser> createProfile({
    required String name,
    String role = 'farmer',
    String langPref = 'bn',
    String? division,
    String? district,
  }) async {
    final authUser = _client.auth.currentUser;
    if (authUser == null) {
      throw Exception('createProfile: no authenticated user');
    }

    final data = await _client
        .from('profiles')
        .upsert({
          'id': authUser.id,
          'email': authUser.email,
          'phone': authUser.phone,
          'name': name,
          'role': role,
          'lang_pref': langPref,
          'division': division,
          'district': district,
        })
        .select()
        .single();

    return AppUser.fromMap(data, authUser);
  }

  Future<AppUser> updateProfile({
    String? name,
    String? division,
    String? district,
    String? langPref,
    String? avatarUrl,
  }) async {
    final authUser = _client.auth.currentUser;
    if (authUser == null) {
      throw Exception('updateProfile: no authenticated user');
    }

    final updates = <String, dynamic>{};
    if (name != null) updates['name'] = name;
    if (division != null) updates['division'] = division;
    if (district != null) updates['district'] = district;
    if (langPref != null) updates['lang_pref'] = langPref;
    if (avatarUrl != null) updates['avatar_url'] = avatarUrl;

    if (updates.isEmpty) return _fetchProfile(authUser);

    final data = await _client
        .from('profiles')
        .update(updates)
        .eq('id', authUser.id)
        .select()
        .single();

    return AppUser.fromMap(data, authUser);
  }

  Future<AppUser> _fetchProfile(User authUser) async {
    final data =
        await _client.from('profiles').select().eq('id', authUser.id).single();
    return AppUser.fromMap(data, authUser);
  }

  Future<AppUser?> _fetchProfileOrNull(User authUser) async {
    final data = await _client
        .from('profiles')
        .select()
        .eq('id', authUser.id)
        .maybeSingle();
    if (data == null) return null;
    return AppUser.fromMap(data, authUser);
  }

  // =========================================================================
  // PRODUCTS
  // =========================================================================

  Future<List<ProductModel>> fetchProducts({
    int from = 0,
    int to = 19,
    String? category,
    String? query,
  }) async {
    var req = _client.from('products').select().eq('is_active', true);

    if (category != null) req = req.eq('category', category);
    if (query != null) req = req.ilike('title', '%$query%');

    final data =
        await req.order('created_at', ascending: false).range(from, to);

    return (data as List)
        .map((e) => ProductModel.fromMap(e as Map<String, dynamic>))
        .toList();
  }

  Future<ProductModel> fetchProductById(String id) async {
    final data = await _client.from('products').select().eq('id', id).single();
    return ProductModel.fromMap(data);
  }

  Future<List<ProductModel>> fetchMyListings() async {
    final data = await _client
        .from('products')
        .select()
        .eq('seller_id', _uid)
        .order('created_at', ascending: false);
    return (data as List)
        .map((e) => ProductModel.fromMap(e as Map<String, dynamic>))
        .toList();
  }

  Future<ProductModel> createProduct({
    required String title,
    String? description,
    required String category,
    required double price,
    required String unit,
    required int stock,
    List<String> images = const [],
  }) async {
    final data = await _client
        .from('products')
        .insert({
          'seller_id': _uid,
          'title': title,
          'description': description,
          'category': category,
          'price': price,
          'unit': unit,
          'stock': stock,
          'images': images,
          'is_active': true,
        })
        .select()
        .single();
    return ProductModel.fromMap(data);
  }

  Future<void> setProductActive(String productId,
      {required bool active}) async {
    await _client
        .from('products')
        .update({'is_active': active})
        .eq('id', productId)
        .eq('seller_id', _uid);
  }

  // =========================================================================
  // CART
  // =========================================================================

  Future<List<CartItemModel>> fetchCart() async {
    final data = await _client
        .from('cart_items')
        .select('*, products(*)')
        .eq('user_id', _uid)
        .order('added_at', ascending: false);
    return (data as List)
        .map((e) => CartItemModel.fromMap(e as Map<String, dynamic>))
        .toList();
  }

  Future<CartItemModel> addToCart({
    required String productId,
    int quantity = 1,
  }) async {
    final existing = await _client
        .from('cart_items')
        .select()
        .eq('user_id', _uid)
        .eq('product_id', productId)
        .maybeSingle();

    if (existing != null) {
      final newQty = (existing['quantity'] as int) + quantity;
      final updated = await _client
          .from('cart_items')
          .update({'quantity': newQty})
          .eq('id', existing['id'] as String)
          .select('*, products(*)')
          .single();
      return CartItemModel.fromMap(updated);
    }

    final inserted = await _client
        .from('cart_items')
        .insert({
          'user_id': _uid,
          'product_id': productId,
          'quantity': quantity,
        })
        .select('*, products(*)')
        .single();
    return CartItemModel.fromMap(inserted);
  }

  Future<void> updateCartQuantity({
    required String cartItemId,
    required int quantity,
  }) async {
    if (quantity <= 0) {
      await removeFromCart(cartItemId);
      return;
    }
    await _client
        .from('cart_items')
        .update({'quantity': quantity})
        .eq('id', cartItemId)
        .eq('user_id', _uid);
  }

  Future<void> removeFromCart(String cartItemId) async {
    await _client
        .from('cart_items')
        .delete()
        .eq('id', cartItemId)
        .eq('user_id', _uid);
  }

  Future<void> clearCart() async {
    await _client.from('cart_items').delete().eq('user_id', _uid);
  }

  // =========================================================================
  // ORDERS
  // =========================================================================

  Future<OrderModel> placeOrder({
    required String productId,
    required String sellerId,
    required int quantity,
    required double total,
    String? notes,
    String? paymentMethod,
    String? deliveryAddress,
    String? transactionId, // ADD THIS
  }) async {
    final data = await _client
        .from('orders')
        .insert({
          'buyer_id': _uid,
          'seller_id': sellerId,
          'product_id': productId,
          'quantity': quantity,
          'total': total,
          'status': 'pending',
          'notes': notes,
          'payment_method': paymentMethod,
          'delivery_address': deliveryAddress,
          'transaction_id': transactionId, // ADD THIS
          if (transactionId != null)
            'paid_at': DateTime.now().toIso8601String(), // ADD THIS
        })
        .select()
        .single();
    return OrderModel.fromMap(data);
  }

  Future<List<OrderModel>> placeOrdersFromCart() async {
    final cartItems = await fetchCart();
    if (cartItems.isEmpty) throw Exception('Cart is empty');

    final orders = <OrderModel>[];
    for (final item in cartItems) {
      final product = item.product;
      if (product == null) {
        throw Exception('Cart item ${item.id} has no product data');
      }
      final order = await placeOrder(
        productId: item.productId,
        sellerId: product.sellerId,
        quantity: item.quantity,
        total: product.price * item.quantity,
      );
      orders.add(order);
    }

    await clearCart();
    return orders;
  }

  Future<List<OrderModel>> fetchMyOrders() async {
    final data = await _client
        .from('orders')
        .select()
        .eq('buyer_id', _uid)
        .order('created_at', ascending: false);
    return (data as List)
        .map((e) => OrderModel.fromMap(e as Map<String, dynamic>))
        .toList();
  }

  Future<List<OrderModel>> fetchMySales() async {
    final data = await _client
        .from('orders')
        .select()
        .eq('seller_id', _uid)
        .order('created_at', ascending: false);
    return (data as List)
        .map((e) => OrderModel.fromMap(e as Map<String, dynamic>))
        .toList();
  }

  Future<void> updateOrderStatus({
    required String orderId,
    required String status,
  }) async {
    await _client
        .from('orders')
        .update({'status': status})
        .eq('id', orderId)
        .eq('seller_id', _uid);
  }

  Future<void> cancelOrderAsBuyer({required String orderId}) async {
    await _client
        .from('orders')
        .update({'status': 'cancelled'})
        .eq('id', orderId)
        .eq('buyer_id', _uid);
  }

  // =========================================================================
  // EQUIPMENT (RENTALS — OWNER SIDE)
  // =========================================================================

  Future<List<EquipmentModel>> fetchMyEquipmentListings() async {
    final data = await _client
        .from('equipment')
        .select()
        .eq('owner_id', _uid)
        .order('created_at', ascending: false);
    return (data as List)
        .map((e) => EquipmentModel.fromMap(e as Map<String, dynamic>))
        .toList();
  }

  Future<EquipmentModel> createEquipment({
    required String name,
    String? description,
    required String type,
    required double ratePerDay,
    required int minBookingDays,
    String? division,
    String? locationText,
    List<String> images = const [],
  }) async {
    final data = await _client
        .from('equipment')
        .insert({
          'owner_id': _uid,
          'name': name,
          'description': description,
          'type': type,
          'rate_per_day': ratePerDay,
          'min_booking_days': minBookingDays,
          'division': division,
          'location_text': locationText,
          'images': images,
          'available': true,
        })
        .select()
        .single();
    return EquipmentModel.fromMap(data);
  }

  Future<EquipmentModel> updateEquipment({
    required String equipmentId,
    String? name,
    String? description,
    double? ratePerDay,
    int? minBookingDays,
    String? division,
    String? locationText,
    List<String>? images,
  }) async {
    final updates = <String, dynamic>{};
    if (name != null) updates['name'] = name;
    if (description != null) updates['description'] = description;
    if (ratePerDay != null) updates['rate_per_day'] = ratePerDay;
    if (minBookingDays != null) updates['min_booking_days'] = minBookingDays;
    if (division != null) updates['division'] = division;
    if (locationText != null) updates['location_text'] = locationText;
    if (images != null) updates['images'] = images;

    final data = await _client
        .from('equipment')
        .update(updates)
        .eq('id', equipmentId)
        .eq('owner_id', _uid)
        .select()
        .single();
    return EquipmentModel.fromMap(data);
  }

  Future<void> setEquipmentAvailable(String equipmentId,
      {required bool available}) async {
    await _client
        .from('equipment')
        .update({'available': available})
        .eq('id', equipmentId)
        .eq('owner_id', _uid);
  }

  Future<void> deleteEquipment(String equipmentId) async {
    await _client
        .from('equipment')
        .delete()
        .eq('id', equipmentId)
        .eq('owner_id', _uid);
  }

  Future<String> uploadEquipmentImage(String localPath) async {
    final file = File(localPath);
    final ext = localPath.split('.').last.toLowerCase();
    final fileName = '$_uid/${DateTime.now().millisecondsSinceEpoch}.$ext';

    await _client.storage.from('equipment-images').upload(
          fileName,
          file,
          fileOptions: FileOptions(contentType: 'image/$ext'),
        );

    return _client.storage.from('equipment-images').getPublicUrl(fileName);
  }

  Future<String> uploadEquipmentImageBytes(List<int> bytes, String ext) async {
    final fileName = '$_uid/${DateTime.now().millisecondsSinceEpoch}.$ext';

    await _client.storage.from('equipment-images').uploadBinary(
          fileName,
          bytes as dynamic,
          fileOptions: FileOptions(contentType: 'image/$ext'),
        );

    return _client.storage.from('equipment-images').getPublicUrl(fileName);
  }

  Future<String> uploadProductImage(List<int> bytes, String ext) async {
    final fileName = '$_uid/${DateTime.now().millisecondsSinceEpoch}.$ext';

    await _client.storage.from('product-images').uploadBinary(
          fileName,
          bytes as dynamic,
          fileOptions: FileOptions(contentType: 'image/$ext'),
        );

    return _client.storage.from('product-images').getPublicUrl(fileName);
  }

  // =========================================================================
  // EQUIPMENT (RENTALS — RENTER / BROWSE SIDE)
  // =========================================================================

  Future<List<EquipmentModel>> fetchEquipment({
    int from = 0,
    int to = 19,
    String? division,
    String? type,
  }) async {
    var req = _client.from('equipment').select().eq('available', true);

    if (division != null) req = req.eq('division', division);
    if (type != null) req = req.eq('type', type);

    final data =
        await req.order('created_at', ascending: false).range(from, to);

    return (data as List)
        .map((e) => EquipmentModel.fromMap(e as Map<String, dynamic>))
        .toList();
  }

  Future<EquipmentModel> fetchEquipmentById(String id) async {
    final data = await _client.from('equipment').select().eq('id', id).single();
    return EquipmentModel.fromMap(data);
  }

  // =========================================================================
  // BOOKINGS
  // =========================================================================

  Future<BookingModel> placeBooking({
    required String equipmentId,
    required double ratePerDay,
    required DateTime startDate,
    required DateTime endDate,
    String? notes,
    String? paymentMethod,
    String? transactionId,
  }) async {
    final days = endDate.difference(startDate).inDays + 1;
    if (days < 1) throw Exception('endDate must be on or after startDate');

    final totalCost = ratePerDay * days;

    String fmt(DateTime d) => '${d.year.toString().padLeft(4, '0')}-'
        '${d.month.toString().padLeft(2, '0')}-'
        '${d.day.toString().padLeft(2, '0')}';

    final data = await _client
        .from('bookings')
        .insert({
          'renter_id': _uid,
          'equipment_id': equipmentId,
          'start_date': fmt(startDate),
          'end_date': fmt(endDate),
          'status': 'pending',
          'payment_status': transactionId != null ? 'paid' : 'pending',
          'payment_method': paymentMethod,
          'total_cost': totalCost,
          'notes': notes,
          'transaction_id': transactionId,
        })
        .select()
        .single();
    return BookingModel.fromMap(data);
  }

  Future<BookingModel> fetchBookingById(String bookingId) async {
    final data = await _client
        .from('bookings')
        .select('*, equipment(*, profiles(phone))')
        .eq('id', bookingId)
        .single();
    return BookingModel.fromMap(data);
  }

  Future<List<BookingModel>> fetchEquipmentBookings(String equipmentId) async {
    final data = await _client
        .from('bookings')
        .select()
        .eq('equipment_id', equipmentId)
        .not('status', 'in', '("cancelled","completed")')
        .order('start_date', ascending: true);

    return (data as List)
        .map((e) => BookingModel.fromMap(e as Map<String, dynamic>))
        .toList();
  }

  Future<List<BookingModel>> fetchMyBookings() async {
    final data = await _client
        .from('bookings')
        .select('*, equipment(*, profiles(phone))')
        .eq('renter_id', _uid)
        .order('created_at', ascending: false);
    return (data as List)
        .map((e) => BookingModel.fromMap(e as Map<String, dynamic>))
        .toList();
  }

  Future<List<BookingModel>> fetchBookingHistory() async {
    final data = await _client
        .from('bookings')
        .select('*, equipment(*)')
        .eq('renter_id', _uid)
        .eq('status', 'completed')
        .order('created_at', ascending: false);
    return (data as List)
        .map((e) => BookingModel.fromMap(e as Map<String, dynamic>))
        .toList();
  }

  Future<List<BookingModel>> fetchBookingsForMyEquipment() async {
    final equipmentRows =
        await _client.from('equipment').select('id').eq('owner_id', _uid);

    final ids = (equipmentRows as List).map((e) => e['id'] as String).toList();

    if (ids.isEmpty) return [];

    final data = await _client
        .from('bookings')
        .select('*, equipment(*, profiles(phone))')
        .inFilter('equipment_id', ids)
        .order('created_at', ascending: false);

    return (data as List)
        .map((e) => BookingModel.fromMap(e as Map<String, dynamic>))
        .toList();
  }

  Future<void> updateBookingStatus({
    required String bookingId,
    required String status,
    bool actingAsOwner = false,
  }) async {
    if (actingAsOwner) {
      await _client
          .from('bookings')
          .update({'status': status}).eq('id', bookingId);
    } else {
      await _client
          .from('bookings')
          .update({'status': status})
          .eq('id', bookingId)
          .eq('renter_id', _uid);
    }
  }

  Future<void> cancelBooking(String bookingId,
      {required bool actingAsOwner}) async {
    await updateBookingStatus(
      bookingId: bookingId,
      status: 'cancelled',
      actingAsOwner: actingAsOwner,
    );
  }

  Future<void> markBookingPaid({
    required String bookingId,
    required String paymentMethod,
  }) async {
    await _client
        .from('bookings')
        .update({
          'payment_status': 'paid',
          'payment_method': paymentMethod,
        })
        .eq('id', bookingId)
        .eq('renter_id', _uid);
  }

// ------------------------
// DOCTOR
// ------------------------

  Future<List<DoctorModel>> fetchDoctors({
    int from = 0,
    int to = 19,
    String? division,
    String? specialization,
  }) async {
    var req = _client.from('doctors').select();

    if (division != null) req = req.eq('division', division);
    if (specialization != null) {
      req = req.ilike('specialization', '%$specialization%');
    }

    final data = await req.order('name', ascending: true).range(from, to);

    return (data as List)
        .map((e) => DoctorModel.fromMap(e as Map<String, dynamic>))
        .toList();
  }

  Future<DoctorModel> fetchDoctorById(String id) async {
    final data = await _client.from('doctors').select().eq('id', id).single();
    return DoctorModel.fromMap(data);
  }
}
