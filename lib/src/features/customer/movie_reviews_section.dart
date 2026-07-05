import 'package:flutter/material.dart';

import '../../../api/api_client.dart';
import '../../../api/exceptions/api_exceptions.dart';
import '../../../models/review.dart';
import '../../core/app_theme.dart';
import 'write_review_sheet.dart';

/// Requirements 14.1–14.9: Review section with paginated list and write-review support.
///
/// - 14.1, 14.2, 14.3: Authenticated users can submit reviews; 403 is shown with
///   a friendly message when the user has not watched the movie.
/// - 14.4, 14.5: Inline validation enforces rating 1–5 and comment 10–500 chars.
/// - 14.8, 14.9: Paginated review list fetched from
///   GET /api/movies/{movieId}/reviews with verified badge support.
class MovieReviewsSection extends StatefulWidget {
  const MovieReviewsSection({
    super.key,
    required this.movieId,
    this.currentUserId,
  });

  final String movieId;

  /// When non-null the "Viết đánh giá" button is shown for this user.
  final String? currentUserId;

  @override
  State<MovieReviewsSection> createState() => _MovieReviewsSectionState();
}

class _MovieReviewsSectionState extends State<MovieReviewsSection> {
  final _api = APIClient();

  final List<Review> _reviews = [];
  int _currentPage = 1;
  int _totalPages = 1;
  int _totalItems = 0;
  bool _isLoading = false;
  bool _isLoadingMore = false;
  String? _error;

  @override
  void initState() {
    super.initState();
    _fetchReviews(page: 1, replace: true);
  }

  /// Fetch a page of reviews from the API.
  ///
  /// Requirements:
  /// - 14.8: API_Client SHALL GET /api/movies/{movieId}/reviews with pagination
  /// - 14.9: Backend returns userId, userName, rating, comment, createdAt, isVerified
  Future<void> _fetchReviews({required int page, bool replace = false}) async {
    if (_isLoading || _isLoadingMore) return;

    setState(() {
      if (replace) {
        _isLoading = true;
        _error = null;
      } else {
        _isLoadingMore = true;
      }
    });

    try {
      final response = await _api.getMovieReviews(
        widget.movieId,
        page: page,
        pageSize: 5,
      );

      if (!mounted) return;

      setState(() {
        if (replace) {
          _reviews.clear();
        }
        _reviews.addAll(response.data);
        _currentPage = response.page;
        _totalPages = response.totalPages;
        _totalItems = response.totalItems;
        _isLoading = false;
        _isLoadingMore = false;
        _error = null;
      });
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _isLoading = false;
        _isLoadingMore = false;
        _error = 'Không thể tải đánh giá. Vui lòng thử lại.';
      });
    }
  }

  void _loadMore() {
    if (_currentPage < _totalPages && !_isLoadingMore) {
      _fetchReviews(page: _currentPage + 1);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(18, 18, 18, 24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Expanded(
                child: _SectionHeading(
                  totalItems: _isLoading ? null : _totalItems,
                ),
              ),
              if (widget.currentUserId != null)
                TextButton.icon(
                  onPressed: () => _openWriteReviewSheet(context),
                  icon: const Icon(Icons.edit_rounded, size: 16),
                  label: const Text('Viết đánh giá'),
                  style: TextButton.styleFrom(
                    foregroundColor: AppColors.ink,
                    textStyle: const TextStyle(
                      fontWeight: FontWeight.w700,
                      fontSize: 13,
                    ),
                  ),
                ),
            ],
          ),
          const SizedBox(height: 14),
          _buildContent(),
        ],
      ),
    );
  }

  /// Opens the write-review bottom sheet.
  ///
  /// Requirements: 14.1, 14.2, 14.3
  Future<void> _openWriteReviewSheet(BuildContext context) async {
    final submitted = await showWriteReviewSheet(
      context: context,
      api: _api,
      userId: widget.currentUserId!,
      movieId: widget.movieId,
    );

    if (submitted == true) {
      // Refresh the first page so the new review shows up
      _fetchReviews(page: 1, replace: true);
    }
  }

  Widget _buildContent() {
    if (_isLoading) {
      return const _ReviewLoadingPlaceholder();
    }

    if (_error != null && _reviews.isEmpty) {
      return _ErrorView(
        message: _error!,
        onRetry: () => _fetchReviews(page: 1, replace: true),
      );
    }

    if (_reviews.isEmpty) {
      return const _EmptyReviews();
    }

    return Column(
      children: [
        ..._reviews.map(
          (review) => Padding(
            padding: const EdgeInsets.only(bottom: 12),
            child: _ApiReviewCard(review: review),
          ),
        ),
        if (_isLoadingMore)
          const Padding(
            padding: EdgeInsets.symmetric(vertical: 12),
            child: Center(child: CircularProgressIndicator(strokeWidth: 2)),
          )
        else if (_currentPage < _totalPages)
          _LoadMoreButton(onPressed: _loadMore)
        else if (_reviews.isNotEmpty)
          _AllLoadedIndicator(totalItems: _totalItems),
      ],
    );
  }
}

