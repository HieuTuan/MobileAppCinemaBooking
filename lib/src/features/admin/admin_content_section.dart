import 'dart:io';

import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:intl/intl.dart';
import 'package:video_player/video_player.dart';

import '../../../api/api_client.dart';
import '../../../models/admin_models.dart' as admin_models;
import '../../../models/admin_models.dart'
    hide Room; // app_models.dart Room is used instead
import '../../../models/review.dart' as review_models;
import '../../core/app_theme.dart';
import '../../core/formatters.dart';
import '../../models/app_models.dart';
import '../../shared/widgets/glass_card.dart';
import '../../state/cinema_store.dart';

// ─── Main Widget ──────────────────────────────────────────────────────────────

class AdminContentSection extends StatefulWidget {
  const AdminContentSection({super.key, required this.store});
  final CinemaStore store;

  @override
  State<AdminContentSection> createState() => _AdminContentSectionState();
}

class _AdminContentSectionState extends State<AdminContentSection> {
  final _api = APIClient();

  bool _moviesLoading = false;
  List<AdminFoodCombo> _combos = [];
  bool _combosLoading = false;
  List<AdminActor> _actors = [];
  bool _actorsLoading = false;
  List<admin_models.Room> _adminRooms = [];
  bool _roomsLoading = false;
  List<review_models.Review> _reviews = [];
  bool _reviewsLoading = false;
  final Set<String> _expandedContentSections = {'reviews'};
  OverlayEntry? _adminToastEntry;

  @override
  void dispose() {
    _adminToastEntry?.remove();
    _adminToastEntry = null;
    super.dispose();
  }

  @override
  void initState() {
    super.initState();
    _loadMovies();
    _loadCombos();
    _loadActors();
    _loadRooms();
    _loadReviews();
  }

  // ─── Load ─────────────────────────────────────────────────────────────────

  Future<void> _loadMovies() async {
    if (mounted) setState(() => _moviesLoading = true);
    try {
      final page = await _api.getMovies(pageSize: 200, quiet: true);
      if (mounted) {
        setState(() => widget.store.replaceMoviesFromApi(page.data));
      }
    } catch (e) {
      if (mounted) {
        _showSnack('Loi tai danh sach phim: ${_errorMsg(e)}', isError: true);
      }
    } finally {
      if (mounted) setState(() => _moviesLoading = false);
    }
  }

  Future<void> _loadCombos() async {
    setState(() => _combosLoading = true);
    try {
      final list = await _api.adminGetFoodCombos();
      if (mounted) setState(() => _combos = list);
    } catch (_) {
    } finally {
      if (mounted) setState(() => _combosLoading = false);
    }
  }

  Future<void> _loadActors() async {
    setState(() => _actorsLoading = true);
    try {
      final list = await _api.adminGetActors();
      if (mounted) setState(() => _actors = list);
    } catch (_) {
    } finally {
      if (mounted) setState(() => _actorsLoading = false);
    }
  }

  Future<void> _loadRooms() async {
    setState(() => _roomsLoading = true);
    try {
      final list = await _api.adminGetRooms();
      if (mounted) {
        setState(() => _adminRooms = list);
        widget.store.replaceRooms(list.map(_roomFromAdmin).toList());
      }
    } catch (_) {
    } finally {
      if (mounted) setState(() => _roomsLoading = false);
    }
  }

  Future<void> _loadReviews() async {
    setState(() => _reviewsLoading = true);
    try {
      final page = await _api.getAdminReviews(pageSize: 50);
      if (mounted) setState(() => _reviews = page.data);
    } catch (e) {
      if (mounted) {
        _showSnack('Lỗi tải đánh giá: ${_errorMsg(e)}', isError: true);
      }
    } finally {
      if (mounted) setState(() => _reviewsLoading = false);
    }
  }

  Future<void> _apiDeleteReview(review_models.Review review) async {
    try {
      await _api.deleteReview(review.id);
      setState(() {
        _reviews = _reviews.where((item) => item.id != review.id).toList();
      });
      _showSnack('Đã xóa đánh giá!');
    } catch (e) {
      _showSnack('Lỗi xóa đánh giá: ${_errorMsg(e)}', isError: true);
    }
  }

  // ─── Movie CRUD ───────────────────────────────────────────────────────────

  Future<void> _apiSaveMovie(Movie uiMovie, {bool isNew = false}) async {
    final req = MovieManagementRequest(
      title: uiMovie.title,
      description: uiMovie.description,
      genres: uiMovie.genres,
      durationMinutes: uiMovie.durationMinutes,
      director: uiMovie.director,
      cast: uiMovie.cast,
      posterUrl: uiMovie.posterUrl,
      trailerUrl: uiMovie.trailerUrl,
      ageRating: uiMovie.ageRating,
      releaseDate: uiMovie.releaseDate,
      status: uiMovie.status == MovieStatus.nowShowing
          ? 'nowShowing'
          : 'comingSoon',
      rating: uiMovie.rating,
    );
    try {
      final saved = isNew
          ? await _api.adminCreateMovie(req)
          : await _api.adminUpdateMovie(uiMovie.id, req);
      final savedMovie = _uiMovieFromApi(saved, fallback: uiMovie);
      if (mounted) {
        setState(() => widget.store.saveMovie(savedMovie));
      } else {
        widget.store.saveMovie(savedMovie);
      }
      _showSnack(isNew ? 'Đã thêm phim!' : 'Đã cập nhật phim!');
    } catch (e) {
      _showSnack('Lỗi: ${_errorMsg(e)}', isError: true);
    }
  }

  Movie _uiMovieFromApi(dynamic movie, {required Movie fallback}) {
    return Movie(
      id: movie.id as String,
      title: movie.title as String,
      description: movie.description as String,
      genres: List<String>.from(movie.genres as List),
      durationMinutes: movie.durationMinutes as int,
      director: movie.director as String,
      cast: List<String>.from(movie.cast as List),
      posterUrl: movie.posterUrl as String,
      trailerUrl: movie.trailerUrl as String,
      rating: (movie.rating as num).toDouble(),
      ageRating: movie.ageRating as String,
      releaseDate: movie.releaseDate as DateTime,
      status: movie.status == 'nowShowing'
          ? MovieStatus.nowShowing
          : MovieStatus.comingSoon,
      heroColor: fallback.heroColor,
    );
  }

  Future<void> _apiDeleteMovie(String movieId) async {
    try {
      await _api.adminDeleteMovie(movieId);
      if (mounted) {
        setState(() => widget.store.deleteMovie(movieId));
      } else {
        widget.store.deleteMovie(movieId);
      }
      _showSnack('Đã xoá phim!');
    } catch (e) {
      final msg = _errorMsg(e);
      _showSnack(
        msg.contains('409') || msg.contains('showtime')
            ? 'Không thể xoá: phim đang có suất chiếu!'
            : 'Lỗi: $msg',
        isError: true,
      );
    }
  }

  // ─── Actor CRUD ───────────────────────────────────────────────────────────

  Future<bool> _apiSaveActor(
    AdminActor actor, {
    bool isNew = false,
    bool showSnack = false,
  }) async {
    final req = ActorManagementRequest(
      name: actor.name,
      avatarUrl: actor.avatarUrl,
      description: actor.description,
    );
    try {
      AdminActor saved;
      if (isNew) {
        saved = await _api.adminCreateActor(req);
        setState(() => _actors = [..._actors, saved]..sort(_sortActors));
      } else {
        saved = await _api.adminUpdateActor(actor.id, req);
        setState(() {
          _actors = _actors.map((a) => a.id == actor.id ? saved : a).toList()
            ..sort(_sortActors);
        });
      }
      return true;
    } catch (e) {
      if (showSnack) {
        _showSnack('Lỗi: ${_errorMsg(e)}', isError: true);
      }
      return false;
    }
  }

  Future<void> _apiDeleteActor(AdminActor actor) async {
    try {
      await _api.adminDeleteActor(actor.id);
      setState(() => _actors = _actors.where((a) => a.id != actor.id).toList());
      _showSnack('Đã xóa diễn viên!');
    } catch (e) {
      _showSnack('Lỗi: ${_errorMsg(e)}', isError: true);
    }
  }

  int _sortActors(AdminActor a, AdminActor b) =>
      a.name.toLowerCase().compareTo(b.name.toLowerCase());

  // ─── Combo CRUD ───────────────────────────────────────────────────────────

  Future<void> _apiSaveCombo(AdminFoodCombo combo, {bool isNew = false}) async {
    final req = FoodComboManagementRequest(
      name: combo.name,
      description: combo.description,
      price: combo.price,
      quantity: combo.quantity,
      imageUrl: combo.imageUrl,
      isActive: combo.isActive,
    );
    try {
      AdminFoodCombo saved;
      if (isNew) {
        saved = await _api.adminCreateFoodCombo(req);
        setState(() => _combos = [saved, ..._combos]);
      } else {
        saved = await _api.adminUpdateFoodCombo(combo.id, req);
        setState(() {
          _combos = _combos.map((c) => c.id == combo.id ? saved : c).toList();
        });
      }
      _showSnack(isNew ? 'Đã thêm combo!' : 'Đã cập nhật combo!');
    } catch (e) {
      _showSnack('Lỗi: ${_errorMsg(e)}', isError: true);
    }
  }

  Future<void> _apiToggleCombo(AdminFoodCombo combo) async {
    try {
      final updated = await _api.adminToggleFoodCombo(
        combo.id,
        isActive: !combo.isActive,
      );
      setState(() {
        _combos = _combos.map((c) => c.id == combo.id ? updated : c).toList();
      });
    } catch (e) {
      _showSnack('Lỗi: ${_errorMsg(e)}', isError: true);
    }
  }

  // ─── Open actor dialog (standalone) ────────────────────────────────────────────

  void _openActorDialog(BuildContext context, {AdminActor? actor}) {
    showDialog<void>(
      context: context,
      builder: (_) => _buildActorDialogWidget(
        context: context,
        actor: actor,
        onSave: (next) =>
            _apiSaveActor(next, isNew: actor == null, showSnack: false),
      ),
    );
  }

  // ─── Helpers ──────────────────────────────────────────────────────────────

