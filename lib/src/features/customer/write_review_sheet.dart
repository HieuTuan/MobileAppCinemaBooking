import 'package:flutter/material.dart';

import '../../../api/api_client.dart';
import '../../../api/exceptions/api_exceptions.dart';
import '../../core/app_theme.dart';

Future<bool?> showWriteReviewSheet({
  required BuildContext context,
  required APIClient api,
  required String userId,
  required String movieId,
  String? movieTitle,
}) {
  return showModalBottomSheet<bool>(
    context: context,
    isScrollControlled: true,
    backgroundColor: Colors.transparent,
    builder: (_) => WriteReviewSheet(
      api: api,
      userId: userId,
      movieId: movieId,
      movieTitle: movieTitle,
    ),
  );
}

class WriteReviewSheet extends StatefulWidget {
  const WriteReviewSheet({
    super.key,
    required this.api,
    required this.userId,
    required this.movieId,
    this.movieTitle,
  });

  final APIClient api;
  final String userId;
  final String movieId;
  final String? movieTitle;

  @override
  State<WriteReviewSheet> createState() => _WriteReviewSheetState();
}

class _WriteReviewSheetState extends State<WriteReviewSheet> {
  final _commentController = TextEditingController();
  int _rating = 0;
  String? _ratingError;
  String? _commentError;
  String? _serverError;
  bool _submitting = false;

  @override
  void dispose() {
    _commentController.dispose();
    super.dispose();
  }

  String? _validateRating(int rating) {
    if (rating < 1 || rating > 10) {
      return 'Vui lòng chọn điểm từ 1 đến 10';
    }
    return null;
  }

  String? _validateComment(String text) {
    final len = text.trim().length;
    if (len < 10) {
      return 'Bình luận phải có ít nhất 10 ký tự';
    }
    if (len > 500) {
      return 'Bình luận không được vượt quá 500 ký tự';
    }
    return null;
  }

  bool _validate() {
    final ratingError = _validateRating(_rating);
    final commentError = _validateComment(_commentController.text);
    setState(() {
      _ratingError = ratingError;
      _commentError = commentError;
      _serverError = null;
    });
    return ratingError == null && commentError == null;
  }

  Future<void> _submit() async {
    if (!_validate()) return;
    setState(() {
      _submitting = true;
      _serverError = null;
    });

    try {
      await widget.api.createReview(
        userId: widget.userId,
        movieId: widget.movieId,
        rating: _rating,
        comment: _commentController.text.trim(),
      );
      if (!mounted) return;
      Navigator.of(context).pop(true);
    } on ApiAuthorizationException {
      setState(() {
        _serverError =
            'Bạn cần check-in và sử dụng vé trước khi đánh giá phim.';
        _submitting = false;
      });
    } on ApiConflictException {
      setState(() {
        _serverError = 'Bạn đã đánh giá phim này rồi.';
        _submitting = false;
      });
    } on ApiValidationException catch (e) {
      setState(() {
        _serverError = e.error.message;
        _submitting = false;
      });
    } catch (_) {
      setState(() {
        _serverError = 'Không thể gửi đánh giá. Vui lòng thử lại.';
        _submitting = false;
      });
    }
  }

  void _selectRating(int value) {
    setState(() {
      _rating = value;
      _ratingError = null;
    });
  }

