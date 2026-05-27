import 'package:cine_book/core/constants/app_colors.dart';
import 'package:cine_book/router/app_router.dart';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';

class OrderSummaryScreen extends StatefulWidget {
  final String showtimeId;
  final List<String> seatIds;

  const OrderSummaryScreen({
    super.key,
    required this.showtimeId,
    required this.seatIds,
  });

  @override
  State<OrderSummaryScreen> createState() => _OrderSummaryScreenState();
}

class _OrderSummaryScreenState extends State<OrderSummaryScreen> {
  String _selectedPaymentMethod = 'momo';
  bool _isProcessing = false;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.backgroundDark,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        title: const Text('Tóm tắt đơn hàng'),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _buildOrderDetails(),
            const SizedBox(height: 24),
            _buildPriceBreakdown(),
            const SizedBox(height: 24),
            const Text(
              'Phương thức thanh toán',
              style: TextStyle(color: Colors.white, fontSize: 18, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 12),
            _buildPaymentMethod('momo', 'Ví MoMo', Icons.account_balance_wallet, Colors.pink),
            _buildPaymentMethod('vnpay', 'VNPay', Icons.payment, Colors.blue),
            _buildPaymentMethod('zalopay', 'ZaloPay', Icons.account_balance, Colors.green),
          ],
        ),
      ),
      bottomNavigationBar: _buildPayButton(),
    );
  }

  Widget _buildOrderDetails() {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.grey[900],
        borderRadius: BorderRadius.circular(16),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'THÔNG TIN VÉ',
            style: TextStyle(color: AppColors.primary, fontWeight: FontWeight.bold, fontSize: 12),
          ),
          const SizedBox(height: 12),
          const Text(
            'Avengers: Endgame',
            style: TextStyle(color: Colors.white, fontSize: 18, fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 4),
          const Text(
            'CGV Vincom Center - Cinema 3',
            style: TextStyle(color: Colors.grey, fontSize: 14),
          ),
          const SizedBox(height: 8),
          Row(
            children: [
              const Icon(Icons.calendar_today, color: Colors.grey, size: 14),
              const SizedBox(width: 4),
              const Text('Hôm nay, 27/05/2026', style: TextStyle(color: Colors.white, fontSize: 14)),
              const SizedBox(width: 16),
              const Icon(Icons.access_time, color: Colors.grey, size: 14),
              const SizedBox(width: 4),
              const Text('19:30', style: TextStyle(color: Colors.white, fontSize: 14)),
            ],
          ),
          const Divider(color: Colors.white10, height: 24),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Text('Ghế đã chọn', style: TextStyle(color: Colors.grey)),
              Text(
                widget.seatIds.join(', '),
                style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildPriceBreakdown() {
    final int subtotal = widget.seatIds.length * 90000;
    const int discount = 0;
    final int total = subtotal - discount;

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.grey[900],
        borderRadius: BorderRadius.circular(16),
      ),
      child: Column(
        children: [
          _buildPriceRow('Tạm tính', subtotal),
          const SizedBox(height: 8),
          _buildPriceRow('Giảm giá', discount, isDiscount: true),
          const Divider(color: Colors.white10, height: 24),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Text('Tổng cộng', style: TextStyle(color: Colors.white, fontSize: 16, fontWeight: FontWeight.bold)),
              Text(
                NumberFormat.currency(locale: 'vi_VN', symbol: 'đ', decimalDigits: 0).format(total),
                style: const TextStyle(color: AppColors.primary, fontSize: 20, fontWeight: FontWeight.bold),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildPriceRow(String label, int amount, {bool isDiscount = false}) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(label, style: const TextStyle(color: Colors.grey)),
        Text(
          '${isDiscount ? '-' : ''}${NumberFormat.currency(locale: 'vi_VN', symbol: 'đ', decimalDigits: 0).format(amount)}',
          style: TextStyle(color: isDiscount ? Colors.green : Colors.white),
        ),
      ],
    );
  }

  Widget _buildPaymentMethod(String id, String name, IconData icon, Color color) {
    final isSelected = _selectedPaymentMethod == id;
    return GestureDetector(
      onTap: () => setState(() => _selectedPaymentMethod = id),
      child: Container(
        margin: const EdgeInsets.only(bottom: 12),
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: isSelected ? color.withValues(alpha: 0.1) : Colors.grey[900],
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: isSelected ? color : Colors.transparent),
        ),
        child: Row(
          children: [
            Icon(icon, color: color),
            const SizedBox(width: 16),
            Text(name, style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
            const Spacer(),
            if (isSelected) Icon(Icons.check_circle, color: color),
          ],
        ),
      ),
    );
  }

  Widget _buildPayButton() {
    return Container(
      padding: const EdgeInsets.all(24),
      color: AppColors.backgroundDark,
      child: ElevatedButton(
        onPressed: _isProcessing ? null : _processPayment,
        style: ElevatedButton.styleFrom(
          backgroundColor: AppColors.primary,
          padding: const EdgeInsets.symmetric(vertical: 16),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        ),
        child: _isProcessing
            ? const SizedBox(
                height: 20,
                width: 20,
                child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2),
              )
            : const Text(
                'THANH TOÁN NGAY',
                style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 16),
              ),
      ),
    );
  }

  void _processPayment() async {
    setState(() => _isProcessing = true);
    await Future.delayed(const Duration(seconds: 2));
    if (mounted) {
      _showSuccessDialog();
    }
  }

  void _showSuccessDialog() {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => AlertDialog(
        backgroundColor: Colors.grey[900],
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(Icons.check_circle_outline, color: Colors.green, size: 80),
            const SizedBox(height: 16),
            const Text(
              'Thanh toán thành công!',
              style: TextStyle(color: Colors.white, fontSize: 20, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 8),
            const Text(
              'Vé của bạn đã được lưu vào hệ thống.',
              textAlign: TextAlign.center,
              style: TextStyle(color: Colors.grey),
            ),
            const SizedBox(height: 24),
            ElevatedButton(
              onPressed: () {
                Navigator.of(context).pop();
                context.go(AppRouter.ticketList);
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.primary,
                minimumSize: const Size(double.infinity, 48),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
              ),
              child: const Text('XEM VÉ CỦA TÔI'),
            ),
          ],
        ),
      ),
    );
  }
}
