import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:http/http.dart' as http;
import 'package:image_picker/image_picker.dart';
import 'package:intl/intl.dart';

import '../../core/constants.dart';
import '../../core/theme.dart';
import '../../models/rental.dart';
import '../../providers/rental_provider.dart';
import '../../providers/lang_provider.dart';
import '../../services/supabase_service.dart';
import 'booking_screen.dart';

String _t(bool bn, String bangla, String english) => bn ? bangla : english;

Future<LatLng?> _geocodeLocation(String query) async {
  try {
    final encoded = Uri.encodeComponent(query);
    final url =
        'https://maps.googleapis.com/maps/api/geocode/json?address=$encoded&region=BD&key=${AppConstants.googleMapsApiKey}';
    final res = await http.get(Uri.parse(url));
    if (res.statusCode != 200) return null;
    final body = jsonDecode(res.body) as Map<String, dynamic>;
    final results = body['results'] as List?;
    if (results == null || results.isEmpty) return null;
    final loc = (results.first as Map)['geometry']['location'];
    return LatLng(
        (loc['lat'] as num).toDouble(), (loc['lng'] as num).toDouble());
  } catch (_) {
    return null;
  }
}

// ===========================================================================
// ROOT SCREEN
// ===========================================================================
class RentalsScreen extends ConsumerStatefulWidget {
  const RentalsScreen({super.key});

  @override
  ConsumerState<RentalsScreen> createState() => _RentalsScreenState();
}

class _RentalsScreenState extends ConsumerState<RentalsScreen>
    with SingleTickerProviderStateMixin {
  late final TabController _tabController;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final bn = ref.watch(langProvider);

    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        backgroundColor: AppTheme.primaryGreen,
        foregroundColor: Colors.white,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: Colors.white),
          onPressed: () => Navigator.pop(context),
        ),
        title: Text(
          _t(bn, 'সরঞ্জাম ভাড়া', 'Equipment Rental'),
          style: const TextStyle(fontWeight: FontWeight.w700, fontSize: 18),
        ),
        // No language toggle — controlled globally from home screen
        bottom: TabBar(
          controller: _tabController,
          indicatorColor: Colors.white,
          indicatorWeight: 3,
          labelStyle:
              const TextStyle(fontWeight: FontWeight.w700, fontSize: 14),
          unselectedLabelStyle:
              const TextStyle(fontWeight: FontWeight.w400, fontSize: 14),
          labelColor: Colors.white,
          unselectedLabelColor: Colors.white70,
          tabs: [
            Tab(text: _t(bn, 'ব্রাউজ করুন', 'Browse')),
            Tab(text: _t(bn, 'আমার সরঞ্জাম', 'My Equipment')),
          ],
        ),
      ),
      body: TabBarView(
        controller: _tabController,
        children: [
          _BrowseTab(bn: bn),
          _OwnerTab(bn: bn),
        ],
      ),
    );
  }
}

// ===========================================================================
// BROWSE TAB
// ===========================================================================
class _BrowseTab extends ConsumerStatefulWidget {
  final bool bn;
  const _BrowseTab({required this.bn});

  @override
  ConsumerState<_BrowseTab> createState() => _BrowseTabState();
}

class _BrowseTabState extends ConsumerState<_BrowseTab> {
  final _scrollController = ScrollController();

  @override
  void initState() {
    super.initState();
    _scrollController.addListener(_onScroll);
  }

  @override
  void dispose() {
    _scrollController.dispose();
    super.dispose();
  }

  void _onScroll() {
    if (_scrollController.position.pixels >=
        _scrollController.position.maxScrollExtent - 200) {
      ref.read(browseEquipmentProvider.notifier).loadMore();
    }
  }

  @override
  Widget build(BuildContext context) {
    final filter = ref.watch(rentalFilterProvider);
    final equipmentAsync = ref.watch(browseEquipmentProvider);

    return Column(
      children: [
        _FilterBar(filter: filter, bn: widget.bn),
        Expanded(
          child: equipmentAsync.when(
            loading: () => const Center(child: CircularProgressIndicator()),
            error: (e, _) => _ErrorView(
              message: _t(widget.bn, 'তালিকা লোড করতে ব্যর্থ হয়েছে',
                  'Failed to load listings'),
              onRetry: () =>
                  ref.read(browseEquipmentProvider.notifier).refresh(),
            ),
            data: (items) {
              if (items.isEmpty) {
                return _EmptyView(
                  icon: Icons.agriculture_outlined,
                  message: _t(
                      widget.bn,
                      'এই ফিল্টারে কোনো সরঞ্জাম পাওয়া যায়নি',
                      'No equipment found for this filter'),
                );
              }
              return RefreshIndicator(
                color: AppTheme.primaryGreen,
                onRefresh: () =>
                    ref.read(browseEquipmentProvider.notifier).refresh(),
                child: ListView.builder(
                  controller: _scrollController,
                  padding: const EdgeInsets.all(16),
                  itemCount: items.length + 1,
                  itemBuilder: (context, index) {
                    if (index == items.length) {
                      return ref.read(browseEquipmentProvider.notifier).hasMore
                          ? const Padding(
                              padding: EdgeInsets.symmetric(vertical: 16),
                              child: Center(child: CircularProgressIndicator()))
                          : const SizedBox(height: 16);
                    }
                    return _EquipmentCard(
                      equipment: items[index],
                      bn: widget.bn,
                      onBook: () => Navigator.push(
                          context,
                          MaterialPageRoute(
                              builder: (_) => BookingScreen(
                                  equipment: items[index],
                                  bn: widget.bn))).then((_) =>
                          ref.read(browseEquipmentProvider.notifier).refresh()),
                    );
                  },
                ),
              );
            },
          ),
        ),
      ],
    );
  }
}

