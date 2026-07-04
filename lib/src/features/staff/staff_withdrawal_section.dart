import 'dart:async';

import 'package:flutter/material.dart';

import '../../../api/api_client.dart';
import '../../../models/wallet_models.dart';
import '../../core/app_theme.dart';
import '../../core/formatters.dart';

class StaffWithdrawalSection extends StatefulWidget {
  const StaffWithdrawalSection({super.key});

  @override
  State<StaffWithdrawalSection> createState() => _StaffWithdrawalSectionState();
}

class _StaffWithdrawalSectionState extends State<StaffWithdrawalSection> {
  final _api = APIClient();
  bool _loading = true;
  String? _error;
  List<WithdrawalRequest> _requests = [];

  @override
  void initState() {
    super.initState();
    _fetch();
  }

  Future<void> _fetch() async {
    if (!mounted) return;
    setState(() {
      _loading = true;
      _error = null;
    });
    try {
      final reqs = await _api.staffGetWithdrawalRequests();
      reqs.sort(
        (a, b) => _withdrawalActivityTime(b).compareTo(
          _withdrawalActivityTime(a),
        ),
      );
      if (!mounted) return;
      setState(() {
        _requests = reqs;
        _loading = false;
      });
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _error = 'Lỗi tải danh sách: $e';
        _loading = false;
      });
    }
  }

  DateTime _withdrawalActivityTime(WithdrawalRequest request) {
    return request.processedAt ?? request.requestedAt;
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.fromLTRB(0, 8, 0, 12),
          child: Row(
            children: [
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: AppColors.primary.withValues(alpha: .1),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: const Icon(
                  Icons.account_balance_rounded,
                  color: AppColors.primary,
                  size: 20,
                ),
              ),
              const SizedBox(width: 10),
              const Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Xử lý rút tiền',
                    style: TextStyle(fontSize: 16, fontWeight: FontWeight.w900),
                  ),
                  Text(
                    'Chuyển khoản và xác nhận rút tiền từ ví',
                    style: TextStyle(fontSize: 12, color: AppColors.muted),
                  ),
                ],
              ),
            ],
          ),
        ),
        if (_loading)
          const Center(
            child: Padding(
              padding: EdgeInsets.all(24),
              child: CircularProgressIndicator(),
            ),
          )
        else if (_error != null)
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: AppColors.danger.withValues(alpha: .1),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Text(
              _error!,
              style: const TextStyle(color: AppColors.danger),
            ),
          )
        else if (_requests.isEmpty)
          const Center(
            child: Padding(
              padding: EdgeInsets.all(24),
              child: Text(
                'Không có yêu cầu rút tiền nào đang chờ xử lý',
                style: TextStyle(color: AppColors.muted),
              ),
            ),
          )
        else
          ..._requests.map(
            (req) =>
                _WithdrawalCard(request: req, api: _api, onProcessed: _fetch),
          ),
      ],
    );
  }
}

class _WithdrawalCard extends StatefulWidget {
  const _WithdrawalCard({
    required this.request,
    required this.api,
    required this.onProcessed,
  });

  final WithdrawalRequest request;
  final APIClient api;
  final Future<void> Function() onProcessed;

  @override
  State<_WithdrawalCard> createState() => _WithdrawalCardState();
}

class _WithdrawalCardState extends State<_WithdrawalCard> {
  bool _processing = false;

