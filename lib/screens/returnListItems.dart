import 'package:flutter/material.dart';
import 'package:mittsure/screens/commonLayout.js.dart';

import '../services/apiService.dart';

class ReturnOrderListScreen extends StatefulWidget {
  final id;
  ReturnOrderListScreen({required this.id});
  @override
  State<ReturnOrderListScreen> createState() => _ReturnOrderListScreenState();
}

class _ReturnOrderListScreenState extends State<ReturnOrderListScreen> {
   List<dynamic> orderItems = [];


   String getPrice(item){
     print(item);
     int unitPrice = int.parse(item['unitPrice']??item['landing_cost'].toString());
     int qty = item['qty'];
     int total = unitPrice * qty;

     return total.toString();
   }

  Future<void> _fetchOrders() async {
    final body = {
      "id":widget.id
    };

    try {

      final response = await ApiService.post(
        endpoint: '/order/fetchRetunOrderLineItem',  // Use your API endpoint
        body: body,
      );

      // Check if the response is valid
      if (response != null) {

        final  data = response['data'];


        setState(() {
          print(data);
          orderItems = data;
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

    super.initState();
    _fetchOrders();
  }
  @override
  Widget build(BuildContext context) {
    return CommonLayout(
      currentIndex: 4,
        title: 'Order List',

      child: ListView.builder(
        itemCount: orderItems.length,
        itemBuilder: (context, index) {
          final item = orderItems[index];
          return Card(
            margin: const EdgeInsets.symmetric(vertical: 5, horizontal: 10),
            child: ListTile(
              title: Text(item['nameSku']??item['product_name'], style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
              subtitle: Text('Quantity: ${item['qty']}'),
              trailing: Text('Rs.${getPrice(item)}',
                  style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: Colors.green)),
            ),
          );
        },
      ),
    );
  }
}


