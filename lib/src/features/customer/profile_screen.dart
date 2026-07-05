import 'package:flutter/material.dart';

import '../../../api/api_client.dart';
import '../../../models/update_profile_request.dart';
import '../../../models/user_profile.dart';
import '../../core/app_theme.dart';
import '../../core/formatters.dart';
import '../../core/labels.dart';
import '../../models/app_models.dart';
import '../../state/cinema_store.dart';
import 'notification_preferences_screen.dart';
import 'wallet_screen.dart';

// ── Màu bổ sung cho trang profile (cinema dark theme) ─────────────────────────
const _kCinemaRed = Color(0xFFE53935);
const _kCinemaGold = Color(0xFFC9A44C);
const _kDarkBg = Color(0xFF0F172A);
const _kDarkCard = Color(0xFF1E293B);
const _kDarkSurface = Color(0xFF263044);

class ProfileScreen extends StatefulWidget {
  const ProfileScreen({super.key, required this.store});

  final CinemaStore store;

  @override
  State<ProfileScreen> createState() => _ProfileScreenState();
}

class _ProfileScreenState extends State<ProfileScreen>
    with SingleTickerProviderStateMixin {
  // ── form controllers ──────────────────────────────────────────────────────
  late final TextEditingController _name;
  late final TextEditingController _phone;
  late final TextEditingController _email;

  // ── state ─────────────────────────────────────────────────────────────────
  bool _loadingProfile = false;
  bool _saving = false;
  UserProfile? _remoteProfile;
  DateTime? _birthdate;
  String? _phoneError;
  String? _birthdateError;
  bool _pendingEmailChange = false;
  bool _editMode = false;

  // ── animation ─────────────────────────────────────────────────────────────
  AnimationController? _heroCtrl;
  Animation<double>? _heroFade;

  // ── API ───────────────────────────────────────────────────────────────────
  final _api = APIClient();

  @override
  void initState() {
    super.initState();
    final user = widget.store.currentUser!;
    _name = TextEditingController(text: user.fullName);
    _phone = TextEditingController(text: user.phone);
    _email = TextEditingController(text: user.email);

    _heroCtrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 650),
    )..forward();
    _heroFade = CurvedAnimation(parent: _heroCtrl!, curve: Curves.easeOut);

    _fetchProfile();
  }

  @override
  void dispose() {
    _name.dispose();
    _phone.dispose();
    _email.dispose();
    _heroCtrl?.dispose();
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
        _birthdate ??= profile.birthdate;
        if (!_editMode) {
          _name.text = profile.fullName;
          _phone.text = profile.phone ?? '';
          _email.text = profile.email;
        }
      });
      widget.store.setCurrentUserFromProfile(profile);
    } catch (_) {
      // Silently fall back to local data
    } finally {
      if (mounted) setState(() => _loadingProfile = false);
    }
  }

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
      widget.store.setCurrentUserFromProfile(updatedProfile);
      if (!mounted) return;
      setState(() {
        _remoteProfile = updatedProfile;
        _name.text = updatedProfile.fullName;
        _phone.text = updatedProfile.phone ?? '';
        _email.text = updatedProfile.email;
        _birthdate = updatedProfile.birthdate;
        _pendingEmailChange = emailChanged;
        _editMode = false;
      });
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          duration: const Duration(seconds: 3),
          backgroundColor: Colors.transparent,
          elevation: 0,
          behavior: SnackBarBehavior.floating,
          margin: const EdgeInsets.fromLTRB(16, 0, 16, 90),
          content: Container(
            padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 14),
            decoration: BoxDecoration(
              gradient: const LinearGradient(
                colors: [Color(0xFF1B3A2A), Color(0xFF1E4D34)],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
              borderRadius: BorderRadius.circular(14),
              border: Border.all(
                color: const Color(0xFF1B9E66).withValues(alpha: .55),
              ),
              boxShadow: [
                BoxShadow(
                  color: const Color(0xFF1B9E66).withValues(alpha: .25),
                  blurRadius: 20,
                  offset: const Offset(0, 8),
                ),
              ],
            ),
            child: const Row(
              children: [
                Icon(
                  Icons.check_circle_rounded,
                  color: Color(0xFF4ECDA4),
                  size: 20,
                ),
                SizedBox(width: 12),
                Expanded(
                  child: Text(
                    'Cập nhật hồ sơ thành công',
                    style: TextStyle(
                      color: Colors.white,
                      fontWeight: FontWeight.w700,
                      fontSize: 14,
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      );
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          duration: const Duration(seconds: 3),
          backgroundColor: Colors.transparent,
          elevation: 0,
          behavior: SnackBarBehavior.floating,
          margin: const EdgeInsets.fromLTRB(16, 0, 16, 90),
          content: Container(
            padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 14),
            decoration: BoxDecoration(
              gradient: const LinearGradient(
                colors: [Color(0xFF2D1515), Color(0xFF451A1A)],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
              borderRadius: BorderRadius.circular(14),
              border: Border.all(
                color: const Color(0xFFD04747).withValues(alpha: .5),
              ),
              boxShadow: [
                BoxShadow(
                  color: const Color(0xFFD04747).withValues(alpha: .15),
                  blurRadius: 20,
                  offset: const Offset(0, 8),
                ),
              ],
            ),
            child: Row(
              children: [
                const Icon(
                  Icons.error_rounded,
                  color: Color(0xFFFF7A7A),
                  size: 20,
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Text(
                    'Cập nhật thất bại: ${e.toString()}',
                    style: const TextStyle(
                      color: Colors.white,
                      fontWeight: FontWeight.w700,
                      fontSize: 14,
                    ),
                  ),
                ),
              ],
            ),
          ),
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
      builder: (ctx, child) => Theme(
        data: Theme.of(ctx).copyWith(
          colorScheme: const ColorScheme.dark(
            primary: _kCinemaGold,
            surface: _kDarkCard,
          ),
        ),
        child: child!,
      ),
    );
    if (picked == null) return;
    setState(() {
      _birthdate = picked;
      _birthdateError = null;
    });
  }

  // ── rank helpers ──────────────────────────────────────────────────────────

  Color _rankColor(String rank) {
    switch (rank.toLowerCase()) {
      case 'gold':
      case 'vàng':
        return _kCinemaGold;
      case 'platinum':
      case 'bạch kim':
        return const Color(0xFFE5E7EB);
      case 'silver':
      case 'bạc':
        return const Color(0xFF94A3B8);
      default:
        return const Color(0xFF6366F1);
    }
  }

  IconData _rankIcon(String rank) {
    switch (rank.toLowerCase()) {
      case 'gold':
      case 'vàng':
        return Icons.workspace_premium_rounded;
      case 'platinum':
      case 'bạch kim':
        return Icons.diamond_rounded;
      default:
        return Icons.star_rounded;
    }
  }

  // ── build ─────────────────────────────────────────────────────────────────

  @override
  Widget build(BuildContext context) {
    final localUser = widget.store.currentUser!;
    final memberRank = _remoteProfile?.memberRank ?? localUser.memberRank;
    final points = _remoteProfile?.points ?? localUser.points;
    final initials = localUser.fullName.trim().isNotEmpty
        ? localUser.fullName.trim().characters.first.toUpperCase()
        : '?';

    return FadeTransition(
      opacity: _heroFade ?? const AlwaysStoppedAnimation(1.0),
      child: ListView(
        padding: EdgeInsets.zero,
        children: [
          // ═══════════════════════════════════════════════════════════════
          // HERO HEADER — dark cinema gradient + avatar
          // ═══════════════════════════════════════════════════════════════
          _HeroHeader(
            initials: initials,
            fullName: localUser.fullName,
            email: localUser.email,
            memberRank: memberRank,
            points: points,
            rankColor: _rankColor(memberRank),
            rankIcon: _rankIcon(memberRank),
            loading: _loadingProfile,
            onEditTap: () => setState(() => _editMode = !_editMode),
            editMode: _editMode,
          ),

          const SizedBox(height: 20),

          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // ── Pending email change banner ────────────────────────
                if (_pendingEmailChange) ...[
                  const _InfoBanner(
                    icon: Icons.mail_outline_rounded,
                    message:
                        'Yêu cầu thay đổi email đang chờ xác minh. '
                        'Email xác nhận đã được gửi đến địa chỉ mới.',
                    color: Color(0xFFF59E0B),
                  ),
                  const SizedBox(height: 16),
                ],

                // ═══════════════════════════════════════════════════════
                // EDIT PROFILE FORM (collapsible)
                // ═══════════════════════════════════════════════════════
                AnimatedSize(
                  duration: const Duration(milliseconds: 280),
                  curve: Curves.easeInOut,
                  child: _editMode
                      ? _ProfileForm(
                          nameCtrl: _name,
                          phoneCtrl: _phone,
                          emailCtrl: _email,
                          birthdate: _birthdate,
                          phoneError: _phoneError,
                          birthdateError: _birthdateError,
                          saving: _saving,
                          onPhoneChanged: (_) {
                            if (_phoneError != null) {
                              setState(() => _phoneError = null);
                            }
                          },
                          onEmailChanged: (value) {
                            final original = widget.store.currentUser!.email;
                            if (value.trim() != original) {
                              ScaffoldMessenger.of(context)
                                ..clearSnackBars()
                                ..showSnackBar(
                                  const SnackBar(
                                    content: Text(
                                      'Thay đổi email cần xác minh qua email.',
                                    ),
                                    duration: Duration(seconds: 4),
                                  ),
                                );
                            }
                          },
                          onPickBirthdate: _pickBirthdate,
                          onSave: _save,
                          onCancel: () => setState(() => _editMode = false),
                        )
                      : const SizedBox.shrink(),
                ),

                if (_editMode) const SizedBox(height: 20),

                // ═══════════════════════════════════════════════════════
                // QUICK ACTIONS
                // ═══════════════════════════════════════════════════════
                const _SectionLabel(label: 'Dịch vụ'),
                const SizedBox(height: 10),
                Row(
                  children: [
                    Expanded(
                      child: _QuickTile(
                        icon: Icons.account_balance_wallet_rounded,
                        label: 'Ví điện tử',
                        subtitle: 'Số dư & rút tiền',
                        gradient: const LinearGradient(
                          colors: [Color(0xFF1565C0), Color(0xFF0D47A1)],
                          begin: Alignment.topLeft,
                          end: Alignment.bottomRight,
                        ),
                        onTap: () => Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (_) => WalletScreen(store: widget.store),
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: _QuickTile(
                        icon: Icons.notifications_rounded,
                        label: 'Thông báo',
                        subtitle: 'Tùy chọn nhận tin',
                        gradient: const LinearGradient(
                          colors: [Color(0xFF7C3AED), Color(0xFF5B21B6)],
                          begin: Alignment.topLeft,
                          end: Alignment.bottomRight,
                        ),
                        onTap: () => Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (_) => NotificationPreferencesScreen(
                              userId: localUser.id,
                            ),
                          ),
                        ),
                      ),
                    ),
                  ],
                ),

                const SizedBox(height: 24),

                // ═══════════════════════════════════════════════════════
                // BOOKING HISTORY
                // ═══════════════════════════════════════════════════════
                // _SectionLabel(label: 'Lịch sử vé'),
                // const SizedBox(height: 10),
                // if (history.isEmpty)
                //   _EmptyHistory()
                // else
                //   ...history.map((booking) => _BookingTile(booking: booking)),

                // const SizedBox(height: 100),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// HERO HEADER
// ─────────────────────────────────────────────────────────────────────────────

class _HeroHeader extends StatelessWidget {
  const _HeroHeader({
    required this.initials,
    required this.fullName,
    required this.email,
    required this.memberRank,
    required this.points,
    required this.rankColor,
    required this.rankIcon,
    required this.loading,
    required this.onEditTap,
    required this.editMode,
  });

  final String initials;
  final String fullName;
  final String email;
  final String memberRank;
  final int points;
  final Color rankColor;
  final IconData rankIcon;
  final bool loading;
  final VoidCallback onEditTap;
  final bool editMode;

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: const BoxDecoration(
        gradient: LinearGradient(
          colors: [_kDarkBg, Color(0xFF1A2744), Color(0xFF0F1E3A)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
      ),
      child: SafeArea(
        bottom: false,
        child: Padding(
          padding: const EdgeInsets.fromLTRB(20, 16, 20, 28),
          child: Column(
            children: [
              // Top row: title + edit button
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  const Text(
                    'Hồ sơ',
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 22,
                      fontWeight: FontWeight.w900,
                      letterSpacing: 0.3,
                    ),
                  ),
                  GestureDetector(
                    onTap: onEditTap,
                    child: AnimatedContainer(
                      duration: const Duration(milliseconds: 200),
                      padding: const EdgeInsets.symmetric(
                        horizontal: 14,
                        vertical: 8,
                      ),
                      decoration: BoxDecoration(
                        color: editMode
                            ? _kCinemaGold.withValues(alpha: .25)
                            : Colors.white.withValues(alpha: .1),
                        borderRadius: BorderRadius.circular(20),
                        border: Border.all(
                          color: editMode ? _kCinemaGold : Colors.white24,
                        ),
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(
                            editMode ? Icons.close_rounded : Icons.edit_rounded,
                            size: 15,
                            color: editMode ? _kCinemaGold : Colors.white70,
                          ),
                          const SizedBox(width: 6),
                          Text(
                            editMode ? 'Hủy' : 'Chỉnh sửa',
                            style: TextStyle(
                              fontSize: 13,
                              fontWeight: FontWeight.w700,
                              color: editMode ? _kCinemaGold : Colors.white70,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ],
              ),

              const SizedBox(height: 24),

              // Avatar + info
              if (loading)
                const Padding(
                  padding: EdgeInsets.symmetric(vertical: 20),
                  child: CircularProgressIndicator(color: _kCinemaGold),
                )
              else
                Row(
                  children: [
                    // Avatar
                    Stack(
                      children: [
                        Container(
                          width: 76,
                          height: 76,
                          decoration: BoxDecoration(
                            shape: BoxShape.circle,
                            gradient: const LinearGradient(
                              colors: [_kCinemaGold, Color(0xFFE8B84B)],
                              begin: Alignment.topLeft,
                              end: Alignment.bottomRight,
                            ),
                            boxShadow: [
                              BoxShadow(
                                color: _kCinemaGold.withValues(alpha: .45),
                                blurRadius: 20,
                                offset: const Offset(0, 8),
                              ),
                            ],
                          ),
                          alignment: Alignment.center,
                          child: Text(
                            initials,
                            style: const TextStyle(
                              fontSize: 30,
                              fontWeight: FontWeight.w900,
                              color: Colors.white,
                            ),
                          ),
                        ),
                        // Rank icon badge
                        Positioned(
                          bottom: 0,
                          right: 0,
                          child: Container(
                            padding: const EdgeInsets.all(4),
                            decoration: BoxDecoration(
                              color: _kDarkBg,
                              shape: BoxShape.circle,
                              border: Border.all(color: _kDarkBg, width: 2),
                            ),
                            child: Icon(rankIcon, size: 14, color: rankColor),
                          ),
                        ),
                      ],
                    ),

                    const SizedBox(width: 16),

                    // Name + email + rank
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            fullName,
                            style: const TextStyle(
                              color: Colors.white,
                              fontSize: 20,
                              fontWeight: FontWeight.w900,
                            ),
                          ),
                          const SizedBox(height: 3),
                          Text(
                            email,
                            style: const TextStyle(
                              color: Colors.white54,
                              fontSize: 13,
                            ),
                          ),
                          const SizedBox(height: 8),
                          // Rank badge
                          Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 10,
                              vertical: 4,
                            ),
                            decoration: BoxDecoration(
                              color: rankColor.withValues(alpha: .18),
                              borderRadius: BorderRadius.circular(20),
                              border: Border.all(
                                color: rankColor.withValues(alpha: .55),
                              ),
                            ),
                            child: Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                Icon(rankIcon, size: 13, color: rankColor),
                                const SizedBox(width: 5),
                                Text(
                                  memberRank,
                                  style: TextStyle(
                                    color: rankColor,
                                    fontSize: 12,
                                    fontWeight: FontWeight.w800,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),

              const SizedBox(height: 20),

              // ── Points card ──────────────────────────────────────────
              Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 20,
                  vertical: 14,
                ),
                decoration: BoxDecoration(
                  color: Colors.white.withValues(alpha: .07),
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: Colors.white12),
                ),
                child: Row(
                  children: [
                    const Icon(
                      Icons.local_fire_department_rounded,
                      color: _kCinemaGold,
                      size: 22,
                    ),
                    const SizedBox(width: 10),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Text(
                            'Điểm tích lũy',
                            style: TextStyle(
                              color: Colors.white54,
                              fontSize: 12,
                            ),
                          ),
                          Text(
                            '$points điểm',
                            style: const TextStyle(
                              color: Colors.white,
                              fontSize: 18,
                              fontWeight: FontWeight.w900,
                            ),
                          ),
                        ],
                      ),
                    ),
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 12,
                        vertical: 6,
                      ),
                      decoration: BoxDecoration(
                        gradient: const LinearGradient(
                          colors: [_kCinemaGold, Color(0xFFE8A020)],
                        ),
                        borderRadius: BorderRadius.circular(20),
                      ),
                      child: const Text(
                        'Đổi điểm',
                        style: TextStyle(
                          color: Colors.white,
                          fontSize: 12,
                          fontWeight: FontWeight.w800,
                        ),
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
}

// ─────────────────────────────────────────────────────────────────────────────
// PROFILE EDIT FORM
// ─────────────────────────────────────────────────────────────────────────────

class _ProfileForm extends StatelessWidget {
  const _ProfileForm({
    required this.nameCtrl,
    required this.phoneCtrl,
    required this.emailCtrl,
    required this.birthdate,
    required this.phoneError,
    required this.birthdateError,
    required this.saving,
    required this.onPhoneChanged,
    required this.onEmailChanged,
    required this.onPickBirthdate,
    required this.onSave,
    required this.onCancel,
  });

  final TextEditingController nameCtrl;
  final TextEditingController phoneCtrl;
  final TextEditingController emailCtrl;
  final DateTime? birthdate;
  final String? phoneError;
  final String? birthdateError;
  final bool saving;
  final ValueChanged<String> onPhoneChanged;
  final ValueChanged<String> onEmailChanged;
  final VoidCallback onPickBirthdate;
  final VoidCallback onSave;
  final VoidCallback onCancel;

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: _kDarkCard,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Colors.white12),
      ),
      padding: const EdgeInsets.all(18),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Row(
            children: [
              Icon(Icons.person_outline_rounded, color: _kCinemaGold, size: 18),
              SizedBox(width: 8),
              Text(
                'Cập nhật thông tin',
                style: TextStyle(
                  color: Colors.white,
                  fontWeight: FontWeight.w800,
                  fontSize: 15,
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),

          // Full name
          _DarkTextField(
            controller: nameCtrl,
            label: 'Họ và tên',
            icon: Icons.badge_outlined,
          ),
          const SizedBox(height: 12),

          // Phone
          _DarkTextField(
            controller: phoneCtrl,
            label: 'Số điện thoại',
            icon: Icons.phone_outlined,
            keyboardType: TextInputType.phone,
            errorText: phoneError,
            onChanged: onPhoneChanged,
          ),
          const SizedBox(height: 12),

          // Email
          _DarkTextField(
            controller: emailCtrl,
            label: 'Email',
            icon: Icons.email_outlined,
            keyboardType: TextInputType.emailAddress,
            onChanged: onEmailChanged,
          ),
          const SizedBox(height: 12),

          // Birthdate picker
          GestureDetector(
            onTap: onPickBirthdate,
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 14),
              decoration: BoxDecoration(
                color: _kDarkSurface,
                borderRadius: BorderRadius.circular(10),
                border: Border.all(
                  color: birthdateError != null ? _kCinemaRed : Colors.white12,
                ),
              ),
              child: Row(
                children: [
                  const Icon(
                    Icons.cake_outlined,
                    color: Colors.white38,
                    size: 20,
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Text(
                      birthdate != null
                          ? shortDate(birthdate!)
                          : 'Chưa chọn ngày sinh',
                      style: TextStyle(
                        color: birthdate != null
                            ? Colors.white
                            : Colors.white38,
                        fontSize: 15,
                      ),
                    ),
                  ),
                  const Icon(
                    Icons.calendar_today_outlined,
                    color: Colors.white38,
                    size: 18,
                  ),
                ],
              ),
            ),
          ),
          if (birthdateError != null) ...[
            const SizedBox(height: 4),
            Text(
              birthdateError!,
              style: const TextStyle(color: _kCinemaRed, fontSize: 12),
            ),
          ],

          const SizedBox(height: 18),

          // Action buttons
          Row(
            children: [
              Expanded(
                child: OutlinedButton(
                  onPressed: onCancel,
                  style: OutlinedButton.styleFrom(
                    foregroundColor: Colors.white70,
                    side: const BorderSide(color: Colors.white24),
                    padding: const EdgeInsets.symmetric(vertical: 13),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(10),
                    ),
                  ),
                  child: const Text(
                    'Hủy',
                    style: TextStyle(fontWeight: FontWeight.w700),
                  ),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                flex: 2,
                child: ElevatedButton.icon(
                  onPressed: saving ? null : onSave,
                  icon: saving
                      ? const SizedBox(
                          width: 16,
                          height: 16,
                          child: CircularProgressIndicator(
                            strokeWidth: 2,
                            color: Colors.white,
                          ),
                        )
                      : const Icon(Icons.save_outlined, size: 18),
                  label: Text(saving ? 'Đang lưu...' : 'Lưu hồ sơ'),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: _kCinemaGold,
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(vertical: 13),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(10),
                    ),
                    textStyle: const TextStyle(fontWeight: FontWeight.w800),
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// DARK TEXT FIELD
// ─────────────────────────────────────────────────────────────────────────────

class _DarkTextField extends StatelessWidget {
  const _DarkTextField({
    required this.controller,
    required this.label,
    required this.icon,
    this.keyboardType,
    this.errorText,
    this.onChanged,
  });

  final TextEditingController controller;
  final String label;
  final IconData icon;
  final TextInputType? keyboardType;
  final String? errorText;
  final ValueChanged<String>? onChanged;

  @override
  Widget build(BuildContext context) {
    return TextField(
      controller: controller,
      keyboardType: keyboardType,
      onChanged: onChanged,
      style: const TextStyle(color: Colors.white),
      decoration: InputDecoration(
        labelText: label,
        labelStyle: const TextStyle(color: Colors.white54),
        prefixIcon: Icon(icon, color: Colors.white38, size: 20),
        errorText: errorText,
        errorStyle: const TextStyle(color: _kCinemaRed),
        filled: true,
        fillColor: _kDarkSurface,
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(10),
          borderSide: const BorderSide(color: Colors.white12),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(10),
          borderSide: const BorderSide(color: Colors.white12),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(10),
          borderSide: const BorderSide(color: _kCinemaGold, width: 1.5),
        ),
        errorBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(10),
          borderSide: const BorderSide(color: _kCinemaRed),
        ),
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// QUICK ACTION TILE
// ─────────────────────────────────────────────────────────────────────────────

class _QuickTile extends StatelessWidget {
  const _QuickTile({
    required this.icon,
    required this.label,
    required this.subtitle,
    required this.gradient,
    required this.onTap,
  });

  final IconData icon;
  final String label;
  final String subtitle;
  final Gradient gradient;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          gradient: gradient,
          borderRadius: BorderRadius.circular(14),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: .25),
              blurRadius: 12,
              offset: const Offset(0, 6),
            ),
          ],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: Colors.white.withValues(alpha: .15),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Icon(icon, color: Colors.white, size: 22),
            ),
            const SizedBox(height: 12),
            Text(
              label,
              style: const TextStyle(
                color: Colors.white,
                fontWeight: FontWeight.w800,
                fontSize: 14,
              ),
            ),
            const SizedBox(height: 2),
            Text(
              subtitle,
              style: const TextStyle(color: Colors.white60, fontSize: 11),
            ),
          ],
        ),
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// BOOKING TILE
// ─────────────────────────────────────────────────────────────────────────────

class BookingTile extends StatelessWidget {
  const BookingTile({super.key, required this.booking});

  final Booking booking;

  Color _statusColor(BookingStatus status) {
    switch (status) {
      case BookingStatus.active:
        return const Color(0xFF1B8A5A);
      case BookingStatus.cancelled:
        return _kCinemaRed;
      case BookingStatus.refunded:
        return const Color(0xFFF59E0B);
      case BookingStatus.used:
        return AppColors.muted;
    }
  }

  @override
  Widget build(BuildContext context) {
    final statusColor = _statusColor(booking.status);
    return Container(
      margin: const EdgeInsets.only(bottom: 10),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AppColors.line),
        boxShadow: softShadow(.04),
      ),
      child: Row(
        children: [
          // Left accent stripe
          Container(
            width: 4,
            height: 72,
            decoration: BoxDecoration(
              color: statusColor,
              borderRadius: const BorderRadius.only(
                topLeft: Radius.circular(12),
                bottomLeft: Radius.circular(12),
              ),
            ),
          ),
          const SizedBox(width: 14),
          // Icon
          Container(
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(
              color: statusColor.withValues(alpha: .1),
              borderRadius: BorderRadius.circular(10),
            ),
            child: Icon(
              Icons.confirmation_number_rounded,
              color: statusColor,
              size: 22,
            ),
          ),
          const SizedBox(width: 12),
          // Info
          Expanded(
            child: Padding(
              padding: const EdgeInsets.symmetric(vertical: 12),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    booking.movieTitle,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(
                      fontWeight: FontWeight.w800,
                      fontSize: 14,
                    ),
                  ),
                  const SizedBox(height: 3),
                  Text(
                    fullDateTime(booking.createdAt),
                    style: const TextStyle(
                      color: AppColors.muted,
                      fontSize: 12,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 8,
                      vertical: 2,
                    ),
                    decoration: BoxDecoration(
                      color: statusColor.withValues(alpha: .12),
                      borderRadius: BorderRadius.circular(20),
                    ),
                    child: Text(
                      bookingStatusLabel(booking.status),
                      style: TextStyle(
                        color: statusColor,
                        fontSize: 11,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
          // Amount
          Padding(
            padding: const EdgeInsets.only(right: 14),
            child: Text(
              money(booking.totalAmount),
              style: const TextStyle(
                fontWeight: FontWeight.w900,
                fontSize: 13,
                color: _kDarkBg,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// EMPTY HISTORY
// ─────────────────────────────────────────────────────────────────────────────

class EmptyHistory extends StatelessWidget {
  const EmptyHistory({super.key});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 32),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AppColors.line),
      ),
      child: Column(
        children: [
          Icon(
            Icons.movie_creation_outlined,
            size: 52,
            color: AppColors.muted.withValues(alpha: .5),
          ),
          const SizedBox(height: 12),
          const Text(
            'Chưa có vé nào',
            style: TextStyle(
              fontWeight: FontWeight.w700,
              color: AppColors.muted,
              fontSize: 15,
            ),
          ),
          const SizedBox(height: 4),
          const Text(
            'Đặt vé ngay để xem phim yêu thích!',
            style: TextStyle(color: AppColors.muted, fontSize: 13),
          ),
        ],
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// SECTION LABEL
// ─────────────────────────────────────────────────────────────────────────────

class _SectionLabel extends StatelessWidget {
  const _SectionLabel({required this.label});
  final String label;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Container(
          width: 3,
          height: 16,
          decoration: BoxDecoration(
            color: _kCinemaGold,
            borderRadius: BorderRadius.circular(2),
          ),
        ),
        const SizedBox(width: 8),
        Text(
          label,
          style: const TextStyle(
            fontSize: 15,
            fontWeight: FontWeight.w900,
            color: _kDarkBg,
            letterSpacing: 0.2,
          ),
        ),
      ],
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// INFO BANNER
// ─────────────────────────────────────────────────────────────────────────────

class _InfoBanner extends StatelessWidget {
  const _InfoBanner({
    required this.icon,
    required this.message,
    required this.color,
  });

  final IconData icon;
  final String message;
  final Color color;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
      decoration: BoxDecoration(
        color: color.withValues(alpha: .1),
        border: Border.all(color: color.withValues(alpha: .4)),
        borderRadius: BorderRadius.circular(10),
      ),
      child: Row(
        children: [
          Icon(icon, color: color, size: 20),
          const SizedBox(width: 10),
          Expanded(
            child: Text(message, style: TextStyle(color: color, fontSize: 13)),
          ),
        ],
      ),
    );
  }
}
