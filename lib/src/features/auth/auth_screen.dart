import 'package:flutter/material.dart';

import '../../../services/analytics_service.dart';
import '../../core/app_theme.dart';
import '../../models/app_models.dart';
import '../../shared/widgets/glass_card.dart';
import '../../state/cinema_store.dart';

class AuthScreen extends StatefulWidget {
  const AuthScreen({super.key, required this.store});

  final CinemaStore store;

  @override
  State<AuthScreen> createState() => _AuthScreenState();
}

class _AuthScreenState extends State<AuthScreen> {
  final _email = TextEditingController(text: 'user@cineluxe.vn');
  final _password = TextEditingController(text: '123456');
  final _name = TextEditingController(text: 'Khách hàng mới');
  final _phone = TextEditingController(text: '0912345678');
  bool _registerMode = false;
  String _message =
      'Đăng nhập để đặt vé, nhận mã QR và quản lý lịch sử giao dịch.';

  @override
  void dispose() {
    _email.dispose();
    _password.dispose();
    _name.dispose();
    _phone.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.ivory,
      body: SafeArea(
        child: LayoutBuilder(
          builder: (context, constraints) {
            final wide = constraints.maxWidth >= 820;
            return Center(
              child: SingleChildScrollView(
                padding: EdgeInsets.fromLTRB(18, wide ? 28 : 12, 18, 24),
                child: ConstrainedBox(
                  constraints: const BoxConstraints(maxWidth: 980),
                  child: wide
                      ? Row(
                          crossAxisAlignment: CrossAxisAlignment.center,
                          children: [
                            const Expanded(child: _BrandPreview()),
                            const SizedBox(width: 28),
                            Expanded(child: _buildPanel()),
                          ],
                        )
                      : Column(
                          crossAxisAlignment: CrossAxisAlignment.stretch,
                          children: [
                            const _BrandHeader(),
                            const SizedBox(height: 16),
                            _buildPanel(),
                          ],
                        ),
                ),
              ),
            );
          },
        ),
      ),
    );
  }

  Widget _buildPanel() {
    return _AuthPanel(
      registerMode: _registerMode,
      message: _message,
      name: _name,
      phone: _phone,
      email: _email,
      password: _password,
      onSubmit: _submit,
      onToggleMode: _toggleMode,
      onForgotPassword: _forgotPassword,
      store: widget.store,
    );
  }

  void _toggleMode() {
    setState(() {
      _registerMode = !_registerMode;
      _message = _registerMode
          ? 'Tạo tài khoản mới và xác thực OTP qua email hoặc SMS.'
          : 'Đăng nhập để đặt vé, nhận mã QR và quản lý lịch sử giao dịch.';
    });
  }

  void _forgotPassword() {
    setState(() {
      _message =
          'Liên kết khôi phục đã gửi tới email/SMS. Mã OTP demo: 246810.';
    });
  }

  void _submit() {
    if (_registerMode) {
      widget.store.register(
        fullName: _name.text.trim(),
        email: _email.text.trim(),
        phone: _phone.text.trim(),
        password: _password.text,
      );
      // Track login after register (Req 41.1, 41.3)
      final user = widget.store.currentUser;
      if (user != null) {
        AnalyticsService.instance.trackLogin(userId: user.id, method: 'email');
      }
      return;
    }
    final ok = widget.store.login(_email.text, _password.text);
    if (!ok) {
      setState(() {
        _message = 'Thông tin đăng nhập không đúng hoặc tài khoản đã bị khóa.';
      });
    } else {
      // Track login event (Req 41.1, 41.3)
      final user = widget.store.currentUser;
      if (user != null) {
        AnalyticsService.instance.trackLogin(userId: user.id, method: 'email');
      }
    }
  }
}

