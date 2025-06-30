import 'dart:convert';
import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';
import 'package:loading_animation_widget/loading_animation_widget.dart';
import 'package:mittsure/newApp/bookLoader.dart';
import 'package:mittsure/screens/Party.dart';
import 'package:mittsure/screens/collection.dart';
import 'package:mittsure/screens/incentiveScreen.dart';
import 'package:mittsure/screens/matchCard.dart';
import 'package:mittsure/screens/notifications.dart';
import 'package:mittsure/screens/orders.dart';
import 'package:mittsure/screens/pie.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:intl/intl.dart';
import '../services/apiService.dart';
import 'login.dart';
import 'returnedOrders.dart';

class HomePage extends StatefulWidget {
  @override
  State<HomePage> createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> {
  String incentive ='0.0';
  List<dynamic> incentu=[];
  final List<Map<String, dynamic>> menuItems = [

    {"title": "Party", "icon": 'assets/images/party.png', "route": PartyScreen(), "color": Colors.indigo[900],"disable":false},
    {"title": "Orders", "icon": 'assets/images/order.png', "route": OrdersScreen(userReq:false), "color": Colors.green,"disable":false},
    {"title": "Incentive Calculator", "icon": 'assets/images/incentive.png', "route": IncentiveScreen(), "color": Colors.indigo[900],"disable":false},
    {"title": "Notification", "icon": 'assets/images/notification.png', "route": NotificationScreen(), "color": Colors.green,"disable":false},

    {"title": "Collection", "icon": 'assets/images/money.png', "route": CollectionScreen(), "color": Colors.green,"disable":true},
    {"title": "Returned Orders", "icon": 'assets/images/download.png', "route": ReturnOrders(), "color": Colors.indigo[900],"disable":true},

  ];

  String _username = "Guest";
  String _currentDate = "";
  bool loading = false;
  double totalAmount=0;
  Map<String,dynamic> dashData={};
  Future<void> _refreshData() async {
    setState(() {
      loading = true;
    });

    await Future.wait([
      _fetchOrders(),
      _fetchIncentive(),
    ]);

    setState(() {
      loading = false;
    });
  }

  capitalize(value) {
    if (value.isNotEmpty) {
      List<dynamic> a = value.split('');
      a[0] = a[0].toUpperCase();
      return a.join('');
    } else {
      return '';
    }
  }

  void showComingSoonPopup(BuildContext context) {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: Text("Oops! Try again later! we're on it! 🔧"),

          actions: [
            TextButton(
              onPressed: () {
                Navigator.of(context).pop(); // Close the dialog
              },
              child: Text('OK'),
            ),
          ],
        );
      },
    );
  }

  Future<void> _fetchIncentive() async {
    final prefs = await SharedPreferences.getInstance();
    final hasData = prefs.getString('user') != null;
    var id = "";
    if (hasData) {
      id = jsonDecode(prefs.getString('user') ?? "")['id'];
    }
    final body = {"ownerId": id};

    try {
      setState(() {
        loading = true;
      });

      final response = await ApiService.post(
        endpoint: '/order/getGroupedIncentives',
        body: body,
      );

      if (response != null) {
        print(response['data']);
        if (response['code'] == 500) {
          _logout();
        }

        setState(() {
          List<dynamic> c=response['data'];
          List<dynamic> a=[];
          double yu=0;

          print("DASdaa");
          List<dynamic> b=response['series_name'];
          print(b.length);
          for(var i=0;i<b.length;i++){
            var obj={"series":b[i]['seriesName'],"amount":0,"color":b[i]['color']};
            for(var j=0;j<c.length;j++){
              

              if(c[j]['seriesId']==b[i]['seriesTableId']){
                obj['amount']=obj['amount']+c[j]['totalAmount'];
                yu+=c[j]['totalAmount'];
              }
            }
            a.add(obj);
          }

          loading = false;

         incentu=a;
         incentive=yu.toStringAsFixed(2);

        });
      } else {
        throw Exception('Failed to load orders');
      }
    } catch (error) {
      print("Error fetddching orders: $error");
    }
  }

  @override
  void initState() {
    super.initState();
    _loadUserData();
  getUserData();
    _getCurrentDate();
  }
  List<dynamic> orders=[];
  Map<String,dynamic> userData={};
  getUserData() async{
    final prefs = await SharedPreferences.getInstance();
    final a = prefs.getString('user') ;
    if(a!.isNotEmpty) {
      setState(() {
        userData = jsonDecode(a??"");
        _fetchOrders();
        _fetchIncentive();
      });
    }
  }

  Future<void> _fetchOrders() async {
    final body = {
      "ownerId":userData['id']
    };

    try {

      final response = await ApiService.post(
        endpoint: '/order/getOrderCountAndAmount',  // Use your API endpoint
        body: body,
      );


      if (response != null) {
        final  data = response['data'];

        setState(() {
          dashData=data;
        });
      } else {
        throw Exception('Failed to load orders');
      }
    } catch (error) {
      print("Error fetchingmmm orders: $error");
    }
  }

  Future<void> _loadUserData() async {
    final prefs = await SharedPreferences.getInstance();
    final userString = prefs.getString('user');
    if (userString != null) {
      try {
        final userMap = jsonDecode(userString);
        setState(() {
          _username = userMap['name'] ?? "Guest";
        });
      } catch (e) {
        print("Error decoding user data: $e");
      }
    }
  }

  void _getCurrentDate() {
    setState(() {
      _currentDate = DateFormat('dd MMMM yyyy').format(DateTime.now());
    });
  }
  final List<dynamic> counts=[
    {"title":"Total Orders","key":"","icon":'assets/images/totalOrders.png'},{"title":"Ordered Amount","key":"totalAmout","icon":'assets/images/orderedAmt.png'},{"title":"Incentive","key":"incentive","icon":'assets/images/in.png'}
  ];

  @override
  Widget build(BuildContext context) {
    final size = MediaQuery.of(context).size;

    return Scaffold(
      appBar: AppBar(
        leading: Icon(Icons.person_sharp, color: Colors.white),
        title: Text("$_currentDate | $_username", style: TextStyle(color: Colors.white, fontSize: 16)),
        backgroundColor: Colors.indigo[900],
        centerTitle: true,
        actions: [
          IconButton(
            icon: Icon(Icons.exit_to_app, color: Colors.white),
            onPressed: _logout,
          ),
        ],
      ),
      body: RefreshIndicator(
        onRefresh: _refreshData, // Call the refresh function
        child: loading
            ? Center(
          child: BookPageLoader(),
        )
            : SingleChildScrollView(
          physics: AlwaysScrollableScrollPhysics(), // Ensure scrolling is enabled
          child: Column(
            children: [
              Padding(
                padding: const EdgeInsets.symmetric(vertical: 12.0),
                child: Row(
                  children: [
                    Expanded(
                      flex: 2,
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                        children: List.generate(3, (index) {
                          final colors = [
                            Colors.blueAccent.withOpacity(0.9),
                            Colors.pinkAccent.withOpacity(0.9),
                            Colors.orangeAccent.withOpacity(0.9)
                          ];
                          return Container(
                            height: size.height * 0.1,
                            width: size.width * 0.5,
                            margin: EdgeInsets.symmetric(vertical: 5, horizontal: 10),
                            decoration: BoxDecoration(
                              color: colors[index],
                              borderRadius: BorderRadius.circular(10),
                              border: Border.all(color: Colors.black.withOpacity(0.2)),
                            ),
                            child: Center(
                              child: Column(
                                mainAxisAlignment: MainAxisAlignment.center,
                                children: [
                                  Row(
                                    mainAxisAlignment: MainAxisAlignment.center,
                                    children: [
                                      SizedBox(
                                        height: MediaQuery.of(context).size.height * 0.04,
                                        child: Image.asset(counts[index]['icon']),
                                      ),
                                      SizedBox(width: 5),
                                      Text(
                                        index == 1
                                            ? '₹'+dashData['totalAmountSum'].toString()??""
                                            : index == 2
                                            ? '₹'+incentive.toString()
                                            :dashData["totalOrders"].toString()??"",
                                        textAlign: TextAlign.center,
                                        style: TextStyle(
                                          fontSize: 15,
                                          fontWeight: FontWeight.bold,
                                          color: Colors.white,
                                        ),
                                      ),
                                    ],
                                  ),
                                  Text(
                                    counts[index]['title'],
                                    textAlign: TextAlign.center,
                                    style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: Colors.white),
                                  ),
                                ],
                              ),
                            ),
                          );
                        }),
                      ),
                    ),
                    Expanded(
                      flex: 3,
                      child: Column(
                        children: [
                          IncentivePieChart(incentu: incentu),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
              SizedBox(height: 20),
              GridView.builder(
                shrinkWrap: true,
                physics: NeverScrollableScrollPhysics(), // Prevent double scrolling
                padding: EdgeInsets.symmetric(horizontal: size.width * 0.05),
                gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                  crossAxisCount: 2,
                  crossAxisSpacing: 10,
                  mainAxisSpacing: 20,
                  childAspectRatio: 3 / 2,
                ),
                itemCount: menuItems.length,
                itemBuilder: (context, index) {
                  return GestureDetector(
                    onTap: () {
                      if (menuItems[index]["disable"]) {
                        showComingSoonPopup(context);
                      } else {
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (context) => menuItems[index]['route'],
                          ),
                        );
                      }
                    },
                    child: Card(
                      elevation: 5,
                      color: Colors.indigo[900],
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(10),
                      ),
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Image.asset(menuItems[index]['icon'], height: 50),
                          SizedBox(height: 5),
                          Text(
                            menuItems[index]["title"],
                            textAlign: TextAlign.center,
                            style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: Colors.white),
                          ),
                        ],
                      ),
                    ),
                  );
                },
              ),
            ],
          ),
        ),
      ),
    );
  }




  void _logout() {
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
                Navigator.of(context).pop(); // Close the dialog
                final prefs = await SharedPreferences.getInstance();
                await prefs.remove("user");
                await prefs.remove("Token");
                Navigator.pushReplacement(
                  context,
                  MaterialPageRoute(builder: (context) => LoginScreen()),
                );
              },
              child: const Text("Logout"),
            ),
          ],
        );
      },
    );
  }
}
