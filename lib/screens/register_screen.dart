import 'package:flutter/material.dart';
import 'package:sjut/services/api_service.dart';

class RegisterScreen extends StatefulWidget {
  const RegisterScreen({super.key});

  @override
  RegisterScreenState createState() => RegisterScreenState();
}

class RegisterScreenState extends State<RegisterScreen> {
  final _nameController = TextEditingController();
  final _regNoController = TextEditingController();
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  String? _error;
  bool _isLoading = false;

  final List<String> _genderOptions = ['male', 'female'];
  final List<String> _yearOptions = ['1', '2', '3', '4'];
  List<Map<String, dynamic>> _faculties = [];

  String? _selectedGender;
  String? _selectedYear;
  int? _selectedFacultyId;

  @override
  void initState() {
    super.initState();
    _fetchFaculties();
  }

  Future<void> _fetchFaculties() async {
    try {
      final faculties = await ApiService().fetchFaculties();
      setState(() {
        _faculties = faculties;
      });
    } catch (e) {
      setState(() {
        _error = 'Failed to load faculties: $e';
      });
    }
  }

  Future<void> _register() async {
    if (_nameController.text.isEmpty ||
        _regNoController.text.isEmpty ||
        _emailController.text.isEmpty ||
        _passwordController.text.isEmpty ||
        _selectedYear == null ||
        _selectedFacultyId == null ||
        _selectedGender == null) {
      setState(() => _error = 'Please fill in all fields');
      return;
    }

    setState(() => _isLoading = true);
    try {
      await ApiService().register(
        name: _nameController.text,
        regNo: _regNoController.text,
        yearOfStudy: int.parse(_selectedYear!),
        facultyId: _selectedFacultyId!,
        email: _emailController.text,
        password: _passwordController.text,
        gender: _selectedGender!,
      );
      if (!mounted) return;
      Navigator.pushReplacementNamed(context, '/main');
    } catch (e) {
      if (mounted) setState(() => _error = e.toString());
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Register')),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: SingleChildScrollView(
          child: Column(
            children: [
              TextField(
                controller: _nameController,
                decoration: const InputDecoration(
                  labelText: 'Name',
                  border: OutlineInputBorder(),
                ),
              ),
              const SizedBox(height: 16),
              TextField(
                controller: _regNoController,
                decoration: const InputDecoration(
                  labelText: 'Registration Number',
                  border: OutlineInputBorder(),
                ),
              ),
              const SizedBox(height: 16),
              TextField(
                controller: _emailController,
                decoration: const InputDecoration(
                  labelText: 'Email',
                  border: OutlineInputBorder(),
                ),
              ),
              const SizedBox(height: 16),
              TextField(
                controller: _passwordController,
                decoration: const InputDecoration(
                  labelText: 'Password',
                  border: OutlineInputBorder(),
                ),
                obscureText: true,
              ),
              const SizedBox(height: 16),
              DropdownButtonFormField<String>(
                value: _selectedYear,
                items: _yearOptions
                    .map((year) => DropdownMenuItem(
                          value: year,
                          child: Text('Year $year'),
                        ))
                    .toList(),
                onChanged: (value) => setState(() => _selectedYear = value),
                decoration: const InputDecoration(
                  labelText: 'Year of Study',
                  border: OutlineInputBorder(),
                ),
              ),
              const SizedBox(height: 16),
                 DropdownButtonFormField<int>(
                  value: _selectedFacultyId,
                  items: _faculties
                      .map((faculty) => DropdownMenuItem<int>(
                            value: faculty['id'] as int, // Explicitly cast to int
                            child: Text(faculty['name']),
                          ))
                      .toList(),
                  onChanged: (value) => setState(() => _selectedFacultyId = value),
                  decoration: const InputDecoration(
                    labelText: 'Faculty',
                    border: OutlineInputBorder(),
                  ),
                ),
              const SizedBox(height: 16),
              DropdownButtonFormField<String>(
                value: _selectedGender,
                items: _genderOptions
                    .map((gender) => DropdownMenuItem(
                          value: gender,
                          child: Text(gender),
                        ))
                    .toList(),
                onChanged: (value) => setState(() => _selectedGender = value),
                decoration: const InputDecoration(
                  labelText: 'Gender',
                  border: OutlineInputBorder(),
                ),
              ),
              if (_error != null)
                Padding(
                  padding: const EdgeInsets.symmetric(vertical: 8.0),
                  child: Text(
                    _error!,
                    style: const TextStyle(color: Colors.red),
                  ),
                ),
              const SizedBox(height: 20),
              _isLoading
                  ? const CircularProgressIndicator()
                  : ElevatedButton(
                      onPressed: _register,
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.green,
                        padding: const EdgeInsets.symmetric(
                            horizontal: 32, vertical: 12),
                      ),
                      child: const Text(
                        'Register',
                        style: TextStyle(color: Colors.white),
                      ),
                    ),
              TextButton(
                onPressed: () => Navigator.pushNamed(context, '/login'),
                child: const Text('Already have an account? Login'),
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
    _passwordController.dispose();
    super.dispose();
  }
}