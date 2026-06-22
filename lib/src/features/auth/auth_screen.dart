import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:go_router/go_router.dart';

import '../../../services/analytics_service.dart';
import '../../../services/auth_service.dart';
import '../../state/cinema_store.dart';

// ============================================================
//  AuthScreen – root widget, picks which page to show
// ============================================================
class AuthScreen extends StatefulWidget {
  const AuthScreen({
    super.key,
    required this.store,
    this.startInRegister = false,
  });

  final CinemaStore store;
  final bool startInRegister;

  @override
  State<AuthScreen> createState() => _AuthScreenState();
}

enum _AuthPage { login, register, forgotStep1, forgotStep2 }

class _AuthScreenState extends State<AuthScreen>
    with SingleTickerProviderStateMixin {
  final _authService = AuthService();

  // Controllers shared across pages
  final _email = TextEditingController();
  final _password = TextEditingController();
  final _name = TextEditingController();
  final _phone = TextEditingController();
  final _newPassword = TextEditingController();
  final _confirmPassword = TextEditingController();
  final _otpCode = TextEditingController();

  _AuthPage _page = _AuthPage.login;
  bool _submitting = false;
  String? _errorMsg;
  String? _successMsg;
  bool _obscurePassword = true;
  bool _obscureNewPassword = true;
  bool _obscureConfirmPassword = true;

  late AnimationController _fadeCtrl;
  late Animation<double> _fadeAnim;

  @override
  void initState() {
    super.initState();
    _page = widget.startInRegister ? _AuthPage.register : _AuthPage.login;
    _fadeCtrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 340),
    );
    _fadeAnim = CurvedAnimation(parent: _fadeCtrl, curve: Curves.easeOut);
    _fadeCtrl.forward();
  }

  @override
  void dispose() {
    _fadeCtrl.dispose();
    _email.dispose();
    _password.dispose();
    _name.dispose();
    _phone.dispose();
    _newPassword.dispose();
    _confirmPassword.dispose();
    _otpCode.dispose();
    super.dispose();
  }

  void _goto(_AuthPage page) {
    setState(() {
      _page = page;
      _errorMsg = null;
      _successMsg = null;
    });
    _fadeCtrl
      ..reset()
      ..forward();
  }

  void _setError(String msg) => setState(() {
    _errorMsg = msg;
    _successMsg = null;
  });

  void _setSuccess(String msg) => setState(() {
    _successMsg = msg;
    _errorMsg = null;
  });

  void _clearMessages() => setState(() {
    _errorMsg = null;
    _successMsg = null;
  });

  // ── Login ──────────────────────────────────────────────────
  // Gọi API: POST /api/auth/login  (xem auth_service.dart)
  Future<void> _doLogin() async {
    final email = _email.text.trim();
    final password = _password.text;
    setState(() => _submitting = true);
    _clearMessages();

    final result = await _authService.signInWithEmail(email, password);

    if (!mounted) return;
    setState(() => _submitting = false);

    if (!result.isSuccess || result.user == null) {
      _setError(
        result.errorMessage ??
            'Thông tin đăng nhập không đúng. Vui lòng thử lại.',
      );
      return;
    }
    widget.store.setCurrentUserFromProfile(result.user!);
    AnalyticsService.instance.trackLogin(
      userId: result.user!.id,
      method: 'email',
    );
    if (mounted) context.go('/');
  }

  // ── Google Sign-In ────────────────────────────────────────
  // Gọi API: POST /api/auth/google  (xem auth_service.dart)
  Future<void> _doGoogleSignIn() async {
    if (_submitting) return;
    setState(() {
      _submitting = true;
      _errorMsg = null;
    });
    final result = await _authService.signInWithGoogle();
    if (!mounted) return;
    setState(() => _submitting = false);

    if (!result.isSuccess || result.user == null) {
      _setError(
        result.errorMessage ?? 'Đăng nhập Google thất bại. Thử lại sau.',
      );
      return;
    }
    widget.store.setCurrentUserFromProfile(result.user!);
    AnalyticsService.instance.trackLogin(
      userId: result.user!.id,
      method: 'google',
    );
    if (mounted) context.go('/');
  }

  // ── Register ──────────────────────────────────────────────
  // Gọi API: POST /api/auth/register  (xem auth_service.dart)
  Future<void> _doRegister() async {
    final email = _email.text.trim();
    final password = _password.text;
    final fullName = _name.text.trim();
    final phone = _phone.text.trim();

    setState(() => _submitting = true);
    _clearMessages();

    final result = await _authService.register(
      email,
      password,
      fullName,
      phone,
    );

    if (!mounted) return;
    setState(() => _submitting = false);

    if (!result.isSuccess || result.user == null) {
      _setError(result.errorMessage ?? 'Đăng ký thất bại. Vui lòng thử lại.');
      return;
    }
    _password.clear();
    _name.clear();
    _phone.clear();
    setState(() {
      _page = _AuthPage.login;
      _successMsg = 'Đăng ký thành công. Vui lòng đăng nhập.';
      _errorMsg = null;
    });
    _fadeCtrl
      ..reset()
      ..forward();
  }

  // ── Forgot Step 1 – Gửi mã OTP qua email ─────────────────
  // Gọi API: POST /api/auth/forgot-password  (xem auth_service.dart)
  Future<void> _doSendOtp() async {
    final email = _email.text.trim();
    setState(() => _submitting = true);
    _clearMessages();

    final result = await _authService.requestPasswordReset(email);

    if (!mounted) return;
    setState(() => _submitting = false);

    if (result.isSuccess) {
      _setSuccess(result.message);
      Future.delayed(const Duration(milliseconds: 800), () {
        if (mounted) _goto(_AuthPage.forgotStep2);
      });
    } else {
      _setError(result.message);
    }
  }

  // ── Forgot Step 2 – Đặt lại mật khẩu bằng mã OTP ────────
  // Gọi API: POST /api/auth/reset-password  (xem auth_service.dart)
  Future<void> _doResetPassword() async {
    final code = _otpCode.text.trim();
    final newPwd = _newPassword.text;
    final confirmPwd = _confirmPassword.text;
    if (newPwd != confirmPwd) {
      return _setError('Mật khẩu xác nhận không khớp.');
    }
    setState(() => _submitting = true);
    _clearMessages();

    final result = await _authService.resetPassword(
      email: _email.text.trim(),
      code: code,
      newPassword: newPwd,
    );

    if (!mounted) return;
    setState(() => _submitting = false);

    if (result.isSuccess) {
      _setSuccess(result.message);
      _otpCode.clear();
      _newPassword.clear();
      _confirmPassword.clear();
      Future.delayed(const Duration(seconds: 2), () {
        if (mounted) _goto(_AuthPage.login);
      });
    } else {
      _setError(result.message);
    }
  }

  // ── Build ─────────────────────────────────────────────────
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF0F1117),
      body: Stack(
        children: [
          Positioned.fill(child: _buildBackground()),
          SafeArea(
            child: Center(
              child: SingleChildScrollView(
                padding: const EdgeInsets.symmetric(
                  horizontal: 24,
                  vertical: 32,
                ),
                child: FadeTransition(
                  opacity: _fadeAnim,
                  child: ConstrainedBox(
                    constraints: const BoxConstraints(maxWidth: 420),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        _HomeButton(onTap: () => context.go('/')),
                        const SizedBox(height: 14),
                        _buildCurrentPage(),
                      ],
                    ),
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildBackground() {
    return Stack(
      children: [
        Container(
          decoration: const BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: [Color(0xFF0F1117), Color(0xFF1A1F30), Color(0xFF0F1117)],
            ),
          ),
        ),
        Positioned(
          top: -120,
          right: -100,
          child: Container(
            width: 400,
            height: 400,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              gradient: RadialGradient(
                colors: [
                  const Color(0xFFC9A44C).withValues(alpha: 0.15),
                  Colors.transparent,
                ],
              ),
            ),
          ),
        ),
        Positioned(
          bottom: -80,
          left: -80,
          child: Container(
            width: 300,
            height: 300,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              gradient: RadialGradient(
                colors: [
                  const Color(0xFF4F8EF7).withValues(alpha: 0.10),
                  Colors.transparent,
                ],
              ),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildCurrentPage() {
    return switch (_page) {
      _AuthPage.login => _buildLoginPage(),
      _AuthPage.register => _buildRegisterPage(),
      _AuthPage.forgotStep1 => _buildForgotStep1Page(),
      _AuthPage.forgotStep2 => _buildForgotStep2Page(),
    };
  }

  // ============================================================
  //  LOGIN PAGE
  // ============================================================
  Widget _buildLoginPage() {
    return _AuthCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          const _Logo(),
          const SizedBox(height: 28),
          const _Heading(
            title: 'Đăng nhập',
            subtitle: 'Chào mừng trở lại CineLuxe',
          ),
          const SizedBox(height: 24),

          _AuthTextField(
            controller: _email,
            label: 'Email',
            hint: 'example@email.com',
            icon: Icons.mail_outline_rounded,
            keyboardType: TextInputType.emailAddress,
            enabled: !_submitting,
            onSubmitted: (_) => FocusScope.of(context).nextFocus(),
          ),
          const SizedBox(height: 14),

          _AuthTextField(
            controller: _password,
            label: 'Mật khẩu',
            hint: '••••••••',
            icon: Icons.lock_outline_rounded,
            obscureText: _obscurePassword,
            enabled: !_submitting,
            suffixIcon: IconButton(
              icon: Icon(
                _obscurePassword
                    ? Icons.visibility_off_outlined
                    : Icons.visibility_outlined,
                size: 20,
                color: Colors.white38,
              ),
              onPressed: () =>
                  setState(() => _obscurePassword = !_obscurePassword),
            ),
            onSubmitted: (_) => _doLogin(),
          ),

          Align(
            alignment: Alignment.centerRight,
            child: TextButton(
              onPressed: _submitting
                  ? null
                  : () => _goto(_AuthPage.forgotStep1),
              style: TextButton.styleFrom(
                foregroundColor: const Color(0xFFC9A44C),
                padding: const EdgeInsets.symmetric(vertical: 4),
              ),
              child: const Text(
                'Quên mật khẩu?',
                style: TextStyle(fontSize: 13, fontWeight: FontWeight.w600),
              ),
            ),
          ),
          const SizedBox(height: 6),

          _MessageBox(error: _errorMsg, success: _successMsg),

          _PrimaryButton(
            label: 'Đăng nhập',
            icon: Icons.login_rounded,
            loading: _submitting,
            onPressed: _doLogin,
          ),
          const SizedBox(height: 20),

          const _OrDivider(),
          const SizedBox(height: 16),

          _GoogleButton(loading: _submitting, onPressed: _doGoogleSignIn),
          const SizedBox(height: 24),

          _SwitchRow(
            text: 'Chưa có tài khoản?',
            actionText: 'Đăng ký ngay',
            onTap: () => _goto(_AuthPage.register),
          ),
        ],
      ),
    );
  }

  // ============================================================
  //  REGISTER PAGE
  // ============================================================
  Widget _buildRegisterPage() {
    return _AuthCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          const _Logo(),
          const SizedBox(height: 28),
          const _Heading(
            title: 'Tạo tài khoản',
            subtitle: 'Đăng ký để đặt vé nhanh chóng',
          ),
          const SizedBox(height: 24),

          _AuthTextField(
            controller: _name,
            label: 'Họ và tên',
            hint: 'Nguyễn Văn A',
            icon: Icons.badge_outlined,
            enabled: !_submitting,
            onSubmitted: (_) => FocusScope.of(context).nextFocus(),
          ),
          const SizedBox(height: 14),

          _AuthTextField(
            controller: _phone,
            label: 'Số điện thoại',
            hint: '0912345678',
            icon: Icons.phone_outlined,
            keyboardType: TextInputType.phone,
            enabled: !_submitting,
            inputFormatters: [
              FilteringTextInputFormatter.allow(RegExp(r'[0-9+]')),
              LengthLimitingTextInputFormatter(13),
            ],
            onSubmitted: (_) => FocusScope.of(context).nextFocus(),
          ),
          const SizedBox(height: 14),

          _AuthTextField(
            controller: _email,
            label: 'Email',
            hint: 'example@email.com',
            icon: Icons.mail_outline_rounded,
            keyboardType: TextInputType.emailAddress,
            enabled: !_submitting,
            onSubmitted: (_) => FocusScope.of(context).nextFocus(),
          ),
          const SizedBox(height: 14),

          _AuthTextField(
            controller: _password,
            label: 'Mật khẩu',
            hint: '••••••••',
            icon: Icons.lock_outline_rounded,
            obscureText: _obscurePassword,
            enabled: !_submitting,
            suffixIcon: IconButton(
              icon: Icon(
                _obscurePassword
                    ? Icons.visibility_off_outlined
                    : Icons.visibility_outlined,
                size: 20,
                color: Colors.white38,
              ),
              onPressed: () =>
                  setState(() => _obscurePassword = !_obscurePassword),
            ),
            onSubmitted: (_) => _doRegister(),
          ),
          const SizedBox(height: 8),

          const _PasswordStrengthHint(),
          const SizedBox(height: 14),

          _MessageBox(error: _errorMsg, success: _successMsg),

          _PrimaryButton(
            label: 'Tạo tài khoản',
            icon: Icons.verified_user_outlined,
            loading: _submitting,
            onPressed: _doRegister,
          ),
          const SizedBox(height: 24),

          _SwitchRow(
            text: 'Đã có tài khoản?',
            actionText: 'Đăng nhập',
            onTap: () => _goto(_AuthPage.login),
          ),
        ],
      ),
    );
  }

  // ============================================================
  //  FORGOT PASSWORD – STEP 1 (Nhập email, gửi OTP)
  // ============================================================
  Widget _buildForgotStep1Page() {
    return _AuthCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Align(
            alignment: Alignment.centerLeft,
            child: _BackButton(onTap: () => _goto(_AuthPage.login)),
          ),
          const SizedBox(height: 16),

          Center(
            child: Container(
              width: 72,
              height: 72,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                gradient: const LinearGradient(
                  colors: [Color(0xFFC9A44C), Color(0xFFE8C76A)],
                ),
                boxShadow: [
                  BoxShadow(
                    color: const Color(0xFFC9A44C).withValues(alpha: 0.35),
                    blurRadius: 20,
                    offset: const Offset(0, 8),
                  ),
                ],
              ),
              child: const Icon(
                Icons.lock_reset_rounded,
                color: Colors.white,
                size: 34,
              ),
            ),
          ),
          const SizedBox(height: 20),

          const _Heading(
            title: 'Quên mật khẩu?',
            subtitle:
                'Nhập email của bạn – chúng tôi sẽ gửi mã xác nhận 6 số để đặt lại mật khẩu.',
          ),
          const SizedBox(height: 24),

          _AuthTextField(
            controller: _email,
            label: 'Địa chỉ Email',
            hint: 'example@email.com',
            icon: Icons.mail_outline_rounded,
            keyboardType: TextInputType.emailAddress,
            enabled: !_submitting,
            onSubmitted: (_) => _doSendOtp(),
          ),
          const SizedBox(height: 14),

          _MessageBox(error: _errorMsg, success: _successMsg),

          _PrimaryButton(
            label: 'Gửi mã xác nhận',
            icon: Icons.mark_email_read_outlined,
            loading: _submitting,
            onPressed: _doSendOtp,
          ),
          const SizedBox(height: 20),

          Text(
            'Kiểm tra cả hộp thư Spam nếu không thấy email.',
            style: TextStyle(
              color: Colors.white.withValues(alpha: 0.38),
              fontSize: 12,
            ),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }

  // ============================================================
  //  FORGOT PASSWORD – STEP 2 (Nhập OTP + mật khẩu mới)
  // ============================================================
  Widget _buildForgotStep2Page() {
    return _AuthCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Align(
            alignment: Alignment.centerLeft,
            child: _BackButton(onTap: () => _goto(_AuthPage.forgotStep1)),
          ),
          const SizedBox(height: 16),

          _StepIndicator(email: _email.text.trim()),
          const SizedBox(height: 24),

          const _Heading(
            title: 'Đặt lại mật khẩu',
            subtitle:
                'Nhập mã 6 số đã gửi đến email của bạn và tạo mật khẩu mới.',
          ),
          const SizedBox(height: 24),

          _OtpField(controller: _otpCode, enabled: !_submitting),
          const SizedBox(height: 16),

          _AuthTextField(
            controller: _newPassword,
            label: 'Mật khẩu mới',
            hint: '••••••••',
            icon: Icons.lock_outline_rounded,
            obscureText: _obscureNewPassword,
            enabled: !_submitting,
            suffixIcon: IconButton(
              icon: Icon(
                _obscureNewPassword
                    ? Icons.visibility_off_outlined
                    : Icons.visibility_outlined,
                size: 20,
                color: Colors.white38,
              ),
              onPressed: () =>
                  setState(() => _obscureNewPassword = !_obscureNewPassword),
            ),
            onSubmitted: (_) => FocusScope.of(context).nextFocus(),
          ),
          const SizedBox(height: 14),

          _AuthTextField(
            controller: _confirmPassword,
            label: 'Xác nhận mật khẩu',
            hint: '••••••••',
            icon: Icons.lock_reset_rounded,
            obscureText: _obscureConfirmPassword,
            enabled: !_submitting,
            suffixIcon: IconButton(
              icon: Icon(
                _obscureConfirmPassword
                    ? Icons.visibility_off_outlined
                    : Icons.visibility_outlined,
                size: 20,
                color: Colors.white38,
              ),
              onPressed: () => setState(
                () => _obscureConfirmPassword = !_obscureConfirmPassword,
              ),
            ),
            onSubmitted: (_) => _doResetPassword(),
          ),
          const SizedBox(height: 10),

          const _PasswordStrengthHint(),
          const SizedBox(height: 14),

          _MessageBox(error: _errorMsg, success: _successMsg),

          _PrimaryButton(
            label: 'Đặt lại mật khẩu',
            icon: Icons.password_rounded,
            loading: _submitting,
            onPressed: _doResetPassword,
          ),
          const SizedBox(height: 16),

          Center(
            child: TextButton(
              onPressed: _submitting ? null : _doSendOtp,
              style: TextButton.styleFrom(
                foregroundColor: const Color(0xFFC9A44C),
              ),
              child: const Text(
                'Gửi lại mã xác nhận',
                style: TextStyle(fontSize: 13, fontWeight: FontWeight.w600),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

// ============================================================
//  REUSABLE SUB-WIDGETS
// ============================================================

class _AuthCard extends StatelessWidget {
  const _AuthCard({required this.child});
  final Widget child;

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: const Color(0xFF1C2030),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: Colors.white.withValues(alpha: 0.08)),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.45),
            blurRadius: 50,
            offset: const Offset(0, 24),
          ),
        ],
      ),
      padding: const EdgeInsets.all(28),
      child: child,
    );
  }
}

