import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import '../../core/theme.dart';
import '../../providers/notifications_provider.dart';
import '../../services/notification_service.dart';

class NotificationsScreen extends ConsumerWidget {
  const NotificationsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final isBn = ref.watch(notifLangProvider);
    final notifsAsync = ref.watch(notificationsProvider);

    return Scaffold(
      backgroundColor: AppTheme.bgLight,
      appBar: AppBar(
        backgroundColor: AppTheme.primaryGreen,
        foregroundColor: Colors.white,
        elevation: 0,
        title: Text(
          isBn ? 'বিজ্ঞপ্তি' : 'Notifications',
          style: const TextStyle(
            fontWeight: FontWeight.w600,
            fontSize: 18,
          ),
        ),
        actions: [
          // Language toggle
          TextButton(
            onPressed: () => ref.read(notifLangProvider.notifier).state = !isBn,
            child: Text(
              isBn ? 'EN' : 'বাং',
              style: const TextStyle(
                color: Colors.white,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
          // Mark all read
          notifsAsync.when(
            data: (list) {
              final hasUnread = list.any((n) => !n.isRead);
              if (!hasUnread) return const SizedBox.shrink();
              return IconButton(
                icon: const Icon(Icons.done_all),
                tooltip: isBn ? 'সব পড়া হয়েছে' : 'Mark all read',
                onPressed: () =>
                    ref.read(notificationsProvider.notifier).markAllAsRead(),
              );
            },
            loading: () => const SizedBox.shrink(),
            error: (_, __) => const SizedBox.shrink(),
          ),
        ],
      ),
      body: notifsAsync.when(
        loading: () => const Center(
          child: CircularProgressIndicator(color: AppTheme.primaryGreen),
        ),
        error: (e, _) => _ErrorState(isBn: isBn),
        data: (notifications) {
          if (notifications.isEmpty) {
            return _EmptyState(isBn: isBn);
          }
          return RefreshIndicator(
            color: AppTheme.primaryGreen,
            onRefresh: () => ref.read(notificationsProvider.notifier).refresh(),
            child: ListView.separated(
              padding: const EdgeInsets.symmetric(vertical: 12),
              itemCount: notifications.length,
              separatorBuilder: (_, __) => const SizedBox(height: 4),
              itemBuilder: (context, index) {
                final notif = notifications[index];
                return _NotificationTile(
                  notification: notif,
                  isBn: isBn,
                  onTap: () {
                    if (!notif.isRead) {
                      ref
                          .read(notificationsProvider.notifier)
                          .markAsRead(notif.id);
                    }
                  },
                );
              },
            ),
          );
        },
      ),
    );
  }
}

// Tile
class _NotificationTile extends StatelessWidget {
  final NotificationModel notification;
  final bool isBn;
  final VoidCallback onTap;

  const _NotificationTile({
    required this.notification,
    required this.isBn,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final isUnread = !notification.isRead;

    return GestureDetector(
      onTap: onTap,
      child: Container(
        margin: const EdgeInsets.symmetric(horizontal: 12),
        decoration: BoxDecoration(
          color: isUnread
              ? AppTheme.primaryGreen.withValues(alpha: 0.06)
              : Colors.white,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: isUnread
                ? AppTheme.primaryGreen.withValues(alpha: 0.25)
                : Colors.grey.shade200,
            width: 1,
          ),
        ),
        child: Padding(
          padding: const EdgeInsets.all(14),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Icon
              Container(
                width: 40,
                height: 40,
                decoration: BoxDecoration(
                  color: _typeColor(notification.type).withValues(alpha: 0.12),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Icon(
                  _typeIcon(notification.type),
                  color: _typeColor(notification.type),
                  size: 20,
                ),
              ),
              const SizedBox(width: 12),
              // Content
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Expanded(
                          child: Text(
                            notification.title(isBn),
                            style: TextStyle(
                              fontSize: 14,
                              fontWeight:
                                  isUnread ? FontWeight.w600 : FontWeight.w500,
                              color: const Color(0xFF1A1A1A),
                            ),
                          ),
                        ),
                        if (isUnread)
                          Container(
                            width: 8,
                            height: 8,
                            decoration: const BoxDecoration(
                              color: AppTheme.primaryGreen,
                              shape: BoxShape.circle,
                            ),
                          ),
                      ],
                    ),
                    const SizedBox(height: 4),
                    Text(
                      notification.body(isBn),
                      style: TextStyle(
                        fontSize: 13,
                        color: Colors.grey.shade600,
                        height: 1.4,
                      ),
                    ),
                    const SizedBox(height: 6),
                    Text(
                      _formatTime(notification.createdAt, isBn),
                      style: TextStyle(
                        fontSize: 11,
                        color: Colors.grey.shade400,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  IconData _typeIcon(String type) {
    switch (type) {
      case 'weather':
        return Icons.wb_cloudy_rounded;
      case 'booking':
        return Icons.agriculture_rounded;
      case 'order':
        return Icons.shopping_bag_rounded;
      case 'system':
      default:
        return Icons.eco_rounded;
    }
  }

  Color _typeColor(String type) {
    switch (type) {
      case 'weather':
        return const Color(0xFF2196F3);
      case 'booking':
        return const Color(0xFFFF9800);
      case 'order':
        return const Color(0xFF9C27B0);
      case 'system':
      default:
        return AppTheme.primaryGreen;
    }
  }

  String _formatTime(DateTime dt, bool isBn) {
    final now = DateTime.now();
    final diff = now.difference(dt);

    if (diff.inMinutes < 60) {
      final mins = diff.inMinutes == 0 ? 1 : diff.inMinutes;
      return isBn ? '$mins মিনিট আগে' : '${mins}m ago';
    } else if (diff.inHours < 24) {
      return isBn ? '${diff.inHours} ঘণ্টা আগে' : '${diff.inHours}h ago';
    } else {
      final formatted =
          DateFormat(isBn ? 'd MMM' : 'd MMM', isBn ? 'bn' : 'en').format(dt);
      return formatted;
    }
  }
}

// Empty  Error states
class _EmptyState extends StatelessWidget {
  final bool isBn;
  const _EmptyState({required this.isBn});

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.notifications_none_rounded,
              size: 64, color: Colors.grey.shade300),
          const SizedBox(height: 16),
          Text(
            isBn ? 'কোনো বিজ্ঞপ্তি নেই' : 'No notifications yet',
            style: TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.w500,
              color: Colors.grey.shade500,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            isBn
                ? 'আবহাওয়া ও ফসলের আপডেট এখানে দেখাবে'
                : 'Weather and crop updates will appear here',
            style: TextStyle(fontSize: 13, color: Colors.grey.shade400),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }
}

class _ErrorState extends StatelessWidget {
  final bool isBn;
  const _ErrorState({required this.isBn});

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.error_outline_rounded,
              size: 48, color: Colors.grey.shade300),
          const SizedBox(height: 12),
          Text(
            isBn ? 'লোড করা যায়নি' : 'Failed to load',
            style: TextStyle(color: Colors.grey.shade500, fontSize: 15),
          ),
        ],
      ),
    );
  }
}