class _BrandHeader extends StatelessWidget {
  const _BrandHeader();

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: AppColors.line),
        boxShadow: softShadow(.06),
      ),
      child: Row(
        children: [
          Container(
            width: 54,
            height: 54,
            decoration: BoxDecoration(
              color: AppColors.ink,
              borderRadius: BorderRadius.circular(8),
            ),
            child: const Icon(
              Icons.movie_creation_rounded,
              color: Colors.white,
            ),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'CineLuxe',
                  style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                    fontWeight: FontWeight.w900,
                    letterSpacing: 0,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  'Đặt vé nhanh, thanh toán VNPay, nhận vé QR ngay trong app.',
                  style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                    color: AppColors.muted,
                    height: 1.35,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _BrandPreview extends StatelessWidget {
  const _BrandPreview();

  @override
  Widget build(BuildContext context) {
    return Container(
      constraints: const BoxConstraints(minHeight: 560),
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(8),
        gradient: const LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [Colors.white, AppColors.pearl, AppColors.goldSoft],
        ),
        border: Border.all(color: AppColors.line),
        boxShadow: softShadow(.08),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: 66,
            height: 66,
            decoration: BoxDecoration(
              color: AppColors.ink,
              borderRadius: BorderRadius.circular(8),
            ),
            child: const Icon(
              Icons.local_movies_rounded,
              color: Colors.white,
              size: 34,
            ),
          ),
          const SizedBox(height: 22),
          Text(
            'CineLuxe',
            style: Theme.of(context).textTheme.displaySmall?.copyWith(
              fontWeight: FontWeight.w900,
              letterSpacing: 0,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            'Trải nghiệm đặt vé xem phim hiện đại cho khách hàng, nhân viên và quản trị viên.',
            style: Theme.of(
              context,
            ).textTheme.titleMedium?.copyWith(height: 1.45),
          ),
          const SizedBox(height: 24),
          const _FeatureRow(
            icon: Icons.event_seat_rounded,
            title: 'Chọn ghế trực quan',
            subtitle: 'Giữ ghế 10 phút, tối đa 8 ghế/lần đặt.',
          ),
          const _FeatureRow(
            icon: Icons.payments_outlined,
            title: 'Thanh toán VNPay',
            subtitle: 'Mô phỏng giao dịch, responseCode và hoàn tiền.',
          ),
          const _FeatureRow(
            icon: Icons.qr_code_2_rounded,
            title: 'Vé điện tử QR',
            subtitle: 'Nhân viên có thể quét hoặc tra cứu thủ công.',
          ),
          const Spacer(),
          GlassCard(
            padding: const EdgeInsets.all(14),
            child: Row(
              children: [
                const CircleAvatar(
                  backgroundColor: AppColors.goldSoft,
                  child: Icon(
                    Icons.auto_awesome_rounded,
                    color: AppColors.gold,
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Text(
                    'Giao diện trắng, gọn và dễ dùng trên điện thoại thông minh.',
                    style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _AuthPanel extends StatelessWidget {
  const _AuthPanel({
    required this.registerMode,
    required this.message,
    required this.name,
    required this.phone,
    required this.email,
    required this.password,
    required this.onSubmit,
    required this.onToggleMode,
    required this.onForgotPassword,
    required this.store,
  });

  final bool registerMode;
  final String message;
  final TextEditingController name;
  final TextEditingController phone;
  final TextEditingController email;
  final TextEditingController password;
  final VoidCallback onSubmit;
  final VoidCallback onToggleMode;
  final VoidCallback onForgotPassword;
  final CinemaStore store;

  @override
  Widget build(BuildContext context) {
    return GlassCard(
      padding: const EdgeInsets.all(18),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          _ModeSwitch(registerMode: registerMode, onChanged: onToggleMode),
          const SizedBox(height: 18),
          Text(
            registerMode ? 'Tạo tài khoản' : 'Đăng nhập',
            style: Theme.of(context).textTheme.headlineSmall?.copyWith(
              fontWeight: FontWeight.w900,
              letterSpacing: 0,
            ),
          ),
          const SizedBox(height: 6),
          Text(
            message,
            style: Theme.of(context).textTheme.bodyMedium?.copyWith(
              color: AppColors.muted,
              height: 1.4,
            ),
          ),
          const SizedBox(height: 18),
          if (registerMode) ...[
            TextField(
              controller: name,
              textInputAction: TextInputAction.next,
              decoration: const InputDecoration(
                labelText: 'Họ và tên',
                prefixIcon: Icon(Icons.badge_outlined),
              ),
            ),
            const SizedBox(height: 12),
            TextField(
              controller: phone,
              keyboardType: TextInputType.phone,
              textInputAction: TextInputAction.next,
              decoration: const InputDecoration(
                labelText: 'Số điện thoại',
                prefixIcon: Icon(Icons.phone_rounded),
              ),
            ),
            const SizedBox(height: 12),
          ],
          TextField(
            controller: email,
            keyboardType: TextInputType.emailAddress,
            textInputAction: TextInputAction.next,
            decoration: const InputDecoration(
              labelText: 'Email',
              prefixIcon: Icon(Icons.mail_outline_rounded),
            ),
          ),
          const SizedBox(height: 12),
          TextField(
            controller: password,
            obscureText: true,
            decoration: const InputDecoration(
              labelText: 'Mật khẩu',
              prefixIcon: Icon(Icons.lock_outline_rounded),
            ),
          ),
          Align(
            alignment: Alignment.centerRight,
            child: TextButton(
              onPressed: onForgotPassword,
              child: const Text('Quên mật khẩu?'),
            ),
          ),
          SizedBox(
            height: 52,
            child: FilledButton.icon(
              onPressed: onSubmit,
              icon: Icon(
                registerMode
                    ? Icons.verified_user_outlined
                    : Icons.login_rounded,
              ),
              label: Text(registerMode ? 'Xác thực OTP' : 'Vào hệ thống'),
              style: FilledButton.styleFrom(
                backgroundColor: AppColors.ink,
                foregroundColor: Colors.white,
                textStyle: const TextStyle(fontWeight: FontWeight.w900),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(8),
                ),
              ),
            ),
          ),
          const SizedBox(height: 16),
          const _DividerLabel('Hoặc đăng nhập bằng'),
          const SizedBox(height: 12),
          Center(
            child: _GoogleSignInButton(
              onPressed: () => store.demoLogin(UserRole.customer),
            ),
          ),
          const SizedBox(height: 16),
          _QuickAccess(store: store),
        ],
      ),
    );
  }
}

class _GoogleSignInButton extends StatelessWidget {
  const _GoogleSignInButton({required this.onPressed});

  final VoidCallback onPressed;

  @override
  Widget build(BuildContext context) {
    return ConstrainedBox(
      constraints: const BoxConstraints(maxWidth: 260),
      child: SizedBox(
        height: 42,
        width: double.infinity,
        child: InkWell(
          onTap: onPressed,
          borderRadius: BorderRadius.circular(999),
          child: DecoratedBox(
            decoration: BoxDecoration(
              color: const Color(0xFFF1F2F4),
              borderRadius: BorderRadius.circular(999),
              border: Border.all(color: const Color(0xFFE3E5E8)),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withValues(alpha: .05),
                  blurRadius: 10,
                  offset: const Offset(0, 4),
                ),
              ],
            ),
            child: const Padding(
              padding: EdgeInsets.symmetric(horizontal: 14),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  _GoogleMark(),
                  SizedBox(width: 12),
                  Flexible(
                    child: FittedBox(
                      fit: BoxFit.scaleDown,
                      child: Text(
                        'Sign in with Google',
                        maxLines: 1,
                        style: TextStyle(
                          color: AppColors.ink,
                          fontWeight: FontWeight.w900,
                          fontSize: 14,
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class _GoogleMark extends StatelessWidget {
  const _GoogleMark();

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: 22,
      height: 22,
      child: CustomPaint(painter: _GoogleMarkPainter()),
    );
  }
}

class _GoogleMarkPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final stroke = Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = 3.2
      ..strokeCap = StrokeCap.round;
    final rect = Offset.zero & size;
    stroke.color = const Color(0xFF4285F4);
    canvas.drawArc(rect.deflate(3), -.12, 1.45, false, stroke);
    stroke.color = const Color(0xFF34A853);
    canvas.drawArc(rect.deflate(3), 1.33, 1.3, false, stroke);
    stroke.color = const Color(0xFFFBBC05);
    canvas.drawArc(rect.deflate(3), 2.63, 1.25, false, stroke);
    stroke.color = const Color(0xFFEA4335);
    canvas.drawArc(rect.deflate(3), 3.88, 1.15, false, stroke);
    final bar = Paint()
      ..color = const Color(0xFF4285F4)
      ..strokeWidth = 3
      ..strokeCap = StrokeCap.round;
    canvas.drawLine(
      Offset(size.width * .52, size.height * .5),
      Offset(size.width * .86, size.height * .5),
      bar,
    );
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}

class _ModeSwitch extends StatelessWidget {
  const _ModeSwitch({required this.registerMode, required this.onChanged});

  final bool registerMode;
  final VoidCallback onChanged;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(4),
      decoration: BoxDecoration(
        color: AppColors.pearl,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: AppColors.line),
      ),
      child: Row(
        children: [
          _ModeButton(
            label: 'Đăng nhập',
            selected: !registerMode,
            onTap: registerMode ? onChanged : null,
          ),
          _ModeButton(
            label: 'Đăng ký',
            selected: registerMode,
            onTap: registerMode ? null : onChanged,
          ),
        ],
      ),
    );
  }
}

class _ModeButton extends StatelessWidget {
  const _ModeButton({required this.label, required this.selected, this.onTap});

  final String label;
  final bool selected;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    return Expanded(
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(7),
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 180),
          padding: const EdgeInsets.symmetric(vertical: 11),
          decoration: BoxDecoration(
            color: selected ? Colors.white : Colors.transparent,
            borderRadius: BorderRadius.circular(7),
            boxShadow: selected ? softShadow(.05) : null,
          ),
          child: Text(
            label,
            textAlign: TextAlign.center,
            style: TextStyle(
              fontWeight: FontWeight.w900,
              color: selected ? AppColors.ink : AppColors.muted,
            ),
          ),
        ),
      ),
    );
  }
}

class _QuickAccess extends StatelessWidget {
  const _QuickAccess({required this.store});

  final CinemaStore store;

  @override
  Widget build(BuildContext context) {
    return DecoratedBox(
      decoration: BoxDecoration(
        color: AppColors.goldSoft.withValues(alpha: .45),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: AppColors.gold.withValues(alpha: .28)),
      ),
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Truy cập nhanh',
              style: Theme.of(
                context,
              ).textTheme.titleSmall?.copyWith(fontWeight: FontWeight.w900),
            ),
            const SizedBox(height: 10),
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: [
                _RoleChip(
                  label: 'Khách hàng',
                  icon: Icons.person_rounded,
                  onTap: () => store.demoLogin(UserRole.customer),
                ),
                _RoleChip(
                  label: 'Nhân viên',
                  icon: Icons.qr_code_scanner_rounded,
                  onTap: () => store.demoLogin(UserRole.staff),
                ),
                _RoleChip(
                  label: 'Quản trị',
                  icon: Icons.admin_panel_settings_rounded,
                  onTap: () => store.demoLogin(UserRole.admin),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

class _RoleChip extends StatelessWidget {
  const _RoleChip({
    required this.label,
    required this.icon,
    required this.onTap,
  });

  final String label;
  final IconData icon;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return ActionChip(
      onPressed: onTap,
      avatar: Icon(icon, size: 18),
      label: Text(label),
      backgroundColor: Colors.white,
      side: const BorderSide(color: AppColors.line),
      labelStyle: const TextStyle(fontWeight: FontWeight.w800),
    );
  }
}

class _DividerLabel extends StatelessWidget {
  const _DividerLabel(this.label);

  final String label;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        const Expanded(child: Divider(color: AppColors.line)),
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 10),
          child: Text(
            label,
            style: Theme.of(context).textTheme.labelMedium?.copyWith(
              color: AppColors.muted,
              fontWeight: FontWeight.w700,
            ),
          ),
        ),
        const Expanded(child: Divider(color: AppColors.line)),
      ],
    );
  }
}

class _FeatureRow extends StatelessWidget {
  const _FeatureRow({
    required this.icon,
    required this.title,
    required this.subtitle,
  });

  final IconData icon;
  final String title;
  final String subtitle;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 18),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: 40,
            height: 40,
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(8),
              border: Border.all(color: AppColors.line),
            ),
            child: Icon(icon, color: AppColors.gold),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: const TextStyle(fontWeight: FontWeight.w900),
                ),
                const SizedBox(height: 3),
                Text(
                  subtitle,
                  style: Theme.of(context).textTheme.bodySmall?.copyWith(
                    color: AppColors.muted,
                    height: 1.35,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