class _Logo extends StatelessWidget {
  const _Logo();

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        Container(
          width: 44,
          height: 44,
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(10),
            gradient: const LinearGradient(
              colors: [Color(0xFFC9A44C), Color(0xFFE8C76A)],
            ),
          ),
          child: const Icon(
            Icons.local_movies_rounded,
            color: Colors.white,
            size: 24,
          ),
        ),
        const SizedBox(width: 10),
        const Text(
          'CineLuxe',
          style: TextStyle(
            color: Colors.white,
            fontSize: 22,
            fontWeight: FontWeight.w900,
            letterSpacing: -0.5,
          ),
        ),
      ],
    );
  }
}

class _Heading extends StatelessWidget {
  const _Heading({required this.title, required this.subtitle});
  final String title;
  final String subtitle;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          title,
          style: const TextStyle(
            color: Colors.white,
            fontSize: 24,
            fontWeight: FontWeight.w900,
            letterSpacing: -0.3,
          ),
        ),
        const SizedBox(height: 6),
        Text(
          subtitle,
          style: TextStyle(
            color: Colors.white.withValues(alpha: 0.52),
            fontSize: 14,
            height: 1.4,
          ),
        ),
      ],
    );
  }
}

class _AuthTextField extends StatelessWidget {
  const _AuthTextField({
    required this.controller,
    required this.label,
    required this.hint,
    required this.icon,
    this.obscureText = false,
    this.keyboardType,
    this.enabled = true,
    this.suffixIcon,
    this.inputFormatters,
    this.onSubmitted,
  });

