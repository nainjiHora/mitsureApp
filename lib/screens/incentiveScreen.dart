import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:mittsure/screens/commonLayout.js.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../services/apiService.dart';

class IncentiveScreen extends StatefulWidget {
  @override
  _IncentiveScreenState createState() => _IncentiveScreenState();
}

class _IncentiveScreenState extends State<IncentiveScreen> {
  String totalOrderedAmount = "";
  double incentive = 0;
  double calculatedIncentive=0;
  double enteredAmount = 0;
  List<dynamic> policies=[];

  Future<void> _fetchOrders() async {
    final prefs = await SharedPreferences.getInstance();
    final hasData = prefs.getString('user') != null;
    var id="";
    if (hasData) {
      id=jsonDecode(prefs.getString('user')??"")['id'];
    }
    final body = {
      "userId":id
    };

    try {

      final response = await ApiService.post(
        endpoint: '/order/getInsentive',  // Use your API endpoint
        body: body,
      );

      // Check if the response is valid
      if (response != null) {



       print(response);
        setState(() {
          totalOrderedAmount=response['totalAmount'];
          incentive=response['calculatedIncentive'];
          policies=response['incentiveData'];
        });
      } else {
        throw Exception('Failed to load orders');
      }
    } catch (error) {
      print("Error fetching orders: $error");
    }
  }


  String getPolicies(item){
    var str="";
    if(item['minAmount']!="" && item['maxAmount']!=""){
      str="For amounts between ${item['minAmount']} to ${item['maxAmount']}, ${item['incentivePercent']}% incentive is applicable.";
    }
    if(item['minAmount']=="" && item['maxAmount']!=""){
      str="For amounts upto ${item['maxAmount']}, ${item['incentivePercent']}% incentive is applicable.";
    }
    if(item['minAmount']!="" && item['maxAmount']==""){
      str="For amounts above ${item['minAmount']} , ${item['incentivePercent']}% incentive is applicable.";
    }


    return str;
  }

  double calculateIncentive(double amount) {
    if (amount <= 10000000) {
      return amount * 0.01;  // 1% incentive for up to 10 million
    } else {
      return 10000000 * 0.01 + (amount - 10000000) * 0.02;  // 2% for amounts above 10 million
    }
  }




  @override
  void initState() {
    super.initState();

    _fetchOrders();// Update incentive on load
  }

  @override
  Widget build(BuildContext context) {
    return CommonLayout(title: 'Incentive Calculator',
       currentIndex: 2,
      child: SingleChildScrollView(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [

            Text("Incentive Calculator",
              style: TextStyle(fontSize: 30, fontWeight: FontWeight.bold),
            ),
            SizedBox(height: 40),
            Text(
              'Enter Amount to Calculate Incentive:',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
            TextField(
              keyboardType: TextInputType.number,
              decoration: InputDecoration(
                hintText: 'Enter amount',
                border: OutlineInputBorder(),
                contentPadding: EdgeInsets.symmetric(vertical: 10, horizontal: 15),
              ),
              onChanged: (value) {
                setState(() {
                  enteredAmount = double.tryParse(value) ?? 0;
                });
              },
            ),
            SizedBox(height: 20),

            ElevatedButton(
              onPressed: () {
                setState(() {
                  calculatedIncentive = calculateIncentive(enteredAmount);
                });
              },
              child: Text('Calculate ',style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold,color: Colors.indigo),),
              style: ElevatedButton.styleFrom(
                // primary: Colors.indigo, // Button color
                padding: EdgeInsets.symmetric(vertical: 14,horizontal: 8),
                textStyle: TextStyle(fontSize: 18, fontWeight: FontWeight.bold,color: Colors.indigo),
              ),
            ),
            SizedBox(height: 20),

            // Display Calculated Incentive
            Text(
              'Calculated Incentive: ₹${calculatedIncentive.toStringAsFixed(2)}',
              style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
            ),
          ],
        ),
      ),
    );
  }
}
