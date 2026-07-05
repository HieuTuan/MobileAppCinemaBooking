import 'dart:async';

import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';

import '../../../api/api_client.dart';
import '../../../models/booking_models.dart' as api_models;
import '../../core/formatters.dart';
import '../../models/app_models.dart';
import '../../state/cinema_store.dart';
import 'payment_screen.dart';

// ── Premium Light Theme Colors ────────────────────────────────────────────────
const _kLightBg      = Color(0xFFF8FAFC); // Clean off-white
const _kCardBg       = Colors.white;
const _kGold         = Color(0xFFC9A44C);
const _kGoldSoft     = Color(0xFFFDFBF7);
const _kDarkText     = Color(0xFF0F172A); // Deep slate black
const _kMutedText    = Color(0xFF64748B); // Slate gray
const _kBorder       = Color(0xFFE2E8F0); // Light gray border
const _kRed          = Color(0xFFD04747);
const _kRedSoft      = Color(0xFFFFEEEE);

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
  final Map<String, int> _quantities = {};
  List<api_models.FoodCombo> _combos = const [];
  Timer? _holdTimer;
  Duration _remaining = Duration.zero;
  bool _loading = true;
  String? _error;

  @override
  void initState() {
    super.initState();
    _loadCombos();
    _tick();
    _holdTimer = Timer.periodic(const Duration(seconds: 1), (_) => _tick());
  }

  @override
  void dispose() {
    _holdTimer?.cancel();
    super.dispose();
  }

  Future<void> _loadCombos() async {
    setState(() {
      _loading = true;
      _error = null;
    });
    try {
      final combos = await _apiClient.getFoodCombos();
      if (mounted) {
        setState(() {
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
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
          backgroundColor: Colors.white,
          title: const Text(
            'Hết thời gian giữ ghế',
            style: TextStyle(color: _kDarkText, fontWeight: FontWeight.w900),
          ),
          content: const Text(
            'Phiên giữ ghế đã hết hạn. Vui lòng thực hiện chọn lại ghế.',
            style: TextStyle(color: _kMutedText),
          ),
          actions: [
            FilledButton(
              onPressed: () {
                Navigator.of(context).pop();
                Navigator.of(context).pop();
              },
              style: FilledButton.styleFrom(backgroundColor: _kDarkText),
              child: const Text('Chọn lại ghế', style: TextStyle(fontWeight: FontWeight.w800)),
            ),
          ],
        ),
      );
      return;
    }
    if (mounted) setState(() => _remaining = remaining);
  }

  int get _comboTotal => _combos.fold(
        0,
        (sum, combo) => sum + combo.price * (_quantities[combo.id] ?? 0),
      );

  int get _seatTotal =>
      widget.store.calculateTotal(widget.showtime, widget.selectedSeats, const []);

  int get _grandTotal => _seatTotal + _comboTotal;

  List<api_models.ComboSelection> get _selections =>
      _quantities.entries
          .where((e) => e.value > 0)
          .map((e) => api_models.ComboSelection(comboId: e.key, quantity: e.value))
          .toList();

  @override
  Widget build(BuildContext context) {
    final warning = _remaining > Duration.zero &&
        _remaining <= const Duration(minutes: 2);
    final expired = _remaining == Duration.zero;
    final hasSelections = _selections.isNotEmpty;

    return Scaffold(
      backgroundColor: _kLightBg,
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        scrolledUnderElevation: 0,
        iconTheme: const IconThemeData(color: _kDarkText),
        title: const Text(
          'Dịch vụ bắp nước',
          style: TextStyle(
            color: _kDarkText,
            fontWeight: FontWeight.w900,
            fontSize: 20,
            letterSpacing: 0.3,
          ),
        ),
      ),
      bottomNavigationBar: SafeArea(
        child: Container(
          decoration: const BoxDecoration(
            color: Colors.white,
            border: Border(top: BorderSide(color: _kBorder)),
          ),
          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              // Ticket details row
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text(
                        'Ghế đã chọn',
                        style: TextStyle(color: _kMutedText, fontSize: 11, fontWeight: FontWeight.w600),
                      ),
                      const SizedBox(height: 3),
                      Text(
                        '${widget.selectedSeats.length} vé (${widget.selectedSeats.join(', ')})',
                        style: const TextStyle(
                          color: _kDarkText,
                          fontSize: 14,
                          fontWeight: FontWeight.w800,
                        ),
                      ),
                    ],
                  ),
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.end,
                    children: [
                      const Text(
                        'Tổng cộng',
                        style: TextStyle(color: _kMutedText, fontSize: 11, fontWeight: FontWeight.w600),
                      ),
                      const SizedBox(height: 3),
                      Text(
                        money(_grandTotal),
                        style: const TextStyle(
                          color: _kDarkText,
                          fontSize: 18,
                          fontWeight: FontWeight.w900,
                        ),
                      ),
                    ],
                  ),
                ],
              ),
              if (hasSelections) ...[
                const SizedBox(height: 10),
                // Breakdown row
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                  decoration: BoxDecoration(
                    color: _kLightBg,
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(color: _kBorder),
                  ),
                  child: Row(
                    children: [
                      const Icon(Icons.fastfood_rounded, size: 14, color: _kMutedText),
                      const SizedBox(width: 6),
                      const Text(
                        'Tiền bắp nước:',
                        style: TextStyle(color: _kMutedText, fontSize: 12, fontWeight: FontWeight.w500),
                      ),
                      const SizedBox(width: 4),
                      Text(
                        money(_comboTotal),
                        style: const TextStyle(
                          color: _kDarkText,
                          fontSize: 12,
                          fontWeight: FontWeight.w800,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
              const SizedBox(height: 14),
              FilledButton(
                onPressed: expired ? null : _continue,
                style: FilledButton.styleFrom(
                  minimumSize: const Size.fromHeight(50),
                  backgroundColor: _kDarkText,
                  disabledBackgroundColor: _kBorder,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
                child: Text(
                  hasSelections
                      ? 'Thanh toán ngay · ${money(_grandTotal)}'
                      : 'Bỏ qua & Tiếp tục',
                  style: const TextStyle(
                    fontSize: 15,
                    fontWeight: FontWeight.w900,
                    color: Colors.white,
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
      body: ListView(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        children: [
          // Hold timer banner
          _HoldTimerBanner(remaining: _remaining, warning: warning),
          const SizedBox(height: 16),

          // Load state
          if (_loading)
            const Center(
              child: Padding(
                padding: EdgeInsets.symmetric(vertical: 48),
                child: CircularProgressIndicator(color: _kDarkText),
              ),
            )
          else if (_error != null)
            _ErrorRetry(message: _error!, onRetry: _loadCombos)
          else if (_combos.isEmpty)
            const _EmptyComboState()
          else ...[
            const Row(
              children: [
                Icon(Icons.fastfood_rounded, color: _kGold, size: 18),
                SizedBox(width: 8),
                Text(
                  'Chọn bắp & nước uống',
                  style: TextStyle(
                    color: _kDarkText,
                    fontSize: 16,
                    fontWeight: FontWeight.w900,
                    letterSpacing: 0.2,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            for (final combo in _combos)
              _ComboCard(
                combo: combo,
                quantity: _quantities[combo.id] ?? 0,
                onChanged: (qty) => setState(() => _quantities[combo.id] = qty),
              ),
          ],
        ],
      ),
    );
  }

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
          comboSelections: _selections,
        ),
      ),
    );
  }
}

// ═════════════════════════════════════════════════════════════════════════════
// HOLD TIMER BANNER
// ═════════════════════════════════════════════════════════════════════════════

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
          color: _kRedSoft,
          borderRadius: BorderRadius.circular(10),
          border: Border.all(color: _kRed.withValues(alpha: .5)),
        ),
        child: const Row(
          children: [
            Icon(Icons.timer_off_rounded, color: _kRed, size: 18),
            SizedBox(width: 8),
            Text(
              'Đã hết thời gian giữ ghế',
              style: TextStyle(
                color: _kRed,
                fontWeight: FontWeight.w900,
                fontSize: 13,
              ),
            ),
          ],
        ),
      );
    }
    final mins = remaining.inMinutes.toString().padLeft(2, '0');
    final secs = (remaining.inSeconds % 60).toString().padLeft(2, '0');
    final color = warning ? _kRed : _kGold;
    final bg = warning ? _kRedSoft : Colors.white;
    final border = warning ? _kRed.withValues(alpha: .4) : _kBorder;

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 11),
      decoration: BoxDecoration(
        color: bg,
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: border),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: .02),
            blurRadius: 10,
            offset: const Offset(0, 4),
          )
        ],
      ),
      child: Row(
        children: [
          Icon(
            Icons.timer_rounded,
            size: 16,
            color: color,
          ),
          const SizedBox(width: 8),
          Text(
            'Thời gian thanh toán còn $mins:$secs',
            style: TextStyle(
              fontWeight: FontWeight.w800,
              color: color,
              fontSize: 13,
            ),
          ),
          const Spacer(),
          Text(
            warning ? 'Hoàn tất nhanh!' : 'Giữ ghế',
            style: TextStyle(
              color: warning ? _kRed : _kMutedText,
              fontSize: 11,
              fontWeight: FontWeight.w800,
            ),
          ),
        ],
      ),
    );
  }
}

