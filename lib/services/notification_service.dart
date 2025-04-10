import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:logger/logger.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';

class NotificationService {
  static final FirebaseMessaging _firebaseMessaging = FirebaseMessaging.instance;
  static final Logger _logger = Logger();

  static Future<void> init() async {
    // Request permission
    NotificationSettings settings = await _firebaseMessaging.requestPermission(
      alert: true,
      badge: true,
      sound: true,
    );
    _logger.i('User granted permission: ${settings.authorizationStatus}');

    // Handle background messages
    FirebaseMessaging.onBackgroundMessage(_firebaseMessagingBackgroundHandler);

    // Handle foreground messages
    setupForegroundMessageListener();
  }

  static Future<void> _firebaseMessagingBackgroundHandler(RemoteMessage message) async {
    _logger.i("Handling a background message: ${message.messageId}");
  }

  static void setupForegroundMessageListener() {
    FirebaseMessaging.onMessage.listen((RemoteMessage message) {
      _logger.i('Received foreground message: ${message.messageId}');
      if (message.notification != null) {
        _logger.i('Notification: ${message.notification!.title} - ${message.notification!.body}');
      }
    });
  }

  static Future<String?> getFCMToken() async {
    String? token = await _firebaseMessaging.getToken();
    _logger.i('Generated FCM Token: $token');
    return token;
  }

  static Future<void> sendTokenToServer(String token) async {
    final prefs = await SharedPreferences.getInstance();
    final authToken = prefs.getString('token');
    if (authToken == null) {
      _logger.w('No auth token found, skipping token send');
      return;
    }

    try {
      final response = await http.post(
        Uri.parse('http://192.168.137.1:8000/api/store-token'),
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $authToken',
        },
        body: jsonEncode({'token': token}),
      );
      if (response.statusCode == 200) {
        _logger.i('FCM token sent to server successfully');
      } else {
        _logger.w('Failed to send token: ${response.statusCode} - ${response.body}');
      }
    } catch (e) {
      _logger.e('Error sending token: $e');
    }
  }

  static Future<void> refreshToken() async {
    _firebaseMessaging.onTokenRefresh.listen((newToken) async {
      _logger.i('FCM Token refreshed: $newToken');
      await sendTokenToServer(newToken);
    });
  }
}