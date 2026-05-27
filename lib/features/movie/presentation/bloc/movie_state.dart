import 'package:cine_book/features/movie/data/models/movie_model.dart';

abstract class MovieState {}

class MovieInitial extends MovieState {}

class MovieLoading extends MovieState {}

class MovieLoaded extends MovieState {
  final List<MovieModel> nowShowing;
  final List<MovieModel> comingSoon;

  MovieLoaded({required this.nowShowing, required this.comingSoon});
}

class MovieError extends MovieState {
  final String message;
  MovieError(this.message);
}
