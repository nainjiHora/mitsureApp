import 'dart:convert';
import 'dart:async';

import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:mittsure/field/agentlocation.dart';
import 'package:mittsure/field/newPunch.dart';
import 'package:mittsure/field/routes.dart';
import 'package:mittsure/newApp/allowances.dart';
import 'package:mittsure/newApp/animatedCircle.dart';
import 'package:mittsure/newApp/bookLoader.dart';
import 'package:mittsure/newApp/expenseList.dart';
import 'package:mittsure/newApp/myProfile.dart';
import 'package:mittsure/newApp/specimenList.dart';
import 'package:mittsure/newApp/specimenRequest.dart';
import 'package:mittsure/newApp/userRequests.dart';
import 'package:mittsure/newApp/visitScreen.dart';
import 'package:mittsure/screens/Party.dart';
import 'package:mittsure/screens/home.dart';
import 'package:mittsure/screens/login.dart';
import 'package:mittsure/screens/notifications.dart';
import 'package:mittsure/screens/orders.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../services/apiService.dart';

class MainMenuScreen extends StatefulWidget {
  @override
  _MainMenuScreenState createState() => _MainMenuScreenState();
}

class _MainMenuScreenState extends State<MainMenuScreen> {
  final GlobalKey<ScaffoldState> _scaffoldKey = GlobalKey<ScaffoldState>();
  bool isPunchedIn = false;
  List<dynamic> punches = [];
  bool flag = false;
  String? hours;
  String _username = "";
  Timer? _timer;
  var visitData = {};
  int _selectedIndex = 0;
  List<dynamic> config = [];
  bool isLoading = true;
  Map<String, dynamic> userData = {};
  Map<String, dynamic> unique = {};
  Duration currentSessionDuration = Duration.zero;

  String get greeting {
    final hour = DateTime.now().hour;
    if (hour < 12) {
      return "Good Morning";
    } else if (hour < 18) {
      return "Good Afternoon";
    } else {
      return "Good Evening";
    }
  }

  getUserData() async {
    final prefs = await SharedPreferences.getInstance();
    final a = prefs.getString('user');
    if (a != null && a.isNotEmpty) {
      setState(() {
        userData = jsonDecode(a);
        _username = (userData['name'] ?? "").toString();
        getRoutePartyCount(userData["id"]);
      });
      await _fetchWorkingHours();
      fetchdashboardtopTiles();
      _updatePunchStatus();
    }
  }

  @override
  void initState() {
    super.initState();

    getAttendanceConfig();
  }

  @override
  void dispose() {
    _timer?.cancel();
    super.dispose();
  }

  getRoutePartyCount(id) async {
    try {
      final response = await ApiService.post(
        endpoint: '/routePlan/getRoutesPartyCount',
        body: {"ownerId": userData['role']=='se'?id:"","rsm":userData['role']=='rsm'?id:'',"asm":userData['role']=='asm'?id:""},
      );

      if (response != null) {
        final data = response['data'];
        setState(() {
          visitData = data;
        });
      }
    } catch (error) {
      print("Error fetching working hours: $error");
    }
  }

  fetchdashboardtopTiles() async {
    try {
      final response = await ApiService.post(
        endpoint: '/visit/getCountVisit',
        body: {
          "ownerId": userData['role'] == 'se' ? userData['id'] : "",
          "rsm": userData['role'] == 'rsm' ? userData['id'] : "",
          "asm": userData['role'] == 'asm' ? userData['id'] : ""
        },
      );

      if (response != null && response['success'] == true) {
        final data = response['data'];
        setState(() {
          print(data);
          setState(() {
            unique = data;
          });
        });
      }
    } catch (error) {
      print("Error fetching working hours: $error");
    }
  }

  getAttendanceConfig() async {
    try {
      final response = await ApiService.post(
        endpoint: '/attendance/getAttendanceConfig',
        body: {},
      );

      if (response != null) {
        final data = response['data'];
        setState(() {
          print(data);
          config = data;
          getUserData();
        });
      }
    } catch (error) {
      print("Error fetching working hours: $error");
    }
  }

