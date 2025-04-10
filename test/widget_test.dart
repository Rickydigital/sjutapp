import 'package:animated_splash_screen/animated_splash_screen.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:sjut/main.dart';
import 'package:sjut/screens/login_screen.dart';

void main() {
  testWidgets('Splash screen transitions to LoginScreen', (WidgetTester tester) async {
    // Build the app with LoginScreen as initialScreen
    await tester.pumpWidget(const MyApp(initialScreen: LoginScreen()));

    // Verify splash screen is displayed initially
    expect(find.byType(AnimatedSplashScreen), findsOneWidget);
    expect(find.byType(Image), findsOneWidget); // Check for logo

    // Wait for the splash duration (3000ms) and trigger a frame
    await tester.pump(const Duration(milliseconds: 3000));
    await tester.pumpAndSettle(); // Wait for animations to complete

    // Verify it transitions to LoginScreen
    expect(find.byType(LoginScreen), findsOneWidget);
    expect(find.text('Login'), findsOneWidget); // Check app bar title
  });
}