  final TextEditingController controller;
  final String label;
  final String hint;
  final IconData icon;
  final bool obscureText;
  final TextInputType? keyboardType;
  final bool enabled;
  final Widget? suffixIcon;
  final List<TextInputFormatter>? inputFormatters;
  final ValueChanged<String>? onSubmitted;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: TextStyle(
            color: Colors.white.withValues(alpha: 0.72),
            fontSize: 13,
            fontWeight: FontWeight.w600,
          ),
        ),
        const SizedBox(height: 7),
        TextFormField(
          controller: controller,
          obscureText: obscureText,
          keyboardType: keyboardType,
          enabled: enabled,
          inputFormatters: inputFormatters,
          textInputAction: TextInputAction.next,
          onFieldSubmitted: onSubmitted,
          style: const TextStyle(color: Colors.white, fontSize: 15),
          decoration: InputDecoration(
            hintText: hint,
            hintStyle: TextStyle(
              color: Colors.white.withValues(alpha: 0.22),
              fontSize: 15,
            ),
            prefixIcon: Icon(icon, size: 20, color: Colors.white38),
            suffixIcon: suffixIcon,
            filled: true,
            fillColor: Colors.white.withValues(alpha: 0.06),
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: BorderSide(
                color: Colors.white.withValues(alpha: 0.12),
              ),
            ),
            enabledBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: BorderSide(
                color: Colors.white.withValues(alpha: 0.12),
              ),
            ),
            focusedBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: const BorderSide(
                color: Color(0xFFC9A44C),
                width: 1.6,
              ),
            ),
            disabledBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: BorderSide(
                color: Colors.white.withValues(alpha: 0.06),
              ),
            ),
            contentPadding: const EdgeInsets.symmetric(
              horizontal: 16,
              vertical: 14,
            ),
          ),
        ),
      ],
    );
  }
}

