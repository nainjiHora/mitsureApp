import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:mittsure/field/requestPartyDetail.dart';
import 'package:mittsure/field/schoolReqdetail.dart';
import 'package:mittsure/newApp/addDistributor.dart';
import 'package:mittsure/newApp/addSchool.dart';
import 'package:mittsure/newApp/bookLoader.dart';
import 'package:mittsure/screens/commonLayout.js.dart';
import 'package:mittsure/screens/newOrder.dart';
import 'package:mittsure/screens/partyDetail.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../services/apiService.dart';

class PartyReqScreen extends StatefulWidget {
  const PartyReqScreen({super.key});

  @override
  State<PartyReqScreen> createState() => _PartyReqScreenState();
}

class _PartyReqScreenState extends State<PartyReqScreen> {
  Map<String, dynamic> userData = {};
  List<dynamic> parties = [];
  String selectedASM = "";
  List<dynamic> asmList = [];
  String selectedRsm = "";
  List<dynamic> rsmList = [];
  String selectedSE = "";
  List<dynamic> seList = [];
  String pageSize = "15";
  String selectedFilter = 'school';
  String searchKeyword = '';
  int currentPage = 1;
  int totalCount = 0;
  bool isLoading = false;
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

          _fetchOrders(currentPage);
        });
      } else {
        throw Exception('Failed to load orders');
      }
    } catch (error) {
      print("Error fetching ojbjbjbjjrders: $error");
    } finally {}
  }

  _fetchAsm(id) async {
    setState(() {
      isLoading = true;
    });
    _fetchOrders(currentPage);
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
        });
      }
    } catch (error) {
      print("Error fetching ojbjbjbjjrders: $error");
    } finally {}
  }

  _fetchSe(id) async {
    _fetchOrders(currentPage);
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

  getUserData() async {
    final prefs = await SharedPreferences.getInstance();
    final a = prefs.getString('user');
    if (a!.isNotEmpty) {
      setState(() {
        userData = jsonDecode(a ?? "");

        if (userData['role'] == 'se') {
          selectedSE = userData['id'];
          _fetchOrders(currentPage);
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

  @override
  void initState() {
    super.initState();
    getUserData();
  }

  Future<void> _fetchOrders(int pageNumber, {String? filter}) async {
    setState(() {
      isLoading = true;
    });

    final body = {
      "pageNumber": pageNumber - 1,
      "request_type_id": 30,
      "recordPerPage": pageSize,
      "ownerName": selectedSE,
      "rsm": selectedRsm,
      "asm": selectedASM,
      "status":0
    };

    try {
      final response = await ApiService.post(
        endpoint: '/party/getRequestTableList',
        body: body,
      );

      if (response != null && response['status'] == true) {
        final data = response['data'];
       
        setState(() {
          totalCount = response['data1'];
          parties = data;
          isLoading = false;
        });
      } else {
        throw Exception('Failed to load orders');
      }
    } catch (error) {
      print("Error fetchidddddng orders: $error");
    } finally {
      setState(() {
        isLoading = false;
      });
    }
  }

  bool hasRole(String targetRole) {
    final role = userData['role'];
    if (role == null) return false;
    return role.toString().contains(targetRole);
  }

  void _updatePageSize(String newSize) {
    setState(() {
      pageSize = newSize;
      currentPage = 1; // Reset to the first page
      parties.clear(); // Clear the current list
    });
    _fetchOrders(currentPage);
  }

  int get totalPages => (totalCount / int.parse(pageSize)).ceil();

  Widget _buildPagination() {
    int startRecord = ((currentPage - 1) * int.parse(pageSize)) + 1;
    int endRecord =
        (startRecord + int.parse(pageSize) - 1).clamp(1, totalCount);

    return Column(
      children: [
        // Showing Records Range
        Padding(
          padding: const EdgeInsets.symmetric(vertical: 5),
          child: Text(
            "Showing $startRecord-$endRecord of $totalCount records",
            style: TextStyle(fontWeight: FontWeight.bold),
          ),
        ),
        // Pagination Controls
        SingleChildScrollView(
          scrollDirection: Axis.horizontal, // Enable horizontal scrolling
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: List.generate(totalPages, (index) {
              final pageNumber = index + 1;
              return GestureDetector(
                onTap: () {
                  setState(() {
                    currentPage = pageNumber;
                  });
                  _fetchOrders(pageNumber, filter: searchKeyword);
                },
                child: Container(
                  margin: EdgeInsets.symmetric(horizontal: 5),
                  padding: EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color:
                        currentPage == pageNumber ? Colors.blue : Colors.white,
                    border: Border.all(color: Colors.blue),
                    borderRadius: BorderRadius.circular(4),
                  ),
                  child: Text(
                    pageNumber.toString(),
                    style: TextStyle(
                      color: currentPage == pageNumber
                          ? Colors.white
                          : Colors.blue,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
              );
            }),
          ),
        )
      ],
    );
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        // Filter Buttons

        userData['role'] != 'se'
            ? Row(
                children: [
                  SizedBox(
                    width: 5,
                  ),
                  hasRole('admin') || userData['role'] == 'zsm'
                      ? Expanded(
                          child: DropdownButtonFormField<String>(
                            value: selectedRsm,
                            decoration: InputDecoration(
                              labelText: 'Select VP',
                              border: OutlineInputBorder(),
                              contentPadding: EdgeInsets.symmetric(
                                  horizontal: 10, vertical: 8),
                            ),
                            style: TextStyle(fontSize: 14),
                            dropdownColor: Colors.white,
                            items: [
                              DropdownMenuItem<String>(
                                value: '', // Blank value for "All"
                                child: Text('All',
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
                              labelText: 'Select CH',
                              border: OutlineInputBorder(),
                              contentPadding: EdgeInsets.symmetric(
                                  horizontal: 10, vertical: 8),
                            ),
                            style: TextStyle(fontSize: 14),
                            dropdownColor: Colors.white,
                            items: [
                              DropdownMenuItem<String>(
                                value: '', // Blank value for "All"
                                child: Text('All',
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
                          child: Text('All',
                              style:
                                  TextStyle(fontSize: 14, color: Colors.black)),
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
                        _fetchOrders(currentPage);
                      },
                    ),
                  ),
                  SizedBox(
                    width: 5,
                  ),
                ],
              )
            : Container(),

        // Page Size Dropdown
        Row(
          mainAxisAlignment: MainAxisAlignment.end,
          children: [
            Text("Records per page: "),
            DropdownButton<String>(
              value: pageSize,
              items: ['15', '20', '25', '30']
                  .map((size) => DropdownMenuItem<String>(
                        value: size,
                        child: Text(size),
                      ))
                  .toList(),
              onChanged: (value) {
                if (value != null) {
                  _updatePageSize(value);
                }
              },
            ),
          ],
        ),
        // List of Parties
        if (isLoading)
          Center(child: BookPageLoader())
        else if (parties.isEmpty)
          Expanded(
            child: Center(
              child: Text(
                "No Party Request",
                style: TextStyle(fontWeight: FontWeight.bold, fontSize: 20),
              ),
            ),
          )
        else
          Expanded(
            child: ListView.builder(
              itemCount: parties.length,
              itemBuilder: (context, index) {
                final party = parties[index];
                return GestureDetector(
                  onTap: () {
                    if(party['partyType']=='distributor'){
                    Navigator.pushReplacement(
                      context,
                      MaterialPageRoute(
                        builder: (context) =>
                            RequestPartyDetailScreen(requestId: party['distributorID'],id:party['id']),
                      ),
                    );
                    }else{
                       Navigator.pushReplacement(
                      context,
                      MaterialPageRoute(
                        builder: (context) =>
                            RequestSchoolDetailScreen(requestId: party['schoolId'],id:party['id']),
                      ),
                    );
                    }
                  },
                  child: Card(
                    margin: EdgeInsets.symmetric(vertical: 8, horizontal: 16),
                    elevation: 3,
                    child: ListTile(
                      title: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            party['schoolId'] ?? party["distributorID"],
                            style: TextStyle(fontWeight: FontWeight.bold),
                          ),
                          Text(
                            party['schoolName'] ?? party['DistributorName'],
                            style: TextStyle(fontWeight: FontWeight.bold),
                          ),
                        ],
                      ),
                      subtitle: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                              'Party Type: ${party['partyType'].toString().toUpperCase()}'),
                        ],
                      ),
                      trailing:
                          Icon(Icons.arrow_forward_ios, color: Colors.grey),
                    ),
                  ),
                );
              },
            ),
          ),
        // Pagination Controls
        if (totalPages > 1)
          Padding(
            padding: const EdgeInsets.all(8.0),
            child: _buildPagination(),
          ),
      ],
    );
  }
}
