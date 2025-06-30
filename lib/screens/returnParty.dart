import 'package:flutter/material.dart';
import 'package:mittsure/screens/commonLayout.js.dart';
import 'package:mittsure/screens/login.dart';
import 'package:mittsure/screens/orderDetail.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../services/apiService.dart';

class ReturnSearchParty extends StatefulWidget {
  const ReturnSearchParty({super.key});

  @override
  State<ReturnSearchParty> createState() => _ReturnSearchPartyState();
}

class _ReturnSearchPartyState extends State<ReturnSearchParty> {
  List<dynamic> parties = [];
  String? selectedFilter; // Default to null for "Select Party Type"
  String? selectedParty;
  List<dynamic> orders = [];
  List<dynamic> filteredOrders = [];

  Future<void> fetchOr() async {
    final body = {
      "pageNumber": 0
    };

    try {
      final response = await ApiService.post(
        endpoint: '/order/fetchOrder',
        body: body,
      );

      if (response != null) {
        final data = response['data'];
        setState(() {
          orders = data;
          print(data);
        });
      } else {
        throw Exception('Failed to load orders');
      }
    } catch (error) {
      print("Error fetching orders: $error");
    }
  }

  @override
  void initState() {
    super.initState();
    fetchOr();
  }

  getOrder(value) {
    setState(() {
      filteredOrders = orders.where((element) => element[selectedFilter == 'school' ? 'schoolId' : 'distributorID'] == value && element['approvalStatus'] == 1).toList();
    });
  }

  String getStatus(int value) {
    switch (value) {
      case 1:
        return "Approved";
      case 0:
        return "Pending";
      case 2:
        return "Rejected";
      default:
        return "Pending";
    }
  }

  Color getColor(int value) {
    switch (value) {
      case 1:
        return Colors.green;
      case 0:
        return Colors.orangeAccent;
      case 2:
        return Colors.red;
      default:
        return Colors.orangeAccent;
    }
  }

  Future<void> _fetchOrders() async {
    final body = {
      "pageNumber": 0,
      "type": selectedFilter,
    };

    try {
      final response = await ApiService.post(
        endpoint: selectedFilter == 'school' ? '/party/getSchool' : '/party/getDistributor',
        body: body,
      );

      if (response != null) {
        final data = response['data'];
        setState(() {
          print(data);
          parties = data;
          selectedParty = null; // Reset party selection
        });
      } else {
        throw Exception('Failed to load parties');
      }
    } catch (error) {
      print("Error fetching orders: $error");
    }
  }

  void _logout() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.clear();
    Navigator.pushReplacement(
      context,
      MaterialPageRoute(builder: (context) => LoginScreen()),
    );
  }

  void _updateFilter(String? filter) {
    setState(() {
      filteredOrders=[];
      selectedFilter = filter;
    });
    _fetchOrders();
  }

  @override
  Widget build(BuildContext context) {
    return CommonLayout(
      currentIndex: 4,
        title: 'Return Order',
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          children: [
            // Filter Dropdown (Party Type)
            DropdownButtonFormField<String>(
              value: selectedFilter,
              hint: const Text("Select Party Type"),
              onChanged: (value) {
                _updateFilter(value);
              },
              items: const [
                DropdownMenuItem(
                  value: 'school',
                  child: Text('School'),
                ),
                DropdownMenuItem(
                  value: 'distributor',
                  child: Text('Distributor'),
                ),
              ],
              decoration: InputDecoration(
                border: OutlineInputBorder(borderRadius: BorderRadius.circular(8.0)),
                contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
              ),
            ),
            const SizedBox(height: 20),

            // Party Dropdown
            if (parties.isNotEmpty)
              DropdownButtonFormField<String>(
                value: selectedParty,
                hint: const Text("Select School/Distributor"),
                onChanged: (value) {
                  setState(() {
                    selectedParty = value;
                    getOrder(value);
                  });
                },
                items: parties.map<DropdownMenuItem<String>>((party) {
                  return DropdownMenuItem<String>(
                    value: party[selectedFilter == 'school' ? 'schoolId' : 'distributorId'].toString(),
                    child: Text(party[selectedFilter == 'school' ? 'schoolName' : 'DistributorName']),
                  );
                }).toList(),
                decoration: InputDecoration(
                  border: OutlineInputBorder(borderRadius: BorderRadius.circular(8.0)),
                  contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                ),
              )
            else
              const Text('No parties available for the selected filter'),

            const SizedBox(height: 20),

            // Orders List or No Orders Message
            filteredOrders.isEmpty
                ? Expanded(
              child: Center(
                child: Text(
                  "No orders",
                  style: TextStyle(fontWeight: FontWeight.bold, fontSize: 20),
                ),
              ),
            )
                : Expanded(
              child: ListView.builder(
                itemCount: filteredOrders.length,
                itemBuilder: (context, index) {
                  return GestureDetector(
                    onTap: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (context) => OrderDetailsScreen(order: filteredOrders[index],userReq: false,),
                        ),
                      );
                    },
                    child: Card(
                      margin: const EdgeInsets.symmetric(vertical: 8, horizontal: 16),
                      elevation: 3,
                      child: ListTile(
                        title: Text(
                          filteredOrders[index]['DistributorName'] ?? filteredOrders[index]['schoolName'],
                          style: const TextStyle(fontWeight: FontWeight.bold),
                        ),
                        subtitle: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text('Mobile: ${filteredOrders[index]['mobileNo']}'),
                            Text('Email: ${filteredOrders[index]['emailId']}'),
                            Text('Amount: Rs.${filteredOrders[index]['totalAmount']}'),
                          ],
                        ),
                        trailing: Container(
                          padding: const EdgeInsets.symmetric(vertical: 4, horizontal: 8),
                          decoration: BoxDecoration(
                            color: getColor(filteredOrders[index]['approvalStatus']),
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: Text(
                            getStatus(filteredOrders[index]['approvalStatus']),
                            style: const TextStyle(
                              color: Colors.white,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
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
    );
  }
}
