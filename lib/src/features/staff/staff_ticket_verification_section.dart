import 'dart:async';

import 'package:dio/dio.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:mobile_scanner/mobile_scanner.dart';

import '../../../api/api_client.dart';
import '../../../api/exceptions/api_exceptions.dart';
import '../../../models/booking_models.dart';
import '../../../services/qr_scanner_service.dart';
import '../../../utils/qr_code_parser.dart';
import '../../core/app_theme.dart';
import '../../core/formatters.dart';
import '../../shared/widgets/glass_card.dart';
import '../../state/cinema_store.dart';

class StaffTicketVerificationSection extends StatefulWidget {
  const StaffTicketVerificationSection({
    super.key,
    required this.store,
    this.showTitle = true,
  });

  final CinemaStore store;
  final bool showTitle;

  @override
  State<StaffTicketVerificationSection> createState() =>
      _StaffTicketVerificationSectionState();
}

class _StaffTicketVerificationSectionState
    extends State<StaffTicketVerificationSection> {
  final _code = TextEditingController();
  final _apiClient = APIClient();
  ValidationResult? _validation;
  List<BookingDetails> _lookupResults = [];
  String _message = 'Sẵn sàng quét QR hoặc nhập mã vé.';
  bool _success = false;
  bool _loading = false;

  @override
  void dispose() {
    _code.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        if (widget.showTitle) const SectionTitle(title: 'Xác thực vé tại cổng'),
        GlassCard(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              TextField(
                controller: _code,
                onSubmitted: (_) => _lookupManual(),
                decoration: const InputDecoration(
                  labelText: 'Mã booking, đoạn mã, tên khách hoặc QR data',
                  prefixIcon: Icon(Icons.qr_code_2_rounded),
                ),
              ),
              const SizedBox(height: 12),
              Row(
                children: [
                  Expanded(
                    child: FilledButton.icon(
                      onPressed: _loading ? null : _lookupManual,
                      icon: _loading
                          ? const SizedBox.square(
                              dimension: 18,
                              child: CircularProgressIndicator(strokeWidth: 2),
                            )
                          : const Icon(Icons.search_rounded),
                      label: const Text('Tìm vé'),
                      style: FilledButton.styleFrom(
                        backgroundColor: AppColors.ink,
                        foregroundColor: Colors.white,
                      ),
                    ),
                  ),
                  const SizedBox(width: 10),
                  OutlinedButton.icon(
                    onPressed: _loading ? null : _openScanner,
                    icon: const Icon(Icons.qr_code_scanner_rounded),
                    label: const Text('Quét liên tục'),
                  ),
                ],
              ),
              const SizedBox(height: 12),
              if (_lookupResults.isNotEmpty) ...[
                for (final booking in _lookupResults)
                  _LookupBookingCard(
                    booking: booking,
                    loading: _loading,
                    onValidate: () => _validateBookingId(booking.bookingId),
                  ),
                const SizedBox(height: 4),
              ],
              _ResultBanner(
                message: _message,
                success: _success,
                validation: _validation,
              ),
            ],
          ),
        ),
      ],
    );
  }

  Future<void> _lookupManual() async {
    final raw = _code.text.trim();
    if (raw.isEmpty) return;

    try {
      final bookingId = tryExtractBookingId(raw);
      if (bookingId != null) {
        await _loadBookingById(bookingId);
        return;
      }
      await _searchManual(raw);
    } on FormatException catch (error) {
      _showError(error.message);
    }
  }

  Future<void> _loadBookingById(String bookingId) async {
    setState(() {
      _loading = true;
      _lookupResults = [];
      _validation = null;
      _success = false;
      _message = 'Đang tải thông tin vé...';
    });

    try {
      final booking = await _apiClient.getBookingDetails(bookingId);
      if (!mounted) return;
      setState(() {
        _lookupResults = [booking];
        _message = 'Đã tìm thấy vé. Kiểm tra thông tin rồi bấm Xác thực vé.';
        _success = false;
      });
    } catch (error) {
      if (!mounted) return;
      _showError(_apiMessage(error));
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  Future<void> _searchManual(String raw) async {
    final query = raw.trim();
    if (query.isEmpty) return;

    setState(() {
      _loading = true;
      _lookupResults = [];
      _validation = null;
      _success = false;
      _message = 'Đang tìm vé...';
    });

    try {
      final looksLikeBookingCode =
          query.toUpperCase().startsWith('BK-') ||
          query.contains('-') ||
          RegExp(r'^[0-9a-fA-F]{6,}$').hasMatch(query);
      final results = await _apiClient.searchBookings(
        bookingId: looksLikeBookingCode ? query : null,
        customerName: looksLikeBookingCode ? null : query,
      );
      if (!mounted) return;
      setState(() {
        _lookupResults = results;
        _message = results.isEmpty
            ? 'Không tìm thấy vé phù hợp.'
            : 'Tìm thấy ${results.length} vé. Chọn vé để xác thực.';
        _success = false;
      });
    } catch (error) {
      if (!mounted) return;
      _showError(_apiMessage(error));
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  Future<void> _validateBookingId(String bookingId) async {
    setState(() => _loading = true);
    try {
      final result = await _apiClient.validateTicket(
        bookingId,
        '',
        staffId: widget.store.currentUser?.id,
      );
      if (!mounted) return;
      setState(() {
        _validation = result;
        _lookupResults = [];
        _message = 'Vé hợp lệ. Đã xác thực thành công.';
        _success = true;
      });
      await _feedback(true);
    } catch (error) {
      if (!mounted) return;
      _showError(_apiMessage(error));
      await _feedback(false);
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  Future<void> _openScanner() async {
    final result = await Navigator.of(context).push<ValidationResult>(
      MaterialPageRoute(
        builder: (_) => _ContinuousScannerScreen(
          apiClient: _apiClient,
          expectedShowtimeId: '',
          staffId: widget.store.currentUser?.id,
        ),
      ),
    );
    if (result == null || !mounted) return;
    setState(() {
      _validation = result;
      _lookupResults = [];
      _message = 'Vé hợp lệ. Đã xác thực thành công.';
      _success = true;
    });
  }

  void _showError(String message) {
    setState(() {
      _validation = null;
      _lookupResults = [];
      _message = message;
      _success = false;
    });
  }
}

class _ContinuousScannerScreen extends StatefulWidget {
  const _ContinuousScannerScreen({
    required this.apiClient,
    required this.expectedShowtimeId,
    required this.staffId,
  });

  final APIClient apiClient;
  final String expectedShowtimeId;
  final String? staffId;

  @override
  State<_ContinuousScannerScreen> createState() =>
      _ContinuousScannerScreenState();
}

class _ContinuousScannerScreenState extends State<_ContinuousScannerScreen> {
  final QrScannerService _scanner = QrScannerService();
  StreamSubscription<String>? _subscription;
  ValidationResult? _lastValidation;
  String _message = 'Đưa mã QR vào khung hình';
  bool _success = false;
  bool _processing = false;

  @override
  void initState() {
    super.initState();
    _subscription = _scanner.codes.listen(_onCode);
    _scanner.startScanning().catchError((Object error) {
      if (mounted) {
        setState(() => _message = 'Không thể mở camera. Hãy cấp quyền camera.');
      }
    });
  }

  @override
  void dispose() {
    _subscription?.cancel();
    _scanner.dispose(disposeController: false);
    super.dispose();
  }

  Future<void> _onCode(String rawCode) async {
    if (_processing) return;
    setState(() => _processing = true);
    try {
      final bookingId = parseTicketBookingId(rawCode);
      final result = await widget.apiClient.validateTicket(
        bookingId,
        widget.expectedShowtimeId,
        staffId: widget.staffId,
      );
      if (!mounted) return;
      setState(() {
        _lastValidation = result;
        _message =
            'Hợp lệ: ${result.movieTitle} - ghế ${result.seatCodes.join(', ')}';
        _success = true;
      });
      await _feedback(true);
    } catch (error) {
      if (!mounted) return;
      setState(() {
        _lastValidation = null;
        _message = error is FormatException
            ? error.message
            : _apiMessage(error);
        _success = false;
      });
      await _feedback(false);
    } finally {
      await Future<void>.delayed(const Duration(milliseconds: 1400));
      if (mounted) setState(() => _processing = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final color = _success ? AppColors.success : AppColors.danger;
    return Scaffold(
      backgroundColor: Colors.black,
      appBar: AppBar(
        backgroundColor: Colors.black,
        foregroundColor: Colors.white,
        title: const Text('Quét vé liên tục'),
        actions: [
          IconButton(
            tooltip: 'Bật/tắt đèn',
            onPressed: _scanner.toggleTorch,
            icon: const Icon(Icons.flashlight_on_rounded),
          ),
        ],
      ),
      body: Stack(
        fit: StackFit.expand,
        children: [
          MobileScanner(
            controller: _scanner.controller,
            onDetect: (_) {},
            errorBuilder: (_, __, ___) => const Center(
              child: Text(
                'Không thể truy cập camera',
                style: TextStyle(color: Colors.white),
              ),
            ),
          ),
          Center(
            child: Container(
              width: 260,
              height: 260,
              decoration: BoxDecoration(
                border: Border.all(color: Colors.white, width: 3),
                borderRadius: BorderRadius.circular(20),
              ),
            ),
          ),
          Align(
            alignment: Alignment.bottomCenter,
            child: SafeArea(
              child: Container(
                width: double.infinity,
                margin: const EdgeInsets.all(16),
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: color.withValues(alpha: .92),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(
                      _success ? Icons.check_circle : Icons.qr_code_scanner,
                      color: Colors.white,
                      size: 38,
                    ),
                    const SizedBox(height: 8),
                    Text(
                      _message,
                      textAlign: TextAlign.center,
                      style: const TextStyle(
                        color: Colors.white,
                        fontWeight: FontWeight.w900,
                      ),
                    ),
                    if (_lastValidation != null)
                      TextButton(
                        onPressed: () =>
                            Navigator.of(context).pop(_lastValidation),
                        child: const Text(
                          'Đóng và xem kết quả',
                          style: TextStyle(color: Colors.white),
                        ),
                      ),
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _LookupBookingCard extends StatelessWidget {
  const _LookupBookingCard({
    required this.booking,
    required this.loading,
    required this.onValidate,
  });

  final BookingDetails booking;
  final bool loading;
  final VoidCallback onValidate;

  @override
  Widget build(BuildContext context) {
    final canValidate = booking.status == 'active';
    final statusColor = switch (booking.status) {
      'active' => AppColors.success,
      'used' => AppColors.muted,
      'cancelled' || 'refunded' => AppColors.danger,
      _ => AppColors.warning,
    };
    return Container(
      width: double.infinity,
      margin: const EdgeInsets.only(bottom: 10),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: AppColors.line),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Expanded(
                child: Text(
                  booking.movieTitle,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(fontWeight: FontWeight.w900),
                ),
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                decoration: BoxDecoration(
                  color: statusColor.withValues(alpha: .1),
                  borderRadius: BorderRadius.circular(999),
                ),
                child: Text(
                  booking.status,
                  style: TextStyle(
                    color: statusColor,
                    fontSize: 12,
                    fontWeight: FontWeight.w800,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 6),
          Text(
            booking.bookingId,
            style: const TextStyle(
              fontSize: 12,
              color: AppColors.muted,
              fontFamily: 'monospace',
            ),
          ),
          const SizedBox(height: 6),
          Text(
            '${shortDate(booking.showtimeDateTime)} ${shortTime(booking.showtimeDateTime)} · ${booking.roomName}',
            style: const TextStyle(fontSize: 12, color: AppColors.muted),
          ),
          Text(
            'Ghế: ${booking.seatCodes.join(', ')}',
            style: const TextStyle(fontSize: 12, color: AppColors.muted),
          ),
          const SizedBox(height: 10),
          SizedBox(
            width: double.infinity,
            child: FilledButton.icon(
              onPressed: loading || !canValidate ? null : onValidate,
              icon: const Icon(Icons.verified_rounded),
              label: Text(canValidate ? 'Xác thực vé' : 'Không thể xác thực'),
              style: FilledButton.styleFrom(
                backgroundColor: AppColors.ink,
                foregroundColor: Colors.white,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _ResultBanner extends StatelessWidget {
  const _ResultBanner({
    required this.message,
    required this.success,
    required this.validation,
  });

  final String message;
  final bool success;
  final ValidationResult? validation;

  @override
  Widget build(BuildContext context) {
    final color = success ? AppColors.success : AppColors.danger;
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: color.withValues(alpha: .09),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: color.withValues(alpha: .35)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            message,
            style: TextStyle(color: color, fontWeight: FontWeight.w900),
          ),
          if (validation != null) ...[
            const SizedBox(height: 8),
            Text('Khách hàng: ${validation!.customerName}'),
            Text('Phim: ${validation!.movieTitle}'),
            Text('Ghế: ${validation!.seatCodes.join(', ')}'),
          ],
        ],
      ),
    );
  }
}

Future<void> _feedback(bool success) async {
  await HapticFeedback.vibrate();
  await SystemSound.play(
    success ? SystemSoundType.click : SystemSoundType.alert,
  );
}

String _apiMessage(Object error) {
  String normalize(String message) {
    if (message == 'Validation window closed') {
      return 'Mã booking hợp lệ, nhưng chưa tới giờ check-in. Vé chỉ xác thực từ 2 giờ trước suất chiếu đến 30 phút sau giờ chiếu.';
    }
    if (message == 'Ticket is not active') {
      return 'Vé chưa ở trạng thái hoạt động. Hãy kiểm tra lại thanh toán hoặc trạng thái vé.';
    }
    if (message == 'Ticket already validated') {
      return 'Vé này đã được xác thực trước đó.';
    }
    if (message == 'Ticket cancelled, entry denied') {
      return 'Vé đã bị hủy hoặc hoàn tiền, không thể vào cổng.';
    }
    if (message.startsWith('Booking not found')) {
      return 'Không tìm thấy mã booking. Hãy nhập đủ mã, ví dụ: BK-448fd3bc-4a4b-4d03-8b6b-949377ad888a.';
    }
    return message;
  }

  if (error is DioException && error.error is ApiException) {
    return normalize((error.error! as ApiException).error.message);
  }
  if (error is ApiException) return normalize(error.error.message);
  return 'Không thể xác thực vé. Vui lòng thử lại.';
}
