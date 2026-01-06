import 'package:flutter/material.dart';
import 'package:firebase_core/firebase_core.dart';

import 'constants/colors.dart';
import 'screens/MPINfillinfScreen.dart';
import 'screens/employee_home_screen.dart';
import 'screens/jobCOmpleteOTPScreen.dart';
import 'screens/jobCOmpletionProofPhto.dart';
import 'screens/jobCompletedScreen.dart';
import 'screens/job_details_screen.dart';
import 'screens/login_screen.dart';
import 'screens/navigate_to_job_screen.dart';
import 'screens/onboarding_screen.dart';
import 'screens/otp_verification_screen.dart';
import 'screens/screenToFillUserPin.dart';
import 'screens/splash_screen.dart';
import 'screens/washProgressShowingScreen.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Firebase.initializeApp();
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Employee App',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(seedColor: AppColors.primaryTeal),
        scaffoldBackgroundColor: AppColors.white,
        useMaterial3: true,
        fontFamily: 'Manrope',
      ),
      initialRoute: '/splash',
      routes: {
        '/splash': (context) => const SplashScreen(),
        '/onboarding': (context) => const OnboardingScreen(),
        '/login': (context) => const LoginScreen(),
        '/otp-verification': (context) => const OtpVerificationScreen(),
        '/employee-home': (context) => const EmployeeHomeScreen(),
        '/job-details': (context) => const JobDetailsScreen(),
        '/navigate-to-job': (context) => const NavigateToJobScreen(),
        '/job-verification': (context) => const JobVerificationScreen(),
        '/wash-progress': (context) => const WashProgressScreen(),
        '/job-completion-proof': (context) => const JobCompletionProofScreen(),
        '/job-completion-otp': (context) => const JobCompletionOtpScreen(),
      },
      onGenerateRoute: (settings) {
        if (settings.name == '/job-arrival-photo') {
          final args = settings.arguments as Map<String, dynamic>? ?? {};
          return MaterialPageRoute(
            builder: (_) => JobArrivalPhotoScreen(
              jobId: args['jobId'] ?? 'JOB-001',
              carModel: args['carModel'] ?? 'Toyota Camry',
              carColor: args['carColor'] ?? 'White',
            ),
          );
        }

        if (settings.name == '/job-completed') {
          final args = settings.arguments as Map<String, dynamic>? ?? {};
          return MaterialPageRoute(
            builder: (_) => JobCompletedScreen(
              employeeName: args['employeeName'] ?? 'Ahmed',
              earnedAmount:
                  (args['earnedAmount'] ?? 150.0).toDouble(),
              jobId: args['jobId'] ?? 'JOB-001',
            ),
          );
        }

        return null;
      },
    );
  }
}
