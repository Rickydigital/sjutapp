import 'package:flutter/material.dart';
import 'package:sjut/services/api_service.dart';

class SettingsScreen extends StatefulWidget {
  const SettingsScreen({super.key});

  @override
  SettingsScreenState createState() => SettingsScreenState(); // Changed _SettingsScreenState to SettingsScreenState
}

class SettingsScreenState extends State<SettingsScreen> { // Changed _SettingsScreenState to SettingsScreenState
  Future<void> _logout() async {
    try {
      await ApiService().logout();
      if (!mounted) return;
      Navigator.pushReplacementNamed(context, '/login');
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Logout failed: $e')),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: ListView(
        children: [
          ListTile(
            title: const Text('Edit Profile'),
            onTap: () => Navigator.pushNamed(context, '/edit-profile'),
          ),
          ListTile(
            title: const Text('Change Password'),
            onTap: () => Navigator.pushNamed(context, '/change-password'),
          ),
          ListTile(
            title: const Text('Logout'),
            onTap: _logout,
          ),
        ],
      ),
    );
  }
}