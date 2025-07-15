import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:mittsure/newApp/MainMenuScreen.dart';
import 'package:mittsure/newApp/visitDetailScreen.dart';
import 'package:mittsure/services/apiService.dart';
import 'package:mittsure/services/utils.dart';
import 'package:shared_preferences/shared_preferences.dart';

class VisitListScreen extends StatefulWidget {
  @override
  _VisitListScreenState createState() => _VisitListScreenState();
}

class _VisitListScreenState extends State<VisitListScreen> {
  DateTimeRange? _selectedDateRange;
  final DateFormat _dateFormat = DateFormat('dd-MM-yyyy');

  List<dynamic> visits = [];
  List<dynamic> yesterdayVisits = [];
  List<dynamic> previousVisits = [];
  Map<String, dynamic> userData = {};
  String selectedASM = "";
  List<dynamic> asmList = [];
  String selectedRsm = "";
  List<dynamic> rsmList = [];
  String selectedSE = "";
  List<dynamic> seList = [];

  bool isLoading = false;

  // Pagination
  int currentPage = 1;
  int totalPages = 1;
  final int recordPerPage = 20;
  int totalCount = 0;

  @override
  void initState() {
    super.initState();
    final today = DateTime.now();
    _selectedDateRange = DateTimeRange(start: today, end: today);
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

          fetchVisits();
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
    fetchVisits();
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
    fetchVisits();
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
          fetchVisits();
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

  fetchVisits() async {
    setState(() => isLoading = true);

    Map<String, dynamic> body = {
      "ownerName": selectedSE,
      "pageNumber": currentPage - 1,
      "recordPerPage": recordPerPage,
      "startDate": formatter.format(_selectedDateRange!.start),
      "endDate": formatter.format(_selectedDateRange!.end),
      "rsm": selectedRsm,
      "asm": selectedASM,
    };

    try {
      print(body);
      final response = await ApiService.post(
        endpoint: '/visit/fetchAllVisit',
        body: body,
      );

      if (response != null && response['status'] == false) {
        final data = response['data'];
        totalCount = response['data1'];
        totalPages = (totalCount / recordPerPage).ceil();

        final now = DateTime.now();
        final today = DateTime(now.year, now.month, now.day);

        setState(() {
          visits = data;
          yesterdayVisits.clear();
          previousVisits.clear();

          for (var visit in data) {
            final startTimeStr = visit['startTime'];
            if (startTimeStr == null) continue;

            final startTime = DateTime.tryParse(startTimeStr);
            if (startTime == null) continue;

            final visitDate =
                DateTime(startTime.year, startTime.month, startTime.day);

            if (visitDate == today) {
              yesterdayVisits.add(visit);
            } else if (visitDate.isBefore(today)) {
              previousVisits.add(visit);
            }
          }
        });
      } else {
        DialogUtils.showCommonPopup(
          context: context,
          message: response['message'],
          isSuccess: false,
        );
      }
    } catch (error) {
      print("Error fetching visits: $error");
    } finally {
      setState(() => isLoading = false);
    }
  }
 final DateFormat formatter = DateFormat('yyyy-MM-dd'); 
  void _pickDateRange() async {
    DateTimeRange? picked = await showDateRangePicker(
      context: context,
      firstDate: DateTime(2023),
      lastDate: DateTime.now().add(Duration(days: 365)),
      initialDateRange: _selectedDateRange,
    );

    if (picked != null) {
      setState(() {
        print(_selectedDateRange);
       
     
        _selectedDateRange = picked;

        fetchVisits();
      });
    }
  }

  Widget _buildVisitCard(dynamic visit) {
    final title = visit['schoolName'] ?? visit['DistributorName'] ?? 'Unnamed';
    final subtitle = visit['partyId']??"";
    final date = visit['startTime']??"";
    final parsedDate =date!=null?
        DateTime.parse(date).toLocal():null; 
    final formattedDate = parsedDate!=null? DateFormat('dd-MM-yyyy').format(parsedDate):"";

    return TweenAnimationBuilder(
      duration: Duration(milliseconds: 500),
      tween: Tween<Offset>(begin: Offset(1, 0), end: Offset(0, 0)),
      builder: (context, offset, child) {
        return Transform.translate(offset: offset * 20, child: child);
      },
      child: GestureDetector(
        onTap: () {
          Navigator.push(
            context,
            MaterialPageRoute(
              builder: (_) => VisitDetailsScreen(visitDetails: visit),
            ),
          );
        },
        child: Card(
          elevation: 4,
          margin: EdgeInsets.symmetric(vertical: 8),
          shape:
              RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
          child: Padding(
            padding: const EdgeInsets.all(12.0),
            child: ListTile(
              contentPadding: EdgeInsets.zero,
              leading: Icon(Icons.location_on, color: Colors.indigo, size: 28),
              title: Text(
                title,
                style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
              ),
              subtitle: subtitle != null
                  ? Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [Text(subtitle), Text(formattedDate)],
                    )
                  : null,
              trailing: Icon(Icons.arrow_forward_ios_rounded,
                  size: 16, color: Colors.grey[600]),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildPaginationControls() {
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        IconButton(
          icon: Icon(Icons.chevron_left),
          onPressed: currentPage > 1
              ? () {
                  setState(() {
                    currentPage--;
                  });
                  fetchVisits();
                }
              : null,
        ),
        Text(
          'Page $currentPage of $totalPages',
          style: TextStyle(fontSize: 16, fontWeight: FontWeight.w500),
        ),
        IconButton(
          icon: Icon(Icons.chevron_right),
          onPressed: currentPage < totalPages
              ? () {
                  setState(() {
                    currentPage++;
                  });
                  fetchVisits();
                }
              : null,
        ),
      ],
    );
  }

  @override
  Widget build(BuildContext context) {
    final dateFilterText = _selectedDateRange == null
        ? 'Select Date Range'
        : '${_dateFormat.format(_selectedDateRange!.start)} - ${_dateFormat.format(_selectedDateRange!.end)}';

    return Scaffold(
      appBar: AppBar(
        title: Text('Visits', style: TextStyle(color: Colors.white)),
        iconTheme: IconThemeData(color: Colors.white),
        backgroundColor: Colors.indigo[900],
        centerTitle: true,
        elevation: 4,
        actions: [
          IconButton(
            icon: const Icon(Icons.home, color: Colors.white),
            onPressed: () {
              Navigator.pushAndRemoveUntil(
                context,
                MaterialPageRoute(builder: (context) => MainMenuScreen()),
                (route) => false,
              );
            },
          ),
        ],
      ),
      body: Column(
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
                          fetchVisits();
                        },
                      ),
                    ),
                    SizedBox(
                      width: 5,
                    ),
                  ],
                )
              : Container(),
              SizedBox(height: 10,),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16.0),
            child: InkWell(
              onTap: _pickDateRange,
              borderRadius: BorderRadius.circular(12),
              child: Container(
                padding: EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                decoration: BoxDecoration(
                  border: Border.all(color: Colors.indigo),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(Icons.date_range, color: Colors.indigo),
                    SizedBox(width: 8),
                    Text(
                      dateFilterText,
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w600,
                        color: Colors.indigo[900],
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
          const SizedBox(height: 10),
          Divider(thickness: 1.2),
          Expanded(
            child: isLoading
                ? Center(child: CircularProgressIndicator())
                : (yesterdayVisits.isEmpty && previousVisits.isEmpty)
                    ? Center(
                        child: Text(
                          "No visits found.",
                          style: TextStyle(
                              fontSize: 16, fontWeight: FontWeight.w500),
                        ),
                      )
                    : ListView(
                        padding:
                            EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                        children: [
                          if (yesterdayVisits.isNotEmpty) ...[
                            Padding(
                              padding: const EdgeInsets.symmetric(vertical: 4),
                              child: Text(
                                "Today's Visits",
                                style: TextStyle(
                                  fontSize: 18,
                                  fontWeight: FontWeight.bold,
                                  color: Colors.indigo[800],
                                ),
                              ),
                            ),
                            ...yesterdayVisits
                                .map((v) => _buildVisitCard(v))
                                .toList(),
                          ],
                          if (previousVisits.isNotEmpty) ...[
                            Padding(
                              padding:
                                  const EdgeInsets.only(top: 16, bottom: 4),
                              child: Text(
                                "Previous Visits",
                                style: TextStyle(
                                  fontSize: 18,
                                  fontWeight: FontWeight.bold,
                                  color: Colors.indigo[800],
                                ),
                              ),
                            ),
                            ...previousVisits
                                .map((v) => _buildVisitCard(v))
                                .toList(),
                          ],
                          SizedBox(height: 12),
                          _buildPaginationControls(),
                        ],
                      ),
          ),
        ],
      ),
    );
  }
}
