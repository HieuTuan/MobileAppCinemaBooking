import 'package:flutter/material.dart';

import '../../core/app_theme.dart';
import '../../core/labels.dart';
import '../../models/app_models.dart';
import '../../shared/widgets/glass_card.dart';
import '../../state/cinema_store.dart';

class StaffRoomManagementSection extends StatefulWidget {
  const StaffRoomManagementSection({super.key, required this.store});

  final CinemaStore store;

  @override
  State<StaffRoomManagementSection> createState() =>
      _StaffRoomManagementSectionState();
}

class _StaffRoomManagementSectionState
    extends State<StaffRoomManagementSection> {
  final Map<String, TextEditingController> _issueControllers = {};

  @override
  void dispose() {
    for (final controller in _issueControllers.values) {
      controller.dispose();
    }
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const SectionTitle(title: 'Phòng chiếu và sự cố kỹ thuật'),
        ...widget.store.rooms.map(
          (room) => _RoomCard(
            room: room,
            issue: _controllerFor(room),
            onToggle: () {
              widget.store.toggleRoomStatus(room.id);
              setState(() {});
            },
            onReport: () => _report(room),
          ),
        ),
      ],
    );
  }

  TextEditingController _controllerFor(Room room) {
    return _issueControllers.putIfAbsent(
      room.id,
      () => TextEditingController(),
    );
  }

  void _report(Room room) {
    final controller = _controllerFor(room);
    final description = controller.text.trim().isEmpty
        ? 'Cần kiểm tra phòng ${room.name}'
        : controller.text.trim();
    widget.store.reportIssue(room.id, description);
    controller.clear();
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text('Đã gửi sự cố phòng ${room.name} lên Admin.')),
    );
  }
}

class _RoomCard extends StatelessWidget {
  const _RoomCard({
    required this.room,
    required this.issue,
    required this.onToggle,
    required this.onReport,
  });

  final Room room;
  final TextEditingController issue;
  final VoidCallback onToggle;
  final VoidCallback onReport;

  @override
  Widget build(BuildContext context) {
    final ready = room.status == RoomStatus.ready;
    return GlassCard(
      margin: const EdgeInsets.only(bottom: 10),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Expanded(
                child: Text(
                  '${room.name} • ${room.screenType}',
                  style: const TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w900,
                  ),
                ),
              ),
              Switch(value: ready, onChanged: (_) => onToggle()),
            ],
          ),
          Text(
            'Sức chứa ${room.capacity} • ${roomStatusLabel(room.status)}',
            style: Theme.of(context).textTheme.bodyMedium?.copyWith(
              color: ready ? AppColors.success : AppColors.warning,
              fontWeight: FontWeight.w800,
            ),
          ),
          const SizedBox(height: 12),
          TextField(
            controller: issue,
            decoration: const InputDecoration(
              hintText: 'Mô tả sự cố kỹ thuật',
              prefixIcon: Icon(Icons.report_problem_outlined),
            ),
          ),
          const SizedBox(height: 10),
          OutlinedButton.icon(
            onPressed: onReport,
            icon: const Icon(Icons.send_outlined),
            label: const Text('Báo cáo Admin'),
          ),
        ],
      ),
    );
  }
}
