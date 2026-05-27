import 'package:cine_book/features/booking/data/models/showtime_model.dart';

abstract class BookingRepository {
  Future<List<ShowtimeModel>> getShowtimes(String movieId, DateTime date);
}
