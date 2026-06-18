import 'package:flutter/material.dart';

/// Banner widget to display offline mode indicator.
///
/// **Requirements Coverage:**
/// - Requirement 35.4: Display offline indicators with "Showing cached results" banner
/// - Requirement 35.8: Visual indicators for cached vs. live data
///
/// Usage:
/// ```dart
/// Column(
///   children: [
///     if (!isOnline) OfflineBanner(),
///     // Rest of content
///   ],
/// )
/// ```
class OfflineBanner extends StatelessWidget {
  final String? message;
  final bool showTimestamp;
  final DateTime? lastSyncTime;

  const OfflineBanner({
    super.key,
    this.message,
    this.showTimestamp = false,
    this.lastSyncTime,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      decoration: BoxDecoration(
        color: Colors.orange[100],
        border: Border(
          bottom: BorderSide(color: Colors.orange[300]!, width: 2),
        ),
      ),
      child: Row(
        children: [
          Icon(Icons.cloud_off, color: Colors.orange[900], size: 20),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  message ?? 'Showing cached results',
                  style: TextStyle(
                    color: Colors.orange[900],
                    fontWeight: FontWeight.w600,
                    fontSize: 14,
                  ),
                ),
                if (showTimestamp && lastSyncTime != null) ...[
                  const SizedBox(height: 4),
                  Text(
                    'Last synced: ${_formatTimestamp(lastSyncTime!)}',
                    style: TextStyle(
                      color: Colors.orange[800],
                      fontSize: 12,
                    ),
                  ),
                ],
              ],
            ),
          ),
          Icon(Icons.info_outline, color: Colors.orange[700], size: 18),
        ],
      ),
    );
  }

  String _formatTimestamp(DateTime time) {
    final now = DateTime.now();
    final difference = now.difference(time);

    if (difference.inMinutes < 1) {
      return 'Just now';
    } else if (difference.inMinutes < 60) {
      return '${difference.inMinutes} min ago';
    } else if (difference.inHours < 24) {
      return '${difference.inHours} hours ago';
    } else {
      return '${difference.inDays} days ago';
    }
  }
}

/// Chip widget to indicate cached data.
///
/// Small badge to show individual items are from cache.
class CachedBadge extends StatelessWidget {
  const CachedBadge({super.key});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: Colors.grey[300],
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.grey[400]!),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(Icons.save_alt, size: 12, color: Colors.grey[700]),
          const SizedBox(width: 4),
          Text(
            'Cached',
            style: TextStyle(
              color: Colors.grey[700],
              fontSize: 10,
              fontWeight: FontWeight.w600,
            ),
          ),
        ],
      ),
    );
  }
}

/// Shimmer loading placeholder for offline mode.
///
/// Shows when trying to load data that's not cached.
class OfflineLoadingPlaceholder extends StatelessWidget {
  final String message;

  const OfflineLoadingPlaceholder({
    super.key,
    this.message = 'This content is not available offline',
  });

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32.0),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              Icons.cloud_off_outlined,
              size: 64,
              color: Colors.grey[400],
            ),
            const SizedBox(height: 16),
            Text(
              message,
              textAlign: TextAlign.center,
              style: TextStyle(
                color: Colors.grey[600],
                fontSize: 16,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              'Connect to the internet to load this content',
              textAlign: TextAlign.center,
              style: TextStyle(
                color: Colors.grey[500],
                fontSize: 14,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
