import 'package:flutter/material.dart';
import '../../../api/api_client.dart';
import '../../../models/notification_preferences.dart';
import '../../core/app_theme.dart';
import '../../shared/widgets/glass_card.dart';

/// Notification Preferences Screen
///
/// **Requirements Coverage:**
/// - Requirement 38.1: GET /api/users/{userId}/notification-preferences when opening settings
/// - Requirement 38.2: Display preferences with categories (showtimeReminders, promotions, newMovies, bookingUpdates)
/// - Requirement 38.3: PATCH /api/users/{userId}/notification-preferences when toggling
/// - Requirement 38.6: Display toggle switches for each category with descriptive labels
///
/// Allows customers to manage their notification preferences for different categories.
class NotificationPreferencesScreen extends StatefulWidget {
  const NotificationPreferencesScreen({
    super.key,
    required this.userId,
  });

  final String userId;

  @override
  State<NotificationPreferencesScreen> createState() =>
      _NotificationPreferencesScreenState();
}

class _NotificationPreferencesScreenState
    extends State<NotificationPreferencesScreen> {
  final APIClient _apiClient = APIClient();
  NotificationPreferences? _preferences;
  bool _isLoading = true;
  String? _errorMessage;
  bool _isSaving = false;

  @override
  void initState() {
    super.initState();
    _loadPreferences();
  }

  /// Load notification preferences from API
  ///
  /// **Requirement 38.1**: GET /api/users/{userId}/notification-preferences
  Future<void> _loadPreferences() async {
    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    try {
      final preferences =
          await _apiClient.getNotificationPreferences(widget.userId);
      setState(() {
        _preferences = preferences;
        _isLoading = false;
      });
    } catch (e) {
      setState(() {
        _errorMessage = 'Không thể tải cài đặt thông báo: ${e.toString()}';
        _isLoading = false;
        // Use default preferences if loading fails
        _preferences = NotificationPreferences.defaults;
      });
    }
  }

  /// Update notification preferences via API
  ///
  /// **Requirement 38.3**: PATCH /api/users/{userId}/notification-preferences
  Future<void> _updatePreferences(NotificationPreferences updated) async {
    setState(() {
      _isSaving = true;
    });

    try {
      await _apiClient.updateNotificationPreferences(
        widget.userId,
        updated,
      );

      // Update local state immediately for responsive UI
      setState(() {
        _preferences = updated;
        _isSaving = false;
      });

      // Show success feedback
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Đã cập nhật cài đặt thông báo'),
            duration: Duration(seconds: 2),
            backgroundColor: Colors.green,
          ),
        );
      }
    } catch (e) {
      setState(() {
        _isSaving = false;
      });

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Lỗi: ${e.toString()}'),
            duration: const Duration(seconds: 3),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  /// Handle toggle change for a specific preference
  void _onToggleChanged(String category, bool value) {
    if (_preferences == null || _isSaving) return;

    NotificationPreferences updated;
    switch (category) {
      case 'showtimeReminders':
        updated = _preferences!.copyWith(showtimeReminders: value);
        break;
      case 'promotions':
        updated = _preferences!.copyWith(promotions: value);
        break;
      case 'newMovies':
        updated = _preferences!.copyWith(newMovies: value);
        break;
      case 'bookingUpdates':
        updated = _preferences!.copyWith(bookingUpdates: value);
        break;
      default:
        return;
    }

    _updatePreferences(updated);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Cài đặt thông báo'),
        // Use theme's primary color instead of AppColors.primary (doesn't exist)
        backgroundColor: AppColors.ink,
        foregroundColor: Colors.white,
      ),
      body: _buildBody(),
    );
  }

  Widget _buildBody() {
    if (_isLoading) {
      return const Center(
        child: CircularProgressIndicator(),
      );
    }

    if (_errorMessage != null && _preferences == null) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(Icons.error_outline, size: 64, color: Colors.red),
            const SizedBox(height: 16),
            Text(
              _errorMessage!,
              textAlign: TextAlign.center,
              style: const TextStyle(fontSize: 16),
            ),
            const SizedBox(height: 24),
            ElevatedButton.icon(
              onPressed: _loadPreferences,
              icon: const Icon(Icons.refresh),
              label: const Text('Thử lại'),
            ),
          ],
        ),
      );
    }

    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        if (_errorMessage != null)
          GlassCard(
            child: Row(
              children: [
                const Icon(Icons.warning, color: Colors.orange),
                const SizedBox(width: 12),
                Expanded(
                  child: Text(
                    _errorMessage!,
                    style: const TextStyle(color: Colors.orange),
                  ),
                ),
              ],
            ),
          ),
        const SizedBox(height: 8),
        GlassCard(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Quản lý thông báo',
                style: Theme.of(context).textTheme.titleLarge?.copyWith(
                      fontWeight: FontWeight.bold,
                    ),
              ),
              const SizedBox(height: 8),
              Text(
                'Chọn loại thông báo bạn muốn nhận. Thông báo quan trọng (xác nhận thanh toán, hủy vé) sẽ luôn được gửi.',
                style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                      color: Colors.grey[600],
                    ),
              ),
            ],
          ),
        ),
        const SizedBox(height: 16),
        _buildPreferenceToggle(
          title: 'Nhắc lịch chiếu',
          subtitle:
              'Nhận thông báo nhắc nhở 2 giờ trước giờ chiếu phim của bạn',
          icon: Icons.access_time,
          value: _preferences!.showtimeReminders,
          onChanged: (value) => _onToggleChanged('showtimeReminders', value),
        ),
        const SizedBox(height: 12),
        _buildPreferenceToggle(
          title: 'Khuyến mãi',
          subtitle: 'Nhận thông báo về các chương trình khuyến mãi và ưu đãi',
          icon: Icons.local_offer,
          value: _preferences!.promotions,
          onChanged: (value) => _onToggleChanged('promotions', value),
        ),
        const SizedBox(height: 12),
        _buildPreferenceToggle(
          title: 'Phim mới',
          subtitle: 'Nhận thông báo khi có phim mới ra mắt',
          icon: Icons.new_releases,
          value: _preferences!.newMovies,
          onChanged: (value) => _onToggleChanged('newMovies', value),
        ),
        const SizedBox(height: 12),
        _buildPreferenceToggle(
          title: 'Cập nhật đặt vé',
          subtitle: 'Nhận thông báo về trạng thái đặt vé và thay đổi',
          icon: Icons.confirmation_number,
          value: _preferences!.bookingUpdates,
          onChanged: (value) => _onToggleChanged('bookingUpdates', value),
        ),
        if (_isSaving)
          const Padding(
            padding: EdgeInsets.only(top: 16),
            child: Center(
              child: CircularProgressIndicator(),
            ),
          ),
      ],
    );
  }

  /// Build a toggle switch for a notification preference
  ///
  /// **Requirement 38.6**: Display toggle switches with descriptive labels
  Widget _buildPreferenceToggle({
    required String title,
    required String subtitle,
    required IconData icon,
    required bool value,
    required ValueChanged<bool> onChanged,
  }) {
    return GlassCard(
      child: SwitchListTile(
        value: value,
        onChanged: _isSaving ? null : onChanged,
        title: Row(
          children: [
            Icon(icon, size: 24, color: AppColors.gold),
            const SizedBox(width: 12),
            Expanded(
              child: Text(
                title,
                style: const TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
          ],
        ),
        subtitle: Padding(
          padding: const EdgeInsets.only(left: 36, top: 4),
          child: Text(
            subtitle,
            style: TextStyle(
              fontSize: 14,
              color: Colors.grey[600],
            ),
          ),
        ),
        activeColor: AppColors.gold,
        contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      ),
    );
  }
}
