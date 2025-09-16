import 'dart:io';
import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter/material.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:mittsure/screens/splash.dart';
import 'package:mittsure/services/fbservice.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import './services/navigation_service.dart';

class MyHttpOverrides extends HttpOverrides {
  @override
  HttpClient createHttpClient(SecurityContext? context) {
    return super.createHttpClient(context)
      ..badCertificateCallback =
          (X509Certificate cert, String host, int port) => true;
  }
}

FlutterLocalNotificationsPlugin flutterLocalNotificationsPlugin = FlutterLocalNotificationsPlugin();

void handleNotificationTap(String? payload) {
  if (payload != null && payload != "") {
    
  }
}

void handleAction(RemoteMessage message) {
  if (message.data.isNotEmpty) {
    
  }
}

Future<void> handleBackgroundMessage(RemoteMessage message) async {
  print('Handling a background message: ${message.notification?.body}');
}

Future<void> _showNotification(RemoteMessage message) async {
  const AndroidNotificationDetails androidNotificationDetails = AndroidNotificationDetails(
    'high_importance_channel', // Channel ID
    'High Importance', // Channel Name
    icon: 'drawable/ic_stat_icon',
    importance: Importance.max,
    priority: Priority.high,
    showWhen: false,
  );

  const NotificationDetails platformChannelSpecifics = NotificationDetails(android: androidNotificationDetails);

  await flutterLocalNotificationsPlugin.show(
    message.notification.hashCode, // Unique ID for notification
    message.notification!.title,
    message.notification!.body,
    platformChannelSpecifics,
    payload: message.data['type'] == 'Waiting' ? message.data['eventId'] : message.data['type'] == 'Reminder' ? 'booking' : "",
  );
}
// final GlobalKey<NavigatorState> navigatorKey = GlobalKey<NavigatorState>();

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  HttpOverrides.global = MyHttpOverrides();
  await dotenv.load();

  var status = await Permission.location.status;
  if (!status.isGranted) {
    status = await Permission.location.request();
  }
  await Firebase.initializeApp();
  IrebaseApi().initNotification();

  // await FirebaseMessaging.instance.requestPermission(
  //   alert: true,
  //   badge: true,
  //   sound: true,
  // );

  FirebaseMessaging.onBackgroundMessage(handleBackgroundMessage);

  const AndroidInitializationSettings initializationSettingsAndroid = AndroidInitializationSettings('drawable/ic_launcher');
  
  // iOS-specific notification settings
  final DarwinInitializationSettings initializationSettingsIOS = DarwinInitializationSettings(
    // onDidReceiveLocalNotification: (int id, String? title, String? body, String? payload) async {
    //   handleNotificationTap(payload);
    // },
  );

  final InitializationSettings initializationSettings = InitializationSettings(
    android: initializationSettingsAndroid,
    iOS: initializationSettingsIOS, // iOS settings added
  );

  await flutterLocalNotificationsPlugin.initialize(
    initializationSettings,
    onDidReceiveNotificationResponse: (NotificationResponse response) {
      handleNotificationTap(response.payload);
    },
  );

  FirebaseMessaging.onMessage.listen((RemoteMessage message) {
    if (message.notification != null) {
      print('Message also contained a notification: ${message.data}');
      _showNotification(message);
    }
  });

  FirebaseMessaging.onMessageOpenedApp.listen((RemoteMessage message) {
    print('A notification was opened: ${message.notification?.title}');
    handleAction(message); // Handle notification tap
  });

  runApp(status.isGranted ? MyApp() : LocationDeniedApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      navigatorKey: navigatorKey,
      debugShowCheckedModeBanner: false,
      title: 'MittsureOne',
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(seedColor: Colors.deepPurple),
        useMaterial3: true,
      ),
      home: SplashScreen(),
    );
  }
}

class LocationDeniedApp extends StatelessWidget {
  const LocationDeniedApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      title: 'MittsureOne',
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(seedColor: Colors.red),
        useMaterial3: true,
      ),
      home: Scaffold(
        body: Center(
          child: Padding(
            padding: const EdgeInsets.all(24.0),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(Icons.location_disabled_outlined,
                    size: 80, color: Colors.red),
                SizedBox(height: 20),
                Text(
                  "Location access is mandatory to use this app.",
                  textAlign: TextAlign.center,
                  style: TextStyle(fontSize: 18),
                ),
                SizedBox(height: 30),
                ElevatedButton(
                  onPressed: () async {
                    var status = await Permission.location.request();
                    if (status.isGranted) {
                      // Restart app by calling main again or navigate programmatically
                      main(); // simple restart, not ideal for production
                    }
                  },
                  child: Text("Retry Permission"),
                ),
                SizedBox(height: 10),
                TextButton(
                  onPressed: () => exit(0),
                  child: Text("Exit App"),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