// ---------------------------------------------------------------------------
// Section Heading
// ---------------------------------------------------------------------------

class _SectionHeading extends StatelessWidget {
  const _SectionHeading({this.totalItems});

  final int? totalItems;

  @override
  Widget build(BuildContext context) {
    final countText = totalItems == null ? '' : ' ($totalItems)';
    return Text(
      'Đánh giá từ khán giả$countText',
      style: Theme.of(context).textTheme.headlineSmall?.copyWith(
        fontWeight: FontWeight.w900,
        letterSpacing: 0,
      ),
    );
  }
}

// ---------------------------------------------------------------------------
// Individual Review Card (API-backed)
// ---------------------------------------------------------------------------

/// Renders a single [Review] with:
/// - Avatar initials
/// - User name
/// - Verified badge (if isVerified == true)
/// - Star rating (1–5)
/// - Comment text
/// - Relative timestamp
///
/// Requirements 14.9
class _ApiReviewCard extends StatefulWidget {
  const _ApiReviewCard({required this.review});

  final Review review;

  @override
  State<_ApiReviewCard> createState() => _ApiReviewCardState();
}

class _ApiReviewCardState extends State<_ApiReviewCard> {
  bool _expanded = false;

  static const int _commentPreviewLength = 200;

  @override
  Widget build(BuildContext context) {
    final review = widget.review;
    final isLongComment = review.comment.length > _commentPreviewLength;
    final displayText = (!_expanded && isLongComment)
        ? '${review.comment.substring(0, _commentPreviewLength)}...'
        : review.comment;

    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: AppColors.line),
        boxShadow: softShadow(.035),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Header row: avatar | name + badge | rating pill
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _UserAvatar(userName: review.userName),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Flexible(
                          child: Text(
                            review.userName,
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: const TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.w900,
                            ),
                          ),
                        ),
                        if (review.isVerified) ...[
                          const SizedBox(width: 6),
                          const _VerifiedBadge(),
                        ],
                      ],
                    ),
                    const SizedBox(height: 3),
                    Text(
                      review.relativeTime,
                      style: Theme.of(
                        context,
                      ).textTheme.bodySmall?.copyWith(color: AppColors.muted),
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 8),
              _StarRatingPill(rating: review.rating),
            ],
          ),
          const SizedBox(height: 12),
          // Comment text
          Text(
            displayText,
            style: Theme.of(context).textTheme.bodyMedium?.copyWith(
              color: AppColors.ink,
              height: 1.45,
            ),
          ),
          if (isLongComment) ...[
            const SizedBox(height: 4),
            GestureDetector(
              onTap: () => setState(() => _expanded = !_expanded),
              child: Text(
                _expanded ? 'Rút gọn' : 'Xem thêm',
                style: const TextStyle(
                  color: Colors.black,
                  fontWeight: FontWeight.w800,
                  fontSize: 13,
                ),
              ),
            ),
          ],
          const SizedBox(height: 10),
          // Footer: star row + date
          Row(
            children: [
              _StarRow(rating: review.rating),
              const Spacer(),
              Text(
                review.formattedDate,
                style: Theme.of(
                  context,
                ).textTheme.bodySmall?.copyWith(color: AppColors.muted),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

// ---------------------------------------------------------------------------
// Verified Badge
// ---------------------------------------------------------------------------

/// Green checkmark badge shown for reviews where [Review.isVerified] is true.
///
/// Requirements 14.9: Backend returns isVerified flag; shown as verification badge.
class _VerifiedBadge extends StatelessWidget {
  const _VerifiedBadge();

  @override
  Widget build(BuildContext context) {
    return Tooltip(
      message: 'Đã xem phim — đánh giá được xác nhận',
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
        decoration: BoxDecoration(
          color: AppColors.success.withValues(alpha: .12),
          borderRadius: BorderRadius.circular(4),
          border: Border.all(
            color: AppColors.success.withValues(alpha: .4),
            width: 0.8,
          ),
        ),
        child: const Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(Icons.verified_rounded, size: 13, color: AppColors.success),
            SizedBox(width: 3),
            Text(
              'Đã xem',
              style: TextStyle(
                fontSize: 11,
                fontWeight: FontWeight.w800,
                color: AppColors.success,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// ---------------------------------------------------------------------------
// Star Rating Pill (numeric)
// ---------------------------------------------------------------------------

class _StarRatingPill extends StatelessWidget {
  const _StarRatingPill({required this.rating});

  final int rating;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 5),
      decoration: BoxDecoration(
        color: const Color(0xFFFFF3E0),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Text(
        '★ $rating/10',
        style: const TextStyle(fontWeight: FontWeight.w900, fontSize: 13),
      ),
    );
  }
}

// ---------------------------------------------------------------------------
// Star Row (filled/outline icons)
// ---------------------------------------------------------------------------

class _StarRow extends StatelessWidget {
  const _StarRow({required this.rating});

  final int rating;

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: List.generate(5, (index) {
        final visualRating = (rating / 2).ceil();
        return Icon(
          index < visualRating ? Icons.star_rounded : Icons.star_border_rounded,
          color: AppColors.ink,
          size: 16,
        );
      }),
    );
  }
}

// ---------------------------------------------------------------------------
// User Avatar
// ---------------------------------------------------------------------------

class _UserAvatar extends StatelessWidget {
  const _UserAvatar({required this.userName});

  final String userName;

  String get _initials {
    final parts = userName.trim().split(RegExp(r'\s+'));
    if (parts.isEmpty) return '?';
    return parts.take(2).map((p) => p.isEmpty ? '' : p[0].toUpperCase()).join();
  }

  @override
  Widget build(BuildContext context) {
    return CircleAvatar(
      radius: 22,
      backgroundColor: AppColors.pearl,
      child: Text(
        _initials,
        style: const TextStyle(
          color: AppColors.ink,
          fontWeight: FontWeight.w900,
          fontSize: 14,
        ),
      ),
    );
  }
}

// ---------------------------------------------------------------------------
// Load More Button
// ---------------------------------------------------------------------------

class _LoadMoreButton extends StatelessWidget {
  const _LoadMoreButton({required this.onPressed});

  final VoidCallback onPressed;

  @override
  Widget build(BuildContext context) {
    return Center(
      child: OutlinedButton.icon(
        onPressed: onPressed,
        style: OutlinedButton.styleFrom(
          foregroundColor: AppColors.ink,
          side: const BorderSide(color: AppColors.line),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
        ),
        icon: const Icon(Icons.expand_more_rounded),
        label: const Text(
          'Xem thêm đánh giá',
          style: TextStyle(fontWeight: FontWeight.w700),
        ),
      ),
    );
  }
}

// ---------------------------------------------------------------------------
// All Loaded Indicator
// ---------------------------------------------------------------------------

class _AllLoadedIndicator extends StatelessWidget {
  const _AllLoadedIndicator({required this.totalItems});

  final int totalItems;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: Center(
        child: Text(
          'Đã hiển thị tất cả $totalItems đánh giá',
          style: Theme.of(
            context,
          ).textTheme.bodySmall?.copyWith(color: AppColors.muted),
        ),
      ),
    );
  }
}

// ---------------------------------------------------------------------------
// Loading Placeholder
// ---------------------------------------------------------------------------

class _ReviewLoadingPlaceholder extends StatelessWidget {
  const _ReviewLoadingPlaceholder();

  @override
  Widget build(BuildContext context) {
    return Column(
      children: List.generate(
        3,
        (_) => const Padding(
          padding: EdgeInsets.only(bottom: 12),
          child: _SkeletonCard(),
        ),
      ),
    );
  }
}

class _SkeletonCard extends StatelessWidget {
  const _SkeletonCard();

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 130,
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: AppColors.pearl,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: AppColors.line),
      ),
      child: const Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              _SkeletonBox(width: 44, height: 44, radius: 22),
              SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    _SkeletonBox(width: 120, height: 14),
                    SizedBox(height: 6),
                    _SkeletonBox(width: 80, height: 11),
                  ],
                ),
              ),
              _SkeletonBox(width: 48, height: 28, radius: 8),
            ],
          ),
          SizedBox(height: 12),
          _SkeletonBox(width: double.infinity, height: 12),
          SizedBox(height: 6),
          _SkeletonBox(width: double.infinity, height: 12),
          SizedBox(height: 6),
          _SkeletonBox(width: 160, height: 12),
        ],
      ),
    );
  }
}