  Future<void> _fetchWorkingHours() async {
    DateTime now = DateTime.now();
    String formattedDate = DateFormat('yyyy-MM-dd').format(now);
    final body = {
      "userId": userData['id'],
      "date": formattedDate,
    };

    try {
      final response = await ApiService.post(
        endpoint: '/attendance/getAttendanceDetailsByDate',
        body: body,
      );

      if (response != null) {
        final data = response['data'];

        final punchRecords = data['inOutHistory'] ?? [];
        setState(() {
          punches = punchRecords;
        });
        _updatePunchStatus();
      }
    } catch (error) {
      print("Error fetching working hours: $error");
    }
  }

  void _updatePunchStatus() {
    bool punchedIn = false;
    DateTime now = DateTime.now();
    for (var record in punches) {
      String? outTimeStr = record['out_time'];
      if (outTimeStr == null || outTimeStr.isEmpty) {
        punchedIn = true;
        break;
      }
    }
    setState(() {
      isPunchedIn = punchedIn;
      isLoading = false;
    });
  }

  void togglePunch() async {
    await Navigator.push(
      context,
      MaterialPageRoute(
          builder: (context) => PunchScreen(
                mark: true,
              )),
    );
    await _fetchWorkingHours();
  }

  String formatDuration(Duration d) {
    return "${d.inHours.toString().padLeft(2, '0')}:"
        "${(d.inMinutes % 60).toString().padLeft(2, '0')}:"
        "${(d.inSeconds % 60).toString().padLeft(2, '0')}";
  }

  Duration get totalWorkedDuration {
    Duration total = Duration.zero;
    DateTime now = DateTime.now();
    for (var record in punches) {
      String? inTimeStr = record['in_time'];
      String? outTimeStr = record['out_time'];

      if (inTimeStr != null) {
        DateTime inTime = DateTime.parse(inTimeStr.replaceFirst(' ', 'T'));
        DateTime outTime = (outTimeStr != null)
            ? DateTime.parse(outTimeStr.replaceFirst(' ', 'T'))
            : now;

        if (outTime.isAfter(inTime)) {
          total += outTime.difference(inTime);
        }
      }
    }

    startTimer(total);
    return total;
  }

  Color getColorForAttendance(Duration duration) {
    // Convert config time string to Duration and sort descending
    List<Map<String, dynamic>> sortedConfig = List.from(config)
      ..sort((a, b) {
        Duration durA = _parseDuration(a['time']);
        Duration durB = _parseDuration(b['time']);
        return durB.compareTo(durA); // Sort descending
      });

    for (var entry in sortedConfig) {
      Duration threshold = _parseDuration(entry['time']);
      if (duration >= threshold) {
        return _hexToColor(entry['color']);
      }
    }

    // Default color if no match
    return Colors.red;
  }

  Duration _parseDuration(String timeStr) {
    final parts = timeStr.split(':').map(int.parse).toList();
    return Duration(hours: parts[0], minutes: parts[1], seconds: parts[2]);
  }

  Color _hexToColor(String hex) {
    hex = hex.replaceFirst('#', '');
    if (hex.length == 6) {
      hex = 'FF$hex'; // Add full opacity if not specified
    }
    return Color(int.parse(hex, radix: 16));
  }

  void startTimer(Duration initialDuration) {
    stopTimer();
    currentSessionDuration = initialDuration;
    _timer = Timer.periodic(Duration(seconds: 1), (_) {
      setState(() {
        currentSessionDuration += Duration(seconds: 1);
      });
    });
  }

  void stopTimer() {
    _timer?.cancel();
  }

  Color greetingIconColor(String greeting) {
    if (greeting == "Good Morning") return Colors.orange;
    if (greeting == "Good Afternoon") return Colors.blueGrey;
    return Colors.deepPurple;
  }