class _OtpField extends StatelessWidget {
  const _OtpField({required this.controller, this.enabled = true});
  final TextEditingController controller;
  final bool enabled;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Mã xác nhận (6 chữ số)',
          style: TextStyle(
            color: Colors.white.withValues(alpha: 0.72),
            fontSize: 13,
            fontWeight: FontWeight.w600,
          ),
        ),
        const SizedBox(height: 7),
        TextFormField(
          controller: controller,
          enabled: enabled,
          keyboardType: TextInputType.number,
          textAlign: TextAlign.center,
          textInputAction: TextInputAction.next,
          inputFormatters: [
            FilteringTextInputFormatter.digitsOnly,
            LengthLimitingTextInputFormatter(6),
          ],
          style: const TextStyle(
            color: Color(0xFFC9A44C),
            fontSize: 24,
            fontWeight: FontWeight.w900,
            letterSpacing: 10,
          ),
          decoration: InputDecoration(
            hintText: '------',
            hintStyle: TextStyle(
              color: Colors.white.withValues(alpha: 0.15),
              fontSize: 24,
              letterSpacing: 10,
            ),
            prefixIcon: const Icon(
              Icons.pin_outlined,
              size: 20,
              color: Colors.white38,
            ),
            filled: true,
            fillColor: Colors.white.withValues(alpha: 0.06),
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: BorderSide(
                color: Colors.white.withValues(alpha: 0.12),
              ),
            ),
            enabledBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: BorderSide(
                color: Colors.white.withValues(alpha: 0.12),
              ),
            ),
            focusedBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: const BorderSide(
                color: Color(0xFFC9A44C),
                width: 1.6,
              ),
            ),
            contentPadding: const EdgeInsets.symmetric(vertical: 16),
          ),
        ),
      ],
    );
  }
}

