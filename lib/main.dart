import 'dart:io';
import 'package:flutter/material.dart';
import 'package:mittsure/screens/splash.dart';
import 'package:permission_handler/permission_handler.dart';

class MyHttpOverrides extends HttpOverrides {
  @override
  HttpClient createHttpClient(SecurityContext? context) {
    return super.createHttpClient(context)
      ..badCertificateCallback = (X509Certificate cert, String host, int port) => true;
  }
}

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  HttpOverrides.global = MyHttpOverrides();

  var status = await Permission.location.status;
  if (!status.isGranted) {
    status = await Permission.location.request();
  }

  runApp(status.isGranted ? MyApp() : LocationDeniedApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
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
                Icon(Icons.location_disabled_outlined, size: 80, color: Colors.red),
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
