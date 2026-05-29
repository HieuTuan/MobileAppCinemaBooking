part of '../../app.dart';

class _BrandPanel extends StatelessWidget {
  const _BrandPanel({required this.users, required this.onPick});

  final List<DemoUser> users;
  final ValueChanged<DemoUser> onPick;

  @override
  Widget build(BuildContext context) {
    return Container(
      constraints: const BoxConstraints(minHeight: 430),
      padding: const EdgeInsets.all(28),
      decoration: BoxDecoration(
        color: _surface.withValues(alpha: .88),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: _gold.withValues(alpha: .22)),
        image: const DecorationImage(
          image: NetworkImage(
            'https://images.unsplash.com/photo-1489599849927-2ee91cede3ba?auto=format&fit=crop&w=1400&q=80',
          ),
          fit: BoxFit.cover,
          opacity: .18,
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Icon(Icons.local_movies_outlined, color: _gold, size: 42),
              const SizedBox(height: 18),
              Text(
                'Cineverse Club',
                style: Theme.of(context).textTheme.displaySmall?.copyWith(
                  fontFamily: 'Playfair Display',
                  fontWeight: FontWeight.w700,
                  color: _stone,
                ),
              ),
              const SizedBox(height: 12),
              const Text(
                'Cong trai nghiem dien anh thuong luu va tro ly phong chieu AI cho khach VIP, quan tri vien va nhan vien sanh.',
                style: TextStyle(color: _muted, height: 1.5, fontSize: 15),
              ),
            ],
          ),
          Wrap(
            spacing: 10,
            runSpacing: 10,
            children: users.map((user) {
              return ActionChip(
                avatar: Icon(_roleIcon(user.role), size: 18, color: _obsidian),
                label: Text(_roleLabel(user.role)),
                backgroundColor: _gold,
                labelStyle: const TextStyle(
                  color: _obsidian,
                  fontWeight: FontWeight.w700,
                ),
                onPressed: () => onPick(user),
              );
            }).toList(),
          ),
        ],
      ),
    );
  }
}

class _LoginPanel extends StatelessWidget {
  const _LoginPanel({
    required this.registering,
    required this.name,
    required this.email,
    required this.password,
    required this.phone,
    required this.error,
    required this.onSubmit,
    required this.onToggleMode,
  });

  final bool registering;
  final TextEditingController name;
  final TextEditingController email;
  final TextEditingController password;
  final TextEditingController phone;
  final String? error;
  final VoidCallback onSubmit;
  final VoidCallback onToggleMode;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: _surface,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: Colors.white.withValues(alpha: .08)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(
            registering ? 'Dang ky hoi vien' : 'Dang nhap',
            style: Theme.of(
              context,
            ).textTheme.headlineSmall?.copyWith(fontWeight: FontWeight.w700),
          ),
          const SizedBox(height: 18),
          if (registering) ...[
            TextField(
              controller: name,
              decoration: const InputDecoration(
                prefixIcon: Icon(Icons.badge_outlined),
                labelText: 'Ho ten',
              ),
              textInputAction: TextInputAction.next,
            ),
            const SizedBox(height: 12),
          ],
          TextField(
            controller: email,
            decoration: const InputDecoration(
              prefixIcon: Icon(Icons.mail_outline),
              labelText: 'Email',
            ),
            keyboardType: TextInputType.emailAddress,
          ),
          const SizedBox(height: 12),
          if (registering) ...[
            TextField(
              controller: phone,
              decoration: const InputDecoration(
                prefixIcon: Icon(Icons.phone_outlined),
                labelText: 'So dien thoai',
              ),
              keyboardType: TextInputType.phone,
              textInputAction: TextInputAction.next,
            ),
            const SizedBox(height: 12),
          ],
          TextField(
            controller: password,
            decoration: const InputDecoration(
              prefixIcon: Icon(Icons.lock_outline),
              labelText: 'Mat ma',
            ),
            obscureText: true,
            onSubmitted: (_) => onSubmit(),
          ),
          if (error != null) ...[
            const SizedBox(height: 12),
            Text(error!, style: const TextStyle(color: Color(0xFFF87171))),
          ],
          const SizedBox(height: 20),
          FilledButton.icon(
            onPressed: onSubmit,
            icon: Icon(registering ? Icons.person_add_alt_1 : Icons.login),
            label: Text(
              registering ? 'TAO TAI KHOAN VIP' : 'VAO SANH CINEVERSE',
            ),
          ),
          const SizedBox(height: 10),
          TextButton(
            onPressed: onToggleMode,
            child: Text(
              registering
                  ? 'Da co tai khoan? Dang nhap'
                  : 'Chua co tai khoan? Dang ky hoi vien',
            ),
          ),
        ],
      ),
    );
  }
}
