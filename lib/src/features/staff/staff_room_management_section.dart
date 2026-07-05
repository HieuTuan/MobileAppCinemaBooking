import 'package:flutter/material.dart';

import '../../core/app_theme.dart';
import '../../core/labels.dart';
import '../../models/app_models.dart';
import '../../shared/widgets/glass_card.dart';
import '../../state/cinema_store.dart';

class StaffRoomManagementSection extends StatefulWidget {
  const StaffRoomManagementSection({
    super.key,
    required this.store,
    this.showTitle = true,
  });

  final CinemaStore store;
  final bool showTitle;

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
        if (widget.showTitle)
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
      margin: const EdgeInsets.only(bottom: 12),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Expanded(
                child: Text(
                  room.name,
                  style: const TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.w900,
                    color: AppColors.ink,
                  ),
                ),
              ),
              Row(
                children: [
                  Text(
                    ready ? 'Hoạt động' : 'Tạm dừng',
                    style: TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.bold,
                      color: ready ? const Color(0xFF047857) : const Color(0xFFB91C1C),
                    ),
                  ),
                  const SizedBox(width: 4),
                  Switch(
                    value: ready,
                    onChanged: (_) => onToggle(),
                    activeColor: const Color(0xFF10B981),
                  ),
                ],
              ),
            ],
          ),
          const SizedBox(height: 4),
          Wrap(
            spacing: 8,
            runSpacing: 6,
            children: [
              _RoomStatusPill(status: room.status),
              _CapacityPill(capacity: room.capacity),
              _ScreenTypePill(type: room.screenType),
            ],
          ),
          const SizedBox(height: 14),
          TextField(
            controller: issue,
            decoration: const InputDecoration(
              hintText: 'Mô tả chi tiết sự cố kỹ thuật...',
              prefixIcon: Icon(Icons.report_problem_outlined, color: Color(0xFFEF4444)),
            ),
          ),
          const SizedBox(height: 10),
          SizedBox(
            width: double.infinity,
            child: OutlinedButton.icon(
              onPressed: onReport,
              icon: const Icon(Icons.report_gmailerrorred_rounded, color: Color(0xFFEF4444), size: 18),
              label: const Text(
                'Gửi báo cáo sự cố kỹ thuật',
                style: TextStyle(
                  fontWeight: FontWeight.w800,
                  color: Color(0xFFEF4444),
                ),
              ),
              style: OutlinedButton.styleFrom(
                side: const BorderSide(color: Color(0xFFFCA5A5)),
                backgroundColor: const Color(0xFFFEF2F2),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _RoomStatusPill extends StatelessWidget {
  const _RoomStatusPill({required this.status});
  final RoomStatus status;

  @override
  Widget build(BuildContext context) {
    Color bgColor;
    Color textColor;
    String label;

    if (status == RoomStatus.ready) {
      bgColor = const Color(0xFF10B981).withOpacity(0.12);
      textColor = const Color(0xFF047857);
      label = 'Sẵn sàng';
    } else {
      bgColor = const Color(0xFFEF4444).withOpacity(0.12);
      textColor = const Color(0xFFB91C1C);
      label = 'Bảo trì';
    }

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
      decoration: BoxDecoration(
        color: bgColor,
        borderRadius: BorderRadius.circular(6),
      ),
      child: Text(
        label,
        style: TextStyle(
          fontSize: 11,
          fontWeight: FontWeight.w900,
          color: textColor,
        ),
      ),
    );
  }
}

class _CapacityPill extends StatelessWidget {
  const _CapacityPill({required this.capacity});
  final int capacity;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
      decoration: BoxDecoration(
        color: AppColors.pearl,
        borderRadius: BorderRadius.circular(6),
        border: Border.all(color: AppColors.line),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          const Icon(
            Icons.airline_seat_recline_normal_rounded,
            size: 12,
            color: AppColors.muted,
          ),
          const SizedBox(width: 4),
          Text(
            '$capacity ghế',
            style: const TextStyle(
              fontSize: 11,
              fontWeight: FontWeight.bold,
              color: AppColors.muted,
            ),
          ),
        ],
      ),
    );
  }
}

class _ScreenTypePill extends StatelessWidget {
  const _ScreenTypePill({required this.type});
  final String type;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
      decoration: BoxDecoration(
        color: const Color(0xFF3B82F6).withOpacity(0.12),
        borderRadius: BorderRadius.circular(6),
      ),
      child: Text(
        type.toUpperCase(),
        style: const TextStyle(
          fontSize: 10,
          fontWeight: FontWeight.w900,
          color: Color(0xFF1D4ED8),
        ),
      ),
    );
  }
}
