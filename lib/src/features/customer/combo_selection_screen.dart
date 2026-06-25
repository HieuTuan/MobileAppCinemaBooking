import 'dart:async';

import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';

import '../../../api/api_client.dart';
import '../../../models/booking_models.dart' as api_models;
import '../../core/app_theme.dart';
import '../../core/formatters.dart';
import '../../models/app_models.dart';
import '../../state/cinema_store.dart';
import 'payment_screen.dart';

/// Màn hình Chọn combo đồ ăn — Luồng R8.
///
/// Bước 1: GET /api/food-combos → danh sách combo active (trong 200ms)
/// Bước 2: Chọn combo + số lượng, lưu trong local state
/// Bước 3: Tổng tiền combo = Σ(price × quantity)
/// Bước 4: Submit booking: gửi kèm combos: [{comboId, quantity}]
/// Lỗi: ComboId invalid hoặc inactive → 400 (xử lý ở payment_screen)
class ComboSelectionScreen extends StatefulWidget {
  const ComboSelectionScreen({
    super.key,
    required this.store,
    required this.movie,
    required this.showtime,
    required this.selectedSeats,
    required this.hold,
  });

  final CinemaStore store;
  final Movie movie;
  final Showtime showtime;
  final List<String> selectedSeats;
  final api_models.HoldResponse hold;

  @override
  State<ComboSelectionScreen> createState() => _ComboSelectionScreenState();
}

class _ComboSelectionScreenState extends State<ComboSelectionScreen> {
  final APIClient _apiClient = APIClient();

  // Bước 2: local state lưu số lượng mỗi combo đã chọn
  final Map<String, int> _quantities = {};

  List<api_models.FoodCombo> _combos = const [];
  Timer? _holdTimer;
  Duration _remaining = Duration.zero;
  bool _loading = true;
  String? _error;

  @override
  void initState() {
    super.initState();
    // Bước 1: gọi API ngay khi mở màn hình
    _loadCombos();
    _tick();
    _holdTimer = Timer.periodic(const Duration(seconds: 1), (_) => _tick());
  }

  @override
  void dispose() {
    _holdTimer?.cancel();
    super.dispose();
  }

  // ── Bước 1: GET /api/food-combos ─────────────────────────────────────────

  Future<void> _loadCombos() async {
    setState(() {
      _loading = true;
      _error = null;
    });
    try {
      final combos = await _apiClient.getFoodCombos();
      if (mounted) {
        setState(() {
          // Chỉ hiển thị combo active và còn hàng
          _combos = combos.where((c) => c.quantity > 0).toList();
          _loading = false;
        });
      }
    } catch (_) {
      if (mounted) {
        setState(() {
          _error = 'Không thể tải danh sách combo. Nhấn để thử lại.';
          _loading = false;
        });
      }
    }
  }

  // ── Hold timer ────────────────────────────────────────────────────────────

  void _tick() {
    final remaining = widget.hold.expiresAt.difference(DateTime.now());
    if (remaining <= Duration.zero) {
      _holdTimer?.cancel();
      if (!mounted) return;
      setState(() => _remaining = Duration.zero);
      showDialog<void>(
        context: context,
        barrierDismissible: false,
        builder: (context) => AlertDialog(
          title: const Text('Thời gian giữ ghế đã hết'),
          content: const Text('Ghế đã được trả lại. Vui lòng chọn ghế lại.'),
          actions: [
            FilledButton(
              onPressed: () {
                Navigator.of(context).pop();
                Navigator.of(context).pop(); // quay về booking_screen
              },
              child: const Text('Chọn lại ghế'),
            ),
          ],
        ),
      );
      return;
    }
    if (mounted) setState(() => _remaining = remaining);
  }

  // ── Bước 3: Tổng tiền combo = Σ(price × quantity) ────────────────────────

  int get _comboTotal => _combos.fold(
        0,
        (sum, combo) => sum + combo.price * (_quantities[combo.id] ?? 0),
      );

  int get _seatTotal =>
      widget.store.calculateTotal(widget.showtime, widget.selectedSeats, const []);

  int get _grandTotal => _seatTotal + _comboTotal;

  // ── Bước 4: combos: [{comboId, quantity}] — chỉ các combo có quantity > 0 ─

  List<api_models.ComboSelection> get _selections =>
      _quantities.entries
          .where((e) => e.value > 0)
          .map((e) => api_models.ComboSelection(comboId: e.key, quantity: e.value))
          .toList();

  // ── Build ─────────────────────────────────────────────────────────────────

