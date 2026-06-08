import 'package:flutter/material.dart';

/// Localized real-time weather observation data packet structure.
class CurrentWeather {
  final String cityName;
  final String country;
  final double tempCelsius;
  final double feelsLikeCelsius;
  final double tempMin;
  final double tempMax;
  final int humidity;
  final double windSpeedMs;
  final String condition;
  final String description;
  final String iconCode;
  final int sunrise;
  final int sunset;
  final double lat;
  final double lon;

  CurrentWeather({
    required this.cityName,
    required this.country,
    required this.tempCelsius,
    required this.feelsLikeCelsius,
    required this.tempMin,
    required this.tempMax,
    required this.humidity,
    required this.windSpeedMs,
    required this.condition,
    required this.description,
    required this.iconCode,
    required this.sunrise,
    required this.sunset,
    required this.lat,
    required this.lon,
  });

  factory CurrentWeather.fromJson(
      Map<String, dynamic> json, double lat, double lon) {
    final weatherOpt = (json['weather'] as List?)?.first;
    return CurrentWeather(
      cityName: json['name'] as String? ?? 'সিলেট',
      country:
          (json['sys'] as Map<String, dynamic>?)?['country'] as String? ?? 'BD',
      tempCelsius:
          ((json['main'] as Map<String, dynamic>?)?['temp'] as num? ?? 0.0)
              .toDouble(),
      feelsLikeCelsius:
          ((json['main'] as Map<String, dynamic>?)?['feels_like'] as num? ??
                  0.0)
              .toDouble(),
      tempMin:
          ((json['main'] as Map<String, dynamic>?)?['temp_min'] as num? ?? 0.0)
              .toDouble(),
      tempMax:
          ((json['main'] as Map<String, dynamic>?)?['temp_max'] as num? ?? 0.0)
              .toDouble(),
      humidity:
          ((json['main'] as Map<String, dynamic>?)?['humidity'] as num? ?? 0)
              .toInt(),
      windSpeedMs:
          ((json['wind'] as Map<String, dynamic>?)?['speed'] as num? ?? 0.0)
              .toDouble(),
      condition: weatherOpt?['main'] as String? ?? 'Clear',
      description: WeatherData.translateCondition(
          weatherOpt?['description'] as String? ?? 'পরিষ্কার আকাশ'),
      iconCode: weatherOpt?['icon'] as String? ?? '01d',
      sunrise: ((json['sys'] as Map<String, dynamic>?)?['sunrise'] as num? ?? 0)
          .toInt(),
      sunset: ((json['sys'] as Map<String, dynamic>?)?['sunset'] as num? ?? 0)
          .toInt(),
      lat: lat,
      lon: lon,
    );
  }
}

/// A specific 3-hour timestamp segment inside the rolling weather pipeline.
class HourlyWeather {
  final DateTime time;
  final double tempCelsius;
  final String condition;
  final String description;
  final String iconCode;
  final int humidity;

  HourlyWeather({
    required this.time,
    required this.tempCelsius,
    required this.condition,
    required this.description,
    required this.iconCode,
    required this.humidity,
  });

  factory HourlyWeather.fromJson(Map<String, dynamic> json) {
    final weatherOpt = (json['weather'] as List?)?.first;
    return HourlyWeather(
      time:
          DateTime.fromMillisecondsSinceEpoch((json['dt'] as int? ?? 0) * 1000),
      tempCelsius:
          ((json['main'] as Map<String, dynamic>?)?['temp'] as num? ?? 0.0)
              .toDouble(),
      condition: weatherOpt?['main'] as String? ?? 'Clear',
      description: WeatherData.translateCondition(
          weatherOpt?['description'] as String? ?? ''),
      iconCode: weatherOpt?['icon'] as String? ?? '01d',
      humidity:
          ((json['main'] as Map<String, dynamic>?)?['humidity'] as num? ?? 0)
              .toInt(),
    );
  }
}

