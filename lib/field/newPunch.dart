// ADD AT TOP (unchanged imports)
import 'dart:async';
import 'dart:convert';
import 'dart:io';

import 'package:flutter/material.dart';
import 'package:geolocator/geolocator.dart';
import 'package:intl/intl.dart';
import 'package:mittsure/field/punchDetailpopup.dart';
import 'package:mittsure/field/vameraScreen.dart';
import 'package:http/http.dart' as http;
import 'package:mittsure/newApp/MainMenuScreen.dart';
import 'package:mittsure/screens/mainMenu.dart';
import 'package:mittsure/services/monthFilter.dart';
import 'package:mittsure/services/utils.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:shimmer/shimmer.dart';

import '../services/apiService.dart';

class PunchScreen extends StatefulWidget {
  @override
  _PunchScreenState createState() => _PunchScreenState();
}

class _PunchScreenState extends State<PunchScreen> {
  List<dynamic> punches = [];
  bool isLoading = false;
  bool isLoadingCards = false;
  bool cameraScreen = false;
  String? meterReading = "";
  Timer? _timer;
  int selectedMonth = 1;
  bool lastPunchIn = false;
  Duration currentSessionDuration = Duration.zero;

  // Dummy counters
  int presentCount = 12;
  int absentCount = 3;
  int halfDayCount = 1;
  Map<String, dynamic> userData = {};
  getUserData() async {
    final prefs = await SharedPreferences.getInstance();
    final a = prefs.getString('user');
    if (a!.isNotEmpty) {
      setState(() {
        userData = jsonDecode(a ?? "");
        _fetchWorkingHours();
        _fetchMonthlyAttendance(null);
      });
    }
  }

