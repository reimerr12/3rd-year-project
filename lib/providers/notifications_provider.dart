import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../services/notification_service.dart';
import '../providers/auth_provider.dart';
import '../providers/weather_provider.dart';

// ---------------------------------------------------------------------------
// Language toggle
// ---------------------------------------------------------------------------

final notifLangProvider = StateProvider<bool>((ref) => true); // true = BN

// ---------------------------------------------------------------------------
// Notifications list
// ---------------------------------------------------------------------------

final notificationsProvider =
    AsyncNotifierProvider<NotificationsNotifier, List<NotificationModel>>(
  NotificationsNotifier.new,
);

class NotificationsNotifier extends AsyncNotifier<List<NotificationModel>> {
  final _service = NotificationService.instance;

  @override
  Future<List<NotificationModel>> build() async {
    final user = ref.watch(currentUserProvider);
    if (user == null) return [];

    // Trigger generation on first load — fire and forget
    _generateInBackground(user.id, user.division);

    return _service.fetchNotifications(user.id);
  }

  Future<void> _generateInBackground(String userId, String? division) async {
    try {
      // Get raw OWM forecast data for weather alerts
      // WeatherNotifier exposes rawForecast — see note below
      final weatherNotifier = ref.read(weatherProvider.notifier);
      final rawForecast = weatherNotifier.rawForecast;

      await _service.generateNotifications(
        userId: userId,
        weatherData: rawForecast,
        userDivision: division,
      );

      // Refresh list after generation
      final updated = await _service.fetchNotifications(userId);
      state = AsyncData(updated);
    } catch (_) {
      // Silent — notifications are non-critical
    }
  }

  Future<void> refresh() async {
    final user = ref.read(currentUserProvider);
    if (user == null) return;
    state = const AsyncLoading();
    state = await AsyncValue.guard(() => _service.fetchNotifications(user.id));
  }

  Future<void> markAsRead(String notificationId) async {
    await _service.markAsRead(notificationId);
    state = AsyncData(
      state.value
              ?.map((n) => n.id == notificationId
                  ? NotificationModel(
                      id: n.id,
                      userId: n.userId,
                      titleEn: n.titleEn,
                      titleBn: n.titleBn,
                      bodyEn: n.bodyEn,
                      bodyBn: n.bodyBn,
                      type: n.type,
                      isRead: true,
                      createdAt: n.createdAt,
                    )
                  : n)
              .toList() ??
          [],
    );
  }

  Future<void> markAllAsRead() async {
    final user = ref.read(currentUserProvider);
    if (user == null) return;
    await _service.markAllAsRead(user.id);
    state = AsyncData(
      state.value
              ?.map((n) => NotificationModel(
                    id: n.id,
                    userId: n.userId,
                    titleEn: n.titleEn,
                    titleBn: n.titleBn,
                    bodyEn: n.bodyEn,
                    bodyBn: n.bodyBn,
                    type: n.type,
                    isRead: true,
                    createdAt: n.createdAt,
                  ))
              .toList() ??
          [],
    );
  }
}

// ---------------------------------------------------------------------------
// Unread count — drives bell badge on home screen
// ---------------------------------------------------------------------------

final unreadCountProvider = Provider<int>((ref) {
  final notifs = ref.watch(notificationsProvider);
  return notifs.when(
    data: (list) => list.where((n) => !n.isRead).length,
    loading: () => 0,
    error: (_, __) => 0,
  );
});
