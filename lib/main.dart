import 'package:flutter/material.dart';

import 'constants/colors.dart';
import 'screens/MPINfillinfScreen.dart';
import 'screens/accountScreen.dart';
import 'screens/availabilityScreen.dart';
import 'screens/employee_home_screen.dart';
import 'screens/jobCOmpleteOTPScreen.dart';
import 'screens/jobCOmpletionProofPhto.dart';
import 'screens/jobCompletedScreen.dart';
import 'screens/job_details_screen.dart';
import 'screens/navigate_to_job_screen.dart';
import 'screens/screenToFillUserPin.dart';
import 'screens/washProgressShowingScreen.dart';

void main() {
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
      ),
      initialRoute: '/employee-home',
      routes: {
        '/employee-home': (context) => const EmployeeHomeScreen(),
        '/availability': (context) => const AvailabilityCalendarScreen(),
        '/employee-account': (context) => const EmployeeAccountScreen(),
        '/account': (context) => const EmployeeAccountScreen(),
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
