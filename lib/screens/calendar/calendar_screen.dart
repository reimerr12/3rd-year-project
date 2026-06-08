// lib/screens/calendar/calendar_screen.dart
// Krishok App — Agricultural Seasonal Calendar
// LIVE SUPABASE INTEGRATION ✅
// UI: stripped app bar (back button only), no percentages, no yellow, bottom nav

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/theme.dart';
import '../../models/crop_calendar.dart';
import '../../providers/calendar_provider.dart';
import '../../core/router.dart';

// ════════════════════════════════════════════════════════════════════════════
// BANGLA CALENDAR HELPER
// ════════════════════════════════════════════════════════════════════════════

class _BanglaHelper {
  static String digits(int n) {
    const d = ['০', '১', '২', '৩', '৪', '৫', '৬', '৭', '৮', '৯'];
    return n.toString().split('').map((c) => d[int.parse(c)]).join();
  }

  static const _bnMonths = [
    'বৈশাখ',
    'জ্যৈষ্ঠ',
    'আষাঢ়',
    'শ্রাবণ',
    'ভাদ্র',
    'আশ্বিন',
    'কার্তিক',
    'অগ্রহায়ণ',
    'পৌষ',
    'মাঘ',
    'ফাল্গুন',
    'চৈত্র',
  ];

  static Map<String, dynamic> convert(DateTime date) {
    final em = date.month;
    final ed = date.day;
    final ey = date.year;
    int bm, bd, by;

    if (em == 4 && ed >= 14) {
      bm = 1;
      bd = ed - 13;
      by = ey - 593;
    } else if (em == 5 && ed < 15) {
      bm = 1;
      bd = ed + 17;
      by = ey - 593;
    } else if (em == 5 && ed >= 15) {
      bm = 2;
      bd = ed - 14;
      by = ey - 593;
    } else if (em == 6 && ed < 15) {
      bm = 2;
      bd = ed + 16;
      by = ey - 593;
    } else if (em == 6 && ed >= 15) {
      bm = 3;
      bd = ed - 14;
      by = ey - 593;
    } else if (em == 7 && ed < 16) {
      bm = 3;
      bd = ed + 16;
      by = ey - 593;
    } else if (em == 7 && ed >= 16) {
      bm = 4;
      bd = ed - 15;
      by = ey - 593;
    } else if (em == 8 && ed < 16) {
      bm = 4;
      bd = ed + 16;
      by = ey - 593;
    } else if (em == 8 && ed >= 16) {
      bm = 5;
      bd = ed - 15;
      by = ey - 593;
    } else if (em == 9 && ed < 16) {
      bm = 5;
      bd = ed + 16;
      by = ey - 593;
    } else if (em == 9 && ed >= 16) {
      bm = 6;
      bd = ed - 15;
      by = ey - 593;
    } else if (em == 10 && ed < 16) {
      bm = 6;
      bd = ed + 15;
      by = ey - 593;
    } else if (em == 10 && ed >= 16) {
      bm = 7;
      bd = ed - 15;
      by = ey - 593;
    } else if (em == 11 && ed < 15) {
      bm = 7;
      bd = ed + 15;
      by = ey - 593;
    } else if (em == 11 && ed >= 15) {
      bm = 8;
      bd = ed - 14;
      by = ey - 593;
    } else if (em == 12 && ed < 15) {
      bm = 8;
      bd = ed + 16;
      by = ey - 593;
    } else if (em == 12 && ed >= 15) {
      bm = 9;
      bd = ed - 14;
      by = ey - 593;
    } else if (em == 1 && ed < 14) {
      bm = 9;
      bd = ed + 17;
      by = ey - 594;
    } else if (em == 1 && ed >= 14) {
      bm = 10;
      bd = ed - 13;
      by = ey - 594;
    } else if (em == 2 && ed < 13) {
      bm = 10;
      bd = ed + 18;
      by = ey - 594;
    } else if (em == 2 && ed >= 13) {
      bm = 11;
      bd = ed - 12;
      by = ey - 594;
    } else if (em == 3 && ed < 14) {
      bm = 11;
      bd = ed + 16;
      by = ey - 594;
    } else if (em == 3 && ed >= 14) {
      bm = 12;
      bd = ed - 13;
      by = ey - 594;
    } else if (em == 4 && ed < 14) {
      bm = 12;
      bd = ed + 17;
      by = ey - 594;
    } else {
      bm = 1;
      bd = 1;
      by = ey - 593;
    }

    bd = bd.clamp(1, 31);
    return {
      'day': bd,
      'month': bm,
      'year': by,
      'monthName': _bnMonths[bm - 1],
      'dayBn': digits(bd),
      'yearBn': digits(by),
    };
  }

  static String seasonBn(int m) {
    if (m >= 3 && m <= 5) return 'গ্রীষ্মকাল';
    if (m >= 6 && m <= 8) return 'বর্ষাকাল';
    if (m >= 9 && m <= 10) return 'শরৎকাল';
    if (m == 11 || m == 12) return 'হেমন্তকাল';
    return 'শীতকাল';
  }

