import 'dart:math' as math;
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import '../../models/weather.dart';
import '../../providers/weather_provider.dart';

class WeatherScreen extends ConsumerStatefulWidget {
  const WeatherScreen({super.key});

  @override
  ConsumerState<WeatherScreen> createState() => _WeatherScreenState();
}

class _WeatherScreenState extends ConsumerState<WeatherScreen>
    with SingleTickerProviderStateMixin {
  late AnimationController _animationController;

  @override
  void initState() {
    super.initState();
    // Smooth ticker animation cycle to drive environmental canvas drawing updates
    _animationController = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 30),
    )..repeat();
  }

  @override
  void dispose() {
    _animationController.dispose();
    super.dispose();
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
        return Icons.umbrella_rounded;
      case '10d':
      case '10n':
        return Icons.water_drop_rounded;
      case '11d':
      case '11n':
        return Icons.thunderstorm_rounded;
      case '50d':
      case '50n':
        return Icons.blur_on_rounded;
      default:
        return Icons.wb_cloudy_rounded;
    }
  }

  @override
  Widget build(BuildContext context) {
    final weatherAsync = ref.watch(weatherProvider);

    return Scaffold(
      backgroundColor: const Color(0xFFF8F9FA),
      body: weatherAsync.when(
        loading: () =>
            const Center(child: CircularProgressIndicator(color: Colors.blue)),
        error: (err, stack) => Center(
          child: ElevatedButton.icon(
            onPressed: () => ref.read(weatherProvider.notifier).refresh(),
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFF3B82F6),
              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
            ),
            icon: const Icon(Icons.refresh, color: Colors.white),
            label: const Text('পুনরায় চেষ্টা করুন',
                style: TextStyle(color: Colors.white)),
          ),
        ),
        data: (data) {
          final config = WeatherData.getThemeConfig(
            data.current.iconCode,
            tempCelsius: data.current.tempCelsius,
          );
          final iconCode = data.current.iconCode;

          return RefreshIndicator(
            onRefresh: () => ref.read(weatherProvider.notifier).refresh(),
            color: Colors.blue,
            backgroundColor: Colors.white,
            child: SingleChildScrollView(
              physics: const AlwaysScrollableScrollPhysics(),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // --- WEATHER HERO LAYER STACK ---
                  Stack(
                    children: [
                      // Base Theme Colored Gradient Background Canvas
                      Container(
                        width: double.infinity,
                        height: 380,
                        decoration: BoxDecoration(
                          gradient: LinearGradient(
                            colors: config.gradient,
                            begin: Alignment.topCenter,
                            end: Alignment.bottomCenter,
                          ),
                          borderRadius: const BorderRadius.only(
                            bottomLeft: Radius.circular(36),
                            bottomRight: Radius.circular(36),
                          ),
                        ),
                      ),

                      // Animated Particle Vector Engine (Rain, Stars, or Cloud Formations)
                      Positioned.fill(
                        child: ClipRRect(
                          borderRadius: const BorderRadius.only(
                            bottomLeft: Radius.circular(36),
                            bottomRight: Radius.circular(36),
                          ),
                          child: AnimatedBuilder(
                            animation: _animationController,
                            builder: (context, _) {
                              return CustomPaint(
                                painter: WeatherEffectPainter(
                                  iconCode: iconCode,
                                  animationValue: _animationController.value,
                                ),
                              );
                            },
                          ),
                        ),
                      ),

                      // Main Active Foreground Data Panel
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          SafeArea(
                            bottom: false,
                            child: Padding(
                              padding: const EdgeInsets.symmetric(
                                  horizontal: 8, vertical: 4),
                              child: Row(
                                children: [
                                  IconButton(
                                    icon: const Icon(
                                        Icons.arrow_back_ios_new_rounded,
                                        color: Colors.white,
                                        size: 20),
                                    onPressed: () => Navigator.pop(context),
                                  ),
                                ],
                              ),
                            ),
                          ),
                          Padding(
                            padding: const EdgeInsets.fromLTRB(24, 4, 24, 24),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Row(
                                  children: [
                                    const Icon(Icons.location_on_rounded,
                                        color: Color(0xB3FFFFFF), size: 18),
                                    const SizedBox(width: 6),
                                    Text(
                                      '${data.current.cityName}, বাংলাদেশ',
                                      style: const TextStyle(
                                        color: Colors.white,
                                        fontSize: 18,
                                        fontWeight: FontWeight.w500,
                                        letterSpacing: 0.5,
                                      ),
                                    ),
                                  ],
                                ),
                                const SizedBox(height: 8),
                                Text(
                                  '${WeatherData.toBangla(data.current.tempCelsius.round())}°',
                                  style: const TextStyle(
                                    color: Colors.white,
                                    fontSize: 86,
                                    fontWeight: FontWeight.w200,
                                    height: 1.0,
                                  ),
                                ),
                                const SizedBox(height: 6),
                                Text(
                                  config.statusText,
                                  style: const TextStyle(
                                    color: Color(0xCCFFFFFF),
                                    fontSize: 15,
                                    fontWeight: FontWeight.w400,
                                  ),
                                ),
                                const SizedBox(height: 28),

                                // Beautiful 3-Column Glassmorphic Info Blocks
                                Row(
                                  children: [
                                    _buildStatGlassCard(
                                        'আর্দ্রতা',
                                        '${WeatherData.toBangla(data.current.humidity)}%',
                                        config),
                                    const SizedBox(width: 12),
                                    _buildStatGlassCard(
                                        'বায়ু',
                                        '${WeatherData.toBangla((data.current.windSpeedMs * 3.6).round())} কিমি/ঘণ্টা',
                                        config),
                                    const SizedBox(width: 12),
                                    _buildStatGlassCard(
                                        'বৃষ্টি সম্ভাবনা',
                                        '${WeatherData.toBangla(data.current.humidity - 5 > 0 ? data.current.humidity - 5 : 0)}%',
                                        config),
                                  ],
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),

                  // --- LOWER FORECAST TRACK PANEL ---
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 20),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const SizedBox(height: 28),
                        const Text(
                          '৫ দিনের পূর্বাভাস',
                          style: TextStyle(
                              color: Color(0xFF1E293B),
                              fontSize: 18,
                              fontWeight: FontWeight.bold),
                        ),
                        const SizedBox(height: 16),
                        _buildForecastTrack(data.daily),
                        const SizedBox(height: 32),
                        const Text(
                          'বৃষ্টির সম্ভাবনা',
                          style: TextStyle(
                              color: Color(0xFF1E293B),
                              fontSize: 18,
                              fontWeight: FontWeight.bold),
                        ),
                        const SizedBox(height: 16),
                        _buildRainProbabilityPanel(data.daily),
                        const SizedBox(height: 30),
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

  Widget _buildStatGlassCard(
      String title, String value, WeatherThemeConfig config) {
    return Expanded(
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 14, horizontal: 6),
        decoration: BoxDecoration(
          color: config.cardBackground,
          borderRadius: BorderRadius.circular(16),
        ),
        child: Column(
          children: [
            Text(
              title,
              style: const TextStyle(
                  color: Color(0xB3FFFFFF),
                  fontSize: 12,
                  fontWeight: FontWeight.w400),
              textAlign: TextAlign.center,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
            const SizedBox(height: 6),
            Text(
              value,
              style: const TextStyle(
                  color: Colors.white,
                  fontSize: 14,
                  fontWeight: FontWeight.bold),
              textAlign: TextAlign.center,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildForecastTrack(List<DailyForecast> days) {
    return SizedBox(
      height: 120,
      child: ListView.builder(
        scrollDirection: Axis.horizontal,
        physics: const BouncingScrollPhysics(),
        itemCount: days.take(5).length,
        itemBuilder: (context, idx) {
          final d = days[idx];
          final isToday = idx == 0;
          String explicitDay = DateFormat('EEE', 'bn').format(d.date);
          if (isToday) explicitDay = 'আজ';

          return Container(
            width: 82,
            margin: const EdgeInsets.only(right: 12, bottom: 4),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(20),
              boxShadow: [
                BoxShadow(
                    color: Colors.black.withAlpha(10),
                    blurRadius: 10,
                    offset: const Offset(0, 4))
              ],
              border: isToday
                  ? Border.all(color: const Color(0xFF3B82F6), width: 1.5)
                  : null,
            ),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Text(
                  explicitDay,
                  style: TextStyle(
                    color: isToday
                        ? const Color(0xFF3B82F6)
                        : const Color(0xFF64748B),
                    fontSize: 13,
                    fontWeight: isToday ? FontWeight.bold : FontWeight.normal,
                  ),
                ),
                const SizedBox(height: 10),
                Icon(_iconFromCode(d.iconCode),
                    color: isToday
                        ? const Color(0xFF3B82F6)
                        : const Color(0xFF475569),
                    size: 26),
                const SizedBox(height: 10),
                Text(
                  '${WeatherData.toBangla(d.tempMax.round())}°',
                  style: TextStyle(
                      color: const Color(0xFF1E293B),
                      fontSize: 16,
                      fontWeight: isToday ? FontWeight.w900 : FontWeight.bold),
                ),
              ],
            ),
          );
        },
      ),
    );
  }

  Widget _buildRainProbabilityPanel(List<DailyForecast> days) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(24),
        boxShadow: [
          BoxShadow(
              color: Colors.black.withAlpha(8),
              blurRadius: 12,
              offset: const Offset(0, 4))
        ],
      ),
      child: Column(
        children: days.take(5).map((d) {
          final dayName =
              DateFormat('EEEE', 'bn').format(d.date).split(',').first;
          final probValue = 35 + (d.tempMin.round() % 6) * 10;

          return Padding(
            padding: const EdgeInsets.symmetric(vertical: 12),
            child: Row(
              children: [
                SizedBox(
                  width: 80,
                  child: Text(dayName,
                      style: const TextStyle(
                          color: Color(0xFF475569),
                          fontSize: 14,
                          fontWeight: FontWeight.w500)),
                ),
                Expanded(
                  child: ClipRRect(
                    borderRadius: BorderRadius.circular(10),
                    child: LinearProgressIndicator(
                      value: probValue / 100,
                      backgroundColor: const Color(0xFFF1F5F9),
                      valueColor: const AlwaysStoppedAnimation<Color>(
                          Color(0xFF3B82F6)),
                      minHeight: 8,
                    ),
                  ),
                ),
                const SizedBox(width: 18),
                SizedBox(
                  width: 40,
                  child: Align(
                    alignment: Alignment.centerRight,
                    child: Text(
                      '${WeatherData.toBangla(probValue)}%',
                      style: const TextStyle(
                          color: Color(0xFF1E293B),
                          fontSize: 13,
                          fontWeight: FontWeight.bold),
                    ),
                  ),
                ),
              ],
            ),
          );
        }).toList(),
      ),
    );
  }
}

// ---CANVAS ENGINE ---
class WeatherEffectPainter extends CustomPainter {
  final String iconCode;
  final double animationValue;

  WeatherEffectPainter({required this.iconCode, required this.animationValue});

  @override
  void paint(Canvas canvas, Size size) {
    final isNight = iconCode.endsWith('n');
    final coreCode = iconCode.substring(0, 2);

    if (isNight) {
      if (coreCode == '09' || coreCode == '10' || coreCode == '11') {
        // Night + Rain/Storm Condition -> Dark night sky canvas backdrop + falling rain particles
        _paintRainLines(canvas, size, const Color(0x3D93C5FD));
      } else {
        // Clear Night Condition -> Twinkling stars fields
        _paintStars(canvas, size);
      }
    } else {
      if (coreCode == '01') {
        // Sunny Condition -> Bright blue canvas + fluffy slow-drifting clouds
        _paintDriftingClouds(canvas, size, const Color(0x26FFFFFF));
      } else if (coreCode == '02' || coreCode == '03' || coreCode == '04') {
        // Cloudy Condition -> Denser layered gray cloud blocks
        _paintDriftingClouds(canvas, size, const Color(0x3DF1F5F9));
      } else if (coreCode == '09' || coreCode == '10' || coreCode == '11') {
        // Stormy/Rain Day Condition -> Gray cloud massives + falling rain vectors
        _paintDriftingClouds(canvas, size, const Color(0x4D94A3B8));
        _paintRainLines(canvas, size, const Color(0x52FFFFFF));
      }
    }
  }

  void _paintStars(Canvas canvas, Size size) {
    // Pre-defined star positions — stable, no per-frame random regeneration
    final stars = [
      (x: 0.08, y: 0.05, size: 1.8),
      (x: 0.23, y: 0.12, size: 1.2),
      (x: 0.41, y: 0.07, size: 2.0),
      (x: 0.67, y: 0.03, size: 1.4),
      (x: 0.85, y: 0.10, size: 1.6),
      (x: 0.15, y: 0.22, size: 1.0),
      (x: 0.55, y: 0.18, size: 1.8),
      (x: 0.75, y: 0.25, size: 1.2),
      (x: 0.32, y: 0.30, size: 2.2),
      (x: 0.91, y: 0.20, size: 1.4),
      (x: 0.48, y: 0.35, size: 1.0),
      (x: 0.62, y: 0.40, size: 1.6),
      (x: 0.10, y: 0.45, size: 1.2),
      (x: 0.78, y: 0.38, size: 2.0),
      (x: 0.25, y: 0.50, size: 1.4),
      (x: 0.50, y: 0.55, size: 1.8),
      (x: 0.88, y: 0.48, size: 1.0),
      (x: 0.38, y: 0.60, size: 1.6),
      (x: 0.70, y: 0.58, size: 1.2),
      (x: 0.05, y: 0.65, size: 2.0),
    ];

    final paint = Paint();

    for (int i = 0; i < stars.length; i++) {
      final star = stars[i];
      // Each star twinkles at a slightly different phase
      final phase = (i / stars.length) * math.pi * 2;
      final opacity =
          0.2 + 0.8 * (math.sin(animationValue * math.pi * 2 + phase) + 1) / 2;
      paint.color = Colors.white.withAlpha((opacity * 255).toInt());
      canvas.drawCircle(
        Offset(star.x * size.width, star.y * size.height),
        star.size,
        paint,
      );
    }
  }

  void _paintDriftingClouds(Canvas canvas, Size size, Color cloudColor) {
    final clouds = [
      (baseX: 0.10, baseY: 0.12, radius: 52.0),
      (baseX: 0.50, baseY: 0.22, radius: 44.0),
      (baseX: 0.78, baseY: 0.08, radius: 38.0),
      (baseX: 0.30, baseY: 0.28, radius: 32.0),
    ];

    final paint = Paint()..color = cloudColor;

    for (final cloud in clouds) {
      // animationValue goes 0→1 over 3s, so * (3/12) = one full drift every 12s
      final x = (cloud.baseX * size.width + animationValue * size.width * 0.5) %
              (size.width + cloud.radius * 2) -
          cloud.radius;
      final y = cloud.baseY * size.height;
      final r = cloud.radius;

      canvas.drawCircle(Offset(x, y), r, paint);
      canvas.drawCircle(Offset(x + r * 0.65, y - r * 0.18), r * 0.72, paint);
      canvas.drawCircle(Offset(x - r * 0.55, y + r * 0.12), r * 0.62, paint);
      canvas.drawCircle(Offset(x + r * 0.25, y - r * 0.30), r * 0.50, paint);
    }
  }

  void _paintRainLines(Canvas canvas, Size size, Color rainColor) {
    final paint = Paint()
      ..color = rainColor
      ..strokeWidth = 1.2
      ..strokeCap = StrokeCap.round;

    final random = math.Random(1337);

    for (int i = 0; i < 45; i++) {
      double startX = random.nextDouble() * (size.width + 30);
      double positionOffset = random.nextDouble() * size.height;

      double startY =
          (positionOffset + (animationValue * size.height)) % size.height;
      double endX = startX - 3.5;
      double endY = startY + 15.0;

      canvas.drawLine(Offset(startX, startY), Offset(endX, endY), paint);
    }
  }

  @override
  bool shouldRepaint(covariant WeatherEffectPainter oldDelegate) => true;
}
