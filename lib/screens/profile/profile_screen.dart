import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/router.dart';
import '../../core/theme.dart';
import '../../providers/auth_provider.dart';
import '../../providers/marketplace_provider.dart';
import '../../models/product.dart';
import '../../services/supabase_service.dart';

// ── Profile Screen ─────────────────────────────────────────────
class ProfileScreen extends ConsumerStatefulWidget {
  const ProfileScreen({super.key});

  @override
  ConsumerState<ProfileScreen> createState() => _ProfileScreenState();
}

class _ProfileScreenState extends ConsumerState<ProfileScreen> {
  static const int _currentTabIndex = 3;
  List<Product> _myListings = [];
  int _soldCount = 0;

  @override
  void initState() {
    super.initState();
    Future.microtask(() async {
      final notifier = ref.read(marketplaceProvider.notifier);
      await notifier.loadOrders();
      final listings = await notifier.fetchMyListings();
      if (mounted) {
        setState(() {
          _myListings = listings;
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
        Navigator.pushReplacementNamed(context, AppRouter.notifications);
        break;
    }
  }

  @override
  Widget build(BuildContext context) {
    final user = ref.watch(currentUserProvider);
    final name = user?.name ?? 'কৃষক';
    final phone = user?.phone ?? '';
    final email = user?.email ?? '';
    final division = user?.division ?? '';
    final role = user?.role ?? 'farmer';
    final avatarUrl = user?.avatarUrl ?? '';

    final marketState = ref.watch(marketplaceProvider);
    final notifier = ref.read(marketplaceProvider.notifier);
    final totalOrders = marketState.orders.length;
    final activeOrders = marketState.orders
        .where((o) => o.status != 'delivered' && o.status != 'cancelled')
        .length;

    return Scaffold(
      backgroundColor: const Color(0xFFF5F7F5),
      body: CustomScrollView(
        slivers: [
          _buildSliverHeader(
            name: name,
            division: division,
            role: role,
            avatarUrl: avatarUrl,
          ),
          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                children: [
                  _buildStatsRow(totalOrders, activeOrders, _myListings.length),
                  const SizedBox(height: 20),
                  _buildMenuSection(
                    title: 'কেনাকাটা',
                    items: [
                      _MenuItem(
                        icon: Icons.receipt_long_outlined,
                        iconColor: const Color(0xFF3B82F6),
                        label: 'আমার অর্ডার',
                        trailing:
                            activeOrders > 0 ? _Badge('$activeOrders') : null,
                        onTap: () =>
                            Navigator.pushNamed(context, AppRouter.orders),
                      ),
                      _MenuItem(
                        icon: Icons.shopping_cart_outlined,
                        iconColor: const Color(0xFFF59E0B),
                        label: 'কার্ট',
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
                    title: 'বিক্রয়',
                    items: [
                      _MenuItem(
                        icon: Icons.storefront_outlined,
                        iconColor: AppTheme.primaryGreen,
                        label: 'আমার পণ্য তালিকা',
                        sublabel: _myListings.isEmpty
                            ? 'কোনো পণ্য নেই'
                            : '${_myListings.length}টি পণ্য · $_soldCount টি বিক্রিত',
                        onTap: () =>
                            _showMyListings(context, _myListings, _soldCount),
                      ),
                      _MenuItem(
                        icon: Icons.add_box_outlined,
                        iconColor: const Color(0xFF8B5CF6),
                        label: 'নতুন পণ্য যোগ করুন',
                        onTap: () =>
                            Navigator.pushNamed(context, AppRouter.sellProduct),
                      ),
                    ],
                  ),
                  const SizedBox(height: 14),
                  _buildMenuSection(
                    title: 'প্রোফাইল',
                    items: [
                      _MenuItem(
                        icon: Icons.person_outline_rounded,
                        iconColor: const Color(0xFF06B6D4),
                        label: 'প্রোফাইল সম্পাদনা',
                        onTap: () => _showEditProfile(
                          context,
                          name: name,
                          phone: phone,
                          email: email,
                          division: division,
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
                        label: 'লগআউট',
                        labelColor: const Color(0xFFEF4444),
                        onTap: () => _confirmLogout(context),
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
      bottomNavigationBar: _buildBottomNav(),
    );
  }

  // ── Sliver header ────────────────────────────────────────────
  Widget _buildSliverHeader({
    required String name,
    required String division,
    required String role,
    required String avatarUrl,
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
                Stack(
                  children: [
                    CircleAvatar(
                      radius: 44,
                      backgroundColor: Colors.white.withValues(alpha: 0.2),
                      backgroundImage:
                          avatarUrl.isNotEmpty ? NetworkImage(avatarUrl) : null,
                      child: avatarUrl.isEmpty
                          ? const Icon(Icons.person,
                              size: 44, color: Colors.white70)
                          : null,
                    ),
                    Positioned(
                      bottom: 0,
                      right: 0,
                      child: Container(
                        padding: const EdgeInsets.all(5),
                        decoration: const BoxDecoration(
                          color: Colors.white,
                          shape: BoxShape.circle,
                        ),
                        child: const Icon(Icons.camera_alt,
                            size: 14, color: AppTheme.primaryGreen),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 12),
                Text(
                  name,
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 4),
                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    if (division.isNotEmpty) ...[
                      const Icon(Icons.location_on,
                          color: Colors.white70, size: 14),
                      const SizedBox(width: 3),
                      Text(
                        division,
                        style: const TextStyle(
                            color: Colors.white70, fontSize: 13),
                      ),
                      const SizedBox(width: 12),
                    ],
                    Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 8, vertical: 2),
                      decoration: BoxDecoration(
                        color: Colors.white.withValues(alpha: 0.2),
                        borderRadius: BorderRadius.circular(10),
                      ),
                      child: Text(
                        role == 'farmer' ? 'কৃষক' : 'ক্রেতা',
                        style: const TextStyle(
                            color: Colors.white,
                            fontSize: 11,
                            fontWeight: FontWeight.w600),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  // ── Stats row ────────────────────────────────────────────────
  Widget _buildStatsRow(int totalOrders, int activeOrders, int listings) {
    return Row(
      children: [
        _StatCard(
            value: '$totalOrders',
            label: 'মোট অর্ডার',
            icon: Icons.receipt_long_outlined,
            color: const Color(0xFF3B82F6)),
        const SizedBox(width: 10),
        _StatCard(
            value: '$activeOrders',
            label: 'চলমান',
            icon: Icons.local_shipping_outlined,
            color: const Color(0xFFF59E0B)),
        const SizedBox(width: 10),
        _StatCard(
            value: '$listings',
            label: 'আমার পণ্য',
            icon: Icons.storefront_outlined,
            color: AppTheme.primaryGreen),
      ],
    );
  }

  // ── Menu section ─────────────────────────────────────────────
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
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          if (title.isNotEmpty)
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 14, 16, 4),
              child: Text(
                title,
                style: TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.w600,
                    color: Colors.grey.shade500,
                    letterSpacing: 0.5),
              ),
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
                borderRadius: BorderRadius.circular(10),
              ),
              child: Icon(item.icon, color: item.iconColor, size: 18),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    item.label,
                    style: TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.w500,
                      color: item.labelColor ?? const Color(0xFF1A1A1A),
                    ),
                  ),
                  if (item.sublabel != null)
                    Text(
                      item.sublabel!,
                      style:
                          TextStyle(fontSize: 12, color: Colors.grey.shade500),
                    ),
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

  // ── My listings bottom sheet ──────────────────────────────────
  void _showMyListings(
      BuildContext context, List<dynamic> listings, int soldCount) {
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
                padding: const EdgeInsets.all(16),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    const Text(
                      'আমার পণ্য তালিকা',
                      style:
                          TextStyle(fontSize: 17, fontWeight: FontWeight.bold),
                    ),
                    Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 10, vertical: 4),
                      decoration: BoxDecoration(
                        color: AppTheme.primaryGreen.withValues(alpha: 0.1),
                        borderRadius: BorderRadius.circular(10),
                      ),
                      child: Text(
                        '$soldCount টি বিক্রিত',
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
                            Text('এখনো কোনো পণ্য যোগ করেননি',
                                style: TextStyle(
                                    color: Colors.grey.shade500, fontSize: 15)),
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
                              child: const Text('পণ্য যোগ করুন'),
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
                                      ? Image.network(
                                          p.primaryImage!,
                                          width: 56,
                                          height: 56,
                                          fit: BoxFit.cover,
                                          errorBuilder: (_, __, ___) =>
                                              _imgPlaceholder(),
                                        )
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
                                              fontSize: 14)),
                                      Text(
                                          '৳${p.price.toStringAsFixed(0)} / ${p.unit}',
                                          style: TextStyle(
                                              color: Colors.grey.shade600,
                                              fontSize: 12)),
                                      Text('স্টক: ${p.stock} ${p.unit}',
                                          style: TextStyle(
                                              color: p.stock > 0
                                                  ? AppTheme.primaryGreen
                                                  : Colors.red.shade400,
                                              fontSize: 12,
                                              fontWeight: FontWeight.w500)),
                                    ],
                                  ),
                                ),
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
                                    p.isActive ? 'সক্রিয়' : 'বন্ধ',
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

  // ── Edit profile bottom sheet ─────────────────────────────────
  void _showEditProfile(
    BuildContext context, {
    required String name,
    required String phone,
    required String email,
    required String division,
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
          padding: EdgeInsets.only(
            bottom: MediaQuery.of(ctx).viewInsets.bottom,
          ),
          child: Container(
            decoration: const BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
            ),
            padding: const EdgeInsets.all(20),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    const Text('প্রোফাইল সম্পাদনা',
                        style: TextStyle(
                            fontSize: 17, fontWeight: FontWeight.bold)),
                    IconButton(
                      icon: const Icon(Icons.close),
                      onPressed: () => Navigator.pop(ctx),
                    ),
                  ],
                ),
                const SizedBox(height: 16),

                // Name field
                _sheetField(nameCtrl, 'নাম', Icons.person_outline),
                const SizedBox(height: 12),

                // Phone — read-only, shown for info only
                _sheetField(
                  TextEditingController(text: phone),
                  'ফোন নম্বর',
                  Icons.phone_outlined,
                  readOnly: true,
                ),
                const SizedBox(height: 12),

                // Email — read-only, shown for info only
                _sheetField(
                  TextEditingController(text: email),
                  'ইমেইল',
                  Icons.email_outlined,
                  readOnly: true,
                ),
                const SizedBox(height: 12),

                // Division dropdown
                DropdownButtonFormField<String>(
                  value: selectedDivision,
                  decoration: InputDecoration(
                    labelText: 'বিভাগ',
                    prefixIcon: const Icon(Icons.location_on_outlined,
                        color: AppTheme.primaryGreen),
                    filled: true,
                    fillColor: const Color(0xFFF8FAF8),
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(10),
                      borderSide: BorderSide(color: Colors.grey.shade200),
                    ),
                    enabledBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(10),
                      borderSide: BorderSide(color: Colors.grey.shade200),
                    ),
                    focusedBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(10),
                      borderSide: const BorderSide(
                          color: AppTheme.primaryGreen, width: 1.5),
                    ),
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

                            // Capture nav/messenger before await
                            final nav = Navigator.of(ctx);
                            final messenger = ScaffoldMessenger.of(context);

                            try {
                              await SupabaseService.instance.updateProfile(
                                name: nameCtrl.text.trim(),
                                division: selectedDivision,
                              );
                              // Refresh auth so header updates immediately
                              await ref.read(authProvider.notifier).refresh();
                              nav.pop();
                              messenger.showSnackBar(
                                const SnackBar(
                                  content: Text('প্রোফাইল আপডেট হয়েছে'),
                                  backgroundColor: AppTheme.primaryGreen,
                                  behavior: SnackBarBehavior.floating,
                                ),
                              );
                            } catch (e) {
                              setSheetState(() => isSaving = false);
                              messenger.showSnackBar(
                                SnackBar(
                                  content: Text('আপডেট ব্যর্থ হয়েছে: $e'),
                                  backgroundColor: Colors.red,
                                  behavior: SnackBarBehavior.floating,
                                ),
                              );
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
                                color: Colors.white, strokeWidth: 2.5),
                          )
                        : const Text('সংরক্ষণ করুন',
                            style: TextStyle(
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

  Widget _sheetField(
    TextEditingController ctrl,
    String label,
    IconData icon, {
    TextInputType keyboardType = TextInputType.text,
    bool readOnly = false,
  }) {
    return TextField(
      controller: ctrl,
      keyboardType: keyboardType,
      readOnly: readOnly,
      style: TextStyle(
        color: readOnly ? Colors.grey.shade500 : Colors.black87,
      ),
      decoration: InputDecoration(
        labelText: label,
        prefixIcon: Icon(icon, color: AppTheme.primaryGreen, size: 20),
        filled: true,
        fillColor: readOnly ? Colors.grey.shade100 : const Color(0xFFF8FAF8),
        contentPadding:
            const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(10),
          borderSide: BorderSide(color: Colors.grey.shade200),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(10),
          borderSide: BorderSide(color: Colors.grey.shade200),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(10),
          borderSide: BorderSide(
            color: readOnly ? Colors.grey.shade200 : AppTheme.primaryGreen,
            width: readOnly ? 1 : 1.5,
          ),
        ),
      ),
    );
  }

  void _confirmLogout(BuildContext context) {
    showDialog(
      context: context,
      builder: (_) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: const Text('লগআউট করবেন?',
            style: TextStyle(fontWeight: FontWeight.bold)),
        content: const Text('আপনি কি সত্যিই লগআউট করতে চান?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text('না', style: TextStyle(color: Colors.grey.shade600)),
          ),
          ElevatedButton(
            onPressed: () {
              Navigator.pop(context);
              ref.read(authProvider.notifier).signOut();
              Navigator.pushNamedAndRemoveUntil(
                context,
                AppRouter.login,
                (route) => false,
              );
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFFEF4444),
              foregroundColor: Colors.white,
              shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(10)),
            ),
            child: const Text('হ্যাঁ, লগআউট'),
          ),
        ],
      ),
    );
  }

  // ── Bottom nav ───────────────────────────────────────────────
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
                icon: Icon(Icons.notifications_outlined), label: 'বার্তা'),
            BottomNavigationBarItem(
                icon: Icon(Icons.person_outline), label: 'প্রোফাইল'),
          ],
        ),
      ),
    );
  }
}

// ── Helper widgets ─────────────────────────────────────────────
class _StatCard extends StatelessWidget {
  final String value;
  final String label;
  final IconData icon;
  final Color color;

  const _StatCard({
    required this.value,
    required this.label,
    required this.icon,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    return Expanded(
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 14, horizontal: 10),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(14),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.04),
              blurRadius: 8,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        child: Column(
          children: [
            Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: color.withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(10),
              ),
              child: Icon(icon, color: color, size: 18),
            ),
            const SizedBox(height: 8),
            Text(value,
                style: TextStyle(
                    fontSize: 20, fontWeight: FontWeight.bold, color: color)),
            Text(label,
                style: TextStyle(fontSize: 11, color: Colors.grey.shade600),
                textAlign: TextAlign.center),
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
        borderRadius: BorderRadius.circular(10),
      ),
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