class _SkeletonBox extends StatelessWidget {
  const _SkeletonBox({
    required this.width,
    required this.height,
    this.radius = 4,
  });

  final double width;
  final double height;
  final double radius;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: width == double.infinity ? null : width,
      height: height,
      decoration: BoxDecoration(
        color: AppColors.line,
        borderRadius: BorderRadius.circular(radius),
      ),
    );
  }
}

// ---------------------------------------------------------------------------
// Empty State
// ---------------------------------------------------------------------------

class _EmptyReviews extends StatelessWidget {
  const _EmptyReviews();

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 32, horizontal: 18),
      alignment: Alignment.center,
      child: Column(
        children: [
          const Icon(
            Icons.rate_review_outlined,
            size: 48,
            color: AppColors.muted,
          ),
          const SizedBox(height: 12),
          Text(
            'Chưa có đánh giá nào.',
            style: Theme.of(context).textTheme.bodyLarge?.copyWith(
              color: AppColors.muted,
              fontWeight: FontWeight.w600,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            'Hãy là người đầu tiên đánh giá bộ phim này!',
            textAlign: TextAlign.center,
            style: Theme.of(
              context,
            ).textTheme.bodyMedium?.copyWith(color: AppColors.muted),
          ),
        ],
      ),
    );
  }
}