  @override
  Widget build(BuildContext context) {
    final charCount = _commentController.text.trim().length;
    final overLimit = charCount > 500;

    return Padding(
      padding: EdgeInsets.only(bottom: MediaQuery.viewInsetsOf(context).bottom),
      child: Container(
        decoration: const BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
        ),
        child: SafeArea(
          top: false,
          child: SingleChildScrollView(
            padding: const EdgeInsets.fromLTRB(20, 8, 20, 20),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Center(
                  child: Container(
                    width: 40,
                    height: 4,
                    margin: const EdgeInsets.only(bottom: 16),
                    decoration: BoxDecoration(
                      color: AppColors.line,
                      borderRadius: BorderRadius.circular(2),
                    ),
                  ),
                ),
                const Text(
                  'Đánh giá phim',
                  style: TextStyle(fontSize: 18, fontWeight: FontWeight.w900),
                ),
                if ((widget.movieTitle ?? '').isNotEmpty) ...[
                  const SizedBox(height: 4),
                  Text(
                    widget.movieTitle!,
                    style: const TextStyle(
                      color: AppColors.muted,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ],
                const SizedBox(height: 18),
                Row(
                  children: [
                    const Text(
                      'Điểm *',
                      style: TextStyle(fontWeight: FontWeight.w800),
                    ),
                    const Spacer(),
                    Text(
                      _rating == 0 ? 'Chưa chọn' : '$_rating/10',
                      style: const TextStyle(fontWeight: FontWeight.w900),
                    ),
                  ],
                ),
                const SizedBox(height: 8),
                Wrap(
                  spacing: 2,
                  runSpacing: 2,
                  children: List.generate(10, (index) {
                    final value = index + 1;
                    final selected = value <= _rating;
                    return SizedBox.square(
                      dimension: 38,
                      child: IconButton(
                        tooltip: '$value/10',
                        visualDensity: VisualDensity.compact,
                        padding: EdgeInsets.zero,
                        onPressed: () => _selectRating(value),
                        icon: Icon(
                          selected
                              ? Icons.star_rounded
                              : Icons.star_border_rounded,
                          color: selected ? Colors.black : AppColors.muted,
                          size: 32,
                        ),
                      ),
                    );
                  }),
                ),
                const SizedBox(height: 6),
                Row(
                  children: List.generate(10, (index) {
                    final value = index + 1;
                    return Expanded(
                      child: GestureDetector(
                        behavior: HitTestBehavior.opaque,
                        onTap: () => _selectRating(value),
                        child: Text(
                          '$value',
                          textAlign: TextAlign.center,
                          style: TextStyle(
                            color: value == _rating
                                ? Colors.black
                                : AppColors.muted,
                            fontSize: 11,
                            fontWeight: value == _rating
                                ? FontWeight.w900
                                : FontWeight.w600,
                          ),
                        ),
                      ),
                    );
                  }),
                ),
                if (_ratingError != null) ...[
                  const SizedBox(height: 6),
                  Text(
                    _ratingError!,
                    style: const TextStyle(
                      color: AppColors.danger,
                      fontSize: 12,
                    ),
                  ),
                ],
                const SizedBox(height: 18),
                Row(
                  children: [
                    const Text(
                      'Bình luận *',
                      style: TextStyle(fontWeight: FontWeight.w800),
                    ),
                    const Spacer(),
                    Text(
                      '$charCount / 500',
                      style: TextStyle(
                        color: overLimit ? AppColors.danger : AppColors.muted,
                        fontSize: 12,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 8),
                TextField(
                  controller: _commentController,
                  minLines: 3,
                  maxLines: 5,
                  onChanged: (_) {
                    setState(() {
                      if (_commentError != null) {
                        _commentError = _validateComment(
                          _commentController.text,
                        );
                      }
                    });
                  },
                  decoration: InputDecoration(
                    hintText: 'Cảm nhận của bạn về bộ phim...',
                    errorText: _commentError,
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(8),
                    ),
                  ),
                ),
                if (_serverError != null) ...[
                  const SizedBox(height: 14),
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 12,
                      vertical: 10,
                    ),
                    decoration: BoxDecoration(
                      color: AppColors.danger.withValues(alpha: .08),
                      borderRadius: BorderRadius.circular(8),
                      border: Border.all(
                        color: AppColors.danger.withValues(alpha: .28),
                      ),
                    ),
                    child: Row(
                      children: [
                        const Icon(
                          Icons.info_outline_rounded,
                          color: AppColors.danger,
                          size: 18,
                        ),
                        const SizedBox(width: 8),
                        Expanded(
                          child: Text(
                            _serverError!,
                            style: const TextStyle(
                              color: AppColors.danger,
                              fontWeight: FontWeight.w700,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
                const SizedBox(height: 16),
                SizedBox(
                  width: double.infinity,
                  child: FilledButton.icon(
                    onPressed: _submitting ? null : _submit,
                    icon: _submitting
                        ? const SizedBox(
                            width: 18,
                            height: 18,
                            child: CircularProgressIndicator(strokeWidth: 2),
                          )
                        : const Icon(Icons.rate_review_rounded),
                    label: Text(_submitting ? 'Đang gửi...' : 'Gửi đánh giá'),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
