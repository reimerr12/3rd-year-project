import 'dart:async';
import 'package:flutter/material.dart';
import '../../core/router.dart';
import '../../core/theme.dart';

// ---------------------------------------------------------------------------
// IMPORTS — uncomment as each system is wired up
// ---------------------------------------------------------------------------
// import 'package:flutter_riverpod/flutter_riverpod.dart';
// import '../../providers/auth_provider.dart';
// import '../../providers/crop_calendar_provider.dart';
// import '../../providers/marketplace_provider.dart';
// import '../../providers/weather_provider.dart';
// import '../../models/crop_calendar.dart';
// import '../../models/product.dart';
// import 'package:cached_network_image/cached_network_image.dart';
// import 'package:intl/intl.dart';

// ---------------------------------------------------------------------------
// DUMMY DATA MODELS
// Lightweight local structs used until real Supabase data is wired in.
//
// Migration checklist (do all 3 steps for each model):
//   1. Delete the dummy class (_SeasonalCrop, _MarketProduct, _BannerItem).
//   2. Import the real model from lib/models/.
//   3. Replace the dummy list with a provider read inside build():
//        _dummySeasonalCrops  → ref.watch(cropCalendarProvider)
//        _dummyMarketProducts → ref.watch(marketplaceProvider).newArrivals
//        _dummyBanners        → ref.watch(promotionsProvider)
// ---------------------------------------------------------------------------

/// Mirrors a row from the `crop_calendar` Supabase table.
/// Real model: lib/models/crop_calendar.dart
class _SeasonalCrop {
  final String name;
  final String period;
  final Color color;
  final Color bgColor;
  final String imageUrl;

  const _SeasonalCrop({
    required this.name,
    required this.period,
    required this.color,
    required this.bgColor,
    required this.imageUrl,
  });
}

/// Mirrors a row from the `products` Supabase table.
/// Real model: lib/models/product.dart
class _MarketProduct {
  final String name;
  final int priceInTaka;
  final double rating;
  final int reviews;
  final String badge;
  final String imageUrl;

  const _MarketProduct({
    required this.name,
    required this.priceInTaka,
    required this.rating,
    required this.reviews,
    required this.badge,
    required this.imageUrl,
  });
}

class _HourlyWeather {
  final String time;
  final String temp;
  final IconData icon;
  final bool isActive;

  _HourlyWeather(this.time, this.temp, this.icon, {this.isActive = false});
}

/// Mirrors a row from the `promotions` Supabase table.
class _BannerItem {
  final String headline;
  final String subline;
  final Color startColor;
  final Color endColor;
  final String imageUrl;

  const _BannerItem({
    required this.headline,
    required this.subline,
    required this.startColor,
    required this.endColor,
    required this.imageUrl,
  });
}

// ---------------------------------------------------------------------------
// DUMMY DATA LISTS
// ---------------------------------------------------------------------------

const List<_SeasonalCrop> _dummySeasonalCrops = [
  _SeasonalCrop(
    name: 'ধান (বোরো)',
    period: 'মে - জুন',
    color: Color(0xFFF9A825),
    bgColor: Color(0xFFFFFDE7),
    imageUrl:
        'https://images.unsplash.com/photo-1615811361523-6bd03d7748e7?w=300&h=200&fit=crop',
  ),
  _SeasonalCrop(
    name: 'পাট',
    period: 'এপ্রিল - আগস্ট',
    color: Color(0xFF388E3C),
    bgColor: Color(0xFFE8F5E9),
    imageUrl:
        'https://images.unsplash.com/photo-1601329856734-7d1b853b24d2?w=300&h=200&fit=crop',
  ),
  _SeasonalCrop(
    name: 'আম',
    period: 'মে - জুলাই',
    color: Color(0xFFFF7043),
    bgColor: Color(0xFFFBE9E7),
    imageUrl:
        'https://images.unsplash.com/photo-1553279768-865429fa0078?w=300&h=200&fit=crop',
  ),
  _SeasonalCrop(
    name: 'শসা',
    period: 'মার্চ - মে',
    color: Color(0xFF43A047),
    bgColor: Color(0xFFE8F5E9),
    imageUrl:
        'https://images.unsplash.com/photo-1604977042946-1eecc30f269e?w=300&h=200&fit=crop',
  ),
];

