import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:image_picker/image_picker.dart';
import 'package:intl/intl.dart';

import '../../core/router.dart';
import '../../core/theme.dart';
import '../../providers/auth_provider.dart';
import '../../providers/marketplace_provider.dart';
import '../../providers/lang_provider.dart';
import '../../models/product.dart';
import '../../models/rental.dart';
import '../../services/supabase_service.dart';

String _t(bool bn, String bangla, String english) => bn ? bangla : english;

class ProfileScreen extends ConsumerStatefulWidget {
  const ProfileScreen({super.key});

  @override
  ConsumerState<ProfileScreen> createState() => _ProfileScreenState();
}

class _ProfileScreenState extends ConsumerState<ProfileScreen> {
  static const int _currentTabIndex = 3;
  List<Product> _myListings = [];
  List<BookingModel> _myBookings = [];
  int _soldCount = 0;
  final Set<String> _dismissedOrderIds = {};
  bool _isUploadingAvatar = false;

  @override
  void initState() {
    super.initState();
    Future.microtask(() async {
      final notifier = ref.read(marketplaceProvider.notifier);
      await notifier.loadOrders();

      final results = await Future.wait([
        notifier.fetchMyListings(),
        SupabaseService.instance.fetchMyBookings(),
      ]);

      if (mounted) {
        setState(() {
          _myListings = results[0] as List<Product>;
          _myBookings = results[1] as List<BookingModel>;
          _soldCount = notifier.myListingsSoldCount;
        });
      }
    });
  }

  void _onTabTapped(int index) {
    if (index == _currentTabIndex) return;
    switch (index) {
      case 0:
        Navigator.pushReplacementNamed(context, AppRouter.home);
        break;
      case 1:
        Navigator.pushReplacementNamed(context, AppRouter.market);
        break;
      case 2:
        Navigator.pushReplacementNamed(context, AppRouter.services);
        break;
    }
  }

