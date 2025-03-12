import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:mittsure/screens/commonLayout.js.dart';
import 'package:mittsure/screens/newOrder.dart';
import 'package:mittsure/screens/partyDetail.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../services/apiService.dart';

class PartyScreen extends StatefulWidget {
  const PartyScreen({super.key});

  @override
  State<PartyScreen> createState() => _PartyScreenState();
}

class _PartyScreenState extends State<PartyScreen> {
  Map<String,dynamic> userData={};
  List<dynamic> parties = [];
  String selectedASM="";
  List<dynamic> asmList=[];
  String selectedRsm="";
  List<dynamic> rsmList=[];
  String selectedSE="";
  List<dynamic> seList=[];
  String pageSize = "15";
  String selectedFilter = 'school';
  String searchKeyword = '';
  int currentPage = 1;
  int totalCount = 0;
  bool isLoading = false;
  List<dynamic> allUsers=[];


  _fetChAllRSM() async{
    try {
      setState(() {
        isLoading=true;
      });
      final response = await ApiService.post(
        endpoint:'/user/getUsers'
        ,
           body : {  }
      );

      if (response != null) {
        final data = response['data'];
        setState(() {
          rsmList=data.where((e)=>e['role']=='rsm').toList();
          asmList=data.where((e)=>e['role']=='asm').toList();
          seList=data.where((e)=>e['role']=='se').toList();
          allUsers=data;


          _fetchOrders(currentPage);

        });
      } else {
        throw Exception('Failed to load orders');
      }
    } catch (error) {
      print("Error fetching ojbjbjbjjrders: $error");
    } finally {

    }
  }

