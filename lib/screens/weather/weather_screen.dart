// lib/screens/weather/weather_screen.dart
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import '../../core/theme.dart';
import '../../models/weather.dart';
import '../../providers/weather_provider.dart';

class WeatherScreen extends ConsumerWidget {
  const WeatherScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final weatherAsync = ref.watch(weatherProvider);

    return Scaffold(
      backgroundColor: AppTheme.bgLight,
      appBar: AppBar(
        title: const Text('আবহাওয়া পূর্বাভাস',
            style: TextStyle(
                color: Colors.white,
                fontWeight: FontWeight.bold,
                fontSize: 18)),
        backgroundColor: AppTheme.primaryGreen,
        elevation: 0,
        iconTheme: const IconThemeData(color: Colors.white),
      ),
      body: weatherAsync.when(
        loading: () => const Center(
            child: CircularProgressIndicator(color: AppTheme.primaryGreen)),
        error: (err, stack) => Center(
          child: ElevatedButton.icon(
            onPressed: () => ref.read(weatherProvider.notifier).refresh(),
            style: ElevatedButton.styleFrom(
                backgroundColor: AppTheme.primaryGreen,
                padding:
                    const EdgeInsets.symmetric(horizontal: 20, vertical: 12)),
            icon: const Icon(Icons.refresh, color: Colors.white),
            label: const Text('পুনরায় চেষ্টা করুন',
                style: TextStyle(
                    color: Colors.white, fontWeight: FontWeight.bold)),
          ),
        ),
        data: (data) => RefreshIndicator(
          onRefresh: () => ref.read(weatherProvider.notifier).refresh(),
          color: AppTheme.primaryGreen,
          child: SingleChildScrollView(
            physics: const AlwaysScrollableScrollPhysics(),
            padding: const EdgeInsets.all(20),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _buildCurrentHeroCard(data.current),
                const SizedBox(height: 24),
                const Text('আজকের প্রতি ৩ ঘণ্টার আপডেট',
                    style: TextStyle(
                        fontSize: 15,
                        fontWeight: FontWeight.bold,
                        color: Colors.black87)),
                const SizedBox(height: 12),
                _buildHourlyTrack(data.next9Hours),
                const SizedBox(height: 24),
                const Text('পরবর্তী ৫ দিনের পূর্বাভাস',
                    style: TextStyle(
                        fontSize: 15,
                        fontWeight: FontWeight.bold,
                        color: Colors.black87)),
                const SizedBox(height: 12),
                _buildDailyList(data.daily),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildCurrentHeroCard(CurrentWeather current) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
            colors: [AppTheme.primaryGreen, Color(0xFF1B5E20)],
            begin: Alignment.topLeft,
            end: Alignment.bottomRight),
        borderRadius: BorderRadius.circular(20),
      ),
      child: Column(
        children: [
          Text(current.cityName,
              style: const TextStyle(
                  fontSize: 24,
                  fontWeight: FontWeight.bold,
                  color: Colors.white)),
          const SizedBox(height: 4),
          // Bengali Number Formatter Filter applied here
          Text('${WeatherData.toBangla(current.tempCelsius.round())}°C',
              style: const TextStyle(
                  fontSize: 56,
                  fontWeight: FontWeight.w900,
                  color: Colors.white)),
          Text(current.description,
              style: const TextStyle(
                  fontSize: 15,
                  color: Colors.white70,
                  fontWeight: FontWeight.w500)),
          const Divider(color: Colors.white24, height: 32),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceAround,
            children: [
              _heroStatItem(Icons.water_drop,
                  '${WeatherData.toBangla(current.humidity)}%', 'আর্দ্রতা'),
              _heroStatItem(
                  Icons.air,
                  '${WeatherData.toBangla((current.windSpeedMs * 3.6).round())} কিমি/ঘণ্টা',
                  'বাতাস'),
            ],
          )
        ],
      ),
    );
  }

  Widget _heroStatItem(IconData icon, String value, String label) {
    return Column(
      children: [
        Icon(icon, color: Colors.white, size: 22),
        const SizedBox(height: 4),
        Text(value,
            style: const TextStyle(
                color: Colors.white,
                fontWeight: FontWeight.bold,
                fontSize: 14)),
        Text(label,
            style: const TextStyle(color: Colors.white60, fontSize: 11)),
      ],
    );
  }

  Widget _buildHourlyTrack(List<HourlyWeather> hours) {
    return SizedBox(
      height: 95,
      child: ListView.builder(
        scrollDirection: Axis.horizontal,
        itemCount: hours.length,
        itemBuilder: (context, idx) {
          final h = hours[idx];
          // Formats standard string date maps and channels them through conversion dictionary loops
          final rawTimeStr = DateFormat('hh:mm a').format(h.time);

          return Container(
            width: 95,
            margin: const EdgeInsets.only(right: 12, bottom: 4),
            decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(14),
                boxShadow: const [
                  BoxShadow(
                      color: Color(0xFFEEEEEE),
                      blurRadius: 4,
                      offset: Offset(0, 2))
                ]),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Text(WeatherData.toBangla(rawTimeStr),
                    style: const TextStyle(fontSize: 10, color: Colors.grey)),
                const SizedBox(height: 4),
                Text('${WeatherData.toBangla(h.tempCelsius.round())}°',
                    style: const TextStyle(
                        fontSize: 15,
                        fontWeight: FontWeight.bold,
                        color: Colors.black87)),
                Text(h.description,
                    style: const TextStyle(fontSize: 9, color: Colors.grey),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis),
              ],
            ),
          );
        },
      ),
    );
  }

  Widget _buildDailyList(List<DailyForecast> days) {
    return ListView.builder(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      itemCount: days.length,
      itemBuilder: (context, idx) {
        final d = days[idx];
        final dayStr = DateFormat('EEEE, d MMMM', 'bn').format(d.date);
        final maxTempStr = WeatherData.toBangla(d.tempMax.round());
        final minTempStr = WeatherData.toBangla(d.tempMin.round());

        return Container(
          margin: const EdgeInsets.only(bottom: 10),
          decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(14),
              boxShadow: const [
                BoxShadow(
                    color: Color(0xFFF2F2F2),
                    blurRadius: 4,
                    offset: Offset(0, 2))
              ]),
          child: ListTile(
            leading: const Icon(Icons.wb_cloudy_outlined,
                color: AppTheme.primaryGreen),
            title: Text(WeatherData.toBangla(dayStr),
                style:
                    const TextStyle(fontWeight: FontWeight.w500, fontSize: 14)),
            trailing: Text('$maxTempStr° / $minTempStr°C',
                style: const TextStyle(
                    fontWeight: FontWeight.bold,
                    color: Colors.black87,
                    fontSize: 14)),
          ),
        );
      },
    );
  }
}
