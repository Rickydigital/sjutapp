import 'package:convex_bottom_bar/convex_bottom_bar.dart';
import 'package:flutter/material.dart';

class CustomBottomNavBar extends StatelessWidget {
  final int currentIndex;
  final Function(int) onTap;

  const CustomBottomNavBar({
    super.key,
    required this.currentIndex,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return ConvexAppBar(
      key: ValueKey(currentIndex),
      backgroundColor: const Color(0xFF582B86),
      style: TabStyle.reactCircle,
      items: const [
        TabItem(icon: Icons.home, title: "Home"),
        TabItem(icon: Icons.calendar_today, title: "Calendar"),
        TabItem(icon: Icons.miscellaneous_services, title: "Services"),
        TabItem(icon: Icons.map, title: "Map"),
        TabItem(icon: Icons.info, title: "News"),
        TabItem(icon: Icons.settings, title: "Settings"),
      ],
      initialActiveIndex: currentIndex,
      onTap: onTap, 
    );
  }
}
