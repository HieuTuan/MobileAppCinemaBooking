import 'package:cine_book/core/constants/app_colors.dart';
import 'package:cine_book/features/auth/presentation/bloc/auth_bloc.dart';
import 'package:cine_book/features/auth/presentation/bloc/auth_event.dart';
import 'package:cine_book/features/auth/presentation/bloc/auth_state.dart';
import 'package:cine_book/router/app_router.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';

class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  final TextEditingController _phoneController = TextEditingController();

  @override
  Widget build(BuildContext context) {
    return BlocListener<AuthBloc, AuthState>(
      listener: (context, state) {
        if (state is Authenticated) {
          context.go(AppRouter.home);
        } else if (state is AuthCodeSent) {
          context.push('${AppRouter.otp}?verificationId=${state.verificationId}&phoneNumber=${_phoneController.text}');
        } else if (state is AuthFailure) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text(state.message)),
          );
        } else if (state is AuthInitial && _phoneController.text == '0123456789') {
          // Special case for mock success transition
          context.go(AppRouter.home);
        }
      },
      child: Scaffold(
        backgroundColor: AppColors.backgroundDark,
        body: SingleChildScrollView(
          padding: const EdgeInsets.all(24.0),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              const SizedBox(height: 100),
              const Icon(Icons.movie_filter, size: 80, color: AppColors.primary),
              const SizedBox(height: 24),
              const Text(
                'Chào mừng đến với CineBook',
                style: TextStyle(fontSize: 28, fontWeight: FontWeight.bold, color: Colors.white),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 48),
              TextField(
                controller: _phoneController,
                keyboardType: TextInputType.phone,
                style: const TextStyle(color: Colors.white),
                decoration: InputDecoration(
                  hintText: 'Số điện thoại (Mock: 0123456789)',
                  hintStyle: const TextStyle(color: Colors.white24),
                  prefixIcon: const Icon(Icons.phone, color: Colors.white24),
                  enabledBorder: OutlineInputBorder(borderSide: const BorderSide(color: Colors.white24), borderRadius: BorderRadius.circular(12)),
                  focusedBorder: OutlineInputBorder(borderSide: const BorderSide(color: AppColors.primary), borderRadius: BorderRadius.circular(12)),
                ),
              ),
              const SizedBox(height: 16),
              BlocBuilder<AuthBloc, AuthState>(
                builder: (context, state) {
                  return ElevatedButton(
                    onPressed: state is AuthLoading
                        ? null
                        : () {
                            if (_phoneController.text.isNotEmpty) {
                              context.read<AuthBloc>().add(AuthSignInWithPhoneRequested(_phoneController.text));
                            }
                          },
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppColors.primary,
                      padding: const EdgeInsets.symmetric(vertical: 16),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                    ),
                    child: state is AuthLoading
                        ? const SizedBox(height: 20, width: 20, child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2))
                        : const Text('ĐĂNG NHẬP VỚI SĐT', style: TextStyle(fontWeight: FontWeight.bold, color: Colors.white)),
                  );
                },
              ),
              const SizedBox(height: 24),
              const Row(
                children: [
                  Expanded(child: Divider(color: Colors.white24)),
                  Padding(padding: EdgeInsets.symmetric(horizontal: 16), child: Text('HOẶC', style: TextStyle(color: Colors.white24))),
                  Expanded(child: Divider(color: Colors.white24)),
                ],
              ),
              const SizedBox(height: 24),
              OutlinedButton.icon(
                onPressed: () {
                  context.go(AppRouter.home);
                },
                icon: const Icon(Icons.g_mobiledata, size: 32),
                label: const Text('TIẾP TỤC VỚI GOOGLE', style: TextStyle(color: Colors.white)),
                style: OutlinedButton.styleFrom(
                  side: const BorderSide(color: Colors.white24),
                  padding: const EdgeInsets.symmetric(vertical: 12),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
