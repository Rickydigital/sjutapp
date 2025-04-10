import 'dart:convert'; // Added for jsonDecode
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http; // Added for http
//import 'package:shared_preferences/shared_preferences.dart'; // Added for SharedPreferences
import 'package:sjut/services/api_service.dart';
import 'package:sjut/models/student.dart'; // Added for Student (adjust path as needed)

class EditProfileScreen extends StatefulWidget {
  const EditProfileScreen({super.key});

  @override
  EditProfileScreenState createState() => EditProfileScreenState();
}

class EditProfileScreenState extends State<EditProfileScreen> {
  final _nameController = TextEditingController();
  final _regNoController = TextEditingController();
  final _emailController = TextEditingController();
  String? _selectedGender;
  String? _selectedYear;
  String? _error;
  bool _isLoading = false;

  final List<String> _genderOptions = ['male', 'female', 'other'];
  final List<String> _yearOptions = ['1', '2', '3', '4'];

  @override
  void initState() {
    super.initState();
    _loadProfile();
  }

  Future<void> _loadProfile() async {
    try {
      // final prefs = await SharedPreferences.getInstance(); // Removed unused variable
      final response = await http.get(
        Uri.parse('${ApiService.baseUrl}/profile'),
        headers: {'Authorization': 'Bearer ${ApiService.token}'},
      );
      if (response.statusCode == 200) {
        final json = jsonDecode(response.body);
        final student = Student.fromJson(json['data']);
        setState(() {
          _nameController.text = student.name;
          _regNoController.text = student.regNo;
          _emailController.text = student.email;
          _selectedGender = student.gender;
          _selectedYear = student.yearOfStudy.toString();
        });
      } else {
        throw Exception('Failed to load profile: ${response.body}');
      }
    } catch (e) {
      setState(() => _error = 'Error loading profile: $e');
    }
  }

  Future<void> _updateProfile() async {
    if (_selectedYear == null || _selectedGender == null) {
      setState(() => _error = 'Please select year and gender');
      return;
    }
    setState(() => _isLoading = true);
    try {
      await ApiService().editProfile(
        name: _nameController.text,
        regNo: _regNoController.text,
        yearOfStudy: int.parse(_selectedYear!),
        email: _emailController.text,
        gender: _selectedGender!,
      );
      if (!mounted) return;
      ScaffoldMessenger.of(context)
          .showSnackBar(const SnackBar(content: Text('Profile updated')));
      Navigator.pop(context);
    } catch (e) {
      if (mounted) setState(() => _error = e.toString());
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Edit Profile')),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: SingleChildScrollView(
          child: Column(
            children: [
              TextField(
                controller: _nameController,
                decoration: const InputDecoration(
                    labelText: 'Name', border: OutlineInputBorder()),
              ),
              const SizedBox(height: 16),
              TextField(
                controller: _regNoController,
                decoration: const InputDecoration(
                    labelText: 'Registration Number',
                    border: OutlineInputBorder()),
              ),
              const SizedBox(height: 16),
              DropdownButtonFormField<String>(
                value: _selectedYear,
                items: _yearOptions
                    .map((year) => DropdownMenuItem(value: year, child: Text(year)))
                    .toList(),
                onChanged: (value) => setState(() => _selectedYear = value),
                decoration: const InputDecoration(
                    labelText: 'Year of Study', border: OutlineInputBorder()),
              ),
              const SizedBox(height: 16),
              TextField(
                controller: _emailController,
                decoration: const InputDecoration(
                    labelText: 'Email', border: OutlineInputBorder()),
              ),
              const SizedBox(height: 16),
              DropdownButtonFormField<String>(
                value: _selectedGender,
                items: _genderOptions
                    .map((gender) =>
                        DropdownMenuItem(value: gender, child: Text(gender)))
                    .toList(),
                onChanged: (value) => setState(() => _selectedGender = value),
                decoration: const InputDecoration(
                    labelText: 'Gender', border: OutlineInputBorder()),
              ),
              if (_error != null)
                Padding(
                  padding: const EdgeInsets.symmetric(vertical: 8.0),
                  child: Text(_error!, style: const TextStyle(color: Colors.red)),
                ),
              const SizedBox(height: 20),
              _isLoading
                  ? const CircularProgressIndicator()
                  : ElevatedButton(
                      onPressed: _updateProfile,
                      child: const Text('Save'),
                    ),
            ],
          ),
        ),
      ),
    );
  }

  @override
  void dispose() {
    _nameController.dispose();
    _regNoController.dispose();
    _emailController.dispose();
    super.dispose();
  }
}