import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import '../../core/router.dart';
import '../../core/theme.dart';
import '../../models/weather.dart';
import '../../models/product.dart';
import '../../models/crop_calendar.dart';
import '../../providers/weather_provider.dart';
import '../../providers/notifications_provider.dart';
import '../../providers/auth_provider.dart';
import '../../providers/marketplace_provider.dart';
import '../../providers/calendar_provider.dart';

// ---------------------------------------------------------------------------
// Bilingual helper
// ---------------------------------------------------------------------------

String _t(bool bn, String bangla, String english) => bn ? bangla : english;

// ---------------------------------------------------------------------------
// HOME SCREEN
// ---------------------------------------------------------------------------

class HomeScreen extends ConsumerStatefulWidget {
  const HomeScreen({super.key});

  @override
  ConsumerState<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends ConsumerState<HomeScreen> {
  bool _showTomorrow = false;
  int _currentTabIndex = 0;
  bool _bn = true; // language toggle

  @override
  void initState() {
    super.initState();
    Future.microtask(() {
      ref.read(marketplaceProvider.notifier).loadProducts();
      ref.read(marketplaceProvider.notifier).loadCart();
    });
  }

  void _onTabTapped(int index) {
    switch (index) {
      case 0:
        break;
      case 1:
        Navigator.pushNamed(context, AppRouter.market);
        break;
      case 2:
        Navigator.pushNamed(context, AppRouter.services);
        break;
      case 3:
        Navigator.pushNamed(context, AppRouter.profile);
        break;
    }
    setState(() => _currentTabIndex = index);
  }

  IconData _iconFromCode(String iconCode) {
    switch (iconCode) {
      case '01d':
        return Icons.wb_sunny_rounded;
      case '01n':
        return Icons.nightlight_round;
      case '02d':
      case '03d':
        return Icons.wb_cloudy_rounded;
      case '02n':
      case '03n':
        return Icons.cloud_queue_rounded;
      case '04d':
      case '04n':
        return Icons.cloud_rounded;
      case '09d':
      case '09n':
      case '10d':
      case '10n':
        return Icons.umbrella_rounded;
      case '11d':
      case '11n':
        return Icons.thunderstorm_rounded;
      case '13d':
      case '13n':
        return Icons.ac_unit_rounded;
      case '50d':
      case '50n':
        return Icons.blur_on_rounded;
      default:
        return Icons.wb_cloudy_rounded;
    }
  }

  @override
  Widget build(BuildContext context) {
    final user = ref.watch(currentUserProvider);
    final userName =
        user?.name.isNotEmpty == true ? user!.name : _t(_bn, 'কৃষক', 'Farmer');

    // Date — Bengali or English locale
    final now = DateTime.now();
    final dateStr = _bn
        ? DateFormat('EEEE, d MMMM yyyy', 'bn').format(now)
        : DateFormat('EEEE, d MMMM yyyy', 'en').format(now);

    final marketState = ref.watch(marketplaceProvider);
    final previewProducts = marketState.products.take(4).toList();

    final calendarAsync = ref.watch(calendarProvider);
    final activeCrops = calendarAsync.valueOrNull?.activeThisMonth ?? [];

    return Scaffold(
      backgroundColor: AppTheme.bgLight,
      body: SafeArea(
        child: SingleChildScrollView(
          physics: const BouncingScrollPhysics(),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // 1. TOP BAR
              _buildTopBar(context, userName, dateStr),

              // 2. WEATHER
              _buildWeatherSection(context),

              // 3. SEARCH BAR
              _buildSearchBar(),

              const SizedBox(height: 14),

              // 4. PROMO BANNERS
              const _PromoImageCarousel(),

              // 5. SEASONAL CROPS
              _buildSectionHeader(
                _t(_bn, 'এই মৌসুমের সেরা ফসল', 'Best Crops This Season'),
                _t(_bn, 'সব দেখুন', 'See All'),
                onActionTap: () =>
                    Navigator.pushNamed(context, AppRouter.calendar),
              ),
              _buildSeasonalCrops(activeCrops, calendarAsync.isLoading),

              // 6. SERVICES
              _buildSectionHeader(
                  _t(_bn, 'আমাদের সেবাসমূহ', 'Our Services'), ''),
              _buildServicesGrid(),

              // 7. MARKETPLACE
              _buildSectionHeader(
                _t(_bn, 'বাজারের নতুন পণ্য', 'New in the Market'),
                _t(_bn, 'দোকানে যান', 'Go to Shop'),
                onActionTap: () =>
                    Navigator.pushNamed(context, AppRouter.market),
              ),
              marketState.isLoading
                  ? const Padding(
                      padding: EdgeInsets.symmetric(vertical: 32),
                      child: Center(
                        child: CircularProgressIndicator(
                            color: AppTheme.primaryGreen),
                      ),
                    )
                  : previewProducts.isEmpty
                      ? Padding(
                          padding: const EdgeInsets.symmetric(
                              horizontal: 16, vertical: 24),
                          child: Center(
                            child: Text(
                              _t(_bn, 'কোনো পণ্য পাওয়া যায়নি',
                                  'No products found'),
                              style: TextStyle(
                                  color: Colors.grey.shade500, fontSize: 14),
                            ),
                          ),
                        )
                      : _buildProductGrid(previewProducts),

              const SizedBox(height: 120),
            ],
          ),
        ),
      ),
      floatingActionButton: _buildFAB(),
      floatingActionButtonLocation: FloatingActionButtonLocation.endFloat,
      bottomNavigationBar: _buildBottomNav(),
    );
  }

  // -------------------------------------------------------------------------
  // TOP BAR — greeting + date | notification bell | EN/বাং toggle
  // -------------------------------------------------------------------------
  Widget _buildTopBar(BuildContext context, String userName, String dateStr) {
    final greeting =
        _t(_bn, 'আসসালামু আলাইকুম, $userName!', 'Hello, $userName!');

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.fromLTRB(20, 20, 20, 10),
      child: Row(
        children: [
          // Greeting + date
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  greeting,
                  style: const TextStyle(
                    color: AppTheme.primaryGreen,
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                Text(
                  dateStr,
                  style: const TextStyle(color: Colors.black54, fontSize: 13),
                ),
              ],
            ),
          ),
          const SizedBox(width: 12),

          // Notification bell
          GestureDetector(
            onTap: () => Navigator.pushNamed(context, AppRouter.notifications),
            child: Stack(
              clipBehavior: Clip.none,
              children: [
                Container(
                  width: 36,
                  height: 36,
                  decoration: BoxDecoration(
                    color: AppTheme.primaryGreen.withValues(alpha: 0.1),
                    shape: BoxShape.circle,
                  ),
                  child: const Icon(
                    Icons.notifications_outlined,
                    color: AppTheme.primaryGreen,
                    size: 20,
                  ),
                ),
                if (ref.watch(unreadCountProvider) > 0)
                  Positioned(
                    top: 0,
                    right: 0,
                    child: Container(
                      width: 10,
                      height: 10,
                      decoration: BoxDecoration(
                        color: Colors.red,
                        shape: BoxShape.circle,
                        border: Border.all(color: Colors.white, width: 1.5),
                      ),
                    ),
                  ),
              ],
            ),
          ),
          const SizedBox(width: 10),

          // Language toggle (replaces avatar)
          GestureDetector(
            onTap: () => setState(() => _bn = !_bn),
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
              decoration: BoxDecoration(
                color: AppTheme.primaryGreen,
                borderRadius: BorderRadius.circular(20),
              ),
              child: Text(
                _bn ? 'EN' : 'বাং',
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 13,
                  fontWeight: FontWeight.w700,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  // -------------------------------------------------------------------------
  // WEATHER SECTION
  // -------------------------------------------------------------------------
  Widget _buildWeatherSection(BuildContext context) {
    final weatherAsync = ref.watch(weatherProvider);

    return weatherAsync.when(
      loading: () => const SizedBox(
        height: 160,
        child: Center(
            child: CircularProgressIndicator(color: AppTheme.primaryGreen)),
      ),
      error: (err, stack) => SizedBox(
        height: 160,
        child: Center(
          child: TextButton.icon(
            onPressed: () => ref.read(weatherProvider.notifier).refresh(),
            icon: const Icon(Icons.refresh, color: AppTheme.primaryGreen),
            label: Text(
              _t(_bn, 'আবহাওয়া লোড করা যায়নি। পুনরায় চেষ্টা করুন',
                  'Could not load weather. Tap to retry.'),
              style: const TextStyle(color: AppTheme.primaryGreen),
            ),
          ),
        ),
      ),
      data: (weatherData) {
        final now = DateTime.now();
        final todayTarget = DateTime(now.year, now.month, now.day);
        final tomorrowTarget = todayTarget.add(const Duration(days: 1));

        final todayHourly = weatherData.hourly.where((h) {
          final hDate = DateTime(h.time.year, h.time.month, h.time.day);
          return hDate.isAtSameMomentAs(todayTarget);
        }).toList();

        final tomorrowHourly = weatherData.hourly.where((h) {
          final hDate = DateTime(h.time.year, h.time.month, h.time.day);
          return hDate.isAtSameMomentAs(tomorrowTarget);
        }).toList();

        final visibleHourly = _showTomorrow
            ? (tomorrowHourly.isNotEmpty
                ? tomorrowHourly
                : weatherData.next9Hours)
            : (todayHourly.length >= 5 ? todayHourly : weatherData.next9Hours);

        HourlyWeather? activeHourlyItem;
        if (visibleHourly.isNotEmpty) {
          activeHourlyItem = visibleHourly.reduce((a, b) {
            final diffA = (a.time.difference(now)).abs();
            final diffB = (b.time.difference(now)).abs();
            return diffA < diffB ? a : b;
          });
        }

        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
              child: Row(
                children: [
                  GestureDetector(
                    onTap: () => setState(() => _showTomorrow = false),
                    child: Text(
                      _t(_bn, 'আজকের আবহাওয়া', "Today's Weather"),
                      style: TextStyle(
                        fontWeight: FontWeight.bold,
                        fontSize: 16,
                        color: !_showTomorrow ? Colors.black : Colors.grey[400],
                      ),
                    ),
                  ),
                  const Spacer(),
                  TextButton(
                    onPressed: () =>
                        Navigator.pushNamed(context, AppRouter.weather),
                    child: Row(
                      children: [
                        Text(
                          _t(_bn, 'পরবর্তী ৫ দিন', 'Next 5 Days'),
                          style: const TextStyle(
                              color: AppTheme.primaryGreen, fontSize: 12),
                        ),
                        const Icon(Icons.chevron_right,
                            size: 16, color: AppTheme.primaryGreen),
                      ],
                    ),
                  ),
                ],
              ),
            ),
            SizedBox(
              height: 120,
              child: visibleHourly.isEmpty
                  ? Center(
                      child: Text(_t(_bn, 'আবহাওয়ার কোনো তথ্য পাওয়া যায়নি',
                          'No weather data available')))
                  : ListView.builder(
                      scrollDirection: Axis.horizontal,
                      padding: const EdgeInsets.symmetric(horizontal: 20),
                      physics: const BouncingScrollPhysics(),
                      itemCount: visibleHourly.length,
                      itemBuilder: (context, index) {
                        final item = visibleHourly[index];
                        final isActive = item == activeHourlyItem;
                        return _buildWeatherCard(item, isActive);
                      },
                    ),
            ),
            const SizedBox(height: 10),
          ],
        );
      },
    );
  }

  Widget _buildWeatherCard(HourlyWeather w, bool isActive) {
    // Time label: Bengali digits/transliteration OR plain English
    final rawTimeStr = DateFormat('h a').format(w.time);
    final timeLabel = _bn ? WeatherData.toBangla(rawTimeStr) : rawTimeStr;

    // Temperature
    final tempLabel = _bn
        ? '${WeatherData.toBangla(w.tempCelsius.round())}°'
        : '${w.tempCelsius.round()}°';

    // Condition
    final condLabel = _bn
        ? WeatherData.getShortBanglaCondition(w.iconCode)
        : WeatherData.getShortEnglishCondition(w.iconCode);

    return Container(
      width: 54,
      margin: const EdgeInsets.only(right: 12),
      padding: const EdgeInsets.symmetric(vertical: 10),
      decoration: BoxDecoration(
        color: isActive ? AppTheme.primaryGreen : Colors.white,
        borderRadius: BorderRadius.circular(25),
        boxShadow: const [
          BoxShadow(
            color: Color(0xFFE0DEDE),
            blurRadius: 6,
            offset: Offset(0, 3),
          ),
        ],
      ),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Text(
            timeLabel,
            style: TextStyle(
              color: isActive ? Colors.white70 : Colors.grey,
              fontSize: 9,
            ),
          ),
          const SizedBox(height: 4),
          Icon(
            _iconFromCode(w.iconCode),
            color: isActive ? Colors.white : AppTheme.primaryGreen,
            size: 18,
          ),
          const SizedBox(height: 4),
          Text(
            tempLabel,
            style: TextStyle(
              color: isActive ? Colors.white : Colors.black87,
              fontSize: 12,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 2),
          Text(
            condLabel,
            style: TextStyle(
              color: isActive ? Colors.white70 : Colors.grey[600],
              fontSize: 9,
              fontWeight: FontWeight.w500,
            ),
          ),
        ],
      ),
    );
  }

  // -------------------------------------------------------------------------
  // SEARCH BAR
  // -------------------------------------------------------------------------
  Widget _buildSearchBar() {
    return GestureDetector(
      onTap: () => Navigator.pushNamed(context, AppRouter.market),
      child: Container(
        margin: const EdgeInsets.fromLTRB(16, 16, 16, 0),
        height: 46,
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(24),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.05),
              blurRadius: 8,
              offset: const Offset(0, 2),
            ),
          ],
          border: Border.all(color: const Color(0xFFE0E0E0)),
        ),
        child: Row(
          children: [
            const SizedBox(width: 14),
            const Icon(Icons.search, color: AppTheme.primaryGreen, size: 20),
            const SizedBox(width: 8),
            Text(
              _t(_bn, 'পণ্য বা সেবা খুঁজুন...',
                  'Search products or services...'),
              style: TextStyle(color: Colors.grey.shade400, fontSize: 13),
            ),
          ],
        ),
      ),
    );
  }

  // -------------------------------------------------------------------------
  // SECTION HEADER
  // -------------------------------------------------------------------------
  Widget _buildSectionHeader(
    String title,
    String action, {
    VoidCallback? onActionTap,
  }) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 20, 16, 10),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(
            title,
            style: const TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.bold,
              color: Color(0xFF111D13),
            ),
          ),
          if (action.isNotEmpty)
            GestureDetector(
              onTap: onActionTap,
              child: Text(
                action,
                style: const TextStyle(
                  color: AppTheme.primaryGreen,
                  fontWeight: FontWeight.bold,
                  fontSize: 13,
                ),
              ),
            ),
        ],
      ),
    );
  }

  // -------------------------------------------------------------------------
  // SEASONAL CROPS
  // -------------------------------------------------------------------------
  Widget _buildSeasonalCrops(List<CropCalendar> crops, bool isLoading) {
    if (isLoading) {
      return const SizedBox(
        height: 120,
        child: Center(
          child: CircularProgressIndicator(color: AppTheme.primaryGreen),
        ),
      );
    }

    if (crops.isEmpty) {
      return SizedBox(
        height: 80,
        child: Center(
          child: Text(
            _t(_bn, 'এই মাসে কোনো ফসলের তথ্য নেই',
                'No crop data for this month'),
            style: TextStyle(color: Colors.grey.shade500, fontSize: 13),
          ),
        ),
      );
    }

    // Month name lists for both languages
    final monthNamesBn = [
      '',
      'জানু',
      'ফেব',
      'মার্চ',
      'এপ্রিল',
      'মে',
      'জুন',
      'জুলাই',
      'আগস্ট',
      'সেপ্টে',
      'অক্টো',
      'নভে',
      'ডিসে',
    ];
    final monthNamesEn = [
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

    return SizedBox(
      height: 120,
      child: ListView.builder(
        scrollDirection: Axis.horizontal,
        physics: const BouncingScrollPhysics(),
        padding: const EdgeInsets.symmetric(horizontal: 20),
        itemCount: crops.length,
        itemBuilder: (context, index) {
          final crop = crops[index];
          final months = _bn ? monthNamesBn : monthNamesEn;
          final sowList = crop.sowMonths;
          final harvestList = crop.harvestMonths;
          String period = '';
          if (sowList.isNotEmpty && harvestList.isNotEmpty) {
            final sowName = months[sowList.first.clamp(1, 12)];
            final harvestName = months[harvestList.last.clamp(1, 12)];
            period = '$sowName - $harvestName';
          } else if (sowList.isNotEmpty) {
            period = months[sowList.first.clamp(1, 12)];
          }

          // Crop name — use English name if available and in EN mode
          final cropLabel = (!_bn) ? crop.cropNameEn : crop.cropNameBn;

          return Padding(
            padding: const EdgeInsets.only(right: 18),
            child: GestureDetector(
              onTap: () => Navigator.pushNamed(context, AppRouter.calendar),
              child: SizedBox(
                width: 74,
                child: Column(
                  children: [
                    Container(
                      height: 70,
                      width: 70,
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        color: AppTheme.primaryGreen.withValues(alpha: 0.08),
                        border: Border.all(
                          color: AppTheme.primaryGreen,
                          width: 2,
                        ),
                      ),
                      child: Center(
                        child: ClipOval(
                          child: crop.imageUrl != null
                              ? Image.network(
                                  crop.imageUrl!,
                                  height: 60,
                                  width: 60,
                                  fit: BoxFit.cover,
                                  errorBuilder: (ctx, _, __) => const Icon(
                                    Icons.grass,
                                    color: AppTheme.primaryGreen,
                                    size: 28,
                                  ),
                                )
                              : const Icon(
                                  Icons.grass,
                                  color: AppTheme.primaryGreen,
                                  size: 28,
                                ),
                        ),
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      cropLabel,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      textAlign: TextAlign.center,
                      style: const TextStyle(
                        fontWeight: FontWeight.w600,
                        fontSize: 12,
                        color: Colors.black,
                      ),
                    ),
                    if (period.isNotEmpty)
                      Text(
                        period,
                        maxLines: 1,
                        textAlign: TextAlign.center,
                        style: TextStyle(
                          color: Colors.grey.shade600,
                          fontSize: 10,
                        ),
                      ),
                  ],
                ),
              ),
            ),
          );
        },
      ),
    );
  }

  // -------------------------------------------------------------------------
  // SERVICES GRID
  // -------------------------------------------------------------------------
  Widget _buildServicesGrid() {
    final services = <Map<String, dynamic>>[
      {
        'icon': Icons.agriculture,
        'labelBn': 'যন্ত্রপাতি ভাড়া',
        'labelEn': 'Equipment Rental',
        'route': AppRouter.rentals,
      },
      {
        'icon': Icons.medical_services_outlined,
        'labelBn': 'কৃষি ডাক্তার',
        'labelEn': 'Agri Doctor',
        'route': AppRouter.doctors,
      },
      {
        'icon': Icons.menu_book_outlined,
        'labelBn': 'চাষ নির্দেশিকা',
        'labelEn': 'Guidelines',
        'route': AppRouter.guidelines,
      },
      {
        'icon': Icons.landscape_outlined,
        'labelBn': 'মাটির গুণমান',
        'labelEn': 'Soil Quality',
        'route': AppRouter.soil,
      },
      {
        'icon': Icons.calendar_month_outlined,
        'labelBn': 'ফসল ক্যালেন্ডার',
        'labelEn': 'Crop Calendar',
        'route': AppRouter.calendar,
      },
    ];

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      child: GridView.builder(
        shrinkWrap: true,
        physics: const NeverScrollableScrollPhysics(),
        gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
          crossAxisCount: 3,
          childAspectRatio: 1.0,
          crossAxisSpacing: 12,
          mainAxisSpacing: 12,
        ),
        itemCount: services.length,
        itemBuilder: (context, index) {
          final svc = services[index];
          return GestureDetector(
            onTap: () => Navigator.pushNamed(context, svc['route'] as String),
            child: Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(16),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withValues(alpha: 0.05),
                    blurRadius: 8,
                    offset: const Offset(0, 3),
                  ),
                ],
              ),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  CircleAvatar(
                    radius: 24,
                    backgroundColor: const Color(0xFFF0F4F0),
                    child: Icon(
                      svc['icon'] as IconData,
                      color: AppTheme.primaryGreen,
                      size: 24,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Flexible(
                    child: Text(
                      _bn ? svc['labelBn'] as String : svc['labelEn'] as String,
                      textAlign: TextAlign.center,
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(
                        fontSize: 11,
                        fontWeight: FontWeight.w600,
                        color: Color(0xFF1A1A1A),
                      ),
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

  // -------------------------------------------------------------------------
  // MARKETPLACE PRODUCT GRID
  // -------------------------------------------------------------------------
  Widget _buildProductGrid(List<Product> products) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      child: GridView.builder(
        shrinkWrap: true,
        physics: const NeverScrollableScrollPhysics(),
        gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
          crossAxisCount: 2,
          crossAxisSpacing: 14,
          mainAxisSpacing: 14,
          childAspectRatio: 0.75,
        ),
        itemCount: products.length,
        itemBuilder: (context, index) {
          final product = products[index];
          return GestureDetector(
            onTap: () => Navigator.pushNamed(
              context,
              AppRouter.productDetail,
              arguments: product,
            ),
            child: Container(
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(16),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withValues(alpha: 0.04),
                    blurRadius: 10,
                    offset: const Offset(0, 4),
                  ),
                ],
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Expanded(
                    flex: 3,
                    child: Stack(
                      children: [
                        Positioned.fill(
                          child: ClipRRect(
                            borderRadius: const BorderRadius.vertical(
                                top: Radius.circular(16)),
                            child: product.primaryImage != null
                                ? Image.network(
                                    product.primaryImage!,
                                    fit: BoxFit.cover,
                                    errorBuilder: (_, __, ___) =>
                                        _imgFallback(),
                                  )
                                : _imgFallback(),
                          ),
                        ),
                        Positioned(
                          top: 8,
                          left: 8,
                          child: Container(
                            padding: const EdgeInsets.symmetric(
                                horizontal: 8, vertical: 4),
                            decoration: BoxDecoration(
                              color:
                                  AppTheme.primaryGreen.withValues(alpha: 0.9),
                              borderRadius: BorderRadius.circular(8),
                            ),
                            child: Text(
                              // categoryBn always Bengali;
                              // product model can add categoryEn later
                              product.categoryBn,
                              style: const TextStyle(
                                  color: Colors.white,
                                  fontSize: 10,
                                  fontWeight: FontWeight.bold),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                  Padding(
                    padding: const EdgeInsets.all(12),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          product.title,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: const TextStyle(
                            fontWeight: FontWeight.bold,
                            fontSize: 14,
                            color: Color(0xFF2D2D2D),
                          ),
                        ),
                        const SizedBox(height: 8),
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Text(
                              '৳${product.price.toStringAsFixed(0)}',
                              style: const TextStyle(
                                color: AppTheme.primaryGreen,
                                fontWeight: FontWeight.w800,
                                fontSize: 15,
                              ),
                            ),
                            GestureDetector(
                              onTap: () => ref
                                  .read(marketplaceProvider.notifier)
                                  .addToCart(product),
                              child: Container(
                                padding: const EdgeInsets.all(6),
                                decoration: const BoxDecoration(
                                  color: AppTheme.primaryGreen,
                                  shape: BoxShape.circle,
                                ),
                                child: const Icon(
                                  Icons.add_shopping_cart_rounded,
                                  color: Colors.white,
                                  size: 16,
                                ),
                              ),
                            ),
                          ],
                        ),
                      ],
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

  Widget _imgFallback() => Container(
        color: Colors.grey.shade100,
        child: Center(
          child:
              Icon(Icons.image_outlined, color: Colors.grey.shade400, size: 36),
        ),
      );

  // -------------------------------------------------------------------------
  // FAB
  // -------------------------------------------------------------------------
  Widget _buildFAB() {
    return FloatingActionButton(
      onPressed: () => Navigator.pushNamed(context, AppRouter.aiChat),
      backgroundColor: AppTheme.primaryGreen,
      shape: const CircleBorder(),
      child: const Icon(
        Icons.psychology_outlined,
        color: Colors.white,
        size: 28,
      ),
    );
  }

  // -------------------------------------------------------------------------
  // BOTTOM NAV
  // -------------------------------------------------------------------------
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
          items: [
            BottomNavigationBarItem(
                icon: const Icon(Icons.home_outlined),
                label: _t(_bn, 'হোম', 'Home')),
            BottomNavigationBarItem(
                icon: const Icon(Icons.store_outlined),
                label: _t(_bn, 'বাজার', 'Market')),
            BottomNavigationBarItem(
                icon: const Icon(Icons.miscellaneous_services_outlined),
                label: _t(_bn, 'সেবা', 'Services')),
            BottomNavigationBarItem(
                icon: const Icon(Icons.person_outline),
                label: _t(_bn, 'প্রোফাইল', 'Profile')),
          ],
        ),
      ),
    );
  }
}

// ---------------------------------------------------------------------------
// PROMO IMAGE CAROUSEL — unchanged
// ---------------------------------------------------------------------------
class _PromoImageCarousel extends StatefulWidget {
  const _PromoImageCarousel();

  @override
  State<_PromoImageCarousel> createState() => _PromoImageCarouselState();
}

class _PromoImageCarouselState extends State<_PromoImageCarousel> {
  final PageController _pageController = PageController();
  int _currentPage = 0;
  Timer? _timer;

  static const _banners = [
    {'asset': 'assets/images/farmer.png', 'route': AppRouter.market},
    {'asset': 'assets/images/tomato.png', 'route': AppRouter.market},
    {'asset': 'assets/images/rental.png', 'route': AppRouter.rentals},
  ];

  @override
  void initState() {
    super.initState();
    _timer = Timer.periodic(const Duration(seconds: 5), (_) {
      final next = (_currentPage + 1) % _banners.length;
      _pageController.animateToPage(
        next,
        duration: const Duration(milliseconds: 500),
        curve: Curves.easeInOut,
      );
    });
  }

  @override
  void dispose() {
    _timer?.cancel();
    _pageController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        SizedBox(
          height: 135,
          child: PageView.builder(
            controller: _pageController,
            itemCount: _banners.length,
            onPageChanged: (i) => setState(() => _currentPage = i),
            itemBuilder: (context, index) {
              final banner = _banners[index];
              return GestureDetector(
                onTap: () => Navigator.pushNamed(context, banner['route']!),
                child: Container(
                  margin: const EdgeInsets.symmetric(horizontal: 16),
                  child: ClipRRect(
                    borderRadius: BorderRadius.circular(16),
                    child: Image.asset(
                      banner['asset']!,
                      fit: BoxFit.cover,
                      width: double.infinity,
                      errorBuilder: (ctx, _, __) => Container(
                        decoration: BoxDecoration(
                          color: AppTheme.primaryGreen.withValues(alpha: 0.1),
                          borderRadius: BorderRadius.circular(16),
                        ),
                        child: const Icon(
                          Icons.image_outlined,
                          color: AppTheme.primaryGreen,
                          size: 40,
                        ),
                      ),
                    ),
                  ),
                ),
              );
            },
          ),
        ),
        const SizedBox(height: 8),
        Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: List.generate(_banners.length, (i) {
            final active = i == _currentPage;
            return AnimatedContainer(
              duration: const Duration(milliseconds: 300),
              margin: const EdgeInsets.symmetric(horizontal: 3),
              width: active ? 20 : 8,
              height: 8,
              decoration: BoxDecoration(
                color: active ? AppTheme.primaryGreen : const Color(0xFFBDBDBD),
                borderRadius: BorderRadius.circular(4),
              ),
            );
          }),
        ),
      ],
    );
  }
}