  void _showSnack(String msg, {bool isError = false}) {
    if (!mounted) return;
    final overlay = Overlay.maybeOf(context, rootOverlay: true);
    if (overlay == null) return;

    _adminToastEntry?.remove();
    _adminToastEntry = OverlayEntry(
      builder: (context) {
        final top = MediaQuery.paddingOf(context).top + 78;
        final color = isError ? Colors.redAccent : AppColors.success;
        return Positioned(
          top: top,
          left: 16,
          right: 16,
          child: Material(
            color: Colors.transparent,
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
              decoration: BoxDecoration(
                color: color,
                borderRadius: BorderRadius.circular(12),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withValues(alpha: .18),
                    blurRadius: 18,
                    offset: const Offset(0, 8),
                  ),
                ],
              ),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Icon(
                    isError
                        ? Icons.error_outline_rounded
                        : Icons.check_circle_outline_rounded,
                    color: Colors.white,
                    size: 18,
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: Text(
                      msg,
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 13,
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        );
      },
    );
    overlay.insert(_adminToastEntry!);
    Future<void>.delayed(const Duration(seconds: 3), () {
      if (_adminToastEntry?.mounted ?? false) {
        _adminToastEntry?.remove();
      }
      _adminToastEntry = null;
    });
  }

  String _errorMsg(Object e) {
    final text = e.toString().replaceFirst('Exception: ', '');
    if (text.contains('/api/admin/movies') &&
        (text.contains('500') || text.contains('bad response'))) {
      return 'Không lưu được phim. Hãy restart backend để cập nhật schema; nếu vẫn lỗi, kiểm tra URL poster/trailer có quá dài không.';
    }
    final messageMatch = RegExp(r'message:\s*([^,}]+)').firstMatch(text);
    if (messageMatch != null) return messageMatch.group(1)!.trim();
    return text.length > 180 ? '${text.substring(0, 180)}...' : text;
  }

  String _movieTitleForReview(review_models.Review review) {
    for (final movie in widget.store.movies) {
      if (movie.id == review.movieId) return movie.title;
    }
    return review.movieId;
  }

  Room _roomFromAdmin(admin_models.Room room) {
    return Room(
      id: room.id,
      cinemaId: room.theaterId,
      name: room.name,
      capacity: room.totalSeats,
      screenType: room.screenType,
      status: room.status.toLowerCase() == 'maintenance'
          ? RoomStatus.maintenance
          : RoomStatus.ready,
    );
  }

  Future<void> _apiCreateRoom(RoomRequest request) async {
    try {
      final saved = await _api.createAdminRoom(request);
      setState(() {
        _adminRooms = [
          saved,
          ..._adminRooms.where((room) => room.id != saved.id),
        ];
      });
      widget.store.saveRoom(_roomFromAdmin(saved));
      _showSnack('Đã tạo phòng chiếu!');
    } catch (e) {
      _showSnack('Lỗi tạo phòng: ${_errorMsg(e)}', isError: true);
    }
  }

  Future<void> _apiUpdateRoomStatus(Room room, bool ready) async {
    final nextStatus = ready ? 'ready' : 'maintenance';
    try {
      final saved = await _api.updateAdminRoomStatus(room.id, nextStatus);
      setState(() {
        _adminRooms = _adminRooms
            .map((item) => item.id == saved.id ? saved : item)
            .toList();
      });
      widget.store.saveRoom(_roomFromAdmin(saved));
      _showSnack(ready ? 'Phòng đã sẵn sàng' : 'Đã chuyển phòng sang bảo trì');
    } catch (e) {
      _showSnack('Lỗi cập nhật phòng: ${_errorMsg(e)}', isError: true);
    }
  }

  admin_models.Room? _adminRoomFor(String roomId) {
    for (final room in _adminRooms) {
      if (room.id == roomId) return room;
    }
    return null;
  }

  String _seatTypeLabel(String type) {
    return switch (type.toLowerCase()) {
      'vip' => 'Ghế VIP',
      'couple' => 'Ghế đôi',
      _ => 'Ghế thường',
    };
  }

  Color _seatTypeColor(String type) {
    return switch (type.toLowerCase()) {
      'vip' => AppColors.gold,
      'couple' => const Color(0xFFE56B8C),
      _ => AppColors.ink,
    };
  }

  Future<void> _apiCreateShowtime(ShowtimeScheduleRequest request) async {
    try {
      final saved = await _api.createAdminShowtime(request);
      widget.store.saveShowtime(
        Showtime(
          id: saved.id,
          movieId: saved.movieId,
          roomId: saved.roomId,
          startTime: saved.startTime,
          endTime: saved.endTime,
          basePrice: saved.basePrice,
          vipSeatPrice: saved.vipSeatPrice,
          coupleSeatPrice: saved.coupleSeatPrice,
          status: saved.status,
        ),
      );
      _showSnack('Đã tạo suất chiếu!');
    } catch (e) {
      _showSnack('Lỗi tạo suất chiếu: ${_errorMsg(e)}', isError: true);
    }
  }

  Future<void> _apiDeleteShowtime(Showtime showtime) async {
    try {
      await _api.deleteAdminShowtime(showtime.id);
      widget.store.deleteShowtime(showtime.id);
      _showSnack('Đã huỷ suất chiếu!');
    } catch (e) {
      _showSnack('Lỗi huỷ suất chiếu: ${_errorMsg(e)}', isError: true);
    }
  }

  String _imageContentType(String filename) {
    final n = filename.toLowerCase();
    if (n.endsWith('.png')) return 'image/png';
    if (n.endsWith('.webp')) return 'image/webp';
    return 'image/jpeg';
  }

  String _videoContentType(String filename) {
    final n = filename.toLowerCase();
    if (n.endsWith('.mov')) return 'video/quicktime';
    if (n.endsWith('.webm')) return 'video/webm';
    return 'video/mp4';
  }

  // ─── Build ────────────────────────────────────────────────────────────────

  @override
  Widget build(BuildContext context) {
    final store = widget.store;
    return _buildAccordionContent(context, store);
    // ignore: dead_code
    return ListView(
      padding: const EdgeInsets.fromLTRB(16, 8, 16, 100),
      children: [
        // Metrics
        Row(
          children: [
            Expanded(
              child: MetricCard(
                label: 'Phim',
                value: '${store.movies.length}',
                icon: Icons.local_movies_rounded,
              ),
            ),
            const SizedBox(width: 10),
            Expanded(
              child: MetricCard(
                label: 'Suất chiếu',
                value: '${store.showtimes.length}',
                icon: Icons.event_rounded,
                color: AppColors.success,
              ),
            ),
          ],
        ),

        // ── Movies ────────────────────────────────────────────────────────
        SectionTitle(
          title: 'Quản lý đánh giá',
          action: IconButton(
            tooltip: 'Tải lại đánh giá',
            onPressed: _reviewsLoading ? null : _loadReviews,
            icon: const Icon(Icons.refresh_rounded),
          ),
        ),
        if (_reviewsLoading)
          const Padding(
            padding: EdgeInsets.symmetric(vertical: 24),
            child: Center(child: CircularProgressIndicator()),
          )
        else if (_reviews.isEmpty)
          const GlassCard(
            child: Padding(
              padding: EdgeInsets.all(16),
              child: Text(
                'Chưa có đánh giá nào.',
                style: TextStyle(color: AppColors.muted),
              ),
            ),
          )
        else
          ..._reviews.map(
            (review) => GlassCard(
              margin: const EdgeInsets.only(bottom: 10),
              child: ListTile(
                contentPadding: EdgeInsets.zero,
                leading: CircleAvatar(
                  backgroundColor: AppColors.ink,
                  foregroundColor: Colors.white,
                  child: Text(
                    '${review.rating}',
                    style: const TextStyle(fontWeight: FontWeight.w900),
                  ),
                ),
                title: Text(
                  _movieTitleForReview(review),
                  style: const TextStyle(fontWeight: FontWeight.w900),
                ),
                subtitle: Text(
                  '${review.userName} • ${review.rating}/10 • ${review.comment}',
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                ),
                trailing: IconButton(
                  tooltip: 'Xóa đánh giá',
                  onPressed: () => _confirmDelete(
                    context,
                    title: 'Xóa đánh giá ${review.rating}/10?',
                    subtitle: 'Hành động này không thể hoàn tác.',
                    onConfirm: () => _apiDeleteReview(review),
                  ),
                  icon: const Icon(Icons.delete_outline_rounded),
                ),
              ),
            ),
          ),
        SectionTitle(
          title: 'Quản lý phim',
          action: FilledButton.icon(
            onPressed: () => _movieEditorDialog(context),
            icon: const Icon(Icons.add_rounded),
            label: const Text('Thêm'),
          ),
        ),
        ...store.movies.map(
          (movie) => GlassCard(
            margin: const EdgeInsets.only(bottom: 10),
            child: ListTile(
              contentPadding: EdgeInsets.zero,
              leading: ClipRRect(
                borderRadius: BorderRadius.circular(8),
                child: CachedNetworkImage(
                  imageUrl: movie.posterUrl,
                  width: 48,
                  height: 64,
                  fit: BoxFit.cover,
                  placeholder: (_, __) => Container(
                    width: 48,
                    height: 64,
                    color: AppColors.pearl,
                    child: const Center(
                      child: SizedBox(
                        width: 20,
                        height: 20,
                        child: CircularProgressIndicator(strokeWidth: 2),
                      ),
                    ),
                  ),
                  errorWidget: (_, __, ___) => Container(
                    width: 48,
                    height: 64,
                    color: AppColors.pearl,
                    child: const Icon(Icons.broken_image_outlined),
                  ),
                ),
              ),
              title: Text(
                movie.title,
                style: const TextStyle(fontWeight: FontWeight.w900),
              ),
              subtitle: Text(
                '${movie.genres.join(', ')} • ${movie.ageRating} • ${movie.director}',
              ),
              trailing: Wrap(
                children: [
                  IconButton(
                    tooltip: 'Sửa phim',
                    onPressed: () => _movieEditorDialog(context, movie: movie),
                    icon: const Icon(Icons.edit_outlined),
                  ),
                  IconButton(
                    tooltip: 'Xóa phim',
                    onPressed: () => _confirmDelete(
                      context,
                      title: 'Xoá phim "${movie.title}"?',
                      subtitle:
                          'Hành động này không thể hoàn tác. Phim có suất chiếu active sẽ không bị xoá.',
                      onConfirm: () => _apiDeleteMovie(movie.id),
                    ),
                    icon: const Icon(Icons.delete_outline_rounded),
                  ),
                ],
              ),
            ),
          ),
        ),

        // ── Genres ────────────────────────────────────────────────────────
        SectionTitle(
          title: 'Danh mục thể loại',
          action: TextButton.icon(
            onPressed: () => _genreDialog(context),
            icon: const Icon(Icons.add_rounded),
            label: const Text('Thêm'),
          ),
        ),
        GlassCard(
          child: Wrap(
            spacing: 8,
            runSpacing: 8,
            children: [
              for (final genre in store.genres.skip(1))
                InputChip(
                  avatar: const Icon(Icons.category_outlined, size: 18),
                  label: Text(genre),
                  onPressed: () => _genreDialog(context, genre: genre),
                  onDeleted: () => store.deleteGenre(genre),
                ),
            ],
          ),
        ),

        // ── Actors ────────────────────────────────────────────────────────
        SectionTitle(
          title: 'Quản lý diễn viên',
          action: FilledButton.icon(
            onPressed: () => _openActorDialog(context),
            icon: const Icon(Icons.person_add_alt_rounded),
            label: const Text('Thêm'),
          ),
        ),
        if (_actorsLoading)
          const Padding(
            padding: EdgeInsets.symmetric(vertical: 24),
            child: Center(child: CircularProgressIndicator()),
          )
        else if (_actors.isEmpty)
          const GlassCard(
            child: Padding(
              padding: EdgeInsets.all(16),
              child: Text(
                'Chưa có diễn viên. Nhấn "Thêm" để tạo hồ sơ.',
                style: TextStyle(color: AppColors.muted),
              ),
            ),
          )
        else
          ..._actors.map(
            (actor) => GlassCard(
              margin: const EdgeInsets.only(bottom: 10),
              child: ListTile(
                contentPadding: EdgeInsets.zero,
                leading: CircleAvatar(
                  backgroundColor: AppColors.pearl,
                  backgroundImage: actor.avatarUrl.isEmpty
                      ? null
                      : CachedNetworkImageProvider(actor.avatarUrl),
                  child: actor.avatarUrl.isEmpty
                      ? const Icon(Icons.person_outline_rounded)
                      : null,
                ),
                title: Text(
                  actor.name,
                  style: const TextStyle(fontWeight: FontWeight.w900),
                ),
                subtitle: Text(
                  actor.description.isEmpty
                      ? 'Chưa có mô tả'
                      : actor.description,
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                ),
                trailing: Wrap(
                  children: [
                    IconButton(
                      tooltip: 'Sửa diễn viên',
                      onPressed: () => _openActorDialog(context, actor: actor),
                      icon: const Icon(Icons.edit_outlined),
                    ),
                    IconButton(
                      tooltip: 'Xóa diễn viên',
                      onPressed: () => _confirmDelete(
                        context,
                        title: 'Xóa diễn viên "${actor.name}"?',
                        subtitle: 'Hành động này không thể hoàn tác.',
                        onConfirm: () => _apiDeleteActor(actor),
                      ),
                      icon: const Icon(Icons.delete_outline_rounded),
                    ),
                  ],
                ),
              ),
            ),
          ),

        // ── Rooms ─────────────────────────────────────────────────────────
        SectionTitle(
          title: 'Quản lý phòng chiếu',
          action: FilledButton.icon(
            onPressed: () => _roomDialog(context),
            icon: const Icon(Icons.meeting_room_rounded),
            label: const Text('Thêm phòng'),
          ),
        ),
        if (_roomsLoading)
          const Padding(
            padding: EdgeInsets.symmetric(vertical: 24),
            child: Center(child: CircularProgressIndicator()),
          )
        else if (store.rooms.isEmpty)
          const GlassCard(
            child: Padding(
              padding: EdgeInsets.all(16),
              child: Text(
                'Chưa có phòng chiếu. Nhấn "Thêm phòng" để tạo layout ghế.',
                style: TextStyle(color: AppColors.muted),
              ),
            ),
          )
        else
          ...store.rooms.map(
            (room) => GlassCard(
              margin: const EdgeInsets.only(bottom: 10),
              child: ListTile(
                contentPadding: EdgeInsets.zero,
                leading: const Icon(Icons.meeting_room_rounded),
                title: Text('${room.name} • ${room.screenType}'),
                subtitle: Text(
                  'Sức chứa ${room.capacity} • ${room.status == RoomStatus.ready ? 'Sẵn sàng' : 'Bảo trì'}',
                ),
                trailing: Wrap(
                  crossAxisAlignment: WrapCrossAlignment.center,
                  children: [
                    IconButton(
                      tooltip: 'Xem sơ đồ ghế',
                      onPressed: () {
                        final adminRoom = _adminRoomFor(room.id);
                        if (adminRoom == null) {
                          _showSnack(
                            'Chưa tải được sơ đồ ghế của phòng này.',
                            isError: true,
                          );
                          return;
                        }
                        _roomSeatLayoutDialog(context, adminRoom);
                      },
                      icon: const Icon(Icons.event_seat_outlined),
                    ),
                    Switch(
                      value: room.status == RoomStatus.ready,
                      onChanged: (value) => _apiUpdateRoomStatus(room, value),
                    ),
                  ],
                ),
              ),
            ),
          ),

        // ── Showtimes ─────────────────────────────────────────────────────
        SectionTitle(
          title: 'Lịch chiếu',
          action: FilledButton.icon(
            onPressed: () => _showtimeDialog(context),
            icon: const Icon(Icons.add_alarm_rounded),
            label: const Text('Tạo suất'),
          ),
        ),
        ...store.showtimes.map((showtime) {
          final movie = store.movieById(showtime.movieId);
          final room = store.roomById(showtime.roomId);
          return GlassCard(
            margin: const EdgeInsets.only(bottom: 10),
            child: ListTile(
              contentPadding: EdgeInsets.zero,
              leading: const Icon(Icons.schedule_rounded),
              title: Text(movie.title),
              subtitle: Text(
                '${room.name} • ${shortDate(showtime.startTime)} ${shortTime(showtime.startTime)}',
              ),
              trailing: Wrap(
                spacing: 6,
                children: [
                  Text(money(showtime.basePrice)),
                  Text(showtime.statusLabel),
                  IconButton(
                    tooltip: 'Xóa suất',
                    onPressed: () => _confirmDelete(
                      context,
                      title: 'Huỷ suất chiếu "${movie.title}"?',
                      subtitle:
                          'Suất chiếu sẽ được chuyển sang trạng thái cancelled trên backend.',
                      onConfirm: () => _apiDeleteShowtime(showtime),
                    ),
                    icon: const Icon(Icons.delete_outline_rounded),
                  ),
                ],
              ),
            ),
          );
        }),

        // ── Food Combos ───────────────────────────────────────────────────
        SectionTitle(
          title: 'Quản lý Combo bắp nước',
          action: FilledButton.icon(
            onPressed: () => _comboDialog(context),
            icon: const Icon(Icons.add_rounded),
            label: const Text('Thêm'),
          ),
        ),
        if (_combosLoading)
          const Padding(
            padding: EdgeInsets.symmetric(vertical: 24),
            child: Center(child: CircularProgressIndicator()),
          )
        else if (_combos.isEmpty)
          const GlassCard(
            child: Padding(
              padding: EdgeInsets.all(16),
              child: Text(
                'Chưa có combo nào. Nhấn "Thêm" để tạo mới.',
                style: TextStyle(color: AppColors.muted),
              ),
            ),
          )
        else
          ..._combos.map(
            (combo) => GlassCard(
              margin: const EdgeInsets.only(bottom: 10),
              child: ListTile(
                contentPadding: EdgeInsets.zero,
                leading: combo.imageUrl.isNotEmpty
                    ? ClipRRect(
                        borderRadius: BorderRadius.circular(8),
                        child: CachedNetworkImage(
                          imageUrl: combo.imageUrl,
                          width: 48,
                          height: 48,
                          fit: BoxFit.cover,
                          errorWidget: (_, __, ___) =>
                              const Icon(Icons.fastfood_rounded, size: 32),
                        ),
                      )
                    : const Icon(Icons.fastfood_rounded, size: 32),
                title: Row(
                  children: [
                    Text(
                      combo.name,
                      style: const TextStyle(fontWeight: FontWeight.w900),
                    ),
                    const SizedBox(width: 8),
                    if (!combo.isActive)
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 6,
                          vertical: 2,
                        ),
                        decoration: BoxDecoration(
                          color: Colors.grey.withValues(alpha: .18),
                          borderRadius: BorderRadius.circular(4),
                        ),
                        child: const Text(
                          'Ẩn',
                          style: TextStyle(
                            fontSize: 11,
                            color: AppColors.muted,
                          ),
                        ),
                      ),
                  ],
                ),
                subtitle: Text(
                  '${NumberFormat.decimalPattern('vi').format(combo.price)} VND'
                  ' • Còn ${combo.quantity}'
                  '${combo.description.isNotEmpty ? ' • ${combo.description}' : ''}',
                ),
                trailing: Wrap(
                  children: [
                    IconButton(
                      tooltip: 'Sửa combo',
                      onPressed: () => _comboDialog(context, combo: combo),
                      icon: const Icon(Icons.edit_outlined),
                    ),
                    IconButton(
                      tooltip: combo.isActive ? 'Ẩn combo' : 'Hiện combo',
                      onPressed: () => _apiToggleCombo(combo),
                      icon: Icon(
                        combo.isActive
                            ? Icons.visibility_off_outlined
                            : Icons.visibility_outlined,
                        color: combo.isActive
                            ? AppColors.muted
                            : AppColors.success,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
      ],
    );
  }

  // ─── Movie editor dialog (step-by-step wizard) ───────────────────────────

  Widget _buildAccordionContent(BuildContext context, CinemaStore store) {
    return ListView(
      padding: const EdgeInsets.fromLTRB(16, 8, 16, 100),
      children: [
        Row(
          children: [
            Expanded(
              child: MetricCard(
                label: 'Phim',
                value: '${store.movies.length}',
                icon: Icons.local_movies_rounded,
              ),
            ),
            const SizedBox(width: 10),
            Expanded(
              child: MetricCard(
                label: 'Suất chiếu',
                value: '${store.showtimes.length}',
                icon: Icons.event_rounded,
                color: AppColors.success,
              ),
            ),
          ],
        ),
        const SizedBox(height: 14),
        _adminSection(
          id: 'reviews',
          title: 'Quản lý đánh giá',
          icon: Icons.star_rate_rounded,
          badge: _reviewsLoading ? 'Đang tải' : '${_reviews.length}',
          action: IconButton(
            tooltip: 'Tải lại đánh giá',
            onPressed: _reviewsLoading ? null : _loadReviews,
            icon: const Icon(Icons.refresh_rounded),
          ),
          children: _reviewChildren(context),
        ),
        _adminSection(
          id: 'movies',
          title: 'Quản lý phim',
          icon: Icons.local_movies_rounded,
          badge: _moviesLoading ? 'Đang tải' : '${store.movies.length}',
          action: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              IconButton(
                tooltip: 'Tải lại phim từ API',
                onPressed: _moviesLoading ? null : _loadMovies,
                icon: const Icon(Icons.refresh_rounded),
              ),
              FilledButton.icon(
                onPressed: () => _movieEditorDialog(context),
                icon: const Icon(Icons.add_rounded),
                label: const Text('Thêm'),
              ),
            ],
          ),
          children: _movieChildren(context, store),
        ),
        _adminSection(
          id: 'genres',
          title: 'Danh mục thể loại',
          icon: Icons.category_rounded,
          badge: '${store.genres.skip(1).length}',
          action: TextButton.icon(
            onPressed: () => _genreDialog(context),
            icon: const Icon(Icons.add_rounded),
            label: const Text('Thêm'),
          ),
          children: _genreChildren(context, store),
        ),
        _adminSection(
          id: 'actors',
          title: 'Quản lý diễn viên',
          icon: Icons.groups_rounded,
          badge: _actorsLoading ? 'Đang tải' : '${_actors.length}',
          action: FilledButton.icon(
            onPressed: () => _openActorDialog(context),
            icon: const Icon(Icons.person_add_alt_rounded),
            label: const Text('Thêm'),
          ),
          children: _actorChildren(context),
        ),
        _adminSection(
          id: 'rooms',
          title: 'Quản lý phòng chiếu',
          icon: Icons.meeting_room_rounded,
          badge: _roomsLoading ? 'Đang tải' : '${store.rooms.length}',
          action: FilledButton.icon(
            onPressed: () => _roomDialog(context),
            icon: const Icon(Icons.meeting_room_rounded),
            label: const Text('Thêm phòng'),
          ),
          children: _roomChildren(context, store),
        ),
        _adminSection(
          id: 'showtimes',
          title: 'Lịch chiếu',
          icon: Icons.schedule_rounded,
          badge: '${store.showtimes.length}',
          action: FilledButton.icon(
            onPressed: () => _showtimeDialog(context),
            icon: const Icon(Icons.add_alarm_rounded),
            label: const Text('Tạo suất'),
          ),
          children: _showtimeChildren(context, store),
        ),
        _adminSection(
          id: 'combos',
          title: 'Quản lý Combo bắp nước',
          icon: Icons.fastfood_rounded,
          badge: _combosLoading ? 'Đang tải' : '${_combos.length}',
          action: FilledButton.icon(
            onPressed: () => _comboDialog(context),
            icon: const Icon(Icons.add_rounded),
            label: const Text('Thêm'),
          ),
          children: _comboChildren(context),
        ),
      ],
    );
  }

  Widget _adminSection({
    required String id,
    required String title,
    required IconData icon,
    required String badge,
    required Widget action,
    required List<Widget> children,
  }) {
    return _AdminAccordionSection(
      title: title,
      icon: icon,
      badge: badge,
      isExpanded: _expandedContentSections.contains(id),
      onToggle: () => setState(() {
        if (_expandedContentSections.contains(id)) {
          _expandedContentSections.remove(id);
        } else {
          _expandedContentSections.add(id);
        }
      }),
      children: [_sectionActionRow(action), ...children],
    );
  }

  Widget _sectionActionRow(Widget action) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 10),
      child: Align(alignment: Alignment.centerRight, child: action),
    );
  }

  List<Widget> _reviewChildren(BuildContext context) {
    if (_reviewsLoading) return [_loadingContent()];
    if (_reviews.isEmpty) return [_emptyContent('Chưa có đánh giá nào.')];
    return _reviews
        .map(
          (review) => GlassCard(
            margin: const EdgeInsets.only(bottom: 10),
            child: Padding(
              padding: const EdgeInsets.symmetric(vertical: 2),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      CircleAvatar(
                        backgroundColor: AppColors.ink,
                        foregroundColor: Colors.white,
                        child: Text(
                          '${review.rating}',
                          style: const TextStyle(fontWeight: FontWeight.w900),
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              _movieTitleForReview(review),
                              maxLines: 2,
                              overflow: TextOverflow.ellipsis,
                              style: const TextStyle(
                                color: AppColors.ink,
                                fontWeight: FontWeight.w900,
                              ),
                            ),
                            const SizedBox(height: 4),
                            Wrap(
                              spacing: 8,
                              runSpacing: 4,
                              crossAxisAlignment: WrapCrossAlignment.center,
                              children: [
                                Text(
                                  review.userName,
                                  style: const TextStyle(
                                    color: AppColors.muted,
                                    fontWeight: FontWeight.w700,
                                  ),
                                ),
                                Text(
                                  '${review.rating}/10',
                                  style: const TextStyle(
                                    color: AppColors.ink,
                                    fontWeight: FontWeight.w900,
                                  ),
                                ),
                                Text(
                                  shortDate(review.createdAt),
                                  style: const TextStyle(
                                    color: AppColors.muted,
                                    fontSize: 12,
                                  ),
                                ),
                                if (review.isVerified)
                                  Container(
                                    padding: const EdgeInsets.symmetric(
                                      horizontal: 7,
                                      vertical: 2,
                                    ),
                                    decoration: BoxDecoration(
                                      color: AppColors.success.withValues(
                                        alpha: .12,
                                      ),
                                      borderRadius: BorderRadius.circular(999),
                                    ),
                                    child: const Text(
                                      'Đã xem',
                                      style: TextStyle(
                                        color: AppColors.success,
                                        fontSize: 11,
                                        fontWeight: FontWeight.w900,
                                      ),
                                    ),
                                  ),
                              ],
                            ),
                          ],
                        ),
                      ),
                      IconButton(
                        tooltip: 'Xóa đánh giá',
                        onPressed: () => _confirmDelete(
                          context,
                          title: 'Xóa đánh giá ${review.rating}/10?',
                          subtitle: 'Hành động này không thể hoàn tác.',
                          onConfirm: () => _apiDeleteReview(review),
                        ),
                        icon: const Icon(Icons.delete_outline_rounded),
                      ),
                    ],
                  ),
                  const SizedBox(height: 12),
                  Container(
                    width: double.infinity,
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: AppColors.pearl.withValues(alpha: .7),
                      borderRadius: BorderRadius.circular(8),
                      border: Border.all(color: AppColors.line),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text(
                          'Nội dung đánh giá',
                          style: TextStyle(
                            color: AppColors.muted,
                            fontSize: 12,
                            fontWeight: FontWeight.w900,
                          ),
                        ),
                        const SizedBox(height: 6),
                        Text(
                          review.comment.trim().isEmpty
                              ? 'Không có nội dung.'
                              : review.comment.trim(),
                          style: const TextStyle(
                            color: AppColors.ink,
                            height: 1.35,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ),
        )
        .toList();
  }

  List<Widget> _movieChildren(BuildContext context, CinemaStore store) {
    if (_moviesLoading) return [_loadingContent()];
    if (store.movies.isEmpty) return [_emptyContent('Chưa có phim nào.')];
    return store.movies
        .map(
          (movie) => GlassCard(
            margin: const EdgeInsets.only(bottom: 10),
            child: ListTile(
              contentPadding: EdgeInsets.zero,
              leading: ClipRRect(
                borderRadius: BorderRadius.circular(8),
                child: CachedNetworkImage(
                  imageUrl: movie.posterUrl,
                  width: 48,
                  height: 64,
                  fit: BoxFit.cover,
                  placeholder: (_, __) => Container(
                    width: 48,
                    height: 64,
                    color: AppColors.pearl,
                    child: const Center(
                      child: SizedBox(
                        width: 20,
                        height: 20,
                        child: CircularProgressIndicator(strokeWidth: 2),
                      ),
                    ),
                  ),
                  errorWidget: (_, __, ___) => Container(
                    width: 48,
                    height: 64,
                    color: AppColors.pearl,
                    child: const Icon(Icons.broken_image_outlined),
                  ),
                ),
              ),
              title: Text(
                movie.title,
                style: const TextStyle(fontWeight: FontWeight.w900),
              ),
              subtitle: Text(
                '${movie.genres.join(', ')} • ${movie.ageRating} • ${movie.director}',
              ),
              trailing: Wrap(
                children: [
                  IconButton(
                    tooltip: 'Sửa phim',
                    onPressed: () => _movieEditorDialog(context, movie: movie),
                    icon: const Icon(Icons.edit_outlined),
                  ),
                  IconButton(
                    tooltip: 'Xóa phim',
                    onPressed: () => _confirmDelete(
                      context,
                      title: 'Xoá phim "${movie.title}"?',
                      subtitle:
                          'Hành động này không thể hoàn tác. Phim có suất chiếu active sẽ không bị xoá.',
                      onConfirm: () => _apiDeleteMovie(movie.id),
                    ),
                    icon: const Icon(Icons.delete_outline_rounded),
                  ),
                ],
              ),
            ),
          ),
        )
        .toList();
  }

  List<Widget> _genreChildren(BuildContext context, CinemaStore store) {
    final genres = store.genres.skip(1).toList();
    if (genres.isEmpty) return [_emptyContent('Chưa có thể loại nào.')];
    return [
      GlassCard(
        child: Wrap(
          spacing: 8,
          runSpacing: 8,
          children: [
            for (final genre in genres)
              InputChip(
                avatar: const Icon(Icons.category_outlined, size: 18),
                label: Text(genre),
                onPressed: () => _genreDialog(context, genre: genre),
                onDeleted: () => store.deleteGenre(genre),
              ),
          ],
        ),
      ),
    ];
  }

  List<Widget> _actorChildren(BuildContext context) {
    if (_actorsLoading) return [_loadingContent()];
    if (_actors.isEmpty) {
      return [_emptyContent('Chưa có diễn viên. Nhấn "Thêm" để tạo hồ sơ.')];
    }
    return _actors
        .map(
          (actor) => GlassCard(
            margin: const EdgeInsets.only(bottom: 10),
            child: ListTile(
              contentPadding: EdgeInsets.zero,
              leading: CircleAvatar(
                backgroundColor: AppColors.pearl,
                backgroundImage: actor.avatarUrl.isEmpty
                    ? null
                    : CachedNetworkImageProvider(actor.avatarUrl),
                child: actor.avatarUrl.isEmpty
                    ? const Icon(Icons.person_outline_rounded)
                    : null,
              ),
              title: Text(
                actor.name,
                style: const TextStyle(fontWeight: FontWeight.w900),
              ),
              subtitle: Text(
                actor.description.isEmpty ? 'Chưa có mô tả' : actor.description,
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
              ),
              trailing: Wrap(
                children: [
                  IconButton(
                    tooltip: 'Sửa diễn viên',
                    onPressed: () => _openActorDialog(context, actor: actor),
                    icon: const Icon(Icons.edit_outlined),
                  ),
                  IconButton(
                    tooltip: 'Xóa diễn viên',
                    onPressed: () => _confirmDelete(
                      context,
                      title: 'Xóa diễn viên "${actor.name}"?',
                      subtitle: 'Hành động này không thể hoàn tác.',
                      onConfirm: () => _apiDeleteActor(actor),
                    ),
                    icon: const Icon(Icons.delete_outline_rounded),
                  ),
                ],
              ),
            ),
          ),
        )
        .toList();
  }

  List<Widget> _roomChildren(BuildContext context, CinemaStore store) {
    if (_roomsLoading) return [_loadingContent()];
    if (store.rooms.isEmpty) {
      return [
        _emptyContent(
          'Chưa có phòng chiếu. Nhấn "Thêm phòng" để tạo layout ghế.',
        ),
      ];
    }
    return store.rooms
        .map(
          (room) => GlassCard(
            margin: const EdgeInsets.only(bottom: 10),
            child: ListTile(
              contentPadding: EdgeInsets.zero,
              leading: const Icon(Icons.meeting_room_rounded),
              title: Text('${room.name} • ${room.screenType}'),
              subtitle: Text(
                'Sức chứa ${room.capacity} • ${room.status == RoomStatus.ready ? 'Sẵn sàng' : 'Bảo trì'}',
              ),
              trailing: Wrap(
                crossAxisAlignment: WrapCrossAlignment.center,
                children: [
                  IconButton(
                    tooltip: 'Xem sơ đồ ghế',
                    onPressed: () {
                      final adminRoom = _adminRoomFor(room.id);
                      if (adminRoom == null) {
                        _showSnack(
                          'Chưa tải được sơ đồ ghế của phòng này.',
                          isError: true,
                        );
                        return;
                      }
                      _roomSeatLayoutDialog(context, adminRoom);
                    },
                    icon: const Icon(Icons.event_seat_outlined),
                  ),
                  Switch(
                    value: room.status == RoomStatus.ready,
                    onChanged: (value) => _apiUpdateRoomStatus(room, value),
                  ),
                ],
              ),
            ),
          ),
        )
        .toList();
  }

  List<Widget> _showtimeChildren(BuildContext context, CinemaStore store) {
    if (store.showtimes.isEmpty) return [_emptyContent('Chưa có lịch chiếu.')];
    return store.showtimes.map((showtime) {
      final movie = store.movieById(showtime.movieId);
      final room = store.roomById(showtime.roomId);
      return GlassCard(
        margin: const EdgeInsets.only(bottom: 10),
        child: ListTile(
          contentPadding: EdgeInsets.zero,
          leading: const Icon(Icons.schedule_rounded),
          title: Text(movie.title),
          subtitle: Text(
            '${room.name} • ${shortDate(showtime.startTime)} ${shortTime(showtime.startTime)}',
          ),
          trailing: Wrap(
            spacing: 6,
            children: [
              Text(money(showtime.basePrice)),
              Text(showtime.statusLabel),
              IconButton(
                tooltip: 'Xóa suất',
                onPressed: () => _confirmDelete(
                  context,
                  title: 'Huỷ suất chiếu "${movie.title}"?',
                  subtitle:
                      'Suất chiếu sẽ được chuyển sang trạng thái cancelled trên backend.',
                  onConfirm: () => _apiDeleteShowtime(showtime),
                ),
                icon: const Icon(Icons.delete_outline_rounded),
              ),
            ],
          ),
        ),
      );
    }).toList();
  }

  List<Widget> _comboChildren(BuildContext context) {
    if (_combosLoading) return [_loadingContent()];
    if (_combos.isEmpty) {
      return [_emptyContent('Chưa có combo nào. Nhấn "Thêm" để tạo mới.')];
    }
    return _combos
        .map(
          (combo) => GlassCard(
            margin: const EdgeInsets.only(bottom: 10),
            child: ListTile(
              contentPadding: EdgeInsets.zero,
              leading: combo.imageUrl.isNotEmpty
                  ? ClipRRect(
                      borderRadius: BorderRadius.circular(8),
                      child: CachedNetworkImage(
                        imageUrl: combo.imageUrl,
                        width: 48,
                        height: 48,
                        fit: BoxFit.cover,
                        errorWidget: (_, __, ___) =>
                            const Icon(Icons.fastfood_rounded, size: 32),
                      ),
                    )
                  : const Icon(Icons.fastfood_rounded, size: 32),
              title: Row(
                children: [
                  Flexible(
                    child: Text(
                      combo.name,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(fontWeight: FontWeight.w900),
                    ),
                  ),
                  const SizedBox(width: 8),
                  if (!combo.isActive)
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 6,
                        vertical: 2,
                      ),
                      decoration: BoxDecoration(
                        color: Colors.grey.withValues(alpha: .18),
                        borderRadius: BorderRadius.circular(4),
                      ),
                      child: const Text(
                        'Ẩn',
                        style: TextStyle(fontSize: 11, color: AppColors.muted),
                      ),
                    ),
                ],
              ),
              subtitle: Text(
                '${NumberFormat.decimalPattern('vi').format(combo.price)} VND'
                ' • Còn ${combo.quantity}'
                '${combo.description.isNotEmpty ? ' • ${combo.description}' : ''}',
              ),
              trailing: Wrap(
                children: [
                  IconButton(
                    tooltip: 'Sửa combo',
                    onPressed: () => _comboDialog(context, combo: combo),
                    icon: const Icon(Icons.edit_outlined),
                  ),
                  IconButton(
                    tooltip: combo.isActive ? 'Ẩn combo' : 'Hiện combo',
                    onPressed: () => _apiToggleCombo(combo),
                    icon: Icon(
                      combo.isActive
                          ? Icons.visibility_off_outlined
                          : Icons.visibility_outlined,
                      color: combo.isActive
                          ? AppColors.muted
                          : AppColors.success,
                    ),
                  ),
                ],
              ),
            ),
          ),
        )
        .toList();
  }

  Widget _loadingContent() {
    return const Padding(
      padding: EdgeInsets.symmetric(vertical: 24),
      child: Center(child: CircularProgressIndicator()),
    );
  }

  Widget _emptyContent(String message) {
    return GlassCard(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Text(message, style: const TextStyle(color: AppColors.muted)),
      ),
    );
  }

  void _movieEditorDialog(BuildContext context, {Movie? movie}) {
    final now = DateTime.now();
    final titleCtrl = TextEditingController(text: movie?.title ?? '');
    final posterCtrl = TextEditingController(text: movie?.posterUrl ?? '');
    final trailerCtrl = TextEditingController(text: movie?.trailerUrl ?? '');
    final descCtrl = TextEditingController(text: movie?.description ?? '');
    final genresCtrl = TextEditingController(
      text: movie?.genres.join(', ') ?? '',
    );
    final directorCtrl = TextEditingController(text: movie?.director ?? '');
    final durationCtrl = TextEditingController(
      text: '${movie?.durationMinutes ?? 110}',
    );
    final imagePicker = ImagePicker();
    final pageCtrl = PageController();

    String selectedAge = movie?.ageRating ?? 'P';
    DateTime selectedRelease = movie?.releaseDate ?? now;
    bool uploadingPoster = false;
    bool uploadingTrailer = false;
    int currentStep = 0;

    final selectedGenres = genresCtrl.text
        .split(',')
        .map((item) => item.trim())
        .where((item) => item.isNotEmpty)
        .toSet();
    final selectedActorIds = _actors
        .where((a) => movie?.cast.contains(a.name) ?? false)
        .map((a) => a.id)
        .toSet();
    final mainActorIds = <String>{};
    final localActors = List<AdminActor>.from(_actors);

    const steps = ['Thong tin', 'Phuong tien', 'Dien vien'];

    void syncGenreController() {
      genresCtrl.text = selectedGenres.join(', ');
    }

    Future<void> pickAndUploadPoster(StateSetter setS) async {
      final source = await showModalBottomSheet<ImageSource>(
        context: context,
        showDragHandle: true,
        builder: (sheetCtx) => SafeArea(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              ListTile(
                leading: const Icon(Icons.photo_library_rounded),
                title: const Text('Chon tu thu vien'),
                onTap: () => Navigator.pop(sheetCtx, ImageSource.gallery),
              ),
              ListTile(
                leading: const Icon(Icons.photo_camera_rounded),
                title: const Text('Chup anh moi'),
                onTap: () => Navigator.pop(sheetCtx, ImageSource.camera),
              ),
            ],
          ),
        ),
      );
      if (source == null) return;
      final picked = await imagePicker.pickImage(
        source: source,
        maxWidth: 1600,
        imageQuality: 88,
      );
      if (picked == null) return;
      setS(() => uploadingPoster = true);
      try {
        final url = await _api.adminUploadImage(
          bytes: await picked.readAsBytes(),
          filename: picked.name,
          contentType: _imageContentType(picked.name),
        );
        posterCtrl.text = url;
        setS(() {});
        _showSnack('Poster đã được tải lên.');
      } catch (e) {
        _showSnack('Upload anh that bai: ${_errorMsg(e)}', isError: true);
      } finally {
        setS(() => uploadingPoster = false);
      }
    }

    Future<void> pickAndUploadTrailer(StateSetter setS) async {
      final picked = await imagePicker.pickVideo(
        source: ImageSource.gallery,
        maxDuration: const Duration(seconds: 60),
      );
      if (picked == null) return;
      final controller = VideoPlayerController.file(File(picked.path));
      try {
        await controller.initialize();
        final dur = controller.value.duration;
        if (dur > const Duration(seconds: 60)) {
          _showSnack(
            'Video qua dai (${dur.inSeconds}s). Trailer chi duoc toi da 60 giay.',
            isError: true,
          );
          return;
        }
      } catch (_) {
      } finally {
        await controller.dispose();
      }
      setS(() => uploadingTrailer = true);
      try {
        final url = await _api.adminUploadVideo(
          bytes: await picked.readAsBytes(),
          filename: picked.name,
          contentType: _videoContentType(picked.name),
        );
        trailerCtrl.text = url;
        setS(() {});
        _showSnack('Da tai trailer len Cloudinary');
      } catch (e) {
        _showSnack('Upload trailer that bai: ${_errorMsg(e)}', isError: true);
      } finally {
        setS(() => uploadingTrailer = false);
      }
    }

    void goTo(StateSetter setS, int step) {
      setS(() => currentStep = step);
      pageCtrl.animateToPage(
        step,
        duration: const Duration(milliseconds: 320),
        curve: Curves.easeInOut,
      );
    }

    showDialog<void>(
      context: context,
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, setS) {
          final isLastStep = currentStep == steps.length - 1;
          final posterUrl = posterCtrl.text.trim();

          Widget stepIndicator() {
            final stepLabels = [
              'Th\u00f4ng tin',
              'Ph\u01b0\u01a1ng ti\u1ec7n',
              'Di\u1ec5n vi\u00ean',
            ];
            const goldColor = Color(0xFFFFB300);
            return Padding(
              padding: const EdgeInsets.fromLTRB(18, 10, 18, 0),
              child: Row(
                children: List.generate(steps.length * 2 - 1, (i) {
                  if (i.isOdd) {
                    final done = currentStep > i ~/ 2;
                    return Expanded(
                      child: Container(
                        height: 2,
                        color: done ? goldColor : Colors.white24,
                      ),
                    );
                  }
                  final idx = i ~/ 2;
                  final isDone = currentStep > idx;
                  final isCurrent = currentStep == idx;
                  return Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      AnimatedContainer(
                        duration: const Duration(milliseconds: 200),
                        width: 28,
                        height: 28,
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          color: isDone
                              ? goldColor
                              : isCurrent
                              ? goldColor.withValues(alpha: .25)
                              : Colors.white12,
                          border: Border.all(
                            color: isCurrent || isDone
                                ? goldColor
                                : Colors.white30,
                            width: 2,
                          ),
                        ),
                        child: Center(
                          child: isDone
                              ? const Icon(
                                  Icons.check_rounded,
                                  size: 14,
                                  color: Colors.white,
                                )
                              : Text(
                                  '${idx + 1}',
                                  style: TextStyle(
                                    fontSize: 12,
                                    fontWeight: FontWeight.w800,
                                    color: isCurrent
                                        ? goldColor
                                        : Colors.white38,
                                  ),
                                ),
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        stepLabels[idx],
                        style: TextStyle(
                          fontSize: 10,
                          fontWeight: FontWeight.w700,
                          color: isCurrent || isDone
                              ? Colors.white
                              : Colors.white38,
                        ),
                      ),
                    ],
                  );
                }),
              ),
            );
          }

          // Step 1: Thong tin
          Widget step1() => SingleChildScrollView(
            padding: const EdgeInsets.all(18),
            child: Column(
              children: [
                _field(titleCtrl, 'T\u00ean phim *'),
                _field(descCtrl, 'M\u00f4 t\u1ea3 phim', maxLines: 4),
                _field(
                  genresCtrl,
                  'Th\u1ec3 lo\u1ea1i (c\u00e1ch nhau b\u1eb1ng d\u1ea5u ph\u1ea9y)',
                ),
                Padding(
                  padding: const EdgeInsets.only(bottom: 18),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      _fieldLabel(
                        'Ch\u1ecdn t\u1eeb danh m\u1ee5c th\u1ec3 lo\u1ea1i',
                      ),
                      const SizedBox(height: 8),
                      Align(
                        alignment: Alignment.centerLeft,
                        child: Wrap(
                          spacing: 8,
                          runSpacing: 8,
                          children: [
                            for (final genre in widget.store.genres.skip(1))
                              FilterChip(
                                avatar: const Icon(
                                  Icons.category_outlined,
                                  size: 18,
                                ),
                                label: Text(genre),
                                selected: selectedGenres.contains(genre),
                                onSelected: (selected) {
                                  setS(() {
                                    if (selected) {
                                      selectedGenres.add(genre);
                                    } else {
                                      selectedGenres.remove(genre);
                                    }
                                    syncGenreController();
                                  });
                                },
                              ),
                            if (widget.store.genres.length <= 1)
                              const Text(
                                'Ch\u01b0a c\u00f3 th\u1ec3 lo\u1ea1i trong danh m\u1ee5c.',
                                style: TextStyle(color: AppColors.muted),
                              ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
                _field(directorCtrl, '\u0110\u1ea1o di\u1ec5n'),
                Row(
                  children: [
                    Expanded(
                      child: _field(
                        durationCtrl,
                        'Th\u1eddi l\u01b0\u1ee3ng (ph\u00fat)',
                        keyboardType: TextInputType.number,
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Padding(
                        padding: const EdgeInsets.only(bottom: 18),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            _fieldLabel('X\u1ebfp h\u1ea1ng tu\u1ed5i'),
                            const SizedBox(height: 7),
                            DropdownButtonFormField<String>(
                              initialValue: selectedAge,
                              isExpanded: true,
                              decoration: _inputDecoration(),
                              items: ['P', 'C13', 'C16', 'C18', 'T18']
                                  .map(
                                    (r) => DropdownMenuItem(
                                      value: r,
                                      child: Text(r),
                                    ),
                                  )
                                  .toList(),
                              onChanged: (v) => setS(() => selectedAge = v!),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ],
                ),
                Padding(
                  padding: const EdgeInsets.only(bottom: 18),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      _fieldLabel('Ng\u00e0y ph\u00e1t h\u00e0nh'),
                      const SizedBox(height: 7),
                      InkWell(
                        borderRadius: BorderRadius.circular(12),
                        onTap: () async {
                          final picked = await showDatePicker(
                            context: ctx,
                            initialDate: selectedRelease,
                            firstDate: DateTime(2000),
                            lastDate: DateTime(2030),
                          );
                          if (picked != null) {
                            setS(() => selectedRelease = picked);
                          }
                        },
                        child: InputDecorator(
                          decoration: _inputDecoration(
                            prefixIcon: const Icon(
                              Icons.event_available_rounded,
                            ),
                          ),
                          child: Text(
                            DateFormat('dd/MM/yyyy').format(selectedRelease),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          );

          // Step 2: Phuong tien
          Widget step2() => SingleChildScrollView(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Container(
                  decoration: BoxDecoration(
                    color: AppColors.pearl,
                    borderRadius: BorderRadius.circular(14),
                    border: Border.all(color: AppColors.line),
                  ),
                  padding: const EdgeInsets.all(14),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          const Icon(
                            Icons.image_rounded,
                            color: AppColors.gold,
                            size: 18,
                          ),
                          const SizedBox(width: 8),
                          const Text(
                            'Poster phim',
                            style: TextStyle(
                              fontWeight: FontWeight.w800,
                              color: AppColors.ink,
                            ),
                          ),
                          const Spacer(),
                          if (uploadingPoster)
                            const SizedBox(
                              width: 16,
                              height: 16,
                              child: CircularProgressIndicator(strokeWidth: 2),
                            ),
                        ],
                      ),
                      const SizedBox(height: 12),
                      if (posterUrl.isNotEmpty)
                        ClipRRect(
                          borderRadius: BorderRadius.circular(10),
                          child: CachedNetworkImage(
                            imageUrl: posterUrl,
                            height: 160,
                            width: double.infinity,
                            fit: BoxFit.cover,
                            placeholder: (_, __) => const SizedBox(
                              height: 80,
                              child: Center(
                                child: CircularProgressIndicator(
                                  strokeWidth: 2,
                                ),
                              ),
                            ),
                            errorWidget: (_, __, ___) => const Icon(
                              Icons.broken_image_outlined,
                              size: 48,
                              color: AppColors.muted,
                            ),
                          ),
                        )
                      else
                        Container(
                          height: 100,
                          decoration: BoxDecoration(
                            color: Colors.white,
                            borderRadius: BorderRadius.circular(10),
                          ),
                          child: const Center(
                            child: Icon(
                              Icons.image_outlined,
                              size: 40,
                              color: AppColors.muted,
                            ),
                          ),
                        ),
                      const SizedBox(height: 10),
                      SizedBox(
                        width: double.infinity,
                        child: FilledButton.icon(
                          onPressed: uploadingPoster
                              ? null
                              : () => pickAndUploadPoster(setS),
                          icon: const Icon(
                            Icons.cloud_upload_rounded,
                            size: 16,
                          ),
                          label: Text(
                            uploadingPoster
                                ? '\u0110ang t\u1ea3i...'
                                : 'T\u1ea3i poster',
                          ),
                        ),
                      ),
                      const SizedBox(height: 10),
                      _field(posterCtrl, 'Ho\u1eb7c d\u00e1n URL poster'),
                    ],
                  ),
                ),
                const SizedBox(height: 14),
                Container(
                  decoration: BoxDecoration(
                    color: AppColors.pearl,
                    borderRadius: BorderRadius.circular(14),
                    border: Border.all(color: AppColors.line),
                  ),
                  padding: const EdgeInsets.all(14),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          const Icon(
                            Icons.play_circle_rounded,
                            color: AppColors.gold,
                            size: 18,
                          ),
                          const SizedBox(width: 8),
                          const Text(
                            'Trailer video',
                            style: TextStyle(
                              fontWeight: FontWeight.w800,
                              color: AppColors.ink,
                            ),
                          ),
                          const Spacer(),
                          if (uploadingTrailer)
                            const Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                SizedBox(
                                  width: 16,
                                  height: 16,
                                  child: CircularProgressIndicator(
                                    strokeWidth: 2,
                                  ),
                                ),
                                SizedBox(width: 8),
                                Text(
                                  '\u0110ang upload...',
                                  style: TextStyle(
                                    fontSize: 12,
                                    color: AppColors.muted,
                                  ),
                                ),
                              ],
                            ),
                        ],
                      ),
                      const SizedBox(height: 6),
                      const Text(
                        '\u26a0\ufe0f  T\u1ed1i \u0111a 60 gi\u00e2y. Qu\u00e1 th\u1eddi l\u01b0\u1ee3ng s\u1ebd b\u1ecb t\u1eeb ch\u1ed1i.',
                        style: TextStyle(
                          fontSize: 12,
                          color: AppColors.warning,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                      const SizedBox(height: 12),
                      if (trailerCtrl.text.trim().isNotEmpty)
                        Container(
                          padding: const EdgeInsets.all(10),
                          decoration: BoxDecoration(
                            color: AppColors.goldSoft,
                            borderRadius: BorderRadius.circular(10),
                            border: Border.all(
                              color: AppColors.gold.withValues(alpha: .4),
                            ),
                          ),
                          child: Row(
                            children: [
                              const Icon(
                                Icons.play_circle_fill_rounded,
                                color: AppColors.gold,
                                size: 28,
                              ),
                              const SizedBox(width: 10),
                              Expanded(
                                child: Text(
                                  trailerCtrl.text.trim(),
                                  style: const TextStyle(
                                    fontSize: 12,
                                    color: AppColors.ink,
                                  ),
                                  maxLines: 2,
                                  overflow: TextOverflow.ellipsis,
                                ),
                              ),
                            ],
                          ),
                        ),
                      const SizedBox(height: 10),
                      SizedBox(
                        width: double.infinity,
                        child: FilledButton.icon(
                          onPressed: uploadingTrailer
                              ? null
                              : () => pickAndUploadTrailer(setS),
                          icon: const Icon(Icons.video_call_rounded, size: 16),
                          label: Text(
                            uploadingTrailer
                                ? '\u0110ang upload...'
                                : 'Ch\u1ecdn video (\u226460s)',
                          ),
                        ),
                      ),
                      const SizedBox(height: 10),
                      _field(trailerCtrl, 'Ho\u1eb7c d\u00e1n URL trailer'),
                    ],
                  ),
                ),
              ],
            ),
          );

          // Step 3: Dien vien
          Widget step3() => Column(
            children: [
              Padding(
                padding: const EdgeInsets.fromLTRB(16, 12, 16, 0),
                child: Row(
                  children: [
                    Expanded(
                      child: Text(
                        selectedActorIds.isEmpty
                            ? 'Ch\u01b0a ch\u1ecdn di\u1ec5n vi\u00ean n\u00e0o'
                            : '${selectedActorIds.length} di\u1ec5n vi\u00ean \u0111\u01b0\u1ee3c ch\u1ecdn',
                        style: const TextStyle(
                          fontSize: 13,
                          color: AppColors.muted,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ),
                    TextButton.icon(
                      onPressed: () async {
                        await showDialog<void>(
                          context: ctx,
                          builder: (_) => _buildActorDialogWidget(
                            context: ctx,
                            actor: null,
                            onSave: (newActor) async {
                              final ok = await _apiSaveActor(
                                newActor,
                                isNew: true,
                                showSnack: false,
                              );
                              if (!ok) return false;
                              setS(() {
                                localActors.clear();
                                localActors.addAll(_actors);
                              });
                              return true;
                            },
                          ),
                        );
                      },
                      icon: const Icon(Icons.person_add_alt_rounded, size: 16),
                      label: const Text('Th\u00eam di\u1ec5n vi\u00ean'),
                    ),
                  ],
                ),
              ),
              const Divider(height: 1),
              if (localActors.isEmpty)
                const Expanded(
                  child: Center(
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(
                          Icons.person_search_rounded,
                          size: 48,
                          color: AppColors.muted,
                        ),
                        SizedBox(height: 12),
                        Text(
                          'Ch\u01b0a c\u00f3 di\u1ec5n vi\u00ean.',
                          style: TextStyle(color: AppColors.muted),
                        ),
                      ],
                    ),
                  ),
                )
              else
                Expanded(
                  child: ListView.builder(
                    padding: const EdgeInsets.symmetric(vertical: 6),
                    itemCount: localActors.length,
                    itemBuilder: (_, i) {
                      final actor = localActors[i];
                      final isSel = selectedActorIds.contains(actor.id);
                      final isMain = mainActorIds.contains(actor.id);
                      return AnimatedContainer(
                        duration: const Duration(milliseconds: 150),
                        margin: const EdgeInsets.symmetric(
                          horizontal: 12,
                          vertical: 4,
                        ),
                        decoration: BoxDecoration(
                          color: isSel ? AppColors.goldSoft : Colors.white,
                          borderRadius: BorderRadius.circular(14),
                          border: Border.all(
                            color: isSel ? AppColors.gold : AppColors.line,
                            width: isSel ? 2 : 1,
                          ),
                        ),
                        child: ListTile(
                          contentPadding: const EdgeInsets.fromLTRB(
                            12,
                            4,
                            4,
                            4,
                          ),
                          leading: Stack(
                            clipBehavior: Clip.none,
                            children: [
                              CircleAvatar(
                                radius: 24,
                                backgroundColor: AppColors.pearl,
                                backgroundImage: actor.avatarUrl.isNotEmpty
                                    ? CachedNetworkImageProvider(
                                        actor.avatarUrl,
                                      )
                                    : null,
                                child: actor.avatarUrl.isEmpty
                                    ? const Icon(
                                        Icons.person_rounded,
                                        color: AppColors.muted,
                                      )
                                    : null,
                              ),
                              if (isMain)
                                Positioned(
                                  right: -4,
                                  top: -4,
                                  child: Container(
                                    width: 16,
                                    height: 16,
                                    decoration: BoxDecoration(
                                      color: AppColors.ink,
                                      shape: BoxShape.circle,
                                      border: Border.all(
                                        color: Colors.white,
                                        width: 1.5,
                                      ),
                                    ),
                                    child: const Icon(
                                      Icons.star_rounded,
                                      size: 10,
                                      color: Colors.white,
                                    ),
                                  ),
                                ),
                            ],
                          ),
                          title: Text(
                            actor.name,
                            style: const TextStyle(
                              fontWeight: FontWeight.w800,
                              fontSize: 14,
                            ),
                          ),
                          subtitle: actor.description.isNotEmpty
                              ? Text(
                                  actor.description,
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                  style: const TextStyle(fontSize: 12),
                                )
                              : null,
                          trailing: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              if (isSel)
                                IconButton(
                                  tooltip: isMain
                                      ? 'B\u1ecf \u0111\u00e1nh d\u1ea5u ch\u00ednh'
                                      : 'Di\u1ec5n vi\u00ean ch\u00ednh',
                                  icon: Icon(
                                    isMain
                                        ? Icons.star_rounded
                                        : Icons.star_border_rounded,
                                    color: isMain
                                        ? AppColors.ink
                                        : AppColors.muted,
                                    size: 22,
                                  ),
                                  onPressed: () => setS(() {
                                    if (isMain) {
                                      mainActorIds.remove(actor.id);
                                    } else {
                                      mainActorIds.add(actor.id);
                                    }
                                  }),
                                ),
                              IconButton(
                                tooltip: 'S\u1eeda',
                                icon: const Icon(Icons.edit_outlined, size: 18),
                                onPressed: () async {
                                  await showDialog<void>(
                                    context: ctx,
                                    builder: (_) => _buildActorDialogWidget(
                                      context: ctx,
                                      actor: actor,
                                      onSave: (updated) async {
                                        final ok = await _apiSaveActor(
                                          updated,
                                          isNew: false,
                                          showSnack: false,
                                        );
                                        if (!ok) return false;
                                        setS(() {
                                          localActors.clear();
                                          localActors.addAll(_actors);
                                        });
                                        return true;
                                      },
                                    ),
                                  );
                                },
                              ),
                              IconButton(
                                tooltip: 'X\u00f3a',
                                icon: const Icon(
                                  Icons.delete_outline_rounded,
                                  size: 18,
                                  color: AppColors.danger,
                                ),
                                onPressed: () async {
                                  final confirm = await showDialog<bool>(
                                    context: ctx,
                                    builder: (c) => AlertDialog(
                                      title: Text('X\u00f3a "${actor.name}"?'),
                                      content: const Text(
                                        'H\u00e0nh \u0111\u1ed9ng n\u00e0y kh\u00f4ng th\u1ec3 ho\u00e0n t\u00e1c.',
                                      ),
                                      actions: [
                                        TextButton(
                                          onPressed: () =>
                                              Navigator.pop(c, false),
                                          child: const Text('H\u1ee7y'),
                                        ),
                                        FilledButton(
                                          style: FilledButton.styleFrom(
                                            backgroundColor: Colors.redAccent,
                                          ),
                                          onPressed: () =>
                                              Navigator.pop(c, true),
                                          child: const Text('X\u00f3a'),
                                        ),
                                      ],
                                    ),
                                  );
                                  if (confirm == true) {
                                    await _apiDeleteActor(actor);
                                    setS(() {
                                      localActors.clear();
                                      localActors.addAll(_actors);
                                      selectedActorIds.remove(actor.id);
                                      mainActorIds.remove(actor.id);
                                    });
                                  }
                                },
                              ),
                              Checkbox(
                                value: isSel,
                                activeColor: AppColors.gold,
                                onChanged: (v) => setS(() {
                                  if (v == true) {
                                    selectedActorIds.add(actor.id);
                                  } else {
                                    selectedActorIds.remove(actor.id);
                                    mainActorIds.remove(actor.id);
                                  }
                                }),
                              ),
                            ],
                          ),
                        ),
                      );
                    },
                  ),
                ),
            ],
          );

          return Dialog(
            insetPadding: const EdgeInsets.symmetric(
              horizontal: 16,
              vertical: 20,
            ),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(20),
            ),
            clipBehavior: Clip.antiAlias,
            child: ConstrainedBox(
              constraints: BoxConstraints(
                maxWidth: 520,
                maxHeight: MediaQuery.of(ctx).size.height * 0.88,
              ),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Container(
                    decoration: const BoxDecoration(
                      gradient: LinearGradient(
                        colors: [Color(0xFF141822), Color(0xFF1E2536)],
                        begin: Alignment.topLeft,
                        end: Alignment.bottomRight,
                      ),
                    ),
                    child: Column(
                      children: [
                        Padding(
                          padding: const EdgeInsets.fromLTRB(18, 14, 10, 4),
                          child: Row(
                            children: [
                              Container(
                                padding: const EdgeInsets.all(7),
                                decoration: BoxDecoration(
                                  color: const Color(
                                    0xFFFFB300,
                                  ).withValues(alpha: .18),
                                  borderRadius: BorderRadius.circular(10),
                                ),
                                child: const Icon(
                                  Icons.movie_creation_rounded,
                                  color: Color(0xFFFFB300),
                                  size: 20,
                                ),
                              ),
                              const SizedBox(width: 12),
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      movie == null
                                          ? 'Th\u00eam phim m\u1edbi'
                                          : 'S\u1eeda phim',
                                      style: const TextStyle(
                                        color: Colors.white,
                                        fontSize: 17,
                                        fontWeight: FontWeight.w900,
                                      ),
                                    ),
                                    Text(
                                      'B\u01b0\u1edbc ${currentStep + 1}/${steps.length}: ${['Th\u00f4ng tin', 'Ph\u01b0\u01a1ng ti\u1ec7n', 'Di\u1ec5n vi\u00ean'][currentStep]}',
                                      style: TextStyle(
                                        color: Colors.white.withValues(
                                          alpha: .6,
                                        ),
                                        fontSize: 12,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                              IconButton(
                                tooltip: '\u0110\u00f3ng',
                                onPressed: uploadingPoster || uploadingTrailer
                                    ? null
                                    : () => Navigator.pop(ctx),
                                icon: const Icon(
                                  Icons.close_rounded,
                                  color: Colors.white54,
                                ),
                              ),
                            ],
                          ),
                        ),
                        stepIndicator(),
                        const SizedBox(height: 10),
                      ],
                    ),
                  ),
                  Flexible(
                    child: PageView(
                      controller: pageCtrl,
                      physics: const NeverScrollableScrollPhysics(),
                      onPageChanged: (p) => setS(() => currentStep = p),
                      children: [step1(), step2(), step3()],
                    ),
                  ),
                  Container(
                    decoration: const BoxDecoration(
                      color: Colors.white,
                      border: Border(top: BorderSide(color: AppColors.line)),
                    ),
                    padding: const EdgeInsets.fromLTRB(16, 10, 16, 12),
                    child: Row(
                      children: [
                        if (currentStep > 0)
                          OutlinedButton.icon(
                            onPressed: () => goTo(setS, currentStep - 1),
                            icon: const Icon(
                              Icons.arrow_back_rounded,
                              size: 16,
                            ),
                            label: const Text('Quay l\u1ea1i'),
                          ),
                        const Spacer(),
                        if (!isLastStep)
                          FilledButton.icon(
                            onPressed: uploadingPoster || uploadingTrailer
                                ? null
                                : () {
                                    if (currentStep == 0 &&
                                        titleCtrl.text.trim().isEmpty) {
                                      _showSnack(
                                        'Vui l\u00f2ng nh\u1eadp t\u00ean phim!',
                                        isError: true,
                                      );
                                      return;
                                    }
                                    goTo(setS, currentStep + 1);
                                  },
                            icon: const Icon(
                              Icons.arrow_forward_rounded,
                              size: 16,
                            ),
                            label: const Text('Ti\u1ebfp theo'),
                          )
                        else
                          FilledButton.icon(
                            onPressed: uploadingPoster || uploadingTrailer
                                ? null
                                : () {
                                    final dur =
                                        int.tryParse(durationCtrl.text) ?? 110;
                                    final isNew = movie == null;
                                    final castNames = [
                                      ...localActors
                                          .where(
                                            (a) =>
                                                selectedActorIds.contains(
                                                  a.id,
                                                ) &&
                                                mainActorIds.contains(a.id),
                                          )
                                          .map((a) => a.name),
                                      ...localActors
                                          .where(
                                            (a) =>
                                                selectedActorIds.contains(
                                                  a.id,
                                                ) &&
                                                !mainActorIds.contains(a.id),
                                          )
                                          .map((a) => a.name),
                                    ];
                                    final uiMovie = Movie(
                                      id: movie?.id ?? 'NEW_${compactId(now)}',
                                      title: titleCtrl.text.trim(),
                                      description: descCtrl.text.trim(),
                                      genres: genresCtrl.text
                                          .split(',')
                                          .map((s) => s.trim())
                                          .where((s) => s.isNotEmpty)
                                          .toList(),
                                      durationMinutes: dur.clamp(30, 300),
                                      director: directorCtrl.text.trim(),
                                      cast: castNames,
                                      posterUrl: posterCtrl.text.trim().isEmpty
                                          ? 'https://image.tmdb.org/t/p/w500/vpnVM9B6NMmQpWeZvzLvDESb2QY.jpg'
                                          : posterCtrl.text.trim(),
                                      trailerUrl:
                                          trailerCtrl.text.trim().isEmpty
                                          ? 'https://youtu.be/demo'
                                          : trailerCtrl.text.trim(),
                                      rating: movie?.rating ?? 0,
                                      ageRating: selectedAge,
                                      releaseDate: selectedRelease,
                                      status:
                                          selectedRelease.isAfter(
                                            DateTime.now(),
                                          )
                                          ? MovieStatus.comingSoon
                                          : MovieStatus.nowShowing,
                                      heroColor: movie?.heroColor ?? 0xFFC9A44C,
                                    );
                                    Navigator.pop(ctx);
                                    _apiSaveMovie(uiMovie, isNew: isNew);
                                  },
                            icon: const Icon(Icons.save_rounded),
                            label: const Text('L\u01b0u phim'),
                          ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          );
        },
      ),
    );
  }

  // ── Actor dialog widget (reusable) ─────────────────────────────────────────

  Widget _buildActorDialogWidget({
    required BuildContext context,
    required AdminActor? actor,
    required Future<bool> Function(AdminActor) onSave,
  }) {
    final nameCtrl = TextEditingController(text: actor?.name ?? '');
    final descCtrl = TextEditingController(text: actor?.description ?? '');
    final avatarCtrl = TextEditingController(text: actor?.avatarUrl ?? '');
    final picker = ImagePicker();
    bool uploadingAvatar = false;
    bool savingActor = false;
    String? actorFormMessage;
    bool actorFormMessageIsError = false;

    return StatefulBuilder(
      builder: (ctx, setS) {
        Future<void> pickAndUploadAvatar() async {
          final picked = await picker.pickImage(
            source: ImageSource.gallery,
            maxWidth: 1200,
            imageQuality: 88,
          );
          if (picked == null) return;
          setS(() {
            uploadingAvatar = true;
            actorFormMessage = null;
            actorFormMessageIsError = false;
          });
          try {
            final url = await _api.adminUploadImage(
              bytes: await picked.readAsBytes(),
              filename: picked.name,
              contentType: _imageContentType(picked.name),
            );
            avatarCtrl.text = url;
            setS(() {
              actorFormMessage =
                  '\u0110\u00e3 t\u1ea3i avatar l\u00ean Cloudinary \u2713';
              actorFormMessageIsError = false;
            });
          } catch (e) {
            setS(() {
              actorFormMessage =
                  'Upload avatar th\u1ea5t b\u1ea1i: ${_errorMsg(e)}';
              actorFormMessageIsError = true;
            });
          } finally {
            setS(() => uploadingAvatar = false);
          }
        }

        return Dialog(
          insetPadding: const EdgeInsets.symmetric(
            horizontal: 20,
            vertical: 40,
          ),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
          ),
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 400),
            child: Padding(
              padding: const EdgeInsets.all(20),
              child: SingleChildScrollView(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    Text(
                      actor == null
                          ? 'Th\u00eam di\u1ec5n vi\u00ean'
                          : 'S\u1eeda di\u1ec5n vi\u00ean',
                      style: const TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.w900,
                        color: AppColors.ink,
                      ),
                    ),
                    const SizedBox(height: 16),
                    Row(
                      children: [
                        GestureDetector(
                          onTap: uploadingAvatar ? null : pickAndUploadAvatar,
                          child: Stack(
                            children: [
                              CircleAvatar(
                                radius: 36,
                                backgroundColor: AppColors.pearl,
                                backgroundImage:
                                    avatarCtrl.text.trim().isNotEmpty
                                    ? CachedNetworkImageProvider(
                                        avatarCtrl.text.trim(),
                                      )
                                    : null,
                                child: avatarCtrl.text.trim().isEmpty
                                    ? const Icon(
                                        Icons.person_outline_rounded,
                                        size: 32,
                                      )
                                    : null,
                              ),
                              Positioned(
                                right: 0,
                                bottom: 0,
                                child: Container(
                                  width: 22,
                                  height: 22,
                                  decoration: BoxDecoration(
                                    color: AppColors.gold,
                                    shape: BoxShape.circle,
                                    border: Border.all(
                                      color: Colors.white,
                                      width: 2,
                                    ),
                                  ),
                                  child: uploadingAvatar
                                      ? const SizedBox(
                                          width: 12,
                                          height: 12,
                                          child: CircularProgressIndicator(
                                            strokeWidth: 1.5,
                                            color: Colors.white,
                                          ),
                                        )
                                      : const Icon(
                                          Icons.camera_alt_rounded,
                                          size: 12,
                                          color: Colors.white,
                                        ),
                                ),
                              ),
                            ],
                          ),
                        ),
                        const SizedBox(width: 14),
                        const Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                '\u1ea2nh \u0111\u1ea1i di\u1ec7n',
                                style: TextStyle(
                                  fontWeight: FontWeight.w700,
                                  color: AppColors.ink,
                                ),
                              ),
                              SizedBox(height: 4),
                              Text(
                                'T\u1ea3i \u1ea3nh t\u1eeb thi\u1ebft b\u1ecb l\u00ean Cloudinary.',
                                style: TextStyle(
                                  fontSize: 12,
                                  color: AppColors.muted,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 12),
                    OutlinedButton.icon(
                      onPressed: uploadingAvatar ? null : pickAndUploadAvatar,
                      icon: uploadingAvatar
                          ? const SizedBox(
                              width: 16,
                              height: 16,
                              child: CircularProgressIndicator(strokeWidth: 2),
                            )
                          : const Icon(Icons.cloud_upload_rounded, size: 18),
                      label: Text(
                        uploadingAvatar
                            ? '\u0110ang upload \u1ea3nh...'
                            : 'T\u1ea3i \u1ea3nh t\u1eeb thi\u1ebft b\u1ecb',
                      ),
                    ),
                    if (actorFormMessage != null) ...[
                      const SizedBox(height: 10),
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 12,
                          vertical: 10,
                        ),
                        decoration: BoxDecoration(
                          color:
                              (actorFormMessageIsError
                                      ? Colors.redAccent
                                      : AppColors.success)
                                  .withValues(alpha: .12),
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(
                            color:
                                (actorFormMessageIsError
                                        ? Colors.redAccent
                                        : AppColors.success)
                                    .withValues(alpha: .35),
                          ),
                        ),
                        child: Row(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Icon(
                              actorFormMessageIsError
                                  ? Icons.error_outline_rounded
                                  : Icons.check_circle_outline_rounded,
                              color: actorFormMessageIsError
                                  ? Colors.redAccent
                                  : AppColors.success,
                              size: 18,
                            ),
                            const SizedBox(width: 8),
                            Expanded(
                              child: Text(
                                actorFormMessage!,
                                style: TextStyle(
                                  color: actorFormMessageIsError
                                      ? Colors.redAccent
                                      : AppColors.success,
                                  fontSize: 12,
                                  fontWeight: FontWeight.w800,
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                    const SizedBox(height: 16),
                    _field(nameCtrl, 'T\u00ean di\u1ec5n vi\u00ean *'),
                    _field(
                      descCtrl,
                      'Ti\u1ec3u s\u1eed / M\u00f4 t\u1ea3',
                      maxLines: 3,
                    ),
                    const SizedBox(height: 4),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.end,
                      children: [
                        TextButton(
                          onPressed: uploadingAvatar || savingActor
                              ? null
                              : () => Navigator.pop(ctx),
                          child: const Text('H\u1ee7y'),
                        ),
                        const SizedBox(width: 10),
                        FilledButton.icon(
                          onPressed: uploadingAvatar || savingActor
                              ? null
                              : () async {
                                  if (nameCtrl.text.trim().isEmpty) {
                                    setS(() {
                                      actorFormMessage =
                                          'Vui l\u00f2ng nh\u1eadp t\u00ean di\u1ec5n vi\u00ean';
                                      actorFormMessageIsError = true;
                                    });
                                    return;
                                  }
                                  setS(() {
                                    savingActor = true;
                                    actorFormMessage = null;
                                    actorFormMessageIsError = false;
                                  });
                                  final next = AdminActor(
                                    id: actor?.id ?? '',
                                    name: nameCtrl.text.trim(),
                                    avatarUrl: avatarCtrl.text.trim(),
                                    description: descCtrl.text.trim(),
                                  );
                                  final ok = await onSave(next);
                                  if (!ctx.mounted) return;
                                  if (!ok) {
                                    setS(() {
                                      savingActor = false;
                                      actorFormMessage =
                                          'Kh\u00f4ng th\u1ec3 l\u01b0u di\u1ec5n vi\u00ean. Vui l\u00f2ng th\u1eed l\u1ea1i.';
                                      actorFormMessageIsError = true;
                                    });
                                    return;
                                  }
                                  setS(() {
                                    savingActor = false;
                                    actorFormMessage = actor == null
                                        ? '\u0110\u00e3 th\u00eam di\u1ec5n vi\u00ean!'
                                        : '\u0110\u00e3 c\u1eadp nh\u1eadt di\u1ec5n vi\u00ean!';
                                    actorFormMessageIsError = false;
                                  });
                                  await Future<void>.delayed(
                                    const Duration(milliseconds: 650),
                                  );
                                  if (ctx.mounted) Navigator.pop(ctx);
                                },
                          icon: savingActor
                              ? const SizedBox(
                                  width: 16,
                                  height: 16,
                                  child: CircularProgressIndicator(
                                    strokeWidth: 2,
                                    color: Colors.white,
                                  ),
                                )
                              : const Icon(Icons.save_rounded),
                          label: Text(
                            savingActor ? '\u0110ang l\u01b0u...' : 'L\u01b0u',
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ),
          ),
        );
      },
    );
  }

  // ─── Combo dialog ─────────────────────────────────────────────────────────

  void _comboDialog(BuildContext context, {AdminFoodCombo? combo}) {
    final nameCtrl = TextEditingController(text: combo?.name ?? '');
    final descCtrl = TextEditingController(text: combo?.description ?? '');
    final priceCtrl = TextEditingController(
      text: combo != null ? '${combo.price}' : '',
    );
    final quantityCtrl = TextEditingController(
      text: combo != null ? '${combo.quantity}' : '',
    );
    final imagePicker = ImagePicker();
    var imageUrl = combo?.imageUrl ?? '';
    var uploadingImage = false;
    bool isActive = combo?.isActive ?? true;

    Future<void> pickAndUploadComboImage(StateSetter setS) async {
      final picked = await imagePicker.pickImage(
        source: ImageSource.gallery,
        maxWidth: 1400,
        imageQuality: 88,
      );
      if (picked == null) return;
      setS(() => uploadingImage = true);
      try {
        final url = await _api.adminUploadImage(
          bytes: await picked.readAsBytes(),
          filename: picked.name,
          contentType: _imageContentType(picked.name),
        );
        setS(() => imageUrl = url);
      } catch (e) {
        if (context.mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('Không thể tải ảnh sản phẩm: ${_errorMsg(e)}'),
            ),
          );
        }
      } finally {
        setS(() => uploadingImage = false);
      }
    }

    showDialog<void>(
      context: context,
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, setS) => AlertDialog(
          title: Text(combo == null ? 'Thêm combo đồ ăn' : 'Sửa combo'),
          content: SizedBox(
            width: 420,
            child: SingleChildScrollView(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  _field(nameCtrl, 'Tên combo *'),
                  _field(descCtrl, 'Mô tả', maxLines: 2),
                  _field(
                    priceCtrl,
                    'Giá (VND) *',
                    keyboardType: TextInputType.number,
                  ),
                  _field(
                    quantityCtrl,
                    'Số lượng tồn *',
                    keyboardType: TextInputType.number,
                  ),
                  Container(
                    width: double.infinity,
                    padding: const EdgeInsets.all(14),
                    decoration: BoxDecoration(
                      color: AppColors.pearl,
                      borderRadius: BorderRadius.circular(14),
                      border: Border.all(color: AppColors.line),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            const Icon(
                              Icons.image_rounded,
                              color: AppColors.gold,
                              size: 18,
                            ),
                            const SizedBox(width: 8),
                            const Expanded(
                              child: Text(
                                'Ảnh sản phẩm',
                                style: TextStyle(
                                  color: AppColors.ink,
                                  fontWeight: FontWeight.w800,
                                ),
                              ),
                            ),
                            if (uploadingImage)
                              const SizedBox(
                                width: 16,
                                height: 16,
                                child: CircularProgressIndicator(
                                  strokeWidth: 2,
                                ),
                              ),
                          ],
                        ),
                        const SizedBox(height: 12),
                        if (imageUrl.isNotEmpty)
                          ClipRRect(
                            borderRadius: BorderRadius.circular(10),
                            child: CachedNetworkImage(
                              imageUrl: imageUrl,
                              height: 130,
                              width: double.infinity,
                              fit: BoxFit.cover,
                              placeholder: (_, __) => const SizedBox(
                                height: 80,
                                child: Center(
                                  child: CircularProgressIndicator(
                                    strokeWidth: 2,
                                  ),
                                ),
                              ),
                              errorWidget: (_, __, ___) => Container(
                                height: 130,
                                color: Colors.white,
                                child: const Center(
                                  child: Icon(
                                    Icons.broken_image_outlined,
                                    size: 42,
                                    color: AppColors.muted,
                                  ),
                                ),
                              ),
                            ),
                          )
                        else
                          Container(
                            height: 110,
                            width: double.infinity,
                            decoration: BoxDecoration(
                              color: Colors.white,
                              borderRadius: BorderRadius.circular(10),
                              border: Border.all(color: AppColors.line),
                            ),
                            child: const Center(
                              child: Icon(
                                Icons.fastfood_rounded,
                                size: 42,
                                color: AppColors.muted,
                              ),
                            ),
                          ),
                        const SizedBox(height: 10),
                        SizedBox(
                          width: double.infinity,
                          child: FilledButton.icon(
                            onPressed: uploadingImage
                                ? null
                                : () => pickAndUploadComboImage(setS),
                            icon: const Icon(
                              Icons.cloud_upload_rounded,
                              size: 16,
                            ),
                            label: Text(
                              uploadingImage
                                  ? 'Đang tải ảnh...'
                                  : imageUrl.isEmpty
                                  ? 'Chọn ảnh sản phẩm'
                                  : 'Đổi ảnh sản phẩm',
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                  SwitchListTile(
                    title: const Text('Hiển thị cho khách hàng'),
                    value: isActive,
                    onChanged: (v) => setS(() => isActive = v),
                  ),
                ],
              ),
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(ctx),
              child: const Text('Hủy'),
            ),
            FilledButton(
              onPressed: uploadingImage
                  ? null
                  : () {
                      final price = int.tryParse(priceCtrl.text.trim()) ?? 0;
                      final quantity =
                          int.tryParse(quantityCtrl.text.trim()) ?? -1;
                      if (nameCtrl.text.trim().isEmpty ||
                          price <= 0 ||
                          quantity < 0 ||
                          imageUrl.trim().isEmpty) {
                        ScaffoldMessenger.of(ctx).showSnackBar(
                          const SnackBar(
                            content: Text(
                              'Vui lòng nhập tên, giá, số lượng và tải ảnh sản phẩm!',
                            ),
                          ),
                        );
                        return;
                      }
                      final newCombo = AdminFoodCombo(
                        id: combo?.id ?? '',
                        name: nameCtrl.text.trim(),
                        description: descCtrl.text.trim(),
                        price: price,
                        quantity: quantity,
                        imageUrl: imageUrl.trim(),
                        isActive: isActive,
                      );
                      Navigator.pop(ctx);
                      _apiSaveCombo(newCombo, isNew: combo == null);
                    },
              child: const Text('Lưu'),
            ),
          ],
        ),
      ),
    );
  }

  // ─── Showtime dialog ──────────────────────────────────────────────────────

  void _showtimeDialog(BuildContext context) {
    final store = widget.store;
    if (store.movies.isEmpty || store.rooms.isEmpty) {
      _showSnack(
        'Cần có phim và phòng trước khi tạo suất chiếu!',
        isError: true,
      );
      return;
    }
    var movieId = store.movies.first.id;
    var roomId = store.rooms.first.id;
    final standardPrice = TextEditingController(text: '120000');
    final vipPrice = TextEditingController(text: '150000');
    final couplePrice = TextEditingController(text: '220000');
    DateTime selectedDate = DateTime.now().add(const Duration(days: 1));
    TimeOfDay selectedTime = const TimeOfDay(hour: 19, minute: 0);
    showDialog<void>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Tạo suất chiếu'),
        content: StatefulBuilder(
          builder: (context, setDialogState) => Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              DropdownButtonFormField<String>(
                initialValue: movieId,
                decoration: const InputDecoration(labelText: 'Phim'),
                items: [
                  for (final m in store.movies)
                    DropdownMenuItem(value: m.id, child: Text(m.title)),
                ],
                onChanged: (v) => setDialogState(() => movieId = v!),
              ),
              const SizedBox(height: 10),
              DropdownButtonFormField<String>(
                initialValue: roomId,
                decoration: const InputDecoration(labelText: 'Phòng'),
                items: [
                  for (final r in store.rooms)
                    DropdownMenuItem(value: r.id, child: Text(r.name)),
                ],
                onChanged: (v) => setDialogState(() => roomId = v!),
              ),
              const SizedBox(height: 10),
              TextField(
                controller: standardPrice,
                keyboardType: TextInputType.number,
                decoration: const InputDecoration(labelText: 'Giá ghế thường'),
              ),
              const SizedBox(height: 10),
              TextField(
                controller: vipPrice,
                keyboardType: TextInputType.number,
                decoration: const InputDecoration(labelText: 'Giá ghế VIP'),
              ),
              const SizedBox(height: 10),
              TextField(
                controller: couplePrice,
                keyboardType: TextInputType.number,
                decoration: const InputDecoration(
                  labelText: 'Giá ghế đôi (1 cặp)',
                ),
              ),
              const SizedBox(height: 10),
              ListTile(
                contentPadding: EdgeInsets.zero,
                leading: const Icon(Icons.event_rounded),
                title: Text(
                  'Ngày: ${DateFormat('dd/MM/yyyy').format(selectedDate)}',
                ),
                onTap: () async {
                  final picked = await showDatePicker(
                    context: context,
                    initialDate: selectedDate,
                    firstDate: DateTime.now(),
                    lastDate: DateTime.now().add(const Duration(days: 365)),
                  );
                  if (picked != null) {
                    setDialogState(() => selectedDate = picked);
                  }
                },
              ),
              ListTile(
                contentPadding: EdgeInsets.zero,
                leading: const Icon(Icons.schedule_rounded),
                title: Text(
                  'Giờ: ${selectedTime.hour.toString().padLeft(2, '0')}:${selectedTime.minute.toString().padLeft(2, '0')}',
                ),
                onTap: () async {
                  final picked = await showTimePicker(
                    context: context,
                    initialTime: selectedTime,
                  );
                  if (picked != null) {
                    setDialogState(() => selectedTime = picked);
                  }
                },
              ),
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Hủy'),
          ),
          FilledButton(
            onPressed: () {
              final movie = store.movieById(movieId);
              final standard = int.tryParse(standardPrice.text.trim()) ?? 0;
              final vip = int.tryParse(vipPrice.text.trim()) ?? 0;
              final couple = int.tryParse(couplePrice.text.trim()) ?? 0;
              if (standard <= 0 || vip <= 0 || couple <= 0) {
                _showSnack('Giá ghế phải lớn hơn 0.', isError: true);
                return;
              }
              if (vip < standard || couple < standard) {
                _showSnack(
                  'Giá ghế VIP và ghế đôi phải lớn hơn hoặc bằng ghế thường.',
                  isError: true,
                );
                return;
              }
              final start = DateTime(
                selectedDate.year,
                selectedDate.month,
                selectedDate.day,
                selectedTime.hour,
                selectedTime.minute,
              );
              // Validation: suất chiếu phải sau hiện tại ít nhất 15 phút
              final minAllowed = DateTime.now().add(
                const Duration(minutes: 15),
              );
              if (!start.isAfter(minAllowed)) {
                _showSnack(
                  'Suất chiếu phải bắt đầu sau ít nhất 15 phút kể từ bây giờ.',
                  isError: true,
                );
                return;
              }
              Navigator.pop(context);
              _apiCreateShowtime(
                ShowtimeScheduleRequest(
                  movieId: movieId,
                  roomId: roomId,
                  startTime: start,
                  endTime: start.add(
                    Duration(minutes: movie.durationMinutes + 20),
                  ),
                  basePrice: standard,
                  vipSeatPrice: vip,
                  coupleSeatPrice: couple,
                ),
              );
            },
            child: const Text('Tạo'),
          ),
        ],
      ),
    );
  }

  // ─── Genre dialog ─────────────────────────────────────────────────────────

  void _genreDialog(BuildContext context, {String? genre}) {
    final isEditing = genre != null;
    final genreCtrl = TextEditingController(text: genre ?? '');
    showDialog<void>(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(isEditing ? 'Sửa thể loại' : 'Thêm thể loại'),
        content: TextField(
          controller: genreCtrl,
          autofocus: true,
          decoration: const InputDecoration(labelText: 'Tên thể loại'),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Hủy'),
          ),
          FilledButton(
            onPressed: () {
              if (isEditing) {
                widget.store.updateGenre(genre, genreCtrl.text);
              } else {
                widget.store.addGenre(genreCtrl.text);
              }
              Navigator.pop(context);
            },
            child: Text(isEditing ? 'Lưu' : 'Thêm'),
          ),
        ],
      ),
    );
  }

  // ─── Room dialog ──────────────────────────────────────────────────────────

  void _roomSeatLayoutDialog(BuildContext context, admin_models.Room room) {
    final currentRoom = room;
    final horizontalController = ScrollController();

    showDialog<void>(
      context: context,
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, _) {
          final seats = [...currentRoom.seatLayout]
            ..sort((a, b) {
              final rowCompare = a.row.compareTo(b.row);
              return rowCompare != 0
                  ? rowCompare
                  : a.column.compareTo(b.column);
            });
          final rows = seats.map((seat) => seat.row).toSet().toList()..sort();
          final maxColumn = seats.fold<int>(
            0,
            (value, seat) => seat.column > value ? seat.column : value,
          );
          final byPosition = {
            for (final seat in seats) '${seat.row}:${seat.column}': seat,
          };

          return AlertDialog(
            title: Text('${currentRoom.name} • ${currentRoom.screenType}'),
            content: SizedBox(
              width: 520,
              child: SingleChildScrollView(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Container(
                      width: double.infinity,
                      padding: const EdgeInsets.symmetric(vertical: 10),
                      decoration: BoxDecoration(
                        color: AppColors.ink,
                        borderRadius: BorderRadius.circular(10),
                      ),
                      child: const Center(
                        child: Text(
                          'MÀN HÌNH',
                          style: TextStyle(
                            color: Colors.white,
                            fontWeight: FontWeight.w900,
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(height: 14),
                    Scrollbar(
                      controller: horizontalController,
                      thumbVisibility: true,
                      trackVisibility: true,
                      child: SingleChildScrollView(
                        controller: horizontalController,
                        scrollDirection: Axis.horizontal,
                        padding: const EdgeInsets.only(bottom: 14),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            for (final row in rows)
                              Padding(
                                padding: const EdgeInsets.only(bottom: 8),
                                child: Row(
                                  children: [
                                    SizedBox(
                                      width: 24,
                                      child: Text(
                                        row,
                                        style: const TextStyle(
                                          fontWeight: FontWeight.w900,
                                        ),
                                      ),
                                    ),
                                    for (
                                      var column = 1;
                                      column <= maxColumn;
                                      column++
                                    )
                                      Padding(
                                        padding: const EdgeInsets.only(
                                          right: 6,
                                        ),
                                        child: Builder(
                                          builder: (_) {
                                            final seat =
                                                byPosition['$row:$column'];
                                            if (seat == null) {
                                              return const SizedBox(
                                                width: 42,
                                                height: 38,
                                              );
                                            }
                                            final color = _seatTypeColor(
                                              seat.seatType,
                                            );
                                            return Tooltip(
                                              message:
                                                  '${seat.seatCode} • ${_seatTypeLabel(seat.seatType)}',
                                              child: AnimatedContainer(
                                                duration: const Duration(
                                                  milliseconds: 150,
                                                ),
                                                width: 42,
                                                height: 38,
                                                decoration: BoxDecoration(
                                                  color: color.withValues(
                                                    alpha: .16,
                                                  ),
                                                  borderRadius:
                                                      BorderRadius.circular(8),
                                                  border: Border.all(
                                                    color: color,
                                                  ),
                                                ),
                                                child: Center(
                                                  child: Text(
                                                    seat.seatCode,
                                                    style: TextStyle(
                                                      color: color,
                                                      fontSize: 11,
                                                      fontWeight:
                                                          FontWeight.w900,
                                                    ),
                                                  ),
                                                ),
                                              ),
                                            );
                                          },
                                        ),
                                      ),
                                  ],
                                ),
                              ),
                          ],
                        ),
                      ),
                    ),
                    const SizedBox(height: 10),
                    Wrap(
                      spacing: 10,
                      runSpacing: 8,
                      children: [
                        for (final type in const ['standard', 'vip', 'couple'])
                          _SeatLegend(
                            color: _seatTypeColor(type),
                            label: _seatTypeLabel(type),
                          ),
                      ],
                    ),
                  ],
                ),
              ),
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(ctx),
                child: const Text('Đóng'),
              ),
            ],
          );
        },
      ),
    ).whenComplete(horizontalController.dispose);
  }

  void _roomDialog(BuildContext context) {
    final store = widget.store;
    final name = TextEditingController(text: 'Phòng mới');
    final capacity = TextEditingController(text: '60');
    var screenType = '2D';
    final rows = TextEditingController(text: '6');
    final seatsPerRow = TextEditingController(text: '10');
    final standardRows = TextEditingController(text: 'A, B, C, D');
    final vipRows = TextEditingController(text: 'E, F');
    final coupleRows = TextEditingController();
    String? validationError;
    showDialog<void>(
      context: context,
      builder: (context) => StatefulBuilder(
        builder: (context, setS) => AlertDialog(
          title: const Text('Thêm phòng chiếu'),
          content: SizedBox(
            width: 430,
            child: SingleChildScrollView(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  _field(name, 'Tên phòng'),
                  Padding(
                    padding: const EdgeInsets.only(bottom: 18),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        _fieldLabel('Công nghệ chiếu'),
                        const SizedBox(height: 7),
                        DropdownButtonFormField<String>(
                          initialValue: screenType,
                          isExpanded: true,
                          decoration: _inputDecoration(),
                          items: const ['2D', '3D', 'IMAX', 'ScreenX']
                              .map(
                                (item) => DropdownMenuItem(
                                  value: item,
                                  child: Text(item),
                                ),
                              )
                              .toList(),
                          onChanged: (value) {
                            if (value == null) return;
                            setS(() => screenType = value);
                          },
                        ),
                      ],
                    ),
                  ),
                  Row(
                    children: [
                      Expanded(
                        child: _field(
                          rows,
                          'Số hàng',
                          keyboardType: TextInputType.number,
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: _field(
                          seatsPerRow,
                          'Ghế mỗi hàng',
                          keyboardType: TextInputType.number,
                        ),
                      ),
                    ],
                  ),
                  _field(
                    capacity,
                    'Sức chứa',
                    keyboardType: TextInputType.number,
                  ),
                  _field(standardRows, 'Hàng ghế thường (VD: A, B, C, D)'),
                  _field(vipRows, 'Hàng VIP (VD: E, F)'),
                  _field(coupleRows, 'Hàng ghế đôi (VD: G)'),
                  if (validationError != null)
                    Container(
                      width: double.infinity,
                      margin: const EdgeInsets.only(bottom: 12),
                      padding: const EdgeInsets.symmetric(
                        horizontal: 12,
                        vertical: 10,
                      ),
                      decoration: BoxDecoration(
                        color: Colors.redAccent.withValues(alpha: .10),
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(
                          color: Colors.redAccent.withValues(alpha: .35),
                        ),
                      ),
                      child: Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Icon(
                            Icons.error_outline_rounded,
                            color: Colors.redAccent,
                            size: 18,
                          ),
                          const SizedBox(width: 8),
                          Expanded(
                            child: Text(
                              validationError!,
                              style: const TextStyle(
                                color: Colors.redAccent,
                                fontWeight: FontWeight.w800,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                ],
              ),
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('Hủy'),
            ),
            FilledButton(
              onPressed: () {
                final rowCount = int.tryParse(rows.text.trim()) ?? 0;
                final seatCount = int.tryParse(seatsPerRow.text.trim()) ?? 0;
                final roomCapacity = int.tryParse(capacity.text.trim()) ?? 0;
                final standardRowList = _parseRowList(standardRows.text);
                final vipRowList = _parseRowList(vipRows.text);
                final coupleRowList = _parseRowList(coupleRows.text);
                final rowGroupError = _validateSeatRowGroups(
                  declaredRowCount: rowCount,
                  standardRows: standardRowList,
                  vipRows: vipRowList,
                  coupleRows: coupleRowList,
                );
                final seatLayout = _buildSeatLayout(
                  seatsPerRow: seatCount,
                  standardRows: standardRowList,
                  vipRows: vipRowList,
                  coupleRows: coupleRowList,
                );
                final totalSeats = seatLayout.length;
                String? error;
                if (name.text.trim().isEmpty) {
                  error = 'Vui lòng nhập tên phòng.';
                } else if (rowCount <= 0) {
                  error = 'Số hàng phải lớn hơn 0.';
                } else if (rowCount > 26) {
                  error = 'Số hàng tối đa là 26, tương ứng A đến Z.';
                } else if (seatCount <= 0) {
                  error = 'Số ghế mỗi hàng phải lớn hơn 0.';
                } else if (rowGroupError != null) {
                  error = rowGroupError;
                } else if (roomCapacity <= 0) {
                  error = 'Sức chứa phải lớn hơn 0.';
                } else if (roomCapacity != rowCount * seatCount) {
                  error =
                      'Sức chứa phải bằng số hàng x số ghế mỗi hàng: ${rowCount * seatCount}.';
                } else if (roomCapacity != totalSeats) {
                  error = 'Sức chứa không khớp layout ghế đã tạo: $totalSeats.';
                }
                if (error != null) {
                  setS(() {
                    validationError = error;
                  });
                  return;
                }
                setS(() => validationError = null);

                final request = RoomRequest(
                  theaterId: store.cinemas.isEmpty
                      ? 'theater-main'
                      : store.cinemas.first.id,
                  name: name.text.trim(),
                  capacity: roomCapacity,
                  screenType: screenType,
                  seatLayout: seatLayout,
                );
                Navigator.pop(context);
                _apiCreateRoom(request);
              },
              child: const Text('Lưu'),
            ),
          ],
        ),
      ),
    );
  }

  List<String> _parseRowList(String text) {
    return text
        .split(RegExp(r'[,;\s]+'))
        .map((item) => item.trim().toUpperCase())
        .where((item) => item.isNotEmpty)
        .toList();
  }

  String? _validateSeatRowGroups({
    required int declaredRowCount,
    required List<String> standardRows,
    required List<String> vipRows,
    required List<String> coupleRows,
  }) {
    final rowOwners = <String, String>{};
    final totalDeclaredRows =
        standardRows.length + vipRows.length + coupleRows.length;
    final groups = <String, List<String>>{
      'hàng ghế thường': standardRows,
      'hàng VIP': vipRows,
      'hàng ghế đôi': coupleRows,
    };

    for (final entry in groups.entries) {
      final groupSeen = <String>{};
      for (final row in entry.value) {
        if (!RegExp(r'^[A-Z]$').hasMatch(row)) {
          return 'Mỗi hàng ghế chỉ dùng một chữ cái từ A đến Z.';
        }
        if (!groupSeen.add(row)) {
          return '${entry.key} không được nhập trùng hàng $row.';
        }
        final owner = rowOwners[row];
        if (owner != null) {
          return 'Hàng $row đang được khai báo ở cả $owner và ${entry.key}.';
        }
        rowOwners[row] = entry.key;
      }
    }

    if (totalDeclaredRows != declaredRowCount) {
      return 'Bạn đang khai báo $totalDeclaredRows hàng ghế, nhưng Số hàng là $declaredRowCount.';
    }

    return null;
  }

  List<RoomSeatLayout> _buildSeatLayout({
    required int seatsPerRow,
    required List<String> standardRows,
    required List<String> vipRows,
    required List<String> coupleRows,
  }) {
    final rows = <({String label, String type})>[
      for (final row in standardRows) (label: row, type: 'standard'),
      for (final row in vipRows) (label: row, type: 'vip'),
      for (final row in coupleRows) (label: row, type: 'couple'),
    ];

    return [
      for (final row in rows)
        for (var column = 1; column <= seatsPerRow; column++)
          RoomSeatLayout(
            seatCode: '${row.label}$column',
            row: row.label,
            column: column,
            seatType: row.type,
          ),
    ];
  }

  // ─── Confirm delete dialog ────────────────────────────────────────────────

  void _confirmDelete(
    BuildContext context, {
    required String title,
    required String subtitle,
    required VoidCallback onConfirm,
  }) {
    showDialog<void>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text(title),
        content: Text(subtitle),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('Hủy'),
          ),
          FilledButton(
            style: FilledButton.styleFrom(backgroundColor: Colors.redAccent),
            onPressed: () {
              Navigator.pop(ctx);
              onConfirm();
            },
            child: const Text('Xoá'),
          ),
        ],
      ),
    );
  }

  // ─── Field helpers ────────────────────────────────────────────────────────

  Widget _field(
    TextEditingController controller,
    String label, {
    int maxLines = 1,
    TextInputType? keyboardType,
  }) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 18),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _fieldLabel(label),
          const SizedBox(height: 7),
          TextField(
            controller: controller,
            maxLines: maxLines,
            keyboardType: keyboardType,
            style: const TextStyle(fontSize: 15, height: 1.25),
            decoration: _inputDecoration(),
          ),
        ],
      ),
    );
  }

  Widget _fieldLabel(String label) {
    return Text(
      label,
      style: const TextStyle(
        color: AppColors.ink,
        fontSize: 13,
        fontWeight: FontWeight.w800,
      ),
    );
  }

  InputDecoration _inputDecoration({Widget? prefixIcon, String? labelText}) {
    return InputDecoration(
      filled: true,
      fillColor: Colors.white,
      isDense: true,
      prefixIcon: prefixIcon,
      labelText: labelText,
      constraints: const BoxConstraints(minHeight: 54),
      contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 15),
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: const BorderSide(color: AppColors.line),
      ),
      enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: const BorderSide(color: AppColors.line),
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: const BorderSide(color: AppColors.gold, width: 1.5),
      ),
    );
  }
}