class _PrimaryButton extends StatelessWidget {
  const _PrimaryButton({
    required this.label,
    required this.icon,
    required this.loading,
    required this.onPressed,
  });

  final String label;
  final IconData icon;
  final bool loading;
  final VoidCallback onPressed;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: 52,
      child: ElevatedButton(
        onPressed: loading ? null : onPressed,
        style: ElevatedButton.styleFrom(
          backgroundColor: const Color(0xFFC9A44C),
          foregroundColor: Colors.white,
          disabledBackgroundColor: const Color(
            0xFFC9A44C,
          ).withValues(alpha: 0.4),
          elevation: 0,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
        ),
        child: loading
            ? const SizedBox(
                width: 22,
                height: 22,
                child: CircularProgressIndicator(
                  strokeWidth: 2.5,
                  color: Colors.white,
                ),
              )
            : Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(icon, size: 20),
                  const SizedBox(width: 8),
                  Text(
                    label,
                    style: const TextStyle(
                      fontSize: 15,
                      fontWeight: FontWeight.w800,
                    ),
                  ),
                ],
              ),
      ),
    );
  }
}

class _GoogleButton extends StatelessWidget {
  const _GoogleButton({required this.loading, required this.onPressed});
  final bool loading;
  final VoidCallback onPressed;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: 52,
      child: OutlinedButton(
        onPressed: loading ? null : onPressed,
        style: OutlinedButton.styleFrom(
          foregroundColor: Colors.white,
          side: BorderSide(color: Colors.white.withValues(alpha: 0.15)),
          backgroundColor: Colors.white.withValues(alpha: 0.05),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            SizedBox(
              width: 22,
              height: 22,
              child: CustomPaint(painter: _GoogleMarkPainter()),
            ),
            const SizedBox(width: 12),
            const Text(
              'Tiếp tục với Google',
              style: TextStyle(
                fontSize: 15,
                fontWeight: FontWeight.w700,
                color: Colors.white,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _GoogleMarkPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final stroke = Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = 3.0
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

class _OrDivider extends StatelessWidget {
  const _OrDivider();

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Expanded(child: Divider(color: Colors.white.withValues(alpha: 0.10))),
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 14),
          child: Text(
            'HOẶC',
            style: TextStyle(
              color: Colors.white.withValues(alpha: 0.35),
              fontSize: 11,
              fontWeight: FontWeight.w700,
              letterSpacing: 1.2,
            ),
          ),
        ),
        Expanded(child: Divider(color: Colors.white.withValues(alpha: 0.10))),
      ],
    );
  }
}

