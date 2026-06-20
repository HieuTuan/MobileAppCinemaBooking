import 'package:flutter/material.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';

import '../../../services/analytics_service.dart';
import '../../core/app_theme.dart';

/// GDPR-compliant analytics consent banner (Req 41.7, 45.8).
///
/// Shows on first launch. User can accept or decline analytics tracking.
/// Decision is persisted in secure storage and applied to [AnalyticsService].
///
/// Usage — wrap in any screen's build or show as dialog:
/// ```dart
/// AnalyticsConsentBanner.showIfNeeded(context);
/// ```
class AnalyticsConsentBanner extends StatelessWidget {
  const AnalyticsConsentBanner({super.key, required this.onDismiss});

  final VoidCallback onDismiss;

  static const _kConsentKey = 'analytics_consent_given';
  static const _storage = FlutterSecureStorage();

  /// Show the banner only if the user has not yet made a choice.
  static Future<void> showIfNeeded(BuildContext context) async {
    final stored = await _storage.read(key: _kConsentKey);
    if (stored != null) return; // already decided
    if (!context.mounted) return;
    showModalBottomSheet<void>(
      context: context,
      isDismissible: false,
      enableDrag: false,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
      ),
      builder: (_) => AnalyticsConsentBanner(
        onDismiss: () => Navigator.of(context).pop(),
      ),
    );
  }

  static Future<void> _saveConsent(bool accepted) async {
    await _storage.write(key: _kConsentKey, value: accepted ? 'true' : 'false');
    await AnalyticsService.instance.setAnalyticsEnabled(enabled: accepted);
  }

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 24, 20, 32),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Icon(Icons.privacy_tip_outlined, color: AppColors.gold),
              const SizedBox(width: 10),
              Text(
                'Quyền riêng tư & Phân tích',
                style: Theme.of(context).textTheme.titleMedium?.copyWith(
                      fontWeight: FontWeight.w900,
                    ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          const Text(
            'CineLuxe thu thập dữ liệu sử dụng ẩn danh để cải thiện trải nghiệm. '
            'Địa chỉ IP được ẩn danh hóa. Chúng tôi không chia sẻ dữ liệu với bên thứ ba '
            'cho mục đích quảng cáo. Bạn có thể thay đổi lựa chọn trong Cài đặt bất kỳ lúc nào.',
            style: TextStyle(height: 1.5),
          ),
          const SizedBox(height: 20),
          Row(
            children: [
              Expanded(
                child: OutlinedButton(
                  onPressed: () async {
                    await _saveConsent(false);
                    onDismiss();
                  },
                  child: const Text('Từ chối'),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: FilledButton(
                  onPressed: () async {
                    await _saveConsent(true);
                    onDismiss();
                  },
                  child: const Text('Đồng ý'),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}
