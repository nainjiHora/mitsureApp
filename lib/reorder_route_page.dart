import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:mittsure/field/createRoute.dart';
import 'package:mittsure/field/routes.dart';
import 'package:mittsure/services/apiService.dart';
import 'package:shared_preferences/shared_preferences.dart';

class ReorderRoutePage extends StatefulWidget {
  final List<dynamic> routes;
  final List<dynamic> schools;
  final List<dynamic> distributors;


  const ReorderRoutePage({super.key, required this.routes,required this.schools,required this.distributors});

  @override
  State<ReorderRoutePage> createState() => _ReorderRoutePageState();
}

class _ReorderRoutePageState extends State<ReorderRoutePage> {
  late List<dynamic> _routeList; 
  bool isLoading =false;


  @override
  void initState() {
    super.initState();
    _routeList =widget.routes;
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
   var id = "";
   if (hasData) {
     id = jsonDecode(prefs.getString('user') ?? "")['id'];
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
     "ownerId": id,
     "date":serializableRoutes[0]['date'],
     "routeVisitId":widget.routes[0]['partyType'],
     "partyList":serializableRoutes
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
      MaterialPageRoute(builder: (context) => CreatedRoutesPage()),
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
   } finally {
     setState(() {
       isLoading = false;
     });
   }
}

@override
Widget build(BuildContext context) {
  return Scaffold(
    appBar: AppBar(title: const Text('Reorder Parties')),
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
                      "${_routeList[index]['visitType']} - ${_routeList[index]['partyType']} on "
                      "${_routeList[index]['date'].day}/${_routeList[index]['date'].month}/${_routeList[index]['date'].year}",
                    ),
                    trailing: const Icon(Icons.drag_handle),
                  ),
                )
            ],
          ),
        ),
        Padding(
          padding: const EdgeInsets.all(16.0),
          child: SizedBox(
            width: double.infinity,
            child: ElevatedButton(
              onPressed: _submitReorderedRoutes,
              child: const Text("Submit"),
            ),
          ),
        ),
      ],
    ),
  );
}

}
