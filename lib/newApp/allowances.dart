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

  bool isLoading = false;
  var userData = {};

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);

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
    if (a != null && a.isNotEmpty) {
      setState(() {
        userData = jsonDecode(a);
        _setDefaultDateRange();
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
          "userId": userData['id'],
          "fromDate":
              "${_dateRange!.start.year}-${_dateRange!.start.month}-${_dateRange!.start.day}",
          "toDate":
              "${_dateRange!.end.year}-${_dateRange!.end.month}-${_dateRange!.end.day}",
        },
      );
      if (response != null) {
        final data = response['data'];
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
          "userId": userData['id'],
          "fromDate":
              "${_dateRange!.start.year}-${_dateRange!.start.month}-${_dateRange!.start.day}",
          "toDate":
              "${_dateRange!.end.year}-${_dateRange!.end.month}-${_dateRange!.end.day}",
        },
      );
      if (response != null) {
        final data = response['data'];
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
            Tab(text: "Daily Allowance",),
          ],
        ),
      ),
      body: Column(
        children: [
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
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
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
              const SizedBox(height: 12),
              // Divider line
              Divider(color: Colors.grey.shade300, thickness: 1),
              const SizedBox(height: 12),
              // Info Rows
              _infoRow(
                icon: Icons.directions_walk,
                label: "User Input KM",
                value: "${item['km_difference']}",
              ),
              const SizedBox(height: 8),
              _infoRow(
                icon: Icons.map_outlined,
                label: "System Generated KM",
                value: "${item['systemGenerated_distance']}",
              ),
            ],
          ),
        ),
      );
    },
  );
}

// A helper widget for consistent row formatting
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
      final cityCategory = item['city'] == null
          ? ''
          : (jsonDecode(item['city'])['category'] ?? '');

      return Card(
        elevation: 2,
        margin: const EdgeInsets.only(bottom: 12),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(12),
        ),
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
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
              const SizedBox(height: 12),
              Divider(color: Colors.grey.shade300, thickness: 1),
              const SizedBox(height: 12),
              // Info Rows
              _infoRow(
                icon: Icons.location_on_outlined,
                label: "Visit Type",
                value: item['visitType'] ?? '-',
              ),
              const SizedBox(height: 8),
              _infoRow(
                icon: Icons.location_city,
                label: "City Category",
                value: cityCategory,
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
