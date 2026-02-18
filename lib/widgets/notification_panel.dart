import 'package:flutter/material.dart';
import '../services/notification_service.dart';

class NotificationPanel extends StatelessWidget {
  final List<AppNotification> notifications;
  final VoidCallback onMarkAllRead;

  const NotificationPanel({
    super.key,
    required this.notifications,
    required this.onMarkAllRead,
  });

  IconData _iconForType(NotificationType type) {
    switch (type) {
      case NotificationType.confirmation:
        return Icons.check_circle_outline;
      case NotificationType.cancellation:
        return Icons.cancel_outlined;
      case NotificationType.reminder:
        return Icons.alarm;
      case NotificationType.newAppointment:
        return Icons.event_available;
    }
  }

  Color _colorForType(NotificationType type) {
    switch (type) {
      case NotificationType.confirmation:
        return Colors.green;
      case NotificationType.cancellation:
        return Colors.red;
      case NotificationType.reminder:
        return Colors.orange;
      case NotificationType.newAppointment:
        return Colors.blue;
    }
  }

  String _timeAgo(DateTime dt) {
    final diff = DateTime.now().difference(dt);
    if (diff.inMinutes < 1) return 'Just now';
    if (diff.inMinutes < 60) return '${diff.inMinutes}m ago';
    if (diff.inHours < 24) return '${diff.inHours}h ago';
    return '${diff.inDays}d ago';
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 360,
      constraints: const BoxConstraints(maxHeight: 480),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.12),
            blurRadius: 24,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          // Header
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Text(
                  'Notifications',
                  style: TextStyle(fontSize: 16, fontWeight: FontWeight.w700),
                ),
                if (notifications.any((n) => !n.isRead))
                  TextButton(
                    onPressed: onMarkAllRead,
                    style: TextButton.styleFrom(
                      padding: EdgeInsets.zero,
                      minimumSize: Size.zero,
                      tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                    ),
                    child: const Text('Mark all read', style: TextStyle(fontSize: 12)),
                  ),
              ],
            ),
          ),
          const Divider(height: 1),

          // List
          if (notifications.isEmpty)
            const Padding(
              padding: EdgeInsets.all(32),
              child: Column(
                children: [
                  Icon(Icons.notifications_none, size: 48, color: Colors.black26),
                  SizedBox(height: 8),
                  Text('No notifications yet', style: TextStyle(color: Colors.black45)),
                ],
              ),
            )
          else
            Flexible(
              child: ListView.separated(
                shrinkWrap: true,
                padding: const EdgeInsets.symmetric(vertical: 4),
                itemCount: notifications.length,
                separatorBuilder: (_, __) =>
                    const Divider(height: 1, indent: 16, endIndent: 16),
                itemBuilder: (context, index) {
                  final n = notifications[index];
                  final color = _colorForType(n.type);
                  return Container(
                    color: n.isRead ? Colors.white : color.withValues(alpha: 0.05),
                    child: ListTile(
                      dense: true,
                      leading: Container(
                        padding: const EdgeInsets.all(8),
                        decoration: BoxDecoration(
                          color: color.withValues(alpha: 0.12),
                          shape: BoxShape.circle,
                        ),
                        child: Icon(_iconForType(n.type), size: 18, color: color),
                      ),
                      title: Text(
                        n.title,
                        style: TextStyle(
                          fontWeight: n.isRead ? FontWeight.w500 : FontWeight.w700,
                          fontSize: 13,
                        ),
                      ),
                      subtitle: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(n.message, style: const TextStyle(fontSize: 12)),
                          const SizedBox(height: 2),
                          Text(
                            _timeAgo(n.createdAt),
                            style: TextStyle(fontSize: 11, color: Colors.grey.shade500),
                          ),
                        ],
                      ),
                      isThreeLine: true,
                    ),
                  );
                },
              ),
            ),
        ],
      ),
    );
  }
}