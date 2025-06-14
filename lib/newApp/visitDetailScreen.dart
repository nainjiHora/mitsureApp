import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

class VisitDetailsScreen extends StatelessWidget {
  final Map<String, dynamic> visitDetails;

  VisitDetailsScreen({super.key, required this.visitDetails});

  @override
  Widget build(BuildContext context) {
    final dateFormat = DateFormat('dd-MM-yyyy');
    final timeFormat = DateFormat('hh:mm a');

    return Scaffold(
      appBar: AppBar(
        title: Text(visitDetails['schoolName']??visitDetails['DistributorName'], style: TextStyle(color: Colors.white)),
        backgroundColor: Colors.indigo[900],
        iconTheme: IconThemeData(color: Colors.white),
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: ListView(
          children: [
            _buildDetailTile('Visit Start Time', '${formatIsoToLocal(visitDetails['startTime'])}'),
            _buildDetailTile('Visit End Time', '${formatIsoToLocal(visitDetails['endTime'])}'),
            _buildDetailTile('Visit Location', visitDetails["start_address"]??""),
            _buildDetailTile('Visit Outcome', visitDetails['visitOutcomeName']??""),
            _buildDetailTile('Visit Count', '${visitDetails['visit_count'].toString()}'),
            // _buildDetailTile('Next Follow-Up Date', dateFormat.format(visitDetails['followUpDate']??"")),
            _buildDetailTile('Next Step', visitDetails['nextStepName']??""),
            _buildDetailTile('Visit Type', visitDetails['typeName']??""),
            _buildDetailTile('Work Done', visitDetails['workDoneName']??""),
            _buildDetailTile('Status', visitDetails['statusTypeName']??""),
          ],
        ),
      ),
    );
  }
  String formatIsoToLocal(String isoDateStr, {String format = 'dd-MM-yyyy hh:mm a'}) {
  try {
    DateTime utcDate = DateTime.parse(isoDateStr);
    DateTime localDate = utcDate.toLocal();
    return DateFormat(format).format(localDate);
  } catch (e) {
    return 'Invalid date';
  }
}

  Widget _buildDetailTile(String title, String value) {
    print(value);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(title,
            style: TextStyle(fontWeight: FontWeight.bold, fontSize: 14, color: Colors.grey[700])),
        SizedBox(height: 4),
        Text(value, style: TextStyle(fontSize: 16)),
        Divider(height: 24),
      ],
    );
  }
}
