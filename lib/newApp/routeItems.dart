import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:mittsure/field/routes.dart';
import 'package:mittsure/newApp/MainMenuScreen.dart';
import 'package:mittsure/newApp/bookLoader.dart';
import 'package:mittsure/newApp/visitPartyDetail.dart';
import 'package:mittsure/services/apiService.dart';
import 'package:mittsure/services/utils.dart';
import 'package:shared_preferences/shared_preferences.dart';

class ItemListPage extends StatefulWidget {
  final id;
  final date;

  final bool userReq;
  const ItemListPage(
      {super.key, required this.id, this.date, required this.userReq});

  @override
  State<ItemListPage> createState() => _ItemListPageState();
}

class _ItemListPageState extends State<ItemListPage> {
  List<dynamic> allItems = [];
  String selectedStatus = 'All';
  List<dynamic> filteredItems = [];
 bool alreadytagged=false;
  int currentPage = 0;
  int perPage = 10;
  String selectedType = 'All';
  bool isLoading = false;

  @override
  void initState() {
    super.initState();
    fetchRouteitems();
   
    getUserData();
  }

  Map<String, dynamic> userData = {};
  getUserData() async {
    final prefs = await SharedPreferences.getInstance();
    final a = prefs.getString('user');
    if (a!.isNotEmpty) {
      setState(() {
        print(a);
        userData = jsonDecode(a ?? "");
      });
    }
  }

  Widget _buildStatusBadge(dynamic visit) {
print(visit['meeting_with_decision_maker']);
    String label = '';
    Color color = Colors.grey;
    var status=widget.userReq?visit['status']:visit['visited_status'];

    switch (status) {
      case 1:
        label = widget.userReq ? 'Approved' : 'Visit Started';
        color = widget.userReq ? Colors.green : Colors.orange;
        break;
      case 2:
        label = widget.userReq ? 'Rejected' : 'Meeting Started';
        color = widget.userReq ? Colors.red : Colors.blue;
        break;
      case 3:
        label = visit['meeting_with_decision_maker']!=null &&visit['meeting_with_decision_maker'].toLowerCase()=='no'?'Visit Ongoing':'Meeting Ended';
        color = Colors.purple;
        break;
      case 4:
        label = 'Visit Completed';
        color = Colors.green;
        break;
      case 0:
        label = widget.userReq ? 'Pending' : '';
        color = Colors.orange;
        break;
      default:
        return const SizedBox(); // No badge for unknown status
    }

    return widget.userReq || status != 0
        ? Container(
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
          )
        : SizedBox(
            height: 0,
          );
  }

  Widget buildFilterChips() {
    List<Map<String, dynamic>> statuses = [
      {"name": 'All', "id": "", "color": Colors.indigo},
      {"name": 'Approved', "id": "1", "color": Colors.green.shade600},
      {"name": 'Pending', "id": "0", "color": Colors.yellow.shade600},
      {"name": 'Rejected', "id": "2", "color": Colors.red}
    ];

    return Wrap(
      spacing: 8,
      children: statuses.map((status) {
        final isSelected = selectedStatus == status['id'];
        return ChoiceChip(
          label: Text(status['name'] ?? ""),
          selected: isSelected,
          selectedColor: status['color'] ?? Colors.indigo,
          checkmarkColor: Colors.white,
          labelStyle: TextStyle(
            color: isSelected ? Colors.white : Colors.black,
          ),
          onSelected: (_) => onStatusChange(status['id'] ?? ""),
        );
      }).toList(),
    );
  }

  void onStatusChange(String status) {
    setState(() {
      print(status);
      selectedStatus = status;
      if (status == "") {
        filteredItems = allItems;
      } else {
        filteredItems = allItems
            .where((element) => element['status'].toString() == status)
            .toList();
      }
    });
  }

