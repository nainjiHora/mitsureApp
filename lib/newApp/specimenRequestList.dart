import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:mittsure/newApp/specimenRequest.dart';
import 'package:mittsure/services/apiService.dart';
import 'package:shared_preferences/shared_preferences.dart';

class SpecimenReList extends StatefulWidget {
  const SpecimenReList({super.key});

  @override
  State<SpecimenReList> createState() => _SpecimenReListState();
}

class _SpecimenReListState extends State<SpecimenReList> {
  bool isLoading = false;
  Map<String, dynamic> userData = {};
  int pageNumber = 1;
  int totalData = 0;
  int recordPerPage = 20;
  String selectedFilter = "All";

  List<Map<String, dynamic>> specimenList = [];

  List<String> filters = ["All", "Approved", "Rejected", "Pending"];

  @override
  void initState() {
    super.initState();
    getUserData();
  }

  getUserData() async {
    final prefs = await SharedPreferences.getInstance();
    final a = prefs.getString('user');
    if (a != null && a.isNotEmpty) {
      userData = jsonDecode(a);
      fetchVisits();
    }
  }

  fetchVisits() async {
    setState(() => isLoading = true);

    String statusFilter = "";
    if (selectedFilter == "Approved") statusFilter = "1";
    if (selectedFilter == "Rejected") statusFilter = "2";
    if (selectedFilter == "Pending") statusFilter = "0";

    Map<String, dynamic> body = {
      "ownerId": userData['id'],
      "pageNumber": pageNumber - 1,
      "recordPerPage": recordPerPage,
      "status": statusFilter != "" ? int.parse(statusFilter) : "",
    };

    try {
      final response = await ApiService.post(
        endpoint: '/Specimen/getAllSpecimens',
        body: body,
      );

      if (response != null && response['status'] == false) {
        setState(() {
          specimenList = List<Map<String, dynamic>>.from(response['data']);
          totalData = response["data1"];
        });
      } else {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(
          content: Text(response['message'] ?? 'Something went wrong'),
          backgroundColor: Colors.red,
        ));
      }
    } catch (error) {
      print("Error fetching visits: $error");
    } finally {
      setState(() => isLoading = false);
    }
  }

  int get totalPages => ((totalData + recordPerPage - 1) / recordPerPage).floor();

  Map<String, dynamic> getStatusDetails(String status) {
    switch (status) {
      case "1":
        return {
          "text": "Accepted",
          "color": Colors.green,
        };
      case "2":
        return {
          "text": "Rejected",
          "color": Colors.red,
        };
      default:
        return {
          "text": "Pending",
          "color": Colors.orange,
        };
    }
  }

  Widget buildPagination() {
    List<Widget> buttons = [];

    for (int i = 1; i <= totalPages; i++) {
      if (i <= 5 || (i - pageNumber).abs() <= 2 || i == totalPages) {
        buttons.add(
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 2),
            child: ElevatedButton(
              onPressed: () {
                setState(() {
                  pageNumber = i;
                });
                fetchVisits();
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: pageNumber == i ? Colors.blue : Colors.grey[200],
                foregroundColor: pageNumber == i ? Colors.white : Colors.black,
                padding: EdgeInsets.symmetric(horizontal: 12, vertical: 8),
              ),
              child: Text("$i"),
            ),
          ),
        );
      } else if (buttons.isEmpty || buttons.last is! Text) {
        buttons.add(Text("..."));
      }
    }

    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        IconButton(
          icon: Icon(Icons.chevron_left),
          onPressed: pageNumber > 1
              ? () {
                  setState(() {
                    pageNumber--;
                  });
                  fetchVisits();
                }
              : null,
        ),
        Text("Page $pageNumber of $totalPages"),
        SizedBox(width: 8),
        ...buttons,
        IconButton(
          icon: Icon(Icons.chevron_right),
          onPressed: pageNumber < totalPages
              ? () {
                  setState(() {
                    pageNumber++;
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
    return Scaffold(
      appBar: AppBar(
        backgroundColor: Colors.indigo.shade600,
        title: Text("Specimen Requests",style: TextStyle(color: Colors.white),),
        iconTheme: IconThemeData(color: Colors.white),
        actions: [
          IconButton(
            icon: Icon(Icons.add),
            onPressed: () {
              Navigator.push(context,
                  MaterialPageRoute(builder: (_) => SpecimenRequestScreen()));
            },
          )
        ],
      ),
      body: Column(
        children: [
          // Filters
          Padding(
            padding: const EdgeInsets.all(8.0),
            child: Wrap(
              spacing: 8,
              children: filters.map((filter) {
                final isSelected = filter == selectedFilter;
                return ChoiceChip(
                  label: Text(filter),
                  selected: isSelected,
                  onSelected: (_) {
                    setState(() {
                      selectedFilter = filter;
                      pageNumber = 1;
                    });
                    fetchVisits();
                  },
                );
              }).toList(),
            ),
          ),

          // List
          Expanded(
            child: isLoading
                ? Center(child: CircularProgressIndicator())
                : specimenList.isEmpty
                    ? Center(child: Text("No records found."))
                    : ListView.builder(
                        itemCount: specimenList.length,
                        itemBuilder: (context, index) {
                          final item = specimenList[index];
                          final statusInfo = getStatusDetails(item['status'].toString());
                          final createdAt = item['createdAt'] != null
                              ? DateFormat('dd MMM yyyy').format(DateTime.parse(item['createdAt']))
                              : 'N/A';

                          return Card(
                            margin: EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                            elevation: 3,
                            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                            child: Padding(
                              padding: const EdgeInsets.all(12.0),
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  // Date + Status Row
                                  Row(
                                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                    children: [
                                      Text(
                                        createdAt,
                                        style: TextStyle(
                                          fontWeight: FontWeight.bold,
                                          fontSize: 16,
                                        ),
                                      ),
                                      Container(
                                        padding: EdgeInsets.symmetric(horizontal: 12, vertical: 4),
                                        decoration: BoxDecoration(
                                          color: statusInfo['color'].withOpacity(0.1),
                                          border: Border.all(color: statusInfo['color']),
                                          borderRadius: BorderRadius.circular(20),
                                        ),
                                        child: Text(
                                          statusInfo['text'],
                                          style: TextStyle(
                                            color: statusInfo['color'],
                                            fontWeight: FontWeight.w600,
                                            fontSize: 12,
                                          ),
                                        ),
                                      ),
                                    ],
                                  ),
                                  SizedBox(height: 8),
                                  Row(
                                    crossAxisAlignment: CrossAxisAlignment.start,
                                    children: [
                                      Icon(Icons.comment, size: 18, color: Colors.grey[600]),
                                      SizedBox(width: 6),
                                      Expanded(
                                        child: Text(
                                          item['remarks'] ?? 'No remarks',
                                          style: TextStyle(fontSize: 14, color: Colors.grey[800]),
                                        ),
                                      ),
                                    ],
                                  ),
                                ],
                              ),
                            ),
                          );
                        },
                      ),
          ),

          // Pagination
          if (!isLoading && specimenList.isNotEmpty)
            Padding(
              padding: const EdgeInsets.all(8.0),
              child: buildPagination(),
            ),
        ],
      ),
    );
  }
}