  // lastPunchIn = punches.isNotEmpty && punches.last.type == "In";
  Future<void> _fetchMonthlyAttendance(month) async {
    print(month);
    setState(() {
      isLoadingCards = true;
    });

    final now = DateTime.now();

    Map<String, dynamic> body = {
      "userId": userData['id'],
      "month": month ?? now.month, // e.g., 6 for June
      "year": now.year, // e.g., 2025
    };

    try {
      print(body);
      final response = await ApiService.post(
        endpoint: '/attendance/getMonthlyAttendanceSummary',
        // Use your API endpoint
        body: body,
      );
      print(response);
      if (response != null && response['success'] == true) {
        final data = response['data'];
        setState(() {
          selectedMonth = body['month'];
          halfDayCount = data['half_day'];
          presentCount = data['full_day'];
          absentCount = data['absent'];
          isLoadingCards = false;
        });
      } else {
        setState(() {
          isLoadingCards = false;
        });
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error'),
            backgroundColor: Colors.red,
          ),
        );
      }
    } catch (error) {
      print("Error fetchingmmm orders: $error");
    }
  }

  Future<void> _fetchWorkingHours() async {
    setState(() {
      isLoading = true;
    });
    DateTime now = DateTime.now();
    String formattedDate = DateFormat('yyyy-MM-dd').format(now);
    final body = {"userId": userData['id'], "date": formattedDate};

    try {
      final response = await ApiService.post(
        endpoint: '/attendance/getAttendanceDetailsByDate',
        // Use your API endpoint
        body: body,
      );

      if (response != null) {
        final data = response['data'];

        Duration totalDuration = Duration();
        final punchRecords = data['inOutHistory'];

        DateTime now = DateTime.now();
        bool flag = false;
        for (var record in punchRecords) {
          String? inTimeStr = record['in_time'];
          String? outTimeStr = record['out_time'];

          if (inTimeStr != null) {
            DateTime inTime = DateTime.parse(inTimeStr.replaceFirst(' ', 'T'));

            DateTime outTime;
            if (outTimeStr != null) {
              outTime = DateTime.parse(outTimeStr.replaceFirst(' ', 'T'));
            } else {
              outTime = now;
              flag = true;
            }

            if (outTime.isAfter(inTime)) {
              totalDuration += outTime.difference(inTime);
            }
          }
        }

        int totalHours = totalDuration.inHours;
        int totalMinutes = totalDuration.inMinutes % 60;

        print(
            'Total Working Time: $totalHours hours and $totalMinutes minutes');
        setState(() {
          punches = punchRecords;
          isLoading = false;
          if (flag) {
            lastPunchIn = true;

            startTimer(punchRecords[0]['in_time']);
          } else {
            lastPunchIn = false;
            stopTimer();
          }
        });
      } else {
        throw Exception('Failed to load orders');
      }
    } catch (error) {
      print("Error fetchingmmm orders: $error");
    }
  }

  Duration get totalWorkedDuration {
    Duration total = Duration.zero;
    DateTime now = DateTime.now();
    bool flag = false;
    for (var record in punches) {
      String? inTimeStr = record['in_time'];
      String? outTimeStr = record['out_time'];

      if (inTimeStr != null) {
        DateTime inTime = DateTime.parse(inTimeStr.replaceFirst(' ', 'T'));

        DateTime outTime;
        if (outTimeStr != null) {
          outTime = DateTime.parse(outTimeStr.replaceFirst(' ', 'T'));
        } else {
          outTime = now;
          flag = true;
        }

        if (outTime.isAfter(inTime)) {
          total += outTime.difference(inTime);
        }
      }
    }
    return total;
  }

  String formatDuration(Duration d) {
    return "${d.inHours.toString().padLeft(2, '0')}:${(d.inMinutes % 60).toString().padLeft(2, '0')}:${(d.inSeconds % 60).toString().padLeft(2, '0')}";
  }

  Future<void> onPunchButtonPressed(String imagePath, String reading) async {
    if (imagePath == null || reading == null) return;

    setState(() {
      cameraScreen = false;
      isLoading = true;
    });
    meterReading = reading;

    final location = await getCurrentLocation(context);
    if (location == null) {
      setState(() {
        cameraScreen =
            false; // 👈 This will hide camera screen when user cancels
      });
      return;
    }
    final punchData = await showDialog<Map<String, dynamic>>(
      context: context,
      builder: (_) => PunchDetailsPopup(meterReading: meterReading ?? ""),
    );

    if (punchData == null) {
      setState(() {
        isLoading = false;
      });
      return;
    }

    try {
      var uri = Uri.parse(
          'https://mittsure.qdegrees.com:3001/attendance/punchAttendance');

      var request = http.MultipartRequest('POST', uri);

      // Add form fields
      request.fields.addAll({
        "in_km": lastPunchIn ? "" : punchData['km'],
        "punch": lastPunchIn ? "out" : "in",
        "out_km": lastPunchIn ? punchData['km'] : "",
        "userId": userData['id'].toString(),
        "remark": punchData['remark'] ?? '',
        "manual_reading": punchData['kmChanged'] ? '1' : '0',
        "work_type": punchData['worktype'] ?? '',
        "in_latitude": lastPunchIn ? "" : location.latitude.toString(),
        "in_longitude": lastPunchIn ? "" : location.longitude.toString(),
        "out_latitude": lastPunchIn ? location.latitude.toString() : "",
        "out_longitude": lastPunchIn ? location.longitude.toString() : "",
      });

      // Add the image file
      File imageFile = File(imagePath);
      if (await imageFile.exists()) {
        request.files.add(
          await http.MultipartFile.fromPath(
            'image', 
            imageFile.path,
          ),
        );
      }

      var streamedResponse = await request.send();

      var response = await http.Response.fromStream(streamedResponse);

        final res = jsonDecode(response.body);
      if (response.statusCode == 200) {
        if (res['status']) {
          
          DialogUtils.showCommonPopup(
          context: context,
          message: res['message'],
          isSuccess: false,
          onOkPressed:(){ setState(() {
           isLoading=false; 
          });
          }
         );
        } else {
          _fetchWorkingHours();
        }
      } else {
       DialogUtils.showCommonPopup(
          context: context,
          message: res['message'],
          isSuccess: false,
          onOkPressed:(){ setState(() {
           isLoading=false; 
          });
          }
         );
      }
    } catch (error) {
      DialogUtils.showCommonPopup(
          context: context,
          message: "Sorry ! Something Went Wrong",
          isSuccess: false,
          onOkPressed:(){ setState(() {
           isLoading=false; 
          });
          }
         );
    }
  }

  void startTimer(String time) {
    stopTimer();

    DateTime startTime = DateTime.parse(time); // Convert string to DateTime

    _timer = Timer.periodic(Duration(seconds: 1), (_) {
      setState(() {
        currentSessionDuration = DateTime.now().difference(startTime);
      });
    });
  }

  void stopTimer() {
    _timer?.cancel();
    currentSessionDuration = Duration.zero;
  }

  @override
  void dispose() {
    stopTimer();
    super.dispose();
  }

  Widget buildSummaryCard(String title, int count, Color color, IconData icon) {
    return Expanded(
      child: Container(
        margin: EdgeInsets.symmetric(horizontal: 6),
        padding: EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: color.withOpacity(0.15),
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: color.withOpacity(0.4)),
        ),
        child: Column(
          children: [
            Icon(icon, size: 28, color: color),
            SizedBox(height: 8),
            Text(title,
                style: TextStyle(
                    fontSize: 16, fontWeight: FontWeight.bold, color: color)),
            Text(count.toString(),
                style: TextStyle(
                    fontSize: 20, fontWeight: FontWeight.bold, color: color)),
          ],
        ),
      ),
    );
  }

  @override
  void initState() {
    // TODO: implement initState
    super.initState();
    getUserData();
  }

  getTime(str) {
    String dateTimeString = str;

    // Parse the string into DateTime
    DateTime parsedDateTime = DateTime.parse(dateTimeString);

    // Format to show only time (e.g., 1:33 PM)
    String formattedTime = DateFormat.jm().format(parsedDateTime);

    // print(formattedTime);
    return formattedTime; // Output: 1:33 PM
  }

  @override
  Widget build(BuildContext context) {
    return WillPopScope(
      onWillPop: ()async{
        Navigator.pushAndRemoveUntil(
                  context,
                  MaterialPageRoute(builder: (context) => MainMenuScreen()),
                  (route) => false, // remove all previous routes
                );
                return false;
      },
      child: Scaffold(
        backgroundColor: const Color(0xFFF5F5F5), // Light grey background
        appBar: AppBar(
          
          title: Text(
            "Attendance",
            style: TextStyle(color: Colors.white, fontSize: 18),
          ),
          backgroundColor: Colors.indigo[900],
          centerTitle: true,
          actions: [
            IconButton(
              icon: const Icon(Icons.home, color: Colors.white),
              onPressed: () {
                Navigator.pushAndRemoveUntil(
                  context,
                  MaterialPageRoute(builder: (context) => MainMenuScreen()),
                  (route) => false, // remove all previous routes
                );
              },
            ),
          ],
        ),
        body: isLoading
            ? Center(
                child: CircularProgressIndicator(),
              )
            : cameraScreen
                ? KMReadingCameraScreen(onReadingCaptured: onPunchButtonPressed)
                : Padding(
                    padding: const EdgeInsets.all(16),
                    child: Column(
                      children: [
                        Card(
                          shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(16)),
                          elevation: 6,
                          color: Colors.white,
                          child: Padding(
                            padding: const EdgeInsets.all(20),
                            child: Column(
                              children: [
                                Text("Today's Working Hours",
                                    style: TextStyle(
                                        color: Colors.indigo[900],
                                        fontSize: 18,
                                        fontWeight: FontWeight.bold)),
                                SizedBox(height: 8),
                                Text(formatDuration(totalWorkedDuration),
                                    style: TextStyle(
                                        fontSize: 34,
                                        fontWeight: FontWeight.w800,
                                        color: Colors.indigo[900])),
                                if (lastPunchIn) ...[
                                  SizedBox(height: 8),
                                  Text(
                                      "Current Session: ${formatDuration(currentSessionDuration)}",
                                      style: TextStyle(
                                          color: Colors.grey[700],
                                          fontWeight: FontWeight.w500)),
                                ],
                              ],
                            ),
                          ),
                        ),
                        SizedBox(height: 20),
                        ElevatedButton.icon(
                          onPressed: () {
                            setState(() => cameraScreen = true);
                          },
                          icon: Icon(lastPunchIn ? Icons.logout : Icons.login,
                              size: 26, color: Colors.white),
                          label: Padding(
                            padding: const EdgeInsets.symmetric(vertical: 14),
                            child: Text(lastPunchIn ? "Punch Out" : "Punch In",
                                style: TextStyle(
                                    fontSize: 20,
                                    fontWeight: FontWeight.bold,
                                    color: Colors.white)),
                          ),
                          style: ElevatedButton.styleFrom(
                            backgroundColor:
                                lastPunchIn ? Colors.red : Colors.green,
                            minimumSize: Size(double.infinity, 56),
                            shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(16)),
                          ),
                        ),
                        SizedBox(height: 20),
                        Row(
                          mainAxisAlignment: MainAxisAlignment.end,
                          children: [
                            MonthFilter(
                              onMonthSelected: _fetchMonthlyAttendance,
                              initialMonth: selectedMonth,
                            ),
                          ],
                        ),
                        SizedBox(
                          height: 5,
                        ),
                        Row(
                          children: isLoadingCards
                              ? List.generate(3, (index) => buildSkeletonCard())
                              : [
                                  buildSummaryCard("Present", presentCount,
                                      Colors.green, Icons.check_circle),
                                  buildSummaryCard("Absent", absentCount,
                                      Colors.red, Icons.cancel),
                                  buildSummaryCard("Half Day", halfDayCount,
                                      Colors.orange, Icons.access_time),
                                ],
                        ),
                        SizedBox(height: 20),
                        Align(
                          alignment: Alignment.centerLeft,
                          child: Text("Today's Punch Report",
                              style: TextStyle(
                                  fontSize: 20,
                                  fontWeight: FontWeight.bold,
                                  color: Colors.indigo[900])),
                        ),
                        SizedBox(height: 12),
                        Expanded(
                          child: punches.isEmpty
                              ? Center(child: Text("No punches yet"))
                              : ListView.builder(
                                  itemCount: punches.length,
                                  itemBuilder: (context, index) {
                                    final punch = punches[index];
                                    return Column(
                                      children: [
                                        punch["out_time"] == null
                                            ? Container()
                                            : Card(
                                                elevation: 3,
                                                shape: RoundedRectangleBorder(
                                                    borderRadius:
                                                        BorderRadius.circular(
                                                            12)),
                                                child: ListTile(
                                                  leading: CircleAvatar(
                                                    backgroundColor:
                                                        Colors.red.shade600,
                                                    child: Icon(
                                                      Icons.logout,
                                                      color: Colors.white,
                                                    ),
                                                  ),
                                                  title: Text(
                                                      "Punch Out - ${getTime(punch["out_time"])}",
                                                      style: TextStyle(
                                                          fontWeight:
                                                              FontWeight.bold)),
                                                  subtitle: Column(
                                                    crossAxisAlignment:
                                                        CrossAxisAlignment.start,
                                                    children: [
                                                      SizedBox(height: 4),
                                                      Text(
                                                          "Meter Reading: ${punch["out_km"]}"),
                                                      // Text("Lat: ${punch.latitude.toStringAsFixed(4)}, Lng: ${punch.longitude.toStringAsFixed(4)}"),
                                                      // Text("Notes: ${punch.note1}, ${punch.note2}, ${punch.note3}"),
                                                    ],
                                                  ),
                                                ),
                                              ),
                                        Card(
                                          elevation: 3,
                                          shape: RoundedRectangleBorder(
                                              borderRadius:
                                                  BorderRadius.circular(12)),
                                          child: ListTile(
                                            leading: CircleAvatar(
                                              backgroundColor:
                                                  Colors.green.shade600,
                                              child: Icon(
                                                Icons.login,
                                                color: Colors.white,
                                              ),
                                            ),
                                            title: Text(
                                                "Punch In - ${getTime(punch["in_time"])}",
                                                style: TextStyle(
                                                    fontWeight: FontWeight.bold)),
                                            subtitle: Column(
                                              crossAxisAlignment:
                                                  CrossAxisAlignment.start,
                                              children: [
                                                SizedBox(height: 4),
                                                Text(
                                                    "Meter Reading: ${punch["in_km"]}"),
                                                // Text("Lat: ${punch.latitude.toStringAsFixed(4)}, Lng: ${punch.longitude.toStringAsFixed(4)}"),
                                                // Text("Notes: ${punch.note1}, ${punch.note2}, ${punch.note3}"),
                                              ],
                                            ),
                                          ),
                                        ),
                                      ],
                                    );
                                  },
                                ),
                        )
                      ],
                    ),
                  ),
      ),
    );
  }
}

