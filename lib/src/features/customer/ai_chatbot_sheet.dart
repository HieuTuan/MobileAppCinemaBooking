import 'dart:math' as math;

import 'package:flutter/material.dart';

import '../../core/app_theme.dart';
import '../../core/formatters.dart';
import '../../models/app_models.dart';
import '../../state/cinema_store.dart';

class AiChatbotButton extends StatelessWidget {
  const AiChatbotButton({super.key, required this.store});

  final CinemaStore store;

  @override
  Widget build(BuildContext context) {
    return FloatingActionButton.extended(
      heroTag: 'customer-ai-chatbot',
      backgroundColor: AppColors.ink,
      foregroundColor: Colors.white,
      icon: const Icon(Icons.smart_toy_rounded),
      label: const Text('AI'),
      onPressed: () => showModalBottomSheet<void>(
        context: context,
        isScrollControlled: true,
        useSafeArea: true,
        backgroundColor: Colors.transparent,
        builder: (_) => AiChatbotSheet(store: store),
      ),
    );
  }
}

class AiChatbotSheet extends StatefulWidget {
  const AiChatbotSheet({super.key, required this.store});

  final CinemaStore store;

  @override
  State<AiChatbotSheet> createState() => _AiChatbotSheetState();
}

class _AiChatbotSheetState extends State<AiChatbotSheet> {
  final _controller = TextEditingController();
  final _scrollController = ScrollController();
  final List<_ChatMessage> _messages = [
    const _ChatMessage(
      fromUser: false,
      text:
          'Xin chào, mình là trợ lý CineLuxe. Bạn có thể hỏi về giá vé, ưu đãi sinh viên, địa chỉ rạp, gửi xe, đồ ăn ngoài hoặc quy định độ tuổi phim.',
    ),
  ];

  @override
  void dispose() {
    _controller.dispose();
    _scrollController.dispose();
    super.dispose();
  }