class _SwitchRow extends StatelessWidget {
  const _SwitchRow({
    required this.text,
    required this.actionText,
    required this.onTap,
  });
  final String text;
  final String actionText;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        Text(
          text,
          style: TextStyle(
            color: Colors.white.withValues(alpha: 0.45),
            fontSize: 14,
          ),
        ),
        TextButton(
          onPressed: onTap,
          style: TextButton.styleFrom(
            foregroundColor: const Color(0xFFC9A44C),
            padding: const EdgeInsets.symmetric(horizontal: 4),
            minimumSize: Size.zero,
            tapTargetSize: MaterialTapTargetSize.shrinkWrap,
          ),
          child: Text(
            actionText,
            style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w700),
          ),
        ),
      ],
    );
  }
}

class _BackButton extends StatelessWidget {
  const _BackButton({required this.onTap});
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(
            Icons.arrow_back_rounded,
            color: Colors.white.withValues(alpha: 0.6),
            size: 18,
          ),
          const SizedBox(width: 6),
          Text(
            'Quay lại',
            style: TextStyle(
              color: Colors.white.withValues(alpha: 0.6),
              fontSize: 13,
              fontWeight: FontWeight.w600,
            ),
          ),
        ],
      ),
    );
  }
}

class _HomeButton extends StatelessWidget {
  const _HomeButton({required this.onTap});
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return TextButton.icon(
      onPressed: onTap,
      icon: const Icon(Icons.arrow_back_rounded, size: 18),
      label: const Text('Về trang chủ'),
      style: TextButton.styleFrom(
        foregroundColor: Colors.white.withValues(alpha: 0.72),
        padding: const EdgeInsets.symmetric(horizontal: 0, vertical: 8),
        textStyle: const TextStyle(fontSize: 13, fontWeight: FontWeight.w700),
      ),
    );
  }
}

