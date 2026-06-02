import 'package:flutter/material.dart';

import '../../core/app_theme.dart';
import '../../core/formatters.dart';
import '../../core/labels.dart';
import '../../models/app_models.dart';
import '../../shared/widgets/glass_card.dart';
import '../../shared/widgets/luxury_scaffold.dart';
import '../../state/cinema_store.dart';

class AdminDashboard extends StatefulWidget {
  const AdminDashboard({super.key, required this.store});

  final CinemaStore store;

  @override
  State<AdminDashboard> createState() => _AdminDashboardState();
}

class _AdminDashboardState extends State<AdminDashboard> {
  int _tab = 0;

  @override
  Widget build(BuildContext context) {
    final pages = [
      _ContentAdmin(store: widget.store),
      _AccountAdmin(store: widget.store),
      _FinanceAdmin(store: widget.store),
      _SystemAdmin(store: widget.store),
    ];
    return LuxuryScaffold(
      title: 'Bảng quản trị',
      actions: [
        IconButton(
          tooltip: 'Đăng xuất',
          onPressed: widget.store.logout,
          icon: const Icon(Icons.logout_rounded),
        ),
      ],
      bottomNavigationBar: NavigationBar(
        selectedIndex: _tab,
        onDestinationSelected: (value) => setState(() => _tab = value),
        destinations: const [
          NavigationDestination(
            icon: Icon(Icons.movie_creation_outlined),
            label: 'Nội dung',
          ),
          NavigationDestination(
            icon: Icon(Icons.people_outline_rounded),
            label: 'Tài khoản',
          ),
          NavigationDestination(
            icon: Icon(Icons.query_stats_rounded),
            label: 'Báo cáo',
          ),
          NavigationDestination(
            icon: Icon(Icons.settings_outlined),
            label: 'Cấu hình',
          ),
        ],
      ),
      child: IndexedStack(index: _tab, children: pages),
    );
  }
}

class _ContentAdmin extends StatelessWidget {
  const _ContentAdmin({required this.store});

  final CinemaStore store;

  @override
  Widget build(BuildContext context) {
    return ListView(
      padding: const EdgeInsets.fromLTRB(16, 8, 16, 100),
      children: [
        Row(
          children: [
            Expanded(
              child: MetricCard(
                label: 'Phim',
                value: store.movies.length.toString(),
                icon: Icons.local_movies_rounded,
              ),
            ),
            const SizedBox(width: 10),
            Expanded(
              child: MetricCard(
                label: 'Suất chiếu',
                value: store.showtimes.length.toString(),
                icon: Icons.event_rounded,
                color: AppColors.success,
              ),
            ),
          ],
        ),
        SectionTitle(
          title: 'Quản lý phim',
          action: FilledButton.icon(
            onPressed: () => _movieDialog(context),
            icon: const Icon(Icons.add_rounded),
            label: const Text('Thêm'),
          ),
        ),
        ...store.movies.map(
          (movie) => GlassCard(
            margin: const EdgeInsets.only(bottom: 10),
            child: ListTile(
              contentPadding: EdgeInsets.zero,
              leading: CircleAvatar(
                backgroundColor: Color(movie.heroColor).withValues(alpha: .18),
                child: const Icon(Icons.movie_filter_rounded),
              ),
              title: Text(movie.title),
              subtitle: Text('${movie.genres.join(', ')} - ${movie.ageRating}'),
              trailing: Wrap(
                spacing: 4,
                children: [
                  IconButton(
                    tooltip: 'Sửa',
                    onPressed: () => _movieDialog(context, movie: movie),
                    icon: const Icon(Icons.edit_outlined),
                  ),
                  IconButton(
                    tooltip: 'Xóa',
                    onPressed: () => store.deleteMovie(movie.id),
                    icon: const Icon(Icons.delete_outline_rounded),
                  ),
                ],
              ),
            ),
          ),
        ),
        const SectionTitle(title: 'Thể loại, rạp, phòng, lịch chiếu'),
        GlassCard(
          child: Wrap(
            spacing: 8,
            runSpacing: 8,
            children: [
              ...store.genres
                  .where((genre) => genre != 'Tất cả')
                  .map((genre) => Chip(label: Text(genre))),
              ...store.rooms.map(
                (room) =>
                    Chip(label: Text('${room.name} - ${room.screenType}')),
              ),
              Chip(label: Text('${store.cinemas.first.name} - 1 rạp')),
            ],
          ),
        ),
        ...store.showtimes.map((showtime) {
          final movie = store.movieById(showtime.movieId);
          final room = store.roomById(showtime.roomId);
          return ListTile(
            leading: const Icon(Icons.schedule_rounded),
            title: Text(movie.title),
            subtitle: Text(
              '${room.name} - ${shortDate(showtime.startTime)} ${shortTime(showtime.startTime)}',
            ),
            trailing: Text(money(showtime.basePrice)),
          );
        }),
      ],
    );
  }

