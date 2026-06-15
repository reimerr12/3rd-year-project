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
import '../../providers/lang_provider.dart';

String _t(bool bn, String bangla, String english) => bn ? bangla : english;

// ---------------------------------------------------------------------------
// Weather emoji helper — day/night aware
// ---------------------------------------------------------------------------
String _weatherEmoji(String iconCode) {
  if (iconCode.length < 2) return '🌤️';
  final core = iconCode.substring(0, 2);
  final isNight = iconCode.endsWith('n');
  switch (core) {
    case '01':
      return isNight ? '🌙' : '☀️';
    case '02':
      return isNight ? '🌙' : '🌤️';
    case '03':
      return '⛅';
    case '04':
      return '☁️';
    case '09':
      return '🌧️';
    case '10':
      return isNight ? '🌧️' : '🌦️';
    case '11':
      return '⛈️';
    case '13':
      return '❄️';
    case '50':
      return '🌫️';
    default:
      return '🌤️';
  }
}

// ---------------------------------------------------------------------------
// Add-to-cart confirmation snackbar
// ---------------------------------------------------------------------------
void _showAddedToCartSnackBar(BuildContext context, Product product, bool bn) {
  ScaffoldMessenger.of(context).showSnackBar(
    SnackBar(
      content: Row(
        children: [
          const Icon(Icons.check_circle, color: Colors.white, size: 20),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              _t(bn, '${product.title} কার্টে যোগ হয়েছে',
                  '${product.title} added to cart'),
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
          ),
        ],
      ),
      backgroundColor: AppTheme.primaryGreen,
      behavior: SnackBarBehavior.floating,
      duration: const Duration(seconds: 2),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      margin: const EdgeInsets.fromLTRB(16, 0, 16, 16),
    ),
  );
}

// ---------------------------------------------------------------------------
// Pressable cart button — extracted widget so each card owns its own bool
// ---------------------------------------------------------------------------
class _PressableCartButton extends StatefulWidget {
  final VoidCallback onTap;
  const _PressableCartButton({required this.onTap});

  @override
  State<_PressableCartButton> createState() => _PressableCartButtonState();
}

class _PressableCartButtonState extends State<_PressableCartButton> {
  bool _pressing = false;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTapDown: (_) => setState(() => _pressing = true),
      onTapUp: (_) {
        setState(() => _pressing = false);
        widget.onTap();
      },
      onTapCancel: () => setState(() => _pressing = false),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 120),
        padding: const EdgeInsets.all(6),
        decoration: BoxDecoration(
          color: _pressing ? Colors.white : AppTheme.primaryGreen,
          shape: BoxShape.circle,
          border: Border.all(
            color: AppTheme.primaryGreen,
            width: 1.5,
          ),
        ),
        child: Icon(
          Icons.add_shopping_cart_rounded,
          color: _pressing ? AppTheme.primaryGreen : Colors.white,
          size: 16,
        ),
      ),
    );
  }
}

// ---------------------------------------------------------------------------
// Service Card — extracted widget with press feedback
// ---------------------------------------------------------------------------
class _ServiceCard extends StatefulWidget {
  final IconData icon;
  final String label;
  final Color color;
  final Color bgColor;
  final VoidCallback onTap;

  const _ServiceCard({
    required this.icon,
    required this.label,
    required this.color,
    required this.bgColor,
    required this.onTap,
  });

  @override
  State<_ServiceCard> createState() => _ServiceCardState();
}

