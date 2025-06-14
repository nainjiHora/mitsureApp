import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:mittsure/newApp/bookLoader.dart';
import 'package:mittsure/services/utils.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:marquee/marquee.dart';
import '../reorder_route_page.dart';
import '../services/apiService.dart';

class CreateRoutePage extends StatefulWidget {
  const CreateRoutePage({super.key});

  @override
  State<CreateRoutePage> createState() => _CreateRoutePageState();
}

class _CreateRoutePageState extends State<CreateRoutePage> {
  List<dynamic> visitTypeOptions = [
    {"routeVisitType": "Select Visit Type", "routeVisitTypeID": ""}
  ];
  bool isLoading = false;
  String? visitType = "";
  String? partyType = '';
  String? selectedSchool;
  DateTime? selectedDate;
  List<dynamic> selectedparty = [];

  final List<Map<String, dynamic>> addedRoutes = [];

  List<dynamic> schools = [];
  List<dynamic> distributors = [];
  List<dynamic> filteredSchools = [];
  List<dynamic> filteredDistributors = [];

  getName(item) {
    if (item['partyType'] == '1') {
      final n = schools
          .where((element) => element['schoolId'] == item['partyId'])
          .toList()[0];
      return n['schoolName'];
    } else {
      final n = distributors
          .where((element) => element['distributorID'] == item['partyId'])
          .toList()[0];
      return n['DistributorName'];
    }
  }

