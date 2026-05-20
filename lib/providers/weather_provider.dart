// lib/providers/weather_provider.dart
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:dio/dio.dart';
import 'package:geolocator/geolocator.dart';
import '../core/constants.dart';
import '../models/weather.dart';

/// Global access entry provider for our asynchronous weather data pipeline.
final weatherProvider =
    AsyncNotifierProvider<WeatherNotifier, WeatherData>(WeatherNotifier.new);

class WeatherNotifier extends AsyncNotifier<WeatherData> {
  // Centralized HTTP network initialization reading directly from AppConstants
  final Dio _dio = Dio(BaseOptions(
    baseUrl: AppConstants.weatherApiUrl,
    connectTimeout: const Duration(seconds: 8),
  ));

  @override
  Future<WeatherData> build() async {
    // Sets up the initial execution pipeline when the UI reads the provider
    return _fetchWeatherPipeline();
  }

  /// Triggers a manual screen pull-to-refresh state updates.
  Future<void> refresh() async {
    state = const AsyncValue.loading();
    // Guard ensures exceptions do not crash execution threads
    state = await AsyncValue.guard(() => _fetchWeatherPipeline());
  }

  /// Coordinates GPS location lookups, runs concurrent API requests, and formats the response.
  Future<WeatherData> _fetchWeatherPipeline() async {
    final pos = await _determineLocation();

    // Concurrent query handling targets the OpenWeather endpoints
    final currentRes = await _dio.get('/weather', queryParameters: {
      'lat': pos.latitude,
      'lon': pos.longitude,
      'appid': AppConstants.weatherApiKey,
      'units': 'metric',
      'lang': 'bn', // Requests native Bengali descriptions from the server
    });

    final forecastRes = await _dio.get('/forecast', queryParameters: {
      'lat': pos.latitude,
      'lon': pos.longitude,
      'appid': AppConstants.weatherApiKey,
      'units': 'metric',
      'lang': 'bn',
    });

    // Model translation mappings
    final current =
        CurrentWeather.fromJson(currentRes.data, pos.latitude, pos.longitude);
    final rawHours = (forecastRes.data['list'] as List)
        .map((h) => HourlyWeather.fromJson(h))
        .toList();

    return WeatherData(
      current: current,
      hourly: rawHours,
      daily: _buildAggregatedDaily(rawHours),
    );
  }

  /// Groups 3-hour intervals into a single map organized by calendar date strings.
  List<DailyForecast> _buildAggregatedDaily(List<HourlyWeather> hours) {
    final Map<String, List<HourlyWeather>> intervals = {};
    for (var h in hours) {
      final stamp = '${h.time.year}-${h.time.month}-${h.time.day}';
      intervals.putIfAbsent(stamp, () => []).add(h);
    }
    return intervals.values
        .map((list) => DailyForecast.fromHourlyList(list))
        .toList();
  }

  /// Gracefully requests GPS access, falling back to a default location if disabled or blocked.
  Future<Position> _determineLocation() async {
    // Production fallback defaults to Sylhet if GPS permissions are denied
    final fallback = Position(
      latitude: 24.8949,
      longitude: 91.8687,
      timestamp: DateTime.now(),
      accuracy: 0,
      altitude: 0,
      heading: 0,
      speed: 0,
      speedAccuracy: 0,
      altitudeAccuracy: 0,
      headingAccuracy: 0,
    );

    try {
      if (!await Geolocator.isLocationServiceEnabled()) return fallback;

      var perm = await Geolocator.checkPermission();
      if (perm == LocationPermission.denied) {
        perm = await Geolocator.requestPermission();
        if (perm == LocationPermission.denied) return fallback;
      }
      if (perm == LocationPermission.deniedForever) return fallback;

      // Fast positioning profile prevents app lockups or stalling on load
      return await Geolocator.getCurrentPosition(
          desiredAccuracy: LocationAccuracy.low,
          timeLimit: const Duration(seconds: 4));
    } catch (_) {
      return fallback; // Return safety defaults on device hardware faults
    }
  }
}