// ---------------------------------------------------------------------------
// Error State
// ---------------------------------------------------------------------------

class _ErrorView extends StatelessWidget {
  const _ErrorView({required this.message, required this.onRetry});

  final String message;
  final VoidCallback onRetry;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 24, horizontal: 18),
      alignment: Alignment.center,
      child: Column(
        children: [
          const Icon(Icons.cloud_off_rounded, size: 44, color: AppColors.muted),
          const SizedBox(height: 12),
          Text(
            message,
            textAlign: TextAlign.center,
            style: Theme.of(
              context,
            ).textTheme.bodyMedium?.copyWith(color: AppColors.muted),
          ),
          const SizedBox(height: 14),
          OutlinedButton.icon(
            onPressed: onRetry,
            icon: const Icon(Icons.refresh_rounded),
            label: const Text('Thử lại'),
          ),
        ],
      ),
    );
  }
}

// ---------------------------------------------------------------------------
// Write Review Bottom Sheet
// ---------------------------------------------------------------------------

/// Bottom sheet for submitting a movie review.
///
/// Requirements:
/// - 14.1: Shows only when user is authenticated (currentUserId passed in).
/// - 14.2: Displays a clear message when 403 Forbidden is received.
/// - 14.3: POSTs to /api/reviews with userId, movieId, rating, and comment.
/// - 14.4: Star selector enforces 1–5 rating (inline error if none selected).
/// - 14.5: Comment must be 10–500 characters; char-count shown inline.
/// - 14.6: Spinner while submitting; button disabled during in-flight request.
class _WriteReviewSheet extends StatefulWidget {
  const _WriteReviewSheet({
    required this.movieId,
    required this.userId,
    required this.api,
  });

