import 'package:flutter/material.dart';

class CustomAppBar extends StatelessWidget implements PreferredSizeWidget {
  const CustomAppBar({super.key});

  @override
  Widget build(BuildContext context) {
    double width = MediaQuery.of(context).size.width;

    return Container(
      width: width,
      height: 100,
      decoration: BoxDecoration(
        image: DecorationImage(
          image: AssetImage('assets/home.png'),
          fit: BoxFit.cover,
          alignment: Alignment.center,
          colorFilter: ColorFilter.mode(
            // ignore: deprecated_member_use
            Colors.black.withOpacity(0.3), 
            BlendMode.darken,
          ),
        ),
      ),
      child: AnimatedOpacity(
        opacity: 1.0, 
        duration: Duration(seconds: 1),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
        
            Padding(
              padding: const EdgeInsets.all(8.0),
              child: IconButton(
                icon: const Icon(
                  Icons.arrow_back,
                  color: Colors.white,
                  size: 28,
                ),
                onPressed: () {
                 
                  Navigator.of(context).pop();
                },
              ),
            ),

            // Right side: Notifications and Popup menu
            Row(
              children: [
                IconButton(
                  onPressed: () {},
                  icon: const Icon(
                    Icons.notifications,
                    color: Colors.white,
                    size: 28,
                  ),
                ),
                PopupMenuButton<String>(
                  onSelected: (value) {},
                  icon: const Icon(
                    Icons.more_vert,
                    color: Colors.white,
                    size: 28,
                  ),
                  itemBuilder: (context) => [
                    const PopupMenuItem(
                      value: "lang",
                      child: Text("Change Language"),
                    ),
                    const PopupMenuItem(
                      value: "settings",
                      child: Text("Settings"),
                    ),
                    const PopupMenuItem(
                      value: "logout",
                      child: Text("Logout"),
                    ),
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
