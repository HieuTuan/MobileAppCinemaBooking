import 'package:cine_book/features/movie/data/models/movie_model.dart';

abstract class MovieRepository {
  Future<List<MovieModel>> getNowShowingMovies();
  Future<List<MovieModel>> getComingSoonMovies();
  Future<MovieModel> getMovieDetails(String id);
}
