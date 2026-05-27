import 'package:cine_book/core/constants/app_colors.dart';
import 'package:cine_book/core/utils/injection.dart';
import 'package:cine_book/features/movie/presentation/bloc/movie_bloc.dart';
import 'package:cine_book/features/movie/presentation/bloc/movie_event.dart';
import 'package:cine_book/features/movie/presentation/bloc/movie_state.dart';
import 'package:cine_book/shared/widgets/movie_card.dart';
import 'package:cine_book/router/app_router.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';

class HomeScreen extends StatelessWidget {
  const HomeScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return BlocProvider(
      create: (context) => getIt<MovieBloc>()..add(GetMoviesEvent()),
      child: Scaffold(
        backgroundColor: AppColors.backgroundDark,
        appBar: AppBar(
          backgroundColor: Colors.transparent,
          elevation: 0,
          title: const Text(
            'CineBook',
            style: TextStyle(color: AppColors.primary, fontWeight: FontWeight.bold),
          ),
          actions: [
            IconButton(
              onPressed: () {},
              icon: const Icon(Icons.notifications_none, color: Colors.white),
            ),
            const CircleAvatar(
              radius: 18,
              backgroundColor: AppColors.primary,
              child: Icon(Icons.person, color: Colors.white),
            ),
            const SizedBox(width: 16),
          ],
        ),
        body: BlocBuilder<MovieBloc, MovieState>(
          builder: (context, state) {
            if (state is MovieLoading) {
              return const Center(child: CircularProgressIndicator(color: AppColors.primary));
            } else if (state is MovieLoaded) {
              return SingleChildScrollView(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Padding(
                      padding: EdgeInsets.fromLTRB(16, 24, 16, 12),
                      child: Text(
                        'Phim đang chiếu',
                        style: TextStyle(
                          fontSize: 22,
                          fontWeight: FontWeight.bold,
                          color: Colors.white,
                        ),
                      ),
                    ),
                    SizedBox(
                      height: 320, // Sufficient height for the card + spacing
                      child: ListView.builder(
                        scrollDirection: Axis.horizontal,
                        itemCount: state.nowShowing.length,
                        padding: const EdgeInsets.symmetric(horizontal: 16),
                        physics: const BouncingScrollPhysics(),
                        itemBuilder: (context, index) {
                          return MovieCard(movie: state.nowShowing[index]);
                        },
                      ),
                    ),
                    const Padding(
                      padding: EdgeInsets.fromLTRB(16, 24, 16, 12),
                      child: Text(
                        'Phim sắp chiếu',
                        style: TextStyle(
                          fontSize: 22,
                          fontWeight: FontWeight.bold,
                          color: Colors.white,
                        ),
                      ),
                    ),
                    SizedBox(
                      height: 320, // Sufficient height for the card + spacing
                      child: ListView.builder(
                        scrollDirection: Axis.horizontal,
                        itemCount: state.comingSoon.length,
                        padding: const EdgeInsets.symmetric(horizontal: 16),
                        physics: const BouncingScrollPhysics(),
                        itemBuilder: (context, index) {
                          return MovieCard(movie: state.comingSoon[index]);
                        },
                      ),
                    ),
                  ],
                ),
              );
            } else if (state is MovieError) {
              return Center(child: Text(state.message, style: const TextStyle(color: Colors.red)));
            }
            return const SizedBox();
          },
        ),
        bottomNavigationBar: BottomNavigationBar(
          backgroundColor: AppColors.backgroundDark,
          selectedItemColor: AppColors.primary,
          unselectedItemColor: Colors.grey,
          type: BottomNavigationBarType.fixed,
          onTap: (index) {
            if (index == 2) {
              context.push(AppRouter.ticketList);
            }
          },
          items: const [
            BottomNavigationBarItem(icon: Icon(Icons.home), label: 'Trang chủ'),
            BottomNavigationBarItem(icon: Icon(Icons.search), label: 'Tìm kiếm'),
            BottomNavigationBarItem(icon: Icon(Icons.confirmation_number), label: 'Vé của tôi'),
            BottomNavigationBarItem(icon: Icon(Icons.person), label: 'Cá nhân'),
          ],
        ),
      ),
    );
  }
}
