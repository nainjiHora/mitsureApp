import 'dart:convert'; // For decoding the JSON response
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:mittsure/newApp/MainMenuScreen.dart';
import 'package:mittsure/newApp/bookLoader.dart';
import 'package:mittsure/newApp/specimenRequest.dart';
import 'package:mittsure/newApp/specimenRequestList.dart';
import 'package:mittsure/newApp/specimendetailsscreen.dart';
import 'package:mittsure/services/pills.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../services/apiService.dart';

class SpecimenScreen extends StatefulWidget {
  final tab;
  SpecimenScreen({required this.tab});
  @override
  _SpecimenScreenState createState() => _SpecimenScreenState();
}

class _SpecimenScreenState extends State<SpecimenScreen> {
  List<String> days = [];
  int selectedFilter = 1;
  List<String> dates = [];
  String selectedASM = "";
  List<dynamic> asmList = [];
  int selectedTab = 1;
  String selectedRsm = "";
  List<dynamic> rsmList = [];
  String selectedSE = "";
  List<dynamic> seList = [];
  String _selectedDate = DateFormat('yyyy-MM-dd')
      .format(DateTime.now()); // Default to today's date
  List<dynamic> orders = [];
  int currentPage = 1;
  int totalCount = 0;
  String pageSize = "15";
  Map<String, List<Map<String, dynamic>>> filteredOrders = {};
  ScrollController _scrollController = ScrollController();
  Map<String, dynamic> userData = {};
  bool isLoading = false;

  void _updatePageSize(String newSize) {
    setState(() {
      pageSize = newSize;
      currentPage = 1;
      orders.clear();
    });
    _fetchOrders(currentPage, selectedFilter);
  }

