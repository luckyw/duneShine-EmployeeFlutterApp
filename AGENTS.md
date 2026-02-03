# AGENTS.md - Flutter Employee Application

## Project Overview
A Flutter mobile application for employee job management with Firebase integration, Google Maps, and secure storage.

## Build/Lint/Test Commands

### Analysis & Linting
```bash
flutter analyze                    # Analyze code for issues
flutter analyze --fix              # Fix auto-fixable issues
```

### Testing
```bash
flutter test                       # Run all tests
flutter test test/widget_test.dart # Run a single test file
flutter test --coverage            # Run tests with coverage
flutter test --name="test name"    # Run specific test by name
```

### Build Commands
```bash
flutter build apk                  # Build APK (Android)
flutter build appbundle            # Build app bundle (Android Play Store)
flutter build ios                  # Build iOS
flutter build apk --release        # Build with release mode
```

### Development
```bash
flutter pub get                    # Get dependencies
flutter pub upgrade                # Upgrade dependencies
flutter run                        # Run app
flutter run -d <device_id>         # Run on specific device
r                                  # Hot reload (while running)
flutter pub run flutter_launcher_icons:main  # Generate app icons
```

## Code Style Guidelines

### Imports Ordering
1. Dart SDK imports (`dart:*`)
2. Flutter SDK imports (`package:flutter/*`)
3. Third-party packages (`package:http/*`, etc.)
4. Local imports (relative paths `../constants/*`)

```dart
import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import '../constants/api_constants.dart';
```

### Naming Conventions
- **Files**: `snake_case.dart` (e.g., `job_model.dart`)
- **Classes**: `PascalCase` (e.g., `JobModel`)
- **Variables**: `camelCase` (e.g., `jobId`)
- **Constants**: `camelCase` or `kCamelCase`
- **Private members**: `_camelCase`
- **Screens**: Suffix with `_screen.dart`
- **Services**: Suffix with `_service.dart`

### Type Safety
- Always specify return types
- Use `const` constructors where possible
- Prefer `final` over `var`
- Use `required` for named parameters
- Use generic types: `List<Job>`, `Map<String, dynamic>`

```dart
// Good
final List<Job> jobs = [];
Future<Map<String, dynamic>> fetchData() async { ... }

// Avoid
var jobs = [];
fetchData() async { ... }
```

### Widget Structure
- Use `const` for stateless widgets
- Use `super.key` in constructors
- Extract large widget trees into private methods

```dart
class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});
  @override
  State<LoginScreen> createState() => _LoginScreenState();
}
```

### Error Handling
- Wrap API calls in try-catch
- Return standardized response with `success` boolean
- Use `debugPrint()` for logging, avoid `print()`

```dart
Future<Map<String, dynamic>> fetchData() async {
  try {
    final response = await http.get(...);
    if (response.statusCode == 200) {
      return {'success': true, 'data': responseData};
    } else {
      return {'success': false, 'message': 'Error'};
    }
  } catch (e) {
    debugPrint('Fetch error: $e');
    return {'success': false, 'message': 'Network error'};
  }
}
```

### Model Classes
- Include `fromJson` factory constructor
- Provide `copyWith` method
- Use nullable types for optional fields
- Add helper getters

```dart
class Job {
  final int id;
  final String status;
  Job({required this.id, required this.status});
  factory Job.fromJson(Map<String, dynamic> json) {
    return Job(id: json['id'] ?? 0, status: json['status'] ?? 'unknown');
  }
  Job copyWith({int? id, String? status}) {
    return Job(id: id ?? this.id, status: status ?? this.status);
  }
}
```

### String Quotes & Formatting
- Prefer single quotes for strings
- Line length: 80 characters
- Use trailing commas for multi-line params
- Indent with 2 spaces

```dart
// Good
final job = Job(
  id: 1,
  status: 'assigned',
);
```

### Comments
- Use `///` for public API documentation
- Use `//` for inline comments

## Project Structure
```
lib/
├── constants/    # App constants (colors, styles, API)
├── models/       # Data models
├── screens/      # UI screens
├── services/     # Business logic
├── utils/        # Utilities
└── main.dart     # App entry point
```

## Dependencies
- `flutter_lints` - Dart/Flutter linting
- `http` - HTTP requests
- `firebase_core`, `cloud_firestore` - Firebase
- `google_maps_flutter` - Maps
- `flutter_secure_storage` - Secure storage
- `geolocator` - Location services
- `image_picker` - Photo capture

## Configuration
- Analysis: `analysis_options.yaml` (uses `package:flutter_lints`)
- Icons: Configured in `pubspec.yaml`
- Assets: `assets/images/`, `assets/fonts/`
- Minimum SDK: Android 21

## Testing Guidelines
- Place tests in `test/` directory
- Name files `*_test.dart`
- Use `testWidgets` for widget tests
- Use `test` for unit tests
- Mirror source file structure

```dart
void main() {
  testWidgets('Widget test', (WidgetTester tester) async {
    await tester.pumpWidget(const MyWidget());
    expect(find.text('Expected'), findsOneWidget);
  });
}
```