  static String seasonEn(int m) {
    if (m >= 3 && m <= 5) return 'Grishmo · Summer';
    if (m >= 6 && m <= 8) return 'Borsha · Monsoon';
    if (m >= 9 && m <= 10) return 'Shorot · Autumn';
    if (m == 11 || m == 12) return 'Hemonto · Late Autumn';
    return 'Sheet · Winter';
  }

  static const _enDayNames = [
    'Monday',
    'Tuesday',
    'Wednesday',
    'Thursday',
    'Friday',
    'Saturday',
    'Sunday',
  ];
  static const _bnDayNames = [
    'সোমবার',
    'মঙ্গলবার',
    'বুধবার',
    'বৃহস্পতিবার',
    'শুক্রবার',
    'শনিবার',
    'রবিবার',
  ];
  static String dayEn(int weekday) => _enDayNames[weekday - 1];
  static String dayBn(int weekday) => _bnDayNames[weekday - 1];
}

// ════════════════════════════════════════════════════════════════════════════
// STATUS HELPERS
// ════════════════════════════════════════════════════════════════════════════

enum _Status { peak, harvest, cultivation, offSeason }

extension _CropStatus on CropCalendar {
  _Status statusFor(int month) {
    if (sowMonths.contains(month) && harvestMonths.contains(month)) {
      return _Status.peak;
    }
    if (harvestMonths.contains(month)) return _Status.harvest;
    if (sowMonths.contains(month)) return _Status.cultivation;
    return _Status.offSeason;
  }
}

const _statusColors = {
  _Status.peak: AppTheme.darkGreen,
  _Status.harvest: AppTheme.primaryGreen,
  _Status.cultivation: AppTheme.lightGreen,
  _Status.offSeason: Color(0xFFCCCCC5),
};

const _statusLabelsEn = {
  _Status.peak: 'Peak Season',
  _Status.harvest: 'Harvest',
  _Status.cultivation: 'Sow',
  _Status.offSeason: 'Off Season',
};

const _statusLabelsBn = {
  _Status.peak: 'ভরা মৌসুম',
  _Status.harvest: 'ফসল তোলা',
  _Status.cultivation: 'বপন',
  _Status.offSeason: 'বিশ্রাম',
};

IconData _categoryIcon(CropCategory c) => switch (c) {
      CropCategory.grain => Icons.grain,
      CropCategory.vegetable => Icons.eco_rounded,
      CropCategory.spice => Icons.local_florist_rounded,
      CropCategory.fruit => Icons.apple_rounded,
      CropCategory.oilseed => Icons.opacity_rounded,
      CropCategory.pulse => Icons.spa_rounded,
      CropCategory.other => Icons.grass_rounded,
    };

// ════════════════════════════════════════════════════════════════════════════
// SCREEN ROOT
// ════════════════════════════════════════════════════════════════════════════

class CalendarScreen extends ConsumerStatefulWidget {
  const CalendarScreen({super.key});

  @override
  ConsumerState<CalendarScreen> createState() => _CalendarScreenState();
}

