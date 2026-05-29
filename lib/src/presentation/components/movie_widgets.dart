part of '../../app.dart';

class _HeroLounge extends StatelessWidget {
  const _HeroLounge({required this.movie});

  final Movie movie;

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 260,
      clipBehavior: Clip.antiAlias,
      decoration: BoxDecoration(borderRadius: BorderRadius.circular(8)),
      child: Stack(
        fit: StackFit.expand,
        children: [
          Image.network(movie.coverUrl, fit: BoxFit.cover),
          Container(
            decoration: const BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.centerLeft,
                end: Alignment.centerRight,
                colors: [
                  Color(0xEE0C0C0E),
                  Color(0x770C0C0E),
                  Color(0x110C0C0E),
                ],
              ),
            ),
          ),
          Padding(
            padding: const EdgeInsets.all(24),
            child: Align(
              alignment: Alignment.centerLeft,
              child: ConstrainedBox(
                constraints: const BoxConstraints(maxWidth: 520),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'Elite Prestige Screening',
                      style: TextStyle(
                        color: _gold,
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      movie.title,
                      style: Theme.of(context).textTheme.displaySmall?.copyWith(
                        fontFamily: 'Playfair Display',
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                    const SizedBox(height: 10),
                    Text(
                      movie.synopsis,
                      maxLines: 3,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(color: _muted, height: 1.45),
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

class MovieCard extends StatefulWidget {
  const MovieCard({
    super.key,
    required this.movie,
    required this.onTap,
    required this.onBook,
  });

  final Movie movie;
  final VoidCallback onTap;
  final VoidCallback onBook;

  @override
  State<MovieCard> createState() => _MovieCardState();
}

class _MovieCardState extends State<MovieCard> {
  bool _hovered = false;

  @override
  Widget build(BuildContext context) {
    return MouseRegion(
      onEnter: (_) => setState(() => _hovered = true),
      onExit: (_) => setState(() => _hovered = false),
      child: TweenAnimationBuilder<double>(
        tween: Tween(end: _hovered ? 1 : 0),
        duration: const Duration(milliseconds: 260),
        curve: Curves.easeOutCubic,
        builder: (context, value, child) {
          return Transform(
            alignment: Alignment.center,
            transform: Matrix4.identity()
              ..setEntry(3, 2, .001)
              ..translateByDouble(0, -8.0 * value, 0, 1)
              ..rotateX(-.035 * value)
              ..rotateY(.045 * value),
            child: child,
          );
        },
        child: InkWell(
          borderRadius: BorderRadius.circular(8),
          onTap: widget.onTap,
          child: AnimatedContainer(
            duration: const Duration(milliseconds: 260),
            clipBehavior: Clip.antiAlias,
            decoration: BoxDecoration(
              color: _surface,
              borderRadius: BorderRadius.circular(8),
              border: Border.all(
                color: (_hovered ? _gold : Colors.white).withValues(
                  alpha: _hovered ? .44 : .08,
                ),
              ),
              boxShadow: [
                BoxShadow(
                  color: (_hovered ? _gold : Colors.black).withValues(
                    alpha: _hovered ? .20 : .28,
                  ),
                  blurRadius: _hovered ? 28 : 18,
                  offset: Offset(0, _hovered ? 18 : 10),
                ),
              ],
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Expanded(
                  child: Stack(
                    fit: StackFit.expand,
                    children: [
                      Hero(
                        tag: 'poster-${widget.movie.id}',
                        child: Image.network(
                          widget.movie.posterUrl,
                          fit: BoxFit.cover,
                        ),
                      ),
                      AnimatedOpacity(
                        opacity: _hovered ? .16 : 0,
                        duration: const Duration(milliseconds: 260),
                        child: const DecoratedBox(
                          decoration: BoxDecoration(
                            gradient: LinearGradient(
                              begin: Alignment.topLeft,
                              end: Alignment.bottomRight,
                              colors: [
                                Colors.white24,
                                Colors.transparent,
                                Colors.white10,
                              ],
                            ),
                          ),
                        ),
                      ),
                      if (widget.movie.vipGold)
                        const Positioned(
                          top: 8,
                          right: 8,
                          child: _StatusPill(
                            color: _gold,
                            textColor: _obsidian,
                            label: 'VIP Gold',
                          ),
                        ),
                    ],
                  ),
                ),
                Padding(
                  padding: const EdgeInsets.all(12),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        widget.movie.title,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: const TextStyle(
                          fontWeight: FontWeight.w800,
                          fontSize: 16,
                        ),
                      ),
                      const SizedBox(height: 5),
                      Text(
                        '${widget.movie.genre} - ${widget.movie.year} - ${widget.movie.duration} phut',
                        style: const TextStyle(color: _muted, fontSize: 12),
                      ),
                      const SizedBox(height: 8),
                      Row(
                        children: [
                          Expanded(
                            child: OutlinedButton.icon(
                              onPressed: widget.onTap,
                              icon: const Icon(Icons.info_outline, size: 18),
                              label: const Text('CHI TIET'),
                            ),
                          ),
                          const SizedBox(width: 8),
                          IconButton.filled(
                            onPressed: widget.onBook,
                            icon: const Icon(
                              Icons.event_seat_outlined,
                              size: 18,
                            ),
                            tooltip: 'Dat ve',
                          ),
                        ],
                      ),
                    ],
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
