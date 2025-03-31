import 'package:flutter/material.dart';

class EventCarousel extends StatelessWidget {
  final List<Map<String, String>> events = [
    {"title": "Tech Conference 2025", "image": "https://via.placeholder.com/300"},
    {"title": "Startup Meetup", "image": "https://via.placeholder.com/300"},
    {"title": "Flutter Workshop", "image": "https://via.placeholder.com/300"},
    {"title": "AI Summit", "image": "https://via.placeholder.com/300"},
    {"title": "Hackathon 2025", "image": "https://via.placeholder.com/300"},
  ];

 EventCarousel({super.key});

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.all(8.0),
          child: Text("Upcoming Events", style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold)),
        ),
        SizedBox(
          height: 180,
          child: ListView.builder(
            scrollDirection: Axis.horizontal,
            itemCount: events.length,
            itemBuilder: (context, index) {
              return Container(
                width: 300,
                margin: EdgeInsets.symmetric(horizontal: 8),
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(10),
                  image: DecorationImage(
                    image: NetworkImage(events[index]["image"]!),
                    fit: BoxFit.cover,
                  ),
                ),
                child: Align(
                  alignment: Alignment.bottomLeft,
                  child: Padding(
                    padding: const EdgeInsets.all(8.0),
                    child: Text(
                      events[index]["title"]!,
                      style: TextStyle(color: Colors.white, fontSize: 16, fontWeight: FontWeight.bold, backgroundColor: Colors.black54),
                    ),
                  ),
                ),
              );
            },
          ),
        ),
      ],
    );
  }
}
