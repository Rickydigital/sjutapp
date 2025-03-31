import 'package:flutter/material.dart';


class ServicesScreen extends StatelessWidget {
  final List<Map<String, dynamic>> services = [
    {"title": "Campuses", "icon": Icons.location_city},
    {"title": "Courses", "icon": Icons.book},
    {"title": "Library", "icon": Icons.library_books},
    {"title": "SIMS", "icon": Icons.person},
    {"title": "ELMS", "icon": Icons.computer},
    {"title": "Alumni", "icon": Icons.people},
    {"title": "Hostels", "icon": Icons.hotel},
    {"title": "Venues", "icon": Icons.event},
    {"title": "Gallery", "icon": Icons.photo},
  ];

  ServicesScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Center( // Centers the grid
        child: Padding(
          padding: const EdgeInsets.all(16.0),
          child: GridView.builder(
            shrinkWrap: true, // Keeps the grid at the center
            gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
              crossAxisCount: 3, // 3 columns
              crossAxisSpacing: 15,
              mainAxisSpacing: 15,
            ),
            itemCount: services.length,
            itemBuilder: (context, index) {
              return GestureDetector(
                onTap: () {
                  // Action when icon is clicked
                },
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    CircleAvatar(
                      radius: 30,
                      backgroundColor: Colors.purple[200],
                      child: Icon(
                        services[index]["icon"],
                        size: 30,
                        color: Colors.white,
                      ),
                    ),
                    SizedBox(height: 8),
                    Text(
                      services[index]["title"],
                      textAlign: TextAlign.center,
                      style: TextStyle(fontSize: 14, fontWeight: FontWeight.w600),
                    ),
                  ],
                ),
              );
            },
          ),
        ),
      );
  }
}
