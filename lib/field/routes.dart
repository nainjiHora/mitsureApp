import 'dart:convert';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter/widgets.dart';
import 'package:mittsure/field/newPunch.dart';
import 'package:mittsure/newApp/MainMenuScreen.dart';
import 'package:mittsure/newApp/bookLoader.dart';
import 'package:mittsure/newApp/routeItems.dart';
import 'package:mittsure/services/apiService.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../services/utils.dart';
import 'createRoute.dart';
// ... import statements stay the same

class CreatedRoutesPage extends StatefulWidget {
  final bool userReq;
  const CreatedRoutesPage({super.key, required this.userReq});

  @override
  State<CreatedRoutesPage> createState() => _CreatedRoutesPageState();
}

class _CreatedRoutesPageState extends State<CreatedRoutesPage> {
  List<dynamic> routeList = [];
  int currentPage = 0;
  int perPage = 10;
  int selectedFilter = 0;
  int totalRecords = 0;
  Map<String, dynamic> userData = {};
  bool isLoading = true;
  final List<int> pageSizes = [5, 10, 20, 50];
  String selectedASM = "";
  List<dynamic> asmList = [];
  String selectedRsm = "";
  List<dynamic> rsmList = [];
  String selectedSE = "";
  List<dynamic> seList = [];

