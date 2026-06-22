import 'dart:io';

import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:intl/intl.dart';
import 'package:video_player/video_player.dart';

import '../../../api/api_client.dart';
import '../../../models/admin_models.dart'
    hide Room; // app_models.dart Room is used instead
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

  List<AdminFoodCombo> _combos = [];
  bool _combosLoading = false;
  List<AdminActor> _actors = [];
  bool _actorsLoading = false;
  bool _roomsLoading = false;

  @override
  void initState() {
    super.initState();
    _loadCombos();
    _loadActors();
    _loadRooms();
  }

  // ─── Load ─────────────────────────────────────────────────────────────────

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
        widget.store.replaceRooms(list.map(_roomFromAdmin).toList());
      }
    } catch (_) {
    } finally {
      if (mounted) setState(() => _roomsLoading = false);
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
      if (isNew) {
        await _api.adminCreateMovie(req);
      } else {
        await _api.adminUpdateMovie(uiMovie.id, req);
      }
      widget.store.saveMovie(uiMovie);
      _showSnack(isNew ? 'Đã thêm phim!' : 'Đã cập nhật phim!');
    } catch (e) {
      _showSnack('Lỗi: ${_errorMsg(e)}', isError: true);
    }
  }

  Future<void> _apiDeleteMovie(String movieId) async {
    try {
      await _api.adminDeleteMovie(movieId);
      widget.store.deleteMovie(movieId);
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

  Future<void> _apiSaveActor(AdminActor actor, {bool isNew = false}) async {
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
      _showSnack(isNew ? 'Đã thêm diễn viên!' : 'Đã cập nhật diễn viên!');
    } catch (e) {
      _showSnack('Lỗi: ${_errorMsg(e)}', isError: true);
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
        onSave: (next) => _apiSaveActor(next, isNew: actor == null),
      ),
    );
  }

  // ─── Helpers ──────────────────────────────────────────────────────────────

  void _showSnack(String msg, {bool isError = false}) {
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(msg),
        backgroundColor: isError ? Colors.redAccent : AppColors.success,
        behavior: SnackBarBehavior.floating,
      ),
    );
  }

  String _errorMsg(Object e) => e.toString().replaceFirst('Exception: ', '');

  Room _roomFromAdmin(dynamic room) {
    return Room(
      id: room.id as String,
      cinemaId: room.theaterId as String,
      name: room.name as String,
      capacity: room.totalSeats as int,
      screenType: room.screenType as String,
      status: (room.status as String).toLowerCase() == 'maintenance'
          ? RoomStatus.maintenance
          : RoomStatus.ready,
    );
  }

  Future<void> _apiCreateRoom(RoomRequest request) async {
    try {
      final saved = await _api.createAdminRoom(request);
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
      widget.store.saveRoom(_roomFromAdmin(saved));
      _showSnack(ready ? 'Phòng đã sẵn sàng' : 'Đã chuyển phòng sang bảo trì');
    } catch (e) {
      _showSnack('Lỗi cập nhật phòng: ${_errorMsg(e)}', isError: true);
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
                trailing: Switch(
                  value: room.status == RoomStatus.ready,
                  onChanged: (value) => _apiUpdateRoomStatus(room, value),
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
                  IconButton(
                    tooltip: 'Xóa suất',
                    onPressed: () => store.deleteShowtime(showtime.id),
                    icon: const Icon(Icons.delete_outline_rounded),
                  ),
                ],
              ),
            ),
          );
        }),

        // ── Food Combos ───────────────────────────────────────────────────
        SectionTitle(
          title: 'Quản lý Combo đồ ăn',
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
        _showSnack('Da tai poster len Cloudinary');
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
            return Padding(
              padding: const EdgeInsets.fromLTRB(18, 10, 18, 0),
              child: Row(
                children: List.generate(steps.length * 2 - 1, (i) {
                  if (i.isOdd) {
                    final done = currentStep > i ~/ 2;
                    return Expanded(
                      child: Container(
                        height: 2,
                        color: done ? AppColors.gold : Colors.white24,
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
                              ? AppColors.gold
                              : isCurrent
                              ? AppColors.gold.withValues(alpha: .25)
                              : Colors.white12,
                          border: Border.all(
                            color: isCurrent || isDone
                                ? AppColors.gold
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
                                        ? AppColors.gold
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
                              await _apiSaveActor(newActor, isNew: true);
                              setS(() {
                                localActors.clear();
                                localActors.addAll(_actors);
                              });
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
                                      color: Colors.amber,
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
                                        ? Colors.amber
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
                                        await _apiSaveActor(
                                          updated,
                                          isNew: false,
                                        );
                                        setS(() {
                                          localActors.clear();
                                          localActors.addAll(_actors);
                                        });
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
                                  color: AppColors.gold.withValues(alpha: .18),
                                  borderRadius: BorderRadius.circular(10),
                                ),
                                child: const Icon(
                                  Icons.movie_creation_rounded,
                                  color: AppColors.gold,
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
    required Future<void> Function(AdminActor) onSave,
  }) {
    final nameCtrl = TextEditingController(text: actor?.name ?? '');
    final descCtrl = TextEditingController(text: actor?.description ?? '');
    final avatarCtrl = TextEditingController(text: actor?.avatarUrl ?? '');
    final picker = ImagePicker();
    bool uploadingAvatar = false;

    return StatefulBuilder(
      builder: (ctx, setS) {
        Future<void> pickAndUploadAvatar() async {
          final picked = await picker.pickImage(
            source: ImageSource.gallery,
            maxWidth: 1200,
            imageQuality: 88,
          );
          if (picked == null) return;
          setS(() => uploadingAvatar = true);
          try {
            final url = await _api.adminUploadImage(
              bytes: await picked.readAsBytes(),
              filename: picked.name,
              contentType: _imageContentType(picked.name),
            );
            avatarCtrl.text = url;
            setS(() {});
            _showSnack(
              '\u0110\u00e3 t\u1ea3i avatar l\u00ean Cloudinary \u2713',
            );
          } catch (e) {
            _showSnack(
              'Upload avatar th\u1ea5t b\u1ea1i: ${_errorMsg(e)}',
              isError: true,
            );
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
                                'Nh\u1ea5n v\u00e0o avatar \u0111\u1ec3 t\u1ea3i \u1ea3nh l\u00ean,\nho\u1eb7c d\u00e1n URL b\u00ean d\u01b0\u1edbi.',
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
                    const SizedBox(height: 16),
                    _field(nameCtrl, 'T\u00ean di\u1ec5n vi\u00ean *'),
                    _field(
                      descCtrl,
                      'Ti\u1ec3u s\u1eed / M\u00f4 t\u1ea3',
                      maxLines: 3,
                    ),
                    _field(avatarCtrl, 'Avatar URL Cloudinary'),
                    const SizedBox(height: 4),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.end,
                      children: [
                        TextButton(
                          onPressed: uploadingAvatar
                              ? null
                              : () => Navigator.pop(ctx),
                          child: const Text('H\u1ee7y'),
                        ),
                        const SizedBox(width: 10),
                        FilledButton.icon(
                          onPressed: uploadingAvatar
                              ? null
                              : () async {
                                  if (nameCtrl.text.trim().isEmpty) {
                                    _showSnack(
                                      'Vui l\u00f2ng nh\u1eadp t\u00ean di\u1ec5n vi\u00ean',
                                      isError: true,
                                    );
                                    return;
                                  }
                                  final next = AdminActor(
                                    id: actor?.id ?? '',
                                    name: nameCtrl.text.trim(),
                                    avatarUrl: avatarCtrl.text.trim(),
                                    description: descCtrl.text.trim(),
                                  );
                                  Navigator.pop(ctx);
                                  await onSave(next);
                                },
                          icon: const Icon(Icons.save_rounded),
                          label: const Text('L\u01b0u'),
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
    final imageCtrl = TextEditingController(text: combo?.imageUrl ?? '');
    bool isActive = combo?.isActive ?? true;

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
                  _field(imageCtrl, 'Ảnh URL'),
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
              onPressed: () {
                final price = int.tryParse(priceCtrl.text.trim()) ?? 0;
                final quantity = int.tryParse(quantityCtrl.text.trim()) ?? -1;
                if (nameCtrl.text.trim().isEmpty ||
                    price <= 0 ||
                    quantity < 0) {
                  ScaffoldMessenger.of(ctx).showSnackBar(
                    const SnackBar(
                      content: Text(
                        'Vui lòng nhập tên, giá và số lượng hợp lệ!',
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
                  imageUrl: imageCtrl.text.trim(),
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
    final price = TextEditingController(text: '120000');
    final date = DateTime.now().add(const Duration(days: 1));
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
                controller: price,
                keyboardType: TextInputType.number,
                decoration: const InputDecoration(labelText: 'Giá vé cơ bản'),
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
              final start = DateTime(date.year, date.month, date.day, 19);
              store.saveShowtime(
                Showtime(
                  id: 'ST${compactId(DateTime.now())}',
                  movieId: movieId,
                  roomId: roomId,
                  startTime: start,
                  endTime: start.add(const Duration(minutes: 110)),
                  basePrice: int.tryParse(price.text) ?? 120000,
                  status: 'Đang mở',
                ),
              );
              Navigator.pop(context);
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

  void _roomDialog(BuildContext context) {
    final store = widget.store;
    final name = TextEditingController(text: 'Phòng mới');
    final capacity = TextEditingController(text: '60');
    var screenType = '2D';
    final rows = TextEditingController(text: '6');
    final seatsPerRow = TextEditingController(text: '10');
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
                final totalSeats = rowCount * seatCount;
                final error = name.text.trim().isEmpty
                    ? 'Vui lòng nhập tên phòng.'
                    : rowCount <= 0
                    ? 'Số hàng phải lớn hơn 0.'
                    : seatCount <= 0
                    ? 'Số ghế mỗi hàng phải lớn hơn 0.'
                    : roomCapacity <= 0
                    ? 'Sức chứa phải lớn hơn 0.'
                    : roomCapacity != totalSeats
                    ? 'Sức chứa phải bằng số hàng x số ghế mỗi hàng.'
                    : null;
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
                  seatLayout: _buildSeatLayout(
                    rows: rowCount,
                    seatsPerRow: seatCount,
                    vipRows: _parseRows(vipRows.text),
                    coupleRows: _parseRows(coupleRows.text),
                  ),
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

  Set<String> _parseRows(String text) {
    return text
        .split(RegExp(r'[,;\s]+'))
        .map((item) => item.trim().toUpperCase())
        .where((item) => item.isNotEmpty)
        .toSet();
  }

  List<RoomSeatLayout> _buildSeatLayout({
    required int rows,
    required int seatsPerRow,
    required Set<String> vipRows,
    required Set<String> coupleRows,
  }) {
    return [
      for (var rowIndex = 0; rowIndex < rows; rowIndex++)
        for (var column = 1; column <= seatsPerRow; column++)
          RoomSeatLayout(
            seatCode: '${String.fromCharCode(65 + rowIndex)}$column',
            row: String.fromCharCode(65 + rowIndex),
            column: column,
            seatType: coupleRows.contains(String.fromCharCode(65 + rowIndex))
                ? 'couple'
                : vipRows.contains(String.fromCharCode(65 + rowIndex))
                ? 'vip'
                : 'standard',
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
