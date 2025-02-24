import 'package:flutter/material.dart';

class DashboardScreen extends StatelessWidget {
  final List<Map<String, dynamic>> orderItems = [
    {'name': 'Apple', 'quantity': 3, 'price': 1.50},
    {'name': 'Banana', 'quantity': 6, 'price': 0.80},
    {'name': 'Orange', 'quantity': 4, 'price': 1.20},
  ];

  int get partyCount => orderItems.length; // Total number of parties/orders
  double get totalOrders => orderItems.fold(0, (sum, item) => sum + item['quantity']); // Total quantity
  double get totalAmount => orderItems.fold(
    0.0,
        (sum, item) => sum + (item['price'] * item['quantity']),
  ); // Total amount

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Executive Dashboard'),
      ),
      body: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // KPIs Section
          Padding(
            padding: const EdgeInsets.all(10.0),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceAround,
              children: [
                _buildKpiCard('Party Count', partyCount.toString(), Colors.blue),
                _buildKpiCard('Orders Booked', totalOrders.toString(), Colors.orange),
                _buildKpiCard('Order Amount', '\$${totalAmount.toStringAsFixed(2)}', Colors.green),
              ],
            ),
          ),
          Divider(thickness: 1, color: Colors.grey[300]),

          // Order List Section
          Expanded(
            child: ListView.builder(
              itemCount: orderItems.length,
              itemBuilder: (context, index) {
                final item = orderItems[index];
                return Card(
                  margin: const EdgeInsets.symmetric(vertical: 5, horizontal: 10),
                  child: ListTile(
                    title: Text(item['name'], style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
                    subtitle: Text('Quantity: ${item['quantity']}'),
                    trailing: Text('\$${(item['price'] * item['quantity']).toStringAsFixed(2)}',
                        style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: Colors.green)),
                  ),
                );
              },
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildKpiCard(String title, String value, Color color) {
    return Container(
      width: 110,
      padding: const EdgeInsets.all(10.0),
      decoration: BoxDecoration(
        color: color.withOpacity(0.2),
        borderRadius: BorderRadius.circular(10),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(
            title,
            style: TextStyle(fontSize: 14, fontWeight: FontWeight.bold, color: color),
            textAlign: TextAlign.center,
          ),
          SizedBox(height: 8),
          Text(
            value,
            style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold, color: Colors.black),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }
}