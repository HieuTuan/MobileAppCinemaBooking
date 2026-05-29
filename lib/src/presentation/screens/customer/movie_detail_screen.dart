part of '../../../app.dart';

class MovieDetailScreen extends StatelessWidget {
  const MovieDetailScreen({
    super.key,
    required this.movie,
    required this.customerName,
    required this.onBook,
  });

  final Movie movie;
  final String customerName;
  final ValueChanged<Booking> onBook;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text(movie.title), backgroundColor: _surface),
      body: ListView(
        padding: const EdgeInsets.only(bottom: 24),
        children: [
          SizedBox(
            height: 330,
            child: Stack(
              fit: StackFit.expand,
              children: [
                Image.network(movie.coverUrl, fit: BoxFit.cover),
                Container(
                  decoration: const BoxDecoration(
                    gradient: LinearGradient(
                      begin: Alignment.topCenter,
                      end: Alignment.bottomCenter,
                      colors: [Color(0x330C0C0E), _obsidian],
                    ),
                  ),
                ),
                Positioned(
                  left: 18,
                  right: 18,
                  bottom: 18,
                  child: Row(
                    crossAxisAlignment: CrossAxisAlignment.end,
                    children: [
                      ClipRRect(
                        borderRadius: BorderRadius.circular(8),
                        child: Hero(
                          tag: 'poster-${movie.id}',
                          child: Image.network(
                            movie.posterUrl,
                            width: 118,
                            height: 176,
                            fit: BoxFit.cover,
                          ),
                        ),
                      ),
                      const SizedBox(width: 16),
                      Expanded(
                        child: Column(
                          mainAxisSize: MainAxisSize.min,
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            if (movie.vipGold)
                              const _StatusPill(
                                color: _gold,
                                textColor: _obsidian,
                                label: 'VIP Gold',
                              ),
                            const SizedBox(height: 8),
                            Text(
                              movie.title,
                              style: Theme.of(context).textTheme.headlineMedium
                                  ?.copyWith(
                                    fontFamily: 'Playfair Display',
                                    fontWeight: FontWeight.w900,
                                  ),
                            ),
                            const SizedBox(height: 8),
                            Text(
                              '${movie.genre} - ${movie.year} - ${movie.duration} phut',
                              style: const TextStyle(color: _muted),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
          Padding(
            padding: const EdgeInsets.all(18),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const _SectionTitle(
                  icon: Icons.info_outline,
                  title: 'Thong tin tac pham',
                ),
                const SizedBox(height: 12),
                _InfoLine(label: 'Dao dien', value: movie.director),
                _InfoLine(label: 'Dien vien', value: movie.cast),
                _InfoLine(label: 'Ma phim', value: movie.id),
                const SizedBox(height: 18),
                const _SectionTitle(
                  icon: Icons.notes_outlined,
                  title: 'Noi dung',
                ),
                const SizedBox(height: 10),
                Text(
                  movie.synopsis,
                  style: const TextStyle(color: _stone, height: 1.55),
                ),
                const SizedBox(height: 20),
                Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: _surface,
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(color: _gold.withValues(alpha: .22)),
                  ),
                  child: const Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      _SectionTitle(
                        icon: Icons.workspace_premium_outlined,
                        title: 'Goi y trai nghiem',
                      ),
                      SizedBox(height: 10),
                      Text(
                        'Prestige VIP hang C-D phu hop voi trai nghiem can bang. Royal Velvet Sofa Bed hang E-F danh cho lich chieu rieng tu va tiec am thuc cao cap.',
                        style: TextStyle(color: _muted, height: 1.45),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 20),
                FilledButton.icon(
                  onPressed: () => _openBooking(context),
                  icon: const Icon(Icons.event_seat_outlined),
                  label: const Text('DAT VE PHIM NAY'),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  void _openBooking(BuildContext context) {
    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (_) => BookingScreen(
          movie: movie,
          customerName: customerName,
          onBook: onBook,
        ),
      ),
    );
  }
}
