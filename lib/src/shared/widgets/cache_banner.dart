import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

import '../../core/app_theme.dart';
import '../../utils/connectivity_service.dart';

/// Compact amber banner shown when displayed data is being served from
/// the local cache. Reused by both the movie list and the bookings list.
class CacheBanner extends StatelessWidget {
  const CacheBanner({
    super.key,
    required this.fromCache,
    required this.cachedAt,
    this.message,
  });

  final bool fromCache;
  final DateTime? cachedAt;
  final String? message;

  @override
  Widget build(BuildContext context) {
    if (!fromCache && ConnectivityService().isOnline) {
      return const SizedBox.shrink();
    }
    final isOffline = !ConnectivityService().isOnline;
    final color = isOffline ? AppColors.danger : AppColors.warning;
    final icon = isOffline ? Icons.cloud_off_rounded : Icons.cached_rounded;
    final defaultMsg = isOffline
        ? 'Mất kết nối mạng. Đang hiển thị kết quả đã lưu cục bộ.'
        : 'Đang hiển thị kết quả được lưu cục bộ.';
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 8, 16, 8),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
        decoration: BoxDecoration(
          color: color.withValues(alpha: .08),
          borderRadius: BorderRadius.circular(8),
          border: Border.all(color: color.withValues(alpha: .35)),
        ),
        child: Row(
          children: [
            Icon(icon, size: 18, color: color),
            const SizedBox(width: 10),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    message ?? defaultMsg,
                    style: TextStyle(
                      color: color,
                      fontWeight: FontWeight.w800,
                      fontSize: 13,
                    ),
                  ),
                  if (cachedAt != null) ...[
                    const SizedBox(height: 2),
                    Text(
                      'Đồng bộ lần cuối: ${DateFormat('dd/MM HH:mm').format(cachedAt!)}',
                      style: TextStyle(
                        color: color.withValues(alpha: .75),
                        fontSize: 11,
                      ),
                    ),
                  ],
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
