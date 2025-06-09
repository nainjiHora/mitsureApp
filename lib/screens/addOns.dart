import 'package:flutter/material.dart';
import 'package:mittsure/screens/selectionScreen.dart';

import '../services/apiService.dart';

class AddOnProductsScreen extends StatefulWidget {
  final payload;
  final items;
  final series;
  AddOnProductsScreen({required this.payload, required this.items, required this.series});

  @override
  State<AddOnProductsScreen> createState() => _AddOnProductsScreenState();
}

class _AddOnProductsScreenState extends State<AddOnProductsScreen> {
  var confuse = {};
  bool isChecked = false;
  List<dynamic> prize = [];
  List<dynamic> addOnProducts = [];
  List<dynamic> dropMenu = [];
  bool isLoading=true;

  getMenu(pp) async {
    final body = {"id": pp.map((ele) => ele['menu']).toList()};

    try {
      final response = await ApiService.post(
        endpoint: '/product/getAddOnsMenu',
        body: body,
      );

      // Check if the response is valid
      if (response != null) {
        final data = response['data'];
        setState(() {
          dropMenu = data;
          isLoading=false;
        });
      }
    } catch (error) {
      print("Error fetching orders: $error");
    }
  }

  getMenuBasedonid(id) {
    List<DropdownMenuItem<String>> dropdownItems = [
      DropdownMenuItem<String>(
        value: "",
        child: Text('Select', style: TextStyle(color: Colors.indigo[900])),
      ),
    ];

    for (var item in dropMenu) {
      if (item['id'] == id || item['id'].toString() == id) {

        if (item['name'] != null) {
          dropdownItems.add(
            DropdownMenuItem<String>(
              value: item['name'].toString(),
              child: Text(item['name'].toString(), style: TextStyle(color: Colors.indigo[900])),
            ),
          );
        }
      }
    }

    return dropdownItems; // Return a List<DropdownMenuItem<String>>
  }

