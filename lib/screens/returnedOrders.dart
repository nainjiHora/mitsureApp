import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:mittsure/screens/commonLayout.js.dart';
import 'package:mittsure/screens/returnListItems.dart';
import 'package:mittsure/screens/returnParty.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../services/apiService.dart';
import 'login.dart';


class ReturnOrders extends StatefulWidget {
  const ReturnOrders({super.key});

  @override
  State<ReturnOrders> createState() => _ReturnOrdersState();
}

class _ReturnOrdersState extends State<ReturnOrders> {
  List<String> days = [];
  List<String> dates = [];
  String _selectedDate = DateFormat('yyyy-MM-dd').format(DateTime.now()); // Default to today's date
  List<dynamic> orders = [];

  @override
  void initState() {
    super.initState();
    _fetchReturnOrders(); // Fetch orders on screen load
  }

  Future<void> _fetchReturnOrders() async {
    final body = {};

    try {
      final response = await ApiService.post(
        endpoint: '/order/fetchReturnOrders', // Use your API endpoint
        body: body,
      );


      if (response != null) {
        final data = response['data'];
        setState(() {

          orders = data;
        });
      } else {
        throw Exception('Failed to load orders');
      }
    } catch (error) {
      print("Error fetching orders: $error");
    }
  }

  // Method to log out (can be customized as per your auth logic)
  void _logout() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.clear();
    Navigator.push(
      context,
      MaterialPageRoute(builder: (context) => LoginScreen()), // Route to LoginScreen
    );
  }

  @override
  Widget build(BuildContext context) {
    return CommonLayout(
      title: 'Returned Orders',
      currentIndex: 4,
      child: Scaffold(
        floatingActionButton: FloatingActionButton(
          onPressed: () {
            // Navigate to ReturnSearchParty screen
            Navigator.push(
              context,
              MaterialPageRoute(builder: (context) => ReturnSearchParty()), // Navigate to ReturnSearchParty
            );
          },
          child: Icon(Icons.add),
          tooltip: 'Return',
        ),
        body: Container(
          color: Colors.grey[100],
          child: Column(
            children: [
              orders.isEmpty
                  ? Center(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    SizedBox(height: 200),
                    Text("No orders", style: TextStyle(fontWeight: FontWeight.bold, fontSize: 20)),
                  ],
                ),
              )
                  : Expanded(
                child: ListView.builder(
                  itemCount: orders.length,
                  itemBuilder: (context, index) {
                    return GestureDetector(
                      onTap: () {
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (context) => ReturnOrderListScreen(id: orders[index]['returnOrderId']), // Route to ReturnOrderListScreen
                          ),
                        );
                      },
                      child: Card(
                        margin: EdgeInsets.symmetric(vertical: 8, horizontal: 16),
                        elevation: 3,
                        child: ListTile(
                          title: Text(
                            orders[index]['DistributorName'] ?? orders[index]['schoolName'],
                            style: TextStyle(fontWeight: FontWeight.bold),
                          ),
                          subtitle: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text('Return Request Date: ${DateFormat('dd MMM yyyy').format(DateTime.parse(orders[index]['createdAt'].toString()))}'),

                            ],
                          ),
                        ),
                      ),
                    );
                  },
                ),
              ),
            ],
          ),
        ),
      ),

    );
  }
}
