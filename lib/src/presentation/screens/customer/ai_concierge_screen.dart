part of '../../../app.dart';

class AiConcierge extends StatefulWidget {
  const AiConcierge({super.key, required this.movies});

  final List<Movie> movies;

  @override
  State<AiConcierge> createState() => _AiConciergeState();
}

class _AiConciergeState extends State<AiConcierge> {
  final _controller = TextEditingController();
  final List<_ChatMessage> _messages = [
    const _ChatMessage(
      fromUser: false,
      text:
          'Kinh chao Quy khach. Cineverse AI san sang goi y phim, rap va combo am thuc phu hop.',
    ),
  ];

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Expanded(
          child: ListView.builder(
            padding: const EdgeInsets.all(18),
            itemCount: _messages.length,
            itemBuilder: (context, index) {
              final message = _messages[index];
              return Align(
                alignment: message.fromUser
                    ? Alignment.centerRight
                    : Alignment.centerLeft,
                child: Container(
                  constraints: const BoxConstraints(maxWidth: 720),
                  margin: const EdgeInsets.only(bottom: 10),
                  padding: const EdgeInsets.all(14),
                  decoration: BoxDecoration(
                    color: message.fromUser ? _gold : _surface,
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(
                      color: Colors.white.withValues(alpha: .07),
                    ),
                  ),
                  child: Text(
                    message.text,
                    style: TextStyle(
                      color: message.fromUser ? _obsidian : _stone,
                      height: 1.45,
                    ),
                  ),
                ),
              );
            },
          ),
        ),
        SafeArea(
          top: false,
          child: Padding(
            padding: const EdgeInsets.fromLTRB(14, 8, 14, 14),
            child: Row(
              children: [
                Expanded(
                  child: TextField(
                    controller: _controller,
                    decoration: const InputDecoration(
                      hintText: 'Vi du: toi di hen ho toi nay',
                    ),
                    onSubmitted: (_) => _send(),
                  ),
                ),
                const SizedBox(width: 10),
                IconButton.filled(
                  onPressed: _send,
                  icon: const Icon(Icons.send),
                  tooltip: 'Gui',
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }

  void _send() {
    final text = _controller.text.trim();
    if (text.isEmpty) return;
    final reply = _recommend(text);
    setState(() {
      _messages.add(_ChatMessage(fromUser: true, text: text));
      _messages.add(_ChatMessage(fromUser: false, text: reply));
      _controller.clear();
    });
  }

  String _recommend(String prompt) {
    final lower = prompt.toLowerCase();
    Movie pick;
    if (lower.contains('con') ||
        lower.contains('gia dinh') ||
        lower.contains('nho')) {
      pick = widget.movies.firstWhere(
        (movie) => movie.genre.contains('Hoat hinh'),
        orElse: () => widget.movies.first,
      );
    } else if (lower.contains('hen') ||
        lower.contains('doi') ||
        lower.contains('lang man')) {
      pick = widget.movies.firstWhere(
        (movie) => movie.vipGold,
        orElse: () => widget.movies.first,
      );
    } else if (lower.contains('hanh dong') || lower.contains('imax')) {
      pick = widget.movies.firstWhere(
        (movie) => movie.genre.contains('Khoa hoc'),
        orElse: () => widget.movies.first,
      );
    } else {
      pick = widget.movies[Random().nextInt(widget.movies.length)];
    }
    return 'Thua Quy khach, toi de xuat "${pick.title}" tai IMAX Landmark 81, hang ghe Prestige VIP C-D. Combo phu hop la Gourmet Gold Popcorn kem Champagne Rose. Neu can khong gian rieng tu, Royal Velvet Sofa Bed hang E-F se xung tam voi dem nay.';
  }
}

class _ChatMessage {
  const _ChatMessage({required this.fromUser, required this.text});

  final bool fromUser;
  final String text;
}
