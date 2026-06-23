import 'package:flutter/material.dart';

import '../../../models/admin_models.dart' hide Room;
import '../../core/app_theme.dart';
import '../../models/app_models.dart';

// ─── Enums / helpers ─────────────────────────────────────────────────────────

enum _EditMode { none, standard, vip, couple, remove }

extension on _EditMode {
  String get label {
    switch (this) {
      case _EditMode.none:
        return 'Chọn công cụ';
      case _EditMode.standard:
        return 'Ghế thường';
      case _EditMode.vip:
        return 'Ghế VIP';
      case _EditMode.couple:
        return 'Ghế đôi';
      case _EditMode.remove:
        return 'Xoá ghế';
    }
  }

  Color get color {
    switch (this) {
      case _EditMode.none:
        return AppColors.muted;
      case _EditMode.standard:
        return const Color(0xFF3B82F6);
      case _EditMode.vip:
        return AppColors.gold;
      case _EditMode.couple:
        return const Color(0xFFEC4899);
      case _EditMode.remove:
        return AppColors.danger;
    }
  }

  IconData get icon {
    switch (this) {
      case _EditMode.none:
        return Icons.touch_app_rounded;
      case _EditMode.standard:
        return Icons.chair_outlined;
      case _EditMode.vip:
        return Icons.star_rounded;
      case _EditMode.couple:
        return Icons.favorite_rounded;
      case _EditMode.remove:
        return Icons.remove_circle_outline_rounded;
    }
  }
}

// ─── Editable seat model ─────────────────────────────────────────────────────

class _EditableSeat {
  _EditableSeat({
    required this.seatCode,
    required this.row,
    required this.column,
    required this.seatType,
    this.exists = true,
  });

  final String seatCode;
  final String row;
  final int column;
  SeatType seatType;
  bool exists; // false = deleted/empty slot

  factory _EditableSeat.fromLayout(RoomSeatLayout layout) {
    SeatType type;
    switch (layout.seatType.toLowerCase()) {
      case 'vip':
        type = SeatType.vip;
        break;
      case 'couple':
        type = SeatType.couple;
        break;
      default:
        type = SeatType.standard;
    }
    return _EditableSeat(
      seatCode: layout.seatCode,
      row: layout.row,
      column: layout.column,
      seatType: type,
    );
  }

  RoomSeatLayout toLayout() {
    String typeStr;
    switch (seatType) {
      case SeatType.vip:
        typeStr = 'vip';
        break;
      case SeatType.couple:
        typeStr = 'couple';
        break;
      default:
        typeStr = 'standard';
    }
    return RoomSeatLayout(
      seatCode: seatCode,
      row: row,
      column: column,
      seatType: typeStr,
    );
  }
}

// ─── Main Screen ─────────────────────────────────────────────────────────────

class RoomSeatEditorScreen extends StatefulWidget {
  const RoomSeatEditorScreen({
    super.key,
    required this.room,
    required this.initialLayout,
    this.onSave,
  });

  /// The Room being edited (for display + meta).
  final Room room;

  /// Initial seat layout to render.
  final List<RoomSeatLayout> initialLayout;

  /// Called with the updated layout when the admin saves. Null ⇒ read-only.
  final Future<void> Function(List<RoomSeatLayout>)? onSave;

  @override
  State<RoomSeatEditorScreen> createState() => _RoomSeatEditorScreenState();
}

