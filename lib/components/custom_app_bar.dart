// lib/components/custom_app_bar.dart
import 'package:flutter/material.dart';
import 'package:sjut/services/api_service.dart';
import 'package:shared_preferences/shared_preferences.dart';

class CustomAppBar extends StatelessWidget implements PreferredSizeWidget {
  const CustomAppBar({super.key});

  Future<void> _logout(BuildContext context) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove('token');
    await prefs.remove('userId');
    await prefs.remove('facultyId');
    await prefs.remove('yearOfStudy');
    ApiService.clearToken();
    if (!context.mounted) return;
    Navigator.pushReplacementNamed(context, '/login');
  }

  @override
  Widget build(BuildContext context) {
    double width = MediaQuery.of(context).size.width;

    return Container(
      width: width,
      height: 100,
      decoration: BoxDecoration(
        image: DecorationImage(
          image: const AssetImage('assets/home.png'),
          fit: BoxFit.cover,
          alignment: Alignment.center,
          colorFilter: ColorFilter.mode(
            Colors.black.withOpacity(0.3),
            BlendMode.darken,
          ),
        ),
      ),
      child: AnimatedOpacity(
        opacity: 1.0,
        duration: const Duration(seconds: 1),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Padding(
              padding: const EdgeInsets.all(8.0),
              child: IconButton(
                icon: const Icon(Icons.arrow_back, color: Colors.white, size: 28),
                onPressed: () {
                  Navigator.of(context).pop();
                },
              ),
            ),
            Row(
              children: [
                IconButton(
                  onPressed: () {},
                  icon: const Icon(Icons.notifications, color: Colors.white, size: 28),
                ),
                PopupMenuButton<String>(
                  onSelected: (value) {
                    switch (value) {
                      case 'login':
                        Navigator.pushNamed(context, '/login');
                        break;
                      case 'logout':
                        _logout(context);
                        break;
                      case 'lang':
                        // Handle language change
                        break;
                      case 'settings':
                        // Handle settings
                        break;
                      case 'timetable':
                        Navigator.pushNamed(context, '/timetable');
                        break;
                      case 'exam_timetable':
                        Navigator.pushNamed(context, '/exam_timetable');
                        break;
                    }
                  },
                  icon: const Icon(Icons.more_vert, color: Colors.white, size: 28),
                  itemBuilder: (context) => [
                    const PopupMenuItem(value: "lang", child: Text("Change Language")),
                    const PopupMenuItem(value: "settings", child: Text("Settings")),
                    if (ApiService.token == null)
                      const PopupMenuItem(value: "login", child: Text("Login"))
                    else ...[
                      const PopupMenuItem(value: "timetable", child: Text("Timetable")),
                      const PopupMenuItem(value: "exam_timetable", child: Text("Examination Timetable")),
                      const PopupMenuItem(value: "logout", child: Text("Logout")),
                    ],
                  ],
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  @override
  Size get preferredSize => const Size.fromHeight(100);
}