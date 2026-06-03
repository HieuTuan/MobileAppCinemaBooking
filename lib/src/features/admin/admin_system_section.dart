import 'package:flutter/material.dart';

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
        SectionTitle(
          title: 'Tích hợp VNPay',
          action: TextButton.icon(
            onPressed: () => _vnpayDialog(context),
            icon: const Icon(Icons.edit_outlined),
            label: const Text('Sửa'),
          ),
        ),
        GlassCard(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text('Terminal ID: ${store.vnpayConfig.terminalId}'),
              Text('Secret Key: ${store.vnpayConfig.secretKey}'),
              Text('Môi trường: ${store.vnpayConfig.environment}'),
              const SizedBox(height: 8),
              const Text(
                'Giao dịch demo dùng sandbox, Refund API được mô phỏng trong Admin.',
              ),
            ],
          ),
        ),
        const SectionTitle(title: 'Bản địa hóa'),
        GlassCard(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              SegmentedButton<AppLanguage>(
                segments: const [
                  ButtonSegment(
                    value: AppLanguage.vi,
                    label: Text('Tiếng Việt'),
                  ),
                  ButtonSegment(value: AppLanguage.en, label: Text('English')),
                ],
                selected: {store.language},
                onSelectionChanged: (value) => store.setLanguage(value.first),
              ),
              const SizedBox(height: 10),
              Text('Tiền tệ mặc định: ${money(125000)}'),
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
    showDialog<void>(
      context: context,
      builder: (context) => AlertDialog(
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
            onPressed: () => Navigator.pop(context),
            child: const Text('Hủy'),
          ),
          FilledButton(
            onPressed: () {
              store.saveBanner(
                AppBanner(
                  id: 'BN${compactId(DateTime.now())}',
                  title: title.text.trim(),
                  message: message.text.trim(),
                  active: true,
                ),
              );
              Navigator.pop(context);
            },
            child: const Text('Lưu'),
          ),
        ],
      ),
    );
  }

  void _vnpayDialog(BuildContext context) {
    final terminal = TextEditingController(text: store.vnpayConfig.terminalId);
    final secret = TextEditingController(text: store.vnpayConfig.secretKey);
    final env = TextEditingController(text: store.vnpayConfig.environment);
    showDialog<void>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Cấu hình VNPay'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextField(
              controller: terminal,
              decoration: const InputDecoration(labelText: 'Terminal ID'),
            ),
            const SizedBox(height: 10),
            TextField(
              controller: secret,
              decoration: const InputDecoration(labelText: 'Secret Key'),
            ),
            const SizedBox(height: 10),
            TextField(
              controller: env,
              decoration: const InputDecoration(
                labelText: 'Môi trường sandbox/production',
              ),
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
              store.updateVnpayConfig(
                VnpayConfig(
                  terminalId: terminal.text.trim(),
                  secretKey: secret.text.trim(),
                  environment: env.text.trim(),
                ),
              );
              Navigator.pop(context);
            },
            child: const Text('Lưu'),
          ),
        ],
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
    return ListTile(
      contentPadding: EdgeInsets.zero,
      leading: Icon(icon),
      title: Text(title),
      subtitle: Text(subtitle),
    );
  }
}
