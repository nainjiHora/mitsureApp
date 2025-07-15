import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:mittsure/newApp/bookLoader.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../services/apiService.dart';

class TravelAllowanceScreen extends StatefulWidget {
  @override
  _TravelAllowanceScreenState createState() => _TravelAllowanceScreenState();
}

class _TravelAllowanceScreenState extends State<TravelAllowanceScreen>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;
  DateTimeRange? _dateRange;
  final today = DateTime.now();

  List<dynamic> taData = [];
  List<dynamic> daData = [];
  String selectedASM = "";
  List<dynamic> asmList = [];
  String selectedRsm = "";
  List<dynamic> rsmList = [];
  String selectedSE = "";
  List<dynamic> seList = [];

  bool isLoading = false;
  var userData = {};

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
    _setDefaultDateRange();
    _tabController.addListener(() {
      if (_tabController.indexIsChanging) return;
      if (_dateRange != null) {
        if (_tabController.index == 0) {
          fetchTAdata();
        } else {
          fetchDAdata();
        }
      }
    });

    getUserData();
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
          if (_tabController.index == 0) {
            fetchTAdata();
          } else {
            fetchDAdata();
          }
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
          isLoading = false;
        });
      } else {
        throw Exception('Failed to load orders');
      }
    } catch (error) {
      print("Error fetching ojbjbjbjjrders: $error");
    } finally {}
  }

  getAdminFilters() {
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
                        if (selectedSE != null && selectedSE != "") {
                          if (_tabController.index == 0) {
                            fetchTAdata();
                          } else {
                            fetchDAdata();
                          }
                        }
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
        )
      ],
    );
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
          isLoading = false;
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

  void _setDefaultDateRange() {
    final day = today.day;
    if (day >= 16) {
      _dateRange = DateTimeRange(
        start: DateTime(today.year, today.month, 16),
        end: DateTime(today.year, today.month + 1, 0),
      );
    } else {
      _dateRange = DateTimeRange(
        start: DateTime(today.year, today.month, 1),
        end: DateTime(today.year, today.month, 15),
      );
    }

    fetchTAdata();
    fetchDAdata();
  }

  fetchTAdata() async {
    setState(() => isLoading = true);
    try {
      final response = await ApiService.post(
        endpoint: '/expense/getExpenseTA',
        body: {
          "userId": selectedSE,
          "rsm":selectedRsm,
          "asm":selectedASM,
          "fromDate":
              "${_dateRange!.start.year}-${_dateRange!.start.month}-${_dateRange!.start.day}",
          "toDate":
              "${_dateRange!.end.year}-${_dateRange!.end.month}-${_dateRange!.end.day}",
        },
      );
      if (response != null) {
        final data = response['data'];
        print(data);
        setState(() => taData = data);
      }
    } catch (error) {
      debugPrint("Error fetching TA data: $error");
    } finally {
      setState(() => isLoading = false);
    }
  }

  fetchDAdata() async {
    setState(() => isLoading = true);
    try {
      final response = await ApiService.post(
        endpoint: '/expense/getExpenseDA',
        body: {
         "userId": selectedSE,
          "rsm":selectedRsm,
          "asm":selectedASM,
          "fromDate":
              "${_dateRange!.start.year}-${_dateRange!.start.month}-${_dateRange!.start.day}",
          "toDate":
              "${_dateRange!.end.year}-${_dateRange!.end.month}-${_dateRange!.end.day}",
        },
      );
      if (response != null) {
        final data = response['data'];
        print(data);
        setState(() => daData = data);
      }
    } catch (error) {
      debugPrint("Error fetching DA data: $error");
    } finally {
      setState(() => isLoading = false);
    }
  }

  Future<void> _pickDateRange() async {
    final picked = await showDateRangePicker(
      context: context,
      firstDate: DateTime(today.year - 1),
      lastDate: DateTime(today.year + 1),
      initialDateRange: _dateRange,
    );
    if (picked != null) {
      setState(() => _dateRange = picked);

      if (_tabController.index == 0) {
        fetchTAdata();
      } else {
        fetchDAdata();
      }
    }
  }

  String formatDateFromString(String dateStr) {
    final parsedDate = DateTime.parse(dateStr);
    return DateFormat('dd-MMM-yyyy').format(parsedDate);
  }

  String formatDate(DateTime date) => DateFormat('dd MMM yyyy').format(date);

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.grey.shade100,
      appBar: AppBar(
        backgroundColor: Colors.indigo.shade700,
        title: const Text(
          "Travel & Daily Allowances",
          style: TextStyle(color: Colors.white),
        ),
        iconTheme: const IconThemeData(color: Colors.white),
        bottom: TabBar(
          labelColor: Colors.white,
          indicatorColor: Colors.white,
          unselectedLabelColor: Colors.white70,
          controller: _tabController,
          tabs: const [
            Tab(text: "Travel Allowance"),
            Tab(
              text: "Daily Allowance",
            ),
          ],
        ),
      ),
      body: Column(
        children: [
          getAdminFilters(),
          Container(
            margin: const EdgeInsets.all(12),
            alignment: Alignment.centerLeft,
            child: ElevatedButton.icon(
              onPressed: _pickDateRange,
              icon: const Icon(Icons.calendar_today),
              label: Text(
                _dateRange != null
                    ? '${formatDate(_dateRange!.start)} - ${formatDate(_dateRange!.end)}'
                    : 'Select Date Range',
                style: const TextStyle(fontSize: 14),
              ),
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.white,
                foregroundColor: Colors.indigo.shade700,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(30),
                ),
                elevation: 2,
              ),
            ),
          ),
          if (isLoading)
            const Expanded(
              child: Center(child: BookPageLoader()),
            )
          else
            Expanded(
              child: TabBarView(
                controller: _tabController,
                children: [
                  _buildTAList(taData),
                  _buildDAList(daData),
                ],
              ),
            ),
        ],
      ),
    );
  }

  Widget _buildTAList(List<dynamic> data) {
  if (data.isEmpty) return _buildNoRecordsWidget("No TA records found.");

  return ListView.builder(
    padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
    itemCount: data.length,
    itemBuilder: (context, index) {
      final item = data[index];
      return Card(
        elevation: 2,
        margin: const EdgeInsets.only(bottom: 12),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(12),
        ),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Header Row
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    "TA Entry #${index + 1}",
                    style: const TextStyle(
                      fontWeight: FontWeight.w600,
                      fontSize: 16,
                    ),
                  ),
                  Text(
                    formatDateFromString(item['visitDate']),
                    style: TextStyle(
                      fontSize: 13,
                      color: Colors.grey.shade700,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 8),
              userData['role']!='se'? Text(
                    item['name']??"",
                    style: const TextStyle(
                      fontWeight: FontWeight.w600,
                      fontSize: 14,
                    ),
                  ):Container(),
              Divider(color: Colors.grey.shade300, thickness: 1),
              const SizedBox(height: 12),

              // Real Tabular Layout
              Table(
                border: TableBorder.all(color: Colors.grey.shade300),
                columnWidths: const {
                  0: FlexColumnWidth(),
                  1: FlexColumnWidth(),
                },
                children: [
                  // Header Row
                  const TableRow(
                    decoration: BoxDecoration(color: Color(0xFFEFEFEF)),
                    children: [
                      Padding(
                        padding: EdgeInsets.all(8.0),
                        child: Text(
                          "User Input KM",
                          style: TextStyle(fontWeight: FontWeight.bold),
                        ),
                      ),
                      Padding(
                        padding: EdgeInsets.all(8.0),
                        child: Text(
                          "System Generated KM",
                          style: TextStyle(fontWeight: FontWeight.bold),
                        ),
                      ),
                    ],
                  ),
                  // Data Row
                  TableRow(
                    children: [
                      Padding(
                        padding: const EdgeInsets.all(8.0),
                        child: Text(
                          "${item['km_difference']}",
                          softWrap: true,
                        ),
                      ),
                      Padding(
                        padding: const EdgeInsets.all(8.0),
                        child: Text(
                          "${item['systemGenerated_distance']}",
                          softWrap: true,
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ],
          ),
        ),
      );
    },
  );
}


  Widget _infoRow({
    required IconData icon,
    required String label,
    required String value,
  }) {
    return Row(
      children: [
        Icon(icon, color: Colors.indigo, size: 20),
        const SizedBox(width: 12),
        Expanded(
          child: Text(
            label,
            style: const TextStyle(
              fontSize: 14,
              color: Colors.black87,
            ),
          ),
        ),
        Text(
          value,
          style: const TextStyle(
            fontWeight: FontWeight.w600,
            fontSize: 14,
            color: Colors.black,
          ),
        ),
      ],
    );
  }

 Widget _buildDAList(List<dynamic> data) {
  if (data.isEmpty) return _buildNoRecordsWidget("No DA records found.");

  return ListView.builder(
    padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
    itemCount: data.length,
    itemBuilder: (context, index) {
      final item = data[index];

      final cityCategory = item['city'] == null || item['city'] == 'null'
          ? ''
          : (jsonDecode(item['city'])['category'] ?? '');

      return Card(
        elevation: 2,
        margin: const EdgeInsets.only(bottom: 12),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(12),
        ),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Header Row
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    "DA Entry #${index + 1}",
                    style: const TextStyle(
                      fontWeight: FontWeight.w600,
                      fontSize: 16,
                    ),
                  ),
                  Text(
                    formatDateFromString(item['attendanceDate']),
                    style: TextStyle(
                      fontSize: 13,
                      color: Colors.grey.shade700,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 8),
              userData['role']!='se'? Text(
                    item['name']??"",
                    style: const TextStyle(
                      fontWeight: FontWeight.w600,
                      fontSize: 14,
                    ),
                  ):Container(),
              Divider(color: Colors.grey.shade300, thickness: 1),
              const SizedBox(height: 12),

              // Real Tabular Layout (2 columns)
              Table(
                border: TableBorder.all(color: Colors.grey.shade300),
                columnWidths: const {
                  0: FlexColumnWidth(),
                  1: FlexColumnWidth(),
                },
                children: [
                  // Header Row
                  const TableRow(
                    decoration: BoxDecoration(color: Color(0xFFEFEFEF)),
                    children: [
                      Padding(
                        padding: EdgeInsets.all(8.0),
                        child: Text(
                          "Visit Type",
                          style: TextStyle(fontWeight: FontWeight.bold),
                        ),
                      ),
                      Padding(
                        padding: EdgeInsets.all(8.0),
                        child: Text(
                          "City Category",
                          style: TextStyle(fontWeight: FontWeight.bold),
                        ),
                      ),
                    ],
                  ),
                  // Data Row
                  TableRow(
                    children: [
                      Padding(
                        padding: const EdgeInsets.all(8.0),
                        child: Text(
                          item['visitType'] ?? '-',
                          softWrap: true,
                        ),
                      ),
                      Padding(
                        padding: const EdgeInsets.all(8.0),
                        child: Text(
                          cityCategory,
                          softWrap: true,
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ],
          ),
        ),
      );
    },
  );
}



  Widget _buildNoRecordsWidget(String message) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const Icon(Icons.info_outline, size: 48, color: Colors.grey),
          const SizedBox(height: 10),
          Text(message,
              style: const TextStyle(fontSize: 16, color: Colors.grey)),
        ],
      ),
    );
  }
}
