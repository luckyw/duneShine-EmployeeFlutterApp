import 'package:flutter/material.dart';
import '../constants/colors.dart';
import '../services/auth_service.dart';
import '../constants/text_styles.dart';
import '../utils/responsive_utils.dart';

class SplashScreen extends StatefulWidget {
  const SplashScreen({super.key});

  @override
  State<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends State<SplashScreen>
    with SingleTickerProviderStateMixin {
  final AuthService _authService = AuthService();
  late AnimationController _controller;
  late Animation<double> _fadeAnimation;
  late Animation<double> _scaleAnimation;
  late Animation<Offset> _slideAnimation;

  @override
  void initState() {
    super.initState();
    _setupAnimations();
    _checkAuthAndNavigate();
  }

  void _setupAnimations() {
    _controller = AnimationController(
      duration: const Duration(seconds: 2),
      vsync: this,
    );

    // Fade Animation: 0.0 to 1.0 over first 60%
    _fadeAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(
        parent: _controller,
        curve: const Interval(0.0, 0.6, curve: Curves.easeOut),
      ),
    );

    // Scale Animation: 0.85 to 1.0 over first 60%
    _scaleAnimation = Tween<double>(begin: 0.85, end: 1.0).animate(
      CurvedAnimation(
        parent: _controller,
        curve: const Interval(0.0, 0.6, curve: Curves.easeOutCubic),
      ),
    );

    // Slide Animation: Offset(0, 0.1) to Offset.zero over 0.2 to 0.8
    _slideAnimation = Tween<Offset>(
      begin: const Offset(0, 0.1),
      end: Offset.zero,
    ).animate(
      CurvedAnimation(
        parent: _controller,
        curve: const Interval(0.2, 0.8, curve: Curves.easeOutQuart),
      ),
    );

    _controller.forward();
  }

  Future<void> _checkAuthAndNavigate() async {
    // Wait for animation to complete + small buffer
    await Future.delayed(const Duration(seconds: 3));

    // Initialize auth service and check if user is logged in
    final isLoggedIn = await _authService.initialize();

    if (mounted) {
      if (isLoggedIn) {
        debugPrint('User already logged in, navigating to home...');
        _navigateWithSlide('/employee-home');
      } else {
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
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.white,
      body: Center(
        child: FadeTransition(
          opacity: _fadeAnimation,
          child: SlideTransition(
            position: _slideAnimation,
            child: ScaleTransition(
              scale: _scaleAnimation,
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                   // Logo Container with Shadow for depth
                  Container(
                    width: 120, 
                    height: 120,
                    child: ClipRRect(
                      borderRadius: BorderRadius.circular(24),
                      child: Image.asset(
                        'assets/images/app_logo.png',
                        fit: BoxFit.cover,
                      ),
                    ),
                  ),
                  const SizedBox(height: 40),
                  // App Name
                  Text.rich(
                    TextSpan(
                      children: [
                        TextSpan(
                          text: 'Dune',
                          style: AppTextStyles.headline(context).copyWith(
                            color: AppColors.primaryTeal,
                            fontSize: ResponsiveUtils.sp(context, 32), 
                            fontWeight: FontWeight.bold,
                            letterSpacing: 1.2,
                          ),
                        ),
                        TextSpan(
                          text: 'Shine',
                          style: AppTextStyles.headline(context).copyWith(
                            color: AppColors.gold,
                            fontSize: ResponsiveUtils.sp(context, 32), 
                            fontWeight: FontWeight.bold,
                            letterSpacing: 1.2,
                          ),
                        ),
                      ],
                    ),
                  ),
                  ResponsiveUtils.verticalSpace(context, 12),
                   // Employee Tag
                  Container(
                    padding: EdgeInsets.symmetric(
                      horizontal: ResponsiveUtils.w(context, 16),
                      vertical: ResponsiveUtils.h(context, 6),
                    ),
                    decoration: BoxDecoration(
                      color: AppColors.gold.withOpacity(0.1),
                      borderRadius: BorderRadius.circular(ResponsiveUtils.r(context, 20)),
                      border: Border.all(color: AppColors.gold.withOpacity(0.3)),
                    ),
                    child: Text(
                      'EMPLOYEE',
                      style: AppTextStyles.subtitle(context).copyWith(
                        color: AppColors.gold,
                        fontSize: ResponsiveUtils.sp(context, 12),
                        letterSpacing: 2.5,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}