  void _send([String? preset]) {
    final text = (preset ?? _controller.text).trim();
    if (text.isEmpty) return;
    _controller.clear();
    setState(() {
      _messages.add(_ChatMessage(fromUser: true, text: text));
      _messages.add(_ChatMessage(fromUser: false, text: _answer(text)));
    });
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!_scrollController.hasClients) return;
      _scrollController.animateTo(
        _scrollController.position.maxScrollExtent,
        duration: const Duration(milliseconds: 220),
        curve: Curves.easeOut,
      );
    });
  }

  String _answer(String question) {
    final q = _normalize(question);
    final cinema = _findCinema(q);

    if (_hasAny(q, const ['gia', 've', 'sinh vien', 'hssv', 'uu dai'])) {
      return _priceAnswer(q, cinema);
    }
    if (_hasAny(q, const [
      'dia chi',
      'o dau',
      'tang',
      'gui xe',
      'di chuyen',
      'maps',
      'vincom',
    ])) {
      return _locationAnswer(cinema);
    }
    if (_hasAny(q, const ['do an', 'bap nuoc', 'mang vao', 'ngoai vao'])) {
      return _outsideFoodAnswer(cinema);
    }
    if (_hasAny(q, const [
      'tuoi',
      't18',
      'c18',
      'c16',
      'c13',
      'p',
      'k',
      'tre em',
    ])) {
      return _ageRatingAnswer(q);
    }
    if (_hasAny(q, const ['khuyet tat', 'xe lan', 'ghe tre em', 'ho tro'])) {
      return _accessibilityAnswer(cinema);
    }

    return _generalAnswer(cinema);
  }

  String _priceAnswer(String q, Cinema? cinema) {
    final weekend = _hasAny(q, const [
      'thu 7',
      'thu bay',
      'chu nhat',
      'cuoi tuan',
      'weekend',
    ]);
    final student = _hasAny(q, const ['sinh vien', 'hssv', 'hoc sinh']);
    final showtimes = _showtimesForCinema(cinema);
    final base = _referencePrice(showtimes, weekend: weekend);
    final vip = base + 45000;
    final couple = base + 70000;
    final studentPrice = weekend
        ? math.max(base - 10000, 0)
        : math.max(base - 20000, 0);
    final cinemaName = cinema?.name ?? 'rạp CineLuxe gần nhất';

    if (student) {
      return [
        'Giá vé HSSV tại $cinemaName ${weekend ? 'cuối tuần/thứ 7' : 'ngày thường'} hiện tham chiếu khoảng ${money(studentPrice)} cho ghế thường.',
        'Ghế VIP khoảng ${money(math.max(vip - 10000, 0))}, ghế đôi tính theo bảng giá ghế đôi tại quầy.',
        'Bạn nhớ mang thẻ học sinh/sinh viên còn hạn và giấy tờ có ảnh khi nhận vé. Ưu đãi có thể không áp dụng cho suất đặc biệt, lễ/Tết hoặc phòng premium.',
      ].join('\n\n');
    }

    return [
      'Bảng giá tham chiếu tại $cinemaName:',
      '- Ghế thường: ${money(base)}',
      '- Ghế VIP: ${money(vip)}',
      '- Ghế đôi: ${money(couple)}',
      if (showtimes.isNotEmpty)
        'Mức này lấy theo dữ liệu suất chiếu đang có trong app; giá cuối cùng sẽ hiện ở bước chọn ghế.'
      else
        'Hiện chưa có suất chiếu cụ thể của rạp này trong app, nên mình dùng bảng giá mặc định của CineLuxe.',
    ].join('\n');
  }

  String _locationAnswer(Cinema? cinema) {
    final c = cinema ?? _fallbackCinema();
    final address = c.address.trim().isEmpty
        ? 'trung tâm thương mại CineLuxe'
        : c.address;
    final mapQuery = Uri.encodeComponent('${c.name} $address');
    final maps = 'https://www.google.com/maps/search/?api=1&query=$mapQuery';
    final floor = _inferFloor(c);

    return [
      '${c.name} nằm tại $address.',
      'Vị trí trong TTTM: $floor. Bạn nên đi thang máy khu trung tâm/food court, sau đó theo biển chỉ dẫn “Cinema”.',
      'Gửi xe: đi theo cổng hầm B1/B2 của TTTM; phí dự kiến 5.000-15.000 VNĐ/xe máy hoặc theo bảng phí tại nơi gửi.',
      'Google Maps: $maps',
    ].join('\n\n');
  }

  String _outsideFoodAnswer(Cinema? cinema) {
    return [
      'Theo quy định CineLuxe, khách không mang đồ ăn/nước uống bên ngoài vào phòng chiếu.',
      'Bạn có thể mua bắp nước tại quầy combo. Nếu có nhu cầu y tế hoặc đồ ăn đặc biệt cho trẻ nhỏ, hãy báo nhân viên trước khi vào rạp để được hỗ trợ.',
      if (cinema != null) 'Rạp áp dụng: ${cinema.name}.',
    ].join('\n\n');
  }

  String _ageRatingAnswer(String q) {
    final movie = widget.store.movies
        .where((item) => q.contains(_normalize(item.title)))
        .firstOrNull;
    final specific = movie == null
        ? ''
        : '\n\nPhim "${movie.title}" đang gắn nhãn ${movie.ageRating}.';

    return [
      'Quy định độ tuổi tham khảo:',
      '- P: phổ biến cho mọi độ tuổi.',
      '- C13: không dành cho khán giả dưới 13 tuổi.',
      '- C16: không dành cho khán giả dưới 16 tuổi.',
      '- C18/T18: không dành cho khán giả dưới 18 tuổi, có thể cần giấy tờ tùy thân.',
      '- K: trẻ em cần có người giám hộ đi kèm nếu rạp/phim áp dụng nhãn này.',
      'CineLuxe có thể yêu cầu CCCD/hộ chiếu/thẻ học sinh sinh viên để kiểm tra khi cần.$specific',
    ].join('\n');
  }

  String _accessibilityAnswer(Cinema? cinema) {
    final rooms = cinema == null
        ? widget.store.rooms
        : widget.store.rooms
              .where((room) => room.cinemaId == cinema.id)
              .toList();
    final roomText = rooms.isEmpty
        ? 'Hiện app chưa có chi tiết phòng của rạp này.'
        : 'Các phòng đang có dữ liệu: ${rooms.map((r) => '${r.name} (${r.screenType})').take(4).join(', ')}.';

    return [
      cinema == null
          ? 'CineLuxe có hỗ trợ khách cần trợ giúp tại quầy.'
          : '${cinema.name} có hỗ trợ khách cần trợ giúp tại quầy.',
      'Ghế trẻ em và hỗ trợ xe lăn tùy tình trạng từng rạp; bạn nên báo nhân viên trước giờ chiếu 15-20 phút.',
      roomText,
    ].join('\n\n');
  }

  String _generalAnswer(Cinema? cinema) {
    final movies = widget.store.movies.take(3).map((m) => m.title).join(', ');
    final c = cinema ?? _fallbackCinema();
    return [
      'Mình có thể hỗ trợ nhanh về:',
      '- Giá vé, HSSV, cuối tuần',
      '- Địa chỉ rạp, tầng, bãi gửi xe, Google Maps',
      '- Quy định đồ ăn ngoài, độ tuổi phim',
      '- Ghế trẻ em, hỗ trợ xe lăn',
      if (widget.store.movies.isNotEmpty)
        'Một số phim đang có trong app: $movies.',
      'Bạn đang hỏi theo rạp: ${c.name}.',
    ].join('\n');
  }

  List<Showtime> _showtimesForCinema(Cinema? cinema) {
    if (cinema == null) return widget.store.showtimes;
    final roomIds = widget.store.rooms
        .where((room) => room.cinemaId == cinema.id)
        .map((room) => room.id)
        .toSet();
    return widget.store.showtimes
        .where((item) => roomIds.contains(item.roomId))
        .toList();
  }

  int _referencePrice(List<Showtime> showtimes, {required bool weekend}) {
    if (showtimes.isEmpty) return weekend ? 120000 : 90000;
    final sorted = [...showtimes]
      ..sort((a, b) => a.basePrice.compareTo(b.basePrice));
    return weekend ? sorted.last.basePrice : sorted.first.basePrice;
  }

  Cinema? _findCinema(String q) {
    for (final cinema in widget.store.cinemas) {
      final haystack = _normalize(
        '${cinema.name} ${cinema.address} ${cinema.city}',
      );
      if (q.contains(_normalize(cinema.name)) ||
          haystack
              .split(' ')
              .where((word) => word.length > 2)
              .any(q.contains)) {
        return cinema;
      }
    }
    if (q.contains('quan 1') || q.contains('q1')) {
      return widget.store.cinemas
          .where((cinema) => _normalize(cinema.address).contains('quan 1'))
          .firstOrNull;
    }
    return widget.store.cinemas.firstOrNull;
  }

  Cinema _fallbackCinema() {
    return widget.store.cinemas.firstOrNull ??
        const Cinema(
          id: 'cineluxe-default',
          name: 'CineLuxe',
          address: 'Tầng 5, trung tâm thương mại CineLuxe',
          city: '',
          latitude: 0,
          longitude: 0,
          phone: '',
        );
  }

  String _inferFloor(Cinema cinema) {
    final text = _normalize('${cinema.name} ${cinema.address}');
    if (text.contains('vincom')) return 'tầng 5, khu rạp chiếu phim Vincom';
    if (text.contains('lotte')) return 'tầng cao nhất/khu giải trí Lotte';
    if (text.contains('aeon')) return 'khu entertainment, gần cụm food court';
    return 'tầng 5 hoặc khu giải trí của TTTM';
  }

  bool _hasAny(String value, List<String> tokens) {
    return tokens.any(value.contains);
  }

  String _normalize(String value) {
    final lower = value.toLowerCase();
    const source =
        'àáạảãâầấậẩẫăằắặẳẵèéẹẻẽêềếệểễìíịỉĩòóọỏõôồốộổỗơờớợởỡùúụủũưừứựửữỳýỵỷỹđ';
    const target =
        'aaaaaaaaaaaaaaaaaeeeeeeeeeeeiiiiiooooooooooooooooouuuuuuuuuuuyyyyyd';
    var result = lower;
    for (var i = 0; i < source.length; i++) {
      result = result.replaceAll(source[i], target[i]);
    }
    return result.replaceAll(RegExp(r'\s+'), ' ').trim();
  }

  @override
  Widget build(BuildContext context) {
    final bottomInset = MediaQuery.viewInsetsOf(context).bottom;
    return Padding(
      padding: EdgeInsets.only(bottom: bottomInset),
      child: DraggableScrollableSheet(
        expand: false,
        initialChildSize: .86,
        minChildSize: .55,
        maxChildSize: .96,
        builder: (context, scrollController) {
          return Container(
            decoration: const BoxDecoration(
              color: AppColors.ivory,
              borderRadius: BorderRadius.vertical(top: Radius.circular(18)),
            ),
            child: Column(
              children: [
                _ChatHeader(onClose: () => Navigator.pop(context)),
                _QuickPrompts(onTap: _send),
                Expanded(
                  child: ListView.builder(
                    controller: _scrollController,
                    padding: const EdgeInsets.fromLTRB(14, 10, 14, 12),
                    itemCount: _messages.length,
                    itemBuilder: (context, index) {
                      return _ChatBubble(message: _messages[index]);
                    },
                  ),
                ),
                _ChatInput(controller: _controller, onSend: _send),
              ],
            ),
          );
        },
      ),
    );
  }
}

