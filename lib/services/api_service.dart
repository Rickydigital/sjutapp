import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';
import 'package:sjut/models/news.dart';
import 'package:logger/logger.dart';
import 'package:sjut/models/timetable.dart';
import 'package:sjut/models/examination_timetable.dart';
import 'package:sjut/services/notification_service.dart'; // Added import

class ApiService {
  static const String baseUrl = 'http://192.168.137.1:8000/api';
  static String? token;
  static int? currentUserId;
  static int? facultyId; // Already defined as static field
  static int? yearOfStudy; // Already defined as static field

  var logger = Logger();

  Future<List<Map<String, dynamic>>> fetchFaculties() async {
    final response = await http.get(
      Uri.parse('$baseUrl/faculties'),
      headers: {'Authorization': 'Bearer $token'},
    );
    if (response.statusCode == 200) {
      final json = jsonDecode(response.body);
      return (json['data'] as List)
          .map((faculty) => {
                'id': faculty['id'],
                'name': faculty['name'],
              })
          .cast<Map<String, dynamic>>()
          .toList();
    } else {
      throw Exception(
          'Failed to load faculties: ${response.statusCode} - ${response.body}');
    }
  }

  Future<List<News>> fetchNews() async {
    final response = await http.get(
      Uri.parse('$baseUrl/news'),
      headers: {'Authorization': 'Bearer $token'},
    );
    if (response.statusCode == 200) {
      final json = jsonDecode(response.body);
      return (json['data'] as List).map((item) => News.fromJson(item)).toList();
    } else {
      throw Exception(
          'Failed to load news: ${response.statusCode} - ${response.body}');
    }
  }

  Future<News> fetchNewsDetail(int newsId) async {
    final response = await http.get(
      Uri.parse('$baseUrl/news/$newsId'),
      headers: {'Authorization': 'Bearer $token'},
    );
    if (response.statusCode == 200) {
      return News.fromJson(jsonDecode(response.body)['data']);
    } else {
      throw Exception('Failed to fetch news: ${response.statusCode}');
    }
  }

  Future<void> addComment(int newsId, String comment) async {
    try {
      final response = await http.post(
        Uri.parse('$baseUrl/news/$newsId/comment'),
        headers: {
          'Authorization': 'Bearer $token',
          'Content-Type': 'application/json',
        },
        body: jsonEncode({'comment': comment}),
      );
      if (response.statusCode == 201) {
        logger.i('Comment added successfully');
      } else {
        throw Exception(
            'Failed to add comment: ${response.statusCode} - ${response.body}');
      }
    } catch (e) {
      logger.e('Error adding comment: $e');
      rethrow;
    }
  }

  Future<void> react(int newsId, String type) async {
    final response = await http.post(
      Uri.parse('$baseUrl/news/$newsId/react'),
      headers: {
        'Authorization': 'Bearer $token',
        'Content-Type': 'application/json',
      },
      body: jsonEncode({'type': type}),
    );
    if (response.statusCode != 201 && response.statusCode != 200) {
      throw Exception('Failed to react: ${response.statusCode}');
    }
  }

  Future<void> removeReaction(int newsId, String type) async {
    final response = await http.delete(
      Uri.parse('$baseUrl/news/$newsId/react?type=$type'),
      headers: {'Authorization': 'Bearer $token'},
    );
    if (response.statusCode != 200) {
      throw Exception('Failed to remove reaction: ${response.statusCode}');
    }
  }

    static Future<void> setToken(
      String newToken, int userId, int facultyId, int yearOfStudy) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString('token', newToken);
    await prefs.setInt('userId', userId);
    await prefs.setInt('facultyId', facultyId);
    await prefs.setInt('yearOfStudy', yearOfStudy);
    token = newToken;
    currentUserId = userId;
    ApiService.facultyId = facultyId;
    ApiService.yearOfStudy = yearOfStudy;

