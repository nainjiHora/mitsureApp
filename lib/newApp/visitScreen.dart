import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
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
  int totalCount = 0;
  bool isLoading = false;
  Map<String, dynamic> userData = {};

  @override
  void initState() {
    super.initState();
    final today = DateTime.now();
    _selectedDateRange = DateTimeRange(start: today, end: today);
    getUserData();
  }

  getUserData() async {
    final prefs = await SharedPreferences.getInstance();
    final a = prefs.getString('user');
    if (a != null && a.isNotEmpty) {
      setState(() {
        userData = jsonDecode(a);
      });
      fetchVisits();
    }
  }

  fetchVisits() async {
    setState(() => isLoading = true);

    Map<String, dynamic> body = {
      "ownerName": userData['id'],
      "pageNumber": 0,
      "recordPerPage": 20,
      "startDate": "",
      "endDate": ""
    };

    try {
      final response = await ApiService.post(
        endpoint: '/visit/fetchVisit',
        body: body,
      );

      if (response != null && response['status'] == false) {
        setState(() {
          visits = response['data'];
          totalCount = response['data1'];
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

  void _pickDateRange() async {
    DateTimeRange? picked = await showDateRangePicker(
      context: context,
      firstDate: DateTime(2023),
      lastDate: DateTime.now().add(Duration(days: 365)),
      initialDateRange: _selectedDateRange,
    );

    if (picked != null) {
      setState(() {
        _selectedDateRange = picked;
        // Optional: Trigger filtered API call
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
        title: Text('Visits', style: TextStyle(color: Colors.white)),
        iconTheme: IconThemeData(color: Colors.white),
        backgroundColor: Colors.indigo[900],
        centerTitle: true,
        elevation: 4,
      ),
      body: Column(
        children: [
          const SizedBox(height: 10),
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
          Divider(),
          Expanded(
            child: isLoading
                ? Center(child: CircularProgressIndicator())
                : visits.isEmpty
                    ? Center(
                        child: Text(
                          "No visits found.",
                          style: TextStyle(
                              fontSize: 16, fontWeight: FontWeight.w500),
                        ),
                      )
                    : ListView.builder(
                        itemCount: visits.length,
                        padding: EdgeInsets.symmetric(horizontal: 12),
                        itemBuilder: (context, index) {
                          final visit = visits[index];
                          final title = visit['schoolName'] ?? visit['DistributorName'];
                          final subtitle = visit['partyId'];

                          return GestureDetector(
                            onTap: () {
                              Navigator.push(
                                context,
                                MaterialPageRoute(
                                  builder: (_) => VisitDetailsScreen(
                                    visitDetails: visit,
                                  ),
                                ),
                              );
                            },
                            child: Card(
                              elevation: 3,
                              margin: EdgeInsets.symmetric(vertical: 8),
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(12),
                              ),
                              child: ListTile(
                                contentPadding: EdgeInsets.symmetric(horizontal: 16, vertical: 10),
                                leading: Icon(Icons.location_on, color: Colors.indigo),
                                title: Text(
                                  title,
                                  style: TextStyle(
                                    fontWeight: FontWeight.w600,
                                    fontSize: 16,
                                  ),
                                ),
                                subtitle: Text(subtitle ?? ''),
                                trailing: Icon(Icons.arrow_forward_ios, size: 16),
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
}
