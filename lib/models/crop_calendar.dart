// lib/models/crop_calendar.dart
// Krishok App — CropCalendar model
// Maps to the `crop_calendar` Supabase table
// Handles ARRAY[1,2,3] type parsing from PostgreSQL

import 'package:flutter/foundation.dart';

// ─── Month helpers ───────────────────────────────────────────────────────────

const List<String> _monthNamesEn = [
  '',
  'January',
  'February',
  'March',
  'April',
  'May',
  'June',
  'July',
  'August',
  'September',
  'October',
  'November',
  'December',
];

const List<String> _monthNamesBn = [
  '',
  'জানুয়ারি',
  'ফেব্রুয়ারি',
  'মার্চ',
  'এপ্রিল',
  'মে',
  'জুন',
  'জুলাই',
  'আগস্ট',
  'সেপ্টেম্বর',
  'অক্টোবর',
  'নভেম্বর',
  'ডিসেম্বর',
];

const List<String> _monthShortBn = [
  '',
  'জান',
  'ফেব',
  'মার',
  'এপ্র',
  'মে',
  'জুন',
  'জুল',
  'আগ',
  'সেপ',
  'অক্ট',
  'নভ',
  'ডিস',
];

const List<String> _monthShortEn = [
  '',
  'Jan',
  'Feb',
  'Mar',
  'Apr',
  'May',
  'Jun',
  'Jul',
  'Aug',
  'Sep',
  'Oct',
  'Nov',
  'Dec',
];

String monthNameBn(int m) => (m >= 1 && m <= 12) ? _monthNamesBn[m] : '';
String monthNameEn(int m) => (m >= 1 && m <= 12) ? _monthNamesEn[m] : '';
String monthShortBn(int m) => (m >= 1 && m <= 12) ? _monthShortBn[m] : '';
String monthShortEn(int m) => (m >= 1 && m <= 12) ? _monthShortEn[m] : '';

/// Converts ASCII digits to Bengali Unicode digits
String toBanglaDigits(String s) {
  const digits = ['০', '১', '২', '৩', '৪', '৫', '৬', '৭', '৮', '৯'];
  return s.replaceAllMapped(
    RegExp(r'\d'),
    (m) => digits[int.parse(m.group(0)!)],
  );
}

// ─── Season ───────────────────────────────────────────────────────────────────

enum Season {
  rabi, // winter/dry
  kharif, // monsoon
  summer,
  yearRound,
}

extension SeasonLabel on Season {
  String get labelBn => switch (this) {
        Season.rabi => 'রবি মৌসুম',
        Season.kharif => 'খরিফ মৌসুম',
        Season.summer => 'গ্রীষ্মকাল',
        Season.yearRound => 'সারা বছর',
      };
  String get labelEn => switch (this) {
        Season.rabi => 'Rabi (Winter)',
        Season.kharif => 'Kharif (Monsoon)',
        Season.summer => 'Summer',
        Season.yearRound => 'Year-round',
      };
}

// ─── Category ────────────────────────────────────────────────────────────────

enum CropCategory {
  grain,
  vegetable,
  spice,
  fruit,
  oilseed,
  pulse,
  other,
}

extension CropCategoryLabel on CropCategory {
  String get labelBn => switch (this) {
        CropCategory.grain => 'শস্য',
        CropCategory.vegetable => 'সবজি',
        CropCategory.spice => 'মসলা',
        CropCategory.fruit => 'ফল',
        CropCategory.oilseed => 'তেলবীজ',
        CropCategory.pulse => 'ডাল',
        CropCategory.other => 'অন্যান্য',
      };
  String get labelEn => switch (this) {
        CropCategory.grain => 'Grain',
        CropCategory.vegetable => 'Vegetable',
        CropCategory.spice => 'Spice',
        CropCategory.fruit => 'Fruit',
        CropCategory.oilseed => 'Oilseed',
        CropCategory.pulse => 'Pulse',
        CropCategory.other => 'Other',
      };

  /// Classify crop by English name
  static CropCategory fromNames(String nameEn) {
    final n = nameEn.toLowerCase();
    if (['rice', 'wheat', 'maize', 'jute', 'sugarcane'].any(n.contains)) {
      return CropCategory.grain;
    }
    if ([
      'potato',
      'tomato',
      'cauliflower',
      'cabbage',
      'brinjal',
      'gourd',
      'okra',
      'pumpkin',
      'spinach',
      'amaranth'
    ].any(n.contains)) {
      return CropCategory.vegetable;
    }
    if (['garlic', 'onion', 'turmeric', 'ginger', 'chili', 'coriander']
        .any(n.contains)) {
      return CropCategory.spice;
    }
    if ([
      'mango',
      'banana',
      'jackfruit',
      'lychee',
      'guava',
      'watermelon',
      'papaya',
      'pineapple',
      'coconut'
    ].any(n.contains)) {
      return CropCategory.fruit;
    }
    if (['mustard', 'sesame', 'groundnut'].any(n.contains)) {
      return CropCategory.oilseed;
    }
    if (['lentil', 'chickpea', 'gram', 'bean', 'groundnut', 'mung']
        .any(n.contains)) {
      return CropCategory.pulse;
    }
    return CropCategory.other;
  }
}