class _FilterBar extends ConsumerWidget {
  final RentalFilter filter;
  final bool bn;
  const _FilterBar({required this.filter, required this.bn});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final notifier = ref.read(rentalFilterProvider.notifier);
    return Container(
      color: Colors.white,
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
      child: Row(
        children: [
          Expanded(
            child: _FilterDropdown<String>(
              hint: _t(bn, 'বিভাগ', 'Division'),
              value: filter.division,
              items: kBangladeshDivisions
                  .map((d) => DropdownMenuItem(value: d, child: Text(d)))
                  .toList(),
              onChanged: notifier.setDivision,
            ),
          ),
          const SizedBox(width: 8),
          Expanded(
            child: _FilterDropdown<EquipmentType>(
              hint: _t(bn, 'ধরন', 'Type'),
              value: filter.type,
              items: EquipmentType.values
                  .map((t) => DropdownMenuItem(
                      value: t, child: Text(bn ? t.labelBn : t.labelEn)))
                  .toList(),
              onChanged: notifier.setType,
            ),
          ),
          if (filter.division != null || filter.type != null) ...[
            const SizedBox(width: 8),
            GestureDetector(
              onTap: notifier.reset,
              child: Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                    color: AppTheme.errorRed.withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(8)),
                child:
                    const Icon(Icons.close, size: 18, color: AppTheme.errorRed),
              ),
            ),
          ],
        ],
      ),
    );
  }
}

class _FilterDropdown<T> extends StatelessWidget {
  final String hint;
  final T? value;
  final List<DropdownMenuItem<T>> items;
  final ValueChanged<T?> onChanged;
  const _FilterDropdown(
      {required this.hint,
      required this.value,
      required this.items,
      required this.onChanged});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10),
      decoration: BoxDecoration(
          border: Border.all(color: AppTheme.borderGrey),
          borderRadius: BorderRadius.circular(10),
          color: Colors.white),
      child: DropdownButtonHideUnderline(
        child: DropdownButton<T>(
          hint: Text(hint,
              style:
                  const TextStyle(fontSize: 13, color: AppTheme.textSecondary)),
          value: value,
          items: items,
          onChanged: onChanged,
          isExpanded: true,
          style: const TextStyle(
              fontSize: 13, color: AppTheme.textPrimary, fontFamily: 'inherit'),
          icon: const Icon(Icons.keyboard_arrow_down,
              size: 18, color: AppTheme.textSecondary),
          dropdownColor: Colors.white,
        ),
      ),
    );
  }
}

class _EquipmentCard extends StatelessWidget {
  final EquipmentModel equipment;
  final bool bn;
  final VoidCallback onBook;
  const _EquipmentCard(
      {required this.equipment, required this.bn, required this.onBook});

  static final _fmt =
      NumberFormat.currency(locale: 'en_BD', symbol: '৳', decimalDigits: 0);

  String _typeLabel(String type) => bn
      ? (EquipmentType.fromValue(type)?.labelBn ?? type)
      : (EquipmentType.fromValue(type)?.labelEn ?? type);
  IconData _typeIcon(String type) {
    switch (type) {
      case 'tractor':
        return Icons.agriculture;
      case 'truck':
        return Icons.local_shipping;
      case 'pump':
        return Icons.water;
      default:
        return Icons.construction;
    }
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppTheme.borderGrey),
        boxShadow: [
          BoxShadow(
              color: Colors.black.withValues(alpha: 0.04),
              blurRadius: 8,
              offset: const Offset(0, 2))
        ],
      ),
      child: Padding(
        padding: const EdgeInsets.all(14),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Container(
              width: 56,
              height: 56,
              decoration: BoxDecoration(
                  color: AppTheme.primaryGreen.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(12)),
              clipBehavior: Clip.antiAlias,
              child: equipment.images.isNotEmpty
                  ? Image.network(equipment.images.first,
                      fit: BoxFit.cover,
                      errorBuilder: (_, __, ___) => Icon(
                          _typeIcon(equipment.type),
                          color: AppTheme.primaryGreen,
                          size: 28))
                  : Icon(_typeIcon(equipment.type),
                      color: AppTheme.primaryGreen, size: 28),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(equipment.name,
                        style: const TextStyle(
                            fontSize: 15, fontWeight: FontWeight.w700)),
                    const SizedBox(height: 2),
                    Text(_typeLabel(equipment.type),
                        style: const TextStyle(
                            fontSize: 12, color: AppTheme.textSecondary)),
                    if (equipment.locationText != null) ...[
                      const SizedBox(height: 4),
                      Row(children: [
                        const Icon(Icons.location_on,
                            size: 12, color: AppTheme.textSecondary),
                        const SizedBox(width: 2),
                        Flexible(
                            child: Text(equipment.locationText!,
                                style: const TextStyle(
                                    fontSize: 11,
                                    color: AppTheme.textSecondary),
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis)),
                      ]),
                    ],
                    if (equipment.ownerPhone != null) ...[
                      const SizedBox(height: 4),
                      Row(children: [
                        const Icon(Icons.phone,
                            size: 12, color: AppTheme.textSecondary),
                        const SizedBox(width: 2),
                        Text(equipment.ownerPhone!,
                            style: const TextStyle(
                                fontSize: 11, color: AppTheme.textSecondary)),
                      ]),
                    ],
                    const SizedBox(height: 8),
                    Row(children: [
                      Text(_fmt.format(equipment.ratePerDay),
                          style: const TextStyle(
                              fontSize: 17,
                              fontWeight: FontWeight.w800,
                              color: AppTheme.primaryGreen)),
                      Text(_t(bn, '/দিন', '/day'),
                          style: const TextStyle(
                              fontSize: 12, color: AppTheme.textSecondary)),
                      const Spacer(),
                      ElevatedButton(
                        onPressed: onBook,
                        style: ElevatedButton.styleFrom(
                          backgroundColor: AppTheme.primaryGreen,
                          foregroundColor: Colors.white,
                          padding: const EdgeInsets.symmetric(
                              horizontal: 16, vertical: 8),
                          minimumSize: Size.zero,
                          tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                          shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(8)),
                          elevation: 0,
                        ),
                        child: Text(_t(bn, 'বুক করুন', 'Book'),
                            style: const TextStyle(
                                fontSize: 13, fontWeight: FontWeight.w700)),
                      ),
                    ]),
                  ]),
            ),
          ],
        ),
      ),
    );
  }
}

