import 'package:supabase_flutter/supabase_flutter.dart';

// ---------------------------------------------------------------------------
// NotificationModel
// ---------------------------------------------------------------------------

class NotificationModel {
  final String id;
  final String userId;
  final String titleEn;
  final String titleBn;
  final String bodyEn;
  final String bodyBn;
  final String type; // 'weather' | 'system' | 'booking' | 'order'
  final bool isRead;
  final DateTime createdAt;

  const NotificationModel({
    required this.id,
    required this.userId,
    required this.titleEn,
    required this.titleBn,
    required this.bodyEn,
    required this.bodyBn,
    required this.type,
    required this.isRead,
    required this.createdAt,
  });

  factory NotificationModel.fromMap(Map<String, dynamic> map) {
    return NotificationModel(
      id: map['id'] as String,
      userId: map['user_id'] as String,
      titleEn: map['title'] as String? ?? '',
      titleBn: map['title_bn'] as String? ?? map['title'] as String? ?? '',
      bodyEn: map['body'] as String? ?? '',
      bodyBn: map['body_bn'] as String? ?? map['body'] as String? ?? '',
      type: map['type'] as String? ?? 'system',
      isRead: map['is_read'] as bool? ?? false,
      createdAt: DateTime.parse(map['created_at'] as String),
    );
  }

  String title(bool isBn) => isBn ? titleBn : titleEn;
  String body(bool isBn) => isBn ? bodyBn : bodyEn;
}

// ---------------------------------------------------------------------------
// NotificationService
// ---------------------------------------------------------------------------

class NotificationService {
  NotificationService._();
  static final NotificationService instance = NotificationService._();
  factory NotificationService() => instance;

  SupabaseClient get _client => Supabase.instance.client;

  // =========================================================================
  // FETCH
  // =========================================================================

  Future<List<NotificationModel>> fetchNotifications(String userId) async {
    final data = await _client
        .from('notifications')
        .select()
        .eq('user_id', userId)
        .order('created_at', ascending: false)
        .limit(50);

    return (data as List)
        .map((e) => NotificationModel.fromMap(e as Map<String, dynamic>))
        .toList();
  }

  Future<int> fetchUnreadCount(String userId) async {
    final data = await _client
        .from('notifications')
        .select()
        .eq('user_id', userId)
        .eq('is_read', false);

    return (data as List).length;
  }

  // =========================================================================
  // MARK READ
  // =========================================================================

  Future<void> markAsRead(String notificationId) async {
    await _client
        .from('notifications')
        .update({'is_read': true}).eq('id', notificationId);
  }

  Future<void> markAllAsRead(String userId) async {
    await _client
        .from('notifications')
        .update({'is_read': true})
        .eq('user_id', userId)
        .eq('is_read', false);
  }

  // =========================================================================
  // GENERATE — called on app open from notifications_provider
  // =========================================================================

  /// Entry point. Runs weather + crop checks, inserts non-duplicate rows.
  Future<void> generateNotifications({
    required String userId,
    required Map<String, dynamic>? weatherData,
    required String? userDivision,
  }) async {
    await Future.wait([
      if (weatherData != null)
        _checkWeather(
          userId: userId,
          weatherData: weatherData,
          division: userDivision,
        ),
      _checkCropCalendar(userId: userId),
    ]);
  }

  // =========================================================================
  // WEATHER CHECK
  // =========================================================================

  Future<void> _checkWeather({
    required String userId,
    required Map<String, dynamic> weatherData,
    String? division,
  }) async {
    final alerts = _extractWeatherAlerts(weatherData);
    for (final alert in alerts) {
      await _insertIfNew(
        userId: userId,
        titleEn: alert['title_en']!,
        titleBn: alert['title_bn']!,
        bodyEn: alert['body_en']!,
        bodyBn: alert['body_bn']!,
        type: 'weather',
      );

      // Also write to weather_alerts table if we have a division
      if (division != null) {
        await _upsertWeatherAlert(
          division: division,
          alertType: alert['alert_type']!,
          messageEn: alert['body_en']!,
          messageBn: alert['body_bn']!,
          severity: alert['severity']!,
        );
      }
    }
  }

