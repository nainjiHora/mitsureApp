import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:geolocator/geolocator.dart';
import 'package:intl/intl.dart';
import 'package:mittsure/field/routes.dart';
import 'package:mittsure/newApp/MainMenuScreen.dart';
import 'package:mittsure/newApp/bookLoader.dart';
import 'package:mittsure/newApp/endVisitScreen.dart';
import 'package:mittsure/newApp/routeItems.dart';
import 'package:mittsure/newApp/visitCaptureScreen.dart';
import 'package:mittsure/screens/commonLayout.js.dart';
import 'package:mittsure/screens/newOrder.dart';
import 'package:mittsure/services/apiService.dart';
import 'package:mittsure/services/utils.dart';
import 'package:shared_preferences/shared_preferences.dart';

class RouteDetailsScreen extends StatefulWidget {
  final Map<String, dynamic> data;
  final type;
  final date;
  final visitStatus;
  final visitId;

  RouteDetailsScreen(
      {Key? key,
      required this.data,
      required this.type,
      required this.date,
      required this.visitStatus,
      this.visitId});

  @override
  State<RouteDetailsScreen> createState() => _RouteDetailsScreenState();
}

class _RouteDetailsScreenState extends State<RouteDetailsScreen> {
  Map<dynamic, dynamic> distributor = {};
  int visitCount = 0;
  var latestVisit = {};
  List<dynamic> visitTypeOptions = [
    {"routeVisitType": "Select Visit Type", "routeVisitTypeID": ""}
  ];
  String? visitType = "";
  DateTime? selectedDate;
  int status = 6;

  formatDateTime(String start, String end) {
    final inputFormat = DateFormat('yyyy-MM-dd HH:mm:ss');
    final dateFormat = DateFormat('MMMM d, yyyy'); // e.g., June 3, 2025
    final timeFormat = DateFormat('hh:mm a'); // e.g., 07:00 AM

    final startDateTime = inputFormat.parse(start);
    final endDateTime = inputFormat.parse(end);

    final date = dateFormat.format(startDateTime);
    final startTime = timeFormat.format(startDateTime);
    final endTime = timeFormat.format(endDateTime);

    return "$date ($startTime-$endTime)";
  }

  fetchlastVisit() async {
    print(widget.data);
    print("ssssss");
    setState(() {
      isLoading = true;
    });
    final body = {"partyId": widget.data['partyId']};

    try {
      final response = await ApiService.post(
        endpoint: '/visit/fetchCurrentVisit', // Use your API endpoint
        body: body,
      );

      if (response != null && response['status'] == false) {
        setState(() {
          visitCount = response['data']['totalCount'];
          latestVisit = response['data']['latestVisit'];
        });
      } else {}
    } catch (error) {
      print("Error fething orders: $error");
    } finally {
      setState(() {
        isLoading = false;
      });
    }
  }

  fetchPicklist() async {
    print(widget.data);
    final body = {};

    try {
      final response = await ApiService.post(
        endpoint: '/picklist/getRouteVisitType', // Use your API endpoint
        body: body,
      );

      if (response != null && response['status'] == false) {
        setState(() {
          visitTypeOptions.addAll(response['data']);

          if (widget.visitStatus != null) {
            status = widget.visitStatus;
          } else {
            status = widget.data['visited_status'];
          }
        });
      } else {
        throw Exception('Failed to get picklist');
      }
    } catch (error) {
      print("Error fetcffng orders: $error");
    }
  }

