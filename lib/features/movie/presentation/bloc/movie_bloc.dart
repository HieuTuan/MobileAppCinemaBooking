import 'package:cine_book/features/movie/domain/repositories/movie_repository.dart';
import 'package:cine_book/features/movie/presentation/bloc/movie_event.dart';
import 'package:cine_book/features/movie/presentation/bloc/movie_state.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

class MovieBloc extends Bloc<MovieEvent, MovieState> {
  final MovieRepository movieRepository;

  MovieBloc({required this.movieRepository}) : super(MovieInitial()) {
    on<GetMoviesEvent>((event, emit) async {
      emit(MovieLoading());
      try {
        final nowShowing = await movieRepository.getNowShowingMovies();
        final comingSoon = await movieRepository.getComingSoonMovies();
        emit(MovieLoaded(nowShowing: nowShowing, comingSoon: comingSoon));
      } catch (e) {
        emit(MovieError(e.toString()));
      }
    });
  }
}