// ═════════════════════════════════════════════════════════════════════════════
// COMBO CARD
// ═════════════════════════════════════════════════════════════════════════════

class _ComboCard extends StatelessWidget {
  const _ComboCard({
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
      duration: const Duration(milliseconds: 200),
      margin: const EdgeInsets.only(bottom: 12),
      decoration: BoxDecoration(
        color: selected ? _kGoldSoft : _kCardBg,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: selected ? _kGold : _kBorder,
          width: selected ? 1.5 : 1,
        ),
        boxShadow: [
          BoxShadow(
            color: selected ? _kGold.withValues(alpha: .06) : Colors.black.withValues(alpha: .03),
            blurRadius: 12,
            offset: const Offset(0, 6),
          )
        ],
      ),
      child: Padding(
        padding: const EdgeInsets.all(14),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            // Image with rounded corners
            ClipRRect(
              borderRadius: BorderRadius.circular(10),
              child: combo.imageUrl.isNotEmpty
                  ? CachedNetworkImage(
                      imageUrl: combo.imageUrl,
                      width: 72,
                      height: 72,
                      fit: BoxFit.cover,
                      placeholder: (_, __) => const _ComboIconFallback(),
                      errorWidget: (_, __, ___) => const _ComboIconFallback(),
                    )
                  : const _ComboIconFallback(),
            ),
            const SizedBox(width: 14),
            // Information
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    combo.name,
                    style: const TextStyle(
                      color: _kDarkText,
                      fontWeight: FontWeight.w900,
                      fontSize: 14,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    combo.description,
                    style: const TextStyle(
                      color: _kMutedText,
                      fontSize: 12,
                    ),
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                  ),
                  const SizedBox(height: 8),
                  // Price row
                  Wrap(
                    crossAxisAlignment: WrapCrossAlignment.center,
                    spacing: 8,
                    runSpacing: 4,
                    children: [
                      Text(
                        money(combo.price),
                        style: const TextStyle(
                          color: _kGold,
                          fontWeight: FontWeight.w900,
                          fontSize: 14,
                        ),
                      ),
                      if (quantity > 1)
                        Text(
                          '× $quantity = ${money(combo.price * quantity)}',
                          style: const TextStyle(
                            color: _kMutedText,
                            fontSize: 11,
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                    ],
                  ),
                ],
              ),
            ),
            const SizedBox(width: 10),
            // Stepper controls
            Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                _StepperBtn(
                  icon: Icons.remove_rounded,
                  enabled: quantity > 0,
                  onTap: () => onChanged(quantity - 1),
                ),
                SizedBox(
                  width: 30,
                  child: Text(
                    '$quantity',
                    textAlign: TextAlign.center,
                    style: const TextStyle(
                      color: _kDarkText,
                      fontWeight: FontWeight.w900,
                      fontSize: 16,
                    ),
                  ),
                ),
                _StepperBtn(
                  icon: Icons.add_rounded,
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

class _StepperBtn extends StatelessWidget {
  const _StepperBtn({
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
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 150),
        width: 28,
        height: 28,
        decoration: BoxDecoration(
          color: enabled ? _kDarkText.withValues(alpha: .04) : Colors.transparent,
          shape: BoxShape.circle,
          border: Border.all(
            color: enabled ? _kDarkText.withValues(alpha: .35) : _kBorder,
          ),
        ),
        alignment: Alignment.center,
        child: Icon(
          icon,
          size: 16,
          color: enabled ? _kDarkText : _kMutedText.withValues(alpha: .4),
        ),
      ),
    );
  }
}

class _ComboIconFallback extends StatelessWidget {
  const _ComboIconFallback();

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 72,
      height: 72,
      color: _kLightBg,
      alignment: Alignment.center,
      child: const Icon(Icons.fastfood_rounded, size: 30, color: _kMutedText),
    );
  }
}

