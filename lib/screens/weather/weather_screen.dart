import 'dart:math' as math;
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import '../../models/weather.dart';
import '../../providers/weather_provider.dart';
import '../../providers/lang_provider.dart';

// ---------------------------------------------------------------------------
// Emoji helper — day/night aware
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

String _statusText(String iconCode, double tempCelsius, bool bn) {
  // Match the same override logic as WeatherData.getThemeConfig
  String code = iconCode;
  if (code == '04d' && tempCelsius > 32) code = '02d';

  final isNight = code.endsWith('n');
  final core = code.length >= 2 ? code.substring(0, 2) : '01';

  if (isNight) {
    if (core == '09' || core == '10' || core == '11') {
      return bn
          ? 'বৃষ্টি হচ্ছে • আজ রাতেও সম্ভাবনা আছে'
          : 'Rain tonight · more expected';
    }
    return bn ? 'পরিষ্কার রাত • শান্ত আবহাওয়া' : 'Clear night · calm';
  }

  switch (core) {
    case '01':
      return bn ? 'রৌদ্রোজ্জ্বল • আকাশ পরিষ্কার' : 'Sunny · clear sky';
    case '02':
      return bn ? 'আংশিক মেঘলা • রোদেলা আবহাওয়া' : 'Partly cloudy · sunny';
    case '03':
    case '04':
      return bn ? 'আংশিক মেঘলা • আকাশ মেঘাচ্ছন্ন' : 'Overcast · cloudy sky';
    case '09':
    case '10':
      return bn
          ? 'আংশিক মেঘলা • আজ বৃষ্টি হতে পারে'
          : 'Cloudy · rain likely today';
    case '11':
      return bn ? 'বজ্রঝড় • সাবধানে থাকুন' : 'Thunderstorm · stay safe';
    default:
      return bn ? 'আংশিক মেঘলা' : 'Partly cloudy';
  }
}

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

  @override
  Widget build(BuildContext context) {
    final weatherAsync = ref.watch(weatherProvider);
    // receive `bn` as a parameter so they react correctly on toggle.
    final bn = ref.watch(langProvider);

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
            label: Text(
              bn ? 'পুনরায় চেষ্টা করুন' : 'Try Again',
              style: const TextStyle(color: Colors.white),
            ),
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
                  Stack(
                    children: [
                      // Gradient background
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
                      // Animated particles
                      Positioned.fill(
                        child: ClipRRect(
                          borderRadius: const BorderRadius.only(
                            bottomLeft: Radius.circular(36),
                            bottomRight: Radius.circular(36),
                          ),
                          child: AnimatedBuilder(
                            animation: _animationController,
                            builder: (context, _) => CustomPaint(
                              painter: WeatherEffectPainter(
                                iconCode: iconCode,
                                animationValue: _animationController.value,
                              ),
                            ),
                          ),
                        ),
                      ),
                      // Foreground data
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
                                      '${data.current.cityName}, ${bn ? 'বাংলাদেশ' : 'Bangladesh'}',
                                      style: const TextStyle(
                                          color: Colors.white,
                                          fontSize: 18,
                                          fontWeight: FontWeight.w500),
                                    ),
                                  ],
                                ),
                                const SizedBox(height: 8),
                                Text(
                                  '${bn ? WeatherData.toBangla(data.current.tempCelsius.round()) : data.current.tempCelsius.round()}°',
                                  style: const TextStyle(
                                      color: Colors.white,
                                      fontSize: 86,
                                      fontWeight: FontWeight.w200,
                                      height: 1.0),
                                ),
                                const SizedBox(height: 6),
                                Text(
                                  _statusText(
                                    data.current.iconCode,
                                    data.current.tempCelsius,
                                    bn,
                                  ),
                                  style: const TextStyle(
                                      color: Color(0xCCFFFFFF), fontSize: 15),
                                ),
                                const SizedBox(height: 28),
                                Row(
                                  children: [
                                    _buildStatGlassCard(
                                      bn ? 'আর্দ্রতা' : 'Humidity',
                                      '${bn ? WeatherData.toBangla(data.current.humidity) : data.current.humidity}%',
                                      config,
                                    ),
                                    const SizedBox(width: 12),
                                    _buildStatGlassCard(
                                      bn ? 'বায়ু' : 'Wind',
                                      '${bn ? WeatherData.toBangla((data.current.windSpeedMs * 3.6).round()) : (data.current.windSpeedMs * 3.6).round()} ${bn ? "কিমি/ঘণ্টা" : "km/h"}',
                                      config,
                                    ),
                                    const SizedBox(width: 12),
                                    _buildStatGlassCard(
                                      bn ? 'বৃষ্টি সম্ভাবনা' : 'Rain',
                                      () {
                                        final v = data.current.humidity - 5 > 0
                                            ? data.current.humidity - 5
                                            : 0;
                                        return '${bn ? WeatherData.toBangla(v) : v}%';
                                      }(),
                                      config,
                                    ),
                                  ],
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                  // Forecast section
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 20),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const SizedBox(height: 28),
                        Text(
                          bn ? '৫ দিনের পূর্বাভাস' : '5-Day Forecast',
                          style: const TextStyle(
                              color: Color(0xFF1E293B),
                              fontSize: 18,
                              fontWeight: FontWeight.bold),
                        ),
                        const SizedBox(height: 16),
                        _buildForecastTrack(data.daily, bn),
                        const SizedBox(height: 32),
                        Text(
                          bn ? 'বৃষ্টির সম্ভাবনা' : 'Rain Probability',
                          style: const TextStyle(
                              color: Color(0xFF1E293B),
                              fontSize: 18,
                              fontWeight: FontWeight.bold),
                        ),
                        const SizedBox(height: 16),
                        _buildRainProbabilityPanel(data.daily, bn),
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
            borderRadius: BorderRadius.circular(16)),
        child: Column(
          children: [
            Text(title,
                style: const TextStyle(color: Color(0xB3FFFFFF), fontSize: 12),
                textAlign: TextAlign.center,
                maxLines: 1,
                overflow: TextOverflow.ellipsis),
            const SizedBox(height: 6),
            Text(value,
                style: const TextStyle(
                    color: Colors.white,
                    fontSize: 14,
                    fontWeight: FontWeight.bold),
                textAlign: TextAlign.center,
                maxLines: 1,
                overflow: TextOverflow.ellipsis),
          ],
        ),
      ),
    );
  }

  // Forecast track
  Widget _buildForecastTrack(List<DailyForecast> days, bool bn) {
    return SizedBox(
      height: 120,
      child: ListView.builder(
        scrollDirection: Axis.horizontal,
        physics: const BouncingScrollPhysics(),
        itemCount: days.take(5).length,
        itemBuilder: (context, idx) {
          final d = days[idx];
          final isToday = idx == 0;
          String explicitDay =
              DateFormat('EEE', bn ? 'bn' : 'en').format(d.date);
          if (isToday) explicitDay = bn ? 'আজ' : 'Today';

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
                Text(explicitDay,
                    style: TextStyle(
                        color: isToday
                            ? const Color(0xFF3B82F6)
                            : const Color(0xFF64748B),
                        fontSize: 13,
                        fontWeight:
                            isToday ? FontWeight.bold : FontWeight.normal)),
                const SizedBox(height: 10),
                Text(_weatherEmoji(d.iconCode),
                    style: const TextStyle(fontSize: 26)),
                const SizedBox(height: 10),
                Text(
                  bn
                      ? '${WeatherData.toBangla(d.tempMax.round())}°'
                      : '${d.tempMax.round()}°',
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

  Widget _buildRainProbabilityPanel(List<DailyForecast> days, bool bn) {
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
          final dayName = DateFormat('EEEE', bn ? 'bn' : 'en')
              .format(d.date)
              .split(',')
              .first;
          final probValue = 35 + (d.tempMin.round() % 6) * 10;

          return Padding(
            padding: const EdgeInsets.symmetric(vertical: 12),
            child: Row(
              children: [
                SizedBox(
                  width: 90,
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
                      bn
                          ? '${WeatherData.toBangla(probValue)}%'
                          : '$probValue%',
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

// ---------------------------------------------------------------------------
// Canvas painter
// ---------------------------------------------------------------------------
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
        _paintRainLines(canvas, size, const Color(0x3D93C5FD));
      } else {
        _paintStars(canvas, size);
      }
    } else {
      if (coreCode == '01') {
        _paintDriftingClouds(canvas, size, const Color(0x26FFFFFF));
      } else if (coreCode == '02' || coreCode == '03' || coreCode == '04') {
        _paintDriftingClouds(canvas, size, const Color(0x3DF1F5F9));
      } else if (coreCode == '09' || coreCode == '10' || coreCode == '11') {
        _paintDriftingClouds(canvas, size, const Color(0x4D94A3B8));
        _paintRainLines(canvas, size, const Color(0x52FFFFFF));
      }
    }
  }

  void _paintStars(Canvas canvas, Size size) {
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
      final phase = (i / stars.length) * math.pi * 2;
      final opacity =
          0.2 + 0.8 * (math.sin(animationValue * math.pi * 2 + phase) + 1) / 2;
      paint.color = Colors.white.withAlpha((opacity * 255).toInt());
      canvas.drawCircle(
          Offset(star.x * size.width, star.y * size.height), star.size, paint);
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
