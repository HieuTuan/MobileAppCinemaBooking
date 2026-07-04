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
import '../../models/app_models.dart';
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
                decoration: const InputDecoration(
                  labelText: 'Mã booking hoặc QR data',
                  prefixIcon: Icon(Icons.qr_code_2_rounded),
                ),
              ),
              const SizedBox(height: 12),
              Row(
                children: [
                  Expanded(
                    child: FilledButton.icon(
                      onPressed: _loading ? null : _verifyManual,
                      icon: _loading
                          ? const SizedBox.square(
                              dimension: 18,
                              child: CircularProgressIndicator(strokeWidth: 2),
                            )
                          : const Icon(Icons.verified_rounded),
                      label: const Text('Xác thực'),
                      style: FilledButton.styleFrom(
                        backgroundColor: AppColors.ink,
                        foregroundColor: Colors.white,
                      ),
                    ),
                  ),
                  const SizedBox(width: 10),
                  OutlinedButton.icon(
                    onPressed: _openScanner,
                    icon: const Icon(Icons.qr_code_scanner_rounded),
                    label: const Text('Quét liên tục'),
                  ),
                ],
              ),
              const SizedBox(height: 12),
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

  Future<void> _verifyManual() async {
    final raw = _code.text.trim();
    if (raw.isEmpty) return;
    var bookingId = raw;
    if (raw.startsWith('CINELUXE|')) {
      try {
        bookingId = parseQrTicket(raw).bookingId;
      } on FormatException catch (error) {
        _showError(error.message);
        return;
      }
    }
    setState(() => _loading = true);
    try {
      final result = await _apiClient.validateTicket(
        bookingId,
        '', // Empty string for global showtime check-in
        staffId: widget.store.currentUser?.id,
      );
      if (!mounted) return;
      setState(() {
        _validation = result;
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
          expectedShowtimeId: '', // Empty string for global showtime check-in
          staffId: widget.store.currentUser?.id,
        ),
      ),
    );
    if (result == null || !mounted) return;
    setState(() {
      _validation = result;
      _message = 'Vé hợp lệ. Đã xác thực thành công.';
      _success = true;
    });
  }

  void _showError(String message) {
    setState(() {
      _validation = null;
      _message = message;
      _success = false;
    });
  }

  String _showtimeLabel(Showtime showtime) {
    final movie = widget.store.movieById(showtime.movieId);
    return '${movie.title} • ${shortDate(showtime.startTime)} ${shortTime(showtime.startTime)}';
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
      final qr = parseQrTicket(rawCode);
      final result = await widget.apiClient.validateTicket(
        qr.bookingId,
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
  if (error is DioException && error.error is ApiException) {
    return (error.error! as ApiException).error.message;
  }
  if (error is ApiException) return error.error.message;
  return 'Không thể xác thực vé. Vui lòng thử lại.';
}
