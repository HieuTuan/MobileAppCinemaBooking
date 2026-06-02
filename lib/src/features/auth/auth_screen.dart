import 'package:flutter/material.dart';

import '../../models/app_models.dart';
import '../../shared/widgets/glass_card.dart';
import '../../shared/widgets/luxury_scaffold.dart';
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
      'OTP demo: 246810. OAuth Google/Facebook được mô phỏng trong FE.';

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
    return LuxuryScaffold(
      child: LayoutBuilder(
        builder: (context, constraints) {
          final wide = constraints.maxWidth > 760;
          return Center(
            child: SingleChildScrollView(
              padding: const EdgeInsets.all(20),
              child: ConstrainedBox(
                constraints: const BoxConstraints(maxWidth: 980),
                child: Flex(
                  direction: wide ? Axis.horizontal : Axis.vertical,
                  crossAxisAlignment: CrossAxisAlignment.center,
                  children: [
                    if (wide)
                      const Expanded(flex: 5, child: _HeroPanel())
                    else
                      const _HeroPanel(),
                    SizedBox(width: wide ? 24 : 0, height: wide ? 0 : 18),
                    if (wide)
                      Expanded(
                        flex: 4,
                        child: _AuthPanel(
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
                        ),
                      )
                    else
                      _AuthPanel(
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
                      ),
                  ],
                ),
              ),
            ),
          );
        },
      ),
    );
  }

  void _toggleMode() {
    setState(() {
      _registerMode = !_registerMode;
      _message = _registerMode
          ? 'Nhập thông tin, hệ thống sẽ gửi OTP tới email/SMS.'
          : 'Đăng nhập bằng email/mật khẩu hoặc OAuth demo.';
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
      return;
    }
    final ok = widget.store.login(_email.text, _password.text);
    if (!ok) {
      setState(() {
        _message = 'Thông tin đăng nhập không đúng hoặc tài khoản đã bị khóa.';
      });
    }
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
          Text(
            registerMode ? 'Đăng ký tài khoản' : 'Đăng nhập',
            style: Theme.of(
              context,
            ).textTheme.headlineSmall?.copyWith(fontWeight: FontWeight.w900),
          ),
          const SizedBox(height: 8),
          Text(message, style: Theme.of(context).textTheme.bodySmall),
          const SizedBox(height: 16),
          if (registerMode) ...[
            TextField(
              controller: name,
              decoration: const InputDecoration(
                labelText: 'Họ và tên',
                prefixIcon: Icon(Icons.badge_outlined),
              ),
            ),
            const SizedBox(height: 10),
            TextField(
              controller: phone,
              keyboardType: TextInputType.phone,
              decoration: const InputDecoration(
                labelText: 'Số điện thoại',
                prefixIcon: Icon(Icons.phone_rounded),
              ),
            ),
            const SizedBox(height: 10),
          ],
          TextField(
            controller: email,
            keyboardType: TextInputType.emailAddress,
            decoration: const InputDecoration(
              labelText: 'Email hoặc số điện thoại',
              prefixIcon: Icon(Icons.mail_outline_rounded),
            ),
          ),
          const SizedBox(height: 10),
          TextField(
            controller: password,
            obscureText: true,
            decoration: const InputDecoration(
              labelText: 'Mật khẩu',
              prefixIcon: Icon(Icons.lock_outline_rounded),
            ),
          ),
          const SizedBox(height: 14),
          ShimmerButton(
            label: registerMode ? 'Xác thực OTP và đăng ký' : 'Vào hệ thống',
            icon: registerMode
                ? Icons.verified_user_outlined
                : Icons.login_rounded,
            onPressed: onSubmit,
          ),
          TextButton(
            onPressed: onToggleMode,
            child: Text(
              registerMode
                  ? 'Đã có tài khoản? Đăng nhập'
                  : 'Chưa có tài khoản? Đăng ký',
            ),
          ),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: [
              OutlinedButton.icon(
                onPressed: () => store.demoLogin(UserRole.customer),
                icon: const Icon(Icons.person_rounded),
                label: const Text('Khách demo'),
              ),
              OutlinedButton.icon(
                onPressed: () => store.demoLogin(UserRole.staff),
                icon: const Icon(Icons.qr_code_scanner_rounded),
                label: const Text('Nhân viên demo'),
              ),
              OutlinedButton.icon(
                onPressed: () => store.demoLogin(UserRole.admin),
                icon: const Icon(Icons.admin_panel_settings_rounded),
                label: const Text('Quản trị demo'),
              ),
            ],
          ),
          const Divider(height: 24),
          Row(
            children: [
              Expanded(
                child: OutlinedButton.icon(
                  onPressed: () => store.demoLogin(UserRole.customer),
                  icon: const Icon(Icons.g_mobiledata_rounded),
                  label: const Text('Google'),
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: OutlinedButton.icon(
                  onPressed: () => store.demoLogin(UserRole.customer),
                  icon: const Icon(Icons.facebook_rounded),
                  label: const Text('Facebook'),
                ),
              ),
            ],
          ),
          TextButton(
            onPressed: onForgotPassword,
            child: const Text('Quên mật khẩu? Khôi phục qua email/SMS'),
          ),
        ],
      ),
    );
  }
}

class _HeroPanel extends StatelessWidget {
  const _HeroPanel();

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      mainAxisSize: MainAxisSize.min,
      children: [
        const Icon(Icons.local_movies_rounded, size: 54),
        const SizedBox(height: 12),
        Text(
          'CineLuxe',
          style: Theme.of(context).textTheme.displayMedium?.copyWith(
            fontWeight: FontWeight.w900,
            letterSpacing: 0,
          ),
        ),
        Text(
          'Đặt vé xem phim sang trọng, nhanh và đầy đủ luồng User - Staff - Admin.',
          style: Theme.of(context).textTheme.titleMedium,
        ),
        const SizedBox(height: 18),
        const Wrap(
          spacing: 10,
          runSpacing: 10,
          children: [
            _Pill('OTP'),
            _Pill('OAuth'),
            _Pill('VNPay'),
            _Pill('Vé QR'),
            _Pill('RBAC'),
          ],
        ),
      ],
    );
  }
}

class _Pill extends StatelessWidget {
  const _Pill(this.label);

  final String label;

  @override
  Widget build(BuildContext context) {
    return Chip(
      label: Text(label),
      avatar: const Icon(Icons.auto_awesome_rounded, size: 16),
    );
  }
}