// ===========================================================================
// OWNER TAB
// ===========================================================================
class _OwnerTab extends ConsumerStatefulWidget {
  final bool bn;
  const _OwnerTab({required this.bn});

  @override
  ConsumerState<_OwnerTab> createState() => _OwnerTabState();
}

class _OwnerTabState extends ConsumerState<_OwnerTab> {
  bool _showBookings = false;

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Container(
          color: Colors.white,
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
          child: Row(
            children: [
              _SubTab(
                  label: _t(widget.bn, 'আমার তালিকা', 'My Listings'),
                  active: !_showBookings,
                  onTap: () => setState(() => _showBookings = false)),
              const SizedBox(width: 8),
              _SubTab(
                  label: _t(widget.bn, 'বুকিং সমূহ', 'Bookings'),
                  active: _showBookings,
                  onTap: () => setState(() => _showBookings = true)),
              const Spacer(),
              GestureDetector(
                onTap: () => _showAddSheet(context),
                child: Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                  decoration: BoxDecoration(
                      color: AppTheme.primaryGreen,
                      borderRadius: BorderRadius.circular(8)),
                  child: Row(mainAxisSize: MainAxisSize.min, children: [
                    const Icon(Icons.add, color: Colors.white, size: 16),
                    const SizedBox(width: 4),
                    Text(_t(widget.bn, 'যোগ করুন', 'Add'),
                        style: const TextStyle(
                            color: Colors.white,
                            fontSize: 13,
                            fontWeight: FontWeight.w700)),
                  ]),
                ),
              ),
            ],
          ),
        ),
        Expanded(
            child: _showBookings
                ? _OwnerBookingsList(bn: widget.bn)
                : _MyEquipmentList(bn: widget.bn)),
      ],
    );
  }

  void _showAddSheet(BuildContext context) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => _AddEquipmentSheet(bn: widget.bn),
    );
  }
}

class _SubTab extends StatelessWidget {
  final String label;
  final bool active;
  final VoidCallback onTap;
  const _SubTab(
      {required this.label, required this.active, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 7),
        decoration: BoxDecoration(
          color: active
              ? AppTheme.primaryGreen.withValues(alpha: 0.12)
              : Colors.transparent,
          borderRadius: BorderRadius.circular(8),
          border: Border.all(
              color: active ? AppTheme.primaryGreen : AppTheme.borderGrey),
        ),
        child: Text(label,
            style: TextStyle(
                fontSize: 13,
                fontWeight: active ? FontWeight.w700 : FontWeight.w400,
                color: active ? AppTheme.darkGreen : AppTheme.textSecondary)),
      ),
    );
  }
}

class _MyEquipmentList extends ConsumerWidget {
  final bool bn;
  const _MyEquipmentList({required this.bn});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final equipmentAsync = ref.watch(myEquipmentProvider);
    return equipmentAsync.when(
      loading: () => const Center(child: CircularProgressIndicator()),
      error: (e, _) => _ErrorView(
        message:
            _t(bn, 'তালিকা লোড করতে ব্যর্থ হয়েছে', 'Failed to load listings'),
        onRetry: () => ref.read(myEquipmentProvider.notifier).refresh(),
      ),
      data: (items) {
        if (items.isEmpty) {
          return _EmptyView(
              icon: Icons.add_box_outlined,
              message: _t(
                  bn,
                  'আপনার কোনো সরঞ্জাম তালিকা নেই\nউপরে + যোগ করুন চাপুন',
                  'No equipment listed yet\nTap + Add above'));
        }
        return RefreshIndicator(
          color: AppTheme.primaryGreen,
          onRefresh: () => ref.read(myEquipmentProvider.notifier).refresh(),
          child: ListView.builder(
            padding: const EdgeInsets.all(16),
            itemCount: items.length,
            itemBuilder: (_, i) =>
                _MyEquipmentCard(equipment: items[i], bn: bn),
          ),
        );
      },
    );
  }
}

class _MyEquipmentCard extends ConsumerWidget {
  final EquipmentModel equipment;
  final bool bn;
  const _MyEquipmentCard({required this.equipment, required this.bn});

