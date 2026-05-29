part of '../../../app.dart';

class AdminScreen extends StatelessWidget {
  const AdminScreen({
    super.key,
    required this.user,
    required this.movies,
    required this.onSave,
    required this.onDelete,
    required this.onLogout,
  });

  final DemoUser user;
  final List<Movie> movies;
  final ValueChanged<Movie> onSave;
  final ValueChanged<String> onDelete;
  final VoidCallback onLogout;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: _CineAppBar(
        title: 'Bang quan tri Cineverse',
        user: user,
        onLogout: onLogout,
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => _openEditor(context),
        icon: const Icon(Icons.add),
        label: const Text('Them phim'),
      ),
      body: ListView.separated(
        padding: const EdgeInsets.all(18),
        itemCount: movies.length,
        separatorBuilder: (_, __) => const SizedBox(height: 12),
        itemBuilder: (context, index) {
          final movie = movies[index];
          return Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: _surface,
              borderRadius: BorderRadius.circular(8),
              border: Border.all(color: Colors.white.withValues(alpha: .08)),
            ),
            child: Row(
              children: [
                ClipRRect(
                  borderRadius: BorderRadius.circular(6),
                  child: Image.network(
                    movie.posterUrl,
                    width: 72,
                    height: 104,
                    fit: BoxFit.cover,
                  ),
                ),
                const SizedBox(width: 14),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        movie.title,
                        style: const TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.w800,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        '${movie.id} - ${movie.genre} - ${movie.year}',
                        style: const TextStyle(color: _muted),
                      ),
                      const SizedBox(height: 6),
                      Text(
                        movie.director,
                        style: const TextStyle(color: _gold),
                      ),
                    ],
                  ),
                ),
                IconButton(
                  onPressed: () => _openEditor(context, movie),
                  icon: const Icon(Icons.edit_outlined),
                  tooltip: 'Sua',
                ),
                IconButton(
                  onPressed: () => onDelete(movie.id),
                  icon: const Icon(Icons.delete_outline),
                  tooltip: 'Xoa',
                ),
              ],
            ),
          );
        },
      ),
    );
  }

  Future<void> _openEditor(BuildContext context, [Movie? movie]) async {
    final result = await showDialog<Movie>(
      context: context,
      builder: (_) => MovieEditorDialog(movie: movie),
    );
    if (result != null) onSave(result);
  }
}
