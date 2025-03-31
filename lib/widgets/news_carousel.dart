import 'package:flutter/material.dart';

class NewsCarousel extends StatelessWidget {
  final List<Map<String, String>> news = [
    {"title": "Flutter 3.10 Released!", "image": "https://via.placeholder.com/300"},
    {"title": "AI Changing the World", "image": "https://via.placeholder.com/300"},
    {"title": "Elon Musk Announces New Project", "image": "https://via.placeholder.com/300"},
    {"title": "SpaceX Plans Mars Mission", "image": "https://via.placeholder.com/300"},
    {"title": "Tech Giants Invest in AI", "image": "https://via.placeholder.com/300"},
  ];

  NewsCarousel({super.key});

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.all(8.0),
          child: Text("Latest News", style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold)),
        ),
        SizedBox(
          height: 180,
          child: ListView.builder(
            scrollDirection: Axis.horizontal,
            itemCount: news.length,
            itemBuilder: (context, index) {
              return Container(
                width: 300,
                margin: EdgeInsets.symmetric(horizontal: 8),
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(10),
                  image: DecorationImage(
                    image: NetworkImage(news[index]["image"]!),
                    fit: BoxFit.cover,
                  ),
                ),
                child: Align(
                  alignment: Alignment.bottomLeft,
                  child: Padding(
                    padding: const EdgeInsets.all(8.0),
                    child: Text(
                      news[index]["title"]!,
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
