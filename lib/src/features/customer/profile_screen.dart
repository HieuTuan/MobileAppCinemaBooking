import 'package:flutter/material.dart';

import '../../../api/api_client.dart';
import '../../../models/update_profile_request.dart';
import '../../../models/user_profile.dart';
import '../../core/app_theme.dart';
import '../../core/formatters.dart';
import '../../core/labels.dart';
import '../../shared/widgets/glass_card.dart';
import '../../state/cinema_store.dart';
import 'notification_preferences_screen.dart';

class ProfileScreen extends StatefulWidget {
  const ProfileScreen({super.key, required this.store});

  final CinemaStore store;

  @override
  State<ProfileScreen> createState() => _ProfileScreenState();
}

class _ProfileScreenState extends State<ProfileScreen> {
  // ── form controllers ──────────────────────────────────────────────────────
  late final TextEditingController _name;
  late final TextEditingController _phone;
  late final TextEditingController _email;

  // ── state ─────────────────────────────────────────────────────────────────
  bool _loadingProfile = false;
  bool _saving = false;
  UserProfile? _remoteProfile;

  DateTime? _birthdate;

  // inline validation errors
  String? _phoneError;
  String? _birthdateError;

  // pending email change flag (set when user edited email field)
  bool _pendingEmailChange = false;

  // ── API ───────────────────────────────────────────────────────────────────
  final _api = APIClient();

  @override
  void initState() {
    super.initState();
    final user = widget.store.currentUser!;
    _name = TextEditingController(text: user.fullName);
    _phone = TextEditingController(text: user.phone);
    _email = TextEditingController(text: user.email);
    _fetchProfile();
  }

  @override
  void dispose() {
    _name.dispose();
    _phone.dispose();
    _email.dispose();
    super.dispose();
  }

  // ── helpers ───────────────────────────────────────────────────────────────

  Future<void> _fetchProfile() async {
    final userId = widget.store.currentUser?.id;
    if (userId == null) return;
    setState(() => _loadingProfile = true);
    try {
      final profile = await _api.getProfile(userId);
      if (!mounted) return;
      setState(() {
        _remoteProfile = profile;
        // Prefill birthdate from remote profile if not yet set
        _birthdate ??= profile.birthdate;
      });
    } catch (_) {
      // Silently fall back to local data on network error
    } finally {
      if (mounted) setState(() => _loadingProfile = false);
    }
  }

  /// Validates phone and birthdate fields.
  /// Returns true when all inline validations pass.
  bool _validate() {
    final request = UpdateProfileRequest(
      phone: _phone.text.isEmpty ? null : _phone.text.trim(),
      birthdate: _birthdate,
    );

    final phoneErr = request.validatePhone();
    final bdErr = request.validateBirthdate();

    setState(() {
      _phoneError = phoneErr;
      _birthdateError = bdErr;
    });

    return phoneErr == null && bdErr == null;
  }

