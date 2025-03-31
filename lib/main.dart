import 'package:flutter/material.dart';
import 'package:animated_splash_screen/animated_splash_screen.dart';
import 'package:page_transition/page_transition.dart';
import 'dart:io' show Platform;
import 'components/custom_bottom_nav_bar.dart';
import 'components/custom_app_bar.dart'; // Ensure you have this file
import 'screens/home_screen.dart';
import 'screens/about_screen.dart';
import 'screens/calendar_screen.dart';
import 'screens/maps_screen.dart';
import 'screens/services_screen.dart';
import 'screens/settings_screen.dart';

void main() {
  runApp(MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    final splashTransition = Platform.isAndroid || Platform.isIOS
        ? SplashTransition.fadeTransition
        : SplashTransition.rotationTransition;

    return MaterialApp(
      debugShowCheckedModeBanner: false,
      title: 'Flutter App',
      theme: ThemeData(primarySwatch: Colors.green),
      home: AnimatedSplashScreen(
        splash: Image.asset(
          'assets/logo.png',
          width: 200,
          height: 200,
        ),
        nextScreen: MainScreen(),
        splashTransition: splashTransition,
        pageTransitionType: PageTransitionType.fade,
        duration: 3000,
        backgroundColor: Colors.white,
        splashIconSize: 250,
      ),
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

  final List<Widget> _screens = [
    HomeScreen(),
    CalendarScreen(),
    ServicesScreen(),
    MapScreen(),
    AboutScreen(),
    SettingsScreen(),
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
  }

  void _onPageChanged(int index) {
    setState(() {
      _currentIndex = index;
    });
  }

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      child: Scaffold(
        appBar: const CustomAppBar(),
        body: PageView(
          controller: _pageController,
          onPageChanged: _onPageChanged,
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
