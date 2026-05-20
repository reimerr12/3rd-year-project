/// this will have everything required to put in on a weather screen (we can change it when necessary).
// lib/models/weather.dart

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
      // Dynamic translation fallback mapping if api delivers string variables in english format
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

  /// Global engine to transform standard English layout numbers or strings into clean Bengali digit glyphs
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

  /// Clean verification translator dictionary fallback handler
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

  static String getShortBanglaCondition(String iconCode) {
    // Matches the first two digits of the OpenWeather icon code
    final coreCode = iconCode.substring(0, 2);
    switch (coreCode) {
      case '01':
        return 'রোদ'; // Clear sky
      case '02':
      case '03':
      case '04':
        return 'মেঘ'; // Clouds
      case '09':
      case '10':
        return 'বৃষ্টি'; // Rain / Shower drizzle
      case '11':
        return 'ঝড়'; // Thunderstorm
      case '13':
        return 'তুষার'; // Snow
      case '50':
        return 'কুয়াশা'; // Mist / Fog
      default:
        return 'মেঘ';
    }
  }
}