  @override
  Widget build(BuildContext context) {
    final req = widget.request;
    final isPending = req.status == 'PENDING';
    final statusColor = switch (req.status) {
      'COMPLETED' => AppColors.success,
      'REJECTED' => AppColors.danger,
      _ => AppColors.warning,
    };
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AppColors.line),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: .03),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                shortDate(req.processedAt ?? req.requestedAt),
                style: const TextStyle(color: AppColors.muted, fontSize: 13),
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                decoration: BoxDecoration(
                  color: statusColor.withValues(alpha: .1),
                  borderRadius: BorderRadius.circular(4),
                ),
                child: Text(
                  req.statusLabel,
                  style: TextStyle(
                    color: statusColor,
                    fontSize: 12,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Text(
            money(req.amount),
            style: const TextStyle(
              fontSize: 24,
              fontWeight: FontWeight.w900,
              color: AppColors.primary,
            ),
          ),
          const SizedBox(height: 12),
          _InfoRow('Ngân hàng', req.bankName),
          const SizedBox(height: 4),
          _InfoRow('Số tài khoản', req.accountNumber),
          const SizedBox(height: 4),
          _InfoRow('Chủ tài khoản', req.accountHolder),
          const SizedBox(height: 4),
          _InfoRow('Người yêu cầu', req.userName ?? req.userId),
          if (req.note != null && req.note!.trim().isNotEmpty) ...[
            const SizedBox(height: 4),
            _InfoRow('Ghi chu', req.note!.trim()),
          ],
          const SizedBox(height: 16),
          Row(
            children: [
              Expanded(
                child: OutlinedButton(
                  onPressed:
                      _processing || !isPending ? null : () => _reject(context),
                  style: OutlinedButton.styleFrom(
                    foregroundColor: AppColors.danger,
                    side: BorderSide(
                      color: AppColors.danger.withValues(alpha: .5),
                    ),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(8),
                    ),
                  ),
                  child: const Text('Từ chối'),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: FilledButton(
                  onPressed: _processing || !isPending
                      ? null
                      : () => _approve(context),
                  style: FilledButton.styleFrom(
                    backgroundColor: AppColors.primary,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(8),
                    ),
                  ),
                  child: _processing
                      ? const SizedBox(
                          width: 16,
                          height: 16,
                          child: CircularProgressIndicator(
                            strokeWidth: 2,
                            color: Colors.white,
                          ),
                        )
                      : const Text('Đã chuyển khoản'),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Future<void> _approve(BuildContext context) async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Xác nhận đã chuyển khoản'),
        content: Text(
          'Bạn đã chuyển ${money(widget.request.amount)} đến tài khoản '
          '${widget.request.accountNumber} (${widget.request.bankName}) chưa?',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: const Text('Chưa'),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(ctx, true),
            child: const Text('Đã chuyển'),
          ),
        ],
      ),
    );
    if (confirm != true || !context.mounted) return;

    setState(() => _processing = true);
    try {
      await widget.api
          .staffCompleteWithdrawal(widget.request.id)
          .timeout(const Duration(seconds: 15));
      if (!context.mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Đã xác nhận chuyển khoản thành công'),
          backgroundColor: AppColors.success,
        ),
      );
      await widget.onProcessed();
    } catch (e) {
      if (!context.mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Lỗi: ${_actionErrorMessage(e)}'),
          backgroundColor: AppColors.danger,
        ),
      );
    } finally {
      if (mounted) setState(() => _processing = false);
    }
  }

  Future<void> _reject(BuildContext context) async {
    final reasonCtrl = TextEditingController();
    try {
      final confirm = await showDialog<bool>(
        context: context,
        builder: (ctx) => AlertDialog(
          title: const Text('Từ chối rút tiền'),
          content: TextField(
            controller: reasonCtrl,
            decoration: const InputDecoration(
              hintText: 'Lý do từ chối (tùy chọn)',
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(ctx, false),
              child: const Text('Hủy'),
            ),
            FilledButton(
              onPressed: () => Navigator.pop(ctx, true),
              style: FilledButton.styleFrom(backgroundColor: AppColors.danger),
              child: const Text('Từ chối'),
            ),
          ],
        ),
      );
      if (confirm != true || !context.mounted) return;

      setState(() => _processing = true);
      try {
        await widget.api
            .staffRejectWithdrawal(widget.request.id, reasonCtrl.text.trim())
            .timeout(const Duration(seconds: 15));
        if (!context.mounted) return;
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Đã từ chối và hoàn tiền vào ví khách'),
            backgroundColor: AppColors.success,
          ),
        );
        await widget.onProcessed();
      } catch (e) {
        if (!context.mounted) return;
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Lỗi: ${_actionErrorMessage(e)}'),
            backgroundColor: AppColors.danger,
          ),
        );
      } finally {
        if (mounted) setState(() => _processing = false);
      }
    } finally {
      reasonCtrl.dispose();
    }
  }

  String _actionErrorMessage(Object error) {
    if (error is TimeoutException) {
      return 'Quá thời gian chờ phản hồi. Vui lòng tải lại danh sách để kiểm tra trạng thái.';
    }
    return error.toString();
  }
}

class _InfoRow extends StatelessWidget {
  const _InfoRow(this.label, this.value);

  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        SizedBox(
          width: 100,
          child: Text(
            label,
            style: const TextStyle(color: AppColors.muted, fontSize: 13),
          ),
        ),
        Expanded(
          child: Text(
            value,
            style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 13),
          ),
        ),
      ],
    );
  }
}
