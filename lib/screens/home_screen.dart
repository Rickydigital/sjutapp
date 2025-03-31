import 'package:flutter/material.dart';
import '../widgets/event_carousel.dart';
import '../widgets/news_carousel.dart';

class HomeScreen extends StatelessWidget {
  const HomeScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: double.infinity,
            child: Image.asset("assets/logo.png", fit: BoxFit.cover),
          ),
          EventCarousel(),
          NewsCarousel(),
        ],
      ),
    );
  }
}
