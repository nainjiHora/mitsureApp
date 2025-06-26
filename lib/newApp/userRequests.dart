import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:mittsure/services/apiService.dart';
import 'package:shared_preferences/shared_preferences.dart';



class RequestsScreen extends StatefulWidget {
  @override
  _RequestsScreenState createState() => _RequestsScreenState();
}

class _RequestsScreenState extends State<RequestsScreen> {
 
  String selectedFilter = '';
  String selectedASM = "";
  List<dynamic> asmList = [];
  String selectedRsm = "";
  List<dynamic> rsmList = [];
  String selectedSE = "";
  List<dynamic> seList = [];
  bool isLoading = false;

  List<dynamic> requestTypes = [
    {"id":"","name":"All"}
  ];

  List<dynamic> requests = [
  
  ];

   @override
  void initState() {
    // TODO: implement initState
    super.initState();
  getUserData();
  fetchPicklist();
  }

    fetchPicklist() async {
    final body = {};

    try {
      final response = await ApiService.post(
        endpoint: '/picklist/getRequestTypeList', // Use your API endpoint
        body: body,
      );
      if (response != null && response['status'] == true) {
        setState(() {
          requestTypes.addAll(response['data']);
        });
      } else {
        throw Exception('Failed to load orders');
      }
    } catch (error) {
      print("Error fetcffdfdhing orders: $error");
    }
  }

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
          fetchRequests();
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
          fetchRequests();
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
            fetchRequests();
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
            fetchRequests();
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



    fetchRequests() async {
      print("ADdada");
    final body = {
      "asm":selectedASM,
      "rsm":selectedRsm,
      "ownerName":selectedSE,
      "pageNumber":0,
      "recordPerPage":20,
      "request_type_id":selectedFilter 
         };

    try {
      
      final response = await ApiService.post(
        endpoint: '/party/getRequestTableList', // Use your API endpoint
        body: body,
      );
     
      if (response != null && response['status'] == true) {
        setState(() {
          requests.addAll(response['data']);
        });
      } else {
        throw Exception('Failed to load orders');
      }
    } catch (error) {
      print("Error fetcffdfdhing orders: $error");
    }
  }

  @override
  Widget build(BuildContext context) {
   

    return Scaffold(
      appBar: AppBar(
        title: Text('User Requests'),
      ),
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.all(8.0),
            child: DropdownButtonFormField<String>(
              value: selectedFilter,
              items: requestTypes.map((type) {
                return DropdownMenuItem<String>(
                  value: type['id'].toString(),
                  child: Text(type['name']),
                );
              }).toList(),
              decoration: InputDecoration(
                labelText: 'Filter by Request Type',
                border: OutlineInputBorder(),
              ),
              onChanged: (val) {
                setState(() {
                  selectedFilter = val!;
                  fetchRequests();
                });
              },
            ),
          ),
          Expanded(
            child: ListView.builder(
              itemCount: requests.length,
              itemBuilder: (context, index) {
                final request = requests[index];
                return Card(
                  margin: EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                  child: ListTile(
                    title: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                      Text('${request['employeeId']} '),
                      Text('${request['ownerName']}'),
                    ],),
                    subtitle: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                       if( request['min_time']!=null &&request['min_time']=='party')Text(request['min_time']!=null &&request['min_time']=='party'?request['schoolIdForLocation']??request['distributorIDforLocation']:" "),
                        Text(request['request_type_name']),
                      ],
                    ),
                    trailing: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        IconButton(
                          icon: Icon(Icons.visibility, color: Colors.blue),
                          onPressed: () {
                            _showRequestDetails(context, request);
                          },
                        ),
                        IconButton(
                          icon: Icon(Icons.check, color: Colors.green),
                          onPressed: () {
                            _handleAction(request, 'Approved');
                          },
                        ),
                        IconButton(
                          icon: Icon(Icons.close, color: Colors.red),
                          onPressed: () {
                            _handleAction(request, 'Rejected');
                          },
                        ),
                      ],
                    ),
                  ),
                );
              },
            ),
          ),
        ],
      ),
    );
  }

  void _showRequestDetails(BuildContext context,  request) {
    showDialog(
      context: context,
      builder: (_) => AlertDialog(
        title: Text('Request Details'),
        content: Text(request.details),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context), child: Text('Close')),
        ],
      ),
    );
  }

  void _handleAction( request, String action) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text('${request.userName}\'s request ${action.toLowerCase()}')),
    );
    // You can add API call or logic to approve/reject here.
  }
}