class _CalendarScreenState extends ConsumerState<CalendarScreen>
    with TickerProviderStateMixin {
  // Calendar isn't a main tab — no tab is "active" in home/market/services/profile
  // We keep index 0 highlighted as Home since user came from there
  int _currentTabIndex = 0;

  late AnimationController _slideCtrl;
  late Animation<Offset> _slideAnim;
  late AnimationController _fadeCtrl;
  late Animation<double> _fadeAnim;

  @override
  void initState() {
    super.initState();
    _slideCtrl = AnimationController(
        vsync: this, duration: const Duration(milliseconds: 320));
    _fadeCtrl = AnimationController(
        vsync: this, duration: const Duration(milliseconds: 260));

    _slideAnim = Tween<Offset>(
      begin: const Offset(1, 0),
      end: Offset.zero,
    ).animate(CurvedAnimation(parent: _slideCtrl, curve: Curves.easeOutCubic));

    _fadeAnim = Tween<double>(begin: 0, end: 1)
        .animate(CurvedAnimation(parent: _fadeCtrl, curve: Curves.easeOut));

    _slideCtrl.forward();
    _fadeCtrl.forward();
  }

  @override
  void dispose() {
    _slideCtrl.dispose();
    _fadeCtrl.dispose();
    super.dispose();
  }

  void _onTabTapped(int index) {
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
      case 3:
        Navigator.pushReplacementNamed(context, AppRouter.profile);
        break;
    }
    setState(() => _currentTabIndex = index);
  }

  void _navigateMonth(int dir) {
    final notifier = ref.read(calendarProvider.notifier);
    final s = ref.read(calendarProvider).valueOrNull;
    if (s == null) return;
    final nextMonth = DateTime(s.focusedYear, s.focusedMonth + dir);
    notifier.goToMonth(nextMonth.year, nextMonth.month);

    _slideAnim = Tween<Offset>(
      begin: Offset(dir.toDouble(), 0),
      end: Offset.zero,
    ).animate(CurvedAnimation(parent: _slideCtrl, curve: Curves.easeOutCubic));
    _slideCtrl.forward(from: 0);
  }

  @override
  Widget build(BuildContext context) {
    final async = ref.watch(calendarProvider);

    return Scaffold(
      backgroundColor: AppTheme.surfaceGreen,
      bottomNavigationBar: _buildBottomNav(),
      body: async.when(
        loading: () => const _LoadingView(),
        error: (err, _) => _ErrorView(
          error: err.toString(),
          onRetry: ref.read(calendarProvider.notifier).refresh,
        ),
        data: (state) => RefreshIndicator(
          onRefresh: ref.read(calendarProvider.notifier).refresh,
          child: CustomScrollView(
            slivers: [
              _buildAppBar(state),
              SliverToBoxAdapter(child: _buildDualMonthHeader(state)),
              SliverToBoxAdapter(child: _buildSeasonBanner(state)),
              SliverToBoxAdapter(child: _buildCategoryFilter(state)),
              SliverToBoxAdapter(child: _buildCalendarCard(state)),
              SliverToBoxAdapter(child: _buildMonthCropOverview(state)),
              if (state.selectedDay != null)
                SliverToBoxAdapter(child: _buildDateDetailPanel(state)),
              const SliverToBoxAdapter(child: SizedBox(height: 40)),
            ],
          ),
        ),
      ),
    );
  }

  // ─── BOTTOM NAV — matches home_screen.dart exactly ───────────────────────

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
                icon: Icon(Icons.miscellaneous_services_outlined),
                label: 'সেবা'),
            BottomNavigationBarItem(
                icon: Icon(Icons.person_outline), label: 'প্রোফাইল'),
          ],
        ),
      ),
    );
  }

  // ─── 1. APP BAR ───────────────────────────────────────────────────────────

  Widget _buildAppBar(CalendarState state) {
    return SliverAppBar(
      pinned: true,
      elevation: 0,
      backgroundColor: AppTheme.primaryGreen,
      systemOverlayStyle: SystemUiOverlayStyle.light,
      automaticallyImplyLeading: false,
      title: Row(
        children: [
          IconButton(
            onPressed: () =>
                Navigator.pushReplacementNamed(context, AppRouter.home),
            icon: Container(
              padding: const EdgeInsets.all(6),
              decoration: BoxDecoration(
                color: Colors.white.withValues(alpha: 0.18),
                shape: BoxShape.circle,
                border: Border.all(
                    color: Colors.white.withValues(alpha: 0.35), width: 1),
              ),
              child: const Icon(Icons.arrow_back_ios_new_rounded,
                  color: Colors.white, size: 16),
            ),
          ),
          const Spacer(),
          GestureDetector(
            onTap: () => ref.read(calendarProvider.notifier).toggleLanguage(),
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
              decoration: BoxDecoration(
                color: Colors.white.withValues(alpha: 0.18),
                borderRadius: BorderRadius.circular(20),
                border: Border.all(
                    color: Colors.white.withValues(alpha: 0.35), width: 1),
              ),
              child: Text(
                state.isBangla ? 'EN' : 'বাং',
                style: const TextStyle(
                  color: Colors.white,
                  fontWeight: FontWeight.w700,
                  fontSize: 12,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  // ─── 2. DUAL MONTH HEADER ─────────────────────────────────────────────────

  Widget _buildDualMonthHeader(CalendarState state) {
    final b1 = _BanglaHelper.convert(
        DateTime(state.focusedYear, state.focusedMonth, 1));
    final lastDay =
        DateUtils.getDaysInMonth(state.focusedYear, state.focusedMonth);
    final b2 = _BanglaHelper.convert(
        DateTime(state.focusedYear, state.focusedMonth, lastDay));

    final sameMonth = b1['month'] == b2['month'];
    final banglaLabel = sameMonth
        ? '${b1['monthName']} ${b1['yearBn']} বঙ্গাব্দ'
        : '${b1['monthName']} – ${b2['monthName']} ${b2['yearBn']} বঙ্গাব্দ';

    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 14, 20, 0),
      child: Container(
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(16),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.05),
              blurRadius: 10,
              offset: const Offset(0, 3),
            ),
          ],
        ),
        child: Row(
          children: [
            IconButton(
              onPressed: () => _navigateMonth(-1),
              icon: Container(
                padding: const EdgeInsets.all(6),
                decoration: const BoxDecoration(
                  color: AppTheme.bgLight,
                  shape: BoxShape.circle,
                ),
                child: const Icon(Icons.chevron_left_rounded,
                    color: AppTheme.primaryGreen, size: 20),
              ),
            ),
            Expanded(
              child: Column(
                children: [
                  Text(
                    state.isBangla
                        ? '${_monthNameBn(state.focusedMonth)} ${_BanglaHelper.digits(state.focusedYear)}'
                        : '${_monthNameEn(state.focusedMonth)} ${state.focusedYear}',
                    style: const TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.w900,
                      color: Color(0xFF1B4332),
                      letterSpacing: 0.2,
                    ),
                    textAlign: TextAlign.center,
                  ),
                  const SizedBox(height: 4),
                  Container(
                    padding:
                        const EdgeInsets.symmetric(horizontal: 10, vertical: 3),
                    decoration: BoxDecoration(
                      color: AppTheme.bgLight,
                      borderRadius: BorderRadius.circular(20),
                    ),
                    child: Text(
                      banglaLabel,
                      style: const TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.w700,
                        color: AppTheme.primaryGreen,
                      ),
                      textAlign: TextAlign.center,
                    ),
                  ),
                  const SizedBox(height: 8),
                ],
              ),
            ),
            IconButton(
              onPressed: () => _navigateMonth(1),
              icon: Container(
                padding: const EdgeInsets.all(6),
                decoration: const BoxDecoration(
                  color: AppTheme.bgLight,
                  shape: BoxShape.circle,
                ),
                child: const Icon(Icons.chevron_right_rounded,
                    color: AppTheme.primaryGreen, size: 20),
              ),
            ),
          ],
        ),
      ),
    );
  }

  // ─── 3. SEASON BANNER ────────────────────────────────────────────────────

  Widget _buildSeasonBanner(CalendarState state) {
    final cropCount = state.activeThisMonth.length;
    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 12, 20, 0),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        decoration: BoxDecoration(
          gradient: const LinearGradient(
            colors: [AppTheme.lightGreen, AppTheme.primaryGreen],
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
          borderRadius: BorderRadius.circular(14),
          boxShadow: [
            BoxShadow(
              color: AppTheme.primaryGreen.withValues(alpha: 0.25),
              blurRadius: 10,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        child: Row(
          children: [
            Expanded(
              child: Text(
                state.isBangla
                    ? _BanglaHelper.seasonBn(state.focusedMonth)
                    : _BanglaHelper.seasonEn(state.focusedMonth),
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 16,
                  fontWeight: FontWeight.w800,
                ),
              ),
            ),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
              decoration: BoxDecoration(
                color: Colors.white.withValues(alpha: 0.15),
                borderRadius: BorderRadius.circular(10),
              ),
              child: Column(
                children: [
                  Text(
                    state.isBangla
                        ? _BanglaHelper.digits(cropCount)
                        : '$cropCount',
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 24,
                      fontWeight: FontWeight.w900,
                    ),
                  ),
                  Text(
                    state.isBangla ? 'সক্রিয়\nফসল' : 'Active\nCrops',
                    style: const TextStyle(color: Colors.white70, fontSize: 10),
                    textAlign: TextAlign.center,
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  // ─── 4. CATEGORY FILTER ──────────────────────────────────────────────────

  Widget _buildCategoryFilter(CalendarState state) {
    final cats = [
      null,
      CropCategory.grain,
      CropCategory.vegetable,
      CropCategory.fruit,
      CropCategory.spice,
      CropCategory.oilseed,
      CropCategory.pulse,
    ];
    final labelsEn = {
      null: 'All',
      CropCategory.grain: 'Grain',
      CropCategory.vegetable: 'Veg',
      CropCategory.fruit: 'Fruit',
      CropCategory.spice: 'Spice',
      CropCategory.oilseed: 'Oil',
      CropCategory.pulse: 'Pulse',
    };
    final labelsBn = {
      null: 'সব',
      CropCategory.grain: 'শস্য',
      CropCategory.vegetable: 'সবজি',
      CropCategory.fruit: 'ফল',
      CropCategory.spice: 'মসলা',
      CropCategory.oilseed: 'তেলবীজ',
      CropCategory.pulse: 'ডাল',
    };

    return SizedBox(
      height: 54,
      child: ListView.separated(
        scrollDirection: Axis.horizontal,
        padding: const EdgeInsets.fromLTRB(20, 12, 20, 0),
        itemCount: cats.length,
        separatorBuilder: (_, __) => const SizedBox(width: 8),
        itemBuilder: (_, i) {
          final cat = cats[i];
          final active = state.selectedCategory == cat;
          final label = state.isBangla ? labelsBn[cat]! : labelsEn[cat]!;
          return GestureDetector(
            onTap: () =>
                ref.read(calendarProvider.notifier).selectCategory(cat),
            child: AnimatedContainer(
              duration: const Duration(milliseconds: 200),
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 5),
              decoration: BoxDecoration(
                color: active ? AppTheme.primaryGreen : Colors.white,
                borderRadius: BorderRadius.circular(22),
                border: Border.all(
                  color: active
                      ? AppTheme.primaryGreen
                      : Colors.grey.withValues(alpha: 0.22),
                ),
                boxShadow: active
                    ? [
                        BoxShadow(
                          color: AppTheme.primaryGreen.withValues(alpha: 0.28),
                          blurRadius: 8,
                          offset: const Offset(0, 2),
                        ),
                      ]
                    : null,
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(_categoryIcon(cat ?? CropCategory.other),
                      size: 14,
                      color: active ? Colors.white : AppTheme.primaryGreen),
                  const SizedBox(width: 5),
                  Text(
                    label,
                    style: TextStyle(
                      color: active ? Colors.white : const Color(0xFF444444),
                      fontWeight: FontWeight.w600,
                      fontSize: 12,
                    ),
                  ),
                ],
              ),
            ),
          );
        },
      ),
    );
  }

  // ─── 5. CALENDAR CARD ────────────────────────────────────────────────────

  Widget _buildCalendarCard(CalendarState state) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 12, 20, 0),
      child: Container(
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(20),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.06),
              blurRadius: 16,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        child: Column(
          children: [
            const SizedBox(height: 12),
            _buildWeekdayRow(state),
            const SizedBox(height: 4),
            SlideTransition(
              position: _slideAnim,
              child: _buildDaysGrid(state),
            ),
            const SizedBox(height: 8),
            _buildLegend(state),
            const SizedBox(height: 12),
          ],
        ),
      ),
    );
  }

  Widget _buildWeekdayRow(CalendarState state) {
    const engDays = ['Su', 'Mo', 'Tu', 'We', 'Th', 'Fr', 'Sa'];
    const bnDays = ['র', 'সো', 'ম', 'বু', 'বৃ', 'শু', 'শ'];
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 8),
      child: Row(
        children: List.generate(
            7,
            (i) => Expanded(
                  child: Column(
                    children: [
                      Text(
                        state.isBangla ? bnDays[i] : engDays[i],
                        style: const TextStyle(
                            color: Color(0xFF555555),
                            fontSize: 11,
                            fontWeight: FontWeight.w700),
                      ),
                      if (!state.isBangla)
                        Text(bnDays[i],
                            style: TextStyle(
                                color: Colors.grey[400],
                                fontSize: 9,
                                fontWeight: FontWeight.w600)),
                    ],
                  ),
                )),
      ),
    );
  }

  Widget _buildDaysGrid(CalendarState state) {
    final year = state.focusedYear;
    final month = state.focusedMonth;
    final first = DateTime(year, month, 1);
    final days = DateUtils.getDaysInMonth(year, month);
    final start = first.weekday % 7;
    final today = DateTime.now();

    final hasPeak = state.allCrops.any(
        (c) => c.sowMonths.contains(month) && c.harvestMonths.contains(month));
    final hasHarvest = state.harvestingThisMonth.isNotEmpty;
    final hasCultivation = state.sowingThisMonth.isNotEmpty;

    Color? dotColor;
    if (hasPeak) {
      dotColor = _statusColors[_Status.peak];
    } else if (hasHarvest) {
      dotColor = _statusColors[_Status.harvest];
    } else if (hasCultivation) {
      dotColor = _statusColors[_Status.cultivation];
    }

    final cells = <Widget>[
      ...List.filled(start, const SizedBox()),
      ...List.generate(days, (i) {
        final d = i + 1;
        final date = DateTime(year, month, d);
        final isToday = date.year == today.year &&
            date.month == today.month &&
            date.day == today.day;
        final isSelected = d == state.selectedDay;
        final bangla = _BanglaHelper.convert(date);

        return _DayCell(
          engDay: state.isBangla ? _BanglaHelper.digits(d) : '$d',
          bnDay: bangla['dayBn'] as String,
          isToday: isToday,
          isSelected: isSelected,
          dotColor: dotColor,
          isBangla: state.isBangla,
          onTap: () {
            ref.read(calendarProvider.notifier).selectDay(d);
            _fadeCtrl.forward(from: 0);
          },
        );
      }),
    ];

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 4),
      child: GridView.count(
        crossAxisCount: 7,
        shrinkWrap: true,
        physics: const NeverScrollableScrollPhysics(),
        childAspectRatio: 0.72,
        children: cells,
      ),
    );
  }

  Widget _buildLegend(CalendarState state) {
    final items = state.isBangla
        ? [
            (_Status.peak, 'ভরা মৌসুম'),
            (_Status.harvest, 'ফসল তোলা'),
            (_Status.cultivation, 'বপন'),
          ]
        : [
            (_Status.peak, 'Peak Season'),
            (_Status.harvest, 'Harvest'),
            (_Status.cultivation, 'Sow'),
          ];

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 12),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: items
            .map((item) => Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 6),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Container(
                        width: 7,
                        height: 7,
                        decoration: BoxDecoration(
                          color: _statusColors[item.$1],
                          shape: BoxShape.circle,
                        ),
                      ),
                      const SizedBox(width: 4),
                      Text(item.$2,
                          style:
                              TextStyle(fontSize: 9, color: Colors.grey[600])),
                    ],
                  ),
                ))
            .toList(),
      ),
    );
  }

  // ─── 6. MONTH CROP OVERVIEW ───────────────────────────────────────────────

  Widget _buildMonthCropOverview(CalendarState state) {
    final crops = state.activeThisMonth
        .where((c) =>
            state.selectedCategory == null ||
            c.category == state.selectedCategory)
        .toList();

    if (crops.isEmpty) {
      return Padding(
        padding: const EdgeInsets.fromLTRB(20, 16, 20, 0),
        child: Center(
          child: Column(
            children: [
              Icon(Icons.eco_rounded, size: 40, color: Colors.grey[300]),
              const SizedBox(height: 8),
              Text(
                state.isBangla ? 'এই মাসে কোনো ফসল নেই' : 'No crops this month',
                style: TextStyle(color: Colors.grey[500], fontSize: 13),
              ),
            ],
          ),
        ),
      );
    }

    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 16, 20, 0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Icon(Icons.bar_chart_rounded,
                  color: AppTheme.primaryGreen, size: 18),
              const SizedBox(width: 6),
              Text(
                state.isBangla ? 'এই মাসের ফসল' : 'This Month\'s Crops',
                style: const TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.w800,
                  color: Color(0xFF1B4332),
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          ...crops.take(6).map((crop) => _CropStatusTile(
                crop: crop,
                status: crop.statusFor(state.focusedMonth),
                isBangla: state.isBangla,
              )),
          if (crops.length > 6)
            Center(
              child: Padding(
                padding: const EdgeInsets.only(top: 6),
                child: Text(
                  state.isBangla
                      ? 'আরও ${_BanglaHelper.digits(crops.length - 6)} টি ফসল'
                      : '+ ${crops.length - 6} more crops',
                  style: const TextStyle(
                    color: AppTheme.lightGreen,
                    fontWeight: FontWeight.w600,
                    fontSize: 12,
                  ),
                ),
              ),
            ),
        ],
      ),
    );
  }

  // ─── 7. DATE DETAIL PANEL ─────────────────────────────────────────────────

  Widget _buildDateDetailPanel(CalendarState state) {
    final day = state.selectedDay!;
    final date = DateTime(state.focusedYear, state.focusedMonth, day);
    final bangla = _BanglaHelper.convert(date);

    final crops = state.activeThisMonth
        .where((c) =>
            state.selectedCategory == null ||
            c.category == state.selectedCategory)
        .toList();

    return FadeTransition(
      opacity: _fadeAnim,
      child: Padding(
        padding: const EdgeInsets.fromLTRB(20, 16, 20, 0),
        child: Container(
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(20),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withValues(alpha: 0.06),
                blurRadius: 16,
                offset: const Offset(0, 4),
              ),
            ],
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Container(
                padding: const EdgeInsets.all(16),
                decoration: const BoxDecoration(
                  gradient: LinearGradient(
                    colors: [AppTheme.lightGreen, AppTheme.primaryGreen],
                  ),
                  borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
                ),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            state.isBangla
                                ? '${_BanglaHelper.dayBn(date.weekday)}, ${_BanglaHelper.digits(day)} ${_monthNameBn(date.month)} ${_BanglaHelper.digits(date.year)}'
                                : '${_BanglaHelper.dayEn(date.weekday)}, ${_monthNameEn(date.month)} $day, ${date.year}',
                            style: const TextStyle(
                              color: Colors.white,
                              fontSize: 15,
                              fontWeight: FontWeight.w800,
                            ),
                          ),
                          const SizedBox(height: 5),
                          Container(
                            padding: const EdgeInsets.symmetric(
                                horizontal: 10, vertical: 4),
                            decoration: BoxDecoration(
                              color: Colors.white.withValues(alpha: 0.18),
                              borderRadius: BorderRadius.circular(20),
                            ),
                            child: Text(
                              state.isBangla
                                  ? '${bangla['dayBn']} ${bangla['monthName']} ${bangla['yearBn']} বঙ্গাব্দ'
                                  : '${_BanglaHelper.dayEn(date.weekday)}, ${bangla['dayBn']} ${bangla['monthName']} ${bangla['yearBn']} বঙ্গাব্দ',
                              style: TextStyle(
                                color: Colors.white.withValues(alpha: 0.92),
                                fontSize: 12,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(width: 10),
                    Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 12, vertical: 8),
                      decoration: BoxDecoration(
                        color: Colors.white.withValues(alpha: 0.18),
                        borderRadius: BorderRadius.circular(10),
                      ),
                      child: Column(
                        children: [
                          Text(
                            state.isBangla
                                ? _BanglaHelper.digits(crops.length)
                                : '${crops.length}',
                            style: const TextStyle(
                              color: Colors.white,
                              fontSize: 22,
                              fontWeight: FontWeight.w900,
                            ),
                          ),
                          Text(
                            state.isBangla ? 'সক্রিয়\nফসল' : 'Active\nCrops',
                            style: const TextStyle(
                                color: Colors.white70, fontSize: 9),
                            textAlign: TextAlign.center,
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
              if (crops.isEmpty)
                Padding(
                  padding: const EdgeInsets.all(24),
                  child: Center(
                    child: Column(
                      children: [
                        Icon(Icons.eco_rounded,
                            size: 36, color: Colors.grey[300]),
                        const SizedBox(height: 8),
                        Text(
                          state.isBangla
                              ? 'এই ফিল্টারে কোনো ফসল নেই'
                              : 'No crops for selected filter',
                          style:
                              TextStyle(color: Colors.grey[500], fontSize: 13),
                          textAlign: TextAlign.center,
                        ),
                      ],
                    ),
                  ),
                )
              else
                Padding(
                  padding: const EdgeInsets.all(14),
                  child: Column(
                    children: crops
                        .map((crop) => _DetailedCropCard(
                              crop: crop,
                              status: crop.statusFor(date.month),
                              isBangla: state.isBangla,
                            ))
                        .toList(),
                  ),
                ),
            ],
          ),
        ),
      ),
    );
  }

  // ─── HELPERS ──────────────────────────────────────────────────────────────

  static const _monthsEn = [
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
  static const _monthsBn = [
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

  String _monthNameEn(int m) => _monthsEn[m - 1];
  String _monthNameBn(int m) => _monthsBn[m - 1];
}

// ════════════════════════════════════════════════════════════════════════════
// DAY CELL
// ════════════════════════════════════════════════════════════════════════════

class _DayCell extends StatelessWidget {
  const _DayCell({
    required this.engDay,
    required this.bnDay,
    required this.isToday,
    required this.isSelected,
    required this.dotColor,
    required this.isBangla,
    required this.onTap,
  });

  final String engDay;
  final String bnDay;
  final bool isToday;
  final bool isSelected;
  final Color? dotColor;
  final bool isBangla;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 180),
        margin: const EdgeInsets.all(2),
        decoration: BoxDecoration(
          color: isSelected
              ? AppTheme.primaryGreen
              : isToday
                  ? AppTheme.bgLight
                  : Colors.transparent,
          borderRadius: BorderRadius.circular(10),
          border: isToday && !isSelected
              ? Border.all(color: AppTheme.primaryGreen, width: 1.5)
              : null,
        ),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Text(
              // In BN mode: engDay already holds Bengali digits (passed in from _buildDaysGrid)
              // In EN mode: engDay holds ASCII digits, show bnDay as sub-label
              engDay,
              style: TextStyle(
                fontSize: 14,
                fontWeight:
                    isSelected || isToday ? FontWeight.w800 : FontWeight.w500,
                color: isSelected
                    ? Colors.white
                    : isToday
                        ? AppTheme.primaryGreen
                        : AppTheme.textPrimary,
              ),
            ),
            if (!isBangla) ...[
              Container(
                width: 18,
                height: 0.5,
                color: isSelected
                    ? Colors.white.withValues(alpha: 0.4)
                    : Colors.grey.withValues(alpha: 0.3),
                margin: const EdgeInsets.symmetric(vertical: 1),
              ),
              Text(
                bnDay,
                style: TextStyle(
                  fontSize: 10,
                  fontWeight: FontWeight.w600,
                  color: isSelected
                      ? Colors.white.withValues(alpha: 0.85)
                      : isToday
                          ? AppTheme.primaryGreen.withValues(alpha: 0.75)
                          : AppTheme.textHint,
                ),
              ),
            ],
            if (dotColor != null) ...[
              const SizedBox(height: 2),
              Container(
                width: 5,
                height: 5,
                decoration: BoxDecoration(
                  color: isSelected ? Colors.white : dotColor,
                  shape: BoxShape.circle,
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }
}

// ════════════════════════════════════════════════════════════════════════════
// CROP STATUS TILE
// ════════════════════════════════════════════════════════════════════════════

class _CropStatusTile extends StatelessWidget {
  const _CropStatusTile({
    required this.crop,
    required this.status,
    required this.isBangla,
  });

  final CropCalendar crop;
  final _Status status;
  final bool isBangla;

  @override
  Widget build(BuildContext context) {
    final color = _statusColors[status]!;
    final label =
        isBangla ? _statusLabelsBn[status]! : _statusLabelsEn[status]!;

    return Padding(
      padding: const EdgeInsets.only(bottom: 10),
      child: Row(
        children: [
          _CropImage(imageUrl: crop.imageUrl, size: 36, color: color),
          const SizedBox(width: 10),
          Expanded(
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Expanded(
                  child: Text(
                    isBangla ? crop.cropNameBn : crop.cropNameEn,
                    style: const TextStyle(
                      fontWeight: FontWeight.w700,
                      fontSize: 13,
                      color: Color(0xFF222222),
                    ),
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
                const SizedBox(width: 8),
                Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                  decoration: BoxDecoration(
                    color: color.withValues(alpha: 0.14),
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(
                        color: color.withValues(alpha: 0.30), width: 1),
                  ),
                  child: Text(
                    label,
                    style: TextStyle(
                      fontSize: 10,
                      color: color,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

// ════════════════════════════════════════════════════════════════════════════
// DETAILED CROP CARD
// ════════════════════════════════════════════════════════════════════════════

class _DetailedCropCard extends StatelessWidget {
  const _DetailedCropCard({
    required this.crop,
    required this.status,
    required this.isBangla,
  });

  final CropCalendar crop;
  final _Status status;
  final bool isBangla;

  @override
  Widget build(BuildContext context) {
    final color = _statusColors[status]!;
    final label =
        isBangla ? _statusLabelsBn[status]! : _statusLabelsEn[status]!;
    final notes = isBangla ? crop.notesBn : crop.notesEn;

    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.05),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: color.withValues(alpha: 0.2)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              _CropImage(imageUrl: crop.imageUrl, size: 44, color: color),
              const SizedBox(width: 10),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      isBangla ? crop.cropNameBn : crop.cropNameEn,
                      style: const TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w800,
                        color: Color(0xFF1B4332),
                      ),
                    ),
                    Text(
                      isBangla ? crop.cropNameEn : crop.cropNameBn,
                      style: TextStyle(
                        fontSize: 13,
                        fontWeight: FontWeight.w500,
                        color: AppTheme.primaryGreen.withValues(alpha: 0.75),
                      ),
                    ),
                  ],
                ),
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 6),
                decoration: BoxDecoration(
                  color: color,
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Text(
                  label,
                  style: const TextStyle(
                      color: Colors.white,
                      fontSize: 11,
                      fontWeight: FontWeight.w700),
                ),
              ),
            ],
          ),
          if (notes != null && notes.isNotEmpty) ...[
            const SizedBox(height: 10),
            Container(
              padding: const EdgeInsets.all(10),
              decoration: BoxDecoration(
                color: Colors.white.withValues(alpha: 0.6),
                borderRadius: BorderRadius.circular(10),
              ),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Icon(Icons.info_outline_rounded,
                      size: 13, color: Colors.grey[500]),
                  const SizedBox(width: 5),
                  Expanded(
                    child: Text(
                      notes,
                      style: TextStyle(fontSize: 12, color: Colors.grey[700]),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ],
      ),
    );
  }
}

// ════════════════════════════════════════════════════════════════════════════
// CROP IMAGE
// ════════════════════════════════════════════════════════════════════════════

class _CropImage extends StatelessWidget {
  const _CropImage({
    required this.imageUrl,
    required this.size,
    required this.color,
  });

  final String? imageUrl;
  final double size;
  final Color color;

  @override
  Widget build(BuildContext context) {
    final hasImage = imageUrl != null && imageUrl!.isNotEmpty;

    return Container(
      width: size,
      height: size,
      clipBehavior: Clip.antiAlias,
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.12),
        borderRadius: BorderRadius.circular(size * 0.27),
        border: Border.all(
          color: color.withValues(alpha: 0.18),
          width: 1,
        ),
      ),
      child: hasImage
          ? Image.network(
              imageUrl!,
              fit: BoxFit.cover,
              loadingBuilder: (_, child, progress) {
                if (progress == null) return child;
                return Center(
                  child: SizedBox(
                    width: size * 0.4,
                    height: size * 0.4,
                    child: CircularProgressIndicator(
                      strokeWidth: 2,
                      color: color,
                      value: progress.expectedTotalBytes != null
                          ? progress.cumulativeBytesLoaded /
                              progress.expectedTotalBytes!
                          : null,
                    ),
                  ),
                );
              },
              errorBuilder: (_, __, ___) => Icon(
                Icons.eco_rounded,
                size: size * 0.5,
                color: color,
              ),
            )
          : Icon(
              Icons.eco_rounded,
              size: size * 0.5,
              color: color,
            ),
    );
  }
}

// ════════════════════════════════════════════════════════════════════════════
// LOADING / ERROR
// ════════════════════════════════════════════════════════════════════════════

class _LoadingView extends StatelessWidget {
  const _LoadingView();
  @override
  Widget build(BuildContext context) => const Scaffold(
        backgroundColor: AppTheme.surfaceGreen,
        body: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              CircularProgressIndicator(color: AppTheme.primaryGreen),
              SizedBox(height: 16),
              Text('লোড হচ্ছে...',
                  style:
                      TextStyle(color: AppTheme.textSecondary, fontSize: 14)),
            ],
          ),
        ),
      );
}

class _ErrorView extends StatelessWidget {
  const _ErrorView({required this.error, required this.onRetry});
  final String error;
  final VoidCallback onRetry;
  @override
  Widget build(BuildContext context) => Scaffold(
        backgroundColor: AppTheme.surfaceGreen,
        body: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(Icons.cloud_off_rounded, size: 52, color: Colors.grey[300]),
              const SizedBox(height: 12),
              const Text('তথ্য লোড হয়নি',
                  style: TextStyle(
                      fontSize: 15,
                      fontWeight: FontWeight.w600,
                      color: AppTheme.textPrimary)),
              const SizedBox(height: 8),
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 20),
                child: Text(
                  error,
                  style: TextStyle(fontSize: 12, color: Colors.grey[600]),
                  textAlign: TextAlign.center,
                ),
              ),
              const SizedBox(height: 16),
              ElevatedButton.icon(
                onPressed: onRetry,
                icon: const Icon(Icons.refresh_rounded),
                label: const Text('আবার চেষ্টা করুন'),
              ),
            ],
          ),
        ),
      );
}