  tagLocation() async {
    print(":plplpl");
    try {
      setState(() {
        isLoading = true;
      });
      bool serviceEnabled = await Geolocator.isLocationServiceEnabled();
      if (!serviceEnabled) return;

      LocationPermission permission = await Geolocator.requestPermission();
      if (permission == LocationPermission.denied ||
          permission == LocationPermission.deniedForever) {
        return;
      }

      Position position = await Geolocator.getCurrentPosition(
          desiredAccuracy: LocationAccuracy.high);
      final body = {
        "lat": position.latitude.toString(),
        "long": position.longitude.toString(),
        "type": widget.type.toString(),
        "id": widget.data['addressId'],
        "data": jsonEncode({
          "party": widget.data['partyId'],
          "lat": position.latitude.toString(),
          "long": position.longitude.toString(),
        })
      };

      final response = await ApiService.post(
        endpoint: '/party/markLocation',
        body: body,
      );

      print(response);

      if (response != null && response['success'] == true) {
        setState(() {
          widget.data['lat'] = position.latitude;
          widget.data['long'] = position.longitude;
          DialogUtils.showCommonPopup(
              context: context, message: "Location Marked", isSuccess: true);
          isLoading = false;
        });
      } else {
        DialogUtils.showCommonPopup(
            context: context, message: response['message'], isSuccess: false);
        setState(() {
          isLoading = false;
        });
      }
    } catch (error) {
      DialogUtils.showCommonPopup(
          context: context, message: "Something Went Wrong", isSuccess: false);
      setState(() {
        isLoading = false;
      });
    }
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

  Future<void> _pickDate(change) async {
    final now = DateTime.now();
    final DateTime? picked = await showDatePicker(
      context: context,
      initialDate: now.add(const Duration(days: 0)),
      firstDate: now.add(const Duration(days: 0)),
      lastDate: now.add(const Duration(days: 7)),
    );
    if (picked != null) {
      change(() {
        selectedDate = picked;
      });
    }
  }

  Future<void> showFormDialog({
    required BuildContext context,
    required void Function() onSubmit,
  }) async {
    await showDialog(
      context: context,
      builder: (BuildContext dialogContext) {
        return StatefulBuilder(
          builder: (context, setState) {
            return AlertDialog(
              title: const Text('Update Data'),
              content: SizedBox(
                height: 150,
                child: Padding(
                  padding: const EdgeInsets.all(10),
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
                          _pickDate(setState);
                        },
                        decoration: InputDecoration(
                          hintText: selectedDate == null
                              ? 'Choose date'
                              : "${selectedDate!.day}-${selectedDate!.month}-${selectedDate!.year}",
                          labelText: selectedDate == null
                              ? 'Choose date'
                              : "${selectedDate!.day}-${selectedDate!.month}-${selectedDate!.year}",
                          suffixIcon: const Icon(Icons.calendar_today),
                          border: const OutlineInputBorder(),
                          contentPadding: const EdgeInsets.symmetric(
                              horizontal: 12, vertical: 14),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
              actions: <Widget>[
                TextButton(
                  child: const Text('Cancel'),
                  onPressed: () => Navigator.of(dialogContext).pop(),
                ),
                ElevatedButton(
                  child: const Text('Submit'),
                  onPressed: () {
                    Navigator.of(dialogContext).pop();
                    onSubmit();
                  },
                ),
              ],
            );
          },
        );
      },
    );
  }

  Future<void> showDeleteConfirmationDialog({
    required BuildContext context,
    required VoidCallback onConfirm,
  }) async {
    return showDialog(
      context: context,
      builder: (BuildContext dialogContext) {
        return AlertDialog(
          title: const Text(
            'Confirm Remove',
            style: TextStyle(color: Colors.black),
          ),
          content: const Text(
            'Are you sure you want to remove this from route plan? This action cannot be undone.',
          ),
          actions: <Widget>[
            TextButton(
              child: const Text('Cancel'),
              onPressed: () {
                Navigator.of(dialogContext).pop(); // Close dialog
              },
            ),
            ElevatedButton(
              style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
              child: const Text(
                'Confirm',
                style: TextStyle(color: Colors.white),
              ),
              onPressed: () {
                Navigator.of(dialogContext).pop(); // Close dialog
                onConfirm(); // Trigger the deletion
              },
            ),
          ],
        );
      },
    );
  }

  var userData = {};
  getUserData() async {
    final prefs = await SharedPreferences.getInstance();
    final a = prefs.getString('user');
    if (a!.isNotEmpty) {
      setState(() {
        userData = jsonDecode(a ?? "");
      });
    }
  }

  @override
  void initState() {
    // TODO: implement initState
    super.initState();
    fetchPicklist();
    fetchlastVisit();
    getUserData();

    distributor = widget.data;
  }

  bool isLoading = false;

  void deleteRoutes() async {
    setState(() {
      isLoading = true;
    });

    final body = {
      "routeLineItemId": widget.data['route_line_items_id'],
    };

    try {
      final response = await ApiService.post(
        endpoint: '/routePlan/deleteOfRoutParty',
        body: body,
      );

      if (response != null && response['success'] == true) {
        Navigator.push(context,
            MaterialPageRoute(builder: (context) => CreatedRoutesPage()));
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
  }

  Future<void> startMeeting(String filter) async {
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
      "id": widget.data['visitId'] ?? widget.visitId, // visit id
      "ownerId": id
    };

    try {
      final response = await ApiService.post(
        endpoint: filter == "end"
            ? '/visit/endMeetingVisit'
            : '/visit/startMeetingVisit',
        body: body,
      );
      if (response != null && response['status'] == false) {
        setState(() {
          isLoading = false;
          status = filter == 'end' ? 3 : 2;
        });
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
              content:
                  Text(filter == 'end' ? "Meeting Ended" : "Meeting Started")),
        );
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(response['message'])),
        );
      }
    } catch (error) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(error.toString())),
      );
    }
  }

  void _submitRoutes() async {
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
      "owner_id": id,
      "date": selectedDate.toString().substring(0, 11),
      "routeLineItemId": widget.data['route_line_items_id'],
      "visitType": visitType
    };

    try {
      final response = await ApiService.post(
        endpoint: '/routePlan/updateDateOfRoutParty',
        body: body,
      );

      if (response != null && response['success'] == true) {
        Navigator.push(context,
            MaterialPageRoute(builder: (context) => CreatedRoutesPage()));
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
  }

  bool isToday(String dateString) {
    final date = DateTime.parse(dateString); // Make sure format is 'yyyy-MM-dd'
    final now = DateTime.now();
    return date.year == now.year &&
        date.month == now.month &&
        date.day == now.day;
  }

  void showEndPopup(BuildContext context) {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: Text("Are you sure to end the meeting?"),
          actions: [
            TextButton(
              onPressed: () {
                startMeeting("end");
                Navigator.of(context).pop();
              },
              child: Text('Yes'),
            ),
            TextButton(
              onPressed: () {
                Navigator.of(context).pop(); // Close the dialog
              },
              child: Text('No'),
            ),
          ],
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return WillPopScope(
      onWillPop: () async {
        Navigator.pushReplacement(
          context,
          MaterialPageRoute(
            builder: (context) => ItemListPage(
              date: widget.date,
              id: widget.data['routeId'],
            ),
          ),
        );
        return false; // Prevent default back navigation
      },
      child: Scaffold(
        appBar: AppBar(
          backgroundColor: Colors.indigo[900],
          iconTheme: IconThemeData(color: Colors.white),
          title: Text(
            widget.type == 1
                ? distributor['schoolName']
                : distributor['DistributorName'],
            style: TextStyle(color: Colors.white, fontSize: 20),
          ),
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
            : ListView(
                padding: const EdgeInsets.all(16.0),
                children: [
                  Container(
                    color: Colors.indigo[50],
                    child: Padding(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 15, vertical: 10),
                      child: Column(
                        children: [
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              Text(
                                "No. of Visits:  ",
                                style: TextStyle(fontWeight: FontWeight.bold),
                              ),
                              Text(
                                "${visitCount.toString()}",
                                style: TextStyle(fontWeight: FontWeight.bold),
                              )
                            ],
                          ),
                          visitCount > 0
                              ? Row(
                                  mainAxisAlignment:
                                      MainAxisAlignment.spaceBetween,
                                  children: [
                                    Text(
                                      "Last Visit :  ",
                                      style: TextStyle(
                                          fontWeight: FontWeight.bold),
                                    ),
                                    Text(
                                      "${formatDateTime(latestVisit['startTime'], latestVisit['endTime'])}",
                                      style: TextStyle(
                                          fontWeight: FontWeight.bold),
                                    )
                                  ],
                                )
                              : Container(),
                        ],
                      ),
                    ),
                  ),
                  // Distributor Details Section
                  SectionTitle(
                      title: widget.type == 1
                          ? 'School Details'
                          : 'Distributor Details'),
                  DetailsRow(
                      label: 'Name',
                      value: widget.type == 1
                          ? distributor['schoolName']
                          : distributor['DistributorName'] ?? 'N/A'),
                  DetailsRow(
                      label: 'GST Number',
                      value: distributor['GSTno'] ?? 'N/A'),
                  DetailsRow(
                    label: 'Created At',
                    value: distributor['createdAt'] != null
                        ? distributor['createdAt'].toString().substring(0, 10)
                        : 'N/A',
                  ),
                  const Divider(),

                  // Address Section
                  const SectionTitle(title: 'Address Details'),
                  DetailsRow(
                      label: 'Pincode', value: distributor['Pincode'] ?? 'N/A'),
                  DetailsRow(
                      label: 'Address Line ',
                      value: distributor['AddressLine1'] ?? 'N/A'),
                  DetailsRow(
                      label: 'Landmark',
                      value: distributor['Landmark'] ?? 'N/A'),
                  const Divider(),

                  const SectionTitle(title: 'Contact Person Details'),
                  DetailsRow(
                      label: 'Name', value: distributor['name'] ?? 'N/A'),
                  DetailsRow(
                      label: 'Role', value: distributor['role'] ?? 'N/A'),
                  DetailsRow(
                      label: 'Contact Number',
                      value: distributor['makerContact'] ?? 'N/A'),
                  DetailsRow(
                      label: 'Email', value: distributor['email'] ?? 'N/A'),
                  const Divider(),
                  SizedBox(
                    height: 20,
                  ),

                  // Additional Information Section
                  //           const SectionTitle(title: 'Additional Information'),
                  //           DetailsRow(label: 'PAN Number', value: distributor['panNumber'] ?? 'N/A'),
                  //           DetailsRow(label: 'Transporter Name', value: distributor['transporter_name'] ?? 'N/A'),
                  //           DetailsRow(label: 'KYC Received', value: distributor['kycRecieved'] == 1 ? 'Yes' : 'No'),
                  // SizedBox(height:10,),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceAround,
                    children: [
                      status == 0
                          ? ElevatedButton.icon(
                              icon: Icon(
                                Icons.edit,
                                color: Colors.white,
                              ),
                              style: ElevatedButton.styleFrom(
                                fixedSize: Size(150, 50),
                                backgroundColor: Colors.indigo[900],
                              ),
                              onPressed: () {
                                showFormDialog(
                                  context: context,
                                  onSubmit: () {
                                    _submitRoutes();
                                  },
                                );
                              },
                              label: Text(
                                "Edit",
                                style: TextStyle(color: Colors.white),
                              ),
                            )
                          : Container(),
                      status == 0
                          ? ElevatedButton.icon(
                              icon: Icon(
                                Icons.delete_forever,
                                color: Colors.white,
                              ),
                              style: ElevatedButton.styleFrom(
                                fixedSize: Size(150, 50),
                                backgroundColor: Colors.red,
                              ),
                              onPressed: () {
                                showDeleteConfirmationDialog(
                                  context: context,
                                  onConfirm: () {
                                    deleteRoutes();
                                  },
                                );
                              },
                              label: Text(
                                "Delete",
                                style: TextStyle(color: Colors.white),
                              ),
                            )
                          : Container(),
                    ],
                  ),
                  SizedBox(
                    height: 6,
                  ),
                  userData['role'] == 'se' &&
                          status == 0 &&
                          widget.data['status'] == 1 &&
                          isToday(widget.date) &&
                          widget.data['lat'] == null &&
                          widget.data['long'] == null
                      ? ElevatedButton.icon(
                          icon: Icon(
                            Icons.map,
                            color: Colors.white,
                          ),
                          style: ElevatedButton.styleFrom(
                            minimumSize: Size(10, 50),
                            backgroundColor: Colors.orange.shade400,
                          ),
                          onPressed: () {
                            tagLocation();
                          },
                          label: Text(
                            "Tag Location",
                            style: TextStyle(color: Colors.white),
                          ),
                        )
                      : Container(),
                  SizedBox(
                    height: 10,
                  ),
                  userData['role'] == 'se' &&
                          status == 0 &&
                          widget.data['status'] == 1 &&
                          isToday(widget.date) &&
                          widget.data['lat'] != null &&
                          widget.data['long'] != null
                      ? ElevatedButton.icon(
                          icon: Icon(
                            Icons.start_outlined,
                            color: Colors.white,
                          ),
                          style: ElevatedButton.styleFrom(
                            minimumSize: Size(10, 50),
                            backgroundColor: Colors.green,
                          ),
                          onPressed: () {
                            Navigator.push(
                              context,
                              MaterialPageRoute(
                                builder: (context) => VisitCaptureScreen(
                                  visit: widget.data,
                                  date: widget.data,
                                  type: widget.type,
                                ),
                              ),
                            );
                          },
                          label: Text(
                            "Start Visit",
                            style: TextStyle(color: Colors.white),
                          ),
                        )
                      : Container(),
                  userData['role'] == 'se' && status == 1
                      ? ElevatedButton.icon(
                          icon: Icon(
                            Icons.start_outlined,
                            color: Colors.white,
                          ),
                          style: ElevatedButton.styleFrom(
                            minimumSize: Size(10, 50),
                            backgroundColor: Colors.green,
                          ),
                          onPressed: () {
                            startMeeting("start");
                          },
                          label: Text(
                            "Start Meeting",
                            style: TextStyle(color: Colors.white),
                          ),
                        )
                      : Container(),
                  userData['role'] == 'se' && status == 2
                      ? ElevatedButton.icon(
                          icon: Icon(
                            Icons.start_outlined,
                            color: Colors.white,
                          ),
                          style: ElevatedButton.styleFrom(
                            minimumSize: Size(10, 50),
                            backgroundColor: Colors.green,
                          ),
                          onPressed: () {
                            showEndPopup(context);
                          },
                          label: Text(
                            "End Meeting",
                            style: TextStyle(color: Colors.white),
                          ),
                        )
                      : Container(),
                  userData['role'] == 'se' && status == 3
                      ? ElevatedButton.icon(
                          icon: Icon(
                            Icons.start_outlined,
                            color: Colors.white,
                          ),
                          style: ElevatedButton.styleFrom(
                            minimumSize: Size(10, 50),
                            backgroundColor: Colors.green,
                          ),
                          onPressed: () {
                            Navigator.push(
                              context,
                              MaterialPageRoute(
                                builder: (context) => EndVisitScreen(
                                    visit: widget.data,
                                    date: widget.date,
                                    type: widget.type,
                                    visitId: widget.visitId),
                              ),
                            );
                          },
                          label: Text(
                            "End Visit",
                            style: TextStyle(color: Colors.white),
                          ),
                        )
                      : Container()
                ],
              ),
      ),
    );
  }
}

// Section Title Widget
class SectionTitle extends StatelessWidget {
  final String title;

  const SectionTitle({Key? key, required this.title}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8.0),
      child: Text(
        title,
        style: const TextStyle(
          fontSize: 16,
          fontWeight: FontWeight.bold,
          color: Colors.black87,
        ),
      ),
    );
  }
}

// Details Row Widget
class DetailsRow extends StatelessWidget {
  final String label;
  final String value;

  const DetailsRow({Key? key, required this.label, required this.value})
      : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4.0),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(
            label,
            style: const TextStyle(fontSize: 14, color: Colors.black54),
          ),
          Expanded(
            child: Text(
              value,
              textAlign: TextAlign.end,
              style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w500),
              overflow: TextOverflow.ellipsis,
            ),
          ),
        ],
      ),
    );
  }
}