  void showComingSoonPopup(BuildContext context) {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: Text("You must select all the Add ONs to proceed"),

          actions: [
            TextButton(
              onPressed: () {
                Navigator.of(context).pop(); // Close the dialog
              },
              child: Text('OK'),
            ),
          ],
        );
      },
    );
  }
  Future<void> order() async {

    if (prize.where((ele)=>ele['selected']=="").toList().length>0) {
      showComingSoonPopup(context);
      return;
    }
    var body = widget.payload;
    body['addOns']=prize.map((ele)=>ele['selected']).toList();
    body['onBoardERP']=isChecked??false;

    try {

      Navigator.push(
        context,
        MaterialPageRoute(builder: (context) =>CreateOrderScreen(payload: body)), // Route to HomePage
      );

    } catch (error) {
      print("Error creating order: $error");
      // _showErrorMessage("Failed to place the order. Please try again.");
    }
  }
  getAddONs() async {
    final a = confuse.keys.toList();
    final filteredSeries = widget.series.where((e) => a.contains(e['seriesTableId'])).toList();
    final addOns = filteredSeries.map((e) => e['addOnProduct']).toList();
    final add=addOns.where((ele)=>ele!=null).toList();


    final body = {"id": add};

    try {
      if(add.length>0) {
        final response = await ApiService.post(
          endpoint: '/product/getAddOns',
          body: body,
        );
        print(response);
        // Check if the response is valid
        if (response != null) {
          final data = response['data'];
          for (var series in filteredSeries) {
            for (var add in data) {
              if (add['product_id'] == series['addOnProduct']) {
                if (add['condition'] == "set") {
                  if (confuse[series['seriesTableId']]["set"]["total"] >=
                      add['amount']) {
                    final result = confuse[series['seriesTableId']]["set"]["total"] /
                        add['amount'];
                    final n = result.floor();

                    for (var i = 0; i < n; i++) {
                      prize.add({
                        "menu": add['name'],
                        "selected": "",
                        "series": series['seriesName']
                      });
                    }
                  }
                } else {
                  if (confuse[series['seriesTableId']]["individual"]["total"] >=
                      add['amount'] &&
                      (confuse[series['seriesTableId']]["individual"]["count"] >=
                          add['bookCount']) &&
                      (add['maxCount'] == null || add['maxCount'] >=
                          confuse[series['seriesTableId']]["individual"]["count"])) {
                    final result = confuse[series['seriesTableId']]["individual"]["total"] /
                        add['amount'];
                    final n = result.floor();

                    for (var i = 0; i < n; i++) {
                      prize.add({
                        "menu": add['name'],
                        "selected": "",
                        "series": series['seriesName']
                      });
                    }
                  }
                }
              }
            }
          }
          if (prize.length > 0) {
            getMenu(prize);
          } else {
            setState(() {
              isLoading = false;
            });
          }
        } else {
          throw Exception('Failed to load orders');
        }
      }else{
        setState(() {
          isLoading=false;
        });
      }
    } catch (error) {
      print("Error fetching orders: $error");
    }
  }

  groupData(items) {
    for (var item in items) {
      if (!confuse.containsKey(item.series)) {
        confuse[item.series] = {
          "set": {'total': 0.0, "count": 0},
          "individual": {'total': 0.0, "count": 0}
        };
      }
      final mrp = item.price * item.qty;

      if (item.itemType.toLowerCase() == 'choose from set') {
        confuse[item.series]['set']['total'] = confuse[item.series]['set']['total'] + mrp;
      } else {
        confuse[item.series]['individual']['total'] = confuse[item.series]['individual']['total'] + mrp;
        confuse[item.series]['individual']['count']++;
      }
    }
    getAddONs();
  }

  @override
  void initState() {
    super.initState();
    groupData(widget.items);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(

      appBar: AppBar(

        title: Text("Add-On Products", style: TextStyle(fontFamily: 'Roboto', fontSize: 20,color: Colors.white)),
        backgroundColor: Colors.indigo[900],
    leading: IconButton(
    icon: Icon(Icons.arrow_back, color: Colors.white),
    onPressed: () {
    Navigator.pop(context);
    },
      ),
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Title
            Text(
              "Complimentary Products with Your Order",
              style: TextStyle(
                fontSize: 22,
                fontWeight: FontWeight.bold,
                color: Colors.indigo[900],
                fontFamily: 'Montserrat',
              ),
            ),
            const SizedBox(height: 10),

            // Subtitle
            Text(
              "The following add-on products are provided as complimentary offers with your order:",
              style: TextStyle(fontSize: 16, color: Colors.black54, fontFamily: 'Roboto'),
            ),
            const SizedBox(height: 20),

          Row(
            mainAxisAlignment: MainAxisAlignment.start,
            children: [
              Checkbox(
                value: isChecked,
                onChanged: (bool? value) {
                  setState(() {

                    isChecked = value ?? false;
                  });
                },
              ),
              Text("Onboard For ERP",style:TextStyle(fontSize: 20)),
            ],
          ),
            isLoading?Center(child: CircularProgressIndicator(),):Expanded(
              child: prize.length>0?ListView.builder(
                itemCount: prize.length,
                itemBuilder: (context, index) {

                  final item = prize[index];
                  final id = item['menu'];
                  final dropdownOptions = getMenuBasedonid(id) ?? [];

                  return Padding(
                    padding: const EdgeInsets.all(8.0),
                    child: Card(
                      elevation: 5,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(15),
                      ),
                      color: Colors.indigo[900],
                      child: Padding(
                        padding: const EdgeInsets.all(16.0),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              "Select ${(index + 1).toString()} Add-on Item",
                              style: TextStyle(
                                fontSize: 18,
                                fontWeight: FontWeight.bold,
                                color: Colors.indigo[900],
                                fontFamily: 'Montserrat',
                              ),
                            ),
                            Text(
                              "Series: ${item['series']}",
                              style: TextStyle(
                                fontSize: 15,
                                fontWeight: FontWeight.bold,
                                color: Colors.indigo[900],
                                fontFamily: 'Montserrat',
                              ),
                            ),
                            const SizedBox(height: 10),
                            DropdownButton<String>(
                              value: item['selected'],
                              hint: Text('Select an option', style: TextStyle(color: Colors.black54)),
                              items: dropdownOptions,
                              onChanged: (value) {
                                setState(() {
                                  prize[index]['selected'] = value!;
                                });
                              },
                              style: TextStyle(color: Colors.indigo[900], fontFamily: 'Roboto'),
                              iconEnabledColor: Colors.indigo[900],
                            ),
                          ],
                        ),
                      ),
                    ),
                  );
                },
              ):Center(child: Text("No AddOn Product"),),
            ),
            Center(
              child: SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  style: ElevatedButton.styleFrom(
                    backgroundColor:  Colors.green,
                    padding: const EdgeInsets.symmetric(vertical: 14),
                  ),
                  onPressed: order,
                  child: const Text('Proceed', style: TextStyle(color: Colors.white)),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