  Future<void> _fetchOrders(int pageNumber, {String? filter}) async {
    setState(() {
      isLoading = true;
    });
    final prefs = await SharedPreferences.getInstance();
    final hasData = prefs.getString('user') != null;
    var id = "";
    if (hasData) {
      id = jsonDecode(prefs.getString('user') ?? "")['id'];
    } else {
      return;
    }

    final body = {
      "ownerId": id,
    };
    if ((partyType == "1" && schools.length == 0) ||
        (partyType == "0" && distributors.length == 0)) {
      try {
        final response = await ApiService.post(
          endpoint:
              partyType == "1" ? '/party/getAllSchool' : '/party/getAllDistri',
          body: body,
        );
        if (response != null) {
          final data = response['data'];
          setState(() {
            if (partyType == "1") {
              filteredSchools = data;
              schools = data;
            } else {
              filteredDistributors = data;
              distributors = data;
            }
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
    } else {
      setState(() {
        isLoading = false;
      });
    }
  }

  Future<void> _pickDate() async {
    final now = DateTime.now();
    final DateTime? picked = await showDatePicker(
      context: context,
      initialDate: now.add(const Duration(days: 1)),
      firstDate: now.add(const Duration(days: 1)),
      lastDate: now.add(const Duration(days: 7)),
    );
    if (picked != null) {
      setState(() {
        selectedDate = picked;
      });
    }
  }

  void _addRoute() {
    if (visitType != null &&
        partyType != null &&
        selectedSchool != null &&
        selectedDate != null) {
      if (selectedparty
              .where((element) => element['partyId'] == selectedSchool)
              .toList()
              .length >
          0) {
        DialogUtils.showCommonPopup(
          context: context,
          message: "This Party already exists",
          isSuccess: false,
        );
        return;
      } else {
        setState(() {
          selectedparty.add({
            'visitType': visitType,
            'partyType': partyType,
            'partyId': selectedSchool,
            'date': selectedDate,
          });
          selectedSchool = null;
          // removeParty(partyType, selectedSchool);
        });
      }
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please select all fields')),
      );
    }
  }

  void _goToNextPage() {
    if (selectedparty.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('No routes added')),
      );
      return;
    }

    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => ReorderRoutePage(
            routes: selectedparty,
            schools: schools,
            distributors: distributors),
      ),
    );
  }

  fetchPicklist() async {
    final body = {};

    try {
      final response = await ApiService.post(
        endpoint: '/picklist/getRouteVisitType', // Use your API endpoint
        body: body,
      );
      if (response != null && response['status'] == false) {
        setState(() {
          visitTypeOptions.addAll(response['data']);
        });
      } else {
        throw Exception('Failed to load orders');
      }
    } catch (error) {
      print("Error fetcffdfdhing orders: $error");
    }
  }

  @override
  void initState() {
    // TODO: implement initState
    super.initState();
    fetchPicklist();
  }

  removeParty(filter, id) {
    print(filter);
    if (filter == 0) {
      final n = filteredDistributors
          .where((element) => element['distributorID'] != id)
          .toList();
      setState(() {
        filteredDistributors = n;
      });
    } else {
      final n = filteredSchools
          .where((element) => element['schoolId'] != id)
          .toList();
      setState(() {
        filteredSchools = n;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Stack(
      children: [
        Scaffold(
          appBar: AppBar(title: const Text('Create Route')),
          body: Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              children: [
                _buildDropdown(
                    'Visit Type',
                    visitTypeOptions,
                    "routeVisitTypeID",
                    'routeVisitType',
                    visitType,
                    (val) => setState(() {
                          visitType = val;
                        })),
                const SizedBox(height: 12),
                TextFormField(
                  readOnly: true,
                  onTap: () {
                    selectedparty.length > 0 ? null : _pickDate();
                  },
                  decoration: InputDecoration(
                    hintText: selectedDate == null
                        ? 'Choose date'
                        : "${selectedDate!.day}-${selectedDate!.month}-${selectedDate!.year}",
                    suffixIcon: const Icon(Icons.calendar_today),
                    border: const OutlineInputBorder(),
                    contentPadding: const EdgeInsets.symmetric(
                        horizontal: 12, vertical: 14),
                  ),
                ),
                const SizedBox(height: 12),
                _buildDropdown(
                    'Party Type',
                    [
                      {"id": "", "name": "Select Party Type"},
                      {"id": "1", "name": "School"},
                      {"id": "0", "name": "Distributor"}
                    ],
                    "id",
                    'name',
                    partyType, (val) {
                  setState(() => partyType = val);
                  _fetchOrders(int.parse(val ?? '0'));
                }),
                const SizedBox(height: 12),
                partyType == '1'
                    ? _buildDropdown(
                        'Select School',
                        filteredSchools,
                        "schoolId",
                        'schoolName',
                        selectedSchool,
                        (val) => setState(() {
                              selectedSchool = val;
                            }))
                    : _buildDropdown(
                        'Select Distributor',
                        filteredDistributors,
                        "distributorID",
                        'DistributorName',
                        selectedSchool,
                        (val) => setState(() {
                              selectedSchool = val;
                            })),
                const SizedBox(height: 20),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceAround,
                  children: [
                    ElevatedButton.icon(
                      onPressed: _addRoute,
                      icon: const Icon(Icons.add),
                      label: const Text('Add'),
                    ),
                    ElevatedButton(
                      onPressed: _goToNextPage,
                      child: const Text('Next'),
                    ),
                  ],
                ),
                Row(
                  mainAxisAlignment: MainAxisAlignment.start,
                  children: [
                    Text(
                      "Selected Parties",
                      style:
                          TextStyle(fontSize: 22, fontWeight: FontWeight.w700),
                    ),
                  ],
                ),
                Container(
                  height: 55 * (selectedparty.length).toDouble(),
                  width: double.infinity,
                  child: selectedparty.length > 0
                      ? ListView.builder(
                          itemCount: selectedparty.length,
                          itemBuilder: (context, index) {
                            final item = selectedparty[index];
                            return Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: [
                                Container(
                                  width: 300,
                                  margin: const EdgeInsets.symmetric(
                                      vertical: 5,
                                      horizontal:
                                          10), // Add some spacing around rows
                                  padding: const EdgeInsets.all(
                                      8), // Add padding inside the row
                                  decoration: BoxDecoration(
                                    color: Colors.blue[
                                        50], // Light blue background color
                                    border: Border.all(
                                        color: Colors.blue,
                                        width: 1), // Blue border
                                    borderRadius: BorderRadius.circular(
                                        8), // Rounded corners
                                  ),
                                  child: Row(
                                    mainAxisAlignment:
                                        MainAxisAlignment.spaceAround,
                                    children: [
                                      Text(
                                        getName(item).length > 10
                                            ? getName(item)
                                                    .toString()
                                                    .substring(0, 26) +
                                                "..."
                                            : getName(item),
                                        style: const TextStyle(
                                            fontSize: 14,
                                            fontWeight: FontWeight
                                                .bold), // Add styling to the text
                                      ),
                                      SizedBox(
                                          width:
                                              56), // Add spacing between elements
                                    ],
                                  ),
                                ),
                                GestureDetector(
                                  onTap: () {
                                    setState(() {
                                      selectedparty.removeAt(index);
                                    });
                                  },
                                  child: Icon(
                                    Icons.delete,
                                    color: Colors.red,
                                  ),
                                )
                              ],
                            );
                          },
                          physics: NeverScrollableScrollPhysics(),
                        )
                      : Text("No Products Added"),
                ),
              ],
            ),
          ),
        ),
        if (isLoading) const BookPageLoader(),
      ],
    );
  }

  Widget _buildDropdown(String label, List<dynamic> items, keyId, keyName,
      String? value, ValueChanged<String?> onChanged) {
    return DropdownButtonFormField<String>(
      decoration: InputDecoration(
        labelText: label,
        border: const OutlineInputBorder(),
        contentPadding:
            const EdgeInsets.symmetric(horizontal: 12, vertical: 14),
      ),
      value: value,
      items: items
          .map((item) => DropdownMenuItem(
              value: item![keyId]!.toString(),
              child: Text(item[keyName] ?? "")))
          .toList(),
      onChanged: onChanged,
    );
  }
}