  final String movieId;
  final String userId;
  final APIClient api;

  @override
  State<_WriteReviewSheet> createState() => _WriteReviewSheetState();
}

class _WriteReviewSheetState extends State<_WriteReviewSheet> {
  final _commentController = TextEditingController();
  int _rating = 0; // 0 = not selected yet

  // Validation error messages
  String? _ratingError;
  String? _commentError;

  // Submission state
  bool _isSubmitting = false;
  String? _serverError;

  @override
  void dispose() {
    _commentController.dispose();
    super.dispose();
  }

  // ---- Validation helpers ------------------------------------------------

  /// Requirement 14.4: rating must be 1–5.
  String? _validateRating(int rating) {
    if (rating < 1 || rating > 5) {
      return 'Vui lòng chọn số sao (1–5)';
    }
    return null;
  }

  /// Requirement 14.5: comment 10–500 chars.
  String? _validateComment(String text) {
    final len = text.trim().length;
    if (len < 10) {
      return 'Bình luận phải có ít nhất 10 ký tự (hiện tại: $len)';
    }
    if (len > 500) {
      return 'Bình luận không được vượt quá 500 ký tự';
    }
    return null;
  }

  bool _runValidation() {
    final rErr = _validateRating(_rating);
    final cErr = _validateComment(_commentController.text);
    setState(() {
      _ratingError = rErr;
      _commentError = cErr;
      _serverError = null;
    });
    return rErr == null && cErr == null;
  }

  // ---- Submission --------------------------------------------------------