  Future<void> _save() async {
    if (!_validate()) return;

    final userId = widget.store.currentUser?.id;
    if (userId == null) return;

    final currentEmail = widget.store.currentUser!.email;
    final newEmail = _email.text.trim();
    final emailChanged = newEmail.isNotEmpty && newEmail != currentEmail;

    setState(() => _saving = true);
    try {
      final request = UpdateProfileRequest(
        fullName: _name.text.trim().isEmpty ? null : _name.text.trim(),
        phone: _phone.text.trim().isEmpty ? null : _phone.text.trim(),
        birthdate: _birthdate,
      );

      final updatedProfile = await _api.updateProfile(userId, request);

      // Also update local store so the UI reflects the change immediately
      widget.store.updateProfile(_name.text.trim(), _phone.text.trim());

      if (!mounted) return;
      setState(() {
        _remoteProfile = updatedProfile;
        _pendingEmailChange = emailChanged;
      });

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Cập nhật hồ sơ thành công')),
      );
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Cập nhật thất bại: ${e.toString()}'),
          backgroundColor: AppColors.danger,
        ),
      );
    } finally {
      if (mounted) setState(() => _saving = false);
    }
  }

  Future<void> _pickBirthdate() async {
    final now = DateTime.now();
    final picked = await showDatePicker(
      context: context,
      initialDate: _birthdate ?? DateTime(now.year - 20),
      firstDate: DateTime(1920),
      lastDate: now,
      helpText: 'Chọn ngày sinh',
      confirmText: 'Xác nhận',
      cancelText: 'Hủy',
    );
    if (picked == null) return;
    setState(() {
      _birthdate = picked;
      // Clear birthdate error once user picks a valid date
      _birthdateError = null;
    });
  }

  // ── build ─────────────────────────────────────────────────────────────────

  @override
  Widget build(BuildContext context) {
    final localUser = widget.store.currentUser!;
    final history = widget.store.bookingsForUser(localUser.id);

    // Use remote rank/points when available, fall back to local store
    final memberRank = _remoteProfile?.memberRank ?? localUser.memberRank;
    final points = _remoteProfile?.points ?? localUser.points;

    return ListView(
      padding: const EdgeInsets.fromLTRB(16, 8, 16, 100),
      children: [
        // ── Profile header card ──────────────────────────────────────────
        GlassCard(
          child: _loadingProfile
              ? const Center(
                  child: Padding(
                    padding: EdgeInsets.symmetric(vertical: 8),
                    child: CircularProgressIndicator(),
                  ),
                )
              : Row(
                  children: [
                    CircleAvatar(
                      radius: 34,
                      backgroundColor: AppColors.goldSoft,
                      child: Text(
                        localUser.fullName.characters.first.toUpperCase(),
                        style: const TextStyle(
                          fontSize: 28,
                          fontWeight: FontWeight.w900,
                        ),
                      ),
                    ),
                    const SizedBox(width: 14),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            localUser.fullName,
                            style: Theme.of(
                              context,
                            ).textTheme.titleLarge?.copyWith(
                              fontWeight: FontWeight.w900,
                            ),
                          ),
                          Text('$memberRank · $points điểm'),
                          Text(localUser.email),
                        ],
                      ),
                    ),
                  ],
                ),
        ),

        // ── Pending email change banner ──────────────────────────────────
        if (_pendingEmailChange) ...[
          const SizedBox(height: 10),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
            decoration: BoxDecoration(
              color: AppColors.warning.withValues(alpha: .12),
              border: Border.all(color: AppColors.warning),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Row(
              children: [
                const Icon(Icons.mail_outline, color: AppColors.warning),
                const SizedBox(width: 10),
                Expanded(
                  child: Text(
                    'Yêu cầu thay đổi email đang chờ xác minh. '
                    'Email xác nhận đã được gửi đến địa chỉ mới.',
                    style: TextStyle(
                      fontSize: 13,
                      color: AppColors.warning,
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],

        // ── Update profile form ──────────────────────────────────────────
        const SectionTitle(title: 'Cập nhật thông tin'),
        GlassCard(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Full name
              TextField(
                controller: _name,
                decoration: const InputDecoration(labelText: 'Họ và tên'),
              ),
              const SizedBox(height: 10),

              // Phone with inline validation
              TextField(
                controller: _phone,
                keyboardType: TextInputType.phone,
                decoration: InputDecoration(
                  labelText: 'Số điện thoại',
                  errorText: _phoneError,
                  errorStyle: const TextStyle(color: AppColors.danger),
                ),
                onChanged: (_) {
                  if (_phoneError != null) setState(() => _phoneError = null);
                },
              ),
              const SizedBox(height: 10),

              // Email field with change-notification message
              TextField(
                controller: _email,
                keyboardType: TextInputType.emailAddress,
                decoration: const InputDecoration(labelText: 'Email'),
                onChanged: (value) {
                  final original = widget.store.currentUser!.email;
                  if (value.trim() != original) {
                    // Show the notice inline once the user starts changing the email
                    ScaffoldMessenger.of(context).clearSnackBars();
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(
                        content: Text(
                          'Thay đổi email cần xác minh. '
                          'Email xác nhận sẽ được gửi đến địa chỉ mới.',
                        ),
                        duration: Duration(seconds: 4),
                      ),
                    );
                  }
                },
              ),
              const SizedBox(height: 10),

              // Birthdate picker
              InkWell(
                onTap: _pickBirthdate,
                borderRadius: BorderRadius.circular(8),
                child: InputDecorator(
                  decoration: InputDecoration(
                    labelText: 'Ngày sinh',
                    errorText: _birthdateError,
                    errorStyle: const TextStyle(color: AppColors.danger),
                    suffixIcon: const Icon(Icons.calendar_today_outlined),
                  ),
                  child: Text(
                    _birthdate != null
                        ? shortDate(_birthdate!)
                        : 'Chưa chọn ngày sinh',
                    style: TextStyle(
                      color: _birthdate != null
                          ? AppColors.ink
                          : AppColors.muted,
                    ),
                  ),
                ),
              ),
              const SizedBox(height: 14),

              SizedBox(
                width: double.infinity,
                child: FilledButton.icon(
                  onPressed: _saving ? null : _save,
                  icon: _saving
                      ? const SizedBox(
                          width: 18,
                          height: 18,
                          child: CircularProgressIndicator(
                            strokeWidth: 2,
                            color: Colors.white,
                          ),
                        )
                      : const Icon(Icons.save_outlined),
                  label: Text(_saving ? 'Đang lưu...' : 'Lưu hồ sơ'),
                ),
              ),
            ],
          ),
        ),

        // ── Notification settings ────────────────────────────────────────
        const SectionTitle(title: 'Cài đặt thông báo'),
        GlassCard(
          child: ListTile(
            contentPadding: EdgeInsets.zero,
            leading: const Icon(Icons.notifications, color: AppColors.gold),
            title: const Text('Quản lý thông báo'),
            subtitle: const Text('Cài đặt tùy chọn nhận thông báo'),
            trailing: const Icon(Icons.chevron_right),
            onTap: () {
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (context) => NotificationPreferencesScreen(
                    userId: localUser.id,
                  ),
                ),
              );
            },
          ),
        ),

        // ── Booking history ──────────────────────────────────────────────
        const SectionTitle(title: 'Lịch sử vé'),
        if (history.isEmpty)
          const GlassCard(child: Text('Chưa có lịch sử đặt vé.'))
        else
          ...history.map(
            (booking) => GlassCard(
              margin: const EdgeInsets.only(bottom: 10),
              child: ListTile(
                contentPadding: EdgeInsets.zero,
                leading: const Icon(Icons.confirmation_number_rounded),
                title: Text(booking.movieTitle),
                subtitle: Text(
                  '${fullDateTime(booking.createdAt)} - ${bookingStatusLabel(booking.status)}',
                ),
                trailing: Text(money(booking.totalAmount)),
              ),
            ),
          ),
      ],
    );
  }
}
