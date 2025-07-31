// ADD AT TOP (unchanged imports)
import 'dart:async';
import 'dart:convert';
import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter/widgets.dart';
import 'package:geolocator/geolocator.dart';
import 'package:intl/intl.dart';
import 'package:mittsure/field/punchDetailpopup.dart';
import 'package:mittsure/field/vameraScreen.dart';
import 'package:http/http.dart' as http;
import 'package:mittsure/newApp/MainMenuScreen.dart';
import 'package:mittsure/newApp/bookLoader.dart';
import 'package:mittsure/screens/mainMenu.dart';
import 'package:mittsure/services/monthFilter.dart';
import 'package:mittsure/services/utils.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:shimmer/shimmer.dart';

import '../services/apiService.dart';

class PunchScreen extends StatefulWidget {
  final bool mark;

  PunchScreen({required this.mark});

  @override
  _PunchScreenState createState() => _PunchScreenState();
}

class _PunchScreenState extends State<PunchScreen> {
  List<dynamic> punches = [];
  DateTime? followUpDate;
  String selectedASM = "";
  List<dynamic> asmList = [];
  String selectedRsm = "";
  List<dynamic> rsmList = [];
  String selectedSE = "";
  List<dynamic> seList = [];
  bool isLoading = false;
  bool isLoadingCards = false;
  bool cameraScreen = false;
  String? meterReading = "";
  var reasonData = null;
  Timer? _timer;
  int selectedMonth = 1;
  bool lastPunchIn = false;
  Duration currentSessionDuration = Duration.zero;

  // Dummy counters
  int presentCount = 0;
  int leaveCount = 0;
  int absentCount = 0;
  int halfDayCount = 0;
  bool meterCamera = false;
  Map<String, dynamic> userData = {};
  getUserData() async {
    final prefs = await SharedPreferences.getInstance();
    final a = prefs.getString('user');
    if (a!.isNotEmpty) {
      setState(() {
        userData = jsonDecode(a ?? "");
        print(userData['role']);

        if (userData['role'] == 'se') {
          selectedSE = userData['id'];
          _fetchWorkingHours(null);
        _fetchMonthlyAttendance(null);
        } else if (userData['role'] == 'rsm') {
          selectedRsm = userData['id'];
          _fetchAsm(userData['id']);
        } else if (userData['role'] == 'asm') {
          selectedASM = userData['id'];
          _fetchSe(userData['id']);
        } else {
          _fetChAllRSM();
        }
      });
    }
  }

  List<dynamic> allUsers = [];
  _fetChAllRSM() async {
    try {
      setState(() {
        isLoading = true;
      });
      final response =
          await ApiService.post(endpoint: '/user/getUsers', body: {});

      if (response != null) {
        final data = response['data'];
        setState(() {
          rsmList = data.where((e) => e['role'] == 'rsm').toList();
          asmList = data.where((e) => e['role'] == 'asm').toList();
          seList = data.where((e) => e['role'] == 'se').toList();
          allUsers = data;
         isLoading=false;
        
        });
      } else {
        throw Exception('Failed to load orders');
      }
    } catch (error) {
      print("Error fetching ojbjbjbjjrders: $error");
    } finally {}
  }

  bool hasRole(String targetRole) {
    final role = userData['role'];
    if (role == null) return false;
    return role.toString().contains(targetRole);
  }

  _fetchAsm(id) async {
    setState(() {
      isLoading = true;
    });
    
    try {
      if (id != "") {
        final response = await ApiService.post(
          endpoint: '/user/getUserListBasedOnId',
          body: {"userId": id},
        );

        if (response != null) {
          final data = response['data'];
          setState(() {
            asmList = data;
            selectedSE = "";
            selectedASM = "";

            seList = response['data1'];
            isLoading = false;
          });
        } else {
          throw Exception('Failed to load orders');
        }
      } else {
        setState(() {
          selectedASM = "";
          selectedSE = "";
          asmList = allUsers.where((e) => e['role'] == 'asm').toList();
          seList = allUsers.where((e) => e['role'] == 'se').toList();
          isLoading=false;
        });
      }
    } catch (error) {
      print("Error fetching ojbjbjbjjrders: $error");
    } finally {}
  }