// ═════════════════════════════════════════════════════════════════════════════
// HELPER STATES
// ═════════════════════════════════════════════════════════════════════════════

class _EmptyComboState extends StatelessWidget {
  const _EmptyComboState();

  @override
  Widget build(BuildContext context) {
    return const Center(
      child: Padding(
        padding: EdgeInsets.symmetric(vertical: 60),
        child: Column(
          children: [
            Icon(Icons.no_food_outlined, size: 48, color: _kMutedText),
            SizedBox(height: 12),
            Text(
              'Hiện chưa có combo bắp nước nào',
              style: TextStyle(color: _kMutedText, fontSize: 14),
            ),
          ],
        ),
      ),
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
        padding: const EdgeInsets.symmetric(vertical: 48),
        child: Column(
          children: [
            const Icon(Icons.wifi_off_rounded, size: 48, color: _kMutedText),
            const SizedBox(height: 12),
            Text(
              message,
              textAlign: TextAlign.center,
              style: const TextStyle(color: _kMutedText),
            ),
            const SizedBox(height: 16),
            ElevatedButton.icon(
              onPressed: onRetry,
              icon: const Icon(Icons.refresh_rounded),
              label: const Text('Thử lại'),
              style: ElevatedButton.styleFrom(
                backgroundColor: _kDarkText,
                foregroundColor: Colors.white,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(10),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