  static final _fmt =
      NumberFormat.currency(locale: 'en_BD', symbol: '৳', decimalDigits: 0);

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final notifier = ref.read(myEquipmentProvider.notifier);
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: AppTheme.borderGrey)),
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Row(children: [
          Expanded(
              child: Text(equipment.name,
                  style: const TextStyle(
                      fontSize: 15, fontWeight: FontWeight.w700))),
          Row(children: [
            Text(
                equipment.available
                    ? _t(bn, 'উপলব্ধ', 'Available')
                    : _t(bn, 'অনুপলব্ধ', 'Unavailable'),
                style: TextStyle(
                    fontSize: 12,
                    color: equipment.available
                        ? AppTheme.primaryGreen
                        : AppTheme.errorRed)),
            const SizedBox(width: 6),
            Switch(
                value: equipment.available,
                activeThumbColor: AppTheme.primaryGreen,
                materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
                onChanged: (v) =>
                    notifier.toggleAvailability(equipment.id, available: v)),
          ]),
        ]),
        const SizedBox(height: 4),
        Text(
          '${bn ? (EquipmentType.fromValue(equipment.type)?.labelBn ?? equipment.type) : (EquipmentType.fromValue(equipment.type)?.labelEn ?? equipment.type)}  •  ${_fmt.format(equipment.ratePerDay)}/${_t(bn, "দিন", "day")}',
          style: const TextStyle(fontSize: 12, color: AppTheme.textSecondary),
        ),
        if (equipment.locationText != null) ...[
          const SizedBox(height: 4),
          Row(children: [
            const Icon(Icons.location_on,
                size: 12, color: AppTheme.textSecondary),
            const SizedBox(width: 4),
            Expanded(
                child: Text(equipment.locationText!,
                    style: const TextStyle(
                        fontSize: 12, color: AppTheme.textSecondary))),
          ]),
        ],
        const SizedBox(height: 10),
        Row(mainAxisAlignment: MainAxisAlignment.end, children: [
          TextButton.icon(
            onPressed: () async {
              final confirmed = await _confirmDelete(context);
              if (confirmed == true) notifier.remove(equipment.id);
            },
            icon: const Icon(Icons.delete_outline,
                size: 16, color: AppTheme.errorRed),
            label: Text(_t(bn, 'মুছুন', 'Delete'),
                style: const TextStyle(fontSize: 13, color: AppTheme.errorRed)),
            style: TextButton.styleFrom(
                padding:
                    const EdgeInsets.symmetric(horizontal: 8, vertical: 4)),
          ),
        ]),
      ]),
    );
  }

  Future<bool?> _confirmDelete(BuildContext context) {
    return showDialog<bool>(
      context: context,
      builder: (_) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: Text(_t(bn, 'সরঞ্জাম মুছবেন?', 'Delete Equipment?')),
        content: Text(bn
            ? '${equipment.name} তালিকা থেকে স্থায়ীভাবে সরিয়ে দেওয়া হবে।'
            : '${equipment.name} will be permanently removed.'),
        actions: [
          TextButton(
              onPressed: () => Navigator.pop(context, false),
              child: Text(_t(bn, 'বাতিল', 'Cancel'),
                  style: const TextStyle(color: AppTheme.textSecondary))),
          TextButton(
              onPressed: () => Navigator.pop(context, true),
              child: Text(_t(bn, 'মুছুন', 'Delete'),
                  style: const TextStyle(color: AppTheme.errorRed))),
        ],
      ),
    );
  }
}

class _OwnerBookingsList extends ConsumerWidget {
  final bool bn;
  const _OwnerBookingsList({required this.bn});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final bookingsAsync = ref.watch(ownerBookingsProvider);
    return bookingsAsync.when(
      loading: () => const Center(child: CircularProgressIndicator()),
      error: (e, _) => _ErrorView(
          message:
              _t(bn, 'বুকিং লোড করতে ব্যর্থ হয়েছে', 'Failed to load bookings'),
          onRetry: () => ref.read(ownerBookingsProvider.notifier).refresh()),
      data: (bookings) {
        if (bookings.isEmpty) {
          return _EmptyView(
              icon: Icons.event_note_outlined,
              message:
                  _t(bn, 'আপনার সরঞ্জামে কোনো বুকিং নেই', 'No bookings yet'));
        }
        return RefreshIndicator(
          color: AppTheme.primaryGreen,
          onRefresh: () => ref.read(ownerBookingsProvider.notifier).refresh(),
          child: ListView.builder(
              padding: const EdgeInsets.all(16),
              itemCount: bookings.length,
              itemBuilder: (_, i) =>
                  _OwnerBookingCard(booking: bookings[i], bn: bn)),
        );
      },
    );
  }
}

class _OwnerBookingCard extends ConsumerWidget {
  final BookingModel booking;
  final bool bn;
  const _OwnerBookingCard({required this.booking, required this.bn});

  static final _dateFmt = DateFormat('d MMM yyyy');
  static final _currFmt =
      NumberFormat.currency(locale: 'en_BD', symbol: '৳', decimalDigits: 0);

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final notifier = ref.read(ownerBookingsProvider.notifier);
    final status = BookingStatus.fromValue(booking.status);
    final payment = PaymentStatus.fromValue(booking.paymentStatus);

    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: AppTheme.borderGrey)),
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Row(children: [
          Expanded(
              child: Text(booking.equipment?.name ?? '—',
                  style: const TextStyle(
                      fontSize: 15, fontWeight: FontWeight.w700))),
          _StatusChip(status: status, bn: bn),
        ]),
        const SizedBox(height: 6),
        Text(
            '${_dateFmt.format(booking.startDate)} → ${_dateFmt.format(booking.endDate)}  (${booking.durationDays} ${_t(bn, "দিন", "days")})',
            style:
                const TextStyle(fontSize: 12, color: AppTheme.textSecondary)),
        const SizedBox(height: 2),
        Row(children: [
          Text(_currFmt.format(booking.totalCost),
              style: const TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.w700,
                  color: AppTheme.primaryGreen)),
          const SizedBox(width: 8),
          _PaymentChip(status: payment, bn: bn),
        ]),
        if (booking.notes != null) ...[
          const SizedBox(height: 6),
          Text(booking.notes!,
              style: const TextStyle(
                  fontSize: 12,
                  color: AppTheme.textSecondary,
                  fontStyle: FontStyle.italic)),
        ],
        if (status == BookingStatus.pending) ...[
          const SizedBox(height: 10),
          Row(children: [
            _ActionButton(
                label: _t(bn, 'নিশ্চিত করুন', 'Confirm'),
                color: AppTheme.primaryGreen,
                onTap: () => notifier.updateStatus(
                    bookingId: booking.id,
                    status: BookingStatus.confirmed.value)),
            const SizedBox(width: 8),
            _ActionButton(
                label: _t(bn, 'বাতিল', 'Cancel'),
                color: AppTheme.errorRed,
                onTap: () => notifier.updateStatus(
                    bookingId: booking.id,
                    status: BookingStatus.cancelled.value)),
          ]),
        ],
        if (status == BookingStatus.confirmed) ...[
          const SizedBox(height: 10),
          _ActionButton(
              label: _t(bn, 'সক্রিয় করুন', 'Activate'),
              color: AppTheme.primaryGreen,
              onTap: () => notifier.updateStatus(
                  bookingId: booking.id, status: BookingStatus.active.value)),
        ],
        if (status == BookingStatus.active) ...[
          const SizedBox(height: 10),
          _ActionButton(
              label: _t(bn, 'সম্পন্ন করুন', 'Mark Complete'),
              color: AppTheme.darkGreen,
              onTap: () => notifier.updateStatus(
                  bookingId: booking.id,
                  status: BookingStatus.completed.value)),
        ],
      ]),
    );
  }
}

