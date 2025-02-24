import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:mittsure/screens/commonLayout.js.dart';

import '../services/apiService.dart';

class NotificationScreen extends StatefulWidget {
  @override
  State<NotificationScreen> createState() => _NotificationScreenState();
}

class _NotificationScreenState extends State<NotificationScreen> {

   List<dynamic> notifications = [
    {
      "title": 'New Message',
      "body": 'You have received a new message from John.',
      "timestamp": DateTime.now().subtract(Duration(minutes: 5)),
    },
    {
      "title": 'Order Update',
      "body": 'Your order has been shipped and is on its way.',
      "timestamp": DateTime.now().subtract(Duration(hours: 1)),
}

  ];

  Future<void> _fetchNOtification() async {
    final body = {
      "pageNumber":0

    };

    try {

      final response = await ApiService.post(
        endpoint: '/notification/fetchNotification',  // Use your API endpoint
        body: body,
      );


      if (response != null) {

        final  data = response['data'];

        print(data);
        setState(() {
          notifications = data;
        });
      } else {
        throw Exception('Failed to load orders');
      }
    } catch (error) {
      print("Error fetching orders: $error");
    }
  }

  @override
  void initState() {
    // TODO: implement initState
    super.initState();
    _fetchNOtification();
  }
  @override
  Widget build(BuildContext context) {
    return CommonLayout(currentIndex: 2,
        title: 'Notifications',
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: ListView.builder(
          itemCount: notifications.length,
          itemBuilder: (context, index) {
            final notification = notifications[index];
            final formattedTimestamp =notification['createdAt']==null?"":DateFormat('dd MMM yyyy')
                .format(DateTime.parse(notification['createdAt'].toString()));

            return Card(
              elevation: 5,
              margin: EdgeInsets.symmetric(vertical: 10),
              child: ListTile(
                contentPadding: EdgeInsets.all(16),
                title: Text(
                  notification['notificationTitle'],
                  style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                ),
                subtitle: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(notification['notificationMessage']),
                    SizedBox(height: 8),
                    Text(
                      'Received at: $formattedTimestamp',
                      style: TextStyle(fontSize: 12, color: Colors.grey),
                    ),
                  ],
                ),
                trailing: Icon(Icons.notifications_active, color: Colors.blue),
              ),
            );
          },
        ),
      ),
    );
  }
}
