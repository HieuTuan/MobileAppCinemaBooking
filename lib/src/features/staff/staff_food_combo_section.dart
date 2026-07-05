import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

import '../../../api/api_client.dart';
import '../../../models/admin_models.dart';
import '../../core/app_theme.dart';
import '../../shared/widgets/glass_card.dart';

class StaffFoodComboSection extends StatefulWidget {
  const StaffFoodComboSection({super.key, this.showTitle = true});

  final bool showTitle;

  @override
  State<StaffFoodComboSection> createState() => _StaffFoodComboSectionState();
}

class _StaffFoodComboSectionState extends State<StaffFoodComboSection> {
  final _api = APIClient();
  final _money = NumberFormat.decimalPattern('vi');

  List<AdminFoodCombo> _combos = const [];
  bool _loading = false;

  @override
  void initState() {
    super.initState();
    _loadCombos();
  }

  Future<void> _loadCombos() async {
    setState(() => _loading = true);
    try {
      final combos = await _api.staffGetFoodCombos();
      if (mounted) setState(() => _combos = combos);
    } catch (e) {
      _showSnack('Không thể tải combo: ${_errorMsg(e)}', isError: true);
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  Future<void> _toggleCombo(AdminFoodCombo combo) async {
    try {
      final updated = await _api.staffUpdateFoodComboStatus(
        combo.id,
        isActive: !combo.isActive,
      );
      if (!mounted) return;
      setState(() {
        _combos = _combos
            .map((item) => item.id == updated.id ? updated : item)
            .toList();
      });
      _showSnack(updated.isActive ? 'Đã mở bán combo' : 'Đã tạm ngưng combo');
    } catch (e) {
      _showSnack(
        'Không thể cập nhật trạng thái: ${_errorMsg(e)}',
        isError: true,
      );
    }
  }

  void _showSnack(String message, {bool isError = false}) {
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: isError ? Colors.redAccent : AppColors.success,
        behavior: SnackBarBehavior.floating,
      ),
    );
  }

  String _errorMsg(Object e) => e.toString().replaceFirst('Exception: ', '');

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        if (widget.showTitle)
          SectionTitle(
            title: 'Trạng thái bắp nước',
            action: IconButton(
              tooltip: 'Tải lại',
              onPressed: _loading ? null : _loadCombos,
              icon: const Icon(Icons.refresh_rounded),
            ),
          ),
        if (_loading)
          const Padding(
            padding: EdgeInsets.symmetric(vertical: 24),
            child: Center(child: CircularProgressIndicator()),
          )
        else if (_combos.isEmpty)
          const GlassCard(
            child: Padding(
              padding: EdgeInsets.all(16),
              child: Text(
                'Chưa có combo đồ ăn.',
                style: TextStyle(color: AppColors.muted),
              ),
            ),
          )
        else
          ..._combos.map(
            (combo) => GlassCard(
              margin: const EdgeInsets.only(bottom: 12),
              child: Row(
                children: [
                  Container(
                    width: 44,
                    height: 44,
                    decoration: BoxDecoration(
                      color: combo.isActive
                          ? const Color(0xFFF59E0B).withValues(alpha: 0.12)
                          : Colors.grey.withValues(alpha: 0.12),
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: Icon(
                      Icons.fastfood_rounded,
                      color: combo.isActive
                          ? const Color(0xFFF59E0B)
                          : AppColors.muted,
                      size: 20,
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          combo.name,
                          style: const TextStyle(
                            fontWeight: FontWeight.w900,
                            fontSize: 15,
                            color: AppColors.ink,
                          ),
                        ),
                        const SizedBox(height: 4),
                        Row(
                          children: [
                            Text(
                              '${_money.format(combo.price)} đ',
                              style: const TextStyle(
                                fontSize: 13,
                                fontWeight: FontWeight.w800,
                                color: Color(0xFFEF4444),
                              ),
                            ),
                            const SizedBox(width: 8),
                            _FoodStatusBadge(quantity: combo.quantity),
                          ],
                        ),
                      ],
                    ),
                  ),
                  Switch(
                    value: combo.isActive,
                    onChanged: (_) => _toggleCombo(combo),
                    activeThumbColor: const Color(0xFF10B981),
                  ),
                ],
              ),
            ),
          ),
      ],
    );
  }
}

class _FoodStatusBadge extends StatelessWidget {
  const _FoodStatusBadge({required this.quantity});
  final int quantity;

  @override
  Widget build(BuildContext context) {
    Color bgColor;
    Color textColor;
    String label;

    if (quantity == 0) {
      bgColor = const Color(0xFFEF4444).withValues(alpha: 0.12);
      textColor = const Color(0xFFB91C1C);
      label = 'Hết hàng';
    } else if (quantity < 10) {
      bgColor = const Color(0xFFF59E0B).withValues(alpha: 0.12);
      textColor = const Color(0xFFB45309);
      label = 'Sắp hết: $quantity';
    } else {
      bgColor = const Color(0xFF10B981).withValues(alpha: 0.12);
      textColor = const Color(0xFF047857);
      label = 'Còn lại: $quantity';
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
          fontSize: 10,
          fontWeight: FontWeight.w900,
          color: textColor,
        ),
      ),
    );
  }
}
