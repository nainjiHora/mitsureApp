import 'package:flutter/material.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:shared_preferences/shared_preferences.dart';

class IrebaseApi {
  final FirebaseMessaging _firebaseMessaging = FirebaseMessaging.instance;
  final FlutterLocalNotificationsPlugin _flutterLocalNotificationsPlugin =
      FlutterLocalNotificationsPlugin();

  Future<String?> initNotification() async {
    await _firebaseMessaging.requestPermission();

    final String? fcmToken = await _firebaseMessaging.getToken();
    if (fcmToken != null) {
      print("fcm");
      print(fcmToken);
      final SharedPreferences prefs = await SharedPreferences.getInstance();
      await prefs.setString('fcm', fcmToken);
      return fcmToken;
    }

    FirebaseMessaging.onMessage.listen((RemoteMessage message) {
      print('Message received in foreground: ${message.notification?.title}');
      print('Body: ${message.notification?.body}');
      print('Data: ${message.data}');
    });
  }
}
