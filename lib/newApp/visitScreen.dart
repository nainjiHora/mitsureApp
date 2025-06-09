import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:mittsure/newApp/visitDetailScreen.dart';

class Visit {
  final String partyName;
  final String partyAddress;

  Visit({required this.partyName, required this.partyAddress});
}

class VisitListScreen extends StatefulWidget {
  @override
  _VisitListScreenState createState() => _VisitListScreenState();
}

class _VisitListScreenState extends State<VisitListScreen> {
  DateTimeRange? _selectedDateRange;
  final DateFormat _dateFormat = DateFormat('dd-MM-yyyy');

  List<Visit> visits = [
    Visit(partyName: 'Saint SOldier Public School', partyAddress: '123 Market St, New York'),
    Visit(partyName: 'Maheshwari Public School', partyAddress: '456 Sunset Blvd, LA'),
    Visit(partyName: 'VIdhyashram School', partyAddress: '789 Silicon Ave, SF'),
  ];

  @override
  void initState() {
    super.initState();
    final today = DateTime.now();
    _selectedDateRange = DateTimeRange(start: today, end: today);
  }

  void _pickDateRange() async {
    DateTimeRange? picked = await showDateRangePicker(
      context: context,
      firstDate: DateTime(2023),
      lastDate: DateTime.now().add(Duration(days: 365)),
      initialDateRange: _selectedDateRange,
    );

    if (picked != null) {
      setState(() {
        _selectedDateRange = picked;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    String dateFilterText = _selectedDateRange == null
        ? 'Select Date Range'
        : '${_dateFormat.format(_selectedDateRange!.start)} - ${_dateFormat.format(_selectedDateRange!.end)}';

    return Scaffold(
      appBar: AppBar(
        title: Text(
          'Visits',
          style: TextStyle(color: Colors.white),
        ),
        iconTheme: IconThemeData(color: Colors.white),
        backgroundColor: Colors.indigo[900],
      ),
      body: Column(
        children: [
          SizedBox(height: 10),
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              InkWell(
                onTap: _pickDateRange,
                child: Padding(
                  padding: const EdgeInsets.all(12.0),
                  child: Row(
                    children: [
                      Icon(Icons.date_range),
                      SizedBox(width: 8),
                      Text(
                        dateFilterText,
                        style: TextStyle(fontSize: 16,fontWeight: FontWeight.w600),
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),
          Divider(),
          Expanded(
            child: ListView.builder(
              itemCount: visits.length,
              itemBuilder: (context, index) {
                final visit = visits[index];
                return GestureDetector(
                  onTap: (){
                    Navigator.push(
  context,
  MaterialPageRoute(
    builder: (_) => VisitDetailsScreen(
      visitDetails: {
        'startLat': 37.4219983,
        'startLong': -122.084,
        'endLat': 37.4275,
        'endLong': -122.1697,
        'outcome': 'Successful demo & feedback collected',
        'visitCount': 3,
        'nextFollowUpDate': DateTime.now().add(Duration(days: 7)),
        'nextStep': 'Send Proposal',
        'visitType': 'Client Meeting',
        'meetingTime': DateTime.now(),
        'duration': '45 mins',
      },
    ),
  ),
);
                  },
                  child: ListTile(
                    title: Text(visit.partyName,style: TextStyle(fontWeight: FontWeight.w600),),
                    subtitle: Text(visit.partyAddress),
                    leading: Icon(Icons.location_on),
                  ),
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}