  Future<void> _submit() async {
    if (!_runValidation()) return;

    setState(() {
      _isSubmitting = true;
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
      Navigator.of(context).pop(true); // signal success
    } on ApiAuthorizationException {
      // Requirement 14.2: 403 means user hasn't watched the movie
      setState(() {
        _serverError = 'Bạn cần xem phim trước khi có thể đánh giá.';
        _isSubmitting = false;
      });
    } catch (e) {
      setState(() {
        _serverError = 'Không thể gửi đánh giá. Vui lòng thử lại.';
        _isSubmitting = false;
      });
    }
  }

  // ---- UI ----------------------------------------------------------------

  @override
  Widget build(BuildContext context) {
    final comment = _commentController.text;
    final charCount = comment.trim().length;
    final isOverLimit = charCount > 500;

    return Padding(
      // Pushes the sheet up when the keyboard opens
      padding: EdgeInsets.only(
        bottom: MediaQuery.of(context).viewInsets.bottom,
      ),
      child: Container(
        decoration: const BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
        ),
        child: SafeArea(
          top: false,
          child: Padding(
            padding: const EdgeInsets.fromLTRB(20, 8, 20, 20),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Drag handle
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
                  'Viết đánh giá',
                  style: TextStyle(fontSize: 18, fontWeight: FontWeight.w900),
                ),
                const SizedBox(height: 4),
                Text(
                  'Chia sẻ cảm nhận của bạn về bộ phim này.',
                  style: Theme.of(
                    context,
                  ).textTheme.bodySmall?.copyWith(color: AppColors.muted),
                ),
                const SizedBox(height: 20),

                // --- Star rating selector (Requirement 14.4) ---
                const Text(
                  'Số sao *',
                  style: TextStyle(fontWeight: FontWeight.w700),
                ),
                const SizedBox(height: 8),
                Row(
                  children: List.generate(5, (index) {
                    final starValue = index + 1;
                    return GestureDetector(
                      onTap: () {
                        setState(() {
                          _rating = starValue;
                          _ratingError = _validateRating(starValue);
                        });
                      },
                      child: Padding(
                        padding: const EdgeInsets.only(right: 6),
                        child: Icon(
                          index < _rating
                              ? Icons.star_rounded
                              : Icons.star_border_rounded,
                          color: index < _rating
                              ? AppColors.ink
                              : AppColors.muted,
                          size: 34,
                        ),
                      ),
                    );
                  }),
                ),
                if (_ratingError != null) ...[
                  const SizedBox(height: 4),
                  Text(
                    _ratingError!,
                    style: const TextStyle(
                      color: AppColors.danger,
                      fontSize: 12,
                    ),
                  ),
                ],
                const SizedBox(height: 18),

                // --- Comment field (Requirement 14.5) ---
                Row(
                  children: [
                    const Text(
                      'Bình luận *',
                      style: TextStyle(fontWeight: FontWeight.w700),
                    ),
                    const Spacer(),
                    Text(
                      '$charCount / 500',
                      style: TextStyle(
                        fontSize: 12,
                        color: isOverLimit ? AppColors.danger : AppColors.muted,
                        fontWeight: isOverLimit
                            ? FontWeight.w700
                            : FontWeight.normal,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 8),
                TextField(
                  controller: _commentController,
                  maxLines: 4,
                  onChanged: (_) {
                    // Live char-count update + re-validate if already shown error
                    if (_commentError != null) {
                      setState(() {
                        _commentError = _validateComment(
                          _commentController.text,
                        );
                      });
                    } else {
                      setState(() {}); // just refresh char counter
                    }
                  },
                  decoration: InputDecoration(
                    hintText:
                        'Bạn nghĩ gì về bộ phim này? (tối thiểu 10 ký tự)',
                    errorText: _commentError,
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(8),
                      borderSide: BorderSide(
                        color: _commentError != null
                            ? AppColors.danger
                            : AppColors.line,
                      ),
                    ),
                    enabledBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(8),
                      borderSide: BorderSide(
                        color: _commentError != null
                            ? AppColors.danger
                            : AppColors.line,
                      ),
                    ),
                  ),
                ),
                const SizedBox(height: 16),

                // --- Server-side / 403 error banner ---
                if (_serverError != null)
                  Container(
                    margin: const EdgeInsets.only(bottom: 14),
                    padding: const EdgeInsets.symmetric(
                      horizontal: 14,
                      vertical: 10,
                    ),
                    decoration: BoxDecoration(
                      color: AppColors.danger.withValues(alpha: .08),
                      borderRadius: BorderRadius.circular(8),
                      border: Border.all(
                        color: AppColors.danger.withValues(alpha: .3),
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
                              fontSize: 13,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),

                // --- Submit button (Requirement 14.6) ---
                SizedBox(
                  width: double.infinity,
                  child: FilledButton(
                    onPressed: _isSubmitting ? null : _submit,
                    style: FilledButton.styleFrom(
                      backgroundColor: AppColors.ink,
                      foregroundColor: Colors.white,
                      minimumSize: const Size(double.infinity, 48),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(8),
                      ),
                    ),
                    child: _isSubmitting
                        ? const SizedBox(
                            width: 20,
                            height: 20,
                            child: CircularProgressIndicator(
                              strokeWidth: 2,
                              color: Colors.white,
                            ),
                          )
                        : const Text(
                            'Gửi đánh giá',
                            style: TextStyle(fontWeight: FontWeight.w700),
                          ),
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
