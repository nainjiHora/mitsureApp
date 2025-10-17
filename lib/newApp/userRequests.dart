
import 'package:flutter/material.dart';
import 'package:mittsure/field/partyRequest.dart';
import 'package:mittsure/field/routes.dart';
import 'package:mittsure/newApp/specimenRequestList.dart';
import 'package:mittsure/screens/Party.dart';
import 'package:mittsure/screens/orders.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:mittsure/services/apiService.dart';

class RequestsScreen extends StatefulWidget {
  @override
  _RequestsScreenState createState() => _RequestsScreenState();
}

class _RequestsScreenState extends State<RequestsScreen> with TickerProviderStateMixin {
  // Your existing state variables...
  String selectedFilter = '';
  String selectedASM = "";
  List<dynamic> asmList = [];
  String selectedRsm = "";
  List<dynamic> rsmList = [];
  String selectedSE = "";
  List<dynamic> seList = [];
  bool isLoading = false;

  List<dynamic> requestTypes = [{"id": "", "name": "All"}];
  List<dynamic> requests = [];
  Map<String, dynamic> userData = {};

  TabController? _tabController;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 4, vsync: this);
  }

  @override
  void dispose() {
    _tabController?.dispose();
    super.dispose();
  }

  // Your existing functions like getUserData, fetchPicklist, _fetChAllRSM, fetchRequests, etc...

  @override
  Widget build(BuildContext context) {
    return DefaultTabController(
      length: 4,
      child: Scaffold(
        
         appBar: AppBar(
          bottom: TabBar(
          controller: _tabController,
          labelColor: Colors.white,
          indicatorColor: Colors.white,
          unselectedLabelColor: Colors.white70,
          tabs: const [
            Tab(text: 'Party'),
            Tab(text: 'Order'),
            Tab(text: 'Route'),
            Tab(text: 'Specimen'),
          ],
        ),
          iconTheme: IconThemeData(color: Colors.white),
          title: Text('User Requests', style: TextStyle(color: Colors.white)),
          backgroundColor: Colors.indigo[900],
          elevation: 0,
        ),
        body: TabBarView(
          controller: _tabController,
          children: [
            PartyReqScreen(),
            OrdersScreen(userReq:true,type: 'Sales',),
            CreatedRoutesPage(userReq: true),
            SpecimenReList(userReq: true,tab:1)
            
          ],
        ),
      ),
    );
  }
}
