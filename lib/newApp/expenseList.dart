import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:mittsure/newApp/addExpense.dart';
import 'package:mittsure/newApp/expenseDetails.dart';
import 'package:mittsure/services/apiService.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../services/utils.dart';
import 'MainMenuScreen.dart';

class ExpenseListScreen extends StatefulWidget {
  @override
  _ExpenseListScreenState createState() => _ExpenseListScreenState();
}

class _ExpenseListScreenState extends State<ExpenseListScreen> {
  List<Map<String, dynamic>> filteredExpenses = [];
  bool isLoading = false;
  DateTime selectedDate = DateTime.now();
  DateTimeRange? _selectedDateRange;
  final DateFormat _dateFormat = DateFormat('dd-MM-yyyy');
  Map<String, dynamic> userData = {};

  String selectedASM = "";
  List<dynamic> asmList = [];
  String selectedRsm = "";
  List<dynamic> rsmList = [];
  String selectedSE = "";
  List<dynamic> seList = [];

  int pageNumber = 0;
  int recordPerPage = 20;
  int totalData = 0;

  @override
  void initState() {
    super.initState();
    final today = DateTime.now();
   
_selectedDateRange = DateTimeRange(
  start: today.subtract(const Duration(days: 6)),
  end: today,
);
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
    print(id);
    print("ppooiintt");
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
            var b=[{"id":userData['id'],"name":userData['name']}];

            final List<Map<String, dynamic>> castedData = List<Map<String, dynamic>>.from(data);
           b.addAll(castedData);
           seList=b;
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
      "pageNumber": pageNumber,
      "recordPerPage": recordPerPage,
      "startDate": formatter.format(_selectedDateRange!.start),
      "endDate": formatter.format(_selectedDateRange!.end),
      "rsm": selectedRsm,
      "asm": selectedASM,
    };