  /// Inspects hourly forecast data from OWM and returns alert maps.
  List<Map<String, String>> _extractWeatherAlerts(
      Map<String, dynamic> weatherData) {
    final alerts = <Map<String, String>>[];

    // Pull hourly list — OWM /forecast returns { list: [...] }
    final hourlyList = weatherData['list'] as List? ?? [];
    final next6h = hourlyList.take(2).toList(); // 2 × 3hr slots = 6hrs

    double maxRainMm = 0;
    double maxWindMs = 0;
    bool thunderstorm = false;

    for (final slot in next6h) {
      final rain = (slot['rain'] as Map?)?['3h'] as num? ?? 0;
      final wind = (slot['wind'] as Map?)?['speed'] as num? ?? 0;
      final weatherList = slot['weather'] as List? ?? [];
      final conditionId =
          weatherList.isNotEmpty ? weatherList[0]['id'] as int? ?? 0 : 0;

      if (rain > maxRainMm) maxRainMm = rain.toDouble();
      if (wind > maxWindMs) maxWindMs = wind.toDouble();
      if (conditionId >= 200 && conditionId < 300) thunderstorm = true;
    }

    final windKmh = maxWindMs * 3.6;

    if (thunderstorm) {
      alerts.add({
        'title_en': 'Thunderstorm Warning',
        'title_bn': 'বজ্রঝড়ের সতর্কতা',
        'body_en':
            'A thunderstorm is expected in your area within the next 6 hours. Secure your crops and equipment.',
        'body_bn':
            'পরবর্তী ৬ ঘণ্টার মধ্যে আপনার এলাকায় বজ্রঝড়ের সম্ভাবনা রয়েছে। ফসল ও যন্ত্রপাতি সুরক্ষিত করুন।',
        'alert_type': 'thunderstorm',
        'severity': 'high',
      });
    } else if (maxRainMm >= 10) {
      alerts.add({
        'title_en': 'Heavy Rain Expected',
        'title_bn': 'ভারী বৃষ্টির পূর্বাভাস',
        'body_en':
            'Heavy rainfall (${maxRainMm.toStringAsFixed(0)} mm) is expected in the next 6 hours.',
        'body_bn':
            'পরবর্তী ৬ ঘণ্টায় ভারী বৃষ্টিপাত (${maxRainMm.toStringAsFixed(0)} মিমি) হওয়ার সম্ভাবনা আছে।',
        'alert_type': 'heavy_rain',
        'severity': 'medium',
      });
    } else if (maxRainMm >= 2.5) {
      alerts.add({
        'title_en': 'Rain Expected Soon',
        'title_bn': 'বৃষ্টির সম্ভাবনা',
        'body_en': 'Moderate rain is expected within the next 6 hours.',
        'body_bn': 'পরবর্তী ৬ ঘণ্টার মধ্যে মাঝারি বৃষ্টির সম্ভাবনা রয়েছে।',
        'alert_type': 'rain',
        'severity': 'low',
      });
    }

    if (windKmh >= 60) {
      alerts.add({
        'title_en': 'Strong Wind Warning',
        'title_bn': 'প্রবল বাতাসের সতর্কতা',
        'body_en':
            'Wind speeds up to ${windKmh.toStringAsFixed(0)} km/h expected. Protect standing crops.',
        'body_bn':
            '${windKmh.toStringAsFixed(0)} কিমি/ঘণ্টা পর্যন্ত বাতাস প্রবাহিত হতে পারে। দাঁড়ানো ফসল রক্ষা করুন।',
        'alert_type': 'strong_wind',
        'severity': 'high',
      });
    }

    return alerts;
  }

  Future<void> _upsertWeatherAlert({
    required String division,
    required String alertType,
    required String messageEn,
    required String messageBn,
    required String severity,
  }) async {
    // weather_alerts table has title/body as single `message` TEXT column
    // store EN version there; BN is in notifications table
    try {
      await _client.from('weather_alerts').insert({
        'division': division,
        'alert_type': alertType,
        'message': messageEn,
        'severity': severity,
      });
    } catch (_) {
      // Non-critical — don't crash notification flow
    }
  }

  // =========================================================================
  // CROP CALENDAR CHECK
  // =========================================================================

  Future<void> _checkCropCalendar({required String userId}) async {
    final now = DateTime.now();
    final currentMonth = now.month;

    try {
      // Fetch crops where current month is in sow_months or harvest_months
      final sowData = await _client
          .from('crop_calendar')
          .select('crop_name_en, crop_name_bn')
          .contains('sow_months', [currentMonth]);

      final harvestData = await _client
          .from('crop_calendar')
          .select('crop_name_en, crop_name_bn')
          .contains('harvest_months', [currentMonth]);

      final sowCrops =
          (sowData as List).map((e) => e as Map<String, dynamic>).toList();

      final harvestCrops =
          (harvestData as List).map((e) => e as Map<String, dynamic>).toList();

      if (sowCrops.isNotEmpty) {
        final namesEn =
            sowCrops.map((c) => c['crop_name_en'] as String).join(', ');
        final namesBn =
            sowCrops.map((c) => c['crop_name_bn'] as String).join(', ');

        await _insertIfNew(
          userId: userId,
          titleEn: 'Time to Sow',
          titleBn: 'বপনের সময়',
          bodyEn: 'This month is ideal for sowing: $namesEn.',
          bodyBn: 'এই মাসে বপনের উপযুক্ত সময়: $namesBn।',
          type: 'system',
        );
      }

      if (harvestCrops.isNotEmpty) {
        final namesEn =
            harvestCrops.map((c) => c['crop_name_en'] as String).join(', ');
        final namesBn =
            harvestCrops.map((c) => c['crop_name_bn'] as String).join(', ');

        await _insertIfNew(
          userId: userId,
          titleEn: 'Harvest Season',
          titleBn: 'ফসল তোলার সময়',
          bodyEn: 'These crops are ready to harvest this month: $namesEn.',
          bodyBn: 'এই মাসে এই ফসলগুলো তোলার উপযুক্ত সময়: $namesBn।',
          type: 'system',
        );
      }
    } catch (_) {
      // Non-critical
    }
  }

  // =========================================================================
  // DEDUP INSERT — skips if same type + title_en exists today
  // =========================================================================

  Future<void> _insertIfNew({
    required String userId,
    required String titleEn,
    required String titleBn,
    required String bodyEn,
    required String bodyBn,
    required String type,
  }) async {
    final today = DateTime.now();
    final startOfDay =
        DateTime(today.year, today.month, today.day).toIso8601String();
    final endOfDay = DateTime(today.year, today.month, today.day, 23, 59, 59)
        .toIso8601String();

    final existing = await _client
        .from('notifications')
        .select('id')
        .eq('user_id', userId)
        .eq('type', type)
        .eq('title', titleEn) // title column stores EN value
        .gte('created_at', startOfDay)
        .lte('created_at', endOfDay)
        .maybeSingle();

    if (existing != null) return; // already inserted today

    await _client.from('notifications').insert({
      'user_id': userId,
      'title': titleEn,
      'body': bodyEn,
      'title_bn': titleBn,
      'body_bn': bodyBn,
      'type': type,
      'is_read': false,
    });
  }
}
