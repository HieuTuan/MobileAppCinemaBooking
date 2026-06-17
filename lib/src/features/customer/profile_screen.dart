import 'package:flutter/material.dart';

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
  late final TextEditingController _name;
  late final TextEditingController _phone;

  @override
  void initState() {
    super.initState();
    final user = widget.store.currentUser!;
    _name = TextEditingController(text: user.fullName);
    _phone = TextEditingController(text: user.phone);
  }

  @override
  void dispose() {
    _name.dispose();
    _phone.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final user = widget.store.currentUser!;
    final history = widget.store.bookingsForUser(user.id);
    return ListView(
      padding: const EdgeInsets.fromLTRB(16, 8, 16, 100),
      children: [
        GlassCard(
          child: Row(
            children: [
              CircleAvatar(
                radius: 34,
                backgroundColor: AppColors.goldSoft,
                child: Text(
                  user.fullName.characters.first.toUpperCase(),
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
                      user.fullName,
                      style: Theme.of(context).textTheme.titleLarge?.copyWith(
                        fontWeight: FontWeight.w900,
                      ),
                    ),
                    Text('${user.memberRank} - ${user.points} điểm'),
                    Text(user.email),
                  ],
                ),
              ),
            ],
          ),
        ),
        const SectionTitle(title: 'Cập nhật thông tin'),
        GlassCard(
          child: Column(
            children: [
              TextField(
                controller: _name,
                decoration: const InputDecoration(labelText: 'Họ và tên'),
              ),
              const SizedBox(height: 10),
              TextField(
                controller: _phone,
                decoration: const InputDecoration(labelText: 'Số điện thoại'),
              ),
              const SizedBox(height: 10),
              SizedBox(
                width: double.infinity,
                child: FilledButton.icon(
                  onPressed: () =>
                      widget.store.updateProfile(_name.text, _phone.text),
                  icon: const Icon(Icons.save_outlined),
                  label: const Text('Lưu hồ sơ'),
                ),
              ),
            ],
          ),
        ),
        const SectionTitle(title: 'Cài đặt thông báo'),
        GlassCard(
          child: ListTile(
            contentPadding: EdgeInsets.zero,
            leading: Icon(Icons.notifications, color: AppColors.primary),
            title: const Text('Quản lý thông báo'),
            subtitle: const Text('Cài đặt tùy chọn nhận thông báo'),
            trailing: const Icon(Icons.chevron_right),
            onTap: () {
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (context) => NotificationPreferencesScreen(
                    userId: user.id,
                  ),
                ),
              );
            },
          ),
        ),
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
