part of '../../../app.dart';

class MovieLounge extends StatefulWidget {
  const MovieLounge({
    super.key,
    required this.movies,
    required this.customerName,
    required this.onBook,
  });

  final List<Movie> movies;
  final String customerName;
  final ValueChanged<Booking> onBook;

  @override
  State<MovieLounge> createState() => _MovieLoungeState();
}

class _MovieLoungeState extends State<MovieLounge> {
  String _filter = 'Tat ca';
  String _query = '';

  @override
  Widget build(BuildContext context) {
    final genres = [
      'Tat ca',
      ...widget.movies.map((movie) => movie.genre).toSet(),
    ];
    final movies = widget.movies.where((movie) {
      final matchesGenre = _filter == 'Tat ca' || movie.genre == _filter;
      final text = '${movie.title} ${movie.director} ${movie.cast}'
          .toLowerCase();
      return matchesGenre && text.contains(_query.toLowerCase());
    }).toList();

    return ListView(
      padding: const EdgeInsets.fromLTRB(18, 18, 18, 28),
      children: [
        _HeroLounge(movie: widget.movies.first),
        const SizedBox(height: 18),
        TextField(
          decoration: const InputDecoration(
            prefixIcon: Icon(Icons.search),
            hintText: 'Tim phim, dao dien, dien vien',
          ),
          onChanged: (value) => setState(() => _query = value),
        ),
        const SizedBox(height: 12),
        SingleChildScrollView(
          scrollDirection: Axis.horizontal,
          child: Row(
            children: genres.map((genre) {
              final selected = genre == _filter;
              return Padding(
                padding: const EdgeInsets.only(right: 8),
                child: ChoiceChip(
                  label: Text(genre),
                  selected: selected,
                  selectedColor: _gold,
                  labelStyle: TextStyle(color: selected ? _obsidian : _stone),
                  onSelected: (_) => setState(() => _filter = genre),
                ),
              );
            }).toList(),
          ),
        ),
        const SizedBox(height: 18),
        LayoutBuilder(
          builder: (context, constraints) {
            final width = constraints.maxWidth;
            final columns = width > 980
                ? 4
                : width > 680
                ? 3
                : width > 430
                ? 2
                : 1;
            return GridView.builder(
              itemCount: movies.length,
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                crossAxisCount: columns,
                childAspectRatio: columns == 1 ? 1.85 : .62,
                crossAxisSpacing: 14,
                mainAxisSpacing: 14,
              ),
              itemBuilder: (context, index) {
                return MovieCard(
                  movie: movies[index],
                  onTap: () => _openDetail(context, movies[index]),
                  onBook: () => _openBooking(context, movies[index]),
                );
              },
            );
          },
        ),
      ],
    );
  }

  void _openDetail(BuildContext context, Movie movie) {
    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (_) => MovieDetailScreen(
          movie: movie,
          customerName: widget.customerName,
          onBook: widget.onBook,
        ),
      ),
    );
  }

  void _openBooking(BuildContext context, Movie movie) {
    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (_) => BookingScreen(
          movie: movie,
          customerName: widget.customerName,
          onBook: widget.onBook,
        ),
      ),
    );
  }
}
