import 'dart:convert';
import 'dart:io';
import 'package:flutter_foreground_task/flutter_foreground_task.dart';
import 'package:geolocator/geolocator.dart';
import 'package:http/http.dart' as http;
import 'package:http/io_client.dart';
import 'package:mittsure/services/apiService.dart';
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
    return prefs.getString('Token');  // Assuming token is stored under the key 'token'
  }
  @override
  Future<void> onRepeatEvent(DateTime timestamp) async {
    print("🔁 onRepeatEvent called at $timestamp");
    print("lkjhgfdfghjhgfdfghgfghjgfghjhgfghgfghgfghgfghfdfg");
    final position = await Geolocator.getCurrentPosition(
      desiredAccuracy: LocationAccuracy.high,
    );

    if (position.accuracy > 50) return;

    final visitId = await FlutterForegroundTask.getData<String>(key: 'visitId');
    final lat = await FlutterForegroundTask.getData<String>(key: 'lat');
    final long = await FlutterForegroundTask.getData<String>(key: 'long');

    final payload = {
      "visitId": visitId,
      "lat": position.latitude,
      "lng": position.longitude,
      "accuracy": position.accuracy,
      "partyLat":lat,
      "partyLong":long,
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

    final response = await client.post(
      Uri.parse("https://mittsure.qdegrees.com:3001/visit/checkLocation"),
      headers:defaultHeaders,
      body: jsonEncode(payload),
    );

    print(response.body);
    print("response from id d");
    var data=jsonDecode(response.body);
    if(data['count']>=7){
      print("stopping serverice");
      await FlutterForegroundTask.stopService();
    }

  }

  @override
  Future<void> onDestroy(DateTime timestamp) {
    // TODO: implement onDestroy
    throw UnimplementedError();
  }

  @override
  Future<void> onStart(DateTime timestamp, TaskStarter starter) {
    // TODO: implement onStart
    throw UnimplementedError();
  }
}