Widget buildSkeletonCard() {
  return Shimmer.fromColors(
    baseColor: Colors.grey.shade300,
    highlightColor: Colors.grey.shade100,
    child: Container(
      margin: const EdgeInsets.symmetric(horizontal: 8),
      padding: const EdgeInsets.all(16),
      width: 100,
      height: 100,
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
      ),
    ),
  );
}

Future<Position?> getCurrentLocation(BuildContext context) async {
  bool serviceEnabled = await Geolocator.isLocationServiceEnabled();
  if (!serviceEnabled) {
    bool? openSettings = await showDialog<bool>(
      context: context,
      barrierDismissible: false, // force user to choose
      builder: (context) => AlertDialog(
        icon: Icon(Icons.error),
        iconColor: Colors.red,
        title: Text('Location Disabled'),
        content: Text('Please enable location services to continue.'),
        actions: [
          TextButton(
            child: Text('Cancel'),
            onPressed: () {
              Navigator.pop(context, false);
            },
          ),
          ElevatedButton(
            child: Text('Turn On'),
            onPressed: () async {
              await Geolocator.openLocationSettings();
              Navigator.pop(context, true);
            },
          ),
        ],
      ),
    );

    if (openSettings != true) {
      return null;
    }

    // Wait until location service is enabled
    while (!(await Geolocator.isLocationServiceEnabled())) {
      await Future.delayed(Duration(seconds: 1));
    }
  }

  LocationPermission permission = await Geolocator.checkPermission();
  if (permission == LocationPermission.deniedForever) {
    throw Exception('Location permissions are permanently denied.');
  }

  if (permission == LocationPermission.denied) {
    permission = await Geolocator.requestPermission();
    if (permission != LocationPermission.whileInUse &&
        permission != LocationPermission.always) {
      throw Exception('Location permissions are denied.');
    }
  }

  return await Geolocator.getCurrentPosition(
    desiredAccuracy: LocationAccuracy.high,
  );
}
