import 'package:dio/dio.dart';
import '../core/constants.dart';

class WeatherService {
  final Dio _dio = Dio(BaseOptions(
    baseUrl: AppConstants.weatherApiUrl,
    connectTimeout: const Duration(seconds: 8),
  ));

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