  void _movieDialog(BuildContext context, {Movie? movie}) {
    final title = TextEditingController(text: movie?.title ?? 'Phim mới');
    final genre = TextEditingController(
      text: movie?.genres.join(', ') ?? 'Hành động',
    );
    showDialog<void>(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(movie == null ? 'Thêm phim' : 'Sửa phim'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextField(
              controller: title,
              decoration: const InputDecoration(labelText: 'Tên phim'),
            ),
            const SizedBox(height: 10),
            TextField(
              controller: genre,
              decoration: const InputDecoration(labelText: 'Thể loại'),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Hủy'),
          ),
          FilledButton(
            onPressed: () {
              final now = DateTime.now();
              final saved = Movie(
                id: movie?.id ?? 'M${compactId(now)}',
                title: title.text,
                description:
                    movie?.description ?? 'Mô tả phim mới từ Admin Panel.',
                genres: genre.text
                    .split(',')
                    .map((item) => item.trim())
                    .toList(),
                durationMinutes: movie?.durationMinutes ?? 110,
                director: movie?.director ?? 'Đang cập nhật',
                cast: movie?.cast ?? const ['Đang cập nhật'],
                posterUrl:
                    movie?.posterUrl ??
                    'https://image.tmdb.org/t/p/w500/vpnVM9B6NMmQpWeZvzLvDESb2QY.jpg',
                trailerUrl: movie?.trailerUrl ?? 'https://youtu.be/demo',
                rating: movie?.rating ?? 7.5,
                ageRating: movie?.ageRating ?? 'T13',
                releaseDate: movie?.releaseDate ?? now,
                status: movie?.status ?? MovieStatus.comingSoon,
                heroColor: movie?.heroColor ?? 0xFFC9A44C,
              );
              store.saveMovie(saved);
              Navigator.pop(context);
            },
            child: const Text('Lưu'),
          ),
        ],
      ),
    );
  }
}

class _AccountAdmin extends StatefulWidget {
  const _AccountAdmin({required this.store});

  final CinemaStore store;

  @override
  State<_AccountAdmin> createState() => _AccountAdminState();
}

class _AccountAdminState extends State<_AccountAdmin> {
  final _search = TextEditingController();

  @override
  void dispose() {
    _search.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final query = _search.text.toLowerCase();
    final users = widget.store.users.where((user) {
      return query.isEmpty ||
          user.fullName.toLowerCase().contains(query) ||
          user.email.toLowerCase().contains(query);
    }).toList();
    return ListView(
      padding: const EdgeInsets.fromLTRB(16, 8, 16, 100),
      children: [
        TextField(
          controller: _search,
          onChanged: (_) => setState(() {}),
          decoration: const InputDecoration(
            hintText: 'Tìm user/staff theo tên hoặc email',
            prefixIcon: Icon(Icons.search_rounded),
          ),
        ),
        SectionTitle(
          title: 'Tài khoản và RBAC',
          action: FilledButton.icon(
            onPressed: () => _addStaffDialog(context),
            icon: const Icon(Icons.person_add_alt_rounded),
            label: const Text('Staff'),
          ),
        ),
        ...users.map(
          (user) => GlassCard(
            margin: const EdgeInsets.only(bottom: 10),
            child: ListTile(
              contentPadding: EdgeInsets.zero,
              leading: Icon(
                user.role == UserRole.admin
                    ? Icons.admin_panel_settings_rounded
                    : user.role == UserRole.staff
                    ? Icons.badge_rounded
                    : Icons.person_rounded,
              ),
              title: Text(user.fullName),
              subtitle: Text(
                '${user.email} - ${roleLabel(user.role)} - ${user.permissions.join(', ')}',
              ),
              trailing: Switch(
                value: user.isActive,
                onChanged: user.role == UserRole.admin
                    ? null
                    : (_) => widget.store.toggleUserStatus(user.id),
              ),
            ),
          ),
        ),
      ],
    );
  }

  void _addStaffDialog(BuildContext context) {
    final name = TextEditingController(text: 'Nhân viên mới');
    final email = TextEditingController(text: 'new.staff@cineluxe.vn');
    showDialog<void>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Tạo tài khoản Staff'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextField(
              controller: name,
              decoration: const InputDecoration(labelText: 'Họ tên'),
            ),
            const SizedBox(height: 10),
            TextField(
              controller: email,
              decoration: const InputDecoration(labelText: 'Email'),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Hủy'),
          ),
          FilledButton(
            onPressed: () {
              widget.store.addStaff(name.text, email.text);
              Navigator.pop(context);
            },
            child: const Text('Tạo'),
          ),
        ],
      ),
    );
  }
}

class _FinanceAdmin extends StatelessWidget {
  const _FinanceAdmin({required this.store});

  final CinemaStore store;

