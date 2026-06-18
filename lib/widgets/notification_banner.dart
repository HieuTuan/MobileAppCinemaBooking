import 'package:flutter/material.dart';
import 'package:firebase_messaging/firebase_messaging.dart';

/// In-app notification banner for foreground notifications
///
/// Displays a banner at the top of the screen when a notification
/// is received while the app is in the foreground.
///
/// **Requirements:**
/// - Requirement 15.6: Handle foreground notifications with in-app banner
/// - Requirement 16.6: Navigate to appropriate screen when banner is tapped
///
/// Usage:
/// ```dart
/// NotificationBanner.show(
///   context: context,
///   message: remoteMessage,
///   onTap: () => handleNotificationTap(remoteMessage),
/// );
/// ```
class NotificationBanner {
  /// Show an in-app notification banner
  ///
  /// Parameters:
  /// - [context]: BuildContext for showing the banner
  /// - [message]: RemoteMessage from Firebase
  /// - [onTap]: Callback when banner is tapped
  static void show({
    required BuildContext context,
    required RemoteMessage message,
    required VoidCallback onTap,
  }) {
    final notification = message.notification;
    if (notification == null) {
      debugPrint('NotificationBanner: No notification content to display');
      return;
    }

    final title = notification.title ?? 'Thông báo';
    final body = notification.body ?? '';

    // Show a SnackBar with notification content
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: _BannerContent(
          title: title,
          body: body,
          onTap: () {
            ScaffoldMessenger.of(context).hideCurrentSnackBar();
            onTap();
          },
        ),
        duration: const Duration(seconds: 4),
        behavior: SnackBarBehavior.floating,
        backgroundColor: Theme.of(context).colorScheme.primaryContainer,
        dismissDirection: DismissDirection.up,
        margin: const EdgeInsets.only(
          bottom: 16,
          left: 16,
          right: 16,
        ),
      ),
    );
  }

  /// Show a material banner (alternative to SnackBar)
  ///
  /// Material banners stay on screen until dismissed,
  /// useful for important notifications.
  static void showMaterialBanner({
    required BuildContext context,
    required RemoteMessage message,
    required VoidCallback onTap,
  }) {
    final notification = message.notification;
    if (notification == null) {
      debugPrint('NotificationBanner: No notification content to display');
      return;
    }

    final title = notification.title ?? 'Thông báo';
    final body = notification.body ?? '';

    ScaffoldMessenger.of(context).showMaterialBanner(
      MaterialBanner(
        content: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              title,
              style: const TextStyle(
                fontWeight: FontWeight.bold,
                fontSize: 16,
              ),
            ),
            const SizedBox(height: 4),
            Text(body),
          ],
        ),
        leading: const Icon(Icons.notifications_active),
        actions: [
          TextButton(
            onPressed: () {
              ScaffoldMessenger.of(context).hideCurrentMaterialBanner();
            },
            child: const Text('Đóng'),
          ),
          TextButton(
            onPressed: () {
              ScaffoldMessenger.of(context).hideCurrentMaterialBanner();
              onTap();
            },
            child: const Text('Xem'),
          ),
        ],
      ),
    );
  }
}

/// Banner content widget
class _BannerContent extends StatelessWidget {
  const _BannerContent({
    required this.title,
    required this.body,
    required this.onTap,
  });

  final String title;
  final String body;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 8),
        child: Row(
          children: [
            Icon(
              Icons.notifications_active,
              color: Theme.of(context).colorScheme.onPrimaryContainer,
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    title,
                    style: TextStyle(
                      fontWeight: FontWeight.bold,
                      fontSize: 14,
                      color: Theme.of(context).colorScheme.onPrimaryContainer,
                    ),
                  ),
                  if (body.isNotEmpty) ...[
                    const SizedBox(height: 4),
                    Text(
                      body,
                      style: TextStyle(
                        fontSize: 13,
                        color: Theme.of(context).colorScheme.onPrimaryContainer,
                      ),
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ],
                ],
              ),
            ),
            const SizedBox(width: 8),
            Icon(
              Icons.arrow_forward_ios,
              size: 16,
              color: Theme.of(context).colorScheme.onPrimaryContainer,
            ),
          ],
        ),
      ),
    );
  }
}