  _fetchSe(id) async {
   print(id);
    try {
      setState(() {
        isLoading = true;
      });
      if (id != "") {
        final response = await ApiService.post(
          endpoint: '/user/getUserListBasedOnId',
          body: {"userId": id},
        );

        if (response != null) {
          final data = response['data'];
          setState(() {
            selectedSE = "";
            seList = data;
            isLoading = false;
          });
        } else {
          throw Exception('Failed to load orders');
        }
      } else {
        setState(() {
          selectedSE = "";
          seList = allUsers.where((e) => e['role'] == 'se').toList();
          isLoading = false;
        });
      }
    } catch (error) {
      print("Error fetching orders: $error");
    } finally {
      setState(() {
        isLoading = false;
      });
    }
  }



  // lastPunchIn = punches.isNotEmpty && punches.last.type == "In";
  Future<void> _fetchMonthlyAttendance(month) async {
    setState(() {
      isLoadingCards = true;
    });

    final now = DateTime.now();

    Map<String, dynamic> body = {
      "userId": widget.mark? userData['id']:selectedSE,
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
          leaveCount = data['leave'];
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

  Future<void> _fetchWorkingHours(date) async {
    DateTime now =date?? DateTime.now();
    
    setState(() {
      isLoading = true;
      followUpDate = now;
    });
    String formattedDate = DateFormat('yyyy-MM-dd').format(now);
    final body = { "userId": widget.mark? userData['id']:selectedSE,
     "date": formattedDate};

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

  Future<void> onPunchButtonPressed(
      String imagePath, String reading, bool manual) async {
    if (imagePath == null || reading == null) return;

    setState(() {
      cameraScreen = false;
      isLoading = true;
    });
    meterReading = reading;

    final location = await getCurrentLocation(context);
    if (location == null) {
      setState(() {
        cameraScreen = false;
      });
      return;
    }
    final punchData = reasonData;

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

      request.fields.addAll({
        "city" :jsonEncode(punchData['city']),
        "in_km": lastPunchIn ? "" : reading,
        "punch": lastPunchIn ? "out" : "in",
        "out_km": lastPunchIn ? reading : "",
        "userId": userData['id'].toString(),
        "remark": punchData['remark'] ?? '',
        "manual_reading": manual ? '1' : '0',
        "work_type":
            punchData['worktype'] != "" && punchData['worktype'] != null
                ? punchData['worktype']['name']
                : '',
        "in_latitude": lastPunchIn ? "" : location.latitude.toString(),
        "in_longitude": lastPunchIn ? "" : location.longitude.toString(),
        "visitType":
            punchData['visitType'] != "" && punchData['visitType'] != null
                ? punchData['visitType']['name']
                : '',
        "vehicleType":
            punchData['vehicleType'] != "" && punchData['vehicleType'] != null
                ? punchData['vehicleType']['name']
                : '',
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
        print(res);
        print("ppooiiu");
        if (res['status'] == false) {
          final prefs = await SharedPreferences.getInstance();
          if (lastPunchIn) {
            prefs.remove('vehicleType');
          } else {
            final gl = punchData['vehicleType'] != "" &&
                    punchData['vehicleType'] != null &&
                    punchData['vehicleType']['min_time'] == '1'
                ? true
                : false;
            print(gl);
            print('glanh');
            prefs.setBool('vehicleType', gl);
          }
          _fetchWorkingHours(null);
        } else {
          DialogUtils.showCommonPopup(
              context: context,
              message: res['message'],
              isSuccess: false,
              onOkPressed: () {
                setState(() {
                  isLoading = false;
                });
              });
        }
      } else {
        DialogUtils.showCommonPopup(
            context: context,
            message: res['message'],
            isSuccess: false,
            onOkPressed: () {
              setState(() {
                isLoading = false;
              });
            });
      }
    } catch (error) {
      print(error);
      DialogUtils.showCommonPopup(
          context: context,
          message: "Sorry ! Something Went Wrong",
          isSuccess: false,
          onOkPressed: () {
            setState(() {
              isLoading = false;
            });
          });
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
                    fontSize: 12, fontWeight: FontWeight.bold, color: color)),
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
    int currentMonth = DateTime.now().month;
    selectedMonth=currentMonth;
    getUserData();
  }

  getTime(str) {
    String dateTimeString = str;

    DateTime parsedDateTime = DateTime.parse(dateTimeString);
    String formattedTime = DateFormat.jm().format(parsedDateTime);

    return formattedTime; // Output: 1:33 PM
  }

  getAdminFilters(){
    return Column(
      children: [
        const SizedBox(height: 10),
          
          userData['role'] != 'se'
              ? Row(
                  children: [
                    SizedBox(
                      width: 5,
                    ),
                    hasRole('admin') ||
                            userData['role'] == 'zsm' ||
                            userData['role'] == 'zsm'
                        ? Expanded(
                            child: DropdownButtonFormField<String>(
                              value: selectedRsm,
                              decoration: InputDecoration(
                                labelText: 'Select HO',
                                border: OutlineInputBorder(),
                                contentPadding: EdgeInsets.symmetric(
                                    horizontal: 10, vertical: 8),
                              ),
                              style: TextStyle(fontSize: 14),
                              dropdownColor: Colors.white,
                              items: [
                                DropdownMenuItem<String>(
                                  value: '', // Blank value for "All"
                                  child: Text('Select HO',
                                      style: TextStyle(
                                          fontSize: 14, color: Colors.black)),
                                ),
                                ...rsmList.map((rsm) {
                                  return DropdownMenuItem<String>(
                                    value: rsm['id'].toString(),
                                    child: Text(rsm['name'],
                                        style: TextStyle(
                                            fontSize: 14, color: Colors.black)),
                                  );
                                }).toList(),
                              ],
                              onChanged: (value) {
                                setState(() {
                                  selectedRsm = value ?? "";
                                });
                                _fetchAsm(value);
                              },
                            ),
                          )
                        : SizedBox(height: 0),
                    SizedBox(
                      width: 5,
                    ),
                    userData['role'] == 'rsm' ||
                            hasRole('admin') ||
                            userData['role'] == 'zsm'
                        ? Expanded(
                            child: DropdownButtonFormField<String>(
                              value: selectedASM,
                              decoration: InputDecoration(
                                labelText: 'Select ARM',
                                border: OutlineInputBorder(),
                                contentPadding: EdgeInsets.symmetric(
                                    horizontal: 10, vertical: 8),
                              ),
                              style: TextStyle(fontSize: 14),
                              dropdownColor: Colors.white,
                              items: [
                                DropdownMenuItem<String>(
                                  value: '', // Blank value for "All"
                                  child: Text('Select ARM',
                                      style: TextStyle(
                                          fontSize: 14, color: Colors.black)),
                                ),
                                ...asmList.map((rsm) {
                                  return DropdownMenuItem<String>(
                                    value: rsm['id'].toString(),
                                    child: Text(rsm['name'],
                                        style: TextStyle(
                                            fontSize: 14, color: Colors.black)),
                                  );
                                }).toList(),
                              ],
                              onChanged: (value) {
                                setState(() {
                                  selectedASM = value ?? "";
                                });
                                _fetchSe(value);
                              },
                            ),
                          )
                        : SizedBox(height: 0),
                    SizedBox(
                      width: 5,
                    ),
                    SizedBox(
                      width: 5,
                    ),
                  ],
                )
              : Container(),
          SizedBox(
            height: 8,
          ),
          userData['role'] != 'se'
              ? Row(
                  children: [
                    SizedBox(
                      width: 5,
                    ),
                    SizedBox(
                      width: 5,
                    ),
                    Expanded(
                      child: DropdownButtonFormField<String>(
                        value: selectedSE,
                        decoration: InputDecoration(
                          labelText: 'Select RM',
                          border: OutlineInputBorder(),
                          contentPadding:
                              EdgeInsets.symmetric(horizontal: 10, vertical: 8),
                        ),
                        style: TextStyle(fontSize: 14),
                        dropdownColor: Colors.white,
                        items: [
                          DropdownMenuItem<String>(
                            value: '', // Blank value for "All"
                            child: Text('Select RM',
                                style: TextStyle(
                                    fontSize: 14, color: Colors.black)),
                          ),
                          ...seList.map((rsm) {
                            return DropdownMenuItem<String>(
                              value: rsm['id'].toString(),
                              child: Text(rsm['name'],
                                  style: TextStyle(
                                      fontSize: 14, color: Colors.black)),
                            );
                          }).toList(),
                        ],
                        onChanged: (value) {
                          selectedSE = value ?? "";
                         if(selectedSE!=null &&selectedSE!=""){ _fetchWorkingHours(null);
        _fetchMonthlyAttendance(null);}
                        },
                      ),
                    ),
                    SizedBox(
                      width: 5,
                    ),
                  ],
                )
              : Container(),
              SizedBox(height: 10,)
      ],
    );
  }
  Future<void> selectDateRange(BuildContext context) async {
  final DateTime now = DateTime.now();
  final DateTimeRange? picked = await showDateRangePicker(
    context: context,
    firstDate: DateTime(now.year - 1), // earliest date selectable
    lastDate: DateTime(now.year + 1), // latest date selectable
    initialDateRange: DateTimeRange(
      start: now.subtract(Duration(days: 7)),
      end: now,
    ),
  );

  if (picked != null) {
    markleave(picked);
  }
}

markleave(DateTimeRange picked)async{
  try{
    setState(() {
      isLoading=true;
    });
   var body = {
      "ownerId": userData!['id'],
      "startDate":picked.start.toString().substring(0,11),
      "endDate":picked.end.toString().substring(0,11)
      
    };
    print(body);
  
    final response = await ApiService.post(
      endpoint: "/attendance/markLeaveInAttendance",
      body: body,
    );

    if (response != null && response['status'] == false) {
      

      
      DialogUtils.showCommonPopup(
        context: context,
        message: response['message'],
        isSuccess: true,
      );
      _fetchMonthlyAttendance(selectedMonth);
    } else {
      DialogUtils.showCommonPopup(
        context: context,
        message: response['message'],
        isSuccess: false,
      );
    }
  } catch (e) {
    
    DialogUtils.showCommonPopup(
      context: context,
      message: 'Something went wrong',
      isSuccess: false,
    );
  } finally {
    setState(() {
      isLoading = false;
    });
  }
}

  @override
  Widget build(BuildContext context) {
    return WillPopScope(
      onWillPop: () async {
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
          iconTheme: IconThemeData(color: Colors.white),
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
        body: Stack(
          children: [
            
          
            cameraScreen
                ? KMReadingCameraScreen(
                    onReadingCaptured: onPunchButtonPressed, bike: meterCamera)
                : Padding(
                    padding: const EdgeInsets.all(16),
                    child: Column(
                      children: [
                        if (widget.mark)
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
                        if (widget.mark) SizedBox(height: 20),
                        if (widget.mark)
                          ElevatedButton.icon(
                            onPressed: () async {
                              reasonData =
                                  await showDialog<Map<String, dynamic>>(
                                context: context,
                                builder: (_) => PunchDetailsPopup(
                                  meterReading: meterReading ?? "",
                                  punchIn: !lastPunchIn,
                                ),
                              );
                              if (reasonData == null) {
                                setState(() {
                                  isLoading = false;
                                });
                                return;
                              } else {
                                bool flag=false;
                                if(lastPunchIn){
                                 try{
                                   final res=await ApiService.post(endpoint: "/attendance/getUserInKm", body: {
                                     "userId":userData['id']
                                   });
                                   if(res['success']==true){
                                     if(res['data']['in_km']!=''&&res['data']['in_km']!=null){
                                       flag=true;
                                     }
                                   }

                                 }
                                 catch(e){
                                   print(e);
                                 }
                                }
                                setState((){
                                  if (reasonData['vehicleType'] != null &&
                                      reasonData['vehicleType'] != "" &&
                                      reasonData['vehicleType']['min_time'] ==
                                          '1') {
                                    meterCamera = true;
                                  } else {

                                    meterCamera = flag;
                                  }
                                  cameraScreen = true;
                                });
                              }
                            },
                              icon: Icon(lastPunchIn ? Icons.logout : Icons.login,
                                size: 26, color: Colors.white),
                            label: Padding(
                              padding: const EdgeInsets.symmetric(vertical: 14),
                              child: Text(
                                  lastPunchIn ? "Punch Out" : "Punch In",
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
                          if (widget.mark) SizedBox(height: 10),
                          if (widget.mark)
                          ElevatedButton.icon(
                            onPressed: () async {
                             selectDateRange(context);
                            },
                              icon: Icon(Icons.power_off,
                                size: 26, color: Colors.white),
                            label: Padding(
                              padding: const EdgeInsets.symmetric(vertical: 14),
                              child: Text(
                                  "Mark Leave",
                                  style: TextStyle(
                                      fontSize: 20,
                                      fontWeight: FontWeight.bold,
                                      color: Colors.white)),
                            ),
                            style: ElevatedButton.styleFrom(
                              backgroundColor:
                                   const Color.fromARGB(255, 249, 180, 4),
                              minimumSize: Size(double.infinity, 56),
                              shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(16)),
                            ),
                          ),
                        SizedBox(height: 20),
                        !widget.mark? getAdminFilters():Container(),
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
                                  buildSummaryCard("Half Day", halfDayCount,
                                      Colors.orange, Icons.access_time),
                                  buildSummaryCard("Leave", leaveCount,
                                      Colors.blueAccent, Icons.access_time),
                                      
                                  buildSummaryCard("Absent", absentCount,
                                      Colors.red, Icons.cancel),
                                      
                                ],
                        ),
                        SizedBox(height: 20),
                        Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              Text(
                                  widget.mark
                                      ? "Today's Punch Report"
                                      : "Punch Report",
                                  style: TextStyle(
                                      fontSize: 20,
                                      fontWeight: FontWeight.bold,
                                      color: Colors.indigo[900])),
                              GestureDetector(
                                onTap: () async {
                                  final picked = await showDatePicker(
                                    context: context,
                                    initialDate: DateTime.now(),
                                    firstDate: DateTime(DateTime.now().year),
                                    lastDate: DateTime.now(),
                                  );
                                  if (picked != null)
                                    setState((){
                                      followUpDate = picked;
                                      _fetchWorkingHours(followUpDate);
                                    });
                                },
                                child: Row(
                                  children: [
                                    Icon(Icons.calendar_today),
                                    Text(
                                        widget.mark
                                            ? ""
                                            :followUpDate!=null? " ${followUpDate!.day}-${followUpDate!.month}-${followUpDate!.year}":"",
                                        style: TextStyle(
                                            fontSize: 20,
                                            fontWeight: FontWeight.bold,
                                            color: Colors.indigo[900])),
                                  ],
                                ),
                              ),
                            ]),
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
                                                        CrossAxisAlignment
                                                            .start,
                                                    children: [
                                                      SizedBox(height: 4),
                                                      Text(
                                                          "Meter Reading: ${punch["out_km"] ?? "N/A"}"),
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
                                                    fontWeight:
                                                        FontWeight.bold)),
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
            if (isLoading) const BookPageLoader(),
          ],
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