const List<_MarketProduct> _dummyMarketProducts = [
  _MarketProduct(
    name: 'জৈব সার',
    priceInTaka: 450,
    rating: 4.6,
    reviews: 98,
    badge: 'জনপ্রিয়',
    // High-quality image of dark organic soil/compost
    imageUrl:
        'https://encrypted-tbn0.gstatic.com/images?q=tbn:ANd9GcRh4aNYL-1nB0Mi8pkPAJOeq2uuhqVOMBTf3g&s',
  ),
  _MarketProduct(
    name: 'টমেটো বীজ',
    priceInTaka: 120,
    rating: 4.8,
    reviews: 55,
    badge: 'নতুন',
    // Clear image of fresh tomatoes or seeds
    imageUrl:
        'https://encrypted-tbn0.gstatic.com/images?q=tbn:ANd9GcRxfRnl7rm3iErN3IYr2RIUEFhyblXrOoFz4A&sr',
  ),
  _MarketProduct(
    name: 'ধানের বীজ',
    priceInTaka: 280,
    rating: 4.5,
    reviews: 120,
    badge: 'সেরা',
    // Close up of high-quality grain/seeds
    imageUrl:
        'https://images.unsplash.com/photo-1536304993881-ff6e9eefa2a6?w=500&auto=format&fit=crop',
  ),
  _MarketProduct(
    name: 'সেচ পাম্প',
    priceInTaka: 12500,
    rating: 4.7,
    reviews: 34,
    badge: 'জনপ্রিয়',
    // Irrigation/Water pump or farm water system
    imageUrl:
        'https://5.imimg.com/data5/SELLER/Default/2024/12/474276131/FE/KL/JL/41249538/water-pump-500x500.png',
  ),
];

final List<_BannerItem> _dummyBanners = [
  const _BannerItem(
    headline: 'একসাথে কিনলে ছাড়!',
    subline: 'ধানের বীজে বিশেষ অফার!',
    startColor: AppTheme.primaryGreen,
    endColor: Color(0xFF1B5E20),
    imageUrl:
        'https://images.unsplash.com/photo-1592982537447-6f2a6a0c7c10?w=300&h=200&fit=crop',
  ),
  const _BannerItem(
    headline: 'নতুন বীজ পাওয়া যাচ্ছে',
    subline: 'সেরা মানের বীজ সংগ্রহ করুন!',
    startColor: AppTheme.skyBlue,
    endColor: Color(0xFF0D47A1),
    imageUrl:
        'https://images.unsplash.com/photo-1530836369250-ef72a3f5cda8?w=300&h=200&fit=crop',
  ),
  const _BannerItem(
    headline: 'কৃষি সরঞ্জামে ৩০% ছাড়',
    subline: 'সীমিত সময়ের অফার!',
    startColor: Color(0xFF7B1FA2),
    endColor: Color(0xFF4A148C),
    imageUrl:
        'https://images.unsplash.com/photo-1416879595882-3373a0480b5b?w=300&h=200&fit=crop',
  ),
];