class _ChatHeader extends StatelessWidget {
  const _ChatHeader({required this.onClose});

  final VoidCallback onClose;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.fromLTRB(16, 12, 8, 12),
      decoration: const BoxDecoration(
        color: AppColors.ink,
        borderRadius: BorderRadius.vertical(top: Radius.circular(18)),
      ),
      child: Row(
        children: [
          Container(
            width: 38,
            height: 38,
            decoration: BoxDecoration(
              color: AppColors.gold,
              borderRadius: BorderRadius.circular(8),
            ),
            child: const Icon(Icons.smart_toy_rounded, color: Colors.white),
          ),
          const SizedBox(width: 10),
          const Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'CineLuxe AI',
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 16,
                    fontWeight: FontWeight.w900,
                  ),
                ),
                Text(
                  'Giá vé, rạp, chính sách 24/7',
                  style: TextStyle(color: Colors.white70, fontSize: 12),
                ),
              ],
            ),
          ),
          IconButton(
            onPressed: onClose,
            icon: const Icon(Icons.close_rounded, color: Colors.white70),
          ),
        ],
      ),
    );
  }
}

class _QuickPrompts extends StatelessWidget {
  const _QuickPrompts({required this.onTap});

  final ValueChanged<String> onTap;

  @override
  Widget build(BuildContext context) {
    const prompts = [
      'Giá vé sinh viên thứ 7?',
      'Rạp ở tầng mấy, gửi xe đâu?',
      'Có được mang đồ ăn ngoài không?',
      'Quy định T18 là gì?',
      'Có hỗ trợ xe lăn không?',
    ];
    return SizedBox(
      height: 52,
      child: ListView.separated(
        padding: const EdgeInsets.fromLTRB(14, 10, 14, 8),
        scrollDirection: Axis.horizontal,
        itemCount: prompts.length,
        separatorBuilder: (_, __) => const SizedBox(width: 8),
        itemBuilder: (context, index) {
          return ActionChip(
            label: Text(prompts[index]),
            onPressed: () => onTap(prompts[index]),
            avatar: const Icon(Icons.auto_awesome_rounded, size: 16),
          );
        },
      ),
    );
  }
}

