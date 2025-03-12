import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:mittsure/screens/orders.dart';
import 'package:mittsure/screens/selectionScreen.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../services/apiService.dart';
import 'addOns.dart';

class CartScreen extends StatefulWidget {
  final List<dynamic> orders; // List of objects like {quantity: 5, data: [items]}
  final dynamic payload;
  final series;

  CartScreen({required this.orders, this.payload,required this.series});

  @override
  _CartScreenState createState() => _CartScreenState();
}

class _CartScreenState extends State<CartScreen> {
  // List of cart items
  List<CartItem> cartItems = [];
  var seriedDiscount={};
  final TextEditingController otpController = TextEditingController(); // OTP input controller

  // Function to calculate total price
  double getTotalPrice() {
    return cartItems.fold(0.0, (sum, item) {return sum + (item.price * item.qty*(1-item.discount/100));});
  }




  Future<void> order() async {
    
    if (seriedDiscount.keys.toList().length==0) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('You Have Not filled the discount'),
          backgroundColor: Colors.red,
        ),
      );
      return;
    }
    var  body  = widget.payload;
    body['totalAmount']=widget.payload['orderType'].toLowerCase()=='sales'?getTotalPrice().toStringAsFixed(2):0;
    body['seriesDiscount']=seriedDiscount;
    body['orders'] = cartItems.map((item) {
      return {
        'itemId': item.itemId,
        'name': item.name,
        'price': item.price,
        'qty': item.qty,
        'productGroup':item.productGroup,
        'orderType':item.itemType??"",
        'total':widget.payload['orderType'].toLowerCase()=='sales'?item.price * item.qty*(1-item.discount/100):0
      };
    }).toList();

    try {
if(widget.payload['orderType'].toLowerCase()=='sales') {
  print(body);
  Navigator.push(
    context,
    MaterialPageRoute(builder: (context) =>
        AddOnProductsScreen(payload: body,
          items: cartItems,
          series: widget.series,)), // Route to HomePage
  );
}else{
  Navigator.push(
    context,
    MaterialPageRoute(builder: (context) =>CreateOrderScreen(payload: body)), // Route to HomePage
  );
}

    } catch (error) {
      print("Error creating order: $error");
      _showErrorMessage("Failed to place the order. Please try again.");
    }
  }



  // Show error message in a SnackBar
  void _showErrorMessage(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(message), backgroundColor: Colors.red),
    );
  }

  // Show success message in a SnackBar
  void _showSuccessMessage(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(message), backgroundColor: Colors.green),
    );
  }


  void setData() {
    cartItems.clear();
    var disc={};
    for (var order in widget.orders) {

      int quantity = int.parse(order['quantity'].toString()) ?? 1;
      String group=order['group'];
      List<dynamic> items = order['data'];

      for (var item in items) {
        disc[item['seriesCategory']]=order["discount"];
        cartItems.add(CartItem(

          name: group=="6HPipXSLx5"?item['product_name']:item['nameSku'] ,
          productGroup: group,
          price:( item['unitPrice'] != null ? double.tryParse(item['unitPrice'].toString()):double.tryParse(item['landing_cost'].toString())) ?? 0.0,
          qty: quantity,
          series:item['seriesCategory']??"",
          itemId: item['skuId'] ?? item['id'],
          total:item['unitPrice'] != null ? double.tryParse(item['unitPrice'].toString())!*quantity ?? 0.0 : 0.0,
          discount:order['discount'],
          itemType:order['orderType']
        ));
      }
    }
    print(cartItems);
    setState(() {
      seriedDiscount=disc;
    });
  }

  @override
  void initState() {
    super.initState();
    setData();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(

      appBar: AppBar(
        leading: IconButton(
          icon: Icon(Icons.arrow_back, color: Colors.white),
          onPressed: () {
            Navigator.pop(context);
          },
        ),
        title: Text("My Cart", style: TextStyle(color: Colors.white)),
        backgroundColor: Colors.indigo,
      ),
      body: Column(
        children: [

          Expanded(
            child: ListView.builder(
              itemCount: cartItems.length,
              itemBuilder: (context, index) {
                final item = cartItems[index];
                return Card(
                  margin: EdgeInsets.symmetric(horizontal: 10, vertical: 8),
                  elevation: 2,
                  child: ListTile(
                    title: Text(item.name, style: TextStyle(fontWeight: FontWeight.bold)),
                    subtitle: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text("Total Price: ${item.price} x ${item.qty} = ₹ ${(item.price * item.qty).toStringAsFixed(2)}"),
                        Text("Price: ₹ ${item.price}", style: TextStyle(fontWeight: FontWeight.bold)),
                      ],
                    ),
                    trailing: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        IconButton(
                          icon: Icon(Icons.remove),
                          onPressed: () {
                            setState(() {
                              if (item.qty > 1) item.qty--;
                            });
                          },
                        ),
                        Text("${item.qty}"),
                        IconButton(
                          icon: Icon(Icons.add),
                          onPressed: () {
                            setState(() {
                              item.qty++;
                            });
                          },
                        ),
                        IconButton(
                          icon: Icon(Icons.delete, color: Colors.red),
                          onPressed: () {
                            setState(() {
                              cartItems.removeAt(index);
                            });
                          },
                        ),
                      ],
                    ),
                  ),
                );
              },
            ),
          ),
          Container(
            padding: EdgeInsets.symmetric(vertical: 10, horizontal: 16),
            color: Colors.white,
            child: Column(
              children: [
                Divider(),
                Text("Total: ₹ ${widget.payload['orderType'].toLowerCase()=='sales'?getTotalPrice().toStringAsFixed(2):0}", style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
                SizedBox(height: 10),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    // Apply Discount Button
                    ElevatedButton.icon(
                      style: ElevatedButton.styleFrom(
                       // Button size
                        backgroundColor: Colors.green, // Button color
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(8),
                        ),
                      ),
                      onPressed: () {
                        showGroupedCartPopup(context,cartItems,widget.series);
                      },
                      icon: const Icon(Icons.discount, color: Colors.white), // Icon for the button
                      label: const Text(
                        "Discounts",
                        style: TextStyle(fontSize: 14, color: Colors.white),
                      ),
                    ),

                    // Proceed Button
                    ElevatedButton.icon(
                      style: ElevatedButton.styleFrom(

                        backgroundColor: Colors.blue, // Button color
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(8),
                        ),
                      ),
                      onPressed: () {

                        order();
                      },
                      icon: const Icon(Icons.arrow_forward, color: Colors.white), // Icon for the button
                      label: const Text(
                        "Proceed",
                        style: TextStyle(fontSize: 14, color: Colors.white),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          )
        ],
      ),
    );
  }
  void showGroupedCartPopup(BuildContext context, List<CartItem> cartItems, List<dynamic> seriesData) {
    final Map<String, List<CartItem>> groupedItems = {};
    for (var item in cartItems) {
      if (!groupedItems.containsKey(item.series)) {
        groupedItems[item.series] = [];
      }
      groupedItems[item.series]!.add(item);
    }

    final Map<String, double> seriesTotals = {};
    groupedItems.forEach((series, items) {
      seriesTotals[series] = items.fold(0, (sum, item) {
        return sum + (item.price * item.qty * (1 - item.discount / 100));
      });
    });

    final Map<String, TextEditingController> controllers = {};
    final Map<String, String?> errorMessages = {};

    groupedItems.forEach((series, items) {
      controllers[series] = TextEditingController(
        text: items.isNotEmpty ? items[0].discount.toString() : '0',
      );
      errorMessages[series] = null;
    });

    showDialog(
      context: context,
      builder: (BuildContext context) {
        return StatefulBuilder(
          builder: (BuildContext context, StateSetter popupSetState) {
            return Dialog(
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(20),
              ),
              child: Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(20),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.grey.withOpacity(0.2),
                      blurRadius: 10,
                      spreadRadius: 5,
                    ),
                  ],
                ),
                child: SingleChildScrollView(
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text(
                        'Apply Discount',
                        style: TextStyle(
                          fontSize: 20,
                          fontWeight: FontWeight.bold,
                          fontFamily: 'Poppins',
                        ),
                      ),
                      const SizedBox(height: 10),
                      ...groupedItems.entries.map((entry) {

                        final series = entry.key;
                        final items = entry.value;
                        final total = seriesTotals[series]!;
                        final seriesInfo = seriesData.firstWhere(
                              (element) => element['seriesTableId'] == series,
                          orElse: () => null,
                        );

                        return Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              'Series: ${seriesInfo?['seriesName'] ?? series}',
                              style: const TextStyle(
                                fontWeight: FontWeight.bold,
                                fontSize: 16,
                              ),
                            ),
                            Text(
                              'Total: ₹${total.toStringAsFixed(2)}',
                              style: const TextStyle(fontSize: 14, color: Colors.grey),
                            ),
                            const SizedBox(height: 8),
                            TextField(
                              controller: controllers[series],
                              keyboardType: TextInputType.number,
                              decoration: InputDecoration(
                                labelText: 'Update Discount (%)',
                                labelStyle: const TextStyle(
                                  fontSize: 14,
                                  fontFamily: 'Poppins',
                                ),
                                errorText: errorMessages[series],
                                border: OutlineInputBorder(
                                  borderRadius: BorderRadius.circular(10),
                                ),
                              ),
                              onChanged: (value) {

                                if (value.isNotEmpty) {
                                  final newDiscount = int.tryParse(value) ?? 0;
                  
                                  if (seriesInfo != null) {
                                    final discountType = seriesInfo['discountType'];
                                    final minDiscount = seriesInfo['minDiscount'] ?? 0;
                                    final maxDiscount = seriesInfo['maxDiscount'] ?? 100;
                  
                                    String? errorMessage;
                                    if (discountType == 'flat') {
                                      if (newDiscount != minDiscount) {
                                        errorMessage = 'Discount must be exactly $minDiscount%';
                                      }
                                    } else if (discountType == 'range') {
                                      print(discountType);
                                      if (newDiscount < minDiscount || newDiscount > maxDiscount) {
                                        errorMessage =
                                        'Discount must be between $minDiscount% and $maxDiscount%';
                                      }
                                    }
                                    setState(() {
                  
                                      if (errorMessage == null) {
                                        seriedDiscount[series]=newDiscount;
                                        for (var item in items) {
                                          item.discount = newDiscount;
                                        }
                  
                                        seriesTotals[series] = items.fold(0, (sum, item) {
                                          return sum +
                                              (item.price * item.qty *
                                                  (1 - item.discount / 100));
                                        });
                                      }
                                    });
                                    popupSetState(() {
                                      errorMessages[series] = errorMessage;
                                      if (errorMessage == null) {
                                        for (var item in items) {
                                          item.discount = newDiscount;
                                        }
                  
                                        seriesTotals[series] = items.fold(0, (sum, item) {
                                          return sum +
                                              (item.price * item.qty *
                                                  (1 - item.discount / 100));
                                        });
                                      }
                                    });
                                  }
                                }
                              },
                            ),
                            const SizedBox(height: 10),
                            Divider(
                              thickness: 1,
                              color: Colors.grey[300],
                            ),
                          ],
                        );
                      }).toList(),
                      const SizedBox(height: 16),
                      Align(
                        alignment: Alignment.centerRight,
                        child: ElevatedButton(
                          onPressed: () {
                            Navigator.pop(context);
                          },
                          style: ElevatedButton.styleFrom(
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(10),
                            ),
                            backgroundColor: Colors.blueAccent,
                            padding: const EdgeInsets.symmetric(
                              horizontal: 20,
                              vertical: 12,
                            ),
                          ),
                          child: const Text(
                            'Close',
                            style: TextStyle(fontSize: 14,color: Colors.white, fontWeight: FontWeight.bold),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            );
          },
        );
      },
    );
  }




}

class CartItem {
  String name;
  String productGroup;
  double total;
  String series;
  double price;
  int qty;
  String itemId;
  int discount;
  String itemType;

  CartItem({required this.itemType, required this.series,required this.name,required this.discount,required this.productGroup,required this.total, required this.price, this.qty = 1, required this.itemId});
}