// ---------------------------------------------------------------------------
// HOME SCREEN
//
// When Riverpod is wired, convert:
//   class HomeScreen extends StatefulWidget
//   →  class HomeScreen extends ConsumerStatefulWidget
//   class _HomeScreenState extends State<HomeScreen>
//   →  class _HomeScreenState extends ConsumerState<HomeScreen>
// ---------------------------------------------------------------------------

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  int _currentTabIndex = 0;

  void _onTabTapped(int index) {
    switch (index) {
      case 0:
        break;
      case 1:
        Navigator.pushNamed(context, AppRouter.market);
        break;
      case 2:
        // TODO: Navigator.pushNamed(context, AppRouter.services);
        break;
      case 3:
        Navigator.pushNamed(context, AppRouter.settings);
        break;
    }
    setState(() => _currentTabIndex = index);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      // Sets background to the light theme color
      backgroundColor: AppTheme.bgLight,

      // SafeArea ensures content doesn't overlap with status bar or notches
      body: SafeArea(
        child: SingleChildScrollView(
          // BouncingScrollPhysics provides a modern iOS-style feel when scrolling
          physics: const BouncingScrollPhysics(),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // 1. REFACTORED TOP BAR
              // Now contains Greeting, Location, and Avatar in a single transparent row
              _buildTopBar(context),

              // 2. WEATHER SECTION (WhatsApp Style)
              // Displays horizontal hourly pills with the active hour highlighted in green
              _buildWeatherSection(context),

              // 3. SEARCH BAR
              // Positioned after the weather for better accessibility
              _buildSearchBar(),

              const SizedBox(height: 14),

              // 4. PROMO BANNERS
              // Displays marketing or informational carousels
              _PromoCarousel(banners: _dummyBanners),

              // 5. SEASONAL CROPS SECTION
              // Uses circular icons for crops like "Tomato" and "Paddy"
              _buildSectionHeader(
                'এই মৌসুমের সেরা ফসল',
                'সব দেখুন',
                onActionTap: () =>
                    Navigator.pushNamed(context, AppRouter.calendar),
              ),
              _buildSeasonalCrops(_dummySeasonalCrops),

              // 6. SERVICES SECTION
              // Displays agricultural services offered by the app
              _buildSectionHeader('আমাদের সেবাসমূহ', ''),
              _buildServicesGrid(),

              // 7. MARKETPLACE SECTION
              // Updated to use high-quality Unsplash images and a modern "Add to Cart" button
              // Fixed childAspectRatio (0.75) and removed ratings to prevent overflow
              _buildSectionHeader(
                'বাজারের নতুন পণ্য',
                'দোকানে যান',
                onActionTap: () =>
                    Navigator.pushNamed(context, AppRouter.market),
              ),
              _buildProductGrid(_dummyMarketProducts),

              // 8. BOTTOM SPACING
              // Ensures the last items are visible above the floating button and nav bar
              const SizedBox(height: 120),
            ],
          ),
        ),
      ),

      // 9. CIRCULAR FLOATING ACTION BUTTON
      // Modern circular "AI Assistant" button without the extended label
      floatingActionButton: _buildFAB(),
      floatingActionButtonLocation: FloatingActionButtonLocation.endFloat,

      // 10. ROUNDED BOTTOM NAVIGATION BAR
      // Wrapped in ClipRRect to provide a premium curved-corner look
      bottomNavigationBar: _buildBottomNav(),
    );
  }

  // -------------------------------------------------------------------------
  // TOP BAR
  // -------------------------------------------------------------------------
  // TODO(auth): Replace hardcoded greeting name 'রহিম' with:
  //   ref.watch(authProvider).user?.displayName ?? 'কৃষক'
  // TODO(i18n): Replace hardcoded date string 'মঙ্গলবার, ২০ মে ২০২৬' with:
  //   DateFormat('EEEE, d MMMM yyyy', 'bn').format(DateTime.now())
  //   Requires: intl package + Bengali locale data loaded in main.dart
  // TODO(auth): Replace pravatar placeholder URL with:
  //   ref.watch(authProvider).user?.avatarUrl ?? a local fallback asset
  //   Consider wrapping in CachedNetworkImage for offline resilience
  Widget _buildTopBar(BuildContext context) {
    return Container(
      width: double.infinity,
      padding:
          const EdgeInsets.fromLTRB(20, 20, 20, 10), // Tightened top padding
      child: const Row(
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'আসসালামু আলাইকুম, রহিম!',
                  style: TextStyle(
                    color: AppTheme.primaryGreen,
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                Text(
                  'মঙ্গলবার, ২০ মে ২০২৬',
                  style: TextStyle(color: Colors.black54, fontSize: 13),
                ),
              ],
            ),
          ),
          /* // Location moved to the top right for a cleaner look
          Row(
            children: [
              Icon(Icons.near_me_outlined, color: AppTheme.primaryGreen),
              SizedBox(width: 4),
              Text(
                'সিলেট',
                style: TextStyle(
                    color: AppTheme.primaryGreen,
                    fontSize: 13,
                    fontWeight: FontWeight.w700),
              ),
            ],
          ), */
          SizedBox(width: 12),
          CircleAvatar(
            radius: 18,
            backgroundImage: NetworkImage('https://i.pravatar.cc/150?u=rahim'),
          ),
        ],
      ),
    );
  }

  // -------------------------------------------------------------------------
  // WEATHER SECTION
  // -------------------------------------------------------------------------

  // TODO(weather): Replace dummy `hourly` list with:
  //   ref.watch(weatherProvider).hourlyForecast
  //   Model: lib/models/weather.dart → HourlyWeather { time, tempCelsius, condition }
  //   API: OpenWeatherMap One Call 3.0 → /onecall?lat=&lon=&exclude=minutely,alerts
  //   Map condition codes → Icons: see lib/utils/weather_icon_mapper.dart (to create)
  // TODO(weather): 'isActive' should be the hour closest to DateTime.now(), not hardcoded index 1
  //   Logic: hourly.indexWhere((h) => h.time is nearest to current hour)
  // TODO(l10n): 'Today' / 'Tomorrow' labels should use AppLocalizations or Bengali strings
  // TODO(weather): 'Tomorrow' tab should be tappable — toggle between today/tomorrow hourly slices
  //   State: add `bool _showTomorrow = false;` or a small Riverpod StateProvider
  // TODO(weather): Pull user's lat/lng for weather query from:
  //   ref.watch(locationProvider) — request permission on first launch
  Widget _buildWeatherSection(BuildContext context) {
    final hourly = [
      _HourlyWeather('12:00', '26', Icons.wb_cloudy_outlined),
      _HourlyWeather('02:00', '28', Icons.wb_cloudy,
          isActive: true), // Active card highlighted in green
      _HourlyWeather('04:00', '23', Icons.thunderstorm_outlined),
      _HourlyWeather('06:00', '26', Icons.wb_sunny_outlined),
      _HourlyWeather('08:00', '27', Icons.wb_cloudy_outlined),
    ];

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
          child: Row(
            children: [
              const Text('Today',
                  style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
              const SizedBox(width: 20),
              Text('Tomorrow',
                  style: TextStyle(color: Colors.grey[400], fontSize: 16)),
              const Spacer(),
              TextButton(
                onPressed: () =>
                    Navigator.pushNamed(context, AppRouter.weather),
                child: const Row(
                  children: [
                    Text('Next 7 Days',
                        // ── CHANGED: was Colors.blue → AppTheme.primaryGreen ──
                        style: TextStyle(
                            color: AppTheme.primaryGreen, fontSize: 12)),
                    Icon(Icons.chevron_right,
                        size: 16,
                        // ── CHANGED: was Colors.blue → AppTheme.primaryGreen ──
                        color: AppTheme.primaryGreen),
                  ],
                ),
              )
            ],
          ),
        ),
        SizedBox(
          height: 110,
          child: ListView.builder(
            scrollDirection: Axis.horizontal,
            padding: const EdgeInsets.symmetric(horizontal: 20),
            itemCount: hourly.length,
            itemBuilder: (context, index) => _buildWeatherCard(hourly[index]),
          ),
        ),
        const SizedBox(height: 20), // Spacing before search bar
      ],
    );
  }

  // TODO(weather): Replace _HourlyWeather dummy model with real HourlyWeather from lib/models/weather.dart
  // TODO(weather): tempCelsius should display as '${w.temp}°C' or toggle °F based on user prefs
  Widget _buildWeatherCard(_HourlyWeather w) {
    return Container(
      width: 52,
      margin: const EdgeInsets.only(right: 12),
      padding: const EdgeInsets.symmetric(vertical: 12),
      decoration: BoxDecoration(
        // ── CHANGED: active card was Colors.blue → AppTheme.primaryGreen ──
        color: w.isActive ? AppTheme.primaryGreen : Colors.white,
        borderRadius: BorderRadius.circular(25), // Pill shape
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
          Text(w.time,
              style: TextStyle(
                  color: w.isActive ? Colors.white70 : Colors.grey,
                  fontSize: 9)),
          const SizedBox(height: 6),
          Icon(w.icon,
              // ── CHANGED: inactive icon was Colors.blueAccent → AppTheme.primaryGreen ──
              color: w.isActive ? Colors.white : AppTheme.primaryGreen,
              size: 18),
          const SizedBox(height: 6),
          Text('${w.temp}°',
              style: TextStyle(
                  color: w.isActive ? Colors.white : Colors.black87,
                  fontSize: 12,
                  fontWeight: FontWeight.bold)),
        ],
      ),
    );
  }

  // -------------------------------------------------------------------------
  // SEARCH BAR
  // -------------------------------------------------------------------------

  Widget _buildSearchBar() {
    return GestureDetector(
      // TODO: Navigator.pushNamed(context, AppRouter.search);
      onTap: () {},
      child: Container(
        margin: const EdgeInsets.fromLTRB(16, 16, 16, 0),
        height: 46,
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(24),
          boxShadow: [
            BoxShadow(
              // ── CHANGED: withOpacity(0.05) → withValues(alpha: 0.05) ──
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
              'পণ্য বা সেবা খুঁজুন...',
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

  Widget _buildSeasonalCrops(List<_SeasonalCrop> crops) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        SizedBox(
          // Height adjusted to fit the circle and two lines of text
          height: 120,
          child: ListView.builder(
            scrollDirection: Axis.horizontal,
            physics:
                const BouncingScrollPhysics(), // Smoother feel for long lists
            padding: const EdgeInsets.symmetric(horizontal: 20),
            itemCount: crops.length,
            itemBuilder: (context, index) {
              final crop = crops[index];
              return Padding(
                padding:
                    const EdgeInsets.only(right: 18), // Spacing between circles
                child: GestureDetector(
                  onTap: () => Navigator.pushNamed(context, AppRouter.calendar),
                  child: SizedBox(
                    width: 74, // Fixed width for consistent alignment
                    child: Column(
                      children: [
                        // Circular Image with Border
                        Container(
                          height: 70,
                          width: 70,
                          decoration: BoxDecoration(
                            shape: BoxShape.circle,
                            // ── CHANGED: withOpacity(0.3) → withValues(alpha: 0.3) ──
                            color: crop.bgColor.withValues(alpha: 0.3),
                            border: Border.all(
                              color: crop.color,
                              width: 1.5,
                            ),
                          ),
                          child: Center(
                            child: ClipOval(
                              child: Image.network(
                                crop.imageUrl,
                                height:
                                    60, // Slightly smaller than container for padding
                                width: 60,
                                fit: BoxFit.cover,
                                errorBuilder: (ctx, _, __) => Icon(
                                  Icons.grass,
                                  color: crop.color,
                                  size: 28,
                                ),
                              ),
                            ),
                          ),
                        ),
                        const SizedBox(height: 4),

                        // Crop Name
                        Text(
                          crop.name,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          textAlign: TextAlign.center,
                          style: const TextStyle(
                            fontWeight: FontWeight.w600,
                            fontSize: 12,
                            color: Colors.black,
                          ),
                        ),

                        // Date/Period
                        Text(
                          crop.period,
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
        ),
      ],
    );
  }

  // -------------------------------------------------------------------------
  // SERVICES GRID
  // -------------------------------------------------------------------------

  Widget _buildServicesGrid() {
    final services = <Map<String, dynamic>>[
      {
        'icon': Icons.agriculture,
        'label': 'যন্ত্রপাতি ভাড়া',
        'route': AppRouter.rentals
      },
      {
        'icon': Icons.medical_services_outlined,
        'label': 'কৃষি ডাক্তার',
        'route': AppRouter.doctors
      },
      {
        'icon': Icons.location_on_outlined,
        'label': 'নিকটস্থ নার্সারি',
        'route': AppRouter.nearby
      },
      {
        'icon': Icons.menu_book_outlined,
        'label': 'চাষ নির্দেশিকা',
        'route': AppRouter.guidelines
      },
      {
        'icon': Icons.landscape_outlined,
        'label': 'মাটির গুণমান',
        'route': AppRouter.soil
      },
      {
        'icon': Icons.calendar_month_outlined,
        'label': 'ফসল ক্যালেন্ডার',
        'route': AppRouter.calendar
      },
      {
        'icon': Icons.wb_cloudy_outlined,
        'label': 'আবহাওয়া',
        'route': AppRouter.weather
      },
    ];

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      child: GridView.builder(
        shrinkWrap: true,
        physics: const NeverScrollableScrollPhysics(),
        gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
          crossAxisCount: 3, // Changed from 4 to 3
          childAspectRatio: 1.0, // Increased to 1.0 (Square) to fix overflow
          crossAxisSpacing: 12,
          mainAxisSpacing: 12,
        ),
        itemCount: services.length,
        itemBuilder: (context, index) {
          final svc = services[index];
          return GestureDetector(
            onTap: () => Navigator.pushNamed(context, svc['route'] as String),
            child: Container(
              padding: const EdgeInsets.all(8), // Add internal padding
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(16),
                boxShadow: [
                  BoxShadow(
                    // ── CHANGED: withOpacity(0.05) → withValues(alpha: 0.05) ──
                    color: Colors.black.withValues(alpha: 0.05),
                    blurRadius: 8,
                    offset: const Offset(0, 3),
                  ),
                ],
              ),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  // Icon section
                  CircleAvatar(
                    radius: 24, // Slightly larger since we have more room
                    backgroundColor: const Color(0xFFF0F4F0),
                    child: Icon(
                      svc['icon'] as IconData,
                      color: AppTheme.primaryGreen,
                      size: 24,
                    ),
                  ),
                  const SizedBox(height: 8),
                  // Text section - Wrapped in Flexible to prevent overflow
                  Flexible(
                    child: Text(
                      svc['label'] as String,
                      textAlign: TextAlign.center,
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(
                        fontSize:
                            11, // Slightly larger font since items are bigger
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

  Widget _buildProductGrid(List<_MarketProduct> products) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      child: GridView.builder(
        shrinkWrap: true,
        physics: const NeverScrollableScrollPhysics(),
        gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
          crossAxisCount: 2,
          crossAxisSpacing: 14,
          mainAxisSpacing: 14,
          childAspectRatio:
              0.75, // Adjusted to fit image and the new bottom row
        ),
        itemCount: products.length,
        itemBuilder: (context, index) {
          final product = products[index];
          return Container(
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(16),
              boxShadow: [
                BoxShadow(
                  // ── CHANGED: withOpacity(0.04) → withValues(alpha: 0.04) ──
                  color: Colors.black.withValues(alpha: 0.04),
                  blurRadius: 10,
                  offset: const Offset(0, 4),
                ),
              ],
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // 1. Image Section (Expanded to fill top space)
                Expanded(
                  flex: 3,
                  child: Stack(
                    children: [
                      Positioned.fill(
                        child: ClipRRect(
                          borderRadius: const BorderRadius.vertical(
                              top: Radius.circular(16)),
                          child: Image.network(
                            product.imageUrl,
                            fit: BoxFit.cover,
                          ),
                        ),
                      ),
                      Positioned(
                        top: 8,
                        left: 8,
                        child: Container(
                          padding: const EdgeInsets.symmetric(
                              horizontal: 8, vertical: 4),
                          decoration: BoxDecoration(
                            // ── CHANGED: withOpacity(0.9) → withValues(alpha: 0.9) ──
                            color: AppTheme.primaryGreen.withValues(alpha: 0.9),
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: Text(
                            product.badge,
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

                // 2. Info Section
                Padding(
                  padding: const EdgeInsets.all(12),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        product.name,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: const TextStyle(
                          fontWeight: FontWeight.bold,
                          fontSize: 14,
                          color: Color(0xFF2D2D2D),
                        ),
                      ),
                      const SizedBox(height: 12), // Space before price row

                      // 3. Price and Add to Cart Row
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Text(
                            '৳${product.priceInTaka}',
                            style: const TextStyle(
                              color: AppTheme.primaryGreen,
                              fontWeight: FontWeight.w800,
                              fontSize: 15,
                            ),
                          ),
                          // Add to Cart Button
                          GestureDetector(
                            onTap: () {
                              // TODO: Add to cart logic
                            },
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
          );
        },
      ),
    );
  }

  // -------------------------------------------------------------------------
  // FAB — AI assistant shortcut
  // -------------------------------------------------------------------------

  Widget _buildFAB() {
    return FloatingActionButton(
      onPressed: () => Navigator.pushNamed(context, AppRouter.aiChat),
      backgroundColor: AppTheme.primaryGreen,
      // Using shape to ensure it stays perfectly circular
      shape: const CircleBorder(),
      child: const Icon(
        Icons.psychology_outlined,
        color: Colors.white,
        size: 28, // Slightly larger icon looks better in a circle
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
          topLeft: Radius.circular(24), // Rounded top-left
          topRight: Radius.circular(24), // Rounded top-right
        ),
        boxShadow: [
          BoxShadow(
            // ── CHANGED: withOpacity(0.08) → withValues(alpha: 0.08) ──
            color: Colors.black.withValues(alpha: 0.08),
            blurRadius: 10,
            offset: const Offset(0, -4), // Shadow pushed upwards
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
          elevation: 0, // Set to 0 because we are using the Container's shadow
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

// ---------------------------------------------------------------------------
// PROMO CAROUSEL
// ---------------------------------------------------------------------------

class _PromoCarousel extends StatefulWidget {
  final List<_BannerItem> banners;
  const _PromoCarousel({required this.banners});

  @override
  State<_PromoCarousel> createState() => _PromoCarouselState();
}

class _PromoCarouselState extends State<_PromoCarousel> {
  final PageController _pageController = PageController();
  int _currentPage = 0;
  Timer? _timer;

  @override
  void initState() {
    super.initState();
    _timer = Timer.periodic(const Duration(seconds: 5), (_) {
      final next = (_currentPage + 1) % widget.banners.length;
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
            itemCount: widget.banners.length,
            onPageChanged: (i) => setState(() => _currentPage = i),
            itemBuilder: (context, index) =>
                _BannerCard(banner: widget.banners[index]),
          ),
        ),
        const SizedBox(height: 8),
        Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: List.generate(widget.banners.length, (i) {
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

// ---------------------------------------------------------------------------
// BANNER CARD
// ---------------------------------------------------------------------------

class _BannerCard extends StatelessWidget {
  final _BannerItem banner;
  const _BannerCard({required this.banner});

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [banner.startColor, banner.endColor],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(16),
      ),
      child: Stack(
        children: [
          Positioned(
            right: -10,
            top: -10,
            child: Container(
              width: 100,
              height: 100,
              decoration: const BoxDecoration(
                shape: BoxShape.circle,
                color: Color.fromARGB(18, 255, 255, 255),
              ),
            ),
          ),
          Positioned(
            right: 40,
            bottom: -20,
            child: Container(
              width: 70,
              height: 70,
              decoration: const BoxDecoration(
                shape: BoxShape.circle,
                color: Color.fromARGB(13, 255, 255, 255),
              ),
            ),
          ),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
            child: Row(
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Text(
                        banner.headline,
                        style: const TextStyle(
                          color: Colors.white,
                          fontWeight: FontWeight.bold,
                          fontSize: 15,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        banner.subline,
                        style: const TextStyle(
                          color: Color.fromARGB(204, 255, 255, 255),
                          fontSize: 11,
                        ),
                      ),
                      const SizedBox(height: 10),
                      SizedBox(
                        height: 30,
                        child: ElevatedButton(
                          onPressed: () {},
                          style: ElevatedButton.styleFrom(
                            backgroundColor: Colors.white,
                            foregroundColor: AppTheme.primaryGreen,
                            padding: const EdgeInsets.symmetric(horizontal: 16),
                            minimumSize: Size.zero,
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(20),
                            ),
                          ),
                          child: const Text(
                            'দেখুন',
                            style: TextStyle(
                                fontWeight: FontWeight.bold, fontSize: 12),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
                // TODO: swap for CachedNetworkImage
                ClipRRect(
                  borderRadius: BorderRadius.circular(10),
                  child: Image.network(
                    banner.imageUrl,
                    width: 85,
                    height: 85,
                    fit: BoxFit.cover,
                    loadingBuilder: (ctx, child, progress) => progress == null
                        ? child
                        : Container(
                            width: 85,
                            height: 85,
                            decoration: BoxDecoration(
                              // ── CHANGED: withOpacity(0.2) → withValues(alpha: 0.2) ──
                              color: Colors.white.withValues(alpha: 0.2),
                              borderRadius: BorderRadius.circular(10),
                            ),
                          ),
                    errorBuilder: (ctx, _, __) => Container(
                      width: 85,
                      height: 85,
                      decoration: BoxDecoration(
                        // ── CHANGED: withOpacity(0.2) → withValues(alpha: 0.2) ──
                        color: Colors.white.withValues(alpha: 0.2),
                        borderRadius: BorderRadius.circular(10),
                      ),
                      child: const Icon(Icons.image_outlined,
                          color: Colors.white54, size: 30),
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