    try {
      print(body);
      final response = await ApiService.post(
        endpoint: '/expense/fetchExpenses',
        body: body,
      );

      if (response != null && response['status'] == false) {
        final data = List<Map<String, dynamic>>.from(response['data']);
        setState(() {
          totalData = response["data1"];
          print(data);
          filteredExpenses = data.map((item) {
            return {
              ...item,
              'date': DateTime.parse(item['date']),
              'createdAt': DateTime.parse(item['createdAt']),
            };
          }).toList();
        });
      } else {
          DialogUtils.showCommonPopup(
        context: context, message: response['message'], isSuccess: false);
      
      }
    } catch (error) {
      print("Error fetching visits: $error");
    } finally {
      setState(() => isLoading = false);
    }
  }

  void pickDate() async {
    DateTime? picked = await showDatePicker(
      context: context,
      initialDate: selectedDate,
      firstDate: DateTime(2020),
      lastDate: DateTime.now(),
    );

    if (picked != null) {
      setState(() {
        selectedDate = picked;
        pageNumber = 0;
      });
      fetchVisits();
    }
  }

  String getStatusLabel(status) {
    return status == "1"
        ? "Approved"
        : status == "2"
            ? "Rejected"
            : "Pending";
  }

  Color getStatusColor(status) {
    return status == "1"
        ? Colors.green
        : status == "0"
            ? Colors.orange
            : Colors.red;
  }

  int get totalPages =>
      (totalData / recordPerPage).ceil(); // 🔢 Calculate total pages

  void onPageChange(int index) {
    if (index != pageNumber) {
      setState(() {
        pageNumber = index;
      });
      fetchVisits();
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

  @override
  Widget build(BuildContext context) {
    final dateFilterText = _selectedDateRange == null
        ? 'Select Date Range'
        : '${_dateFormat.format(_selectedDateRange!.start)} - ${_dateFormat.format(_selectedDateRange!.end)}';
    return Scaffold(
      appBar: AppBar(
        title: Text("Expenses", style: TextStyle(color: Colors.white)),
        backgroundColor: Colors.indigo[900],
        iconTheme: IconThemeData(color: Colors.white),
        centerTitle: true,
        actions: [
          IconButton(
            icon: Icon(Icons.home),
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
          // 🔍 Date Filter
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
          SizedBox(
            height: 10,
          ),
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
          Padding(
            padding: EdgeInsets.all(12.0),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.end,
              children: [
                ElevatedButton.icon(
                  onPressed: () {
                    Navigator.pushReplacement(
                      context,
                      MaterialPageRoute(
                          builder: (context) => AddExpenseScreen()),
                    );
                  },
                  icon: Icon(Icons.add, color: Colors.white),
                  label: Text("Add", style: TextStyle(color: Colors.white)),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.green,
                    padding: EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(8),
                    ),
                  ),
                ),
              ],
            ),
          ),

          // 📃 Expense List
          Expanded(
            child: isLoading
                ? Center(child: CircularProgressIndicator())
                : filteredExpenses.isEmpty
                    ? Center(
                        child: Text("No expenses found",
                            style: TextStyle(color: Colors.grey)),
                      )
                    : ListView.builder(
                        itemCount: filteredExpenses.length,
                        itemBuilder: (context, index) {
                          final item = filteredExpenses[index];
                          return GestureDetector(
                            onTap: () {
                              Navigator.push(
                                context,
                                MaterialPageRoute(
                                  builder: (context) =>
                                      ExpenseDetailScreen(expense: item),
                                ),
                              );
                            },
                            child: Card(
                              elevation: 3,
                              margin: EdgeInsets.symmetric(
                                  horizontal: 12, vertical: 6),
                              shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(10)),
                              child: Padding(
                                padding: const EdgeInsets.all(12.0),
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Row(
                                      mainAxisAlignment:
                                          MainAxisAlignment.spaceBetween,
                                      children: [
                                        Text(
                                          "₹${item['Amount']}",
                                          style: TextStyle(
                                              fontSize: 18,
                                              fontWeight: FontWeight.bold),
                                        ),
                                        Container(
                                          padding: EdgeInsets.symmetric(
                                              horizontal: 10, vertical: 4),
                                          decoration: BoxDecoration(
                                            color:
                                                getStatusColor(item['Status'])
                                                    .withOpacity(0.1),
                                            borderRadius:
                                                BorderRadius.circular(12),
                                          ),
                                          child: Text(
                                            getStatusLabel(item['Status']),
                                            style: TextStyle(
                                              fontSize: 12,
                                              color: getStatusColor(
                                                  item['Status']),
                                              fontWeight: FontWeight.w600,
                                            ),
                                          ),
                                        ),
                                      ],
                                    ),
                                    SizedBox(height: 8),
                                    if (item['schoolName'] != null)
                                      Text("School: ${item['schoolName']}")
                                    else if (item['DistributorName'] != null)
                                      Text(
                                          "Distributor: ${item['DistributorName']}"),
                                    SizedBox(height: 4),
                                    Text(
                                      "Purpose: ${item['expensePurposeName'] ?? 'N/A'}",
                                    ),
                                    SizedBox(height: 2),
                                    Text(
                                      "Type: ${item['expenseTypeName'] ?? 'N/A'}",
                                    ),
                                  ],
                                ),
                              ),
                            ),
                          );
                        },
                      ),
          ),

          // ⬅️ Page Navigation
          if (totalPages > 1)
            Padding(
              padding: const EdgeInsets.symmetric(vertical: 10),
              child: Wrap(
                spacing: 8,
                children: List.generate(totalPages, (index) {
                  final isSelected = index == pageNumber;
                  return ElevatedButton(
                    onPressed: () => onPageChange(index),
                    style: ElevatedButton.styleFrom(
                      backgroundColor:
                          isSelected ? Colors.indigo : Colors.grey.shade300,
                      foregroundColor: isSelected ? Colors.white : Colors.black,
                      minimumSize: Size(40, 40),
                      padding: EdgeInsets.symmetric(horizontal: 12),
                    ),
                    child: Text("${index + 1}"),
                  );
                }),
              ),
            ),
        ],
      ),
    );
  }
}