  _fetchAsm(id) async{
    setState(() {
      isLoading=true;
    });
    _fetchOrders(currentPage);
    try {

      if(id!="") {
        final response = await ApiService.post(
          endpoint: '/user/getUserListBasedOnId'
          ,
          body: {"userId": id},
        );

        if (response != null) {
          final data = response['data'];
          setState(() {
            asmList = data;
            selectedSE="";
            seList=response['data1'];
            isLoading = false;
          });
        } else {
          throw Exception('Failed to load orders');
        }
      }else{
        setState(() {
          selectedASM="";
          selectedSE = "";
          asmList=allUsers.where((e)=>e['role']=='asm').toList();
          seList=allUsers.where((e)=>e['role']=='se').toList();

        });
      }
    } catch (error) {
      print("Error fetching ojbjbjbjjrders: $error");
    } finally {

    }
  }
  _fetchSe(id) async{
    _fetchOrders(currentPage);
    try {
      setState(() {
        isLoading=true;
      });
      if(id!="") {
        final response = await ApiService.post(
          endpoint: '/user/getUserListBasedOnId'
          ,
          body: {"userId": id},
        );

        if (response != null) {
          final data = response['data'];
          setState(() {

            seList=data;
            isLoading = false;
          });
        } else {
          throw Exception('Failed to load orders');
        }
      }else{
        setState(() {
          selectedSE = "";
          seList=allUsers.where((e)=>e['role']=='se').toList();
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
  getUserData() async{
    final prefs = await SharedPreferences.getInstance();
    final a = prefs.getString('user') ;
    if(a!.isNotEmpty) {
      setState(() {

        userData = jsonDecode(a??"");

         if(userData['role']=='se') {
           selectedSE=userData['id'];
           _fetchOrders(currentPage);
         }else if(userData['role']=='rsm'){
        selectedRsm=userData['id'];
           _fetchAsm(userData['id']);
         }
      else if(userData['role']=='asm'){
        selectedASM=userData['id'];
        _fetchSe(userData['id']);
      }
         else{
           _fetChAllRSM();
         }
      });
    }
  }
  @override
  void initState() {
    super.initState();
    getUserData();

  }

  Future<void> _fetchOrders(int pageNumber, {String? filter}) async {
    setState(() {
      isLoading = true;
    });

    final body = {
      "pageNumber": pageNumber - 1, // Backend may use 0-based indexing
      "type": selectedFilter,
      "recordPerPage": pageSize,
      "ownerId": selectedSE,
      "rsm": selectedRsm,
      "asm": selectedASM,
    };

    if (filter != null && filter.isNotEmpty) {
      body["filter"] = filter;
    }

    if(selectedSE!=null&& selectedSE.isNotEmpty){
    body['ownerId']=selectedSE;
  }



    try {
      print(body);
      final response = await ApiService.post(
        endpoint: selectedFilter == 'school'
            ? '/party/getSchool'
            : '/party/getDistributor',
        body: body,
      );

      if (response != null) {
        final data = response['data'];
        setState(() {
          totalCount = response['data1'];
          parties = data;
          isLoading=false;
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
  }

  void _updateFilter(String filter) {
    setState(() {
      selectedFilter = filter;
      currentPage = 1;
      parties.clear();
    });
    _fetchOrders(currentPage);
  }

  void _onSearchChanged(String value) {
    setState(() {
      searchKeyword = value;
    });

    if (value.length % 4 == 0) {
      _fetchOrders(currentPage, filter: value);
    }
  }

  void _updatePageSize(String newSize) {
    setState(() {
      pageSize = newSize;
      currentPage = 1; // Reset to the first page
      parties.clear(); // Clear the current list
    });
    _fetchOrders(currentPage);
  }

  int get totalPages => (totalCount / int.parse(pageSize)).ceil();

  Widget _buildPagination() {
    int startRecord = ((currentPage - 1) * int.parse(pageSize)) + 1;
    int endRecord = (startRecord + int.parse(pageSize) - 1).clamp(1, totalCount);

    return Column(
      children: [
        // Showing Records Range
        Padding(
          padding: const EdgeInsets.symmetric(vertical: 5),
          child: Text(
            "Showing $startRecord-$endRecord of $totalCount records",
            style: TextStyle(fontWeight: FontWeight.bold),
          ),
        ),
        // Pagination Controls
        SingleChildScrollView(
          scrollDirection: Axis.horizontal, // Enable horizontal scrolling
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: List.generate(totalPages, (index) {
              final pageNumber = index + 1;
              return GestureDetector(
                onTap: () {
                  setState(() {
                    currentPage = pageNumber;
                  });
                  _fetchOrders(pageNumber, filter: searchKeyword);
                },
                child: Container(
                  margin: EdgeInsets.symmetric(horizontal: 5),
                  padding: EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: currentPage == pageNumber ? Colors.blue : Colors.white,
                    border: Border.all(color: Colors.blue),
                    borderRadius: BorderRadius.circular(4),
                  ),
                  child: Text(
                    pageNumber.toString(),
                    style: TextStyle(
                      color: currentPage == pageNumber ? Colors.white : Colors.blue,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
              );
            }),
          ),
        )

      ],
    );
  }


  @override
  Widget build(BuildContext context) {
    return CommonLayout(
      currentIndex: 0,
      title: 'Parties',
      child: Container(
        color: Colors.grey[100],
        child: Column(
          children: [
            // Filter Buttons
            Padding(
              padding: const EdgeInsets.symmetric(vertical: 10),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  _buildFilterButton("School", selectedFilter == 'school', () {
                    _updateFilter('school');
                  }),
                  SizedBox(width: 10),
                  _buildFilterButton(
                      "Distributor", selectedFilter == 'distributor', () {
                    _updateFilter('distributor');
                  }),
                ],
              ),
            ),
            userData['role']!='se'? Row(
              children: [
                SizedBox(width: 5,),
                userData['role'].contains('admin')||userData['role']=='zsm'?Expanded(
                  child:DropdownButtonFormField<String>(
                    value: selectedRsm,
                    decoration: InputDecoration(
                      labelText: 'Select RSM',
                      border: OutlineInputBorder(),
                      contentPadding: EdgeInsets.symmetric(horizontal: 10, vertical: 8),
                    ),
                    style: TextStyle(fontSize: 14),
                    dropdownColor: Colors.white,
                    items: [
                      DropdownMenuItem<String>(
                        value: '', // Blank value for "All"
                        child: Text('All', style: TextStyle(fontSize: 14, color: Colors.black)),
                      ),
                      ...rsmList.map((rsm) {
                        return DropdownMenuItem<String>(
                          value: rsm['id'].toString(),
                          child: Text(rsm['name'], style: TextStyle(fontSize: 14, color: Colors.black)),
                        );
                      }).toList(),
                    ],
                    onChanged: (value) {
                      setState(() {
                        selectedRsm=value??"";
                      });
                      _fetchAsm(value);
                    },
                  )
                  ,
                ):SizedBox(height:0),
                SizedBox(width: 5,),
                userData['role']=='rsm'||userData['role'].contains('admin')||userData['role']=='zsm'?Expanded(
                  child: DropdownButtonFormField<String>(
                    value: selectedASM,
                    decoration: InputDecoration(
                      labelText: 'Select ASM',
                      border: OutlineInputBorder(),
                      contentPadding: EdgeInsets.symmetric(horizontal: 10, vertical: 8),
                    ),
                    style: TextStyle(fontSize: 14),
                    dropdownColor: Colors.white,
                    items: [
                      DropdownMenuItem<String>(
                        value: '', // Blank value for "All"
                        child: Text('All', style: TextStyle(fontSize: 14, color: Colors.black)),
                      ),
                      ...asmList.map((rsm) {
                        return DropdownMenuItem<String>(
                          value: rsm['id'].toString(),
                          child: Text(rsm['name'], style: TextStyle(fontSize: 14, color: Colors.black)),
                        );
                      }).toList(),
                    ],
                    onChanged: (value){
                      setState(() {
                        selectedASM=value??"";
                      });
                      _fetchSe(value);
                    },
                  ),
                ):SizedBox(height:0),
                SizedBox(width: 5,),

                SizedBox(width: 5,),
              ],
            ):Container(),
            SizedBox(height: 8,),
            userData['role']!='se'? Row(
              children: [
                SizedBox(width: 5,),

                SizedBox(width: 5,),
                Expanded(
                  child: DropdownButtonFormField<String>(
                    value: selectedSE,
                    decoration: InputDecoration(
                      labelText: 'Select RM',
                      border: OutlineInputBorder(),
                      contentPadding: EdgeInsets.symmetric(horizontal: 10, vertical: 8),
                    ),
                    style: TextStyle(fontSize: 14),
                    dropdownColor: Colors.white,
                    items: [
                      DropdownMenuItem<String>(
                        value: '', // Blank value for "All"
                        child: Text('All', style: TextStyle(fontSize: 14, color: Colors.black)),
                      ),
                      ...seList.map((rsm) {
                        return DropdownMenuItem<String>(
                          value: rsm['id'].toString(),
                          child: Text(rsm['name'], style: TextStyle(fontSize: 14, color: Colors.black)),
                        );
                      }).toList(),
                    ],
                    onChanged: (value){
                      selectedSE=value??"";
                      _fetchOrders(currentPage);
                    },
                  ),
                ),
                SizedBox(width: 5,),
              ],
            ):Container(),
            Padding(
              padding: const EdgeInsets.all(6.0),
              child: TextField(
                onChanged: _onSearchChanged,
                decoration: InputDecoration(
                  labelText: 'Search By Name Or Party Id',
                  hintText: 'Enter keyword',
                  prefixIcon: Icon(Icons.search),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(10),
                  ),
                  contentPadding: EdgeInsets.symmetric(horizontal: 10, vertical: 8),
                ),
              ),
            ),
            // Page Size Dropdown
            Row(
              mainAxisAlignment: MainAxisAlignment.end,
              children: [
                Text("Records per page: "),
                DropdownButton<String>(
                  value: pageSize,
                  items: ['15', '20', '25', '30']
                      .map((size) => DropdownMenuItem<String>(
                    value: size,
                    child: Text(size),
                  ))
                      .toList(),
                  onChanged: (value) {
                    if (value != null) {
                      _updatePageSize(value);
                    }
                  },
                ),
              ],
            ),
            // List of Parties
            if (isLoading)
              Center(child: CircularProgressIndicator())
            else if (parties.isEmpty)
              Expanded(
                child: Center(
                  child: Text(
                    "No Party Assigned",
                    style: TextStyle(fontWeight: FontWeight.bold, fontSize: 20),
                  ),
                ),
              )
            else
              Expanded(
                child: ListView.builder(
                  itemCount: parties.length,
                  itemBuilder: (context, index) {
                    final party = parties[index];
                    return GestureDetector(
                      onTap: () {
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (context) => DistributorDetailsScreen(
                              data: party,
                              type: selectedFilter,
                            ),
                          ),
                        );
                      },
                      child: Card(
                        margin:
                        EdgeInsets.symmetric(vertical: 8, horizontal: 16),
                        elevation: 3,
                        child: ListTile(
                          title: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                party['schoolId'] ?? party["distributorID"],
                                style: TextStyle(fontWeight: FontWeight.bold),
                              ),
                              Text(
                                party['schoolName'] ??
                                    party['DistributorName'],
                                style: TextStyle(fontWeight: FontWeight.bold),
                              ),
                            ],
                          ),
                          subtitle: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text('Mobile: ${party['makerContact']}'),
                              Text('Email: ${party['email']}'),
                            ],
                          ),
                          trailing: Icon(Icons.arrow_forward_ios,
                              color: Colors.grey),
                        ),
                      ),
                    );
                  },
                ),
              ),
            // Pagination Controls
            if (totalPages > 1)
              Padding(
                padding: const EdgeInsets.all(8.0),
                child: _buildPagination(),
              ),
          ],
        ),
      ),
    );
  }

  Widget _buildFilterButton(String text, bool isSelected, VoidCallback onTap) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: EdgeInsets.symmetric(vertical: 4, horizontal: 16),
        decoration: BoxDecoration(
          color: isSelected ? Colors.blue : Colors.white,
          borderRadius: BorderRadius.circular(20),
          border: Border.all(color: Colors.blue),
        ),
        child: Text(
          text,
          style: TextStyle(
            color: isSelected ? Colors.white : Colors.blue,
            fontWeight: FontWeight.bold,
          ),
        ),
      ),
    );
  }
}
