import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter_typeahead/flutter_typeahead.dart';
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
  String? tagUserController = null;
  final TextEditingController prefDistributor = TextEditingController();
  final TextEditingController selectedRouteController = TextEditingController();
  final TextEditingController rmController = TextEditingController();
  List<dynamic> asms = [];
  List<dynamic> routeNames = [];
  List<dynamic> rsms = [];
  List<dynamic> rms = [];
  List<dynamic> rmsOnly = [];
  Map<String, dynamic> userData = {};
  List<dynamic> allUsers = [];
  String? superwisorController = null;
  String? rsmController = null;
  final _formKey = GlobalKey<FormState>();
  bool includeCompanion = false;
  String? visitType = "";
  String? partyType = '';
  String? selectedRM = '';
  String? selectedSchool;
    String? selectedRoute;
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

    if(userData['role'] != 'se' && (selectedRM==''||selectedRM==null)){
      DialogUtils.showCommonPopup(context: context, message: "Assign RM or ARM First", isSuccess: false);
      return;

    }
    setState(() {
      isLoading = true;
    });

    final body = {
      "ownerId": userData['role'] != "se" ? selectedRM : userData['id'],
      "routeName":selectedRoute??"",
      // "visitEndRequired":"yes"
    };
    print(body);
    print("bodyforoute");
    if ((partyType == "1" && schools.length == 0) ||
        (partyType == "0" && distributors.length == 0)||true) {
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
              print(schools);

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
      initialDate: now.add(const Duration(days: 0)),
      firstDate: now.add(const Duration(days: 0)),
      lastDate: now.add(const Duration(days: 7)),
    );
    if (picked != null) {
      setState(() {
        selectedDate = picked;
      });
    }
  }

  getUserData() async {
    final prefs = await SharedPreferences.getInstance();
    final a = prefs.getString('user');
    if (a!.isNotEmpty) {
      setState(() {
        userData = jsonDecode(a ?? "");
        _fetChAllRSM();
        fetchAllRouteNames();
      });
    }
  }

  _fetChAllRSM() async {
    if (allUsers.length == 0)
      try {
        setState(() {
          isLoading = true;
        });
        final response =
            await ApiService.post(endpoint: '/user/getUsers', body: {});

        if (response != null) {
          final data = response['data'];

          setState(() {
            // rsms = data.where((e) => e['role'] == 'rsm').toList();
            // asms = data.where((e) => e['role'] == 'asm').toList();
            print(data);
            rms = data
                .where((e) =>
                    (e['cluster'] == userData['cluster']) &&
                    userData['id'] != e['id'])
                .toList();
            rmsOnly = data
                .where((e) =>
                    ((e['cluster'] == userData['cluster']) &&
                    userData['id'] != e['id'] &&
                    e['role'] == 'se') || e['id']==userData['id'])
                .toList();
            print(userData);
            allUsers = data;
            isLoading = false;
          });
        } else {
          throw Exception('Failed to load orders');
        }
      } catch (error) {
        print("Error fetching ojbjbjbjjrders: $error");
      } finally {
        setState(() {
          isLoading = false;
        });
      }
  }

  _fetchAsm(id) async {
    try {
      setState(() {
        asms = allUsers
            .where((e) => e['role'] == 'asm' && e['reportingManager'] == id)
            .toList();

        // superwisorController = asms[0]['id'];
        isLoading = false;
        // tagUserController = "";
      });
    } catch (error) {
      print("Error fetching ojbjbjbjjrders: $error");
    } finally {}
  }

  _fetchSe(id) async {
    try {
      setState(() {
        rms = allUsers
            .where((e) =>
                e['role'] == 'se' &&
                e['reportingManager'] == id &&
                e['id'] != userData['id'])
            .toList();
        // tagUserController = rms[0]['id'];
        isLoading = false;
      });
    } catch (e) {
      print(e);
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
        print("Dassd");
        setState(() {
          selectedparty.add({
            'visitType': visitType,
            'partyType': partyType,
            'partyId': selectedSchool,
            'date': selectedDate,
          });
          selectedSchool = null;
          prefDistributor.clear();
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
            visitType: visitTypeOptions,
            tagPartner: tagUserController ?? superwisorController ?? "",
            distributors: distributors,
            selectedRM: selectedRM),
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
      print(response);
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
    getUserData();

  }

  fetchAllRouteNames() async {
    final body = {
      "cluster":userData['cluster']
    };
print(body);
print("getroutecluster");
    try {
      final response = await ApiService.post(
        endpoint: '/picklist/getAllRouteNames',
        body: body,
      );
      print(response);
      if (response != null && response['status'] == true) {
        setState(() {
          routeNames.addAll(response['data']);
        });
      }
    } catch (error) {
      print("Error fetcffdfdhing orders: $error");
    }
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
            resizeToAvoidBottomInset: true,
            appBar: AppBar(title: const Text('Create Route')),
            body: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 14),
              child: SingleChildScrollView(
                child: SizedBox(
                  height: MediaQuery.of(context).size.height * 0.85,
                  child: Column(
                    children: [
                      if (userData['role'] == 'se')
                        CheckboxListTile(
                          title: Text('Tag Colleague'),
                          value: includeCompanion,
                          onChanged: (value) async {
                            setState(() {
                              includeCompanion = value ?? false;
                            });
                            if (includeCompanion) {
                              await _fetChAllRSM();
                            } else {
                              rsmController = null;
                              tagUserController = null;
                              superwisorController = null;
                            }
                          },
                        ),
                      if (includeCompanion) ...[
                        // Padding(
                        //   padding: const EdgeInsets.all(8.0),
                        //   child: _buildDropdown(
                        //     'Select HO',
                        //     rsms,
                        //     'id',
                        //     'name',
                        //     rsmController,
                        //         (value) {
                        //       setState(() {
                        //         rsmController = value;
                        //         superwisorController=null;
                        //         tagUserController=null;
                        //         _fetchAsm(value);
                        //       });
                        //     },
                        //   ),
                        // ),
                        // Padding(
                        //   padding: const EdgeInsets.all(8.0),
                        //   child: _buildDropdown(
                        //     'Select ARM',
                        //     asms,
                        //     'id',
                        //     'name',
                        //     superwisorController,
                        //         (value) {
                        //       setState(() {
                        //         superwisorController = value;
                        //
                        //         tagUserController=null;
                        //         _fetchSe(value);
                        //       });
                        //     },
                        //   ),
                        // ),
                        Padding(
                          padding: const EdgeInsets.symmetric(vertical: 10.0),
                          child: _buildDropdown(
                            'Select Colleague',
                            rms,
                            'id',
                            'name',
                            tagUserController,
                            (value) {
                              setState(() {
                                tagUserController = value;
                              });
                            },
                          ),
                        ),
                      ],
                      if (userData['role'] != 'se')
                        TypeAheadFormField<Map<String, dynamic>>(
                          textFieldConfiguration: TextFieldConfiguration(
                            controller: rmController,
                            decoration: InputDecoration(
                              labelText: 'Assign RM',
                              border: OutlineInputBorder(),
                            ),
                          ),
                          suggestionsCallback: (pattern) {
                            return rmsOnly
                                .where((dist) => dist['name']
                                    .toLowerCase()
                                    .contains(pattern.toLowerCase()))
                                .cast<Map<String, dynamic>>();
                          },
                          itemBuilder: (context, suggestion) {
                            return ListTile(
                              title: Text(suggestion['name']),
                            );
                          },
                          onSuggestionSelected: (suggestion) {
                            setState(() {
                              selectedRM = suggestion['id'];
                              rmController.text = suggestion['name'];
                            });
                          },
                        ),
                      SizedBox(
                        height: 10,
                      ),
                      _buildDropdown(
                          'Visit Purpose',
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
                        if(userData['role'] != 'se' && (selectedRM==''||selectedRM==null)){
                          DialogUtils.showCommonPopup(context: context, message: "Assign RM or ARM First", isSuccess: false);
                          setState(() {
                            partyType=null;
                          });
                          return;

                        }
                        setState(() {
                          partyType = val;
                          prefDistributor.clear();
                        });
                        _fetchOrders(int.parse(val ?? '0'));
                      }),
                      const SizedBox(height: 12),
                      if(userData['role']!="se")
                      Padding(
                        padding: const EdgeInsets.symmetric(vertical: 10),
                        child: TypeAheadFormField<String>(
                          textFieldConfiguration: TextFieldConfiguration(
                            controller: selectedRouteController,
                            decoration: InputDecoration(
                              labelText: 'Search Route',
                              border: OutlineInputBorder(),
                            ),
                          ),
                          suggestionsCallback: (pattern) {
                            return routeNames
                                .where((route) => route
                                    .toLowerCase()
                                    .contains(pattern.toLowerCase()))
                                .cast<String>();
                          },
                          itemBuilder: (context, suggestion) {
                            return ListTile(
                              title: Text(suggestion),
                            );
                          },
                          onSuggestionSelected: (suggestion) {
                            setState(() {
                              selectedRouteController.text=suggestion;
                              selectedRoute=suggestion;
                              _fetchOrders(1);
                            });
                          },
                        ),
                      ),
                      // partyType == '1'
                      //     ? _buildDropdown(
                      //         'Select School',
                      //         filteredSchools,
                      //         "schoolId",
                      //         'schoolName',
                      //         selectedSchool,
                      //         (val) => setState(() {
                      //               selectedSchool = val;
                      //             }))
                      //     : _buildDropdown(
                      //         'Select Distributor',
                      //         filteredDistributors,
                      //         "distributorID",
                      //         'DistributorName',
                      //         selectedSchool,
                      //         (val) => setState(() {
                      //               selectedSchool = val;
                      //             })),
                      partyType == '1'
                          ?
                          // Text(
                          //   "Preferred Distributor",
                          //   style: TextStyle(fontWeight: FontWeight.bold),
                          // ),
                          TypeAheadFormField<Map<String, dynamic>>(
                              textFieldConfiguration: TextFieldConfiguration(
                                controller: prefDistributor,
                                decoration: InputDecoration(
                                  labelText: 'Search School',
                                  border: OutlineInputBorder(),
                                ),
                              ),
                              suggestionsCallback: (pattern) {
                                return schools
                                    .where((dist) => dist['schoolName']
                                        .toLowerCase()
                                        .contains(pattern.toLowerCase())||
          dist['AddressLine1']
              .toLowerCase()
              .contains(pattern.toLowerCase()))
                                    .cast<Map<String, dynamic>>();
                              },
                              itemBuilder: (context, suggestion) {
                                return ListTile(
                                  title: Text("${suggestion['schoolId']}-${suggestion['schoolName']}"),
                                );
                              },
                              onSuggestionSelected: (suggestion) {
                                setState(() {
                                  selectedSchool = suggestion['schoolId'];
                                  prefDistributor.text =
                                      suggestion['schoolName'];
                                });
                              },
                            )
                          : TypeAheadFormField<Map<String, dynamic>>(
                              textFieldConfiguration: TextFieldConfiguration(
                                controller: prefDistributor,
                                decoration: InputDecoration(
                                  labelText: 'Search Distributor',
                                  border: OutlineInputBorder(),
                                ),
                              ),
                              suggestionsCallback: (pattern) {
  return distributors
      .where((dist) =>
          dist['DistributorName']
              .toLowerCase()
              .contains(pattern.toLowerCase()) ||
          dist['AddressLine1']
              .toLowerCase()
              .contains(pattern.toLowerCase()))
      .cast<Map<String, dynamic>>();
},

                              itemBuilder: (context, suggestion) {
                                return ListTile(
                                  title: Text("${suggestion['distributorID']}-${suggestion['DistributorName']}"),
                                );
                              },
                              onSuggestionSelected: (suggestion) {
                                setState(() {
                                  selectedSchool = suggestion['distributorID'];
                                  prefDistributor.text =
                                      suggestion['DistributorName'];
                                });
                              },
                            ),
                      const SizedBox(height: 20),

                      ElevatedButton.icon(
                        style: ButtonStyle(
                          backgroundColor:
                              MaterialStateProperty.all(Colors.indigo.shade600),
                          minimumSize: MaterialStateProperty.all(
                              const Size(180, 48)), // width: 180, height: 48
                        ),
                        onPressed: _addRoute,
                        icon: const Icon(Icons.add, color: Colors.white),
                        label: const Text('Add',
                            style: TextStyle(color: Colors.white)),
                      ),

                      Padding(
                        padding: const EdgeInsets.all(8.0),
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.start,
                          children: [
                            Text(
                              "Selected Parties",
                              style: TextStyle(
                                  fontSize: 22, fontWeight: FontWeight.w700),
                            ),
                          ],
                        ),
                      ),
                      Expanded(
                        child: selectedparty.isNotEmpty
                            ? ListView.builder(
                                itemCount: selectedparty.length,
                                itemBuilder: (context, index) {
                                  final item = selectedparty[index];
                                  return Row(
                                    mainAxisAlignment:
                                        MainAxisAlignment.spaceBetween,
                                    children: [
                                      Container(
                                        width: 300,
                                        margin: const EdgeInsets.symmetric(
                                            vertical: 5, horizontal: 10),
                                        padding: const EdgeInsets.all(8),
                                        decoration: BoxDecoration(
                                          color: Colors.blue[50],
                                          border: Border.all(
                                              color: Colors.blue, width: 1),
                                          borderRadius:
                                              BorderRadius.circular(8),
                                        ),
                                        child: Row(
                                          mainAxisAlignment:
                                              MainAxisAlignment.spaceAround,
                                          children: [
                                            Text(
                                              getName(item).length > 22
                                                  ? getName(item)
                                                          .toString()
                                                          .substring(0, 21) +
                                                      "..."
                                                  : getName(item),
                                              style: const TextStyle(
                                                fontSize: 14,
                                                fontWeight: FontWeight.bold,
                                              ),
                                            ),
                                            const SizedBox(width: 56),
                                          ],
                                        ),
                                      ),
                                      GestureDetector(
                                        onTap: () {
                                          setState(() {
                                            selectedparty.removeAt(index);
                                          });
                                        },
                                        child: const Icon(Icons.delete,
                                            color: Colors.red),
                                      ),
                                    ],
                                  );
                                },
                              )
                            : const Center(child: Text("No Products Added")),
                      ),
                      ElevatedButton.icon(
                        style: ButtonStyle(
                          backgroundColor:
                              MaterialStateProperty.all(Colors.green),
                          minimumSize: MaterialStateProperty.all(
                              const Size(180, 48)), // width: 180, height: 48
                        ),
                        onPressed: _goToNextPage,
                        icon: const Icon(Icons.arrow_forward,
                            color: Colors.white),
                        label: const Text('Proceed',
                            style: TextStyle(color: Colors.white)),
                      ),
                    ],
                  ),
                ),
              ),
            )),
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
