import 'package:flutter/material.dart';
import 'package:flutter/widgets.dart';
import 'package:mittsure/newApp/MainMenuScreen.dart';
import 'package:mittsure/newApp/hointervention.dart';
import 'package:mittsure/newApp/visitPartyDetail.dart';
import 'package:mittsure/services/apiService.dart';
import 'package:multi_select_flutter/chip_display/multi_select_chip_display.dart';
import 'package:multi_select_flutter/dialog/multi_select_dialog_field.dart';
import 'package:multi_select_flutter/util/multi_select_item.dart';
import 'ReeviewAnswersScreen.dart';

class MeetingHappen extends StatefulWidget {
final Map<String, dynamic> data;
  final type;
  final date;
  final visitStatus;
  final userReq;
  final visitId;

  MeetingHappen(
      {Key? key,
      required this.data,
      required this.type,
      required this.date,
      required this.userReq,
      required this.visitStatus,
      this.visitId});
  
 

  @override
  State<MeetingHappen> createState() => _MeetingHappenState();
}

class _MeetingHappenState extends State<MeetingHappen> {
  List<Map<dynamic, dynamic>> answers = [{}];
  List<dynamic> categories = [];
  List<String?> selectedCategories = [];
  List<List<dynamic>> questionList = [[]];
  List<dynamic> questions = [];

  String? interested=null;
  String? selectedReason;
  String? daysNeeded;
  int selectedindex = 0;
  List<dynamic> reasons = [];

  @override
  void initState() {
    super.initState();
    
    fetchReason();
  }

  fetchReason() async {
    try {
      final response = await ApiService.post(
        endpoint: '/picklist/getReasonList',
        body: {},
      );

      if (response != null) {
        final data = response['data'];
        setState(() {
          reasons = data;
        });
      }
    } catch (error) {
      print("Error fetching reasons: $error");
    }
  }

  
  @override
  Widget build(BuildContext context) {
    return Scaffold(
     
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(8.0),
          child: Column(
            children: [
              Expanded(
                  child: ListView(children: [
                    Padding(
                      padding: const EdgeInsets.all(12.0),
                      child: Text("Is Decision Maker/School Authority Available for Meeting ?",style: TextStyle(fontWeight: FontWeight.bold)),
                    ),
                _buildDropdown(
                  "",
                  [
                    {"name": 'Yes'},
                    {"name": 'No'}
                  ],
                  "name",
                  "name",
                  interested,
                  (value) {
                    setState(() {
                      interested = value;
                    });
                  },
                ),
               
               
              ])),
              ElevatedButton.icon(
                onPressed: () {
                  if (interested!.toLowerCase() == 'yes') {
                   Navigator.pushReplacement(
                      context,
                      MaterialPageRoute(
                        builder: (context) => RouteDetailsScreen(
                            visitId:widget.visitId,
                            visitStatus:widget.visitStatus,
                            userReq:widget.userReq,
                            date:widget.date,
                            type:widget.type,
                            data:widget.data
                      )));
                    
                  } else {
                    // Navigator.push(
                    //   context,
                    //   MaterialPageRoute(
                    //     builder: (context) => HoInterventionScreen(
                    //         answers: [],
                    //         payload: widget.payload,
                    //         visit: widget.visit,
                    //         interested: selectedReason),
                    //   ),
                    // );
                  }
                },
                icon: Icon(Icons.remove_red_eye_outlined),
                label: Text("Submit"),
              ),
            ],
          ),
        ),
      ),
    );
  }

  

  Widget _buildDropdown(
    String label,
    List<dynamic> items,
    String keyId,
    String keyName,
    String? value,
    ValueChanged<String?> onChanged,
  ) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 12),
      child: DropdownButtonFormField<String>(
        decoration: InputDecoration(
          labelText: label,
          border: OutlineInputBorder(borderRadius: BorderRadius.circular(8)),
          contentPadding:
              const EdgeInsets.symmetric(horizontal: 12, vertical: 14),
        ),
        value: value,
        items: items
            .map((item) => DropdownMenuItem<String>(
                  value: item[keyId].toString(),
                  child: Text(item[keyName] ?? ""),
                ))
            .toList(),
        onChanged: onChanged,
        validator: (val) =>
            val == null || val.isEmpty ? 'Please select $label' : null,
      ),
    );
  }
}