// ===========================================================================
// ADD EQUIPMENT SHEET (unchanged internally — receives bn from parent)
// ===========================================================================
class _AddEquipmentSheet extends ConsumerStatefulWidget {
  final bool bn;
  const _AddEquipmentSheet({required this.bn});

  @override
  ConsumerState<_AddEquipmentSheet> createState() => _AddEquipmentSheetState();
}

class _AddEquipmentSheetState extends ConsumerState<_AddEquipmentSheet> {
  final _nameCtrl = TextEditingController();
  final _descCtrl = TextEditingController();
  final _rateCtrl = TextEditingController();
  final _locationCtrl = TextEditingController();
  int _minDays = 1;
  EquipmentType _type = EquipmentType.tractor;
  String? _division;
  bool _isLoading = false;
  LatLng? _pickedLatLng;
  bool _locationSearching = false;
  bool _locationMapVisible = false;
  GoogleMapController? _locationMapCtrl;
  Set<Marker> _locationMarkers = {};
  final List<XFile> _pickedImages = [];
  static const int _maxImages = 4;

  bool get bn => widget.bn;

  void _listen() => setState(() {});

  @override
  void initState() {
    super.initState();
    _nameCtrl.addListener(_listen);
    _rateCtrl.addListener(_listen);
  }

  @override
  void dispose() {
    _nameCtrl.removeListener(_listen);
    _rateCtrl.removeListener(_listen);
    _nameCtrl.dispose();
    _descCtrl.dispose();
    _rateCtrl.dispose();
    _locationCtrl.dispose();
    _locationMapCtrl?.dispose();
    super.dispose();
  }