class _AdminAccordionSection extends StatelessWidget {
  const _AdminAccordionSection({
    required this.title,
    required this.icon,
    required this.badge,
    required this.isExpanded,
    required this.onToggle,
    required this.children,
  });

  final String title;
  final IconData icon;
  final String badge;
  final bool isExpanded;
  final VoidCallback onToggle;
  final List<Widget> children;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Material(
            color: Colors.white.withValues(alpha: .9),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(10),
              side: const BorderSide(color: AppColors.line),
            ),
            child: Row(
              children: [
                Expanded(
                  child: InkWell(
                    onTap: onToggle,
                    borderRadius: const BorderRadius.horizontal(
                      left: Radius.circular(10),
                    ),
                    child: Padding(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 12,
                        vertical: 12,
                      ),
                      child: Row(
                        children: [
                          Icon(icon, size: 20, color: AppColors.ink),
                          const SizedBox(width: 10),
                          Expanded(
                            child: Text(
                              title,
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                              style: const TextStyle(
                                color: AppColors.ink,
                                fontSize: 15,
                                fontWeight: FontWeight.w900,
                              ),
                            ),
                          ),
                          const SizedBox(width: 8),
                          Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 8,
                              vertical: 3,
                            ),
                            decoration: BoxDecoration(
                              color: AppColors.gold.withValues(alpha: .16),
                              borderRadius: BorderRadius.circular(999),
                            ),
                            child: Text(
                              badge,
                              style: const TextStyle(
                                color: AppColors.ink,
                                fontSize: 11,
                                fontWeight: FontWeight.w900,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
                IconButton(
                  tooltip: isExpanded ? 'Thu gọn' : 'Mở rộng',
                  onPressed: onToggle,
                  icon: AnimatedRotation(
                    turns: isExpanded ? .5 : 0,
                    duration: const Duration(milliseconds: 180),
                    child: const Icon(Icons.keyboard_arrow_down_rounded),
                  ),
                ),
              ],
            ),
          ),
          AnimatedCrossFade(
            firstChild: const SizedBox.shrink(),
            secondChild: Padding(
              padding: const EdgeInsets.only(top: 10),
              child: Column(children: children),
            ),
            crossFadeState: isExpanded
                ? CrossFadeState.showSecond
                : CrossFadeState.showFirst,
            duration: const Duration(milliseconds: 180),
            firstCurve: Curves.easeOut,
            secondCurve: Curves.easeOut,
            sizeCurve: Curves.easeOut,
          ),
        ],
      ),
    );
  }
}

class _SeatLegend extends StatelessWidget {
  const _SeatLegend({required this.color, required this.label});

  final Color color;
  final String label;

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Container(
          width: 14,
          height: 14,
          decoration: BoxDecoration(
            color: color.withValues(alpha: .18),
            borderRadius: BorderRadius.circular(4),
            border: Border.all(color: color),
          ),
        ),
        const SizedBox(width: 6),
        Text(
          label,
          style: const TextStyle(
            color: AppColors.muted,
            fontSize: 12,
            fontWeight: FontWeight.w800,
          ),
        ),
      ],
    );
  }
}
