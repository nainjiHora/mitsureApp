import 'dart:convert';
import 'dart:io';
import 'package:flutter_foreground_task/flutter_foreground_task.dart';
import 'package:geolocator/geolocator.dart';
import 'package:http/http.dart' as http;
import 'package:http/io_client.dart';
import 'package:shared_preferences/shared_preferences.dart';

@pragma('vm:entry-point')
class VisitTask extends TaskHandler {


  IOClient createUnsafeClient() {
    final httpClient = HttpClient()
      ..badCertificateCallback =
          (X509Certificate cert, String host, int port) => true;

    return IOClient(httpClient);
  }


  static Future<String?> _getToken() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getString('Token');
  }


  Future<void> _savePendingPayload(Map<String, dynamic> payload) async {
    final prefs = await SharedPreferences.getInstance();
    List<String> list = prefs.getStringList("pending_payloads") ?? [];
    payload['lng']=null;
    payload['lat']=null;
    list.add(jsonEncode(payload));
    await prefs.setStringList("pending_payloads", list);
  }


  Future<void> _sendPendingPayloads(
      IOClient client, Map<String, String> headers) async {
    final prefs = await SharedPreferences.getInstance();
    List<String> list = prefs.getStringList("pending_payloads") ?? [];

    if (list.isEmpty) return;

    List<String> remaining = [];

    for (String item in list) {
      try {
        final response = await client.post(
          Uri.parse("https://mittsure.qdegrees.com:3001/visit/checkLocation"),
          headers: headers,
          body: item,
        );

        print("Pending response: ${response.statusCode}");
      } catch (e) {
        // Still no internet → keep remaining
        remaining.add(item);
      }
    }

    await prefs.setStringList("pending_payloads", remaining);
  }


  @override
  Future<void> onRepeatEvent(DateTime timestamp) async {
    print("🔁 onRepeatEvent called at $timestamp");

    Position? position;


    try {
      bool serviceEnabled = await Geolocator.isLocationServiceEnabled();

      if (serviceEnabled) {
        LocationPermission permission = await Geolocator.checkPermission();

        if (permission != LocationPermission.denied &&
            permission != LocationPermission.deniedForever) {

          final pos = await Geolocator.getCurrentPosition(
            desiredAccuracy: LocationAccuracy.high,
          );

          if (pos.accuracy <= 50) {
            position = pos;
          }
        }
      }
    } catch (e) {
      print("Location error: $e");
      position = null;
    }

    final visitId =
    await FlutterForegroundTask.getData<String>(key: 'visitId');
    final lat = await FlutterForegroundTask.getData<String>(key: 'lat');
    final long = await FlutterForegroundTask.getData<String>(key: 'long');

    final payload = {
      "visitId": visitId,
      "lat": position?.latitude,
      "lng": position?.longitude,
      "accuracy": position?.accuracy,
      "partyLat": lat,
      "partyLong": long,
      "timestamp": DateTime.now().millisecondsSinceEpoch,
    };

    final String? token = await _getToken();

    Map<String, String> defaultHeaders = {
      'Content-Type': 'application/json',
      'Accept': 'application/json',
    };

    if (token != null) {
      defaultHeaders['Token'] = 'token=$token';
      defaultHeaders['token'] = 'token=$token';
    }

    final client = createUnsafeClient();

    // ==============================
    // 🌐 INTERNET + RETRY LOGIC
    // ==============================
    try {

      // ✅ First send OLD payloads
      await _sendPendingPayloads(client, defaultHeaders);

      // ✅ Then send CURRENT payload
      final response = await client.post(
        Uri.parse("https://mittsure.qdegrees.com:3001/visit/checkLocation"),
        headers: defaultHeaders,
        body: jsonEncode(payload),
      );

      print(response.body);

      var data = jsonDecode(response.body);

      if (data['count'] >= 7) {
        print("🛑 stopping service");
        await FlutterForegroundTask.stopService();
      }

    } on SocketException catch (e) {
      print("❌ Internet OFF, saving payload");

      // save locally if internet off
      await _savePendingPayload(payload);

    } catch (e) {
      print("❌ Unknown network error: $e");
    }
  }

  // ==============================
  // 🔥 Required overrides
  // ==============================
  @override
  Future<void> onDestroy(DateTime timestamp) async {
    print("🔥 Task Destroyed");
  }

  @override
  Future<void> onStart(DateTime timestamp, TaskStarter starter) async {
    print("🚀 Task Started");
  }
}
