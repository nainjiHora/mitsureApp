import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:mittsure/screens/commonLayout.js.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../services/apiService.dart';

class NotificationScreen extends StatefulWidget {
  @override
  State<NotificationScreen> createState() => _NotificationScreenState();
}

class _NotificationScreenState extends State<NotificationScreen> {

   List<dynamic> notifications = [];

  Future<void> _fetchNOtification() async {
    final prefs = await SharedPreferences.getInstance();
    final hasData = prefs.getString('user') != null;
    var id = "";
    if (hasData) {
      id = jsonDecode(prefs.getString('user') ?? "")['id'];
    }
    final body = {"ownerId": id};


    try {

      final response = await ApiService.post(
        endpoint: '/notification/getNotification',  // Use your API endpoint
        body: body,
      );

print(response['data']);
print("pointuy");
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
            final formattedTimestamp =notification['createAt']==null?"":DateFormat('dd MMM yyyy')
                .format(DateTime.parse(notification['createAt'].toString()));

            return Card(
              elevation: 5,
              margin: EdgeInsets.symmetric(vertical: 10),
              child: ListTile(
                contentPadding: EdgeInsets.all(16),
                title: Text(
                  notification['header'],
                  style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                ),
                subtitle: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(notification['body']),
                    SizedBox(height: 8),
                    Text(
                      'Received at: $formattedTimestamp',
                      style: TextStyle(fontSize: 12, color: Colors.grey),
                    ),
                  ],
                ),
                trailing: notification['is_read']==0?Icon(Icons.notifications_active, color: Colors.blue):null,
              ),
            );
          },
        ),
      ),
    );
  }
}