  Future<void> _searchLocation() async {
    final query = _locationCtrl.text.trim();
    if (query.isEmpty) return;
    setState(() => _locationSearching = true);
    try {
      final fullQuery =
          query.contains('Bangladesh') ? query : '$query, Bangladesh';
      final coords = await _geocodeLocation(fullQuery);
      if (!mounted) return;
      if (coords != null) {
        final marker = Marker(
          markerId: const MarkerId('equipment_location'),
          position: coords,
          draggable: true,
          infoWindow: InfoWindow(title: query),
          onDragEnd: (newPos) => setState(() {
            _pickedLatLng = newPos;
            _locationMarkers = {
              Marker(
                  markerId: const MarkerId('equipment_location'),
                  position: newPos,
                  draggable: true,
                  onDragEnd: (p) => setState(() {
                        _pickedLatLng = p;
                      }))
            };
          }),
        );
        setState(() {
          _pickedLatLng = coords;
          _locationMapVisible = true;
          _locationMarkers = {marker};
        });
        _locationMapCtrl?.animateCamera(CameraUpdate.newCameraPosition(
            CameraPosition(target: coords, zoom: 14)));
      } else {
        if (!mounted) return;
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(
          content: Text(
              _t(bn, 'অবস্থান খুঁজে পাওয়া যায়নি।', 'Location not found.')),
          backgroundColor: AppTheme.errorRed,
        ));
      }
    } finally {
      if (mounted) setState(() => _locationSearching = false);
    }
  }

  void _onMapTap(LatLng pos) {
    setState(() {
      _pickedLatLng = pos;
      _locationMarkers = {
        Marker(
            markerId: const MarkerId('equipment_location'),
            position: pos,
            draggable: true,
            onDragEnd: (p) => setState(() {
                  _pickedLatLng = p;
                }))
      };
    });
  }

  bool get _isValid =>
      _nameCtrl.text.trim().isNotEmpty &&
      _rateCtrl.text.trim().isNotEmpty &&
      double.tryParse(_rateCtrl.text.trim()) != null;

  Future<void> _pickImages() async {
    final remaining = _maxImages - _pickedImages.length;
    if (remaining <= 0) return;
    final picked = await ImagePicker().pickMultiImage(imageQuality: 80);
    if (picked.isEmpty) return;
    setState(() => _pickedImages.addAll(picked.take(remaining)));
  }

  void _removeImage(int index) => setState(() => _pickedImages.removeAt(index));

  Future<void> _submit() async {
    if (!_isValid) return;
    setState(() => _isLoading = true);
    try {
      final imageUrls = <String>[];
      if (!kIsWeb && _pickedImages.isNotEmpty) {
        for (final xfile in _pickedImages) {
          final url =
              await SupabaseService.instance.uploadEquipmentImage(xfile.path);
          imageUrls.add(url);
        }
      }
      await ref.read(myEquipmentProvider.notifier).addEquipment(
            name: _nameCtrl.text.trim(),
            description:
                _descCtrl.text.trim().isEmpty ? null : _descCtrl.text.trim(),
            type: _type.value,
            ratePerDay: double.parse(_rateCtrl.text.trim()),
            minBookingDays: _minDays,
            division: _division,
            locationText: _locationCtrl.text.trim().isEmpty
                ? null
                : _locationCtrl.text.trim(),
            images: imageUrls,
          );
      if (!mounted) return;
      Navigator.pop(context);
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(
        content:
            Text('${_t(bn, "যোগ করতে ব্যর্থ হয়েছে", "Failed to add")}: $e'),
        backgroundColor: AppTheme.errorRed,
      ));
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: const BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.vertical(top: Radius.circular(24))),
      padding: EdgeInsets.only(
          left: 20,
          right: 20,
          top: 20,
          bottom: MediaQuery.of(context).viewInsets.bottom + 24),
      child: SingleChildScrollView(
        child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              Center(
                  child: Container(
                      width: 40,
                      height: 4,
                      decoration: BoxDecoration(
                          color: AppTheme.borderGrey,
                          borderRadius: BorderRadius.circular(2)))),
              const SizedBox(height: 16),
              Text(_t(bn, 'নতুন সরঞ্জাম যোগ করুন', 'Add New Equipment'),
                  style: const TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.w700,
                      color: AppTheme.darkGreen)),
              const SizedBox(height: 20),
              _SheetField(
                  controller: _nameCtrl,
                  label: _t(bn, 'সরঞ্জামের নাম *', 'Equipment Name *')),
              const SizedBox(height: 12),
              Text(_t(bn, 'ধরন *', 'Type *'),
                  style: const TextStyle(
                      fontSize: 13,
                      color: AppTheme.textSecondary,
                      fontWeight: FontWeight.w500)),
              const SizedBox(height: 6),
              Wrap(
                  spacing: 8,
                  children: EquipmentType.values.map((t) {
                    final selected = _type == t;
                    return ChoiceChip(
                      label: Text(bn ? t.labelBn : t.labelEn),
                      selected: selected,
                      selectedColor:
                          AppTheme.primaryGreen.withValues(alpha: 0.15),
                      onSelected: (_) => setState(() => _type = t),
                      labelStyle: TextStyle(
                          color: selected
                              ? AppTheme.darkGreen
                              : AppTheme.textSecondary,
                          fontWeight:
                              selected ? FontWeight.w700 : FontWeight.normal),
                      side: BorderSide(
                          color: selected
                              ? AppTheme.primaryGreen
                              : AppTheme.borderGrey),
                    );
                  }).toList()),
              const SizedBox(height: 12),
              _SheetField(
                  controller: _rateCtrl,
                  label: _t(bn, 'প্রতিদিনের ভাড়া (৳) *', 'Daily Rate (৳) *'),
                  keyboardType:
                      const TextInputType.numberWithOptions(decimal: true)),
              const SizedBox(height: 12),
              Row(children: [
                Text(_t(bn, 'সর্বনিম্ন বুকিং দিন', 'Minimum Booking Days'),
                    style: const TextStyle(
                        fontSize: 13, color: AppTheme.textSecondary)),
                const Spacer(),
                _StepButton(
                    icon: Icons.remove,
                    onTap: () {
                      if (_minDays > 1) setState(() => _minDays--);
                    }),
                Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 12),
                    child: Text('$_minDays',
                        style: const TextStyle(
                            fontSize: 16, fontWeight: FontWeight.w700))),
                _StepButton(
                    icon: Icons.add, onTap: () => setState(() => _minDays++)),
              ]),
              const SizedBox(height: 12),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 12),
                decoration: BoxDecoration(
                    border: Border.all(color: AppTheme.borderGrey),
                    borderRadius: BorderRadius.circular(10)),
                child: DropdownButtonHideUnderline(
                  child: DropdownButton<String>(
                    hint: Text(_t(bn, 'বিভাগ (ঐচ্ছিক)', 'Division (optional)'),
                        style: const TextStyle(
                            fontSize: 14, color: AppTheme.textSecondary)),
                    value: _division,
                    isExpanded: true,
                    items: kBangladeshDivisions
                        .map((d) => DropdownMenuItem(value: d, child: Text(d)))
                        .toList(),
                    onChanged: (v) => setState(() => _division = v),
                  ),
                ),
              ),
              const SizedBox(height: 12),
              Text(_t(bn, 'অবস্থান *', 'Location *'),
                  style: const TextStyle(
                      fontSize: 13,
                      color: AppTheme.textSecondary,
                      fontWeight: FontWeight.w500)),
              const SizedBox(height: 6),
              Row(children: [
                Expanded(
                  child: TextField(
                    controller: _locationCtrl,
                    style: const TextStyle(fontSize: 14),
                    onSubmitted: (_) => _searchLocation(),
                    decoration: InputDecoration(
                      hintText: _t(bn, 'উপজেলা বা গ্রামের নাম লিখুন...',
                          'Enter upazila or village name...'),
                      hintStyle: const TextStyle(
                          fontSize: 13, color: AppTheme.textSecondary),
                      filled: true,
                      fillColor: Colors.white,
                      contentPadding: const EdgeInsets.symmetric(
                          horizontal: 12, vertical: 12),
                      border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(10),
                          borderSide:
                              const BorderSide(color: AppTheme.borderGrey)),
                      enabledBorder: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(10),
                          borderSide:
                              const BorderSide(color: AppTheme.borderGrey)),
                      focusedBorder: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(10),
                          borderSide: const BorderSide(
                              color: AppTheme.primaryGreen, width: 1.5)),
                    ),
                  ),
                ),
                const SizedBox(width: 8),
                GestureDetector(
                  onTap: _locationSearching ? null : _searchLocation,
                  child: Container(
                    height: 48,
                    width: 48,
                    decoration: BoxDecoration(
                        color: AppTheme.primaryGreen,
                        borderRadius: BorderRadius.circular(10)),
                    child: _locationSearching
                        ? const Center(
                            child: SizedBox(
                                width: 20,
                                height: 20,
                                child: CircularProgressIndicator(
                                    color: Colors.white, strokeWidth: 2)))
                        : const Icon(Icons.search,
                            color: Colors.white, size: 22),
                  ),
                ),
              ]),
              if (_pickedLatLng != null) ...[
                const SizedBox(height: 8),
                Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 10, vertical: 7),
                  decoration: BoxDecoration(
                      color: AppTheme.primaryGreen.withValues(alpha: 0.08),
                      borderRadius: BorderRadius.circular(8),
                      border: Border.all(
                          color: AppTheme.primaryGreen.withValues(alpha: 0.3))),
                  child: Row(children: [
                    const Icon(Icons.check_circle,
                        size: 14, color: AppTheme.primaryGreen),
                    const SizedBox(width: 6),
                    Expanded(
                        child: Text(
                            _t(bn, 'পিন সেট করা হয়েছে — মানচিত্রে টেনে সরান',
                                'Pin set — drag on map to fine-tune'),
                            style: const TextStyle(
                                fontSize: 11,
                                color: AppTheme.darkGreen,
                                fontWeight: FontWeight.w500))),
                    GestureDetector(
                        onTap: () => setState(() {
                              _pickedLatLng = null;
                              _locationMapVisible = false;
                              _locationMarkers = {};
                              _locationCtrl.clear();
                            }),
                        child: const Icon(Icons.close,
                            size: 14, color: AppTheme.textSecondary)),
                  ]),
                ),
              ],
              if (_locationMapVisible && _pickedLatLng != null) ...[
                const SizedBox(height: 10),
                ClipRRect(
                    borderRadius: BorderRadius.circular(12),
                    child: SizedBox(
                        height: 200,
                        child: GoogleMap(
                          initialCameraPosition:
                              CameraPosition(target: _pickedLatLng!, zoom: 14),
                          markers: _locationMarkers,
                          onTap: _onMapTap,
                          onMapCreated: (c) {
                            _locationMapCtrl = c;
                          },
                          myLocationButtonEnabled: false,
                          zoomControlsEnabled: false,
                          mapToolbarEnabled: false,
                        ))),
                Padding(
                    padding: const EdgeInsets.only(top: 6),
                    child: Text(
                        _t(
                            bn,
                            'মানচিত্রে ট্যাপ করুন বা পিন টেনে সঠিক অবস্থান সেট করুন',
                            'Tap on map or drag the pin to set exact location'),
                        style: const TextStyle(
                            fontSize: 11, color: AppTheme.textSecondary))),
              ],
              const SizedBox(height: 12),
              _SheetField(
                  controller: _descCtrl,
                  label: _t(bn, 'বিবরণ (ঐচ্ছিক)', 'Description (optional)'),
                  maxLines: 3),
              const SizedBox(height: 16),
              Text(_t(bn, 'ছবি যোগ করুন (ঐচ্ছিক)', 'Add Photos (optional)'),
                  style: const TextStyle(
                      fontSize: 13,
                      color: AppTheme.textSecondary,
                      fontWeight: FontWeight.w500)),
              const SizedBox(height: 8),
              SizedBox(
                  height: 90,
                  child: ListView(scrollDirection: Axis.horizontal, children: [
                    ..._pickedImages.asMap().entries.map((entry) {
                      return Stack(children: [
                        FutureBuilder<Uint8List>(
                          future: entry.value.readAsBytes(),
                          builder: (context, snap) {
                            if (!snap.hasData) {
                              return Container(
                                  width: 90,
                                  height: 90,
                                  margin: const EdgeInsets.only(right: 8),
                                  decoration: BoxDecoration(
                                      color: AppTheme.primaryGreen
                                          .withValues(alpha: 0.1),
                                      borderRadius: BorderRadius.circular(10),
                                      border: Border.all(
                                          color: AppTheme.borderGrey)),
                                  child: const Center(
                                      child: CircularProgressIndicator(
                                          strokeWidth: 2)));
                            }
                            return Container(
                                width: 90,
                                height: 90,
                                margin: const EdgeInsets.only(right: 8),
                                decoration: BoxDecoration(
                                    borderRadius: BorderRadius.circular(10),
                                    border:
                                        Border.all(color: AppTheme.borderGrey),
                                    image: DecorationImage(
                                        image: MemoryImage(snap.data!),
                                        fit: BoxFit.cover)));
                          },
                        ),
                        Positioned(
                            top: 2,
                            right: 10,
                            child: GestureDetector(
                                onTap: () => _removeImage(entry.key),
                                child: Container(
                                    padding: const EdgeInsets.all(2),
                                    decoration: const BoxDecoration(
                                        color: Colors.white,
                                        shape: BoxShape.circle),
                                    child: const Icon(Icons.close,
                                        size: 14, color: AppTheme.errorRed)))),
                      ]);
                    }),
                    if (_pickedImages.length < _maxImages)
                      GestureDetector(
                        onTap: _pickImages,
                        child: Container(
                          width: 90,
                          height: 90,
                          decoration: BoxDecoration(
                              color:
                                  AppTheme.primaryGreen.withValues(alpha: 0.07),
                              borderRadius: BorderRadius.circular(10),
                              border: Border.all(
                                  color: AppTheme.primaryGreen
                                      .withValues(alpha: 0.4))),
                          child: Column(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                Icon(Icons.add_a_photo_outlined,
                                    color: AppTheme.primaryGreen
                                        .withValues(alpha: 0.8),
                                    size: 26),
                                const SizedBox(height: 4),
                                Text('${_pickedImages.length}/$_maxImages',
                                    style: TextStyle(
                                        fontSize: 11,
                                        color: AppTheme.primaryGreen
                                            .withValues(alpha: 0.8))),
                              ]),
                        ),
                      ),
                  ])),
              const SizedBox(height: 24),
              SizedBox(
                width: double.infinity,
                height: 50,
                child: ElevatedButton(
                  onPressed: (_isValid && !_isLoading) ? _submit : null,
                  style: ElevatedButton.styleFrom(
                      backgroundColor: AppTheme.primaryGreen,
                      foregroundColor: Colors.white,
                      disabledBackgroundColor:
                          AppTheme.primaryGreen.withValues(alpha: 0.4),
                      shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12)),
                      elevation: 0),
                  child: _isLoading
                      ? const SizedBox(
                          width: 20,
                          height: 20,
                          child: CircularProgressIndicator(
                              color: Colors.white, strokeWidth: 2.5))
                      : Text(_t(bn, 'সরঞ্জাম যোগ করুন', 'Add Equipment'),
                          style: const TextStyle(
                              fontSize: 16, fontWeight: FontWeight.w700)),
                ),
              ),
            ]),
      ),
    );
  }
}