// ─── CropCalendar Model ───────────────────────────────────────────────────────

@immutable
class CropCalendar {
  const CropCalendar({
    required this.id,
    required this.cropNameEn,
    required this.cropNameBn,
    this.division,
    required this.sowMonths,
    required this.harvestMonths,
    this.avgYield,
    this.notesEn,
    this.notesBn,
    this.imageUrl,
  });

  final String id;
  final String cropNameEn;
  final String cropNameBn;
  final String? division; // null = all Bangladesh
  final List<int> sowMonths; // 1–12
  final List<int> harvestMonths; // 1–12
  final String? avgYield;
  final String? notesEn;
  final String? notesBn;
  final String? imageUrl;

  // ── Derived ────────────────────────────────────────────────────────────────

  CropCategory get category => CropCategoryLabel.fromNames(cropNameEn);

  /// Heuristic season based on sow months
  Season get season {
    if (sowMonths.length >= 10) return Season.yearRound;
    final avg = sowMonths.reduce((a, b) => a + b) / sowMonths.length;
    if (avg >= 10 || avg <= 2) return Season.rabi;
    if (avg >= 6 && avg <= 9) return Season.kharif;
    return Season.summer;
  }

  /// True if this crop is sown or harvested in [month] (1-based)
  bool activeInMonth(int month) =>
      sowMonths.contains(month) || harvestMonths.contains(month);

  /// True if this crop is sown in [month]
  bool sownInMonth(int month) => sowMonths.contains(month);

  /// True if this crop is harvested in [month]
  bool harvestedInMonth(int month) => harvestMonths.contains(month);

  // ── Localised getters ──────────────────────────────────────────────────────

  String name(bool bangla) => bangla ? cropNameBn : cropNameEn;
  String? notes(bool bangla) => bangla ? notesBn : notesEn;

  String sowLabel(bool bangla) {
    if (sowMonths.isEmpty) return bangla ? 'অজানা' : 'Unknown';
    final names = sowMonths.map(
      (m) => bangla ? monthShortBn(m) : monthShortEn(m),
    );
    return names.join(', ');
  }

  String harvestLabel(bool bangla) {
    if (harvestMonths.isEmpty) return bangla ? 'অজানা' : 'Unknown';
    final names = harvestMonths.map(
      (m) => bangla ? monthShortBn(m) : monthShortEn(m),
    );
    return names.join(', ');
  }

  // ── JSON Parsing (handles ARRAY types from PostgreSQL) ──────────────────────

  /// Parse months from various input types:
  /// - List<dynamic> → [1, 2, 3]
  /// - String → "1,2,3" or "4, 5, 6"
  /// - null → []
  static List<int> _parseMonths(dynamic raw) {
    if (raw == null) return const [];

    // Already a list (Supabase returns as List<dynamic>)
    if (raw is List) {
      return raw
          .map((e) {
            if (e is int) return e;
            if (e is num) return e.toInt();
            if (e is String) return int.tryParse(e) ?? 0;
            return 0;
          })
          .where((m) => m >= 1 && m <= 12)
          .toList();
    }

    // Comma-separated string fallback
    if (raw is String) {
      return raw
          .split(',')
          .map((s) => int.tryParse(s.trim()) ?? 0)
          .where((m) => m >= 1 && m <= 12)
          .toList();
    }

    return const [];
  }

  factory CropCalendar.fromJson(Map<String, dynamic> json) {
    return CropCalendar(
      id: (json['id'] as String?) ?? 'Unknown',
      cropNameEn: (json['crop_name_en'] as String?) ?? 'Unknown',
      cropNameBn: (json['crop_name_bn'] as String?) ?? 'অজানা',
      division: json['division'] as String?,
      sowMonths: _parseMonths(json['sow_months']),
      harvestMonths: _parseMonths(json['harvest_months']),
      avgYield: json['avg_yield'] as String?,
      notesEn: json['notes_en'] as String?,
      notesBn: json['notes_bn'] as String?,
      imageUrl: json['image_url'] as String?,
    );
  }

  Map<String, dynamic> toJson() => {
        'id': id,
        'crop_name_en': cropNameEn,
        'crop_name_bn': cropNameBn,
        'division': division,
        'sow_months': sowMonths,
        'harvest_months': harvestMonths,
        'avg_yield': avgYield,
        'notes_en': notesEn,
        'notes_bn': notesBn,
        'image_url': imageUrl,
      };

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is CropCalendar &&
          runtimeType == other.runtimeType &&
          id == other.id;

  @override
  int get hashCode => id.hashCode;

  @override
  String toString() => 'CropCalendar(id: $id, en: $cropNameEn)';
}
