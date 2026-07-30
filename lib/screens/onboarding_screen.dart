import 'package:flutter/material.dart';
import 'package:geolocator/geolocator.dart';
import '../constants/colors.dart';
import '../utils/responsive_utils.dart';

class OnboardingScreen extends StatefulWidget {
  const OnboardingScreen({Key? key}) : super(key: key);

  @override
  State<OnboardingScreen> createState() => _OnboardingScreenState();
}

class _OnboardingScreenState extends State<OnboardingScreen> with WidgetsBindingObserver {
  final PageController _pageController = PageController();
  int _currentPage = 0;
  bool _isCheckingBackground = false;

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

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    _pageController.dispose();
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) async {
    if (state == AppLifecycleState.resumed && _isCheckingBackground) {
      _isCheckingBackground = false;
      LocationPermission permission = await Geolocator.checkPermission();
      if (permission == LocationPermission.always) {
        if (mounted) {
          Navigator.pushReplacementNamed(context, '/login');
        }
      }
    }
  }

  void _nextPage() {
    if (_currentPage < 3) {
      _pageController.nextPage(
        duration: const Duration(milliseconds: 300),
        curve: Curves.easeInOut,
      );
    }
  }

  Future<void> _handleForegroundRequest() async {
    bool serviceEnabled = await Geolocator.isLocationServiceEnabled();
    if (!serviceEnabled) {
      if (mounted) Navigator.pushReplacementNamed(context, '/login');
      return;
    }

    LocationPermission permission = await Geolocator.checkPermission();
    if (permission == LocationPermission.denied) {
      permission = await Geolocator.requestPermission();
    }

    if (permission == LocationPermission.always || permission == LocationPermission.whileInUse) {
      // Granted foreground, go to page 4
      if (mounted) {
        _pageController.nextPage(
          duration: const Duration(milliseconds: 300),
          curve: Curves.easeInOut,
        );
      }
    } else {
      // Denied foreground, skip background and go to login
      if (mounted) {
        Navigator.pushReplacementNamed(context, '/login');
      }
    }
  }

  Future<void> _handleBackgroundRequest() async {
    LocationPermission permission = await Geolocator.checkPermission();
    if (permission == LocationPermission.always) {
      if (mounted) Navigator.pushReplacementNamed(context, '/login');
      return;
    }

    _isCheckingBackground = true;
    permission = await Geolocator.requestPermission();
    
    if (permission == LocationPermission.whileInUse) {
      await Geolocator.openAppSettings();
    } else if (permission == LocationPermission.always) {
      _isCheckingBackground = false;
      if (mounted) Navigator.pushReplacementNamed(context, '/login');
    }
  }

  void _skipToLogin() {
    Navigator.pushReplacementNamed(context, '/login');
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.darkNavy,
      body: SafeArea(
        child: Column(
          children: [
            // Page content
            Expanded(
              child: PageView(
                controller: _pageController,
                physics: const NeverScrollableScrollPhysics(), // Disable swipe to force button clicks
                onPageChanged: (index) {
                  setState(() {
                    _currentPage = index;
                  });
                },
                children: [
                  _buildStandardPage(_pages[0]),
                  _buildStandardPage(_pages[1]),
                  _buildForegroundPage(),
                  _buildBackgroundPage(),
                ],
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
                  4,
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
            // Bottom Action Area
            _buildBottomAction(),
          ],
        ),
      ),
    );
  }

  Widget _buildBottomAction() {
    if (_currentPage < 2) {
      return Padding(
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
                borderRadius: BorderRadius.circular(ResponsiveUtils.r(context, 16)),
              ),
              elevation: 4,
            ),
            child: Text(
              'Next',
              style: TextStyle(
                fontSize: ResponsiveUtils.sp(context, 18),
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
        ),
      );
    } else if (_currentPage == 2) {
      // Foreground Actions
      return Padding(
        padding: EdgeInsets.all(ResponsiveUtils.w(context, 24)),
        child: Column(
          children: [
            SizedBox(
              width: double.infinity,
              height: ResponsiveUtils.h(context, 56),
              child: ElevatedButton(
                onPressed: _handleForegroundRequest,
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.primaryTeal,
                  foregroundColor: AppColors.white,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(ResponsiveUtils.r(context, 16)),
                  ),
                ),
                child: Text(
                  'Allow Location',
                  style: TextStyle(
                    fontSize: ResponsiveUtils.sp(context, 18),
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
            ),
            ResponsiveUtils.verticalSpace(context, 16),
            TextButton(
              onPressed: _skipToLogin,
              child: Text(
                'Not Now',
                style: TextStyle(color: AppColors.white.withOpacity(0.7), fontSize: ResponsiveUtils.sp(context, 16)),
              ),
            ),
          ],
        ),
      );
    } else {
      // Background Actions
      return Padding(
        padding: EdgeInsets.all(ResponsiveUtils.w(context, 24)),
        child: Column(
          children: [
            SizedBox(
              width: double.infinity,
              height: ResponsiveUtils.h(context, 56),
              child: ElevatedButton(
                onPressed: _handleBackgroundRequest,
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.primaryTeal,
                  foregroundColor: AppColors.white,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(ResponsiveUtils.r(context, 16)),
                  ),
                ),
                child: Text(
                  'Allow Permission',
                  style: TextStyle(
                    fontSize: ResponsiveUtils.sp(context, 18),
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
            ),
            ResponsiveUtils.verticalSpace(context, 16),
            TextButton(
              onPressed: _skipToLogin,
              child: Text(
                'Not Now',
                style: TextStyle(color: AppColors.white.withOpacity(0.7), fontSize: ResponsiveUtils.sp(context, 16)),
              ),
            ),
          ],
        ),
      );
    }
  }

  Widget _buildStandardPage(OnboardingData data) {
    return _buildPageLayout(
      image: data.image,
      title: data.title,
      description: data.description,
    );
  }

  Widget _buildForegroundPage() {
    return _buildPageLayout(
      icon: Icons.location_on,
      title: 'Location Access Required',
      description: 'DuneShine collects location data to route jobs, verify arrivals, and let the dispatch team monitor on-shift partners while you are using the app.',
    );
  }

  Widget _buildBackgroundPage() {
    return _buildPageLayout(
      icon: Icons.location_on_outlined,
      title: 'Always-On Location',
      description: 'DuneShine requires background location to track you while moving to jobs, even when the app is closed or minimized.\n\nTo allow this, you will be taken to Settings. Please select "Allow all the time".',
    );
  }

  Widget _buildPageLayout({String? image, IconData? icon, required String title, required String description}) {
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
                    if (image != null)
                      Container(
                        width: ResponsiveUtils.w(context, 280),
                        height: ResponsiveUtils.w(context, 280),
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
                          child: Image.asset(image, fit: BoxFit.cover),
                        ),
                      )
                    else if (icon != null)
                      Container(
                        width: ResponsiveUtils.w(context, 160),
                        height: ResponsiveUtils.w(context, 160),
                        decoration: BoxDecoration(
                          color: AppColors.primaryTeal.withOpacity(0.1),
                          shape: BoxShape.circle,
                        ),
                        child: Icon(
                          icon,
                          size: ResponsiveUtils.r(context, 80),
                          color: AppColors.primaryTeal,
                        ),
                      ),
                    ResponsiveUtils.verticalSpace(context, 48),
                    Text(
                      title,
                      style: TextStyle(
                        fontSize: ResponsiveUtils.sp(context, 28),
                        fontWeight: FontWeight.bold,
                        color: AppColors.white,
                      ),
                      textAlign: TextAlign.center,
                    ),
                    ResponsiveUtils.verticalSpace(context, 16),
                    Text(
                      description,
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
