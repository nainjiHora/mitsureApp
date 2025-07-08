import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:mittsure/newApp/bookLoader.dart';
import 'package:mittsure/services/apiService.dart';

class VisitDetailsScreen extends StatefulWidget {
  final Map<String, dynamic> visitDetails;

  VisitDetailsScreen({super.key, required this.visitDetails});

  @override
  State<VisitDetailsScreen> createState() => _VisitDetailsScreenState();
}

class _VisitDetailsScreenState extends State<VisitDetailsScreen> {

bool isLoading=true;
Map<dynamic,dynamic> visitData={};

  @override
  void initState() {
    // TODO: implement initState
    super.initState();
   fetchVisit();
  }

  fetchVisit()async{
    
    try {
      setState(() {
        isLoading = true;
      });
      final response =
          await ApiService.post(endpoint: '/visit/fetchVisitById', body: {
            "visitId":widget.visitDetails['visitId']
          });

      if (response != null) {
        final data = response['data'];
        setState(() {
          print(data);
          visitData=data.length>0?data[0]:{};
          isLoading=false;
        });
      } else {
        throw Exception('Failed to load orders');
      }
    } catch (error) {
      print("Error fetching ojbjbjbjjrders: $error");
    } finally {
      setState(() {
        isLoading=false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final dateFormat = DateFormat('dd-MM-yyyy');
    final timeFormat = DateFormat('hh:mm a');

    return Scaffold(
      appBar: AppBar(
        title: Text(widget.visitDetails['schoolName']??widget.visitDetails['DistributorName']??"N/A", style: TextStyle(color: Colors.white)),
        backgroundColor: Colors.indigo[900],
        iconTheme: IconThemeData(color: Colors.white),
      ),
      body: Stack(
        children: [Padding(
          padding: const EdgeInsets.all(16.0),
          child: ListView(
            children: [
              _buildDetailTile('Visit Start Time', '${formatIsoToLocal(visitData['startTime']??"")}'??"N/A"),
              _buildDetailTile('Visit End Time', '${formatIsoToLocal(visitData['endTime']??"")}'??"N/A"),
              _buildDetailTile('Visit Location', visitData["start_address"]??"N/A"),
              _buildDetailTile('Visit Outcome', visitData['visitOutcomeName']??"N/A"),
              _buildDetailTile('Next Step', visitData['nextStepName']??"N/A"),
              _buildDetailTile('Visit Type', visitData['typeName']??"N/A"),
              _buildDetailTile('Work Done', visitData['workDoneName']??"N/A"),
              _buildDetailTile('Further Visit Required', jsonDecode(visitData['furtherVisitRequired']??jsonEncode({}))['visit_required']!=null?jsonDecode(visitData['furtherVisitRequired']??jsonEncode({}))['visit_required']?"YES":"NO":"N/A"),
              _buildDetailTile('Further Visit Remark', jsonDecode(visitData['furtherVisitRequired']??jsonEncode({}))['reason']??"N/A"),
               _buildDetailTile('Remark', visitData['extra']??"N/A"),
              _buildDetailTile('Status', visitData['statusTypeName']??"N/A"),
            ],
          ),
        ),
        if(isLoading)
        BookPageLoader()

        
        ]
      ),
    );
  }

  String formatIsoToLocal(String isoDateStr, {String format = 'dd-MM-yyyy hh:mm a'}) {
  try {
   if(isoDateStr!=null){ DateTime utcDate = DateTime.parse(isoDateStr);
    DateTime localDate = utcDate.toLocal();
    return DateFormat(format).format(localDate);}
    else{
      return "N/A";
    }
  } catch (e) {
    return 'Invalid date';
  }
}

  Widget _buildDetailTile(String title, String value) {
    print(value);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(title??"N/A",
            style: TextStyle(fontWeight: FontWeight.bold, fontSize: 14, color: Colors.grey[700])),
        SizedBox(height: 4),
        Text(value, style: TextStyle(fontSize: 16)),
        Divider(height: 24),
      ],
    );
  }
}
