import 'dart:async';

import 'package:flutter/material.dart';

import '../../../api/api_client.dart';
import '../../../models/booking_models.dart' as api_models;
import '../../core/app_theme.dart';
import '../../core/formatters.dart';
import '../../models/app_models.dart';
import '../../state/cinema_store.dart';
import 'payment_screen.dart';

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
  Timer? _timer;
  Duration _remaining = Duration.zero;
  bool _loading = true;
  String? _error;

  @override
  void initState() {
    super.initState();
    _loadCombos();
    _tick();
    _timer = Timer.periodic(const Duration(seconds: 1), (_) => _tick());
  }

  @override
  void dispose() {
    _timer?.cancel();
    super.dispose();
  }

  Future<void> _loadCombos() async {
    try {
      final combos = await _apiClient.getFoodCombos();
      if (mounted) setState(() => _combos = combos);
    } catch (_) {
      if (mounted) setState(() => _error = 'Không thể tải danh sách combo.');
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  void _tick() {
    final remaining = widget.hold.expiresAt.difference(DateTime.now());
    if (remaining <= Duration.zero) {
      _timer?.cancel();
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
                Navigator.of(context).pop();
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

  int get _comboTotal => _combos.fold(
    0,
    (sum, combo) => sum + combo.price * (_quantities[combo.id] ?? 0),
  );

  int get _seatTotal => widget.store.calculateTotal(
    widget.showtime,
    widget.selectedSeats,
    const [],
  );

  List<api_models.ComboSelection> get _selections => _quantities.entries
      .where((entry) => entry.value > 0)
      .map(
        (entry) => api_models.ComboSelection(
          comboId: entry.key,
          quantity: entry.value,
        ),
      )
      .toList();

  @override
  Widget build(BuildContext context) {
    final warning = _remaining <= const Duration(minutes: 2);
    return Scaffold(
      appBar: AppBar(title: const Text('Chọn combo')),
      bottomNavigationBar: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: FilledButton(
            onPressed: _remaining == Duration.zero ? null : _continue,
            style: FilledButton.styleFrom(
              minimumSize: const Size.fromHeight(54),
              backgroundColor: Colors.black,
            ),
            child: Text('Tiếp tục • ${money(_seatTotal + _comboTotal)}'),
          ),
        ),
      ),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: warning ? const Color(0xFFFFE8E8) : AppColors.pearl,
              borderRadius: BorderRadius.circular(8),
            ),
            child: Text(
              'Giữ ghế còn ${_formatDuration(_remaining)}'
              '${warning ? ' • Hãy hoàn tất sớm' : ''}',
              style: const TextStyle(fontWeight: FontWeight.w900),
            ),
          ),
          const SizedBox(height: 16),
          if (_loading) const Center(child: CircularProgressIndicator()),
          if (_error != null)
            Center(
              child: TextButton(onPressed: _loadCombos, child: Text(_error!)),
            ),
          for (final combo in _combos)
            _ComboTile(
              combo: combo,
              quantity: _quantities[combo.id] ?? 0,
              onChanged: (quantity) {
                setState(() => _quantities[combo.id] = quantity);
              },
            ),
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
          total: _seatTotal + _comboTotal,
          hold: widget.hold,
          comboSelections: _selections,
        ),
      ),
    );
  }

  String _formatDuration(Duration duration) {
    final minutes = duration.inMinutes.toString().padLeft(2, '0');
    final seconds = (duration.inSeconds % 60).toString().padLeft(2, '0');
    return '$minutes:$seconds';
  }
}

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
    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      child: Padding(
        padding: const EdgeInsets.all(14),
        child: Row(
          children: [
            const Icon(Icons.fastfood_rounded, size: 42),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    combo.name,
                    style: const TextStyle(fontWeight: FontWeight.w900),
                  ),
                  Text(combo.description),
                  Text(
                    money(combo.price),
                    style: const TextStyle(fontWeight: FontWeight.w900),
                  ),
                ],
              ),
            ),
            IconButton(
              onPressed: quantity == 0 ? null : () => onChanged(quantity - 1),
              icon: const Icon(Icons.remove_circle_outline),
            ),
            Text(
              '$quantity',
              style: const TextStyle(fontWeight: FontWeight.w900),
            ),
            IconButton(
              onPressed: () => onChanged(quantity + 1),
              icon: const Icon(Icons.add_circle_outline),
            ),
          ],
        ),
      ),
    );
  }
}
