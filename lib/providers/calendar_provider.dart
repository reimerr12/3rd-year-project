import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../models/crop_calendar.dart';

// ─── State ────────────────────────────────────────────────────────────────────

class CalendarState {
  const CalendarState({
    required this.allCrops,
    required this.focusedYear,
    required this.focusedMonth,
    this.selectedDay,
    this.selectedCategory,
    this.isBangla = true,
  });

  final List<CropCalendar> allCrops;
  final int focusedYear;
  final int focusedMonth; // 1–12 Gregorian
  final int? selectedDay; // 1–31, day within focusedMonth
  final CropCategory? selectedCategory;
  final bool isBangla;

  // Crops sowing in focusedMonth
  List<CropCalendar> get sowingThisMonth =>
      allCrops.where((c) => c.sownInMonth(focusedMonth)).toList();

  // Crops harvesting in focusedMonth
  List<CropCalendar> get harvestingThisMonth =>
      allCrops.where((c) => c.harvestedInMonth(focusedMonth)).toList();

  // All crops active in focusedMonth
  List<CropCalendar> get activeThisMonth =>
      allCrops.where((c) => c.activeInMonth(focusedMonth)).toList();

  // Crops for the selected day (month-granularity data)
  List<CropCalendar> cropsForDay(int day) {
    if (selectedCategory != null) {
      return activeThisMonth
          .where((c) => c.category == selectedCategory)
          .toList();
    }
    return activeThisMonth;
  }

  List<CropCalendar> sowingForDay(int day) => sowingThisMonth
      .where((c) => selectedCategory == null || c.category == selectedCategory)
      .toList();

  List<CropCalendar> harvestingForDay(int day) => harvestingThisMonth
      .where((c) => selectedCategory == null || c.category == selectedCategory)
      .toList();

  CalendarState copyWith({
    List<CropCalendar>? allCrops,
    int? focusedYear,
    int? focusedMonth,
    Object? selectedDay = _s,
    Object? selectedCategory = _s,
    bool? isBangla,
  }) =>
      CalendarState(
        allCrops: allCrops ?? this.allCrops,
        focusedYear: focusedYear ?? this.focusedYear,
        focusedMonth: focusedMonth ?? this.focusedMonth,
        selectedDay: selectedDay == _s ? this.selectedDay : selectedDay as int?,
        selectedCategory: selectedCategory == _s
            ? this.selectedCategory
            : selectedCategory as CropCategory?,
        isBangla: isBangla ?? this.isBangla,
      );
}

const _s = Object();

// ─── Notifier ─────────────────────────────────────────────────────────────────

class CalendarNotifier extends AsyncNotifier<CalendarState> {
  @override
  Future<CalendarState> build() async {
    try {
      final crops = await _fetchFromSupabase();
      debugPrint('CalendarProvider: Loaded ${crops.length} crops');

      final now = DateTime.now();
      return CalendarState(
        allCrops: crops,
        focusedYear: now.year,
        focusedMonth: now.month,
        selectedDay: now.day,
      );
    } catch (e) {
      debugPrint(' CalendarProvider error: $e');
      rethrow;
    }
  }

  /// Fetch crop calendar data from Supabase
  /// Handles ARRAY type parsing for sow_months and harvest_months
  Future<List<CropCalendar>> _fetchFromSupabase() async {
    try {
      final rows = await Supabase.instance.client
          .from('crop_calendar')
          .select()
          .order('crop_name_en', ascending: true);

      if (rows.isEmpty) {
        debugPrint(' No crops found in Supabase');
        return [];
      }

      final crops = (rows as List)
          .map((r) {
            try {
              return CropCalendar.fromJson(r as Map<String, dynamic>);
            } catch (e) {
              debugPrint(' Failed to parse crop row: $r\nError: $e');
              return null;
            }
          })
          .whereType<CropCalendar>()
          .toList();
      return crops;
    } on PostgrestException catch (e) {
      debugPrint(' Supabase error: ${e.message}');
      throw Exception('Database error: ${e.message}');
    } catch (e) {
      debugPrint(' Unexpected error: $e');
      throw Exception('Failed to fetch crops: $e');
    }
  }

  /// Refresh crops from Supabase (pull-to-refresh)
  Future<void> refresh() async {
    final prev = state.valueOrNull;
    state = const AsyncLoading();
    state = await AsyncValue.guard(() async {
      final crops = await _fetchFromSupabase();
      final now = DateTime.now();
      return CalendarState(
        allCrops: crops,
        focusedYear: prev?.focusedYear ?? now.year,
        focusedMonth: prev?.focusedMonth ?? now.month,
        selectedDay: prev?.selectedDay ?? now.day,
        selectedCategory: prev?.selectedCategory,
        isBangla: prev?.isBangla ?? true,
      );
    });
  }

  /// Navigate to a specific month
  void goToMonth(int year, int month) {
    state = state.whenData((s) => s.copyWith(
          focusedYear: year,
          focusedMonth: month,
          selectedDay: null,
        ));
  }

  /// Previous month
  void previousMonth() {
    final s = state.valueOrNull;
    if (s == null) return;
    final dt = DateTime(s.focusedYear, s.focusedMonth - 1);
    goToMonth(dt.year, dt.month);
  }

  /// Next month
  void nextMonth() {
    final s = state.valueOrNull;
    if (s == null) return;
    final dt = DateTime(s.focusedYear, s.focusedMonth + 1);
    goToMonth(dt.year, dt.month);
  }

  /// Select a day
  void selectDay(int day) =>
      state = state.whenData((s) => s.copyWith(selectedDay: day));

  /// Select crop category filter
  void selectCategory(CropCategory? cat) =>
      state = state.whenData((s) => s.copyWith(selectedCategory: cat));

  /// Toggle language
  void toggleLanguage() =>
      state = state.whenData((s) => s.copyWith(isBangla: !s.isBangla));

  /// Jump to today
  void goToToday() {
    final now = DateTime.now();
    state = state.whenData((s) => s.copyWith(
          focusedYear: now.year,
          focusedMonth: now.month,
          selectedDay: now.day,
        ));
  }
}

/// Riverpod provider for calendar state
final calendarProvider = AsyncNotifierProvider<CalendarNotifier, CalendarState>(
  CalendarNotifier.new,
);
