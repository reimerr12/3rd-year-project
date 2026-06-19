import 'package:dio/dio.dart';
import '../core/constants.dart';

/// Clean data access isolation architecture managing raw remote endpoints directly
class WeatherService {
  final Dio _dio = Dio(BaseOptions(
    baseUrl: AppConstants.weatherApiUrl,
    connectTimeout: const Duration(seconds: 8),
  ));

  /// Requests the immediate live observation data block based on coordinated positions.
  Future<Map<String, dynamic>> fetchCurrentWeather(
      double lat, double lon) async {
    final response = await _dio.get('/weather', queryParameters: {
      'lat': lat,
      'lon': lon,
      'appid': AppConstants.weatherApiKey,
      'units': 'metric',
      'lang': 'bn',
    });
    return response.data as Map<String, dynamic>;
  }

  /// Requests the extended multi-day 3-hour sequence log blocks from the server.
  Future<Map<String, dynamic>> fetchForecast(double lat, double lon) async {
    final response = await _dio.get('/forecast', queryParameters: {
      'lat': lat,
      'lon': lon,
      'appid': AppConstants.weatherApiKey,
      'units': 'metric',
      'lang': 'bn',
    });
    return response.data as Map<String, dynamic>;
  }
}
