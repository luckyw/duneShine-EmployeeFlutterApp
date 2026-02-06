import 'package:flutter/material.dart';
import '../constants/colors.dart';
import '../utils/responsive_utils.dart';

class OnboardingScreen extends StatefulWidget {
  const OnboardingScreen({Key? key}) : super(key: key);

  @override
  State<OnboardingScreen> createState() => _OnboardingScreenState();
}

class _OnboardingScreenState extends State<OnboardingScreen> {
  final PageController _pageController = PageController();
  int _currentPage = 0;

  final List<OnboardingData> _pages = [
    OnboardingData(
      image: 'assets/images/onboarding_car_wash.png',
      title: 'Professional Car Care',
      description:
          'Deliver premium car washing services to customers at their convenience. Your expertise makes the difference.',
    ),
    OnboardingData(
      image: 'assets/images/onboarding_schedule.png',
      title: 'Flexible Schedule',
      description:
          'Set your own availability and manage your work hours. Work when it suits you best.',
    ),
  ];

  void _nextPage() {
    if (_currentPage < _pages.length - 1) {
      _pageController.nextPage(
        duration: const Duration(milliseconds: 300),
        curve: Curves.easeInOut,
      );
    } else {
      Navigator.pushReplacementNamed(context, '/login');
    }
  }

  void _skip() {
    Navigator.pushReplacementNamed(context, '/login');
  }

  @override
  void dispose() {
    _pageController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.darkNavy,
      body: SafeArea(
        child: Column(
          children: [
            // Skip button
            Align(
              alignment: Alignment.topRight,
              child: Padding(
                padding: EdgeInsets.all(ResponsiveUtils.w(context, 16)),
                child: TextButton(
                  onPressed: _skip,
                  child: Text(
                    'Skip',
                    style: TextStyle(
                      color: AppColors.white.withOpacity(0.7),
                      fontSize: ResponsiveUtils.sp(context, 16),
                    ),
                  ),
                ),
              ),
            ),
            // Page content
            Expanded(
              child: PageView.builder(
                controller: _pageController,
                itemCount: _pages.length,
                onPageChanged: (index) {
                  setState(() {
                    _currentPage = index;
                  });
                },
                itemBuilder: (context, index) {
                  return _buildPage(_pages[index]);
                },
              ),
            ),
            // Dot indicators
            Padding(
              padding: EdgeInsets.symmetric(
                vertical: ResponsiveUtils.h(context, 20),
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: List.generate(
                  _pages.length,
                  (index) => AnimatedContainer(
                    duration: const Duration(milliseconds: 300),
                    margin: EdgeInsets.symmetric(
                      horizontal: ResponsiveUtils.w(context, 4),
                    ),
                    width:
                        _currentPage == index
                            ? ResponsiveUtils.w(context, 24)
                            : ResponsiveUtils.w(context, 8),
                    height: ResponsiveUtils.h(context, 8),
                    decoration: BoxDecoration(
                      color:
                          _currentPage == index
                              ? AppColors.primaryTeal
                              : AppColors.white.withOpacity(0.3),
                      borderRadius: BorderRadius.circular(
                        ResponsiveUtils.r(context, 4),
                      ),
                    ),
                  ),
                ),
              ),
            ),
            // Next/Get Started button
            Padding(
              padding: EdgeInsets.all(ResponsiveUtils.w(context, 24)),
              child: SizedBox(
                width: double.infinity,
                height: ResponsiveUtils.h(context, 56),
                child: ElevatedButton(
                  onPressed: _nextPage,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppColors.primaryTeal,
                    foregroundColor: AppColors.white,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(
                        ResponsiveUtils.r(context, 16),
                      ),
                    ),
                    elevation: 4,
                    shadowColor: AppColors.primaryTeal.withOpacity(0.4),
                  ),
                  child: Text(
                    _currentPage == _pages.length - 1 ? 'Get Started' : 'Next',
                    style: TextStyle(
                      fontSize: ResponsiveUtils.sp(context, 18),
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildPage(OnboardingData data) {
    return LayoutBuilder(
      builder: (context, constraints) {
        return SingleChildScrollView(
          physics: const ClampingScrollPhysics(),
          child: ConstrainedBox(
            constraints: BoxConstraints(
              minHeight: constraints.maxHeight,
            ),
            child: IntrinsicHeight(
              child: Padding(
                padding: EdgeInsets.symmetric(
                  horizontal: ResponsiveUtils.w(context, 24),
                ),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    // Image
                    Container(
                      width: ResponsiveUtils.w(context, 280),
                      height: ResponsiveUtils.w(context, 280), // Keep aspect ratio 1:1
                      decoration: BoxDecoration(
                        borderRadius: BorderRadius.circular(
                          ResponsiveUtils.r(context, 24),
                        ),
                        boxShadow: [
                          BoxShadow(
                            color: AppColors.primaryTeal.withOpacity(0.2),
                            blurRadius: 30,
                            spreadRadius: 5,
                          ),
                        ],
                      ),
                      child: ClipRRect(
                        borderRadius: BorderRadius.circular(
                          ResponsiveUtils.r(context, 24),
                        ),
                        child: Image.asset(data.image, fit: BoxFit.cover),
                      ),
                    ),
                    ResponsiveUtils.verticalSpace(context, 48),
                    // Title
                    Text(
                      data.title,
                      style: TextStyle(
                        fontSize: ResponsiveUtils.sp(context, 28),
                        fontWeight: FontWeight.bold,
                        color: AppColors.white,
                      ),
                      textAlign: TextAlign.center,
                    ),
                    ResponsiveUtils.verticalSpace(context, 16),
                    // Description
                    Text(
                      data.description,
                      style: TextStyle(
                        fontSize: ResponsiveUtils.sp(context, 16),
                        color: AppColors.white.withOpacity(0.7),
                        height: 1.5,
                      ),
                      textAlign: TextAlign.center,
                    ),
                  ],
                ),
              ),
            ),
          ),
        );
      },
    );
  }
}

class OnboardingData {
  final String image;
  final String title;
  final String description;

  OnboardingData({
    required this.image,
    required this.title,
    required this.description,
  });
}