    String? fcmToken = await NotificationService.getFCMToken();
    if (fcmToken != null && fcmToken.isNotEmpty) {
      await NotificationService.sendTokenToServer(fcmToken);
    }
  }

  static Future<void> clearToken() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove('token');
    await prefs.remove('userId');
    await prefs.remove('facultyId');
    await prefs.remove('yearOfStudy');
    token = null;
    currentUserId = null;
    ApiService.facultyId = null; // Corrected: Use static reference
    ApiService.yearOfStudy = null; // Corrected: Use static reference
    if (kDebugMode) {
      print('Token cleared');
    }
  }

  Future<void> login(String email, String password) async {
    try {
      final response = await http.post(
        Uri.parse('$baseUrl/login'),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({'email': email, 'password': password}),
      );

      final json = jsonDecode(response.body);
      logger.i('💡 Full Login Response: $json');

      if (response.statusCode == 200 && json['success'] == true) {
        String token = json['data']['token'];
        int userId = json['data']['student']['id'];
        int facultyId = json['data']['student']['faculty_id'];
        int yearOfStudy = json['data']['student']['year_of_study'];
        await setToken(token, userId, facultyId, yearOfStudy);
        logger.i('✅ Login successful - Token: $token, User ID: $userId');
      } else {
        throw Exception('Login failed: ${json['message'] ?? 'Unknown error'}');
      }
    } catch (e) {
      logger.e('❌ Login Error: $e');
      throw Exception('An error occurred during login: $e');
    }
  }

  Future<void> register({
    required String name,
    required String regNo,
    required int yearOfStudy,
    required int facultyId,
    required String email,
    required String password,
    required String gender,
    String? confirmPassword, // Added for password confirmation
  }) async {
    try {
      final response = await http.post(
        Uri.parse('$baseUrl/register'),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({
          'name': name,
          'reg_no': regNo,
          'year_of_study': yearOfStudy,
          'faculty_id': facultyId,
          'email': email,
          'password': password,
          'password_confirmation': confirmPassword,
          'gender': gender,
        }),
      );

      if (response.statusCode == 201) {
        final json = jsonDecode(response.body);
        String token = json['data']['token'];
        int userId = json['data']['student']['id'];
        await setToken(token, userId, facultyId, yearOfStudy);
        logger.i('Registration successful');
      } else {
        throw Exception('Registration failed: ${response.body}');
      }
    } catch (e) {
      logger.e('Registration error: $e');
      rethrow;
    }
  }

  Future<void> logout() async {
    try {
      final response = await http.post(
        Uri.parse('$baseUrl/logout'),
        headers: {'Authorization': 'Bearer $token'},
      );
      if (response.statusCode == 200) {
        await clearToken();
        logger.i('Logout successful');
      } else {
        throw Exception('Logout failed: ${response.statusCode}');
      }
    } catch (e) {
      logger.e('Logout error: $e');
      rethrow;
    }
  }

    Future<void> editProfile({
    required String name,
    required String regNo,
    required int yearOfStudy,
    required String email,
    required String gender,
  }) async {
    try {
      final response = await http.put(
        Uri.parse('$baseUrl/profile'),
        headers: {
          'Authorization': 'Bearer $token',
          'Content-Type': 'application/json',
        },
        body: jsonEncode({
          'name': name,
          'reg_no': regNo,
          'year_of_study': yearOfStudy,
          'email': email,
          'gender': gender,
        }),
      );
      if (response.statusCode == 200) {
        logger.i('Profile updated successfully');
        final prefs = await SharedPreferences.getInstance();
        await prefs.setInt('yearOfStudy', yearOfStudy);
        ApiService.yearOfStudy = yearOfStudy;
        String? fcmToken = await NotificationService.getFCMToken();
        if (fcmToken != null && fcmToken.isNotEmpty) {
          await NotificationService.sendTokenToServer(fcmToken);
        }
      } else {
        throw Exception('Failed to update profile: ${response.body}');
      }
    } catch (e) {
      logger.e('Edit profile error: $e');
      rethrow;
    }
  }

     Future<void> changePassword({
      required String currentPassword,
      required String newPassword,
      required String confirmPassword,
    }) async {
      if (newPassword != confirmPassword) {
        throw Exception('Passwords do not match');
      }
      try {
        final response = await http.post(
          Uri.parse('$baseUrl/change-password'),
          headers: {
            'Authorization': 'Bearer $token',
            'Content-Type': 'application/json',
          },
          body: jsonEncode({
            'current_password': currentPassword,
            'new_password': newPassword,
            'new_password_confirmation': confirmPassword,
          }),
        );
        if (response.statusCode == 200) {
          logger.i('Password changed successfully');
          String? fcmToken = await NotificationService.getFCMToken();
          if (fcmToken != null && fcmToken.isNotEmpty) {
            await NotificationService.sendTokenToServer(fcmToken);
          }
        } else {
          throw Exception('Failed to change password: ${response.body}');
        }
      } catch (e) {
        logger.e('Change password error: $e');
        rethrow;
      }
    }

    Future<void> forgotPassword(String email) async {
    try {
      final response = await http.post(
        Uri.parse('$baseUrl/forgot-password'),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({'email': email}),
      );
      if (response.statusCode == 200) {
        logger.i('Password reset email sent');
      } else {
        throw Exception('Failed to send reset email: ${response.body}');
      }
    } catch (e) {
      logger.e('Forgot password error: $e');
      rethrow;
    }
  }
  Future<List<Timetable>> fetchLectureTimetables() async {
    final prefs = await SharedPreferences.getInstance();
    final facultyId = prefs.getInt('facultyId') ?? 1;
    final yearOfStudy = prefs.getInt('yearOfStudy') ?? 1;

    final response = await http.get(
      Uri.parse('$baseUrl/timetables/lecture?faculty_id=$facultyId&year_id=$yearOfStudy'),
      headers: {'Authorization': 'Bearer $token'},
    );
    if (response.statusCode == 200) {
      final json = jsonDecode(response.body);
      return (json['data'] as List).map((item) => Timetable.fromJson(item)).toList();
    } else {
      throw Exception('Failed to load lecture timetables');
    }
  }

  Future<List<ExaminationTimetable>> fetchExaminationTimetables() async {
    final prefs = await SharedPreferences.getInstance();
    final facultyId = prefs.getInt('facultyId') ?? 1;
    final yearOfStudy = prefs.getInt('yearOfStudy') ?? 1;

    final response = await http.get(
      Uri.parse('$baseUrl/timetables/examination?faculty_id=$facultyId&year_id=$yearOfStudy'),
      headers: {'Authorization': 'Bearer $token'},
    );
    if (response.statusCode == 200) {
      final json = jsonDecode(response.body);
      return (json['data'] as List)
          .map((item) => ExaminationTimetable.fromJson(item))
          .toList();
    } else {
      throw Exception('Failed to load examination timetables');
    }
  }

  void toggleReaction(int newsId, String type) {}

  Future<List<Map<String, dynamic>>> fetchVenues() async {
    final response = await http.get(
      Uri.parse('$baseUrl/venues'),
      headers: {'Authorization': 'Bearer $token'},
    );
    if (response.statusCode == 200) {
      final List<dynamic> json = jsonDecode(response.body);
      return json
          .map((venue) => {
                'id': venue['id'],
                'name': venue['name'],
                'lat': double.parse(venue['lat'].toString()),
                'lng': double.parse(venue['lng'].toString()),
              })
          .toList();
    } else {
      throw Exception(
          'Failed to load venues: ${response.statusCode} - ${response.body}');
    }
  }

  Future<void> saveTimetables(String key, List<dynamic> timetables) async {
    final prefs = await SharedPreferences.getInstance();
    final jsonString = jsonEncode(timetables.map((t) => t.toJson()).toList());
    await prefs.setString(key, jsonString);
  }

  Future<List<T>> loadTimetables<T>(
      String key, T Function(Map<String, dynamic>) fromJson) async {
    final prefs = await SharedPreferences.getInstance();
    final jsonString = prefs.getString(key);
    if (jsonString != null) {
      final List<dynamic> jsonList = jsonDecode(jsonString);
      return jsonList.map((json) => fromJson(json)).toList();
    }
    return [];
  }

  Future<void> enrichTimetablesWithVenueNames(List<dynamic> timetables) async {
    try {
      final venues = await fetchVenues();
      for (var timetable in timetables) {
        final venue = venues.firstWhere(
          (v) => v['id'] == timetable.venueId,
          orElse: () => {'name': 'Unknown Venue'},
        );
        timetable.venueName = venue['name'];
      }
    } catch (e) {
      for (var timetable in timetables) {
        timetable.venueName = 'Unknown Venue'; // Fallback
      }
    }
  }
}