import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:mittsure/newApp/specimenReqDetail.dart';
import 'package:mittsure/newApp/specimenRequest.dart';
import 'package:mittsure/services/apiService.dart';
import 'package:mittsure/services/utils.dart';
import 'package:shared_preferences/shared_preferences.dart';

class SpecimenReList extends StatefulWidget {
  final bool userReq;
  const SpecimenReList({super.key, required this.userReq});

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

  List<String> filters = [];

  String selectedASM = "";
  List<dynamic> asmList = [];
  String selectedRsm = "";
  List<dynamic> rsmList = [];
  String selectedSE = "";
  List<dynamic> seList = [];
  @override
  void initState() {
    super.initState();

    getUserData();
  }
    void _approveRequest(id) async {
    setState(() {
      isLoading = true;
    });
    try {
      final response = await ApiService.post(
        endpoint: '/Specimen/approveRejectSpecimenToUser',
        body: {
          "isDirectApproval": true,
          "approvalStatus": "1",
          "specimenId": id
        },
      );
      setState(() {
        isLoading = false;
      });
      if (response != null && response['status'] == false) {
        DialogUtils.showCommonPopup(
            context: context, message: "Approved Sucessfully", isSuccess: true ,onOkPressed: (){getUserData();});

      }
    } catch (e) {
      print(e);
      DialogUtils.showCommonPopup(
          context: context, message: "Something Went Wrong", isSuccess: false);
    } finally {
      setState(() {
        isLoading = false;
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

  getUserData() async {
    final prefs = await SharedPreferences.getInstance();
    final a = prefs.getString('user');
    if (a!.isNotEmpty) {
      setState(() {
        userData = jsonDecode(a ?? "");
        filters = widget.userReq
            ? ["Partial Approved", "Pending"]
            : ["All", "Approved", "Rejected", "Partial Approved", "Pending"];
        selectedFilter = widget.userReq ? "Pending" : "All";
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

    String statusFilter = "0";
    if (!widget.userReq) {
      if (selectedFilter == "Approved") statusFilter = "1";
      if (selectedFilter == "Rejected") statusFilter = "2";
    }
    if (selectedFilter == "Partial Approved") statusFilter = "3";
    if (selectedFilter == "Pending") statusFilter = "0";

    Map<String, dynamic> body = {
      "ownerId": userData["role"] == 'se' ? userData['id'] : selectedSE,
      "rsm": selectedRsm,
      "asm": selectedASM,
      "pageNumber": pageNumber - 1,
      "recordPerPage": recordPerPage,
      "status": statusFilter != "" ? int.parse(statusFilter) : "",
    };
    print(body);
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

  int get totalPages =>
      ((totalData + recordPerPage - 1) / recordPerPage).floor();

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
                backgroundColor:
                    pageNumber == i ? Colors.blue : Colors.grey[200],
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
      appBar: widget.userReq
          ? null
          : AppBar(
              backgroundColor: Colors.indigo.shade600,
              title: Text(
                "Specimen Requests",
                style: TextStyle(color: Colors.white),
              ),
              iconTheme: IconThemeData(color: Colors.white),
              actions: [
                IconButton(
                  icon: Icon(Icons.add),
                  onPressed: () {
                    Navigator.push(
                        context,
                        MaterialPageRoute(
                            builder: (_) => SpecimenRequestScreen()));
                  },
                )
              ],
            ),
      body: Column(
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

                          final createdAt = item['createdAt'] != null
                              ? DateFormat('dd MMM yyyy')
                                  .format(DateTime.parse(item['createdAt']))
                              : 'N/A';

                          return GestureDetector(
                            onTap: () {
                              if (widget.userReq) {
                              } else {
                                Navigator.pushReplacement(
                                  context,
                                  MaterialPageRoute(
                                      builder: (context) => SpecimenReqDetail(
                                            id: item['specimenId'],
                                            userReq: widget.userReq,
                                          )),
                                );
                              }
                            },
                            child: Card(
                              margin: EdgeInsets.symmetric(
                                  horizontal: 12, vertical: 6),
                              elevation: 3,
                              shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(12)),
                              child: Padding(
                                padding: const EdgeInsets.all(12.0),
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    // Date + Status Row
                                    Row(
                                      mainAxisAlignment:
                                          MainAxisAlignment.spaceBetween,
                                      children: [
                                        Text(
                                          createdAt,
                                          style: TextStyle(
                                            fontWeight: FontWeight.bold,
                                            fontSize: 16,
                                          ),
                                        ),
                                       widget.userReq? Row(
                                          children: [
                                            GestureDetector(
                                                onTap: () {
                                                  Navigator.push(
                                                    context,
                                                    MaterialPageRoute(
                                                      builder: (context) =>
                                                          SpecimenReqDetail(
                                                        id: item['specimenId'],
                                                        userReq: widget.userReq,
                                                      ),
                                                    ),
                                                  );
                                                },
                                                child: Icon(
                                                    Icons.remove_red_eye,
                                                    color: Colors
                                                        .indigo.shade600)),
                                            const SizedBox(width: 12),
                                            GestureDetector(
                                                onTap: () {
                                                  _approveRequest(item['specimenId']);
                                                },
                                                child: Icon(
                                                    Icons.thumb_up_sharp,
                                                    color:
                                                        Colors.green.shade600)),
                                          ],
                                        ):Container()
                                      ],
                                    ),
                                    SizedBox(height: 8),
                                    Row(
                                      crossAxisAlignment:
                                          CrossAxisAlignment.start,
                                      children: [
                                        Icon(Icons.comment,
                                            size: 18, color: Colors.grey[600]),
                                        SizedBox(width: 6),
                                        Expanded(
                                          child: Text(
                                            item['remarks'] ?? 'No remarks',
                                            style: TextStyle(
                                                fontSize: 14,
                                                color: Colors.grey[800]),
                                          ),
                                        ),
                                      ],
                                    ),
                                  ],
                                ),
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