  @override
  Widget build(BuildContext context) {
    final sold = store.soldTicketsByMovie();
    return ListView(
      padding: const EdgeInsets.fromLTRB(16, 8, 16, 100),
      children: [
        Row(
          children: [
            Expanded(
              child: MetricCard(
                label: 'Doanh thu',
                value: money(store.revenueTotal()),
                icon: Icons.payments_outlined,
              ),
            ),
            const SizedBox(width: 10),
            Expanded(
              child: MetricCard(
                label: 'Booking',
                value: store.bookings.length.toString(),
                icon: Icons.confirmation_number_outlined,
                color: AppColors.success,
              ),
            ),
          ],
        ),
        const SectionTitle(title: 'Thống kê vé theo phim'),
        GlassCard(
          child: Column(
            children: sold.entries.map((entry) {
              return ListTile(
                contentPadding: EdgeInsets.zero,
                title: Text(entry.key),
                subtitle: LinearProgressIndicator(
                  value: (entry.value / 20).clamp(0, 1),
                  color: AppColors.gold,
                ),
                trailing: Text('${entry.value} vé'),
              );
            }).toList(),
          ),
        ),
        const SectionTitle(title: 'Booking, VNPay và hoàn tiền'),
        ...store.bookings.map(
          (booking) => GlassCard(
            margin: const EdgeInsets.only(bottom: 10),
            child: ListTile(
              contentPadding: EdgeInsets.zero,
              title: Text('${booking.id} - ${booking.customerName}'),
              subtitle: Text(
                '${booking.movieTitle} - ${bookingStatusLabel(booking.status)}',
              ),
              trailing: Wrap(
                spacing: 6,
                children: [
                  Text(money(booking.totalAmount)),
                  IconButton(
                    tooltip: 'Refund VNPay',
                    onPressed: booking.status == BookingStatus.active
                        ? () => store.cancelBooking(booking.id)
                        : null,
                    icon: const Icon(Icons.undo_rounded),
                  ),
                ],
              ),
            ),
          ),
        ),
        const SectionTitle(title: 'Xuất báo cáo'),
        GlassCard(
          child: Wrap(
            spacing: 8,
            runSpacing: 8,
            children: [
              FilledButton.icon(
                onPressed: () =>
                    _snack(context, 'Đã tạo file Excel .xlsx demo.'),
                icon: const Icon(Icons.table_chart_outlined),
                label: const Text('Excel .xlsx'),
              ),
              OutlinedButton.icon(
                onPressed: () => _snack(context, 'Đã tạo file PDF demo.'),
                icon: const Icon(Icons.picture_as_pdf_outlined),
                label: const Text('PDF'),
              ),
            ],
          ),
        ),
      ],
    );
  }

  void _snack(BuildContext context, String text) {
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(text)));
  }
}

class _SystemAdmin extends StatelessWidget {
  const _SystemAdmin({required this.store});

  final CinemaStore store;

  @override
  Widget build(BuildContext context) {
    final config = store.vnpayConfig;
    return ListView(
      padding: const EdgeInsets.fromLTRB(16, 8, 16, 100),
      children: [
        const SectionTitle(title: 'Giá vé theo ghế và suất'),
        const GlassCard(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              ListTile(
                contentPadding: EdgeInsets.zero,
                leading: Icon(Icons.chair_outlined),
                title: Text('Standard'),
                subtitle: Text('Giá cơ bản theo suất chiếu'),
              ),
              ListTile(
                contentPadding: EdgeInsets.zero,
                leading: Icon(Icons.event_seat_rounded),
                title: Text('VIP'),
                subtitle: Text('Giá cơ bản + 45.000 VND'),
              ),
              ListTile(
                contentPadding: EdgeInsets.zero,
                leading: Icon(Icons.weekend_outlined),
                title: Text('Couple'),
                subtitle: Text('2 vé + phụ thu 70.000 VND'),
              ),
            ],
          ),
        ),
        const SectionTitle(title: 'Banner và thông báo app'),
        ...store.banners.map(
          (banner) => GlassCard(
            margin: const EdgeInsets.only(bottom: 10),
            child: ListTile(
              contentPadding: EdgeInsets.zero,
              leading: const Icon(Icons.campaign_outlined),
              title: Text(banner.title),
              subtitle: Text(banner.message),
              trailing: Icon(
                banner.active
                    ? Icons.visibility_rounded
                    : Icons.visibility_off_rounded,
              ),
            ),
          ),
        ),
        const SectionTitle(title: 'Tích hợp VNPay'),
        GlassCard(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text('Terminal ID: ${config.terminalId}'),
              Text('Secret Key: ${config.secretKey}'),
              Text('Môi trường: ${config.environment}'),
              const SizedBox(height: 8),
              const Text(
                'Chữ ký giao dịch: HMAC-SHA512, callback IPN qua HTTPS.',
              ),
            ],
          ),
        ),
        const SectionTitle(title: 'Sự cố phòng chiếu từ Staff'),
        if (store.issues.isEmpty)
          const GlassCard(child: Text('Chưa có sự cố nào.'))
        else
          ...store.issues.map(
            (issue) => GlassCard(
              margin: const EdgeInsets.only(bottom: 10),
              child: ListTile(
                contentPadding: EdgeInsets.zero,
                leading: const Icon(Icons.report_problem_outlined),
                title: Text(store.roomById(issue.roomId).name),
                subtitle: Text(
                  '${issue.description} - ${fullDateTime(issue.createdAt)}',
                ),
                trailing: Text(issue.status),
              ),
            ),
          ),
      ],
    );
  }
}
