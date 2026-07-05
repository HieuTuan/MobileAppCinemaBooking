import 'package:flutter/material.dart';

import '../../../api/api_client.dart';
import '../../core/app_theme.dart';
import '../../core/formatters.dart';
import '../../models/app_models.dart';
import '../../shared/widgets/glass_card.dart';
import '../../state/cinema_store.dart';

class AdminSystemSection extends StatelessWidget {
  const AdminSystemSection({super.key, required this.store});

  final CinemaStore store;

  @override
  Widget build(BuildContext context) {
    return ListView(
      padding: const EdgeInsets.fromLTRB(16, 8, 16, 100),
      children: [
        SectionTitle(
          title: 'Giá vé theo ghế và suất',
          action: TextButton.icon(
            onPressed: () => _pricingDialog(context),
            icon: const Icon(Icons.edit_outlined),
            label: const Text('Sửa'),
          ),
        ),
        GlassCard(
          child: Column(
            children: [
              _ConfigRow(
                icon: Icons.chair_outlined,
                title: 'Ghế thường',
                subtitle:
                    'Giá cơ bản theo suất + ${money(store.standardSeatSurcharge)}',
              ),
              _ConfigRow(
                icon: Icons.event_seat_rounded,
                title: 'Ghế VIP',
                subtitle:
                    'Giá cơ bản theo suất + ${money(store.vipSeatSurcharge)}',
              ),
              _ConfigRow(
                icon: Icons.weekend_outlined,
                title: 'Ghế đôi',
                subtitle: '2 vé + phụ thu ${money(store.coupleSeatSurcharge)}',
              ),
            ],
          ),
        ),
        SectionTitle(
          title: 'Banner và thông báo app',
          action: TextButton.icon(
            onPressed: () => _bannerDialog(context),
            icon: const Icon(Icons.add_rounded),
            label: const Text('Thêm'),
          ),
        ),
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
                  '${issue.description} • ${fullDateTime(issue.createdAt)}',
                ),
                trailing: Text(issue.status),
              ),
            ),
          ),
      ],
    );
  }

  void _pricingDialog(BuildContext context) {
    final standard = TextEditingController(
      text: '${store.standardSeatSurcharge}',
    );
    final vip = TextEditingController(text: '${store.vipSeatSurcharge}');
    final couple = TextEditingController(text: '${store.coupleSeatSurcharge}');
    showDialog<void>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Cấu hình giá vé'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            _numberField(standard, 'Phụ thu ghế thường'),
            _numberField(vip, 'Phụ thu ghế VIP'),
            _numberField(couple, 'Phụ thu ghế đôi'),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Hủy'),
          ),
          FilledButton(
            onPressed: () {
              store.updateSeatPricing(
                standardSurcharge: int.tryParse(standard.text) ?? 0,
                vipSurcharge: int.tryParse(vip.text) ?? 45000,
                coupleSurcharge: int.tryParse(couple.text) ?? 70000,
              );
              Navigator.pop(context);
            },
            child: const Text('Lưu'),
          ),
        ],
      ),
    );
  }

  void _bannerDialog(BuildContext context) {
    final title = TextEditingController(text: 'Thông báo mới');
    final message = TextEditingController(text: 'Nội dung thông báo trên app.');
    var sending = false;
    showDialog<void>(
      context: context,
      builder: (context) => StatefulBuilder(
        builder: (context, setDialogState) => AlertDialog(
          title: const Text('Thêm banner/thông báo'),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextField(
                controller: title,
                decoration: const InputDecoration(labelText: 'Tiêu đề'),
              ),
              const SizedBox(height: 10),
              TextField(
                controller: message,
                decoration: const InputDecoration(labelText: 'Nội dung'),
              ),
            ],
          ),
          actions: [
            TextButton(
              onPressed: sending ? null : () => Navigator.pop(context),
              child: const Text('Hủy'),
            ),
            FilledButton(
              onPressed: sending
                  ? null
                  : () async {
                      final nextTitle = title.text.trim();
                      final nextMessage = message.text.trim();
                      if (nextTitle.isEmpty || nextMessage.isEmpty) {
                        _showSnack(
                          context,
                          'Vui lòng nhập tiêu đề và nội dung',
                          isError: true,
                        );
                        return;
                      }
                      setDialogState(() => sending = true);
                      try {
                        final delivered = await APIClient()
                            .sendMarketingNotification(
                              title: nextTitle,
                              body: nextMessage,
                            );
                        store.saveBanner(
                          AppBanner(
                            id: 'BN${compactId(DateTime.now())}',
                            title: nextTitle,
                            message: nextMessage,
                            active: true,
                          ),
                        );
                        if (context.mounted) {
                          Navigator.pop(context);
                          _showSnack(
                            context,
                            'Đã gửi thông báo tới $delivered khách hàng',
                          );
                        }
                      } catch (e) {
                        if (!context.mounted) return;
                        _showSnack(
                          context,
                          'Gửi thông báo thất bại: $e',
                          isError: true,
                        );
                      } finally {
                        if (context.mounted) {
                          setDialogState(() => sending = false);
                        }
                      }
                    },
              child: sending
                  ? const SizedBox(
                      width: 18,
                      height: 18,
                      child: CircularProgressIndicator(strokeWidth: 2),
                    )
                  : const Text('Gửi'),
            ),
          ],
        ),
      ),
    );
  }

  void _showSnack(
    BuildContext context,
    String message, {
    bool isError = false,
  }) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: isError ? Colors.redAccent : null,
        behavior: SnackBarBehavior.floating,
      ),
    );
  }

  Widget _numberField(TextEditingController controller, String label) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 10),
      child: TextField(
        controller: controller,
        keyboardType: TextInputType.number,
        decoration: InputDecoration(labelText: label),
      ),
    );
  }
}

class _ConfigRow extends StatelessWidget {
  const _ConfigRow({
    required this.icon,
    required this.title,
    required this.subtitle,
  });

  final IconData icon;
  final String title;
  final String subtitle;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 4),
      decoration: const BoxDecoration(
        border: Border(bottom: BorderSide(color: AppColors.line, width: 0.8)),
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: const Color(0xFFF59E0B).withValues(alpha: 0.12),
              shape: BoxShape.circle,
            ),
            child: Icon(icon, color: const Color(0xFFD97706), size: 20),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: const TextStyle(
                    fontSize: 15,
                    fontWeight: FontWeight.w800,
                    color: AppColors.ink,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  subtitle,
                  style: const TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.w500,
                    color: AppColors.muted,
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
