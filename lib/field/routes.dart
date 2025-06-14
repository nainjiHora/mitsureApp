import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:mittsure/field/newPunch.dart';
import 'package:mittsure/newApp/MainMenuScreen.dart';
import 'package:mittsure/newApp/bookLoader.dart';
import 'package:mittsure/newApp/routeItems.dart';
import 'package:mittsure/services/apiService.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'createRoute.dart';

class CreatedRoutesPage extends StatefulWidget {
  const CreatedRoutesPage({super.key});

  @override
  State<CreatedRoutesPage> createState() => _CreatedRoutesPageState();
}

class _CreatedRoutesPageState extends State<CreatedRoutesPage> {
  List<dynamic> routeList = [];
  int currentPage = 0;
  int perPage = 10;
  int totalRecords = 0;
  bool isLoading = true;
  String selectedStatus = 'All';
  final List<int> pageSizes = [5, 10, 20, 50];

  @override
  void initState() {
    super.initState();
    fetchRoutes();
  }

  Future<void> fetchRoutes() async {
    setState(() {
      isLoading = true;
    });

    final prefs = await SharedPreferences.getInstance();
    final userJson = prefs.getString('user');
    if (userJson == null) return;

    final id = jsonDecode(userJson)['id'];
    final body = {
      "pageNumber": currentPage,
      "recordPerPage": perPage,
      "ownerName": id,
      if (selectedStatus != 'All') "status": selectedStatus.toLowerCase()
    };

    try {
      final response = await ApiService.post(
        endpoint: '/routePlan/getRoutePlan',
        body: body,
      );

      if (response != null&& response['status']==false) {
        setState(() {
          routeList = response['data'] ?? [];
          totalRecords = response['data1'] ?? 0;
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

  void onStatusChange(String status) {
    setState(() {
      selectedStatus = status;
      currentPage = 0;
    });
    fetchRoutes();
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

  Widget buildFilterChips() {
    final statuses = ['All', 'Pending', 'Approved', 'Rejected'];
    return Wrap(
      spacing: 8,
      children: statuses.map((status) {
        final isSelected = selectedStatus == status;
        return ChoiceChip(
          label: Text(status),
          selected: isSelected,
          selectedColor: Colors.indigo[900],
          checkmarkColor: Colors.white,
          labelStyle:
              TextStyle(color: isSelected ? Colors.white : Colors.black),
          onSelected: (_) => onStatusChange(status),
        );
      }).toList(),
    );
  }

  Widget buildPaginationButtons() {
    int totalPages = (totalRecords / perPage).ceil();

    return Wrap(
      spacing: 6,
      children: List.generate(totalPages, (index) {
        bool isSelected = index == currentPage;
        return ElevatedButton(
          style: ElevatedButton.styleFrom(
            padding: const EdgeInsets.symmetric(horizontal: 12),
            backgroundColor:
                isSelected ? Colors.indigo[900] : Colors.grey.shade200,
            foregroundColor: isSelected ? Colors.white : Colors.black,
          ),
          onPressed: () => goToPage(index),
          child: Text('${index + 1}'),
        );
      }),
    );
  }

  @override
  Widget build(BuildContext context) {
    final dates = routeList
        .map(
            (route) => DateTime.tryParse(route['date'] ?? '') ?? DateTime.now())
        .toList()
      ..sort();

    final totalPages = (totalRecords / perPage).ceil();

    return WillPopScope(
       onWillPop: ()async{
        Navigator.pushAndRemoveUntil(
                  context,
                  MaterialPageRoute(builder: (context) => MainMenuScreen()),
                  (route) => false, // remove all previous routes
                );
                return false;
      },
      child: Scaffold(
        appBar: AppBar(
          backgroundColor: Colors.indigo[900],
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
          title:
              const Text('Created Routes', style: TextStyle(color: Colors.white)),
          iconTheme: const IconThemeData(color: Colors.white),
        ),
        body: isLoading
            ?  Center(child: BookPageLoader())
            : Column(
                children: [
                  // Padding(
                  //   padding:
                  //       const EdgeInsets.symmetric(vertical: 8.0, horizontal: 1),
                  //   child: Row(
                  //     children: [
                  //       Expanded(child: buildFilterChips()),
                  //       const SizedBox(width: 10),
                  //     ],
                  //   ),
                  // ),
                  Padding(
                    padding:
                        const EdgeInsets.symmetric(vertical: 8.0, horizontal: 8),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.end,
                      children: [
                        DropdownButton<int>(
                          value: perPage,
                          underline: Container(),
                          items: pageSizes
                              .map((size) => DropdownMenuItem(
                                  value: size, child: Text("Page Size: $size")))
                              .toList(),
                          onChanged: (value) {
                            if (value != null) onPageSizeChange(value);
                          },
                        ),
                      ],
                    ),
                  ),
      
                  // Route List
                  Expanded(
                    child: dates.isEmpty
                        ? const Center(
                            child: Text(
                              'No routes found.\nTry a different filter or create a new one!',
                              textAlign: TextAlign.center,
                              style: TextStyle(fontSize: 18, color: Colors.grey),
                            ),
                          )
                        : ListView.builder(
                            padding: const EdgeInsets.fromLTRB(16, 8, 16, 80),
                            itemCount: routeList.length,
                            itemBuilder: (context, index) {
                              final route = routeList[index];
                              final date =
                                  DateTime.tryParse(route['date'] ?? '') ??
                                      DateTime.now();
                              return GestureDetector(
                                onTap: () {
                                  print(route);
                                  Navigator.push(
                                    context,
                                    MaterialPageRoute(
                                        builder: (context) => ItemListPage(
                                            id: route['routeId'],
                                            date: route['date'])),
                                  );
                                },
                                child: Card(
                                  elevation: 3,
                                  margin: const EdgeInsets.only(bottom: 12),
                                  shape: RoundedRectangleBorder(
                                    borderRadius: BorderRadius.circular(12),
                                  ),
                                  child: ListTile(
                                    leading: const Icon(
                                        Icons.calendar_today_rounded,
                                        color: Colors.indigo),
                                    title: Text(
                                      "${date.day}-${date.month}-${date.year}",
                                      style: const TextStyle(
                                          fontWeight: FontWeight.w600,
                                          fontSize: 16),
                                    ),
                                    subtitle: const Text("Tap to view details"),
                                  ),
                                ),
                              );
                            },
                          ),
                  ),
      
                  // Pagination Controls
                  Padding(
                    padding:
                        const EdgeInsets.symmetric(vertical: 10, horizontal: 16),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text("Page ${currentPage + 1} of $totalPages"),
                        const SizedBox(height: 6),
                        buildPaginationButtons(),
                      ],
                    ),
                  )
                ],
              ),
        floatingActionButton: Padding(
          padding: const EdgeInsets.only(bottom: 12.0),
          child: FloatingActionButton(
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
          ),
        ),
      ),
    );
  }
}

Widget _buildDropdown(String label, List<dynamic> items, keyId, keyName,
    String? value, ValueChanged<String?> onChanged) {
  return DropdownButtonFormField<String>(
    decoration: InputDecoration(
      labelText: label,
      border: const OutlineInputBorder(),
      contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 14),
    ),
    value: value,
    items: items
        .map((item) => DropdownMenuItem(
            value: item![keyId]!.toString(), child: Text(item[keyName] ?? "")))
        .toList(),
    onChanged: onChanged,
  );
}
