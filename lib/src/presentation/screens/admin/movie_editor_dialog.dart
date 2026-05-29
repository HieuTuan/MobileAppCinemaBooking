part of '../../../app.dart';

class MovieEditorDialog extends StatefulWidget {
  const MovieEditorDialog({super.key, this.movie});

  final Movie? movie;

  @override
  State<MovieEditorDialog> createState() => _MovieEditorDialogState();
}

class _MovieEditorDialogState extends State<MovieEditorDialog> {
  late final TextEditingController _id;
  late final TextEditingController _title;
  late final TextEditingController _genre;
  late final TextEditingController _year;
  late final TextEditingController _director;
  late final TextEditingController _cast;
  late final TextEditingController _duration;
  late final TextEditingController _poster;
  late final TextEditingController _cover;
  late final TextEditingController _synopsis;
  late bool _vip;

  @override
  void initState() {
    super.initState();
    final movie = widget.movie;
    _id = TextEditingController(
      text: movie?.id ?? 'MV-${DateTime.now().millisecondsSinceEpoch % 10000}',
    );
    _title = TextEditingController(text: movie?.title ?? '');
    _genre = TextEditingController(text: movie?.genre ?? '');
    _year = TextEditingController(
      text: '${movie?.year ?? DateTime.now().year}',
    );
    _director = TextEditingController(text: movie?.director ?? '');
    _cast = TextEditingController(text: movie?.cast ?? '');
    _duration = TextEditingController(text: '${movie?.duration ?? 120}');
    _poster = TextEditingController(
      text:
          movie?.posterUrl ??
          'https://images.unsplash.com/photo-1440404653325-ab127d49abc1?auto=format&fit=crop&w=700&q=80',
    );
    _cover = TextEditingController(
      text:
          movie?.coverUrl ??
          'https://images.unsplash.com/photo-1517604931442-7e0c8ed2963c?auto=format&fit=crop&w=1400&q=80',
    );
    _synopsis = TextEditingController(text: movie?.synopsis ?? '');
    _vip = movie?.vipGold ?? false;
  }

  @override
  void dispose() {
    for (final controller in [
      _id,
      _title,
      _genre,
      _year,
      _director,
      _cast,
      _duration,
      _poster,
      _cover,
      _synopsis,
    ]) {
      controller.dispose();
    }
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: Text(
        widget.movie == null ? 'Them tac pham' : 'Chinh sua tac pham',
      ),
      content: SizedBox(
        width: 620,
        child: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              _field(_id, 'ID'),
              _field(_title, 'Ten phim'),
              _field(_genre, 'The loai'),
              _field(_year, 'Nam', numeric: true),
              _field(_director, 'Dao dien'),
              _field(_cast, 'Dien vien'),
              _field(_duration, 'Thoi luong', numeric: true),
              _field(_poster, 'Poster URL'),
              _field(_cover, 'Cover URL'),
              _field(_synopsis, 'Tom tat', lines: 3),
              SwitchListTile(
                value: _vip,
                title: const Text('Gan the VIP Gold'),
                activeThumbColor: _gold,
                onChanged: (value) => setState(() => _vip = value),
              ),
            ],
          ),
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.of(context).pop(),
          child: const Text('Huy'),
        ),
        FilledButton(onPressed: _save, child: const Text('Luu')),
      ],
    );
  }

  Widget _field(
    TextEditingController controller,
    String label, {
    bool numeric = false,
    int lines = 1,
  }) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 10),
      child: TextField(
        controller: controller,
        maxLines: lines,
        keyboardType: numeric ? TextInputType.number : TextInputType.text,
        decoration: InputDecoration(labelText: label),
      ),
    );
  }

  void _save() {
    Navigator.of(context).pop(
      Movie(
        id: _id.text.trim(),
        title: _title.text.trim().isEmpty
            ? 'Untitled Cineverse Film'
            : _title.text.trim(),
        genre: _genre.text.trim().isEmpty ? 'Drama' : _genre.text.trim(),
        year: int.tryParse(_year.text) ?? DateTime.now().year,
        director: _director.text.trim().isEmpty
            ? 'Cineverse Studio'
            : _director.text.trim(),
        cast: _cast.text.trim().isEmpty ? 'Dang cap nhat' : _cast.text.trim(),
        duration: int.tryParse(_duration.text) ?? 120,
        posterUrl: _poster.text.trim(),
        coverUrl: _cover.text.trim(),
        synopsis: _synopsis.text.trim().isEmpty
            ? 'Tac pham moi tren lich chieu Cineverse Club.'
            : _synopsis.text.trim(),
        vipGold: _vip,
      ),
    );
  }
}