  @override
  void initState() {
    super.initState();
    getUserData();
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

          fetchRoutes();
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
    fetchRoutes();
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
    fetchRoutes();
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
        print(userData['role']);

        if (userData['role'] == 'se') {
          selectedSE = userData['id'];
          fetchRoutes();
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

  Future<void> fetchRoutes() async {


    setState(() {
      isLoading = true;
    });

    final body = {
      "pageNumber": currentPage,
      "recordPerPage": 20,
      "ownerName": selectedSE,
      "rsm": selectedRsm,
      "asm": selectedASM,
      "status": widget.userReq? selectedFilter:""
    };

    try {
      print(body);
      final response = await ApiService.post(
        endpoint: '/routePlan/getRoutePlan',
        body: body,
      );

      if (response != null && response['status'] == false) {
        setState(() {
          routeList = response['data'] ?? [];
          totalRecords = response['data1'] ?? 0;
          print(response["data1"]);
          print(response["data"][0]);
        });
      }
    } catch (error) {
      print("Error fetching routes: $error");
    } finally {
      setState(() {
        isLoading = false;
      });
    }
  }

  Widget _buildStatusBadge(dynamic item) {

    String label = 'Tagged Route';
    Color color = Colors.cyan;
    return  userData['id']==item['tagged_id']? Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: color.withOpacity(0.1),
        border: Border.all(color: color),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Text(
        label,
        style: TextStyle(
          color: color,
          fontSize: 12,
          fontWeight: FontWeight.bold,
        ),
      ),
    ):SizedBox(height: 0,);
  }

  Widget _buildFilterButton(String text, bool isSelected, VoidCallback onTap) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: EdgeInsets.symmetric(
            vertical: 2, horizontal: 15), // Increased padding
        margin: EdgeInsets.symmetric(
            vertical: 4, horizontal: 4), // Added margin for spacing
        decoration: BoxDecoration(
          color: isSelected ? Colors.blue : Colors.white,
          borderRadius: BorderRadius.circular(25), // More rounded edges
          border: Border.all(color: Colors.blue, width: 1.5), // Thicker border
          boxShadow: [
            if (isSelected)
              BoxShadow(
                color: Colors.blue.withOpacity(0.3),
                blurRadius: 8,
                spreadRadius: 1,
                offset: Offset(0, 3),
              ),
          ],
        ),
        child: Text(
          text,
          style: TextStyle(
            fontSize: 14, // Increased font size
            color: isSelected ? Colors.white : Colors.blue,
            fontWeight: FontWeight.w600,
          ),
        ),
      ),
    );
  }

  void onPageSizeChange(int size) {
    setState(() {
      perPage = size;
      currentPage = 0;
    });
    fetchRoutes();
  }

  void goToPage(int page) {
    setState(() {
      currentPage = page;
    });
    fetchRoutes();
  }

  List<dynamic> get todayRoutes {
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);

    return routeList.where((route) {
      print(route['date']);
      final dateStr = route['date'];
      final parsed = DateTime.tryParse(dateStr ?? '');
      if (parsed == null) return false;
      final dateOnly = DateTime(parsed.year, parsed.month, parsed.day);
      return dateOnly == today;
    }).toList();
  }

  List<dynamic> get upcomingRoutes {
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);

    return routeList.where((route) {
      final dateStr = route['date'];
      final parsed = DateTime.tryParse(dateStr ?? '');
      if (parsed == null) return false;
      final dateOnly = DateTime(parsed.year, parsed.month, parsed.day);
      return dateOnly.isAfter(today);
    }).toList();
  }

  Widget buildRouteCard(dynamic route) {
    final date = DateTime.tryParse(route['date'] ?? '') ?? DateTime.now();

    return GestureDetector(
      onTap: () {
        if (widget.userReq) {
        } else {
          Navigator.push(
            context,
            MaterialPageRoute(
              builder: (context) => ItemListPage(
                id: route['routeId'],
                
                date: route['date'],
                userReq: widget.userReq,
              ),
            ),
          );
        }
      },
      child: Container(
        margin: const EdgeInsets.only(bottom: 12),
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(16),
          boxShadow: [
            BoxShadow(
              color: Colors.indigo.withOpacity(0.1),
              blurRadius: 8,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        child: Row(
          children: [
            // Calendar Icon
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: Colors.indigo.shade50,
              ),
              child: const Icon(Icons.calendar_today, color: Colors.indigo),
            ),

            const SizedBox(width: 16),

            // Text content & icons in expanded section
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        "${date.day.toString().padLeft(2, '0')}-${date.month.toString().padLeft(2, '0')}-${date.year}",
                        style: const TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      _buildStatusBadge(route)
                    ],
                  ),
                  const SizedBox(height: 4),
                  Text(
                    userData['role'] == 'se'
                        ? "Tap to view details"
                        : (route['name'] ?? ''),
                    style: const TextStyle(fontSize: 14, color: Colors.black54),
                  ),
                ],
              ),
            ),

            // Action Icons
           widget.userReq? Row(
              children: [
                GestureDetector(
                    onTap: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (context) => ItemListPage(
                            id: route['routeId'],
                            date: route['date'],
                            
                            userReq: widget.userReq,
                          ),
                        ),
                      );
                    },
                    child: Icon(Icons.remove_red_eye,
                        color: Colors.indigo.shade600)),
                const SizedBox(width: 12),
                GestureDetector(
                  onTap: (){_approveRequest(route['routeId']);},
                  child: Icon(Icons.thumb_up_alt, color: Colors.green.shade600)),
              ],
            ):Container(),
          ],
        ),
      ),
    );
  }

  
  void _approveRequest(id) async {
    setState(() {
      isLoading = true;
    });
    try {
      final response = await ApiService.post(
        endpoint: '/routeplan/approvePartialRouteNotification',
        body: {
          "isDirectApproval": true,
          "approvalStatus": "1",
          "id": id
        },
      );
      setState(() {
        isLoading = false;
      });
      if (response != null && response['status'] == false) {
        DialogUtils.showCommonPopup(
            context: context, message: "Approved Sucessfully", isSuccess: true ,onOkPressed: (){getUserData();});

      }
    } catch (e) {
      print(e);
      DialogUtils.showCommonPopup(
          context: context, message: "Something Went Wrong", isSuccess: false);
    } finally {
      setState(() {
        isLoading = false;
      });
    }
  }

  _updateFilter(status) {
    setState(() {
      selectedFilter = status;
    });
    fetchRoutes();
  }

  @override
  Widget build(BuildContext context) {
    final totalPages = (totalRecords / perPage).ceil();

    return WillPopScope(
      onWillPop: () async {
        Navigator.pushAndRemoveUntil(
          context,
          MaterialPageRoute(builder: (context) => MainMenuScreen()),
          (route) => false,
        );
        return false; // Prevent default back navigation
      },
      child: Scaffold(
        backgroundColor: const Color(0xFFF9F9F9),
        appBar: widget.userReq
            ? null
            : AppBar(
                backgroundColor: Colors.indigo[900],
                title: const Text('Created Routes',
                    style: TextStyle(color: Colors.white)),
                iconTheme: const IconThemeData(color: Colors.white),
                actions: [
                  IconButton(
                    icon: const Icon(Icons.home),
                    onPressed: () {
                      Navigator.pushAndRemoveUntil(
                        context,
                        MaterialPageRoute(
                            builder: (context) => MainMenuScreen()),
                        (route) => false,
                      );
                    },
                  ),
                ],
              ),
        body: isLoading
            ? const Center(child: BookPageLoader())
            : Column(
                children: [
                  SizedBox(
                    height: 10,
                  ),
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
                                              fontSize: 14,
                                              color: Colors.black)),
                                    );
                                  }).toList(),
                                ],
                                onChanged: (value) {
                                  selectedSE = value ?? "";
                                  fetchRoutes();
                                },
                              ),
                            ),
                            SizedBox(
                              width: 5,
                            ),
                          ],
                        )
                      : Container(),
                  SizedBox(
                    height: 10,
                  ),
                  !widget.userReq
                      ? Container()
                      : Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            _buildFilterButton("Pending", selectedFilter == 0,
                                () {
                              _updateFilter(0);
                            }),
                            SizedBox(
                              width: 10,
                            ),
                            _buildFilterButton(
                                "Partially Approved", selectedFilter == 3, () {
                              _updateFilter(3);
                            }),
                          ],
                        ),
                  routeList.isEmpty
                      ? Column(
                          crossAxisAlignment: CrossAxisAlignment.center,
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Row(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                Icon(Icons.route, size: 80, color: Colors.grey),
                              ],
                            ),
                            SizedBox(height: 12),
                            Row(
                              crossAxisAlignment: CrossAxisAlignment.center,
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                Text("No routes found",
                                    style: TextStyle(
                                        color: Colors.grey, fontSize: 18)),
                              ],
                            ),
                          ],
                        )
                      : Expanded(
                          child: ListView(
                            padding: const EdgeInsets.fromLTRB(16, 8, 16, 80),
                            children: [
                              if (todayRoutes.isNotEmpty) ...[
                                const Padding(
                                  padding: EdgeInsets.symmetric(vertical: 8),
                                  child: Text("📅 Today's Routes",
                                      style: TextStyle(
                                          fontSize: 18,
                                          fontWeight: FontWeight.bold,
                                          color: Colors.indigo)),
                                ),
                                ...todayRoutes.map(buildRouteCard),
                              ],
                              if (upcomingRoutes.isNotEmpty) ...[
                                const Padding(
                                  padding: EdgeInsets.symmetric(vertical: 8),
                                  child: Text("🚀 Upcoming Routes",
                                      style: TextStyle(
                                          fontSize: 18,
                                          fontWeight: FontWeight.bold,
                                          color: Colors.indigo)),
                                ),
                                ...upcomingRoutes.map(buildRouteCard),
                              ],
                            ],
                          ),
                        ),
                  Padding(
                    padding: const EdgeInsets.symmetric(vertical: 4),
                    child: Column(
                      children: [
                        Text("Page ${currentPage + 1} of $totalPages",
                            style:
                                const TextStyle(fontWeight: FontWeight.w500)),
                        const SizedBox(height: 6),
                        Wrap(
                          spacing: 6,
                          children: List.generate(totalPages, (index) {
                            final isSelected = index == currentPage;
                            return ElevatedButton(
                              style: ElevatedButton.styleFrom(
                                backgroundColor: isSelected
                                    ? Colors.indigo
                                    : Colors.grey.shade300,
                                foregroundColor:
                                    isSelected ? Colors.white : Colors.black,
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(12),
                                ),
                                padding: const EdgeInsets.symmetric(
                                    horizontal: 14, vertical: 10),
                              ),
                              onPressed: () => goToPage(index),
                              child: Text('${index + 1}'),
                            );
                          }),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
        floatingActionButton: FloatingActionButton(
                backgroundColor: Colors.indigo[900],
                onPressed: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(builder: (_) => const CreateRoutePage()),
                  );
                },
                child: const Icon(
                  Icons.add,
                  color: Colors.white,
                ),
              )
            ,
      ),
    );
  }
}
