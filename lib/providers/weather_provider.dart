import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:geolocator/geolocator.dart';
import '../models/weather.dart';
import '../services/weather_service.dart';

/// Application exposure channel for referencing data-tree dependencies across screens.
final weatherProvider =
    AsyncNotifierProvider<WeatherNotifier, WeatherData>(WeatherNotifier.new);

class WeatherNotifier extends AsyncNotifier<WeatherData> {
  // Direct injection interface linking to our new weather service component
  final WeatherService _service = WeatherService();

  @override
  Future<WeatherData> build() async {
    return _fetchPipeline();
  }

  /// Pull event controller designed to flush existing memory entries and pull fresh remote sheets.
  Future<void> refresh() async {
    state = const AsyncValue.loading();
    state = await AsyncValue.guard(() => _fetchPipeline());
  }

  /// Interlinks hardware location tracking updates to network execution loops.
  Future<WeatherData> _fetchPipeline() async {
    final pos = await _determineLocation();

    // Runs concurrent fetch tasks through our clean WeatherService channels
    final currentRaw =
        await _service.fetchCurrentWeather(pos.latitude, pos.longitude);
    final forecastRaw =
        await _service.fetchForecast(pos.latitude, pos.longitude);

    final current =
        CurrentWeather.fromJson(currentRaw, pos.latitude, pos.longitude);
    final rawHours = (forecastRaw['list'] as List)
        .map((h) => HourlyWeather.fromJson(h))
        .toList();

    return WeatherData(
      current: current,
      hourly: rawHours,
      daily: _buildAggregatedDaily(rawHours),
    );
  }

  /// Recompiles standard raw logs into structured 24-hour individual calendar slices.
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

  /// System position tracker with absolute safety backups to avoid device lockups.
  Future<Position> _determineLocation() async {
    final fallback = Position(
      latitude: 24.8949, longitude: 91.8687, // Sylhet native defaults
      timestamp: DateTime.now(), accuracy: 0, altitude: 0,
      heading: 0, speed: 0, speedAccuracy: 0, altitudeAccuracy: 0,
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

      return await Geolocator.getCurrentPosition(
          desiredAccuracy: LocationAccuracy.low,
          timeLimit: const Duration(seconds: 4));
    } catch (_) {
      return fallback;
    }
  }
}