/// An aggregated daily outlook containing compiled high/low records.
class DailyForecast {
  final DateTime date;
  final double tempMin;
  final double tempMax;
  final String condition;
  final String iconCode;

  DailyForecast({
    required this.date,
    required this.tempMin,
    required this.tempMax,
    required this.condition,
    required this.iconCode,
  });

  factory DailyForecast.fromHourlyList(List<HourlyWeather> hours) {
    final temps = hours.map((h) => h.tempCelsius).toList();
    final rep = hours[hours.length ~/ 2];
    return DailyForecast(
      date: hours.first.time,
      tempMin: temps.reduce((a, b) => a < b ? a : b),
      tempMax: temps.reduce((a, b) => a > b ? a : b),
      condition: rep.condition,
      iconCode: rep.iconCode,
    );
  }
}

/// Configuration settings holding specific asset definitions for lookups.
class WeatherThemeConfig {
  final List<Color> gradient;
  final Color cardBackground;
  final Color textColor;
  final String statusText;

  WeatherThemeConfig({
    required this.gradient,
    required this.cardBackground,
    required this.textColor,
    required this.statusText,
  });
}

/// Complete weather aggregate collection.
class WeatherData {
  final CurrentWeather current;
  final List<HourlyWeather> hourly;
  final List<DailyForecast> daily;

  WeatherData({
    required this.current,
    required this.hourly,
    required this.daily,
  });

  List<HourlyWeather> get next9Hours => hourly.take(9).toList();

  /// Evaluates icon parameters to provide dynamic interface style attributes.
  static WeatherThemeConfig getThemeConfig(String iconCode,
      {double tempCelsius = 0}) {
    // Hot + broken clouds (04d) → treat as warm hazy day visually
    if (iconCode == '04d' && tempCelsius > 32) iconCode = '02d';

    final isNight = iconCode.endsWith('n');
    final coreCode = iconCode.length >= 2 ? iconCode.substring(0, 2) : '01';

    // 1. Night Scene Styling Fallbacks
    if (isNight) {
      if (coreCode == '09' || coreCode == '10' || coreCode == '11') {
        return WeatherThemeConfig(
          gradient: [const Color(0xFF101F32), const Color(0xFF1B2A47)],
          cardBackground: const Color(0x1FFFFFFF),
          textColor: Colors.white,
          statusText: 'বৃষ্টি হচ্ছে • আজ রাতেও সম্ভাবনা আছে',
        );
      }
      return WeatherThemeConfig(
        gradient: [const Color(0xFF0F172A), const Color(0xFF1E293B)],
        cardBackground: const Color(0x14FFFFFF),
        textColor: Colors.white,
        statusText: 'পরিষ্কার রাত • শান্ত আবহাওয়া',
      );
    }

    // 2. Daytime Scene Transitions
    switch (coreCode) {
      case '01':
        return WeatherThemeConfig(
          gradient: [const Color(0xFF3B82F6), const Color(0xFF60A5FA)],
          cardBackground: const Color(0x33FFFFFF),
          textColor: Colors.white,
          statusText: 'রৌদ্রোজ্জ্বল • আকাশ পরিষ্কার',
        );
      case '02':
        return WeatherThemeConfig(
          gradient: [
            const Color(0xFF3B82F6),
            const Color(0xFF60A5FA),
          ],
          cardBackground: const Color(0x33FFFFFF),
          textColor: Colors.white,
          statusText: 'আংশিক মেঘলা • রোদেলা আবহাওয়া',
        );
      case '03':
      case '04':
        return WeatherThemeConfig(
          gradient: [const Color(0xFF64748B), const Color(0xFF475569)],
          cardBackground: const Color(0x26FFFFFF),
          textColor: Colors.white,
          statusText: 'আংশিক মেঘলা • আকাশ মেঘাচ্ছন্ন',
        );
      case '09':
      case '10':
        return WeatherThemeConfig(
          gradient: [const Color(0xFF4A6B82), const Color(0xFF385265)],
          cardBackground: const Color(0x26FFFFFF),
          textColor: Colors.white,
          statusText: 'আংশিক মেঘলা • আজ বৃষ্টি হতে পারে',
        );
      case '11':
        return WeatherThemeConfig(
          gradient: [const Color(0xFF1E1E2F), const Color(0xFF12121F)],
          cardBackground: const Color(0x1FFFFFFF),
          textColor: Colors.white,
          statusText: 'বজ্রঝড় • সাবধানে থাকুন',
        );
      default:
        return WeatherThemeConfig(
          gradient: [const Color(0xFF3B82F6), const Color(0xFF60A5FA)],
          cardBackground: const Color(0x33FFFFFF),
          textColor: Colors.white,
          statusText: 'আংশিক মেঘলা',
        );
    }
  }

