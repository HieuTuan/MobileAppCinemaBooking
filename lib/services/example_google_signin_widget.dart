import 'package:flutter/material.dart';
import 'auth_service.dart';

/// Example widget demonstrating Google OAuth sign-in integration
/// 
/// This is a reference implementation showing how to integrate
/// the AuthService Google OAuth flow in a Flutter UI.
/// 
/// **DO NOT USE THIS IN PRODUCTION** - This is an example only.
/// Integrate this pattern into your actual login screen.
class ExampleGoogleSignInWidget extends StatefulWidget {
  const ExampleGoogleSignInWidget({Key? key}) : super(key: key);

  @override
  State<ExampleGoogleSignInWidget> createState() =>
      _ExampleGoogleSignInWidgetState();
}

class _ExampleGoogleSignInWidgetState extends State<ExampleGoogleSignInWidget> {
  final AuthService _authService = AuthService();
  bool _isLoading = false;
  String? _errorMessage;

  @override
  void initState() {
    super.initState();
    _setupAuthStateListener();
  }

  /// Listen to authentication state changes
  void _setupAuthStateListener() {
    _authService.authStateStream.listen((state) {
      if (mounted) {
        setState(() {
          _isLoading = state == AuthState.authenticating ||
              state == AuthState.refreshing;
        });

        if (state == AuthState.authenticated) {
          // User successfully authenticated - navigate to home
          _navigateToHome();
        }
      }
    });
  }

  /// Handle Google Sign-In button press
  Future<void> _handleGoogleSignIn() async {
    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    try {
      final result = await _authService.signInWithGoogle();

      if (!mounted) return;

      if (result.isSuccess) {
        // Success! Navigation handled by auth state listener
        _showSuccessSnackBar('Welcome, ${result.user?.fullName}!');
      } else {
        // Handle error
        setState(() {
          _errorMessage = result.errorMessage;
          _isLoading = false;
        });

        // Show error message
        _showErrorSnackBar(result.errorMessage ?? 'Sign-in failed');
      }
    } catch (e) {
      if (!mounted) return;

      setState(() {
        _errorMessage = 'An unexpected error occurred';
        _isLoading = false;
      });

      _showErrorSnackBar('An unexpected error occurred: $e');
    }
  }

  void _navigateToHome() {
    // Replace with your actual navigation logic
    Navigator.of(context).pushReplacementNamed('/home');
  }

  void _showSuccessSnackBar(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: Colors.green,
        duration: const Duration(seconds: 2),
      ),
    );
  }

  void _showErrorSnackBar(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: Colors.red,
        duration: const Duration(seconds: 3),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Google Sign-In Example'),
      ),
      body: Center(
        child: Padding(
          padding: const EdgeInsets.all(24.0),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              // App Logo or Title
              const Icon(
                Icons.local_movies,
                size: 80,
                color: Colors.blue,
              ),
              const SizedBox(height: 16),
              const Text(
                'CineLuxe',
                style: TextStyle(
                  fontSize: 32,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 8),
              const Text(
                'Book your movie tickets',
                style: TextStyle(
                  fontSize: 16,
                  color: Colors.grey,
                ),
              ),
              const SizedBox(height: 48),

              // Google Sign-In Button
              if (_isLoading)
                const CircularProgressIndicator()
              else
                ElevatedButton.icon(
                  onPressed: _handleGoogleSignIn,
                  icon: Image.asset(
                    'assets/google_logo.png', // Add Google logo to assets
                    height: 24,
                    width: 24,
                    errorBuilder: (context, error, stackTrace) {
                      // Fallback if image not found
                      return const Icon(Icons.login);
                    },
                  ),
                  label: const Text(
                    'Sign in with Google',
                    style: TextStyle(fontSize: 16),
                  ),
                  style: ElevatedButton.styleFrom(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 24,
                      vertical: 12,
                    ),
                    backgroundColor: Colors.white,
                    foregroundColor: Colors.black87,
                    elevation: 2,
                  ),
                ),

              // Error Message Display
              if (_errorMessage != null) ...[
                const SizedBox(height: 24),
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: Colors.red.shade50,
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(color: Colors.red.shade200),
                  ),
                  child: Row(
                    children: [
                      Icon(Icons.error_outline, color: Colors.red.shade700),
                      const SizedBox(width: 8),
                      Expanded(
                        child: Text(
                          _errorMessage!,
                          style: TextStyle(color: Colors.red.shade700),
                        ),
                      ),
                    ],
                  ),
                ),
              ],

              // Additional Sign-In Options
              const SizedBox(height: 24),
              const Text(
                'or',
                style: TextStyle(color: Colors.grey),
              ),
              const SizedBox(height: 16),
              TextButton(
                onPressed: () {
                  // Navigate to email/password sign-in
                  Navigator.of(context).pushNamed('/email-signin');
                },
                child: const Text('Sign in with email'),
              ),
              TextButton(
                onPressed: () {
                  // Navigate to registration
                  Navigator.of(context).pushNamed('/register');
                },
                child: const Text('Create an account'),
              ),

              // Current User Info (for demo purposes)
              const SizedBox(height: 32),
              if (_authService.currentUser != null) ...[
                const Divider(),
                const SizedBox(height: 16),
                const Text(
                  'Current User:',
                  style: TextStyle(fontWeight: FontWeight.bold),
                ),
                const SizedBox(height: 8),
                Text('Name: ${_authService.currentUser!.fullName}'),
                Text('Email: ${_authService.currentUser!.email}'),
                Text('Rank: ${_authService.currentUser!.memberRank}'),
                Text('Points: ${_authService.currentUser!.points}'),
                const SizedBox(height: 16),
                ElevatedButton(
                  onPressed: () async {
                    await _authService.signOut();
                    if (mounted) {
                      setState(() {});
                      _showSuccessSnackBar('Signed out successfully');
                    }
                  },
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.red,
                  ),
                  child: const Text('Sign Out'),
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }
}