// ---------------------------------------------------------------------------
// Shared small widgets
// ---------------------------------------------------------------------------
class _SheetField extends StatelessWidget {
  final TextEditingController controller;
  final String label;
  final TextInputType? keyboardType;
  final int maxLines;
  const _SheetField(
      {required this.controller,
      required this.label,
      this.keyboardType,
      this.maxLines = 1});

  @override
  Widget build(BuildContext context) {
    return TextField(
      controller: controller,
      keyboardType: keyboardType,
      maxLines: maxLines,
      style: const TextStyle(fontSize: 14),
      decoration: InputDecoration(
        labelText: label,
        labelStyle:
            const TextStyle(fontSize: 13, color: AppTheme.textSecondary),
        filled: true,
        fillColor: Colors.white,
        border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(10),
            borderSide: const BorderSide(color: AppTheme.borderGrey)),
        enabledBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(10),
            borderSide: const BorderSide(color: AppTheme.borderGrey)),
        focusedBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(10),
            borderSide:
                const BorderSide(color: AppTheme.primaryGreen, width: 1.5)),
        contentPadding:
            const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
      ),
    );
  }
}

class _StepButton extends StatelessWidget {
  final IconData icon;
  final VoidCallback onTap;
  const _StepButton({required this.icon, required this.onTap});
  @override
  Widget build(BuildContext context) {
    return GestureDetector(
        onTap: onTap,
        child: Container(
            padding: const EdgeInsets.all(6),
            decoration: BoxDecoration(
                border: Border.all(color: AppTheme.borderGrey),
                borderRadius: BorderRadius.circular(6)),
            child: Icon(icon, size: 16, color: AppTheme.darkGreen)));
  }
}