class _RoomSeatEditorScreenState extends State<RoomSeatEditorScreen>
    with TickerProviderStateMixin {
  // ─── State ────────────────────────────────────────────────────────────────

  late List<_EditableSeat> _seats;
  late List<List<_EditableSeat?>> _grid; // [rowIndex][colIndex]
  _EditMode _mode = _EditMode.none;
  bool _isDragging = false;
  bool _saving = false;
  bool _hasChanges = false;

  late AnimationController _toolbarAnimCtrl;
  late Animation<double> _toolbarAnim;

  // ─── Derived ──────────────────────────────────────────────────────────────

  int get _standardCount =>
      _seats.where((s) => s.exists && s.seatType == SeatType.standard).length;
  int get _vipCount =>
      _seats.where((s) => s.exists && s.seatType == SeatType.vip).length;
  int get _coupleCount =>
      _seats.where((s) => s.exists && s.seatType == SeatType.couple).length;
  int get _totalActive => _seats.where((s) => s.exists).length;

  // ─── Lifecycle ────────────────────────────────────────────────────────────

  @override
  void initState() {
    super.initState();
    _toolbarAnimCtrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 350),
    );
    _toolbarAnim = CurvedAnimation(
      parent: _toolbarAnimCtrl,
      curve: Curves.easeOutCubic,
    );
    _toolbarAnimCtrl.forward();
    _buildFromLayout(widget.initialLayout);
  }

  @override
  void dispose() {
    _toolbarAnimCtrl.dispose();
    super.dispose();
  }

  void _buildFromLayout(List<RoomSeatLayout> layout) {
    _seats = layout.map(_EditableSeat.fromLayout).toList();
    _rebuildGrid();
  }

  void _rebuildGrid() {
    if (_seats.isEmpty) {
      _grid = [];
      return;
    }

    // Collect unique rows in order
    final rowLetters =
        _seats.map((s) => s.row).toSet().toList()..sort();

    final maxCol = _seats.map((s) => s.column).reduce((a, b) => a > b ? a : b);

    _grid = List.generate(rowLetters.length, (ri) {
      final rowLetter = rowLetters[ri];
      return List.generate(maxCol, (ci) {
        final col = ci + 1;
        try {
          return _seats.firstWhere(
            (s) => s.row == rowLetter && s.column == col,
          );
        } catch (_) {
          return null;
        }
      });
    });
  }

  // ─── Edit logic ───────────────────────────────────────────────────────────

  void _applySeatEdit(_EditableSeat seat) {
    if (_mode == _EditMode.none) return;
    setState(() {
      _hasChanges = true;
      switch (_mode) {
        case _EditMode.standard:
          seat.exists = true;
          seat.seatType = SeatType.standard;
          break;
        case _EditMode.vip:
          seat.exists = true;
          seat.seatType = SeatType.vip;
          break;
        case _EditMode.couple:
          seat.exists = true;
          seat.seatType = SeatType.couple;
          break;
        case _EditMode.remove:
          seat.exists = false;
          break;
        case _EditMode.none:
          break;
      }
    });
  }

  // ─── Save ─────────────────────────────────────────────────────────────────

  Future<void> _handleSave() async {
    if (widget.onSave == null) return;
    final activeSeats =
        _seats.where((s) => s.exists).map((s) => s.toLayout()).toList();
    setState(() => _saving = true);
    try {
      await widget.onSave!(activeSeats);
      if (mounted) {
        setState(() {
          _hasChanges = false;
          _saving = false;
        });
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Đã lưu sơ đồ ghế!'),
            backgroundColor: AppColors.success,
            behavior: SnackBarBehavior.floating,
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        setState(() => _saving = false);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Lỗi lưu: $e'),
            backgroundColor: AppColors.danger,
            behavior: SnackBarBehavior.floating,
          ),
        );
      }
    }
  }

  // ─── Build ────────────────────────────────────────────────────────────────

  @override
  Widget build(BuildContext context) {
    final isEditable = widget.onSave != null;
    return Scaffold(
      backgroundColor: const Color(0xFF0D1117),
      appBar: AppBar(
        backgroundColor: const Color(0xFF161B22),
        foregroundColor: Colors.white,
        title: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              widget.room.name,
              style: const TextStyle(
                fontSize: 17,
                fontWeight: FontWeight.w900,
                color: Colors.white,
              ),
            ),
            Text(
              '${widget.room.screenType} • ${widget.room.capacity} ghế',
              style: const TextStyle(fontSize: 12, color: Color(0xFF8B949E)),
            ),
          ],
        ),
        actions: [
          if (isEditable && _hasChanges)
            Padding(
              padding: const EdgeInsets.only(right: 12),
              child: FilledButton.icon(
                style: FilledButton.styleFrom(
                  backgroundColor: AppColors.gold,
                  foregroundColor: Colors.black,
                  minimumSize: const Size(0, 36),
                  padding: const EdgeInsets.symmetric(horizontal: 16),
                ),
                onPressed: _saving ? null : _handleSave,
                icon: _saving
                    ? const SizedBox(
                        width: 14,
                        height: 14,
                        child: CircularProgressIndicator(
                          strokeWidth: 2,
                          color: Colors.black,
                        ),
                      )
                    : const Icon(Icons.save_rounded, size: 16),
                label: const Text(
                  'Lưu',
                  style: TextStyle(fontWeight: FontWeight.w800),
                ),
              ),
            ),
        ],
      ),
      body: Column(
        children: [
          // ── Stats bar ────────────────────────────────────────────────
          _buildStatsBar(),

          // ── Edit toolbar (only when editable) ────────────────────────
          if (isEditable) _buildEditToolbar(),

          // ── Screen indicator ─────────────────────────────────────────
          _buildScreenIndicator(),

          // ── Seat grid ────────────────────────────────────────────────
          Expanded(child: _buildSeatGrid(isEditable)),

          // ── Legend ───────────────────────────────────────────────────
          _buildLegend(),
        ],
      ),
    );
  }

  // ─── Stats bar ────────────────────────────────────────────────────────────

  Widget _buildStatsBar() {
    return Container(
      color: const Color(0xFF161B22),
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
      child: Row(
        children: [
          _statChip(
            label: 'Thường',
            count: _standardCount,
            color: const Color(0xFF3B82F6),
            icon: Icons.chair_outlined,
          ),
          const SizedBox(width: 8),
          _statChip(
            label: 'VIP',
            count: _vipCount,
            color: AppColors.gold,
            icon: Icons.star_rounded,
          ),
          const SizedBox(width: 8),
          _statChip(
            label: 'Đôi',
            count: _coupleCount,
            color: const Color(0xFFEC4899),
            icon: Icons.favorite_rounded,
          ),
          const Spacer(),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
            decoration: BoxDecoration(
              color: Colors.white.withValues(alpha: .08),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Text(
              'Tổng: $_totalActive ghế',
              style: const TextStyle(
                color: Colors.white,
                fontSize: 13,
                fontWeight: FontWeight.w700,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _statChip({
    required String label,
    required int count,
    required Color color,
    required IconData icon,
  }) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
      decoration: BoxDecoration(
        color: color.withValues(alpha: .15),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: color.withValues(alpha: .3)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 14, color: color),
          const SizedBox(width: 5),
          Text(
            '$count $label',
            style: TextStyle(
              color: color,
              fontSize: 12,
              fontWeight: FontWeight.w700,
            ),
          ),
        ],
      ),
    );
  }

  // ─── Edit toolbar ─────────────────────────────────────────────────────────

  Widget _buildEditToolbar() {
    return SlideTransition(
      position: Tween<Offset>(
        begin: const Offset(0, -1),
        end: Offset.zero,
      ).animate(_toolbarAnim),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
        decoration: BoxDecoration(
          color: const Color(0xFF21262D),
          border: Border(
            bottom: BorderSide(
              color: Colors.white.withValues(alpha: .08),
            ),
          ),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Padding(
              padding: EdgeInsets.only(left: 4, bottom: 6),
              child: Text(
                'Chọn loại ghế rồi chạm/kéo lên ghế để chỉnh:',
                style: TextStyle(
                  color: Color(0xFF8B949E),
                  fontSize: 11,
                ),
              ),
            ),
            SingleChildScrollView(
              scrollDirection: Axis.horizontal,
              child: Row(
                children: _EditMode.values
                    .map((mode) => _buildToolButton(mode))
                    .toList(),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildToolButton(_EditMode mode) {
    final isSelected = _mode == mode;
    final color = mode.color;
    return GestureDetector(
      onTap: () => setState(() => _mode = isSelected ? _EditMode.none : mode),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        margin: const EdgeInsets.only(right: 8),
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 7),
        decoration: BoxDecoration(
          color: isSelected
              ? color.withValues(alpha: .25)
              : Colors.white.withValues(alpha: .06),
          borderRadius: BorderRadius.circular(10),
          border: Border.all(
            color: isSelected ? color : Colors.white.withValues(alpha: .12),
            width: isSelected ? 1.5 : 1,
          ),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              mode.icon,
              size: 16,
              color: isSelected ? color : const Color(0xFF8B949E),
            ),
            const SizedBox(width: 6),
            Text(
              mode.label,
              style: TextStyle(
                color: isSelected ? color : const Color(0xFF8B949E),
                fontSize: 12,
                fontWeight:
                    isSelected ? FontWeight.w800 : FontWeight.w500,
              ),
            ),
          ],
        ),
      ),
    );
  }

  // ─── Screen indicator ─────────────────────────────────────────────────────

  Widget _buildScreenIndicator() {
    return Padding(
      padding: const EdgeInsets.fromLTRB(24, 16, 24, 4),
      child: Column(
        children: [
          Container(
            height: 4,
            margin: const EdgeInsets.symmetric(horizontal: 32),
            decoration: BoxDecoration(
              gradient: const LinearGradient(
                colors: [
                  Color(0xFF3B82F6),
                  Color(0xFF8B5CF6),
                  Color(0xFFEC4899),
                ],
              ),
              borderRadius: BorderRadius.circular(2),
              boxShadow: [
                BoxShadow(
                  color: const Color(0xFF3B82F6).withValues(alpha: .5),
                  blurRadius: 12,
                  offset: const Offset(0, 2),
                ),
              ],
            ),
          ),
          const SizedBox(height: 6),
          const Text(
            'MÀN HÌNH',
            style: TextStyle(
              color: Color(0xFF8B949E),
              fontSize: 10,
              letterSpacing: 3,
              fontWeight: FontWeight.w600,
            ),
          ),
        ],
      ),
    );
  }

  // ─── Seat grid ────────────────────────────────────────────────────────────

  Widget _buildSeatGrid(bool isEditable) {
    if (_grid.isEmpty) {
      return const Center(
        child: Text(
          'Chưa có sơ đồ ghế',
          style: TextStyle(color: Color(0xFF8B949E)),
        ),
      );
    }

    return InteractiveViewer(
      minScale: 0.5,
      maxScale: 2.5,
      child: SingleChildScrollView(
        padding: const EdgeInsets.fromLTRB(16, 8, 16, 16),
        child: Column(
          children: List.generate(_grid.length, (ri) {
            final rowLetter =
                _seats.map((s) => s.row).toSet().toList()..sort();
            return _buildRow(rowLetter[ri], _grid[ri], isEditable);
          }),
        ),
      ),
    );
  }

  Widget _buildRow(String label, List<_EditableSeat?> cols, bool isEditable) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 6),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          // Row label
          SizedBox(
            width: 22,
            child: Text(
              label,
              textAlign: TextAlign.center,
              style: const TextStyle(
                color: Color(0xFF8B949E),
                fontSize: 11,
                fontWeight: FontWeight.w700,
              ),
            ),
          ),
          const SizedBox(width: 4),
          // Seats
          Wrap(
            spacing: 4,
            children: cols.map((seat) {
              if (seat == null) {
                return const SizedBox(width: 34, height: 34);
              }
              return _buildSeatCell(seat, isEditable);
            }).toList(),
          ),
        ],
      ),
    );
  }

  Widget _buildSeatCell(_EditableSeat seat, bool isEditable) {
    final bool deleted = !seat.exists;

    Color seatColor;
    Color borderColor;
    IconData? seatIcon;

    if (deleted) {
      seatColor = Colors.transparent;
      borderColor = Colors.white.withValues(alpha: .08);
    } else {
      switch (seat.seatType) {
        case SeatType.vip:
          seatColor = AppColors.gold.withValues(alpha: .85);
          borderColor = AppColors.gold;
          seatIcon = Icons.star_rounded;
          break;
        case SeatType.couple:
          seatColor = const Color(0xFFEC4899).withValues(alpha: .85);
          borderColor = const Color(0xFFEC4899);
          seatIcon = Icons.favorite_rounded;
          break;
        default:
          seatColor = const Color(0xFF3B82F6).withValues(alpha: .8);
          borderColor = const Color(0xFF3B82F6);
      }
    }

    Widget cellContent;
    if (deleted) {
      cellContent = Container(
        width: 34,
        height: 30,
        decoration: BoxDecoration(
          color: Colors.white.withValues(alpha: .03),
          borderRadius: BorderRadius.circular(5),
          border: Border.all(
            color: Colors.white.withValues(alpha: .06),
            style: BorderStyle.solid,
          ),
        ),
      );
    } else {
      cellContent = Container(
        width: 34,
        height: 30,
        decoration: BoxDecoration(
          color: seatColor,
          borderRadius: BorderRadius.circular(5),
          border: Border.all(color: borderColor.withValues(alpha: .6)),
          boxShadow: [
            BoxShadow(
              color: borderColor.withValues(alpha: .25),
              blurRadius: 4,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            if (seatIcon != null)
              Icon(seatIcon, size: 10, color: Colors.white)
            else
              const SizedBox(height: 2),
            Text(
              seat.seatCode,
              style: const TextStyle(
                color: Colors.white,
                fontSize: 8,
                fontWeight: FontWeight.w700,
              ),
            ),
          ],
        ),
      );
    }

    if (!isEditable) return cellContent;

    // Editable: support tap + drag
    return GestureDetector(
      onTap: () {
        if (_mode != _EditMode.none) {
          _applySeatEdit(seat);
        } else {
          _showSeatInfo(seat);
        }
      },
      onPanStart: (_) {
        _isDragging = true;
        _applySeatEdit(seat);
      },
      onPanUpdate: (details) {
        // Find seat under pointer
        if (_isDragging) {
          // handled via individual seat onPanStart
        }
      },
      onPanEnd: (_) => _isDragging = false,
      child: MouseRegion(
        cursor: _mode != _EditMode.none
            ? SystemMouseCursors.click
            : SystemMouseCursors.basic,
        child: AnimatedSwitcher(
          duration: const Duration(milliseconds: 180),
          child: KeyedSubtree(key: ValueKey(seat.exists ? seat.seatType : 'del'),
            child: cellContent,
          ),
        ),
      ),
    );
  }

  void _showSeatInfo(_EditableSeat seat) {
    if (!seat.exists) return;
    String typeLabel;
    Color typeColor;
    switch (seat.seatType) {
      case SeatType.vip:
        typeLabel = 'Ghế VIP';
        typeColor = AppColors.gold;
        break;
      case SeatType.couple:
        typeLabel = 'Ghế đôi';
        typeColor = const Color(0xFFEC4899);
        break;
      default:
        typeLabel = 'Ghế thường';
        typeColor = const Color(0xFF3B82F6);
    }

    showModalBottomSheet<void>(
      context: context,
      backgroundColor: const Color(0xFF161B22),
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (ctx) => Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: typeColor.withValues(alpha: .15),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Icon(
                    seat.seatType == SeatType.vip
                        ? Icons.star_rounded
                        : seat.seatType == SeatType.couple
                            ? Icons.favorite_rounded
                            : Icons.chair_outlined,
                    color: typeColor,
                    size: 28,
                  ),
                ),
                const SizedBox(width: 14),
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Ghế ${seat.seatCode}',
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 20,
                        fontWeight: FontWeight.w900,
                      ),
                    ),
                    Text(
                      typeLabel,
                      style: TextStyle(
                        color: typeColor,
                        fontSize: 14,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ],
                ),
              ],
            ),
            const SizedBox(height: 20),
            const Text(
              'Chọn loại ghế để thay đổi:',
              style: TextStyle(color: Color(0xFF8B949E), fontSize: 13),
            ),
            const SizedBox(height: 12),
            Row(
              children: [
                _quickChangeTile(
                  ctx,
                  seat,
                  SeatType.standard,
                  'Thường',
                  const Color(0xFF3B82F6),
                  Icons.chair_outlined,
                ),
                const SizedBox(width: 8),
                _quickChangeTile(
                  ctx,
                  seat,
                  SeatType.vip,
                  'VIP',
                  AppColors.gold,
                  Icons.star_rounded,
                ),
                const SizedBox(width: 8),
                _quickChangeTile(
                  ctx,
                  seat,
                  SeatType.couple,
                  'Đôi',
                  const Color(0xFFEC4899),
                  Icons.favorite_rounded,
                ),
              ],
            ),
            const SizedBox(height: 16),
          ],
        ),
      ),
    );
  }

  Widget _quickChangeTile(
    BuildContext sheetCtx,
    _EditableSeat seat,
    SeatType type,
    String label,
    Color color,
    IconData icon,
  ) {
    final isSelected = seat.seatType == type;
    return Expanded(
      child: GestureDetector(
        onTap: () {
          Navigator.pop(sheetCtx);
          setState(() {
            seat.seatType = type;
            seat.exists = true;
            _hasChanges = true;
          });
        },
        child: Container(
          padding: const EdgeInsets.symmetric(vertical: 12),
          decoration: BoxDecoration(
            color: isSelected
                ? color.withValues(alpha: .2)
                : Colors.white.withValues(alpha: .06),
            borderRadius: BorderRadius.circular(12),
            border: Border.all(
              color: isSelected ? color : Colors.white.withValues(alpha: .12),
              width: isSelected ? 1.5 : 1,
            ),
          ),
          child: Column(
            children: [
              Icon(icon, color: isSelected ? color : const Color(0xFF8B949E), size: 22),
              const SizedBox(height: 4),
              Text(
                label,
                style: TextStyle(
                  color: isSelected ? color : const Color(0xFF8B949E),
                  fontSize: 12,
                  fontWeight: FontWeight.w700,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  // ─── Legend ───────────────────────────────────────────────────────────────

  Widget _buildLegend() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
      color: const Color(0xFF161B22),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          _legendItem(const Color(0xFF3B82F6), 'Ghế thường'),
          const SizedBox(width: 16),
          _legendItem(AppColors.gold, 'Ghế VIP'),
          const SizedBox(width: 16),
          _legendItem(const Color(0xFFEC4899), 'Ghế đôi'),
          const SizedBox(width: 16),
          _legendItem(Colors.white.withValues(alpha: .08), 'Đã xoá'),
        ],
      ),
    );
  }

  Widget _legendItem(Color color, String label) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Container(
          width: 14,
          height: 11,
          decoration: BoxDecoration(
            color: color,
            borderRadius: BorderRadius.circular(2),
          ),
        ),
        const SizedBox(width: 5),
        Text(
          label,
          style: const TextStyle(
            color: Color(0xFF8B949E),
            fontSize: 11,
          ),
        ),
      ],
    );
  }
}
