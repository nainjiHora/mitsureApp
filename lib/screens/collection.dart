import 'package:flutter/material.dart';
import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:mittsure/screens/commonLayout.js.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../services/apiService.dart';
import 'login.dart';

class CollectionScreen extends StatefulWidget {
  @override
  _CollectionScreenState createState() => _CollectionScreenState();
}

class _CollectionScreenState extends State<CollectionScreen> {
   List<dynamic> _items = [];
  int _currentPage = 1; // Current page number
  bool _isLoading = false; // To prevent multiple API calls
  bool _hasMore = false; // To check if more data is available

  final ScrollController _scrollController = ScrollController();

  Future<void> _fetchData() async {
    final body = {
      "pageNumber":0
    };

    try {

      final response = await ApiService.post(
        endpoint: '/collection/getCollection',  // Use your API endpoint
        body: body,
      );

      if (response != null) {

        if(response['code']==500){
          _logout();
        }
        setState((){
          _isLoading=false;
          _items=response['data'];
        });

        print(response);
      } else {
        throw Exception('Failed to load orders');
      }
    } catch (error) {
      print("Error fetching orders: $error");
    }
  }

  @override
  void initState() {
    super.initState();
    _fetchData(); // Fetch initial data
    _scrollController.addListener(_onScroll); // Listen for scroll events
  }

  @override
  void dispose() {
    _scrollController.dispose();
    super.dispose();
  }



  void _onScroll() {
    if (_scrollController.position.pixels ==
        _scrollController.position.maxScrollExtent &&
        !_isLoading &&
        _hasMore) {
      _fetchData(); // Fetch the next page
    }
  }

  @override
  Widget build(BuildContext context) {
    return CommonLayout(
        title: 'Collections',
      currentIndex: 3,
      child: _isLoading
          ? const Center(child: CircularProgressIndicator()) // Show loader initially
          : _items.length>0?ListView.builder(
        controller: _scrollController,
        itemCount: _items.length + (_hasMore ? 1 : 0), // Show loader at the bottom if more data exists
        itemBuilder: (context, index) {
          if (index == _items.length&& _hasMore) {
            return const Center(child: CircularProgressIndicator()); // Bottom loader
          }

          final item = _items[index];
          return Card(
            margin: EdgeInsets.symmetric(vertical: 8, horizontal: 16),
            elevation: 3,
            child: ListTile(
              title: Text(
                "Invoice ID:"+_items[index]['invoiceId']??_items[index]['invoiceId'],
                style: TextStyle(fontWeight: FontWeight.bold),
              ),
              subtitle: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text('Party: ${_items[index]['schoolName']??_items[index]['DistributorName']}',style: TextStyle(fontSize: 18),),
                  Text('Amount: ${_items[index]['amount']}'),
                ],
              ),
              // trailing: Icon(Icons.arrow_forward_ios, color: Colors.grey),

            ),
          );
        },
      ):Center(child: Text("No Collection Items"),),
    );
  }
  void _logout()async {

    final prefs = await SharedPreferences.getInstance();
    await prefs.clear();
    Navigator.push(
      context,
      MaterialPageRoute(builder: (context) =>LoginScreen()), // Route to HomePage
    );

  }
}