  Future<void> _pickAndUploadAvatar(bool bn) async {
    final source = await showModalBottomSheet<ImageSource>(
      context: context,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (_) => SafeArea(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const SizedBox(height: 8),
            Container(
              width: 40,
              height: 4,
              decoration: BoxDecoration(
                color: Colors.grey.shade300,
                borderRadius: BorderRadius.circular(2),
              ),
            ),
            const SizedBox(height: 16),
            ListTile(
              leading: const Icon(Icons.camera_alt_outlined,
                  color: AppTheme.primaryGreen),
              title: Text(_t(bn, 'ক্যামেরা', 'Camera')),
              onTap: () => Navigator.pop(context, ImageSource.camera),
            ),
            ListTile(
              leading: const Icon(Icons.photo_library_outlined,
                  color: AppTheme.primaryGreen),
              title: Text(_t(bn, 'গ্যালারি', 'Gallery')),
              onTap: () => Navigator.pop(context, ImageSource.gallery),
            ),
            const SizedBox(height: 8),
          ],
        ),
      ),
    );

    if (source == null || !mounted) return;

    try {
      final picker = ImagePicker();
      final picked = await picker.pickImage(source: source, imageQuality: 80);
      if (picked == null || !mounted) return;

      setState(() => _isUploadingAvatar = true);

      final bytes = await picked.readAsBytes();
      final ext = picked.name.split('.').last.toLowerCase();
      final url = await SupabaseService.instance.uploadAvatarImage(bytes, ext);

      await SupabaseService.instance.updateProfile(avatarUrl: url);
      await ref.read(authProvider.notifier).refresh();

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(
          content: Text(
              _t(bn, 'প্রোফাইল ছবি আপডেট হয়েছে', 'Profile photo updated')),
          backgroundColor: AppTheme.primaryGreen,
          behavior: SnackBarBehavior.floating,
        ));
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(
          content:
              Text(_t(bn, 'ছবি আপলোড করা যায়নি', 'Could not upload photo')),
          backgroundColor: Colors.red,
          behavior: SnackBarBehavior.floating,
        ));
      }
    } finally {
      if (mounted) setState(() => _isUploadingAvatar = false);
    }
  }

  // ---------------------------------------------------------------------------
  // Booking helpers
  // ---------------------------------------------------------------------------

  int get _activeBookingsCount => _myBookings.where((b) {
        final s = BookingStatus.fromValue(b.status);
        return s != BookingStatus.cancelled && s != BookingStatus.completed;
      }).length;

  Color _bookingStatusColor(String status) {
    switch (BookingStatus.fromValue(status)) {
      case BookingStatus.pending:
        return Colors.orange;
      case BookingStatus.confirmed:
        return const Color(0xFF3B82F6);
      case BookingStatus.active:
        return AppTheme.primaryGreen;
      case BookingStatus.completed:
        return Colors.grey;
      case BookingStatus.cancelled:
        return Colors.red;
    }
  }

  String _bookingStatusLabel(String status, bool bn) {
    final s = BookingStatus.fromValue(status);
    return bn ? s.labelBn : s.labelEn;
  }

  String _paymentStatusLabel(String status, bool bn) {
    final s = PaymentStatus.fromValue(status);
    return bn ? s.labelBn : s.labelEn;
  }

  // ---------------------------------------------------------------------------

  @override
  Widget build(BuildContext context) {
    final bn = ref.watch(langProvider);

    final user = ref.watch(currentUserProvider);
    final name = user?.name ?? 'কৃষক';
    final phone = user?.phone ?? '';
    final email = user?.email ?? '';
    final division = user?.division ?? '';
    final avatarUrl = user?.avatarUrl ?? '';

    final marketState = ref.watch(marketplaceProvider);
    final notifier = ref.read(marketplaceProvider.notifier);
    final visibleOrders = marketState.orders
        .where((o) => !_dismissedOrderIds.contains(o.id))
        .toList();
    final totalOrders =
        visibleOrders.where((o) => o.status != 'cancelled').length;
    final activeOrders = visibleOrders
        .where((o) => o.status != 'delivered' && o.status != 'cancelled')
        .length;

    return Scaffold(
      backgroundColor: const Color(0xFFF5F7F5),
      body: CustomScrollView(
        slivers: [
          _buildSliverHeader(
            name: name,
            division: division,
            avatarUrl: avatarUrl,
            bn: bn,
          ),
          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                children: [
                  _buildStatsRow(
                      totalOrders, activeOrders, _myListings.length, bn),
                  const SizedBox(height: 20),
                  _buildMenuSection(
                    title: bn ? 'কেনাকাটা' : 'Shopping',
                    items: [
                      _MenuItem(
                        icon: Icons.receipt_long_outlined,
                        iconColor: const Color(0xFF3B82F6),
                        label: bn ? 'আমার অর্ডার' : 'My Orders',
                        trailing:
                            activeOrders > 0 ? _Badge('$activeOrders') : null,
                        onTap: () =>
                            Navigator.pushNamed(context, AppRouter.orders),
                      ),
                      _MenuItem(
                        icon: Icons.agriculture_outlined,
                        iconColor: const Color(0xFF16A34A),
                        label: bn ? 'আমার বুকিং' : 'My Bookings',
                        sublabel: _myBookings.isEmpty
                            ? (bn ? 'কোনো বুকিং নেই' : 'No bookings')
                            : '${_myBookings.length}${bn ? 'টি বুকিং' : ' bookings'}'
                                '${_activeBookingsCount > 0 ? ' · $_activeBookingsCount ${bn ? "টি সক্রিয়" : "active"}' : ''}',
                        trailing: _activeBookingsCount > 0
                            ? _Badge('$_activeBookingsCount')
                            : null,
                        onTap: () => _showMyBookings(context, _myBookings, bn),
                      ),
                      _MenuItem(
                        icon: Icons.shopping_cart_outlined,
                        iconColor: const Color(0xFFF59E0B),
                        label: bn ? 'কার্ট' : 'Cart',
                        trailing: notifier.cartCount > 0
                            ? _Badge('${notifier.cartCount}')
                            : null,
                        onTap: () =>
                            Navigator.pushNamed(context, AppRouter.cart),
                      ),
                    ],
                  ),
                  const SizedBox(height: 14),
                  _buildMenuSection(
                    title: bn ? 'বিক্রয়' : 'Sales',
                    items: [
                      _MenuItem(
                        icon: Icons.storefront_outlined,
                        iconColor: AppTheme.primaryGreen,
                        label: bn ? 'আমার পণ্য তালিকা' : 'My Listings',
                        sublabel: _myListings.isEmpty
                            ? (bn ? 'কোনো পণ্য নেই' : 'No products')
                            : '${_myListings.length}${bn ? 'টি পণ্য' : ' products'} · $_soldCount ${bn ? 'টি বিক্রিত' : 'sold'}',
                        onTap: () => _showMyListings(
                            context, _myListings, _soldCount, bn),
                      ),
                      _MenuItem(
                        icon: Icons.add_box_outlined,
                        iconColor: const Color(0xFF8B5CF6),
                        label: bn ? 'নতুন পণ্য যোগ করুন' : 'Add New Product',
                        onTap: () =>
                            Navigator.pushNamed(context, AppRouter.sellProduct),
                      ),
                    ],
                  ),
                  const SizedBox(height: 14),
                  _buildMenuSection(
                    title: bn ? 'প্রোফাইল' : 'Profile',
                    items: [
                      _MenuItem(
                        icon: Icons.person_outline_rounded,
                        iconColor: const Color(0xFF06B6D4),
                        label: bn ? 'প্রোফাইল সম্পাদনা' : 'Edit Profile',
                        onTap: () => _showEditProfile(
                          context,
                          name: name,
                          phone: phone,
                          email: email,
                          division: division,
                          bn: bn,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 14),
                  _buildMenuSection(
                    title: '',
                    items: [
                      _MenuItem(
                        icon: Icons.logout_rounded,
                        iconColor: const Color(0xFFEF4444),
                        label: bn ? 'লগআউট' : 'Logout',
                        labelColor: const Color(0xFFEF4444),
                        onTap: () => _confirmLogout(context, bn),
                      ),
                    ],
                  ),
                  const SizedBox(height: 100),
                ],
              ),
            ),
          ),
        ],
      ),
      bottomNavigationBar: _buildFloatingNav(bn),
    );
  }

  // ---------------------------------------------------------------------------
  // My Bookings sheet
  // ---------------------------------------------------------------------------

  void _showMyBookings(
      BuildContext context, List<BookingModel> bookings, bool bn) {
    final dateFmt = DateFormat('d MMM yyyy');
    final currFmt =
        NumberFormat.currency(locale: 'en_BD', symbol: '৳', decimalDigits: 0);

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => DraggableScrollableSheet(
        initialChildSize: 0.75,
        maxChildSize: 0.95,
        minChildSize: 0.4,
        builder: (_, controller) => Container(
          decoration: const BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
          ),
          child: Column(
            children: [
              const SizedBox(height: 12),
              Container(
                width: 40,
                height: 4,
                decoration: BoxDecoration(
                  color: Colors.grey.shade300,
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
              Padding(
                padding: const EdgeInsets.fromLTRB(16, 12, 16, 12),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      bn ? 'আমার বুকিং' : 'My Bookings',
                      style: const TextStyle(
                          fontSize: 17, fontWeight: FontWeight.bold),
                    ),
                    Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 10, vertical: 4),
                      decoration: BoxDecoration(
                        color: AppTheme.primaryGreen.withValues(alpha: 0.1),
                        borderRadius: BorderRadius.circular(10),
                      ),
                      child: Text(
                        '${bookings.length} ${bn ? "টি" : "total"}',
                        style: const TextStyle(
                          color: AppTheme.primaryGreen,
                          fontSize: 12,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              Divider(height: 1, color: Colors.grey.shade200),
              Expanded(
                child: bookings.isEmpty
                    ? Center(
                        child: Column(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Icon(Icons.agriculture_outlined,
                                size: 56, color: Colors.grey.shade300),
                            const SizedBox(height: 12),
                            Text(
                              bn ? 'এখনো কোনো বুকিং করেননি' : 'No bookings yet',
                              style: TextStyle(
                                  color: Colors.grey.shade500, fontSize: 15),
                            ),
                          ],
                        ),
                      )
                    : ListView.separated(
                        controller: controller,
                        padding: const EdgeInsets.all(16),
                        itemCount: bookings.length,
                        separatorBuilder: (_, __) => const SizedBox(height: 10),
                        itemBuilder: (_, i) {
                          final b = bookings[i];
                          final eq = b.equipment;
                          final statusColor = _bookingStatusColor(b.status);
                          final paymentPaid =
                              PaymentStatus.fromValue(b.paymentStatus) ==
                                  PaymentStatus.paid;

                          return Container(
                            padding: const EdgeInsets.all(14),
                            decoration: BoxDecoration(
                              color: Colors.grey.shade50,
                              borderRadius: BorderRadius.circular(12),
                              border: Border.all(color: Colors.grey.shade200),
                            ),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                // Header: icon + name + status badge
                                Row(
                                  children: [
                                    Container(
                                      padding: const EdgeInsets.all(8),
                                      decoration: BoxDecoration(
                                        color: AppTheme.primaryGreen
                                            .withValues(alpha: 0.1),
                                        borderRadius: BorderRadius.circular(8),
                                      ),
                                      child: const Icon(
                                        Icons.agriculture,
                                        color: AppTheme.primaryGreen,
                                        size: 18,
                                      ),
                                    ),
                                    const SizedBox(width: 10),
                                    Expanded(
                                      child: Text(
                                        eq?.name ??
                                            (bn ? 'সরঞ্জাম' : 'Equipment'),
                                        style: const TextStyle(
                                          fontSize: 14,
                                          fontWeight: FontWeight.w700,
                                        ),
                                        maxLines: 1,
                                        overflow: TextOverflow.ellipsis,
                                      ),
                                    ),
                                    const SizedBox(width: 8),
                                    Container(
                                      padding: const EdgeInsets.symmetric(
                                          horizontal: 8, vertical: 3),
                                      decoration: BoxDecoration(
                                        color:
                                            statusColor.withValues(alpha: 0.1),
                                        borderRadius: BorderRadius.circular(6),
                                        border: Border.all(
                                            color: statusColor.withValues(
                                                alpha: 0.35)),
                                      ),
                                      child: Text(
                                        _bookingStatusLabel(b.status, bn),
                                        style: TextStyle(
                                          fontSize: 11,
                                          fontWeight: FontWeight.w700,
                                          color: statusColor,
                                        ),
                                      ),
                                    ),
                                  ],
                                ),

                                const SizedBox(height: 10),
                                Divider(height: 1, color: Colors.grey.shade200),
                                const SizedBox(height: 10),

                                // Dates row
                                Row(
                                  children: [
                                    const Icon(Icons.calendar_month,
                                        size: 14,
                                        color: AppTheme.textSecondary),
                                    const SizedBox(width: 6),
                                    Text(
                                      '${dateFmt.format(b.startDate)}  →  ${dateFmt.format(b.endDate)}',
                                      style: const TextStyle(
                                        fontSize: 12,
                                        fontWeight: FontWeight.w600,
                                        color: AppTheme.textPrimary,
                                      ),
                                    ),
                                    const Spacer(),
                                    Text(
                                      '${b.durationDays} ${bn ? "দিন" : "days"}',
                                      style: const TextStyle(
                                        fontSize: 12,
                                        color: AppTheme.textSecondary,
                                      ),
                                    ),
                                  ],
                                ),

                                const SizedBox(height: 8),

                                // Cost + payment row
                                Row(
                                  children: [
                                    const Icon(Icons.payments_outlined,
                                        size: 14,
                                        color: AppTheme.textSecondary),
                                    const SizedBox(width: 6),
                                    Text(
                                      currFmt.format(b.totalCost),
                                      style: const TextStyle(
                                        fontSize: 13,
                                        fontWeight: FontWeight.w700,
                                        color: AppTheme.primaryGreen,
                                      ),
                                    ),
                                    const Spacer(),
                                    // Payment method chip
                                    if (b.paymentMethod != null)
                                      Container(
                                        padding: const EdgeInsets.symmetric(
                                            horizontal: 7, vertical: 2),
                                        decoration: BoxDecoration(
                                          color: const Color(0xFFE2136E)
                                              .withValues(alpha: 0.08),
                                          borderRadius:
                                              BorderRadius.circular(5),
                                        ),
                                        child: Text(
                                          b.paymentMethod == 'bkash'
                                              ? 'bKash'
                                              : (bn ? 'নগদ' : 'Cash'),
                                          style: TextStyle(
                                            fontSize: 10,
                                            fontWeight: FontWeight.w600,
                                            color: b.paymentMethod == 'bkash'
                                                ? const Color(0xFFE2136E)
                                                : const Color(0xFF2E7D32),
                                          ),
                                        ),
                                      ),
                                    const SizedBox(width: 6),
                                    // Paid/unpaid badge
                                    Container(
                                      padding: const EdgeInsets.symmetric(
                                          horizontal: 7, vertical: 2),
                                      decoration: BoxDecoration(
                                        color: paymentPaid
                                            ? AppTheme.primaryGreen
                                                .withValues(alpha: 0.1)
                                            : Colors.orange
                                                .withValues(alpha: 0.1),
                                        borderRadius: BorderRadius.circular(5),
                                      ),
                                      child: Text(
                                        _paymentStatusLabel(
                                            b.paymentStatus, bn),
                                        style: TextStyle(
                                          fontSize: 10,
                                          fontWeight: FontWeight.w600,
                                          color: paymentPaid
                                              ? AppTheme.primaryGreen
                                              : Colors.orange,
                                        ),
                                      ),
                                    ),
                                  ],
                                ),

                                // Location (if available)
                                if (eq?.locationText != null ||
                                    eq?.division != null) ...[
                                  const SizedBox(height: 8),
                                  Row(
                                    children: [
                                      const Icon(Icons.location_on,
                                          size: 13,
                                          color: AppTheme.textSecondary),
                                      const SizedBox(width: 5),
                                      Expanded(
                                        child: Text(
                                          [eq?.locationText, eq?.division]
                                              .whereType<String>()
                                              .join(', '),
                                          style: const TextStyle(
                                            fontSize: 12,
                                            color: AppTheme.textSecondary,
                                          ),
                                          maxLines: 1,
                                          overflow: TextOverflow.ellipsis,
                                        ),
                                      ),
                                    ],
                                  ),
                                ],

                                // Notes (if any)
                                if (b.notes != null && b.notes!.isNotEmpty) ...[
                                  const SizedBox(height: 8),
                                  Row(
                                    crossAxisAlignment:
                                        CrossAxisAlignment.start,
                                    children: [
                                      const Icon(Icons.notes,
                                          size: 13,
                                          color: AppTheme.textSecondary),
                                      const SizedBox(width: 5),
                                      Expanded(
                                        child: Text(
                                          b.notes!,
                                          style: const TextStyle(
                                            fontSize: 12,
                                            color: AppTheme.textSecondary,
                                          ),
                                          maxLines: 2,
                                          overflow: TextOverflow.ellipsis,
                                        ),
                                      ),
                                    ],
                                  ),
                                ],
                              ],
                            ),
                          );
                        },
                      ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  // ---------------------------------------------------------------------------
  // Sliver header
  // ---------------------------------------------------------------------------

  Widget _buildSliverHeader({
    required String name,
    required String division,
    required String avatarUrl,
    required bool bn,
  }) {
    return SliverAppBar(
      expandedHeight: 220,
      pinned: true,
      backgroundColor: AppTheme.primaryGreen,
      foregroundColor: Colors.white,
      automaticallyImplyLeading: false,
      flexibleSpace: FlexibleSpaceBar(
        background: Container(
          decoration: const BoxDecoration(
            gradient: LinearGradient(
              colors: [AppTheme.primaryGreen, Color(0xFF1B5E20)],
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
            ),
          ),
          child: SafeArea(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                const SizedBox(height: 10),
                GestureDetector(
                  onTap: () => _pickAndUploadAvatar(bn),
                  child: Stack(
                    children: [
                      CircleAvatar(
                        radius: 44,
                        backgroundColor: Colors.white.withValues(alpha: 0.2),
                        backgroundImage: avatarUrl.isNotEmpty
                            ? NetworkImage(avatarUrl)
                            : null,
                        child: _isUploadingAvatar
                            ? const SizedBox(
                                width: 28,
                                height: 28,
                                child: CircularProgressIndicator(
                                    color: Colors.white, strokeWidth: 2.5),
                              )
                            : avatarUrl.isEmpty
                                ? const Icon(Icons.person,
                                    size: 44, color: Colors.white70)
                                : null,
                      ),
                      Positioned(
                        bottom: 0,
                        right: 0,
                        child: Container(
                          padding: const EdgeInsets.all(5),
                          decoration: BoxDecoration(
                            color: _isUploadingAvatar
                                ? Colors.grey.shade300
                                : Colors.white,
                            shape: BoxShape.circle,
                            boxShadow: [
                              BoxShadow(
                                color: Colors.black.withValues(alpha: 0.15),
                                blurRadius: 4,
                              ),
                            ],
                          ),
                          child: Icon(
                            _isUploadingAvatar
                                ? Icons.hourglass_empty_rounded
                                : Icons.camera_alt,
                            size: 14,
                            color: AppTheme.primaryGreen,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 12),
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 32),
                  child: Text(name,
                      style: const TextStyle(
                          color: Colors.white,
                          fontSize: 20,
                          fontWeight: FontWeight.bold),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      textAlign: TextAlign.center),
                ),
                const SizedBox(height: 4),
                if (division.isNotEmpty)
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 24),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        const Icon(Icons.location_on,
                            color: Colors.white70, size: 14),
                        const SizedBox(width: 3),
                        Flexible(
                          child: Text(division,
                              style: const TextStyle(
                                  color: Colors.white70, fontSize: 13),
                              overflow: TextOverflow.ellipsis),
                        ),
                      ],
                    ),
                  ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  // ---------------------------------------------------------------------------
  // Stats row
  // ---------------------------------------------------------------------------

  Widget _buildStatsRow(
      int totalOrders, int activeOrders, int listings, bool bn) {
    return IntrinsicHeight(
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          _StatCard(
              value: '$totalOrders',
              label: bn ? 'মোট অর্ডার' : 'Total Orders',
              icon: Icons.receipt_long_outlined,
              color: const Color(0xFF3B82F6)),
          const SizedBox(width: 10),
          _StatCard(
              value: '$activeOrders',
              label: bn ? 'চলমান' : 'Active',
              icon: Icons.local_shipping_outlined,
              color: const Color(0xFFF59E0B)),
          const SizedBox(width: 10),
          _StatCard(
              value: '$listings',
              label: bn ? 'আমার পণ্য' : 'My Products',
              icon: Icons.storefront_outlined,
              color: AppTheme.primaryGreen),
        ],
      ),
    );
  }

  // ---------------------------------------------------------------------------
  // Menu section
  // ---------------------------------------------------------------------------

  Widget _buildMenuSection(
      {required String title, required List<_MenuItem> items}) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
              color: Colors.black.withValues(alpha: 0.04),
              blurRadius: 8,
              offset: const Offset(0, 2)),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          if (title.isNotEmpty)
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 14, 16, 4),
              child: Text(title,
                  style: TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.w600,
                      color: Colors.grey.shade500,
                      letterSpacing: 0.5)),
            ),
          ...items.asMap().entries.map((e) {
            final isLast = e.key == items.length - 1;
            return Column(
              children: [
                _buildMenuItem(e.value),
                if (!isLast)
                  Divider(height: 1, indent: 56, color: Colors.grey.shade100),
              ],
            );
          }),
        ],
      ),
    );
  }

  Widget _buildMenuItem(_MenuItem item) {
    return InkWell(
      onTap: item.onTap,
      borderRadius: BorderRadius.circular(16),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 13),
        child: Row(
          children: [
            Container(
              width: 36,
              height: 36,
              decoration: BoxDecoration(
                  color: item.iconColor.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(10)),
              child: Icon(item.icon, color: item.iconColor, size: 18),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(item.label,
                      style: TextStyle(
                          fontSize: 14,
                          fontWeight: FontWeight.w500,
                          color: item.labelColor ?? const Color(0xFF1A1A1A))),
                  if (item.sublabel != null)
                    Text(item.sublabel!,
                        style: TextStyle(
                            fontSize: 12, color: Colors.grey.shade500)),
                ],
              ),
            ),
            if (item.trailing != null) item.trailing!,
            if (item.trailing == null && item.onTap != null)
              Icon(Icons.chevron_right, color: Colors.grey.shade400, size: 20),
          ],
        ),
      ),
    );
  }

  // ---------------------------------------------------------------------------
  // My Listings sheet (unchanged)
  // ---------------------------------------------------------------------------

  void _showMyListings(
      BuildContext context, List<dynamic> listings, int soldCount, bool bn) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => DraggableScrollableSheet(
        initialChildSize: 0.7,
        maxChildSize: 0.95,
        minChildSize: 0.4,
        builder: (_, controller) => Container(
          decoration: const BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.vertical(top: Radius.circular(20))),
          child: Column(
            children: [
              const SizedBox(height: 12),
              Container(
                width: 40,
                height: 4,
                decoration: BoxDecoration(
                    color: Colors.grey.shade300,
                    borderRadius: BorderRadius.circular(2)),
              ),
              Padding(
                padding: const EdgeInsets.all(16),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(bn ? 'আমার পণ্য তালিকা' : 'My Listings',
                        style: const TextStyle(
                            fontSize: 17, fontWeight: FontWeight.bold)),
                    Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 10, vertical: 4),
                      decoration: BoxDecoration(
                          color: AppTheme.primaryGreen.withValues(alpha: 0.1),
                          borderRadius: BorderRadius.circular(10)),
                      child: Text(
                        '$soldCount ${bn ? "টি বিক্রিত" : "sold"}',
                        style: const TextStyle(
                            color: AppTheme.primaryGreen,
                            fontSize: 12,
                            fontWeight: FontWeight.w600),
                      ),
                    ),
                  ],
                ),
              ),
              Divider(height: 1, color: Colors.grey.shade200),
              Expanded(
                child: listings.isEmpty
                    ? Center(
                        child: Column(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Icon(Icons.storefront_outlined,
                                size: 56, color: Colors.grey.shade300),
                            const SizedBox(height: 12),
                            Text(
                              bn
                                  ? 'এখনো কোনো পণ্য যোগ করেননি'
                                  : 'No products listed yet',
                              style: TextStyle(
                                  color: Colors.grey.shade500, fontSize: 15),
                            ),
                            const SizedBox(height: 16),
                            ElevatedButton(
                              onPressed: () {
                                Navigator.pop(context);
                                Navigator.pushNamed(
                                    context, AppRouter.sellProduct);
                              },
                              style: ElevatedButton.styleFrom(
                                backgroundColor: AppTheme.primaryGreen,
                                foregroundColor: Colors.white,
                                shape: RoundedRectangleBorder(
                                    borderRadius: BorderRadius.circular(12)),
                              ),
                              child: Text(bn ? 'পণ্য যোগ করুন' : 'Add Product'),
                            ),
                          ],
                        ),
                      )
                    : ListView.separated(
                        controller: controller,
                        padding: const EdgeInsets.all(16),
                        itemCount: listings.length,
                        separatorBuilder: (_, __) => const SizedBox(height: 10),
                        itemBuilder: (_, i) {
                          final p = listings[i] as dynamic;
                          return Container(
                            padding: const EdgeInsets.all(12),
                            decoration: BoxDecoration(
                              color: Colors.grey.shade50,
                              borderRadius: BorderRadius.circular(12),
                              border: Border.all(color: Colors.grey.shade200),
                            ),
                            child: Row(
                              children: [
                                ClipRRect(
                                  borderRadius: BorderRadius.circular(8),
                                  child: p.primaryImage != null
                                      ? Image.network(p.primaryImage!,
                                          width: 56,
                                          height: 56,
                                          fit: BoxFit.cover,
                                          errorBuilder: (_, __, ___) =>
                                              _imgPlaceholder())
                                      : _imgPlaceholder(),
                                ),
                                const SizedBox(width: 12),
                                Expanded(
                                  child: Column(
                                    crossAxisAlignment:
                                        CrossAxisAlignment.start,
                                    children: [
                                      Text(p.title,
                                          style: const TextStyle(
                                              fontWeight: FontWeight.w600,
                                              fontSize: 14),
                                          maxLines: 1,
                                          overflow: TextOverflow.ellipsis),
                                      Text(
                                          '৳${p.price.toStringAsFixed(0)} / ${p.unit}',
                                          style: TextStyle(
                                              color: Colors.grey.shade600,
                                              fontSize: 12),
                                          overflow: TextOverflow.ellipsis),
                                      Text(
                                        '${bn ? "স্টক" : "Stock"}: ${p.stock} ${p.unit}',
                                        style: TextStyle(
                                            color: p.stock > 0
                                                ? AppTheme.primaryGreen
                                                : Colors.red.shade400,
                                            fontSize: 12,
                                            fontWeight: FontWeight.w500),
                                        overflow: TextOverflow.ellipsis,
                                      ),
                                    ],
                                  ),
                                ),
                                const SizedBox(width: 8),
                                Container(
                                  padding: const EdgeInsets.symmetric(
                                      horizontal: 8, vertical: 4),
                                  decoration: BoxDecoration(
                                    color: p.isActive
                                        ? AppTheme.primaryGreen
                                            .withValues(alpha: 0.1)
                                        : Colors.red.shade50,
                                    borderRadius: BorderRadius.circular(8),
                                  ),
                                  child: Text(
                                    p.isActive
                                        ? (bn ? 'সক্রিয়' : 'Active')
                                        : (bn ? 'বন্ধ' : 'Inactive'),
                                    style: TextStyle(
                                        fontSize: 11,
                                        color: p.isActive
                                            ? AppTheme.primaryGreen
                                            : Colors.red.shade400,
                                        fontWeight: FontWeight.w600),
                                  ),
                                ),
                              ],
                            ),
                          );
                        },
                      ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _imgPlaceholder() => Container(
        width: 56,
        height: 56,
        color: Colors.grey.shade200,
        child: const Icon(Icons.image_outlined, color: Colors.grey),
      );

  // ---------------------------------------------------------------------------
  // Edit profile sheet (unchanged)
  // ---------------------------------------------------------------------------

  void _showEditProfile(
    BuildContext context, {
    required String name,
    required String phone,
    required String email,
    required String division,
    required bool bn,
  }) {
    final nameCtrl = TextEditingController(text: name);
    String selectedDivision = division.isNotEmpty ? division : 'ঢাকা';
    bool isSaving = false;

    const divisions = [
      'ঢাকা',
      'চট্টগ্রাম',
      'রাজশাহী',
      'খুলনা',
      'বরিশাল',
      'সিলেট',
      'রংপুর',
      'ময়মনসিংহ',
    ];

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => StatefulBuilder(
        builder: (ctx, setSheetState) => Padding(
          padding:
              EdgeInsets.only(bottom: MediaQuery.of(ctx).viewInsets.bottom),
          child: Container(
            decoration: const BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.vertical(top: Radius.circular(20))),
            padding: const EdgeInsets.all(20),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(bn ? 'প্রোফাইল সম্পাদনা' : 'Edit Profile',
                        style: const TextStyle(
                            fontSize: 17, fontWeight: FontWeight.bold)),
                    IconButton(
                        icon: const Icon(Icons.close),
                        onPressed: () => Navigator.pop(ctx)),
                  ],
                ),
                const SizedBox(height: 16),
                _sheetField(
                    nameCtrl, bn ? 'নাম' : 'Name', Icons.person_outline),
                const SizedBox(height: 12),
                _sheetField(TextEditingController(text: phone),
                    bn ? 'ফোন নম্বর' : 'Phone', Icons.phone_outlined,
                    readOnly: true),
                const SizedBox(height: 12),
                _sheetField(TextEditingController(text: email),
                    bn ? 'ইমেইল' : 'Email', Icons.email_outlined,
                    readOnly: true),
                const SizedBox(height: 12),
                DropdownButtonFormField<String>(
                  initialValue: selectedDivision,
                  decoration: InputDecoration(
                    labelText: bn ? 'বিভাগ' : 'Division',
                    prefixIcon: const Icon(Icons.location_on_outlined,
                        color: AppTheme.primaryGreen),
                    filled: true,
                    fillColor: const Color(0xFFF8FAF8),
                    border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(10),
                        borderSide: BorderSide(color: Colors.grey.shade200)),
                    enabledBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(10),
                        borderSide: BorderSide(color: Colors.grey.shade200)),
                    focusedBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(10),
                        borderSide: const BorderSide(
                            color: AppTheme.primaryGreen, width: 1.5)),
                  ),
                  items: divisions
                      .map((d) => DropdownMenuItem(value: d, child: Text(d)))
                      .toList(),
                  onChanged: (v) => setSheetState(() => selectedDivision = v!),
                  dropdownColor: Colors.white,
                  icon: const Icon(Icons.keyboard_arrow_down,
                      color: AppTheme.primaryGreen),
                ),
                const SizedBox(height: 20),
                SizedBox(
                  width: double.infinity,
                  height: 50,
                  child: ElevatedButton(
                    onPressed: isSaving
                        ? null
                        : () async {
                            setSheetState(() => isSaving = true);
                            final nav = Navigator.of(ctx);
                            final messenger = ScaffoldMessenger.of(context);
                            try {
                              await SupabaseService.instance.updateProfile(
                                name: nameCtrl.text.trim(),
                                division: selectedDivision,
                              );
                              await ref.read(authProvider.notifier).refresh();
                              nav.pop();
                              messenger.showSnackBar(SnackBar(
                                content: Text(bn
                                    ? 'প্রোফাইল আপডেট হয়েছে'
                                    : 'Profile updated'),
                                backgroundColor: AppTheme.primaryGreen,
                                behavior: SnackBarBehavior.floating,
                              ));
                            } catch (e) {
                              setSheetState(() => isSaving = false);
                              messenger.showSnackBar(SnackBar(
                                content: Text(
                                    '${bn ? "আপডেট ব্যর্থ" : "Update failed"}: $e'),
                                backgroundColor: Colors.red,
                                behavior: SnackBarBehavior.floating,
                              ));
                            }
                          },
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppTheme.primaryGreen,
                      foregroundColor: Colors.white,
                      disabledBackgroundColor:
                          AppTheme.primaryGreen.withValues(alpha: 0.5),
                      shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12)),
                    ),
                    child: isSaving
                        ? const SizedBox(
                            width: 20,
                            height: 20,
                            child: CircularProgressIndicator(
                                color: Colors.white, strokeWidth: 2.5))
                        : Text(bn ? 'সংরক্ষণ করুন' : 'Save',
                            style: const TextStyle(
                                fontSize: 15, fontWeight: FontWeight.bold)),
                  ),
                ),
                const SizedBox(height: 8),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _sheetField(TextEditingController ctrl, String label, IconData icon,
      {TextInputType keyboardType = TextInputType.text,
      bool readOnly = false}) {
    return TextField(
      controller: ctrl,
      keyboardType: keyboardType,
      readOnly: readOnly,
      style: TextStyle(color: readOnly ? Colors.grey.shade500 : Colors.black87),
      decoration: InputDecoration(
        labelText: label,
        prefixIcon: Icon(icon, color: AppTheme.primaryGreen, size: 20),
        filled: true,
        fillColor: readOnly ? Colors.grey.shade100 : const Color(0xFFF8FAF8),
        contentPadding:
            const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
        border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(10),
            borderSide: BorderSide(color: Colors.grey.shade200)),
        enabledBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(10),
            borderSide: BorderSide(color: Colors.grey.shade200)),
        focusedBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(10),
            borderSide: BorderSide(
                color: readOnly ? Colors.grey.shade200 : AppTheme.primaryGreen,
                width: readOnly ? 1 : 1.5)),
      ),
    );
  }

  // ---------------------------------------------------------------------------
  // Logout dialog (unchanged)
  // ---------------------------------------------------------------------------

  void _confirmLogout(BuildContext context, bool bn) {
    showDialog(
      context: context,
      builder: (_) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: Text(bn ? 'লগআউট করবেন?' : 'Log out?',
            style: const TextStyle(fontWeight: FontWeight.bold)),
        content: Text(bn
            ? 'আপনি কি সত্যিই লগআউট করতে চান?'
            : 'Are you sure you want to log out?'),
        actions: [
          ElevatedButton(
            onPressed: () => Navigator.pop(context),
            style: ElevatedButton.styleFrom(
              backgroundColor: AppTheme.primaryGreen,
              foregroundColor: Colors.white,
              shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(10)),
            ),
            child: Text(bn ? 'না' : 'Cancel'),
          ),
          ElevatedButton(
            onPressed: () {
              Navigator.pop(context);
              ref.read(authProvider.notifier).signOut();
              Navigator.pushNamedAndRemoveUntil(
                  context, AppRouter.login, (route) => false);
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFFEF4444),
              foregroundColor: Colors.white,
              shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(10)),
            ),
            child: Text(bn ? 'হ্যাঁ, লগআউট' : 'Yes, Log Out'),
          ),
        ],
      ),
    );
  }

  // ---------------------------------------------------------------------------
  // Floating nav (unchanged)
  // ---------------------------------------------------------------------------

  Widget _buildFloatingNav(bool bn) {
    final items = [
      (icon: Icons.home_rounded, label: _t(bn, 'হোম', 'Home')),
      (icon: Icons.store_rounded, label: _t(bn, 'বাজার', 'Market')),
      (
        icon: Icons.miscellaneous_services_rounded,
        label: _t(bn, 'সেবা', 'Services')
      ),
      (icon: Icons.person_rounded, label: _t(bn, 'প্রোফাইল', 'Profile')),
    ];

    return SafeArea(
      child: Padding(
        padding: const EdgeInsets.fromLTRB(24, 0, 24, 12),
        child: Container(
          height: 68,
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(36),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withValues(alpha: 0.12),
                blurRadius: 24,
                offset: const Offset(0, 8),
              ),
            ],
          ),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceAround,
            children: List.generate(items.length, (i) {
              final item = items[i];
              final isActive = _currentTabIndex == i;
              return GestureDetector(
                onTap: () => _onTabTapped(i),
                behavior: HitTestBehavior.opaque,
                child: AnimatedContainer(
                  duration: const Duration(milliseconds: 200),
                  curve: Curves.easeOutCubic,
                  padding:
                      const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
                  decoration: BoxDecoration(
                    color: isActive
                        ? AppTheme.primaryGreen.withValues(alpha: 0.12)
                        : Colors.transparent,
                    borderRadius: BorderRadius.circular(28),
                  ),
                  child: isActive
                      ? Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Icon(item.icon,
                                color: AppTheme.primaryGreen, size: 20),
                            const SizedBox(width: 6),
                            Text(
                              item.label,
                              style: const TextStyle(
                                color: AppTheme.primaryGreen,
                                fontSize: 13,
                                fontWeight: FontWeight.w700,
                              ),
                            ),
                          ],
                        )
                      : Icon(item.icon,
                          color: const Color(0xFF9E9E9E), size: 22),
                ),
              );
            }),
          ),
        ),
      ),
    );
  }
}

