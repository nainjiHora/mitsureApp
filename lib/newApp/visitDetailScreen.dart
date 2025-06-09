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
        title: Text('Visit Details', style: TextStyle(color: Colors.white)),
        backgroundColor: Colors.indigo[900],
        iconTheme: IconThemeData(color: Colors.white),
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: ListView(
          children: [
            _buildDetailTile('Visit Start Location', '${visitDetails['startLat']}, ${visitDetails['startLong']}'),
            _buildDetailTile('Visit End Location', '${visitDetails['endLat']}, ${visitDetails['endLong']}'),
            _buildDetailTile('Visit Outcome', visitDetails['outcome']),
            _buildDetailTile('Visit Count', '${visitDetails['visitCount']}'),
            _buildDetailTile('Next Follow-Up Date', dateFormat.format(visitDetails['nextFollowUpDate'])),
            _buildDetailTile('Next Step', visitDetails['nextStep']),
            _buildDetailTile('Visit Type', visitDetails['visitType']),
            _buildDetailTile('Meeting Time', timeFormat.format(visitDetails['meetingTime'])),
            _buildDetailTile('Duration', visitDetails['duration']),
          ],
        ),
      ),
    );
  }

  Widget _buildDetailTile(String title, String value) {
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