  _updateFilter(val, status) {
    setState(() {
      selectedFilter = status;
    });
    _fetchOrders(1, status);
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

          _fetchOrders(currentPage, selectedFilter);
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
    _fetchOrders(currentPage, selectedFilter);
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
        });
      }
    } catch (error) {
      print("Error fetching ojbjbjbjjrders: $error");
    } finally {}
  }

  _fetchSe(id) async {
    _fetchOrders(currentPage, selectedFilter);
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

  getUserData() async {
    final prefs = await SharedPreferences.getInstance();
    final a = prefs.getString('user');
    if (a!.isNotEmpty) {
      setState(() {
        userData = jsonDecode(a ?? "");

        if (userData['role'] == 'se') {
          selectedSE = userData['id'];
          _fetchOrders(currentPage, selectedFilter);
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
    selectedTab = widget.tab;
    getUserData();
  }

  @override
  void dispose() {
    _scrollController.dispose(); // Dispose the scroll controller
    super.dispose();
  }

  // Initialize dates for the horizontal scroll
  void _initializeDates() {
    final DateTime now = DateTime.now();
    final DateTime startDate = now.subtract(Duration(days: 30));
    final DateTime endDate = now.add(Duration(days: 7));

    DateTime date = startDate;
    while (date.isBefore(endDate) || date.isAtSameMomentAs(endDate)) {
      dates.add(DateFormat('yyyy-MM-dd').format(date)); // Store full date
      days.add(DateFormat('EEE').format(date).toUpperCase()); // Store day name
      date = date.add(Duration(days: 1)); // Move to the next day
    }
  }

  // Method to handle date selection
  void _onDateSelected(String date) {
    setState(() {
      _selectedDate = date;
    });
    // _fetchOrders(currentPage,); // Fetch orders based on the selected date
  }

  bool hasRole(String targetRole) {
    final role = userData['role'];
    if (role == null) return false;
    return role.toString().contains(targetRole);
  }

  Map<String, List<Map<String, dynamic>>> groupBySeriesName(
      List<dynamic> data) {
    final Map<String, List<Map<String, dynamic>>> grouped = {};

    for (var item in data) {
      final seriesName = item['series_name'] ?? 'Unknown';

      if (!grouped.containsKey(seriesName)) {
        grouped[seriesName] = [];
      }

      grouped[seriesName]!.add(item);
    }

    return grouped;
  }

  Future<void> _fetchOrders(pageN, status) async {
    final body = {
      "pageNumber": pageN - 1,
      "approvalStatus": status,
      "recordPerPage": pageSize,
      "rsm": selectedRsm,
      "asm": selectedASM,
      "ownerId": userData['role'] == "se" ? userData['id'] : selectedSE
    };

    setState(() {
      isLoading = true;
    });

    String url = '';
    if (selectedTab == 1) {
      url = '/specimen/getMyAcceptedAllotSpecimens';
    } else if (selectedTab == 2) {
      url = '/specimen/getAllotSpecimens';
    } else if (selectedTab == 3) {
      url = '/specimen/getMyAllotSpecimens';
    }
    try {
      final response = await ApiService.post(
        endpoint: url, // Use your API endpoint
        body: body,
      );
      // Check if the response is valid
      if (response != null && response['success'] == true) {
        final data = response['data'];


        setState(() {
          orders = data;

          var a=groupBySeriesName(data);
print(a);
          filteredOrders = a;
          totalCount = response['data1'];
          isLoading = false;
        });
      } else {
        setState(() {
          isLoading = false;
        });
        throw Exception('Failed to load orders');
      }
    } catch (error) {
      setState(() {
        isLoading = false;
      });
      print("Error fetching ordersssssd: $error");
    }
  }

  getAppBarName(tab) {
    if (tab == 1) {
      return 'My Specimens';
    } else if (tab == 2) {
      return 'Distributed Specimens';
    } else {
      return 'Alloted Specimens';
    }
  }

  int get totalPages => (totalCount / int.parse(pageSize)).ceil();

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        backgroundColor: Colors.indigo[900],
        iconTheme: IconThemeData(color: Colors.white),
        title: Text(
          getAppBarName(widget.tab),
          style: TextStyle(color: Colors.white, fontSize: 20),
        ),
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
      body: Container(
        color: Colors.grey[100],
        child: Padding(
          padding: const EdgeInsets.symmetric(vertical: 12.0),
          child: Column(
            children: [
              // Row(
              //   children: [
              //     PillTab(label: "My Specimen",active:selectedTab==1,onTap: (){
              //       setState(() {
              //         selectedTab=1;
              //       });
              //       _fetchOrders(currentPage, selectedFilter);
              //     },),
              //     PillTab(label: "Distributed",active:selectedTab==2,onTap: (){
              //       setState(() {
              //         selectedTab=2;
              //       });
              //       _fetchOrders(currentPage, selectedFilter);
              //     }),
              //     PillTab(label: "Alloted Req",active:selectedTab==3,onTap: (){
              //       setState(() {
              //         selectedTab=3;
              //       });
              //       _fetchOrders(currentPage, selectedFilter);
              //     })
              //   ],
              // ),
              //
              // SizedBox(
              //   height: 15,
              // ),
              if (selectedTab == 2)
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
                                        child: Text('All',
                                            style: TextStyle(
                                                fontSize: 14,
                                                color: Colors.black)),
                                      ),
                                      ...rsmList.map((rsm) {
                                        return DropdownMenuItem<String>(
                                          value: rsm['id'].toString(),
                                          child: Text(rsm['name'],
                                              style: TextStyle(
                                                  fontSize: 14,
                                                  color: Colors.black)),
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
                                        child: Text('All',
                                            style: TextStyle(
                                                fontSize: 14,
                                                color: Colors.black)),
                                      ),
                                      ...asmList.map((rsm) {
                                        return DropdownMenuItem<String>(
                                          value: rsm['id'].toString(),
                                          child: Text(rsm['name'],
                                              style: TextStyle(
                                                  fontSize: 14,
                                                  color: Colors.black)),
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
              if (selectedTab == 2)
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
                                _fetchOrders(currentPage, selectedFilter);
                              },
                            ),
                          ),
                          SizedBox(
                            width: 5,
                          ),
                        ],
                      )
                    : Container(),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 5.0),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.start,
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
                  ),
                  if (selectedTab != 3)
                    ElevatedButton.icon(
                        onPressed: () {
                          if (selectedTab == 1) {
                            Navigator.push(
                                context,
                                MaterialPageRoute(
                                    builder: (context) => SpecimenReList(
                                        userReq: false,
                                        tab:
                                            selectedTab)) // remove all previous routes
                                );
                          } else {
                            Navigator.push(
                                context,
                                MaterialPageRoute(
                                    builder: (_) => SpecimenRequestScreen(
                                          seList: seList,
                                          tab: selectedTab,
                                        )));
                          }
                        },
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.green,   // <-- Green background
                          foregroundColor: Colors.white,   // <-- Icon & text color
                        ),
                        icon: Icon(Icons.add),
                        label:
                            Text(selectedTab == 2 ? "Distribute" : "Requests"))
                ],
              ),
              // List of Orders
              !isLoading
                  ? filteredOrders.isEmpty
                      ? Center(
                          child: Column(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              SizedBox(height: 200),
                              Text("No Items",
                                  style: TextStyle(
                                      fontWeight: FontWeight.bold,
                                      fontSize: 20)),
                            ],
                          ),
                        )
                      : Expanded(
                child: ListView(
                  children: filteredOrders.entries.map((entry) {
                    final seriesName = entry.key;
                    final orders = entry.value;

                    return Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        // ---------- SERIES HEADER ----------
                        Padding(
                          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                          child: Text(
                            seriesName.toString().toUpperCase(),
                            style: const TextStyle(
                              fontSize: 20,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ),

                        // ---------- LIST OF ORDERS ----------
                        ...orders.map((order) {
                          return Card(
                            elevation: 3,
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(12),
                            ),
                            margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                            child: InkWell(
                              borderRadius: BorderRadius.circular(12),
                              onTap: () {
                                Navigator.push(
                                  context,
                                  MaterialPageRoute(
                                    builder: (context) => SpecimenDetailsScreen(
                                      specimenDetails: order,
                                      tab: selectedTab,
                                    ),
                                  ),
                                );
                              },
                              child: Padding(
                                padding: const EdgeInsets.all(16),
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      order['nameSku']?.toString().toUpperCase() ?? '',
                                      style: const TextStyle(
                                        fontSize: 16,
                                        fontWeight: FontWeight.bold,
                                      ),
                                    ),
                                    const SizedBox(height: 8),
                                    Row(
                                      children: [
                                        Text(
                                          order['sku_code']?.toString().toUpperCase() ?? '',
                                          style: const TextStyle(
                                            fontSize: 16,
                                            fontWeight: FontWeight.w400,
                                          ),
                                        ),
                                        const SizedBox(width: 16),
                                        Text(
                                          "Quantity - ${order['quantity']}",
                                          style: const TextStyle(
                                            fontSize: 16,
                                            fontWeight: FontWeight.w400,
                                          ),
                                        ),
                                      ],
                                    ),
                                  ],
                                ),
                              ),
                            ),
                          );
                        }).toList()
                      ],
                    );
                  }).toList(),
                ),
              )
                  : Center(
                      child: BookPageLoader(),
                    ),
              if (totalPages > 1)
                Padding(
                  padding: const EdgeInsets.all(8.0),
                  child: _buildPagination(),
                ),
            ],
          ),
        ),
      ),
    );
  }

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
        Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: List.generate(totalPages, (index) {
            final pageNumber = index + 1;
            return GestureDetector(
              onTap: () {
                setState(() {
                  currentPage = pageNumber;
                });
                _fetchOrders(pageNumber, selectedFilter);
              },
              child: Container(
                margin: EdgeInsets.symmetric(horizontal: 5),
                padding: EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: currentPage == pageNumber ? Colors.blue : Colors.white,
                  border: Border.all(color: Colors.blue),
                  borderRadius: BorderRadius.circular(4),
                ),
                child: Text(
                  pageNumber.toString(),
                  style: TextStyle(
                    color:
                        currentPage == pageNumber ? Colors.white : Colors.blue,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
            );
          }),
        ),
      ],
    );
  }
}
