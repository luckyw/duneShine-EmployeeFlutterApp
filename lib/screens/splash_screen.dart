import 'package:flutter/material.dart';
import '../constants/colors.dart';
import '../services/auth_service.dart';
import '../constants/text_styles.dart';

class SplashScreen extends StatefulWidget {
  const SplashScreen({super.key});

  @override
  State<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends State<SplashScreen> {
  final AuthService _authService = AuthService();

  @override
  void initState() {
    super.initState();
    // Check authentication and navigate accordingly
    _checkAuthAndNavigate();
  }

  Future<void> _checkAuthAndNavigate() async {
    // Wait for splash to display
    await Future.delayed(const Duration(seconds: 2));

    // Initialize auth service and check if user is logged in
    final isLoggedIn = await _authService.initialize();

    if (mounted) {
      // Add small delay before transition
      await Future.delayed(const Duration(milliseconds: 500));

      if (!mounted) return;

      if (isLoggedIn) {
        // User is already logged in, go to home screen
        debugPrint('User already logged in, navigating to home...');
        _navigateWithSlide('/employee-home');
      } else {
        // User not logged in, go to onboarding
        debugPrint('User not logged in, navigating to onboarding...');
        _navigateWithSlide('/onboarding');
      }
    }
  }

  void _navigateWithSlide(String routeName) {
    Navigator.of(context).pushReplacementNamed(
      routeName,
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.white,
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            // Static Logo
            Container(
              width: 200,
              height: 200,
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(20),
              ),
              child: ClipRRect(
                borderRadius: BorderRadius.circular(20),
                child: Image.asset(
                  'assets/images/app_logo.png',
                  fit: BoxFit.cover,
                ),
              ),
            ),
            const SizedBox(height: 30),
            // Static App Name
            Text(
              'DuneShine',
              style: AppTextStyles.headline(context).copyWith(
                color: AppColors.primaryTeal,
                fontSize: 36,
                letterSpacing: 2,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              'Employee',
              style: AppTextStyles.subtitle(context).copyWith(
                color: AppColors.gold,
                fontSize: 18,
                letterSpacing: 4,
                fontWeight: FontWeight.w300,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// Custom slide transition for navigation
class SlideUpPageRoute<T> extends PageRouteBuilder<T> {
  final Widget page;

  SlideUpPageRoute({required this.page})
      : super(
          pageBuilder: (context, animation, secondaryAnimation) => page,
          transitionsBuilder: (context, animation, secondaryAnimation, child) {
            const begin = Offset(0.0, 1.0);
            const end = Offset.zero;
            const curve = Curves.easeOutCubic;

            var tween = Tween(begin: begin, end: end).chain(
              CurveTween(curve: curve),
            );

            return SlideTransition(
              position: animation.drive(tween),
              child: child,
            );
          },
          transitionDuration: const Duration(milliseconds: 500),
        );
}
