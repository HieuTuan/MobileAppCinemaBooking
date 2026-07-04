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
              margin: const EdgeInsets.only(bottom: 10),
              child: Row(
                children: [
                  Container(
                    width: 44,
                    height: 44,
                    decoration: BoxDecoration(
                      color: combo.isActive
                          ? AppColors.gold.withValues(alpha: .16)
                          : Colors.grey.withValues(alpha: .14),
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: Icon(
                      Icons.fastfood_rounded,
                      color: combo.isActive ? AppColors.gold : AppColors.muted,
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          combo.name,
                          style: const TextStyle(fontWeight: FontWeight.w900),
                        ),
                        const SizedBox(height: 3),
                        Text(
                          '${_money.format(combo.price)} VND • Còn ${combo.quantity}',
                          style: Theme.of(context).textTheme.bodySmall
                              ?.copyWith(
                                color: combo.quantity == 0
                                    ? Colors.redAccent
                                    : AppColors.muted,
                                fontWeight: FontWeight.w700,
                              ),
                        ),
                      ],
                    ),
                  ),
                  Switch(
                    value: combo.isActive,
                    onChanged: (_) => _toggleCombo(combo),
                  ),
                ],
              ),
            ),
          ),
      ],
    );
  }
}