class _ChatBubble extends StatelessWidget {
  const _ChatBubble({required this.message});

  final _ChatMessage message;

  @override
  Widget build(BuildContext context) {
    final align = message.fromUser
        ? Alignment.centerRight
        : Alignment.centerLeft;
    final color = message.fromUser ? AppColors.ink : Colors.white;
    final textColor = message.fromUser ? Colors.white : AppColors.ink;
    return Align(
      alignment: align,
      child: Container(
        constraints: BoxConstraints(
          maxWidth: MediaQuery.sizeOf(context).width * .78,
        ),
        margin: const EdgeInsets.symmetric(vertical: 5),
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: color,
          borderRadius: BorderRadius.circular(8),
          border: message.fromUser ? null : Border.all(color: AppColors.line),
        ),
        child: Text(
          message.text,
          style: TextStyle(color: textColor, height: 1.35, fontSize: 13.5),
        ),
      ),
    );
  }
}

class _ChatInput extends StatelessWidget {
  const _ChatInput({required this.controller, required this.onSend});

  final TextEditingController controller;
  final VoidCallback onSend;

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      top: false,
      child: Container(
        padding: const EdgeInsets.fromLTRB(12, 10, 12, 12),
        decoration: const BoxDecoration(
          color: Colors.white,
          border: Border(top: BorderSide(color: AppColors.line)),
        ),
        child: Row(
          children: [
            Expanded(
              child: TextField(
                controller: controller,
                minLines: 1,
                maxLines: 4,
                textInputAction: TextInputAction.send,
                onSubmitted: (_) => onSend(),
                decoration: InputDecoration(
                  hintText: 'Hỏi về giá vé, địa chỉ rạp, chính sách...',
                  filled: true,
                  fillColor: AppColors.pearl,
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(8),
                    borderSide: BorderSide.none,
                  ),
                  contentPadding: const EdgeInsets.symmetric(
                    horizontal: 12,
                    vertical: 10,
                  ),
                ),
              ),
            ),
            const SizedBox(width: 8),
            IconButton.filled(
              onPressed: onSend,
              icon: const Icon(Icons.send_rounded),
              style: IconButton.styleFrom(backgroundColor: AppColors.ink),
            ),
          ],
        ),
      ),
    );
  }
}

class _ChatMessage {
  const _ChatMessage({required this.fromUser, required this.text});

  final bool fromUser;
  final String text;
}