class _ServiceCardState extends State<_ServiceCard> {
  bool _pressing = false;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTapDown: (_) => setState(() => _pressing = true),
      onTapUp: (_) {
        setState(() => _pressing = false);
        widget.onTap();
      },
      onTapCancel: () => setState(() => _pressing = false),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 150),
        padding: const EdgeInsets.all(8),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(
            color: _pressing ? widget.color : Colors.transparent,
            width: 1.5,
          ),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: _pressing ? 0.02 : 0.05),
              blurRadius: _pressing ? 4 : 8,
              offset: const Offset(0, 3),
            ),
          ],
        ),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            AnimatedContainer(
              duration: const Duration(milliseconds: 150),
              child: CircleAvatar(
                radius: 24,
                backgroundColor: _pressing
                    ? widget.color.withValues(alpha: 0.15)
                    : widget.bgColor,
                child: Icon(widget.icon, color: widget.color, size: 24),
              ),
            ),
            const SizedBox(height: 8),
            Flexible(
              child: Text(
                widget.label,
                textAlign: TextAlign.center,
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
                style: TextStyle(
                  fontSize: 11,
                  fontWeight: FontWeight.w600,
                  color: _pressing ? widget.color : const Color(0xFF1A1A1A),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class HomeScreen extends ConsumerStatefulWidget {
  const HomeScreen({super.key});

  @override
  ConsumerState<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends ConsumerState<HomeScreen> {
  bool _showTomorrow = false;
  int _currentTabIndex = 0;

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

  @override
  Widget build(BuildContext context) {
    final bn = ref.watch(langProvider);
    final user = ref.watch(currentUserProvider);
    final userName =
        user?.name.isNotEmpty == true ? user!.name : _t(bn, 'কৃষক', 'Farmer');

    final now = DateTime.now();
    final dateStr = bn
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
              _buildTopBar(context, userName, dateStr, bn),
              _buildWeatherSection(context, bn),
              const SizedBox(height: 14),
              const _PromoImageCarousel(),
              _buildSectionHeader(
                _t(bn, 'এই মৌসুমের সেরা ফসল', 'Best Crops This Season'),
                _t(bn, 'সব দেখুন', 'See All'),
                onActionTap: () =>
                    Navigator.pushNamed(context, AppRouter.calendar),
              ),
              _buildSeasonalCrops(activeCrops, calendarAsync.isLoading, bn),
              _buildSectionHeader(
                  _t(bn, 'আমাদের সেবাসমূহ', 'Our Services'), ''),
              _buildServicesGrid(bn),
              _buildSectionHeader(
                _t(bn, 'বাজারের নতুন পণ্য', 'New in the Market'),
                _t(bn, 'দোকানে যান', 'Go to Shop'),
                onActionTap: () =>
                    Navigator.pushNamed(context, AppRouter.market),
              ),
              marketState.isLoading
                  ? const Padding(
                      padding: EdgeInsets.symmetric(vertical: 32),
                      child: Center(
                          child: CircularProgressIndicator(
                              color: AppTheme.primaryGreen)),
                    )
                  : previewProducts.isEmpty
                      ? Padding(
                          padding: const EdgeInsets.symmetric(
                              horizontal: 16, vertical: 24),
                          child: Center(
                            child: Text(
                              _t(bn, 'কোনো পণ্য পাওয়া যায়নি',
                                  'No products found'),
                              style: TextStyle(
                                  color: Colors.grey.shade500, fontSize: 14),
                            ),
                          ),
                        )
                      : _buildProductGrid(previewProducts, bn),
              const SizedBox(height: 120),
            ],
          ),
        ),
      ),
      floatingActionButton: _buildFAB(),
      floatingActionButtonLocation: FloatingActionButtonLocation.endFloat,
      bottomNavigationBar: _buildBottomNav(bn),
    );
  }

  // -------------------------------------------------------------------------
  // TOP BAR
  // -------------------------------------------------------------------------
  Widget _buildTopBar(
      BuildContext context, String userName, String dateStr, bool bn) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.fromLTRB(20, 20, 20, 10),
      child: Row(
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(userName,
                    style: const TextStyle(
                        color: AppTheme.primaryGreen,
                        fontSize: 20,
                        fontWeight: FontWeight.bold)),
                Text(dateStr,
                    style:
                        const TextStyle(color: Colors.black54, fontSize: 13)),
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
                      color: Colors.grey.shade200, shape: BoxShape.circle),
                  child: const Icon(Icons.notifications_outlined,
                      color: Colors.black87, size: 20),
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
          // Global language toggle
          GestureDetector(
            onTap: () => ref.read(langProvider.notifier).state = !bn,
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
              decoration: BoxDecoration(
                  color: AppTheme.primaryGreen,
                  borderRadius: BorderRadius.circular(20)),
              child: Text(bn ? 'EN' : 'বাং',
                  style: const TextStyle(
                      color: Colors.white,
                      fontSize: 13,
                      fontWeight: FontWeight.w700)),
            ),
          ),
        ],
      ),
    );
  }

  // -------------------------------------------------------------------------
  // WEATHER SECTION
  // -------------------------------------------------------------------------
  Widget _buildWeatherSection(BuildContext context, bool bn) {
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
              _t(bn, 'আবহাওয়া লোড করা যায়নি। পুনরায় চেষ্টা করুন',
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
                      _t(bn, 'আজকের আবহাওয়া', "Today's Weather"),
                      style: TextStyle(
                        fontWeight: FontWeight.bold,
                        fontSize: 16,
                        color: !_showTomorrow ? Colors.black : Colors.grey[400],
                      ),
                    ),
                  ),
                  const Spacer(),
                  GestureDetector(
                    onTap: () =>
                        Navigator.pushNamed(context, AppRouter.weather),
                    child: Row(
                      children: [
                        Text(
                          _t(bn, 'পরবর্তী ৫ দিন', 'Next 5 Days'),
                          style: const TextStyle(
                              color: AppTheme.primaryGreen,
                              fontSize: 12,
                              fontWeight: FontWeight.w600),
                        ),
                        const SizedBox(width: 4),
                        Container(
                          width: 18,
                          height: 18,
                          decoration: BoxDecoration(
                            color:
                                AppTheme.primaryGreen.withValues(alpha: 0.12),
                            shape: BoxShape.circle,
                          ),
                          child: const Icon(Icons.arrow_forward_ios_rounded,
                              size: 10, color: AppTheme.primaryGreen),
                        ),
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
                      child: Text(_t(bn, 'আবহাওয়ার কোনো তথ্য পাওয়া যায়নি',
                          'No weather data available')))
                  : ListView.builder(
                      scrollDirection: Axis.horizontal,
                      padding: const EdgeInsets.symmetric(horizontal: 20),
                      physics: const BouncingScrollPhysics(),
                      itemCount: visibleHourly.length,
                      itemBuilder: (context, index) {
                        final item = visibleHourly[index];
                        final isActive = item == activeHourlyItem;
                        return _buildWeatherCard(item, isActive, bn);
                      },
                    ),
            ),
            const SizedBox(height: 10),
          ],
        );
      },
    );
  }

  Widget _buildWeatherCard(HourlyWeather w, bool isActive, bool bn) {
    final rawTimeStr = DateFormat('h a').format(w.time);
    final timeLabel = bn ? WeatherData.toBangla(rawTimeStr) : rawTimeStr;
    final tempLabel = bn
        ? '${WeatherData.toBangla(w.tempCelsius.round())}°'
        : '${w.tempCelsius.round()}°';
    final condLabel = bn
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
              color: Color(0xFFE0DEDE), blurRadius: 6, offset: Offset(0, 3)),
        ],
      ),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Text(timeLabel,
              style: TextStyle(
                  color: isActive ? Colors.white70 : Colors.grey, fontSize: 9)),
          const SizedBox(height: 4),
          Text(_weatherEmoji(w.iconCode), style: const TextStyle(fontSize: 18)),
          const SizedBox(height: 4),
          Text(tempLabel,
              style: TextStyle(
                  color: isActive ? Colors.white : Colors.black87,
                  fontSize: 12,
                  fontWeight: FontWeight.bold)),
          const SizedBox(height: 2),
          Text(condLabel,
              style: TextStyle(
                  color: isActive ? Colors.white70 : Colors.grey[600],
                  fontSize: 9,
                  fontWeight: FontWeight.w500)),
        ],
      ),
    );
  }

  // -------------------------------------------------------------------------
  // SECTION HEADER
  // -------------------------------------------------------------------------
  Widget _buildSectionHeader(String title, String action,
      {VoidCallback? onActionTap}) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 20, 16, 10),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(title,
              style: const TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                  color: Color(0xFF111D13))),
          if (action.isNotEmpty)
            GestureDetector(
              onTap: onActionTap,
              child: Row(
                children: [
                  Text(action,
                      style: const TextStyle(
                          color: AppTheme.primaryGreen,
                          fontWeight: FontWeight.w600,
                          fontSize: 13)),
                  const SizedBox(width: 4),
                  Container(
                    width: 18,
                    height: 18,
                    decoration: BoxDecoration(
                      color: AppTheme.primaryGreen.withValues(alpha: 0.12),
                      shape: BoxShape.circle,
                    ),
                    child: const Icon(Icons.arrow_forward_ios_rounded,
                        size: 10, color: AppTheme.primaryGreen),
                  ),
                ],
              ),
            ),
        ],
      ),
    );
  }

  // -------------------------------------------------------------------------
  // SEASONAL CROPS
  // -------------------------------------------------------------------------
  Widget _buildSeasonalCrops(
      List<CropCalendar> crops, bool isLoading, bool bn) {
    if (isLoading) {
      return const SizedBox(
        height: 120,
        child: Center(
            child: CircularProgressIndicator(color: AppTheme.primaryGreen)),
      );
    }
    if (crops.isEmpty) {
      return SizedBox(
        height: 80,
        child: Center(
          child: Text(
            _t(bn, 'এই মাসে কোনো ফসলের তথ্য নেই',
                'No crop data for this month'),
            style: TextStyle(color: Colors.grey.shade500, fontSize: 13),
          ),
        ),
      );
    }

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
      'ডিসে'
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
      'Dec'
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
          final months = bn ? monthNamesBn : monthNamesEn;
          final sowList = crop.sowMonths;
          final harvestList = crop.harvestMonths;
          String period = '';
          if (sowList.isNotEmpty && harvestList.isNotEmpty) {
            period =
                '${months[sowList.first.clamp(1, 12)]} - ${months[harvestList.last.clamp(1, 12)]}';
          } else if (sowList.isNotEmpty) {
            period = months[sowList.first.clamp(1, 12)];
          }
          final cropLabel = (!bn) ? crop.cropNameEn : crop.cropNameBn;

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
                        border:
                            Border.all(color: AppTheme.primaryGreen, width: 2),
                      ),
                      child: Center(
                        child: ClipOval(
                          child: crop.imageUrl != null
                              ? Image.network(crop.imageUrl!,
                                  height: 60,
                                  width: 60,
                                  fit: BoxFit.cover,
                                  errorBuilder: (ctx, _, __) => const Icon(
                                      Icons.grass,
                                      color: AppTheme.primaryGreen,
                                      size: 28))
                              : const Icon(Icons.grass,
                                  color: AppTheme.primaryGreen, size: 28),
                        ),
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(cropLabel,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        textAlign: TextAlign.center,
                        style: const TextStyle(
                            fontWeight: FontWeight.w600,
                            fontSize: 12,
                            color: Colors.black)),
                    if (period.isNotEmpty)
                      Text(period,
                          maxLines: 1,
                          textAlign: TextAlign.center,
                          style: TextStyle(
                              color: Colors.grey.shade600, fontSize: 10)),
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
  Widget _buildServicesGrid(bool bn) {
    final services = <Map<String, dynamic>>[
      {
        'icon': Icons.agriculture,
        'labelBn': 'যন্ত্রপাতি ভাড়া',
        'labelEn': 'Equipment Rental',
        'route': AppRouter.rentals,
        'color': const Color(0xFFFF9800),
        'bgColor': const Color(0xFFFFF3E0),
      },
      {
        'icon': Icons.medical_services_outlined,
        'labelBn': 'কৃষি ডাক্তার',
        'labelEn': 'Agri Doctor',
        'route': AppRouter.doctors,
        'color': const Color(0xFFE91E63),
        'bgColor': const Color(0xFFFCE4EC),
      },
      {
        'icon': Icons.menu_book_outlined,
        'labelBn': 'চাষ নির্দেশিকা',
        'labelEn': 'Guidelines',
        'route': AppRouter.guidelines,
        'color': const Color(0xFF009688),
        'bgColor': const Color(0xFFE0F2F1),
      },
      {
        'icon': Icons.landscape_outlined,
        'labelBn': 'মাটির গুণমান',
        'labelEn': 'Soil Quality',
        'route': AppRouter.soil,
        'color': const Color(0xFF8BC34A),
        'bgColor': const Color(0xFFF1F8E9),
      },
      {
        'icon': Icons.calendar_month_outlined,
        'labelBn': 'ফসল ক্যালেন্ডার',
        'labelEn': 'Crop Calendar',
        'route': AppRouter.calendar,
        'color': const Color(0xFF4CAF50),
        'bgColor': const Color(0xFFE8F5E9),
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
          return _ServiceCard(
            icon: svc['icon'] as IconData,
            label: bn ? svc['labelBn'] as String : svc['labelEn'] as String,
            color: svc['color'] as Color,
            bgColor: svc['bgColor'] as Color,
            onTap: () => Navigator.pushNamed(context, svc['route'] as String),
          );
        },
      ),
    );
  }

  // -------------------------------------------------------------------------
  // PRODUCT GRID
  // -------------------------------------------------------------------------
  Widget _buildProductGrid(List<Product> products, bool bn) {
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
            onTap: () => Navigator.pushNamed(context, AppRouter.productDetail,
                arguments: product),
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
                                ? Image.network(product.primaryImage!,
                                    fit: BoxFit.cover,
                                    errorBuilder: (_, __, ___) =>
                                        _imgFallback())
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
                            child: Text(product.categoryBn,
                                style: const TextStyle(
                                    color: Colors.white,
                                    fontSize: 10,
                                    fontWeight: FontWeight.bold)),
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
                        Text(product.title,
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: const TextStyle(
                                fontWeight: FontWeight.bold,
                                fontSize: 14,
                                color: Color(0xFF2D2D2D))),
                        const SizedBox(height: 8),
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Text('৳${product.price.toStringAsFixed(0)}',
                                style: const TextStyle(
                                    color: AppTheme.primaryGreen,
                                    fontWeight: FontWeight.w800,
                                    fontSize: 15)),
                            _PressableCartButton(
                              onTap: () {
                                ref
                                    .read(marketplaceProvider.notifier)
                                    .addToCart(product);
                                _showAddedToCartSnackBar(context, product, bn);
                              },
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
            child: Icon(Icons.image_outlined,
                color: Colors.grey.shade400, size: 36)),
      );

  Widget _buildFAB() {
    return FloatingActionButton(
      onPressed: () => Navigator.pushNamed(context, AppRouter.aiChat),
      backgroundColor: AppTheme.primaryGreen,
      shape: const CircleBorder(),
      child: const Icon(Icons.auto_awesome, color: Colors.white, size: 26),
    );
  }

