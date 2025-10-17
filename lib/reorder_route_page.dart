import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:mittsure/field/createRoute.dart';
import 'package:mittsure/field/routes.dart';
import 'package:mittsure/services/apiService.dart';
import 'package:mittsure/services/utils.dart';
import 'package:shared_preferences/shared_preferences.dart';

class ReorderRoutePage extends StatefulWidget {
  final List<dynamic> routes;
  final List<dynamic> schools;
  final List<dynamic> distributors;
  final List<dynamic> visitType;
  final String tagPartner;
  final selectedRM;


  const ReorderRoutePage({super.key, required this.routes,required this.selectedRM,required this.schools,required this.distributors,required this.tagPartner,required this.visitType});

  @override
  State<ReorderRoutePage> createState() => _ReorderRoutePageState();
}

class _ReorderRoutePageState extends State<ReorderRoutePage> {
  late List<dynamic> _routeList; 
  bool isLoading =false;


  @override
  void initState() {
    super.initState();
    print(widget.routes);
    
    _routeList =widget.routes;
  }

  eNameById(id){
    print(widget.visitType);
   final a= widget.visitType.firstWhere((element) => element['routeVisitTypeID']==id);
   print(a);
   return a['routeVisitType'];
  }

  void _onReorder(int oldIndex, int newIndex) {
    setState(() {
      if (newIndex > oldIndex) newIndex--;
      final item = _routeList.removeAt(oldIndex);
      _routeList.insert(newIndex, item);
    });
  }

getName(item){
if(item['partyType']=='1'){
final n=widget.schools.where((element) => element['schoolId']==item['partyId']).toList()[0];
return n['schoolName'];
}
else{
  final n=widget.distributors.where((element) => element['distributorID']==item['partyId']).toList()[0];
return n['DistributorName'];
}
}

void _submitReorderedRoutes() async {
  setState(() {
     isLoading = true;
   });
   final prefs = await SharedPreferences.getInstance();
   final hasData = prefs.getString('user') != null;
   var user = {};
   if (hasData) {
     user = jsonDecode(prefs.getString('user') ?? "");
   }else{
    
     return;
   }
final List<Map<dynamic, dynamic>> serializableRoutes = _routeList
    .asMap()
    .entries
    .map((entry) {
      int index = entry.key;
      var route = entry.value;
      return {
        ...route,
        'date': route['date'].millisecondsSinceEpoch/1000,
        'partyInd': index, // 👈 Add index here
      };
    })
    .toList();

print(serializableRoutes);

   final body = {
     "ownerId": user['role']=='se'?user['id']:widget.selectedRM,
     "date":serializableRoutes[0]['date'],
     "routeVisitId":widget.routes[0]['partyType'],
     "partyList":serializableRoutes,
     "tagged_id":widget.tagPartner,
   };

print(body);

   try {
    
     final response = await ApiService.post(
       endpoint:'/routePlan/addRoutePlan',
       body: body,
     );
     if (response != null && response['status']==false) {

       Navigator.push(
      context,
      MaterialPageRoute(builder: (context) => CreatedRoutesPage(userReq:false)),
    );
      
     } else {
      print("popop");
      print(response);
       ScaffoldMessenger.of(context).showSnackBar(
         SnackBar(content: Text(response['message']),backgroundColor: Colors.red,),
         
      );
       
     }
   } catch (error) {
     print("Error fetchidddddng orders: $error");
     DialogUtils.showCommonPopup(context: context, message: "Something Went Wrong !!", isSuccess: false);
   } finally {
     setState(() {
       isLoading = false;
     });
   }
}

@override
Widget build(BuildContext context) {
  return Scaffold(
    appBar: AppBar(
      iconTheme: IconThemeData(color:Colors.white),
      title: const Text('Review Parties',style: TextStyle(color: Colors.white),),
    backgroundColor: Colors.indigo.shade900,),
    
    body: Column(
      children: [
        Expanded(
          child: ReorderableListView(
            padding: const EdgeInsets.all(16),
            onReorder: _onReorder,
            children: [
              for (int index = 0; index < _routeList.length; index++)
                Card(
                  key: ValueKey(index),
                  elevation: 2,
                  margin: const EdgeInsets.only(bottom: 12),
                  child: ListTile(
                    title: Text(getName(_routeList[index])),
                    subtitle: Text(
                      "${eNameById(_routeList[index]['visitType'])} on "
                      "${_routeList[index]['date'].day}/${_routeList[index]['date'].month}/${_routeList[index]['date'].year}",
                    ),
                    trailing: const Icon(Icons.drag_handle),
                  ),
                )
            ],
          ),
        ),
        ElevatedButton.icon(
          style: ButtonStyle(
            backgroundColor:
            MaterialStateProperty.all(Colors.green),
            minimumSize: MaterialStateProperty.all(
                const Size(180, 48)), // width: 180, height: 48
          ),
          onPressed: _submitReorderedRoutes,
          icon: const Icon(Icons.arrow_forward,
              color: Colors.white),
          label: const Text('Submit',
              style: TextStyle(color: Colors.white)),
        ),

      ],
    ),
  );
}

}