// =============================================================================
// Helper widgets
// =============================================================================

class _StatCard extends StatelessWidget {
  final String value;
  final String label;
  final IconData icon;
  final Color color;
  const _StatCard(
      {required this.value,
      required this.label,
      required this.icon,
      required this.color});

  @override
  Widget build(BuildContext context) {
    return Expanded(
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 14, horizontal: 8),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(14),
          boxShadow: [
            BoxShadow(
                color: Colors.black.withValues(alpha: 0.04),
                blurRadius: 8,
                offset: const Offset(0, 2)),
          ],
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                  color: color.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(10)),
              child: Icon(icon, color: color, size: 18),
            ),
            const SizedBox(height: 8),
            Text(value,
                style: TextStyle(
                    fontSize: 20, fontWeight: FontWeight.bold, color: color),
                maxLines: 1,
                overflow: TextOverflow.ellipsis),
            Text(label,
                style: TextStyle(fontSize: 11, color: Colors.grey.shade600),
                textAlign: TextAlign.center,
                maxLines: 2,
                overflow: TextOverflow.ellipsis),
          ],
        ),
      ),
    );
  }
}

class _Badge extends StatelessWidget {
  final String text;
  const _Badge(this.text);

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 2),
      decoration: BoxDecoration(
          color: const Color(0xFFEF4444),
          borderRadius: BorderRadius.circular(10)),
      child: Text(text,
          style: const TextStyle(
              color: Colors.white, fontSize: 11, fontWeight: FontWeight.bold)),
    );
  }
}

class _MenuItem {
  final IconData icon;
  final Color iconColor;
  final String label;
  final String? sublabel;
  final Color? labelColor;
  final Widget? trailing;
  final VoidCallback? onTap;

  const _MenuItem({
    required this.icon,
    required this.iconColor,
    required this.label,
    this.sublabel,
    this.labelColor,
    this.trailing,
    this.onTap,
  });
}