// ---------------------------------------------------------------------------
// BOTTOM-NAV
// ---------------------------------------------------------------------------

  Widget _buildBottomNav(bool bn) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: const BorderRadius.only(
            topLeft: Radius.circular(24), topRight: Radius.circular(24)),
        boxShadow: [
          BoxShadow(
              color: Colors.black.withValues(alpha: 0.08),
              blurRadius: 10,
              offset: const Offset(0, -4))
        ],
      ),
      child: ClipRRect(
        borderRadius: const BorderRadius.only(
            topLeft: Radius.circular(24), topRight: Radius.circular(24)),
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
                label: _t(bn, 'হোম', 'Home')),
            BottomNavigationBarItem(
                icon: const Icon(Icons.store_outlined),
                label: _t(bn, 'বাজার', 'Market')),
            BottomNavigationBarItem(
                icon: const Icon(Icons.miscellaneous_services_outlined),
                label: _t(bn, 'সেবা', 'Services')),
            BottomNavigationBarItem(
                icon: const Icon(Icons.person_outline),
                label: _t(bn, 'প্রোফাইল', 'Profile')),
          ],
        ),
      ),
    );
  }
}

// ---------------------------------------------------------------------------
// PROMO CAROUSEL
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
      _pageController.animateToPage(next,
          duration: const Duration(milliseconds: 500), curve: Curves.easeInOut);
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
                    child: Image.asset(banner['asset']!,
                        fit: BoxFit.cover,
                        width: double.infinity,
                        errorBuilder: (ctx, _, __) => Container(
                              decoration: BoxDecoration(
                                color: AppTheme.primaryGreen
                                    .withValues(alpha: 0.1),
                                borderRadius: BorderRadius.circular(16),
                              ),
                              child: const Icon(Icons.image_outlined,
                                  color: AppTheme.primaryGreen, size: 40),
                            )),
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
