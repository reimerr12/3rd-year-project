// lib/providers/rental_provider.dart
//
// Providers
//   browseEquipmentProvider  — paginated list for the Browse tab
//   myEquipmentProvider      — owner's own listings
//   myBookingsProvider       — renter's own bookings
//   ownerBookingsProvider    — bookings on the owner's equipment
//   rentalFilterProvider     — active filter state (division + type)

import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../services/supabase_service.dart';
import '../models/rental.dart';

// ---------------------------------------------------------------------------
// Filter provider
// ---------------------------------------------------------------------------

final rentalFilterProvider =
    StateNotifierProvider<RentalFilterNotifier, RentalFilter>(
  (ref) => RentalFilterNotifier(),
);

class RentalFilterNotifier extends StateNotifier<RentalFilter> {
  RentalFilterNotifier() : super(const RentalFilter());

  void setDivision(String? division) {
    state = state.copyWith(division: division);
  }

  void setType(EquipmentType? type) {
    state = state.copyWith(type: type);
  }

  void reset() {
    state = const RentalFilter();
  }
}

// ---------------------------------------------------------------------------
// Browse tab — available equipment (filtered)
// ---------------------------------------------------------------------------

final browseEquipmentProvider =
    AsyncNotifierProvider<BrowseEquipmentNotifier, List<EquipmentModel>>(
  BrowseEquipmentNotifier.new,
);

class BrowseEquipmentNotifier extends AsyncNotifier<List<EquipmentModel>> {
  static const _pageSize = 20;
  int _page = 0;
  bool _hasMore = true;

  @override
  Future<List<EquipmentModel>> build() async {
    // Re-fetch when filter changes
    ref.watch(rentalFilterProvider);
    _page = 0;
    _hasMore = true;
    return _fetch(reset: true);
  }

  Future<List<EquipmentModel>> _fetch({bool reset = false}) async {
    final filter = ref.read(rentalFilterProvider);
    final from = reset ? 0 : _page * _pageSize;
    final to = from + _pageSize - 1;

    final results = await SupabaseService.instance.fetchEquipment(
      from: from,
      to: to,
      division: filter.division,
      type: filter.type?.value,
    );

    if (results.length < _pageSize) _hasMore = false;
    _page++;
    return results;
  }

  Future<void> refresh() async {
    state = const AsyncLoading();
    state = await AsyncValue.guard(() => _fetch(reset: true));
  }

  Future<void> loadMore() async {
    if (!_hasMore) return;
    if (state.isLoading) return;

    final current = state.valueOrNull ?? [];
    final next = await _fetch();
    state = AsyncData([...current, ...next]);
  }

  bool get hasMore => _hasMore;
}

// --------------
// -------------------------------------------------------------
// Owner tab — own equipment listings
// ---------------------------------------------------------------------------

final myEquipmentProvider =
    AsyncNotifierProvider<MyEquipmentNotifier, List<EquipmentModel>>(
  MyEquipmentNotifier.new,
);

class MyEquipmentNotifier extends AsyncNotifier<List<EquipmentModel>> {
  @override
  Future<List<EquipmentModel>> build() async {
    return SupabaseService.instance.fetchMyEquipmentListings();
  }

  Future<void> refresh() async {
    state = const AsyncLoading();
    state = await AsyncValue.guard(
      () => SupabaseService.instance.fetchMyEquipmentListings(),
    );
  }

  Future<void> addEquipment({
    required String name,
    String? description,
    required String type,
    required double ratePerDay,
    required int minBookingDays,
    String? division,
    String? locationText,
    List<String> images = const [],
  }) async {
    await SupabaseService.instance.createEquipment(
      name: name,
      description: description,
      type: type,
      ratePerDay: ratePerDay,
      minBookingDays: minBookingDays,
      division: division,
      locationText: locationText,
      images: images,
    );
    await refresh();
  }

  Future<void> toggleAvailability(String equipmentId,
      {required bool available}) async {
    await SupabaseService.instance
        .setEquipmentAvailable(equipmentId, available: available);
    await refresh();
  }

  Future<void> remove(String equipmentId) async {
    await SupabaseService.instance.deleteEquipment(equipmentId);
    await refresh();
  }
}

// ---------------------------------------------------------------------------
// Renter's bookings
// ---------------------------------------------------------------------------

final myBookingsProvider =
    AsyncNotifierProvider<MyBookingsNotifier, List<BookingModel>>(
  MyBookingsNotifier.new,
);

class MyBookingsNotifier extends AsyncNotifier<List<BookingModel>> {
  @override
  Future<List<BookingModel>> build() async {
    return SupabaseService.instance.fetchMyBookings();
  }

  Future<void> refresh() async {
    state = const AsyncLoading();
    state = await AsyncValue.guard(
      () => SupabaseService.instance.fetchMyBookings(),
    );
  }

  Future<void> cancelBooking(String bookingId) async {
    await SupabaseService.instance
        .cancelBooking(bookingId, actingAsOwner: false);
    await refresh();
  }

  Future<void> markPaid({
    required String bookingId,
    required String paymentMethod,
  }) async {
    await SupabaseService.instance.markBookingPaid(
      bookingId: bookingId,
      paymentMethod: paymentMethod,
    );
    await refresh();
  }
}

// ---------------------------------------------------------------------------
// Owner's incoming bookings
// ---------------------------------------------------------------------------

final ownerBookingsProvider =
    AsyncNotifierProvider<OwnerBookingsNotifier, List<BookingModel>>(
  OwnerBookingsNotifier.new,
);

class OwnerBookingsNotifier extends AsyncNotifier<List<BookingModel>> {
  @override
  Future<List<BookingModel>> build() async {
    return SupabaseService.instance.fetchBookingsForMyEquipment();
  }

  Future<void> refresh() async {
    state = const AsyncLoading();
    state = await AsyncValue.guard(
      () => SupabaseService.instance.fetchBookingsForMyEquipment(),
    );
  }

  Future<void> updateStatus({
    required String bookingId,
    required String status,
  }) async {
    await SupabaseService.instance.updateBookingStatus(
      bookingId: bookingId,
      status: status,
      actingAsOwner: true,
    );
    await refresh();
  }
}
