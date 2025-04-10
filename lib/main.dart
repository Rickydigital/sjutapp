import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/material.dart';
import 'package:animated_splash_screen/animated_splash_screen.dart';
import 'package:page_transition/page_transition.dart';
import 'dart:io' show Platform;
import 'package:shared_preferences/shared_preferences.dart';
import 'package:sjut/screens/change_password.dart';
import 'package:sjut/screens/edit_profile.dart';
import 'package:sjut/screens/forgot_password.dart';
import 'package:sjut/screens/news_list_screen.dart';
import 'package:sjut/components/custom_bottom_nav_bar.dart';
import 'package:sjut/components/custom_app_bar.dart';
import 'package:sjut/screens/home_screen.dart';
import 'package:sjut/screens/calendar_screen.dart';
import 'package:sjut/screens/maps_screen.dart';
import 'package:sjut/screens/services_screen.dart';
import 'package:sjut/screens/settings_screen.dart';
import 'package:sjut/screens/login_screen.dart';
import 'package:sjut/screens/register_screen.dart';
import 'package:sjut/services/api_service.dart';
import 'package:sjut/screens/timetable_screen.dart';
import 'package:sjut/screens/exam_timetable_screen.dart';
import 'package:sjut/services/notification_service.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:logger/logger.dart';

void main() async {
  final Logger logger = Logger();
  WidgetsFlutterBinding.ensureInitialized();
  await Firebase.initializeApp();
  await NotificationService.init();
  await NotificationService.refreshToken(); // Handle token refreshes
  await _requestNotificationPermission(logger);
  final prefs = await SharedPreferences.getInstance();
  final token = prefs.getString('token');
  final userId = prefs.getInt('userId');
  final facultyId = prefs.getInt('facultyId');
  final yearOfStudy = prefs.getInt('yearOfStudy');
  if (token != null && userId != null && facultyId != null && yearOfStudy != null) {
    ApiService.setToken(token, userId, facultyId, yearOfStudy);
  }
  runApp(MyApp(initialScreen: token != null ? const MainScreen() : const LoginScreen()));
}

Future<void> _requestNotificationPermission(Logger logger) async {
  if (Platform.isAndroid) {
    final status = await Permission.notification.request();
    if (status.isDenied) {
      logger.w('Notification permission denied');
    } else if (status.isPermanentlyDenied) {
      logger.e('Notification permission permanently denied');
      await openAppSettings();
    }
  }
}

class MyApp extends StatelessWidget {
  final Widget initialScreen;

  const MyApp({required this.initialScreen, super.key});

  @override
  Widget build(BuildContext context) {
    final splashTransition = Platform.isAndroid || Platform.isIOS
        ? SplashTransition.fadeTransition
        : SplashTransition.rotationTransition;

    return MaterialApp(
      debugShowCheckedModeBanner: false,
      title: 'SJUT',
      theme: ThemeData(primarySwatch: Colors.green),
      home: AnimatedSplashScreen(
        splash: Image.asset('assets/logo.png', width: 200, height: 200),
        nextScreen: initialScreen,
        splashTransition: splashTransition,
        pageTransitionType: PageTransitionType.fade,
        duration: 3000,
        backgroundColor: Colors.white,
        splashIconSize: 250,
      ),
      routes: {
        '/login': (context) => const LoginScreen(),
        '/register': (context) => const RegisterScreen(),
        '/main': (context) => const MainScreen(),
        '/timetable': (context) => const TimetableScreen(),
        '/exam_timetable': (context) => const ExamTimetableScreen(),
        '/edit-profile': (context) => const EditProfileScreen(),
        '/change-password': (context) => const ChangePasswordScreen(),
        '/forgot-password': (context) => const ForgotPasswordScreen(),
      },
    );
  }
}

class MainScreen extends StatefulWidget {
  const MainScreen({super.key});

  @override
  MainScreenState createState() => MainScreenState();
}

class MainScreenState extends State<MainScreen> {
  int _currentIndex = 0;
  late PageController _pageController;
  final Logger _logger = Logger();  // Initialize the logger for this screen

  final List<Widget> _screens = [
    const HomeScreen(),
    const CalendarScreen(),
    ServicesScreen(),
    const MapScreen(),
    const NewsScreen(),
    const SettingsScreen(),
  ];

  @override
  void initState() {
    super.initState();
    _pageController = PageController(initialPage: _currentIndex);
  }

  @override
  void dispose() {
    _pageController.dispose();
    super.dispose();
  }

  void _onTabTapped(int index) {
    _pageController.animateToPage(
      index,
      duration: const Duration(milliseconds: 300),
      curve: Curves.easeInOut,
    );
    _logger.i('Tab tapped: $index');  // Log the tab change
  }

  void _onPageChanged(int index) {
    setState(() {
      _currentIndex = index;
    });
    _logger.i('Page changed to index: $index');  // Log the page change
  }

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      child: Scaffold(
        appBar: const CustomAppBar(),
        body: PageView(
          controller: _pageController,
          onPageChanged: _onPageChanged,
          physics: const NeverScrollableScrollPhysics(), // Disable swipe navigation
          children: _screens,
        ),
        bottomNavigationBar: CustomBottomNavBar(
          currentIndex: _currentIndex,
          onTap: _onTabTapped,
        ),
      ),
    );
  }
}
