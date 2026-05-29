part of '../../../app.dart';

class LoginScreen extends StatefulWidget {
  const LoginScreen({
    super.key,
    required this.users,
    required this.onLogin,
    required this.onRegister,
  });

  final List<DemoUser> users;
  final ValueChanged<DemoUser> onLogin;
  final ValueChanged<DemoUser> onRegister;

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  final _name = TextEditingController();
  final _email = TextEditingController(text: 'demo@cineverse.vnd');
  final _password = TextEditingController(text: 'demo1234');
  final _phone = TextEditingController();
  bool _registering = false;
  String? _error;

  @override
  void dispose() {
    _name.dispose();
    _email.dispose();
    _password.dispose();
    _phone.dispose();
    super.dispose();
  }

  void _submit() {
    if (_registering) {
      _register();
      return;
    }

    final user = widget.users.where((item) {
      return item.email == _email.text.trim() &&
          item.password == _password.text.trim();
    }).firstOrNull;

    if (user == null) {
      setState(() => _error = 'Thong tin dang nhap khong hop le.');
      return;
    }
    widget.onLogin(user);
  }

  void _register() {
    final name = _name.text.trim();
    final email = _email.text.trim();
    final password = _password.text.trim();
    final phone = _phone.text.trim();

    if (name.isEmpty || email.isEmpty || password.length < 6 || phone.isEmpty) {
      setState(() => _error = 'Vui long nhap day du thong tin dang ky.');
      return;
    }
    final existed = widget.users.any((user) => user.email == email);
    if (existed) {
      setState(() => _error = 'Email nay da co tai khoan Cineverse.');
      return;
    }

    widget.onRegister(
      DemoUser(
        name: name,
        email: email,
        password: password,
        phone: phone,
        role: UserRole.customer,
        memberTier: 'VIP Gold Trial',
        favoriteBranch: 'Lux Quan 1',
      ),
    );
  }

  void _fill(DemoUser user) {
    setState(() {
      _registering = false;
      _name.text = user.name;
      _email.text = user.email;
      _password.text = user.password;
      _phone.text = user.phone;
      _error = null;
    });
  }

  void _toggleMode() {
    setState(() {
      _registering = !_registering;
      _error = null;
      if (_registering) {
        _email.clear();
        _password.clear();
      } else {
        _email.text = 'demo@cineverse.vnd';
        _password.text = 'demo1234';
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Container(
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [_obsidian, Color(0xFF17130E), _surface],
          ),
        ),
        child: SafeArea(
          child: Center(
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 1080),
              child: LayoutBuilder(
                builder: (context, constraints) {
                  final wide = constraints.maxWidth > 760;
                  return SingleChildScrollView(
                    padding: const EdgeInsets.all(24),
                    child: wide
                        ? Row(
                            children: [
                              Expanded(
                                child: _BrandPanel(
                                  users: widget.users,
                                  onPick: _fill,
                                ),
                              ),
                              const SizedBox(width: 24),
                              Expanded(
                                child: _LoginPanel(
                                  registering: _registering,
                                  name: _name,
                                  email: _email,
                                  password: _password,
                                  phone: _phone,
                                  error: _error,
                                  onSubmit: _submit,
                                  onToggleMode: _toggleMode,
                                ),
                              ),
                            ],
                          )
                        : Column(
                            children: [
                              _BrandPanel(users: widget.users, onPick: _fill),
                              const SizedBox(height: 18),
                              _LoginPanel(
                                registering: _registering,
                                name: _name,
                                email: _email,
                                password: _password,
                                phone: _phone,
                                error: _error,
                                onSubmit: _submit,
                                onToggleMode: _toggleMode,
                              ),
                            ],
                          ),
                  );
                },
              ),
            ),
          ),
        ),
      ),
    );
  }
}
