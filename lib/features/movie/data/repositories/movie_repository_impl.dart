import 'package:cine_book/features/movie/data/models/movie_model.dart';
import 'package:cine_book/features/movie/domain/repositories/movie_repository.dart';

class MovieRepositoryImpl implements MovieRepository {
  // Reliable image URLs from a CDN (using placeholder service for absolute reliability)
  static const String _imgBase = 'https://picsum.photos/seed';

  @override
  Future<List<MovieModel>> getNowShowingMovies() async {
    await Future.delayed(const Duration(milliseconds: 500));
    return [
      MovieModel(
        id: '1',
        title: 'Avengers: Endgame',
        description: 'Sau những sự kiện tàn khốc của Avengers: Infinity War (2018), vũ trụ đang bị hủy hoại.',
        durationMinutes: 181,
        genre: ['Hành động', 'Phiêu lưu'],
        ageRating: 'C13',
        posterUrl: '$_imgBase/avengers/600/900',
        imdbRating: 8.4,
        status: 'NOW_SHOWING',
        releaseDate: '2019-04-26',
      ),
      MovieModel(
        id: '2',
        title: 'Spider-Man: No Way Home',
        description: 'Lần đầu tiên trong lịch sử điện ảnh của Người Nhện, danh tính của người anh hùng thân thiện hàng xóm của chúng ta bị lộ.',
        durationMinutes: 148,
        genre: ['Hành động', 'Viễn tưởng'],
        ageRating: 'C13',
        posterUrl: '$_imgBase/spiderman/600/900',
        imdbRating: 8.2,
        status: 'NOW_SHOWING',
        releaseDate: '2021-12-17',
      ),
      MovieModel(
        id: '6',
        title: 'Godzilla x Kong',
        description: 'Cuộc chiến giữa hai quái vật vĩ đại nhất lịch sử điện ảnh.',
        durationMinutes: 115,
        genre: ['Hành động', 'Quái vật'],
        ageRating: 'C13',
        posterUrl: '$_imgBase/godzilla/600/900',
        imdbRating: 6.7,
        status: 'NOW_SHOWING',
        releaseDate: '2024-03-29',
      ),
    ];
  }

  @override
  Future<List<MovieModel>> getComingSoonMovies() async {
    await Future.delayed(const Duration(milliseconds: 500));
    return [
      MovieModel(
        id: '3',
        title: 'Dune: Part Two',
        description: 'Paul Atreides hợp lực với Chani và người Fremen trong khi đang trên con đường trả thù.',
        durationMinutes: 166,
        genre: ['Hành động', 'Sử thi'],
        ageRating: 'C13',
        posterUrl: '$_imgBase/dune/600/900',
        imdbRating: 8.6,
        status: 'COMING_SOON',
        releaseDate: '2024-03-01',
      ),
      MovieModel(
        id: '7',
        title: 'Deadpool & Wolverine',
        description: 'Cặp đôi hoàn cảnh nhất vũ trụ Marvel hội ngộ.',
        durationMinutes: 127,
        genre: ['Hành động', 'Hài hước'],
        ageRating: 'C18',
        posterUrl: '$_imgBase/deadpool/600/900',
        imdbRating: 0.0,
        status: 'COMING_SOON',
        releaseDate: '2024-07-26',
      ),
    ];
  }

  @override
  Future<MovieModel> getMovieDetails(String id) async {
    final all = [...await getNowShowingMovies(), ...await getComingSoonMovies()];
    return all.firstWhere((m) => m.id == id, orElse: () => all.first);
  }
}
