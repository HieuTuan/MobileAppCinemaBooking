import 'package:cine_book/features/booking/data/models/showtime_model.dart';
import 'package:cine_book/features/booking/domain/repositories/booking_repository.dart';

class BookingRepositoryImpl implements BookingRepository {
  @override
  Future<List<ShowtimeModel>> getShowtimes(String movieId, DateTime date) async {
    await Future.delayed(const Duration(milliseconds: 500));
    
    // Mock data for multiple cinemas and times
    return [
      ShowtimeModel(
        id: 'st1',
        movieId: movieId,
        cinemaName: 'CGV Vincom Center',
        startTime: DateTime(date.year, date.month, date.day, 10, 30),
        format: '2D',
        price: 90000,
      ),
      ShowtimeModel(
        id: 'st2',
        movieId: movieId,
        cinemaName: 'CGV Vincom Center',
        startTime: DateTime(date.year, date.month, date.day, 14, 00),
        format: '3D',
        price: 120000,
      ),
      ShowtimeModel(
        id: 'st3',
        movieId: movieId,
        cinemaName: 'Lotte Cinema Landmark',
        startTime: DateTime(date.year, date.month, date.day, 11, 00),
        format: '2D',
        price: 85000,
      ),
      ShowtimeModel(
        id: 'st4',
        movieId: movieId,
        cinemaName: 'Lotte Cinema Landmark',
        startTime: DateTime(date.year, date.month, date.day, 19, 30),
        format: 'IMAX',
        price: 250000,
      ),
      ShowtimeModel(
        id: 'st5',
        movieId: movieId,
        cinemaName: 'BHD Star Cineplex',
        startTime: DateTime(date.year, date.month, date.day, 21, 15),
        format: '2D',
        price: 80000,
      ),
    ];
  }
}
