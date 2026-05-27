import 'package:cine_book/core/constants/app_colors.dart';
import 'package:cine_book/core/utils/injection.dart';
import 'package:cine_book/features/auth/presentation/bloc/auth_bloc.dart';
import 'package:cine_book/features/auth/presentation/bloc/auth_event.dart';
import 'package:cine_book/router/app_router.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

void main() async {
  // 1. Đảm bảo Flutter framework đã sẵn sàng
  WidgetsFlutterBinding.ensureInitialized();
  
  // 2. Thử khởi tạo Firebase (Không để crash nếu thiếu config)
  try {
    await Firebase.initializeApp();
  } catch (e) {
    debugPrint('Firebase App initialization failed: $e');
  }

  // 3. Khởi tạo Dependency Injection (AuthRepository hiện đã an toàn)
  await initInjection();
  
  runApp(const CineBookApp());
}

class CineBookApp extends StatelessWidget {
  const CineBookApp({super.key});

  @override
  Widget build(BuildContext context) {
    return BlocProvider(
      // Lazy load Bloc để tránh truy cập Repository quá sớm
      create: (context) => getIt<AuthBloc>()..add(AuthCheckRequested()),
      child: MaterialApp.router(
        title: 'CineBook',
        debugShowCheckedModeBanner: false,
        theme: ThemeData(
          useMaterial3: true,
          primaryColor: AppColors.primary,
          colorScheme: ColorScheme.fromSeed(
            seedColor: AppColors.primary,
            brightness: Brightness.dark,
            surface: AppColors.backgroundDark,
          ),
          scaffoldBackgroundColor: AppColors.backgroundDark,
          fontFamily: 'Roboto',
        ),
        routerConfig: AppRouter.router,
      ),
    );
  }
}