class _StepIndicator extends StatelessWidget {
  const _StepIndicator({required this.email});
  final String email;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
      decoration: BoxDecoration(
        color: const Color(0xFFC9A44C).withValues(alpha: 0.12),
        borderRadius: BorderRadius.circular(10),
        border: Border.all(
          color: const Color(0xFFC9A44C).withValues(alpha: 0.25),
        ),
      ),
      child: Row(
        children: [
          const Icon(
            Icons.mark_email_read_outlined,
            color: Color(0xFFC9A44C),
            size: 18,
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Text(
              'Mã xác nhận đã gửi đến $email',
              style: const TextStyle(
                color: Color(0xFFC9A44C),
                fontSize: 13,
                fontWeight: FontWeight.w600,
              ),
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
            ),
          ),
        ],
      ),
    );
  }
}

class _MessageBox extends StatelessWidget {
  const _MessageBox({this.error, this.success});
  final String? error;
  final String? success;

  @override
  Widget build(BuildContext context) {
    if (error == null && success == null) return const SizedBox.shrink();

    final isError = error != null;
    final msg = error ?? success!;
    final bgColor = isError
        ? const Color(0xFFD04747).withValues(alpha: 0.12)
        : const Color(0xFF1B9E66).withValues(alpha: 0.12);
    final borderColor = isError
        ? const Color(0xFFD04747).withValues(alpha: 0.40)
        : const Color(0xFF1B9E66).withValues(alpha: 0.40);
    final textColor = isError
        ? const Color(0xFFFF7A7A)
        : const Color(0xFF4ECDA4);
    final iconData = isError
        ? Icons.error_outline_rounded
        : Icons.check_circle_outline_rounded;

    return Padding(
      padding: const EdgeInsets.only(bottom: 14),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
        decoration: BoxDecoration(
          color: bgColor,
          borderRadius: BorderRadius.circular(10),
          border: Border.all(color: borderColor),
        ),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Icon(iconData, color: textColor, size: 18),
            const SizedBox(width: 10),
            Expanded(
              child: Text(
                msg,
                style: TextStyle(color: textColor, fontSize: 13, height: 1.4),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _PasswordStrengthHint extends StatelessWidget {
  const _PasswordStrengthHint();

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.04),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: Colors.white.withValues(alpha: 0.07)),
      ),
      child: Text(
        'Mật khẩu cần ít nhất 8 ký tự, gồm chữ hoa, chữ thường, số và ký tự đặc biệt (!@#\$...).',
        style: TextStyle(
          color: Colors.white.withValues(alpha: 0.40),
          fontSize: 12,
          height: 1.45,
        ),
      ),
    );
  }
}