class _StatusChip extends StatelessWidget {
  final BookingStatus status;
  final bool bn;
  const _StatusChip({required this.status, required this.bn});
  Color get _color {
    switch (status) {
      case BookingStatus.pending:
        return Colors.orange;
      case BookingStatus.confirmed:
        return Colors.blue;
      case BookingStatus.active:
        return AppTheme.primaryGreen;
      case BookingStatus.completed:
        return AppTheme.darkGreen;
      case BookingStatus.cancelled:
        return AppTheme.errorRed;
    }
  }

  @override
  Widget build(BuildContext context) {
    return Container(
        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
        decoration: BoxDecoration(
            color: _color.withValues(alpha: 0.12),
            borderRadius: BorderRadius.circular(6),
            border: Border.all(color: _color.withValues(alpha: 0.4))),
        child: Text(bn ? status.labelBn : status.labelEn,
            style: TextStyle(
                fontSize: 11, fontWeight: FontWeight.w700, color: _color)));
  }
}

class _PaymentChip extends StatelessWidget {
  final PaymentStatus status;
  final bool bn;
  const _PaymentChip({required this.status, required this.bn});
  @override
  Widget build(BuildContext context) {
    final color = status == PaymentStatus.paid
        ? AppTheme.primaryGreen
        : status == PaymentStatus.refunded
            ? Colors.blue
            : Colors.orange;
    return Container(
        padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
        decoration: BoxDecoration(
            color: color.withValues(alpha: 0.1),
            borderRadius: BorderRadius.circular(4)),
        child: Text(bn ? status.labelBn : status.labelEn,
            style: TextStyle(
                fontSize: 10, fontWeight: FontWeight.w600, color: color)));
  }
}

class _ActionButton extends StatelessWidget {
  final String label;
  final Color color;
  final VoidCallback onTap;
  const _ActionButton(
      {required this.label, required this.color, required this.onTap});
  @override
  Widget build(BuildContext context) {
    return GestureDetector(
        onTap: onTap,
        child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 7),
            decoration: BoxDecoration(
                color: color.withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(8),
                border: Border.all(color: color.withValues(alpha: 0.4))),
            child: Text(label,
                style: TextStyle(
                    fontSize: 13, fontWeight: FontWeight.w700, color: color))));
  }
}

class _ErrorView extends StatelessWidget {
  final String message;
  final VoidCallback onRetry;
  const _ErrorView({required this.message, required this.onRetry});
  @override
  Widget build(BuildContext context) {
    final isBn = message.contains(RegExp(r'[\u0980-\u09FF]'));
    return Center(
        child: Column(mainAxisSize: MainAxisSize.min, children: [
      const Icon(Icons.error_outline, size: 48, color: AppTheme.errorRed),
      const SizedBox(height: 12),
      Text(message, style: const TextStyle(color: AppTheme.textSecondary)),
      const SizedBox(height: 12),
      ElevatedButton(
          onPressed: onRetry,
          style: ElevatedButton.styleFrom(
              backgroundColor: AppTheme.primaryGreen,
              foregroundColor: Colors.white),
          child: Text(isBn ? 'আবার চেষ্টা করুন' : 'Try Again')),
    ]));
  }
}

class _EmptyView extends StatelessWidget {
  final IconData icon;
  final String message;
  const _EmptyView({required this.icon, required this.message});
  @override
  Widget build(BuildContext context) {
    return Center(
        child: Column(mainAxisSize: MainAxisSize.min, children: [
      Icon(icon, size: 56, color: AppTheme.borderGrey),
      const SizedBox(height: 12),
      Text(message,
          textAlign: TextAlign.center,
          style: const TextStyle(color: AppTheme.textSecondary, height: 1.5)),
    ]));
  }
}
