import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

class TravelAllowanceScreen extends StatefulWidget {
  @override
  _TravelAllowanceScreenState createState() => _TravelAllowanceScreenState();
}

class _TravelAllowanceScreenState extends State<TravelAllowanceScreen> {
  DateTime? _startDate;
  DateTime? _endDate;

  List<Map<String, dynamic>> allAllowances = [
    {
      'date': DateTime(2024, 6, 1),
      'mode': 'Taxi',
      'systemAmount': 250.0,
      'userAmount': 240.0
    },
    {
      'date': DateTime(2024, 6, 3),
      'mode': 'Train',
      'systemAmount': 500.0,
      'userAmount': 480.0
    },
    {
      'date': DateTime(2024, 6, 10),
      'mode': 'Flight',
      'systemAmount': 1500.0,
      'userAmount': 1600.0
    },
  ];

  List<Map<String, dynamic>> get filteredAllowances {
    if (_startDate == null || _endDate == null) return allAllowances;
    return allAllowances.where((item) {
      return item['date'].isAfter(_startDate!.subtract(Duration(days: 1))) &&
             item['date'].isBefore(_endDate!.add(Duration(days: 1)));
    }).toList();
  }

  Future<void> _pickDateRange() async {
    final picked = await showDateRangePicker(
      context: context,
      firstDate: DateTime(2020),
      lastDate: DateTime.now(),
    );

    if (picked != null) {
      setState(() {
        _startDate = picked.start;
        _endDate = picked.end;
      });
    }
  }

  String formatDate(DateTime date) {
    return DateFormat('dd MMM yyyy').format(date);
  }

  

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Travel Allowances'),
      ),
      body: Column(
        children: [
          // Date Filter
          Padding(
            padding: const EdgeInsets.all(12.0),
            child: Align(
              alignment: Alignment.centerLeft,
              child: ElevatedButton.icon(
                onPressed: _pickDateRange,
                icon: Icon(Icons.calendar_today),
                label: Text(
                  _startDate != null && _endDate != null
                      ? '${formatDate(_startDate!)} - ${formatDate(_endDate!)}'
                      : 'Select Date Range',
                ),
              ),
            ),
          ),

          // Card List
          Expanded(
            child: filteredAllowances.isEmpty
                ? Center(child: Text('No allowances found for selected range.'))
                : ListView.builder(
                    itemCount: filteredAllowances.length,
                    itemBuilder: (context, index) {
                      final item = filteredAllowances[index];
                      return Card(
                        margin: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                        elevation: 3,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: Padding(
                          padding: const EdgeInsets.all(16.0),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                formatDate(item['date']),
                                style: TextStyle(
                                  fontSize: 16,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                              SizedBox(height: 8),
                              Row(
                                children: [
                                  Icon(Icons.directions_transit, size: 20),
                                  SizedBox(width: 8),
                                  Text("Mode: ${item['mode']}"),
                                ],
                              ),
                              SizedBox(height: 8),
                              Text(
                                "System Amount: ₹ ${item['systemAmount'].toStringAsFixed(2)}",
                                style: TextStyle(color: Colors.grey[700]),
                              ),
                              Text(
                                "User Amount: ₹ ${item['userAmount'].toStringAsFixed(2)}",
                                style: TextStyle(color: Colors.grey[700]),
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
}
