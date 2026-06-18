import 'package:flutter/material.dart';

import '../../core/app_theme.dart';

/// Tracks movies confirmed by the user in the current session.
/// Using a static Set means it lives for the app's lifetime (in-memory session).
class AgeGateSession {
  AgeGateSession._();

  static final Set<String> _confirmedMovies = {};

  /// Returns true if the user has already confirmed age for this movie.
  static bool isConfirmed(String movieId) => _confirmedMovies.contains(movieId);

  /// Marks the movie as age-confirmed for the rest of the session.
  static void confirm(String movieId) => _confirmedMovies.add(movieId);
}

/// Shows the T18 age-gate modal and returns [true] if the user confirmed
/// they are 18+, or [false] / [null] if they are underage or dismissed.
///
/// Also persists confirmation in [AgeGateSession] so the user is not asked
/// again for the same movie in the same session.
Future<bool> showAgeGate(BuildContext context, String movieId) async {
  final result = await showModalBottomSheet<bool>(
    context: context,
    isScrollControlled: true,
    backgroundColor: Colors.transparent,
    builder: (context) => _AgeGateModal(movieId: movieId),
  );
  return result == true;
}

class _AgeGateModal extends StatefulWidget {
  const _AgeGateModal({required this.movieId});

  final String movieId;

  @override
  State<_AgeGateModal> createState() => _AgeGateModalState();
}

class _AgeGateModalState extends State<_AgeGateModal> {
  DateTime? _selectedDate;
  bool _checking = false;
  String? _errorMessage;

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: const BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      padding: EdgeInsets.only(
        left: 24,
        right: 24,
        top: 24,
        bottom: MediaQuery.of(context).viewInsets.bottom + 32,
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Drag handle
          Center(
            child: Container(
              width: 40,
              height: 4,
              margin: const EdgeInsets.only(bottom: 20),
              decoration: BoxDecoration(
                color: AppColors.line,
                borderRadius: BorderRadius.circular(2),
              ),
            ),
          ),
          // Warning icon + title
          Row(
            children: [
              Container(
                width: 44,
                height: 44,
                decoration: BoxDecoration(
                  color: const Color(0xFFFFE8E8),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: const Icon(
                  Icons.warning_amber_rounded,
                  color: AppColors.danger,
                  size: 26,
                ),
              ),
              const SizedBox(width: 12),
              const Expanded(
                child: Text(
                  'Nội dung dành cho người từ 18 tuổi',
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.w900,
                    height: 1.3,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 14),
          const Text(
            'Phim này được xếp loại T18. Bạn cần xác nhận ngày sinh để tiếp tục mua vé.',
            style: TextStyle(
              color: AppColors.muted,
              fontSize: 15,
              height: 1.5,
            ),
          ),
          const SizedBox(height: 24),
          // Birthdate picker area
          const Text(
            'Ngày sinh của bạn',
            style: TextStyle(fontWeight: FontWeight.w800, fontSize: 15),
          ),
          const SizedBox(height: 10),
          InkWell(
            onTap: _checking ? null : _pickDate,
            borderRadius: BorderRadius.circular(8),
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 14),
              decoration: BoxDecoration(
                border: Border.all(
                  color: _errorMessage != null
                      ? AppColors.danger
                      : AppColors.line,
                  width: _errorMessage != null ? 1.4 : 1,
                ),
                borderRadius: BorderRadius.circular(8),
                color: AppColors.pearl,
              ),
              child: Row(
                children: [
                  const Icon(
                    Icons.calendar_today_rounded,
                    color: AppColors.muted,
                    size: 20,
                  ),
                  const SizedBox(width: 10),
                  Text(
                    _selectedDate == null
                        ? 'Chọn ngày sinh'
                        : '${_selectedDate!.day.toString().padLeft(2, '0')}/${_selectedDate!.month.toString().padLeft(2, '0')}/${_selectedDate!.year}',
                    style: TextStyle(
                      color: _selectedDate == null
                          ? AppColors.muted
                          : AppColors.ink,
                      fontSize: 16,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                  const Spacer(),
                  const Icon(
                    Icons.expand_more_rounded,
                    color: AppColors.muted,
                  ),
                ],
              ),
            ),
          ),
          if (_errorMessage != null) ...[
            const SizedBox(height: 8),
            Row(
              children: [
                const Icon(
                  Icons.info_outline_rounded,
                  color: AppColors.danger,
                  size: 16,
                ),
                const SizedBox(width: 6),
                Text(
                  _errorMessage!,
                  style: const TextStyle(
                    color: AppColors.danger,
                    fontSize: 13,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ],
            ),
          ],
          const SizedBox(height: 28),
          // Action buttons
          Row(
            children: [
              Expanded(
                child: OutlinedButton(
                  onPressed: _checking
                      ? null
                      : () => Navigator.of(context).pop(false),
                  style: OutlinedButton.styleFrom(
                    minimumSize: const Size.fromHeight(52),
                    side: const BorderSide(color: AppColors.line),
                    foregroundColor: AppColors.ink,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(8),
                    ),
                  ),
                  child: const Text(
                    'Hủy',
                    style: TextStyle(fontWeight: FontWeight.w800),
                  ),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                flex: 2,
                child: FilledButton(
                  onPressed: _checking ? null : _confirm,
                  style: FilledButton.styleFrom(
                    minimumSize: const Size.fromHeight(52),
                    backgroundColor: Colors.black,
                    foregroundColor: Colors.white,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(8),
                    ),
                    disabledBackgroundColor: AppColors.muted,
                  ),
                  child: _checking
                      ? const SizedBox(
                          width: 20,
                          height: 20,
                          child: CircularProgressIndicator(
                            strokeWidth: 2,
                            color: Colors.white,
                          ),
                        )
                      : const Text(
                          'Xác nhận',
                          style: TextStyle(
                            fontWeight: FontWeight.w900,
                            fontSize: 16,
                          ),
                        ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Future<void> _pickDate() async {
    final now = DateTime.now();
    final picked = await showDatePicker(
      context: context,
      initialDate: _selectedDate ?? DateTime(now.year - 25, now.month, now.day),
      firstDate: DateTime(now.year - 100),
      lastDate: DateTime(now.year, now.month, now.day),
      helpText: 'Chọn ngày sinh',
      cancelText: 'Hủy',
      confirmText: 'Xác nhận',
      builder: (context, child) {
        return Theme(
          data: Theme.of(context).copyWith(
            colorScheme: Theme.of(context).colorScheme.copyWith(
              primary: Colors.black,
              onPrimary: Colors.white,
            ),
          ),
          child: child!,
        );
      },
    );
    if (picked != null) {
      setState(() {
        _selectedDate = picked;
        _errorMessage = null;
      });
    }
  }

  void _confirm() {
    if (_selectedDate == null) {
      setState(() => _errorMessage = 'Vui lòng chọn ngày sinh.');
      return;
    }

    final now = DateTime.now();
    final eighteenYearsAgo = DateTime(now.year - 18, now.month, now.day);
    final isAdult = !_selectedDate!.isAfter(eighteenYearsAgo);

    if (!isAdult) {
      setState(
        () =>
            _errorMessage =
                'Bạn chưa đủ 18 tuổi để xem nội dung này.',
      );
      return;
    }

    // Eligible — store in session and proceed
    AgeGateSession.confirm(widget.movieId);
    Navigator.of(context).pop(true);
  }
}