  @override
  Widget build(BuildContext context) {
    return Stack(children: [
      Scaffold(
        key: _scaffoldKey,
        drawer: _buildDrawer(),
        appBar: AppBar(
          iconTheme: IconThemeData(color: Colors.white),
          title: Text('Dashboard', style: TextStyle(color: Colors.white)),
          backgroundColor: Colors.indigo[900],
          elevation: 0,
        ),
        body: SingleChildScrollView(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Icon(
                    greeting == "Good Morning"
                        ? Icons.wb_sunny
                        : greeting == "Good Afternoon"
                            ? Icons.wb_cloudy
                            : Icons.nightlight_round,
                    color: greetingIconColor(greeting),
                    size: 28,
                  ),
                  SizedBox(width: 8),
                  Text(
                    "${greeting}, ${_username.split(' ')[0]}",
                    style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                  ),
                ],
              ),
              SizedBox(height: 10),
              _topStatsRow(),
              SizedBox(height: 18),
              Text("Attendance",
                  style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold)),
              SizedBox(height: 18),
              _attendanceSection(),
              SizedBox(height: 18),
              Text("Analysis",
                  style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold)),
              SizedBox(height: 14),
              _dashboardCards(),
            ],
          ),
        ),
        bottomNavigationBar: _buildBottomNavigationBar(),
      ),
      if (isLoading) const BookPageLoader(),
    ]);
  }

  Widget _topStatsRow() {
    return IntrinsicHeight(
      // Ensure all children have same height
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          _infoBox(
            title: "Party Assigned",
            topValue: unique['schoolCount'].toString() ?? "",
            bottomValue: unique['distributorCount'].toString() ?? "",
            icon: Icons.group,
          ),
          _infoBox(
            title: "Total Visits",
            topValue: unique['totalSchoolVisit'].toString() ?? "",
            bottomValue: unique['totalDistributorVisit'].toString() ?? "",
            icon: Icons.visibility,
          ),
          _infoBox(
            title: "Unique Visits",
            topValue: unique['totalSchoolDistinctVisit'].toString() ?? "",
            bottomValue:
                unique['totalDistributorDistinctVisit'].toString() ?? "",
            icon: Icons.person_outline,
          ),
        ],
      ),
    );
  }

  Widget _buildDrawer() {
    return Drawer(
      backgroundColor: Colors.grey[300],
      child: Column(
        children: [
          DrawerHeader(
            padding: const EdgeInsets.only(bottom: 0, left: 15, right: 15),
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: [Colors.indigo.shade900, Colors.indigo],
              ),
              borderRadius: BorderRadius.vertical(bottom: Radius.circular(20)),
            ),
            child: Column(
              children: [
                CircleAvatar(
                    radius: 32,
                    backgroundColor: Colors.white,
                    child:
                        Icon(Icons.person, size: 40, color: Colors.green[400])),
                SizedBox(height: 10),
                Text(_username.toUpperCase(),
                    style: TextStyle(
                        color: Colors.white,
                        fontSize: 18,
                        fontWeight: FontWeight.bold)),
              ],
            ),
          ),
          Expanded(
            child: ListView(
              padding: EdgeInsets.zero,
              children: [
                _drawerItem("Home", Icons.home, MainMenuScreen(), false),
                _drawerItem("My Profile", Icons.home, ProfilePage(), false),
                _drawerItem("Attendance", Icons.watch_later,
                    PunchScreen(mark: false), false),
                _drawerItem("Visit", Icons.place, VisitListScreen(), false),
                _drawerItem(
                    "Expenses",
                    Icons.request_quote,
                    ExpenseListScreen()
                    // MainMenuScreen()
                    ,
                    false),
                _drawerItem(
                    "Allowances",
                    Icons.request_quote,
                    // MainMenuScreen()
                    TravelAllowanceScreen(),
                    false),
                _drawerItem("Route Plan", Icons.route,
                    CreatedRoutesPage(userReq: false), false),
                _drawerItem("Party", Icons.group, PartyScreen(), false),
                _drawerItem(
                    "Orders",
                    Icons.money,
                    OrdersScreen(
                      userReq: false,
                    ),
                    false),
                _drawerItem(
                    "Specimen",
                    Icons.bookmarks_sharp,
                    SpecimenScreen()
                    // MainMenuScreen()
                    ,
                    false),
                if (userData['role'] != 'se')
                  _drawerItem("Approval Tray", Icons.approval_rounded,
                      RequestsScreen(), false),
                _drawerItem(
                    "Notifications",
                    Icons.notifications,
                    NotificationScreen()
                    // MainMenuScreen()
                    ,
                    false),
                // _drawerItem("Map", Icons.map, AgentsMapScreen()),
                Divider(thickness: 1),
                _drawerItem(
                    "Log Out", Icons.power_settings_new, LoginScreen(), true),
              ],
            ),
          ),
        ],
      ),
    );
  }

  void _logout(cont) {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: const Text("Logout"),
          content: const Text("Are you sure you want to logout?"),
          actions: [
            TextButton(
              onPressed: () {
                Navigator.of(context).pop(); // Close the dialog
              },
              child: const Text("Cancel"),
            ),
            TextButton(
              onPressed: () async {

                Navigator.of(context).pop();
                try {
                  setState(() {
                    isLoading=true;
                  });
                  final response = await ApiService.post(
                    endpoint: '/user/signout',
                    body: {},
                  );

                  if (response != null) {
                    final prefs = await SharedPreferences.getInstance();

                await prefs.remove("user");
                await prefs.remove("Token");
                await prefs.remove('vehicleType');
                Navigator.pushReplacement(
                  cont,
                  MaterialPageRoute(builder: (cont) => LoginScreen()),
                );
                  }
                } catch (error) {
                  print("Error in logout: $error");
                } // Close the dialog
               
              },
              child: const Text("Logout"),
            ),
          ],
        );
      },
    );
  }

  Widget _drawerItem(String title, IconData icon, Widget screen, bool logout) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 10.0, vertical: 2.0),
      child: Card(
        margin: EdgeInsets.zero,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
        elevation: 1,
        child: ListTile(
            dense: true,
            contentPadding: EdgeInsets.symmetric(horizontal: 12),
            leading: Icon(icon, color: Colors.indigo[700]),
            title: Text(title,
                style: TextStyle(fontSize: 15, fontWeight: FontWeight.w500)),
            trailing:
                Icon(Icons.arrow_forward_ios, size: 14, color: Colors.grey),
            onTap: () {
              if (!logout) {
                Navigator.push(
                    context, MaterialPageRoute(builder: (context) => screen));
              } else {
                _logout(context);
              }
            }),
      ),
    );
  }

  Widget _infoBox({
    required String title,
    required String topValue,
    required String bottomValue,
    required IconData icon,
  }) {
    return Expanded(
      child: Card(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        elevation: 4,
        margin: const EdgeInsets.all(8),
        child: Padding(
          padding: const EdgeInsets.all(12),
          child: Column(
            mainAxisAlignment: MainAxisAlignment
                .spaceBetween, // Ensure full vertical space is used
            children: [
              Column(
                children: [
                  // Icon(icon, size: 28, color: Colors.blueAccent),
                  // const SizedBox(height: 6),
                  Text(
                    title,
                    style: const TextStyle(fontWeight: FontWeight.bold),
                    textAlign: TextAlign.center,
                  ),
                  const Divider(thickness: 1.2),
                ],
              ),
              Column(
                children: [
                  const Text(
                    "School",
                    style: TextStyle(color: Colors.black87, fontSize: 14),
                  ),
                  Text(
                    topValue,
                    style: const TextStyle(color: Colors.black87, fontSize: 14),
                  ),
                  const SizedBox(height: 6),
                  const Text(
                    "Distributor",
                    style: TextStyle(color: Colors.black87, fontSize: 14),
                  ),
                  Text(
                    bottomValue,
                    style: const TextStyle(color: Colors.black87, fontSize: 14),
                  ),
                ],
              )
            ],
          ),
        ),
      ),
    );
  }

  Widget _attendanceSection() {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceEvenly,
      children: [
        AnimatedCircleTimer(
            time: formatDuration(totalWorkedDuration),
            hours: getColorForAttendance(totalWorkedDuration),
            flag: isPunchedIn),
        ElevatedButton.icon(
          style: ElevatedButton.styleFrom(
            backgroundColor: isPunchedIn ? Colors.red : Colors.green[700],
            padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 14),
            shape:
                RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
          ),
          onPressed: togglePunch,
          icon: Icon(isPunchedIn ? Icons.logout : Icons.login,
              color: Colors.white),
          label: Text(isPunchedIn ? 'Punch Out' : 'Punch In',
              style: TextStyle(color: Colors.white)),
        ),
      ],
    );
  }

  Widget _buildBottomNavigationBar() {
    return BottomAppBar(
      shape: CircularNotchedRectangle(),
      notchMargin: 3.0,
      color: Colors.indigo[900],
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceAround,
        children: <Widget>[
          _bottomNavIcon(Icons.account_tree, 'Visits', 0, VisitListScreen()),
          _bottomNavIcon(Icons.route_outlined, 'Routes', 1,
              CreatedRoutesPage(userReq: false)),
          _bottomNavIcon(
              Icons.menu, 'Menu', 2, CreatedRoutesPage(userReq: false)),
          _bottomNavIcon(Icons.group_add, 'Party', 3, PartyScreen()),
          _bottomNavIcon(
              Icons.monetization_on_rounded,
              'Sales',
              4,
              OrdersScreen(
                userReq: false,
              )),
        ],
      ),
    );
  }

  Widget _bottomNavIcon(IconData icon, String label, int index, screen) {
    return GestureDetector(
      onTap: () {
        if (index == 2) {
          _scaffoldKey.currentState?.openDrawer();
        } else {
          Navigator.push(
              context, MaterialPageRoute(builder: (context) => screen));
        }
      },
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 2, horizontal: 12),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icon, color: Colors.white),
            Text(label, style: TextStyle(color: Colors.white, fontSize: 12)),
          ],
        ),
      ),
    );
  }

  Widget _dashboardCards() {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceEvenly,
      children: [
        _analysisCard(
            'Scheduled ',
            visitData['totalPrtyCount'] == null
                ? '0'
                : visitData['totalPartyCount'].toString(),
            Icons.star),
        _analysisCard(
            'Completed ',
            visitData['visitedCount'] == null
                ? '0'
                : visitData['visitedCount'].toString(),
            Icons.directions_walk),
        _analysisCard(
            'Running ',
            visitData['runningVisitCount'] == null
                ? '0'
                : visitData['runningVisitCount'].toString(),
            Icons.run_circle_outlined),
        _analysisCard(
            'Pending ',
            visitData['notVisitedCount'] == null
                ? '0'
                : visitData['notVisitedCount'].toString(),
            Icons.pending_actions),
      ],
    );
  }

  Widget _analysisCard(String title, String value, IconData icon) {
    return Expanded(
      child: Card(
        elevation: 3,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        child: Padding(
          padding: const EdgeInsets.all(12),
          child: Column(
            children: [
              Icon(icon, size: 30, color: Colors.green.shade400),
              SizedBox(height: 8),
              Text(value,
                  style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold)),
              SizedBox(height: 4),
              Text(title,
                  style: TextStyle(fontSize: 10, fontWeight: FontWeight.w500)),
              Text("Visits",
                  style: TextStyle(fontSize: 10, fontWeight: FontWeight.w500)),
            ],
          ),
        ),
      ),
    );
  }
}