  /// Translates typical English digit sequences into unified Bengali glyph formats.
  static String toBangla(dynamic input) {
    final String src = input.toString();
    const english = [
      '0',
      '1',
      '2',
      '3',
      '4',
      '5',
      '6',
      '7',
      '8',
      '9',
      'AM',
      'PM'
    ];
    const bangla = [
      '০',
      '১',
      '২',
      '৩',
      '৪',
      '৫',
      '৬',
      '৭',
      '৮',
      '৯',
      'পূর্বাহ্ন',
      'অপরাহ্ন'
    ];

    String output = src;
    for (int i = 0; i < english.length; i++) {
      output = output.replaceAll(english[i], bangla[i]);
    }
    return output;
  }

  /// Maps a raw OpenWeather icon code snippet to a highly visible short single-word label.
  static String getShortBanglaCondition(String iconCode) {
    if (iconCode.length < 2) return 'মেঘ';
    final coreCode = iconCode.substring(0, 2);
    switch (coreCode) {
      case '01':
        return 'রোদ';
      case '02':
      case '03':
      case '04':
        return 'মেঘ';
      case '09':
      case '10':
        return 'বৃষ্টি';
      case '11':
        return 'ঝড়';
      case '13':
        return 'তুষার';
      case '50':
        return 'কুয়াশা';
      default:
        return 'মেঘ';
    }
  }

  static String getShortEnglishCondition(String iconCode) {
    if (iconCode.startsWith('01')) return 'Clear';
    if (iconCode.startsWith('02') || iconCode.startsWith('03')) return 'Partly';
    if (iconCode.startsWith('04')) return 'Cloudy';
    if (iconCode.startsWith('09') || iconCode.startsWith('10')) return 'Rain';
    if (iconCode.startsWith('11')) return 'Storm';
    if (iconCode.startsWith('13')) return 'Snow';
    if (iconCode.startsWith('50')) return 'Fog';
    return 'Cloud';
  }

  /// Explicit fallback dictionary matching detailed text payloads from the server interface.
  static String translateCondition(String text) {
    final clean = text.toLowerCase().trim();
    final Map<String, String> dict = {
      'clear sky': 'পরিষ্কার আকাশ',
      'few clouds': 'আংশিক মেঘলা',
      'scattered clouds': 'বিক্ষিপ্ত মেঘ',
      'broken clouds': 'ভাঙা মেঘ',
      'shower rain': 'ঝিরিঝিরি বৃষ্টি',
      'rain': 'বৃষ্টি',
      'light rain': 'হালকা বৃষ্টি',
      'moderate rain': 'মাঝারি বৃষ্টি',
      'heavy intensity rain': 'ভারী বৃষ্টি',
      'thunderstorm': 'বজ্রঝড়',
      'snow': 'তুষারপাত',
      'mist': 'কুয়াশা',
      'haze': 'ধোঁয়াশা',
    };
    return dict[clean] ?? text;
  }
}