  @override
  Widget build(BuildContext context) {
    final warning = _remaining > Duration.zero &&
        _remaining <= const Duration(minutes: 2);
    final expired = _remaining == Duration.zero;
    final hasSelections = _selections.isNotEmpty;

    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        backgroundColor: Colors.white,
        title: const Text(
          'Chọn combo đồ ăn',
          style: TextStyle(fontWeight: FontWeight.w900),
        ),
      ),
      // ── Bottom bar: tổng tiền + nút tiếp tục ──────────────────────────────
      bottomNavigationBar: SafeArea(
        child: Padding(
          padding: const EdgeInsets.fromLTRB(16, 8, 16, 16),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              // Bước 3: hiển thị tổng tiền realtime
              if (hasSelections) ...[
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                  decoration: BoxDecoration(
                    color: AppColors.pearl,
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Row(
                    children: [
                      const Icon(Icons.fastfood_rounded, size: 18, color: AppColors.muted),
                      const SizedBox(width: 8),
                      Text(
                        'Combo: ${money(_comboTotal)}',
                        style: const TextStyle(fontWeight: FontWeight.w700),
                      ),
                      const Spacer(),
                      Text(
                        'Tổng: ${money(_grandTotal)}',
                        style: const TextStyle(fontWeight: FontWeight.w900),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 8),
              ],
              FilledButton(
                onPressed: expired ? null : _continue,
                style: FilledButton.styleFrom(
                  minimumSize: const Size.fromHeight(54),
                  backgroundColor: Colors.black,
                  disabledBackgroundColor: AppColors.muted,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(10),
                  ),
                ),
                child: Text(
                  hasSelections
                      ? 'Tiếp tục • ${money(_grandTotal)}'
                      : 'Bỏ qua • ${money(_seatTotal)}',
                  style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w900),
                ),
              ),
            ],
          ),
        ),
      ),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          // Hold timer banner
          _HoldTimerBanner(remaining: _remaining, warning: warning),
          const SizedBox(height: 16),

          // Bước 1: loading / error / danh sách combo
          if (_loading)
            const Center(
              child: Padding(
                padding: EdgeInsets.symmetric(vertical: 32),
                child: CircularProgressIndicator(),
              ),
            )
          else if (_error != null)
            _ErrorRetry(message: _error!, onRetry: _loadCombos)
          else if (_combos.isEmpty)
            const _EmptyComboState()
          else ...[
            const _SectionHeader('Combo đồ ăn & thức uống'),
            const SizedBox(height: 10),
            for (final combo in _combos)
              // Bước 2: chọn combo + số lượng
              _ComboTile(
                combo: combo,
                quantity: _quantities[combo.id] ?? 0,
                onChanged: (qty) => setState(() => _quantities[combo.id] = qty),
              ),
          ],
        ],
      ),
    );
  }

  // ── Navigation ────────────────────────────────────────────────────────────

  /// Bước 4: điều hướng sang PaymentScreen kèm combos: [{comboId, quantity}]
  void _continue() {
    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (_) => PaymentScreen(
          store: widget.store,
          movie: widget.movie,
          showtime: widget.showtime,
          selectedSeats: widget.selectedSeats,
          total: _grandTotal,
          hold: widget.hold,
          // Bước 4: gửi kèm combos (rỗng nếu không chọn)
          comboSelections: _selections,
        ),
      ),
    );
  }
}

// ── Widgets ───────────────────────────────────────────────────────────────────

class _HoldTimerBanner extends StatelessWidget {
  const _HoldTimerBanner({required this.remaining, required this.warning});

  final Duration remaining;
  final bool warning;

  @override
  Widget build(BuildContext context) {
    if (remaining == Duration.zero) {
      return Container(
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: const Color(0xFFFFE8E8),
          borderRadius: BorderRadius.circular(8),
        ),
        child: const Row(
          children: [
            Icon(Icons.timer_off_rounded, color: AppColors.danger, size: 18),
            SizedBox(width: 8),
            Text(
              'Thời gian giữ ghế đã hết',
              style: TextStyle(
                color: AppColors.danger,
                fontWeight: FontWeight.w900,
              ),
            ),
          ],
        ),
      );
    }
    final mins = remaining.inMinutes.toString().padLeft(2, '0');
    final secs = (remaining.inSeconds % 60).toString().padLeft(2, '0');
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
      decoration: BoxDecoration(
        color: warning ? const Color(0xFFFFE8E8) : AppColors.pearl,
        borderRadius: BorderRadius.circular(8),
      ),
      child: Row(
        children: [
          Icon(
            Icons.timer_rounded,
            size: 18,
            color: warning ? AppColors.danger : AppColors.muted,
          ),
          const SizedBox(width: 8),
          Text(
            'Ghế giữ còn $mins:$secs',
            style: TextStyle(
              fontWeight: FontWeight.w900,
              color: warning ? AppColors.danger : AppColors.ink,
            ),
          ),
          if (warning) ...[
            const SizedBox(width: 6),
            const Text(
              '• Hãy hoàn tất sớm',
              style: TextStyle(color: AppColors.danger, fontSize: 13),
            ),
          ],
        ],
      ),
    );
  }
}

class _SectionHeader extends StatelessWidget {
  const _SectionHeader(this.title);
  final String title;

