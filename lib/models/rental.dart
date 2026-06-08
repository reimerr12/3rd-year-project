// lib/models/rental.dart
//
// NOTE: EquipmentModel and BookingModel are defined inline in
// services/supabase_service.dart — do NOT duplicate them here.
// This file holds rental-domain helpers and enums used across
// rental screens and providers.

// ---------------------------------------------------------------------------
// Equipment type constants
// ---------------------------------------------------------------------------

enum EquipmentType {
  tractor('tractor', 'ট্র্যাক্টর', 'Tractor'),
  truck('truck', 'ট্রাক', 'Truck'),
  pump('pump', 'পাম্প', 'Pump'),
  other('other', 'অন্যান্য', 'Other');

  const EquipmentType(this.value, this.labelBn, this.labelEn);
  final String value;
  final String labelBn;
  final String labelEn;

  static EquipmentType? fromValue(String? v) {
    if (v == null) return null;
    for (final t in values) {
      if (t.value == v) return t;
    }
    return null;
  }
}

// ---------------------------------------------------------------------------
// Booking status helpers
// ---------------------------------------------------------------------------

enum BookingStatus {
  pending('pending', 'অপেক্ষমান', 'Pending'),
  confirmed('confirmed', 'নিশ্চিত', 'Confirmed'),
  active('active', 'সক্রিয়', 'Active'),
  completed('completed', 'সম্পন্ন', 'Completed'),
  cancelled('cancelled', 'বাতিল', 'Cancelled');

  const BookingStatus(this.value, this.labelBn, this.labelEn);
  final String value;
  final String labelBn;
  final String labelEn;

  static BookingStatus fromValue(String v) {
    for (final s in values) {
      if (s.value == v) return s;
    }
    return BookingStatus.pending;
  }
}

// ---------------------------------------------------------------------------
// Payment status helpers
// ---------------------------------------------------------------------------

enum PaymentStatus {
  pending('pending', 'অপেক্ষমান', 'Pending'),
  paid('paid', 'পরিশোধিত', 'Paid'),
  refunded('refunded', 'ফেরত', 'Refunded');

  const PaymentStatus(this.value, this.labelBn, this.labelEn);
  final String value;
  final String labelBn;
  final String labelEn;

  static PaymentStatus fromValue(String v) {
    for (final s in values) {
      if (s.value == v) return s;
    }
    return PaymentStatus.pending;
  }
}

// ---------------------------------------------------------------------------
// Filter state — used by RentalNotifier to drive the browse tab
// ---------------------------------------------------------------------------

class RentalFilter {
  final String? division;
  final EquipmentType? type;

  const RentalFilter({this.division, this.type});

  RentalFilter copyWith({
    Object? division = _sentinel,
    Object? type = _sentinel,
  }) {
    return RentalFilter(
      division: division == _sentinel ? this.division : division as String?,
      type: type == _sentinel ? this.type : type as EquipmentType?,
    );
  }

  @override
  bool operator ==(Object other) =>
      other is RentalFilter && other.division == division && other.type == type;

  @override
  int get hashCode => Object.hash(division, type);
}

// Sentinel value used to distinguish "not passed" from null in copyWith
const _sentinel = Object();

// ---------------------------------------------------------------------------
// Bangladesh divisions list (used in filter dropdown)
// ---------------------------------------------------------------------------

const kBangladeshDivisions = [
  'Dhaka',
  'Chittagong',
  'Rajshahi',
  'Khulna',
  'Barisal',
  'Sylhet',
  'Rangpur',
  'Mymensingh',
];