  Future<void> fetchRouteitems() async {
    setState(() {
      isLoading = true;
    });

    final body = {
      "id": widget.id,
      if (selectedStatus != 'All') "status": selectedStatus.toLowerCase()
    };

    try {
      final response = await ApiService.post(
        endpoint: '/routePlan/getRoutePlanById',
        body: body,
      );

      if (response != null && response['status'] == false) {
        setState(() {
          allItems = response['data'] ?? [];
         
          alreadytagged=response['data1']=="true"?true:false;
          onStatusChange("");
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

  tagMe() async {
    setState(() {
        isLoading=true;
      });
    try {

      final response = await ApiService.post(
          endpoint: '/routePlan/updateTaggedUser',
          body: {"routeId": widget.id, "taggedId": userData['id']});

      if (response != null && response['status'] == false) {
        setState(() {
          alreadytagged=true;
        });
        DialogUtils.showCommonPopup(
            context: context, message: response["message"], isSuccess: true);
      }
    } catch (e) {
       DialogUtils.showCommonPopup(
            context: context, message: "Something Went Wrong", isSuccess: false);
    }finally{
      setState(() {
        isLoading=false;
      });
    }
  }

    UntagMe() async {
    setState(() {
        isLoading=true;
      });
    try {

      final response = await ApiService.post(
          endpoint: '/routePlan/updateUnTaggedUser',
          body: {"routeId": widget.id, "taggedId": userData['id']});

      if (response != null && response['status'] == false) {
        setState(() {
          alreadytagged=false;
        });
        DialogUtils.showCommonPopup(
            context: context, message: response["message"], isSuccess: true);
      }
    } catch (e) {
       DialogUtils.showCommonPopup(
            context: context, message: "Something Went Wrong", isSuccess: false);
    }finally{
      setState(() {
        isLoading=false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return WillPopScope(
      onWillPop: () async {
        widget.userReq
            ? Navigator.pushAndRemoveUntil(
                context,
                MaterialPageRoute(builder: (context) => MainMenuScreen()),
                (route) => false, // remove all previous routes
              )
            : Navigator.pushAndRemoveUntil(
                context,
                MaterialPageRoute(
                    builder: (context) => CreatedRoutesPage(userReq: false)),
                (route) => false, // remove all previous routes
              );
        return false;
      },
      child: Scaffold(
        appBar: AppBar(
          title: const Text('Route Items', style: TextStyle(color: Colors.white)),
          backgroundColor: Colors.indigo,
          iconTheme: const IconThemeData(color: Colors.white),
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
        ),
        body: isLoading
            ? Center(
                child: BookPageLoader(),
              )
            : Column(
                children: [
                  // Filters and Page Size
                  // Padding(
                  //   padding: const EdgeInsets.all(8),
                  //   child: Row(
                  //     children: [
                  //       Expanded(
                  //         child: Wrap(
                  //           spacing: 8,
                  //           children: itemTypes.map((type) {
                  //             final isSelected = selectedType == type;
                  //             return ChoiceChip(
                  //               label: Text(type),
                  //               selected: isSelected,
                  //               selectedColor: Colors.indigo,
                  //               checkmarkColor: Colors.white,
                  //               labelStyle: TextStyle(color: isSelected ? Colors.white : Colors.black),
                  //               onSelected: (_) {
                  //                 selectedType = type;
                  //                 _applyFilters();
                  //               },
                  //             );
                  //           }).toList(),
                  //         ),
                  //       ),
                  //       const SizedBox(width: 10),

                  //     ],
                  //   ),
                  // ),

                  // Item List
                  Padding(
                    padding: const EdgeInsets.symmetric(
                        vertical: 8.0, horizontal: 1),
                    child: Row(
                      children: [
                        Expanded(child: buildFilterChips()),
                        const SizedBox(width: 10),
                      ],
                    ),
                  ),
                  Expanded(
                    child: filteredItems.isEmpty
                        ? const Center(child: Text("No items found."))
                        : ListView.builder(
                            padding: const EdgeInsets.fromLTRB(16, 8, 16, 80),
                            itemCount: filteredItems.length,
                            itemBuilder: (context, index) {
                              final item = filteredItems[index];
                              return GestureDetector(
                                onTap: () {
                                  print(item);

                                  Navigator.push(
                                      context,
                                      MaterialPageRoute(
                                          builder: (context) =>
                                              RouteDetailsScreen(
                                                data: item,
                                                type: item['partyType'],
                                                date: widget.date,
                                                visitStatus:
                                                    item['visited_status'],
                                                userReq: widget.userReq,
                                              )));
                                },
                                child: Card(
                                  elevation: 3,
                                  shape: RoundedRectangleBorder(
                                    borderRadius: BorderRadius.circular(12),
                                  ),
                                  margin: const EdgeInsets.only(bottom: 12),
                                  child: ListTile(
                                    leading: const Icon(Icons.category,
                                        color: Colors.indigo),
                                    title: Text(item['DistributorName'] ??
                                        item['schoolName']),
                                    subtitle: Text(
                                        "${item['partyType'] == 0 ? 'Distributor' : 'School'}-${item['partyId']}"),
                                    trailing: Column(
                                      children: [
                                        _buildVisitBadge(item),
                                             SizedBox(height: 5,),
                                             _buildStatusBadge(item),
                                      ],
                                    ),
                                  ),
                                ),
                              );
                            },
                          ),
                  ),
if(userData['role']!=null&& alreadytagged)
                  Padding(
                    padding: const EdgeInsets.all(8.0),
                    child: ElevatedButton.icon(
                      style: ButtonStyle(
                        backgroundColor:
                            MaterialStateProperty.all(Colors.deepOrange),
                        minimumSize: MaterialStateProperty.all(
                            const Size(180, 48)), // width: 180, height: 48
                      ),
                      onPressed: UntagMe,
                      icon: const Icon(Icons.person_2, color: Colors.white),
                      label: const Text('Untag Me ',
                          style: TextStyle(color: Colors.white)),
                    ),
                  )  ,
                  if(userData['role']=='asm' && !alreadytagged)
                  Padding(
                    padding: const EdgeInsets.all(8.0),
                    child: ElevatedButton.icon(
                      style: ButtonStyle(
                        backgroundColor:
                            MaterialStateProperty.all(Colors.green),
                        minimumSize: MaterialStateProperty.all(
                            const Size(180, 48)), // width: 180, height: 48
                      ),
                      onPressed: tagMe,
                      icon: const Icon(Icons.person_2, color: Colors.white),
                      label: const Text('Tag Me ',
                          style: TextStyle(color: Colors.white)),
                    ),
                  ),
 

                ],
              ),
      ),
    );
  }
  Widget _buildVisitBadge(dynamic party) {

    String label = '';
    Color color = Colors.grey;
if(party['visitHappened']!=null)
    {
      switch (party['visitHappened'].toUpperCase()) {
        case 'YES':
          label = 'Visited';
          color = Colors.green;
          break;
        case "NO":
          label = ' Not Yet Visited ';
          color = Colors.red;
          break;

        default:
          return const SizedBox(); // No badge for unknown status
      }
    }

    return label==""?SizedBox():Container(
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
          fontSize: 9,
          fontWeight: FontWeight.bold,
        ),
      ),
    );
  }
}