  @override
  Widget build(BuildContext context) {
    return Text(
      title,
      style: const TextStyle(fontSize: 18, fontWeight: FontWeight.w900),
    );
  }
}

class _ErrorRetry extends StatelessWidget {
  const _ErrorRetry({required this.message, required this.onRetry});
  final String message;
  final VoidCallback onRetry;

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 32),
        child: Column(
          children: [
            const Icon(Icons.wifi_off_rounded, size: 48, color: AppColors.muted),
            const SizedBox(height: 12),
            Text(message, textAlign: TextAlign.center),
            const SizedBox(height: 16),
            FilledButton.icon(
              onPressed: onRetry,
              icon: const Icon(Icons.refresh_rounded),
              label: const Text('Thử lại'),
              style: FilledButton.styleFrom(backgroundColor: Colors.black),
            ),
          ],
        ),
      ),
    );
  }
}

class _EmptyComboState extends StatelessWidget {
  const _EmptyComboState();

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 48),
        child: Column(
          children: [
            const Icon(Icons.no_food_outlined, size: 56, color: AppColors.muted),
            const SizedBox(height: 12),
            Text(
              'Hiện chưa có combo nào.',
              style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                    color: AppColors.muted,
                  ),
            ),
          ],
        ),
      ),
    );
  }
}

/// Bước 2: tile hiển thị combo + stepper chọn số lượng.
class _ComboTile extends StatelessWidget {
  const _ComboTile({
    required this.combo,
    required this.quantity,
    required this.onChanged,
  });

  final api_models.FoodCombo combo;
  final int quantity;
  final ValueChanged<int> onChanged;

  @override
  Widget build(BuildContext context) {
    final selected = quantity > 0;
    return AnimatedContainer(
      duration: const Duration(milliseconds: 180),
      margin: const EdgeInsets.only(bottom: 12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: selected ? Colors.black : AppColors.line,
          width: selected ? 1.5 : 1,
        ),
        boxShadow: selected ? softShadow(.07) : null,
      ),
      child: Padding(
        padding: const EdgeInsets.all(14),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            // Ảnh combo (CachedNetworkImage hoặc icon fallback)
            ClipRRect(
              borderRadius: BorderRadius.circular(8),
              child: combo.imageUrl.isNotEmpty
                  ? CachedNetworkImage(
                      imageUrl: combo.imageUrl,
                      width: 64,
                      height: 64,
                      fit: BoxFit.cover,
                      placeholder: (_, __) => const _ComboIcon(),
                      errorWidget: (_, __, ___) => const _ComboIcon(),
                    )
                  : const _ComboIcon(),
            ),
            const SizedBox(width: 14),
            // Tên, mô tả, giá
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    combo.name,
                    style: const TextStyle(
                      fontWeight: FontWeight.w900,
                      fontSize: 15,
                    ),
                  ),
                  const SizedBox(height: 3),
                  Text(
                    combo.description,
                    style: const TextStyle(
                      color: AppColors.muted,
                      fontSize: 13,
                    ),
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                  ),
                  const SizedBox(height: 6),
                  // Bước 3: giá × quantity realtime
                  Row(
                    children: [
                      Text(
                        money(combo.price),
                        style: const TextStyle(
                          fontWeight: FontWeight.w900,
                          fontSize: 15,
                        ),
                      ),
                      if (quantity > 1) ...[
                        const SizedBox(width: 6),
                        Text(
                          '× $quantity = ${money(combo.price * quantity)}',
                          style: const TextStyle(
                            color: AppColors.muted,
                            fontSize: 13,
                          ),
                        ),
                      ],
                    ],
                  ),
                ],
              ),
            ),
            const SizedBox(width: 8),
            // Stepper: - qty +
            Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                _StepperButton(
                  icon: Icons.remove_circle_outline,
                  enabled: quantity > 0,
                  onTap: () => onChanged(quantity - 1),
                ),
                SizedBox(
                  width: 32,
                  child: Text(
                    '$quantity',
                    textAlign: TextAlign.center,
                    style: const TextStyle(
                      fontWeight: FontWeight.w900,
                      fontSize: 18,
                    ),
                  ),
                ),
                _StepperButton(
                  icon: Icons.add_circle_outline,
                  // Không cho phép vượt quá tồn kho
                  enabled: quantity < combo.quantity,
                  onTap: () => onChanged(quantity + 1),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

class _StepperButton extends StatelessWidget {
  const _StepperButton({
    required this.icon,
    required this.enabled,
    required this.onTap,
  });

  final IconData icon;
  final bool enabled;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: enabled ? onTap : null,
      child: Icon(
        icon,
        size: 30,
        color: enabled ? Colors.black : AppColors.line,
      ),
    );
  }
}

class _ComboIcon extends StatelessWidget {
  const _ComboIcon();

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 64,
      height: 64,
      color: AppColors.pearl,
      child: const Icon(Icons.fastfood_rounded, size: 36, color: AppColors.muted),
    );
  }
}
