import 'package:cine_book/features/auth/data/repositories/auth_repository_impl.dart';
import 'package:cine_book/features/auth/domain/repositories/auth_repository.dart';
import 'package:cine_book/features/auth/presentation/bloc/auth_bloc.dart';
import 'package:cine_book/features/booking/data/repositories/booking_repository_impl.dart';
import 'package:cine_book/features/booking/domain/repositories/booking_repository.dart';
import 'package:cine_book/features/movie/data/repositories/movie_repository_impl.dart';
import 'package:cine_book/features/movie/domain/repositories/movie_repository.dart';
import 'package:cine_book/features/movie/presentation/bloc/movie_bloc.dart';
import 'package:get_it/get_it.dart';

final getIt = GetIt.instance;

Future<void> initInjection() async {
  // Repositories
  getIt.registerLazySingleton<AuthRepository>(() => AuthRepositoryImpl());
  getIt.registerLazySingleton<MovieRepository>(() => MovieRepositoryImpl());
  getIt.registerLazySingleton<BookingRepository>(() => BookingRepositoryImpl());

  // Blocs
  getIt.registerFactory(() => AuthBloc(authRepository: getIt()));
  getIt.registerFactory(() => MovieBloc(movieRepository: getIt()));
}
