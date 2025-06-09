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
  int selectedPercent=0;
  double incentive = 0;
  String? selectedSeries;
  List<dynamic> incentiveList=[];
  List<dynamic> series=[];
  double calculatedIncentive=0;
  double enteredAmount = 0;
  bool loading=false;
  List<dynamic> policies=[];

  Future<void> _fetchOrders() async {
    final prefs = await SharedPreferences.getInstance();
    final hasData = prefs.getString('user') != null;
    var id = "";
    if (hasData) {
      id = jsonDecode(prefs.getString('user') ?? "")['id'];
    }
    final body = {"ownerId": id};

    try {
      setState(() {
        loading = true;
      });

      final response = await ApiService.post(
        endpoint: '/order/getGroupedIncentives',
        body: body,
      );

      if (response != null) {


        setState(() {
          List<dynamic> c=response['data'];
          List<dynamic> a=[];
          List<dynamic> b=response['series_name'];
          incentiveList=response['inc'];
          for(var i=0;i<b.length;i++){
            var obj={"series":b[i]['seriesName'],"amount":0,"color":b[i]['color']};
            for(var j=0;j<c.length;j++){

              if(c[j]['seriesId']==b[i]['seriesTableId']){
                obj['amount']=obj['amount']+c[j]['totalAmount'];
                incentive+=c[j]['totalAmount'];
              }
            }
            a.add(obj);
          }

          loading = false;
          series=response['series_name'];

        });
      } else {
        throw Exception('Failed to load orders');
      }
    } catch (error) {
      print("Error fetddching orders: $error");
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
   return amount*(selectedPercent/100);
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
            Text("Incentive Earned",
              style: TextStyle(fontSize: 30, fontWeight: FontWeight.bold),
            ),
            Text(
              incentive.toStringAsFixed(2).toString(),
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
            Text("Incentive Calculator",
              style: TextStyle(fontSize: 30, fontWeight: FontWeight.bold),
            ),
            SizedBox(height: 40),
        DropdownButtonFormField<String>(
          decoration: InputDecoration(
            labelText: "Series",
            border: const OutlineInputBorder(),
            contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 14),
          ),
          value: selectedSeries,
          items: series.map((item) => DropdownMenuItem(value: item!['seriesTableId']!.toString(), child: Text(item["seriesName"].toUpperCase()??""))).toList(),
          onChanged: (value){
            var a=incentiveList.where((ele)=>ele['seriesId']==value).toList()[0];
            setState(() {
              selectedPercent=int.parse(a['incentivePercent'].toString());
            });

          },
        ),
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
              child: Text('Calculate ',style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold,color: Colors.indigo[900]),),
              style: ElevatedButton.styleFrom(
                // primary: Colors.indigo[900], // Button color
                padding: EdgeInsets.symmetric(vertical: 14,horizontal: 8),
                textStyle: TextStyle(fontSize: 18, fontWeight: FontWeight.bold,color: Colors.indigo[900]),
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
