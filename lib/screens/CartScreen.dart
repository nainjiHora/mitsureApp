import 'dart:convert';

import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:mittsure/screens/orders.dart';
import 'package:mittsure/screens/selectionScreen.dart';
import 'package:mittsure/services/utils.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../services/apiService.dart';
import 'addOns.dart';
import 'fileUpload.dart';

class CartScreen extends StatefulWidget {
  final List<dynamic>
      orders; // List of objects like {quantity: 5, data: [items]}
  final dynamic payload;
  final series;
  final applyDiscount;
  final uploadedSeries;
  final specimenProducts;

  CartScreen(
      {required this.orders,
      this.payload,
      required this.series,
      required this.applyDiscount,
      required this.uploadedSeries,
      required this.specimenProducts});

  @override
  _CartScreenState createState() => _CartScreenState();
}

class _CartScreenState extends State<CartScreen> {
  // List of cart items
  List<CartItem> cartItems = [];
  String? tntAmount = "";
  final TextEditingController quantityController = TextEditingController();
  var seriedDiscount = {};
  var seriesData = [];
  bool uploadFileScreen = false;
  bool discAdjust = false;
  Map<String, dynamic> addDiscounts = {};
  final TextEditingController otpController = TextEditingController();

  double getTotalPrice() {
    return cartItems.fold(0.0, (sum, item) {
      return sum + (item.price * item.qty * (1 - item.discount / 100));
    });
  }

  bool checkInventory(value, flag) {
    print(value);
    List<dynamic> matched = widget.specimenProducts
        .where((element) => element['skuId'] == value)
        .toList();

    print(matched);

    if (matched.isNotEmpty) {
      int requestedQty = 1;
      int availableQty = matched[0]['quantity'];
      if (flag) {
        if (availableQty >= requestedQty) {
          matched[0]['quantity'] = availableQty - requestedQty;
          return true;
        }
      } else {
        matched[0]['quantity'] = availableQty + requestedQty;
        return true;
      }
    }

    return false;
  }

  Future<void> order() async {
print(seriedDiscount);
    if (widget.applyDiscount.toString().toLowerCase() == 'yes' && (seriedDiscount.keys.toList().length == 0||
        seriedDiscount.values.any((value) => value <= 0))) {
      DialogUtils.showCommonPopup(context: context, message: 'You have not filled the discount correctly', isSuccess: false);
      // ScaffoldMessenger.of(context).showSnackBar(
      //   const SnackBar(
      //     content: Text(),
      //     backgroundColor: Colors.red,
      //   ),
      // );
      return;
    }
    if (widget.payload['orderProcess'].toString().toLowerCase() == 'upload' &&
        attach.length == 0) {
      DialogUtils.showCommonPopup(context: context, message: 'You have not uploaded any document ', isSuccess: false);


      return;
    }
    if (widget.payload['orderProcess'].toString().toLowerCase() == 'upload' &&
        widget.payload['orderType'].toLowerCase() == 'sales' &&
        (tntAmount == null || tntAmount!.isEmpty || tntAmount == "")) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('You have not filled tentative amount '),
          backgroundColor: Colors.red,
        ),
      );

      return;
    }
    var body = widget.payload;
    body['totalAmount'] = widget.payload['orderType'].toLowerCase() == 'sales'
        ? getTotalPrice().toStringAsFixed(2)
        : 0;
    body['seriesDiscount'] = seriedDiscount;
    body['tentativeAmount'] = tntAmount;
    body['attachment'] = attach;
    body['additionalDiscount']=addDiscounts;
    body['orders'] = cartItems.map((item) {
      return {
        'itemId': item.itemId,
        'name': item.name,
        'price': item.price,
        'qty': item.qty,
        'productGroup': item.productGroup,
        'orderType': item.itemType ?? "",
        'total': widget.payload['orderType'].toLowerCase() == 'sales'
            ? item.price * item.qty * (1 - item.discount / 100)
            : 0
      };
    }).toList();

    try {
      if (widget.payload['orderType'].toLowerCase() == 'sales') {
        print(body);
        Navigator.push(
          context,
          MaterialPageRoute(
              builder: (context) => AddOnProductsScreen(
                    payload: body,
                    items: cartItems,
                    series: seriesData,
                  )), // Route to HomePage
        );
      } else {
        Navigator.push(
          context,
          MaterialPageRoute(
              builder: (context) => CreateOrderScreen(
                    payload: body,
                    seriesData: seriesData,
                  )), // Route to HomePage
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
    var disc = {};
    seriesData = widget.series;
    for (var order in widget.orders) {
      int quantity = int.parse(order['quantity'].toString()) ?? 1;
      String group = order['group'];
      List<dynamic> items = order['data'];

      for (var item in items) {
        disc[item['seriesCategory']] = order["discount"];
        if (group == '6HPipXSLx5') {
          print("lkjhjkjh");
          var discConf = {
            "seriesName": item['product_name'],
            "seriesTableId": item['id'],
            "discountType": item['discountType'],
            "flatDiscount": item['flatDiscount'],
            "maxDiscount": item['maxDiscount'],
            "minDiscount": item['minDiscount']
          };
          seriesData.add(discConf);
          print(discConf);
        }
        cartItems.add(CartItem(
            disApp: group != "6HPipXSLx5",
            name:
                group == "6HPipXSLx5" ? item['product_name'] : item['nameSku'],
            productGroup: group,
            price: (item['unitPrice'] != null
                    ? double.tryParse(item['unitPrice'].toString())
                    : double.tryParse(item['landing_cost'].toString())) ??
                0.0,
            qty: quantity,
            series: item['seriesCategory'] ?? item['id'],
            itemId: item['skuId'] ?? item['id'],
            total: item['unitPrice'] != null
                ? double.tryParse(item['unitPrice'].toString())! * quantity ??
                    0.0
                : 0.0,
            discount: 0,
            itemType: order['orderType']));
      }
    }

    setState(() {
      print("===============================");
      print(widget.uploadedSeries);
      print(disc);
      seriedDiscount = disc;
    });
  }

  @override
  void initState() {
    super.initState();
    setData();
  }

  List<dynamic> attach = [];
  saveFiles(bool flag, arr) {
    setState(() {
      attach = arr;
      uploadFileScreen = flag;
    });
  }

  Widget discountTrailing(int discountPercent) {
    if (discountPercent <= 0) return const SizedBox();

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: Colors.green.shade100,
        borderRadius: BorderRadius.circular(20),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(
            Icons.local_offer,
            color: Colors.green.shade700,
            size: 18,
          ),
          const SizedBox(width: 4),
          Text(
            "${discountPercent.toStringAsFixed(0)}% off",
            style: TextStyle(
              color: Colors.green.shade800,
              fontWeight: FontWeight.bold,
              fontSize: 14,
            ),
          ),
        ],
      ),
    );
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
        backgroundColor: Colors.indigo[900],
      ),
      body: uploadFileScreen
          ? SizedBox(
              height: MediaQuery.of(context).size.height,
              child: FileUploadScreen(
                saveFiles: saveFiles,
              ),
            )
          : Column(
              children: [
                widget.payload['orderProcess'] == 'new'
                    ? Expanded(
                        child: ListView.builder(
                          itemCount: cartItems.length,
                          itemBuilder: (context, index) {
                            final item = cartItems[index];
                            return Card(
                              margin: EdgeInsets.symmetric(
                                  horizontal: 10, vertical: 8),
                              elevation: 2,
                              child: ListTile(
                                title: Text(item.name,
                                    style:
                                        TextStyle(fontWeight: FontWeight.bold)),
                                subtitle: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                        "Total Price: ${item.price} x ${item.qty} = ₹ ${(item.price * item.qty).toStringAsFixed(2)}"),
                                    Text(
                                      "Discounted Price: ₹ ${(item.price * item.qty * (1 - (item.discount / 100))).toStringAsFixed(2)}",
                                    ),
                                    Text("Price: ₹ ${item.price}",
                                        style: TextStyle(
                                            fontWeight: FontWeight.bold)),
                                  ],
                                ),
                                trailing: discountTrailing(item.discount),
                                // Row(
                                //   mainAxisSize: MainAxisSize.min,
                                //   children: [
                                //     IconButton(
                                //       icon: Icon(Icons.remove),
                                //       onPressed: () {
                                //         setState(() {
                                //
                                //           if (item.qty > 1) {
                                //             item.qty--;
                                //             bool b = checkInventory(
                                //                 item.itemId, false);
                                //           }
                                //         });
                                //       },
                                //     ),
                                //     Text("${item.qty}"),
                                //     IconButton(
                                //       icon: Icon(Icons.add),
                                //       onPressed: () {
                                //
                                //         bool b=checkInventory(item.itemId,true);
                                //         if(b){
                                //           setState(() {
                                //             item.qty++;
                                //           });
                                //         }
                                //         else{
                                //           DialogUtils.showCommonPopup(context: context, message: "You Do not have more stock of this item", isSuccess: false);
                                //         }
                                //       },
                                //     ),
                                //     IconButton(
                                //       icon:
                                //           Icon(Icons.delete, color: Colors.red),
                                //       onPressed: () {
                                //         setState(() {
                                //           cartItems.removeAt(index);
                                //         });
                                //       },
                                //     ),
                                //   ],
                                // ),
                              ),
                            );
                          },
                        ),
                      )
                    : Column(
                        children: [
                          SizedBox(height: 20),
                          ElevatedButton(
                            style: ElevatedButton.styleFrom(
                              backgroundColor: Colors.green, // Green background
                              foregroundColor:
                                  Colors.white, // White text & icon
                              padding: const EdgeInsets.symmetric(
                                  horizontal: 16, vertical: 12),
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(8),
                              ),
                            ),
                            onPressed: () {
                              setState(() {
                                uploadFileScreen = true;
                              });
                            },
                            child: Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                const Icon(Icons.upload_file),
                                const SizedBox(width: 8),
                                Text(
                                  "Upload Attachments ${attach.isNotEmpty ? '(' + attach.length.toString() + ' Uploaded)' : ''}",
                                  style: const TextStyle(
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                              ],
                            ),
                          ),
                          const SizedBox(height: 12),
                          if (widget.payload['orderType']
                                  .toString()
                                  .toLowerCase() ==
                              'sales')
                            Padding(
                              padding: const EdgeInsets.all(20.0),
                              child: _buildNumberField(
                                  'Tentative Order Amount', tntAmount, (value) {
                                setState(() => tntAmount = value);
                              }),
                            ),
                        ],
                      ),
                Card(
                  elevation: 4,
                  margin:
                      const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                  shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12)),
                  child: Padding(
                    padding: const EdgeInsets.all(16),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        /// Discount Adjustment Switch
                        // if (widget.payload['orderType'].toLowerCase() ==
                        //         'sales' &&
                        //     widget.payload['applyDiscount'] == "yes")
                        //   SwitchListTile(
                        //     title: const Text(
                        //       "Apply School Discount",
                        //       style: TextStyle(fontWeight: FontWeight.bold),
                        //     ),
                        //     value: discAdjust,
                        //     onChanged: (value) =>
                        //         setState(() => discAdjust = value),
                        //   ),

                        const Divider(),

                        /// Total Price
                        if (widget.payload['orderProcess'] == "new")
                          Text(
                            "Total: ₹ ${widget.payload['orderType'].toLowerCase() == 'sales' ? getTotalPrice().toStringAsFixed(2) : 0}",
                            style: const TextStyle(
                                fontSize: 20, fontWeight: FontWeight.bold),
                          ),

                        const SizedBox(height: 12),

                        /// School + Additional Discount Row
                        if (widget.payload['orderType'].toLowerCase() ==
                                'sales' &&
                            widget.applyDiscount == "yes")
                          Row(
                            children: [
                              /// School Discount
                              Expanded(
                                child: ElevatedButton.icon(
                                  style: ElevatedButton.styleFrom(
                                    backgroundColor: Colors.green,
                                    padding: const EdgeInsets.symmetric(
                                        vertical: 12),
                                    shape: RoundedRectangleBorder(
                                      borderRadius: BorderRadius.circular(10),
                                    ),
                                  ),
                                  onPressed: () {
                                    showGroupedCartPopup(context, cartItems,
                                        seriesData, widget.uploadedSeries);
                                  },
                                  icon: const Icon(Icons.school,
                                      color: Colors.white),
                                  label: const Text("Discount",style: TextStyle(color: Colors.white),),
                                ),
                              ),

                              const SizedBox(width: 10),

                              /// Additional Discount
                              // if (discAdjust)
                              //   Expanded(
                              //     child: ElevatedButton.icon(
                              //       style: ElevatedButton.styleFrom(
                              //         backgroundColor: Colors.orange,
                              //         padding: const EdgeInsets.symmetric(
                              //             vertical: 12),
                              //         shape: RoundedRectangleBorder(
                              //           borderRadius: BorderRadius.circular(10),
                              //         ),
                              //       ),
                              //       onPressed: () {
                              //         showGroupedCartPopupfordistributor(
                              //             context,
                              //             seriedDiscount,
                              //             widget.series);
                              //       },
                              //       icon: const Icon(Icons.discount,
                              //           color: Colors.white),
                              //       label: const Text("School Discount",style: TextStyle(color: Colors.white)),
                              //     ),
                              //   ),
                            ],
                          ),

                        const SizedBox(height: 16),

                        /// Proceed Button Full Width
                        SizedBox(
                          width: double.infinity,
                          child: ElevatedButton.icon(
                            style: ElevatedButton.styleFrom(
                              backgroundColor: Colors.indigo,
                              padding: const EdgeInsets.symmetric(vertical: 14),
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(12),
                              ),
                            ),
                            onPressed: order,
                            icon: const Icon(Icons.arrow_forward,
                                color: Colors.white),
                            label: const Text(
                              "Proceed",
                              style: TextStyle(
                                  fontSize: 16, fontWeight: FontWeight.bold,color: Colors.white),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                )
              ],
            ),
    );
  }

  void showGroupedCartPopup(BuildContext context, List<CartItem> cartItems,
      List<dynamic> seriesData, uploadedSeries) {
    final Map<String, List<CartItem>> groupedItems = {};

    if (widget.payload['orderProcess'] == 'new') {

      for (var item in cartItems) {
        print(item.disApp);
        // if (item.disApp) {
          if (!groupedItems.containsKey(item.series)) {
            groupedItems[item.series] = [];
          }
          groupedItems[item.series]!.add(item);
        // }else{
        //
        // }
      }
    } else {
      for (var item in uploadedSeries) {
        // if (item.disApp) {

        if (!groupedItems.containsKey(item)) {
          groupedItems[item] = [];
        }
        // groupedItems[item.series]!.add(item);
        // }
      }
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
                        'Apply  Discount',
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
                        print(entry);
                        return Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              'Item: ${seriesInfo?['seriesName'] ?? series}',
                              style: const TextStyle(
                                fontWeight: FontWeight.bold,
                                fontSize: 16,
                              ),
                            ),
                            Text(
                              'Total: ₹${total.toStringAsFixed(2)}',
                              style: const TextStyle(
                                  fontSize: 14, color: Colors.grey),
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
                                    final discountType =
                                        seriesInfo['discountType'];
                                    final minDiscount =
                                        seriesInfo['minDiscount'] ?? 0;
                                    final maxDiscount =
                                        seriesInfo['maxDiscount'] ?? 100;

                                    String? errorMessage;
                                    if (discountType == 'flat') {
                                      if (newDiscount != minDiscount) {
                                        errorMessage =
                                            'Discount must be exactly $minDiscount%';
                                      }
                                    } else if (discountType == 'range') {
                                      print(discountType);
                                      if (newDiscount < minDiscount ||
                                          newDiscount > maxDiscount) {
                                        errorMessage =
                                            'Discount must be between $minDiscount% and $maxDiscount%';
                                      }
                                    }
                                    setState(() {
                                      if (errorMessage == null) {
                                        seriedDiscount[series] = newDiscount;
                                        for (var item in items) {
                                          item.discount = newDiscount;
                                        }

                                        seriesTotals[series] =
                                            items.fold(0, (sum, item) {
                                          return sum +
                                              (item.price *
                                                  item.qty *
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

                                        seriesTotals[series] =
                                            items.fold(0, (sum, item) {
                                          return sum +
                                              (item.price *
                                                  item.qty *
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
                            style: TextStyle(
                                fontSize: 14,
                                color: Colors.white,
                                fontWeight: FontWeight.bold),
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

  void showGroupedCartPopupfordistributor(
      BuildContext context, cartItems, List<dynamic> seriesData) {
    // final Map<String, dynamic> groupedItems = {};
    //
    //
    //   for (var item in cartItems) {
    //
    //       if (!groupedItems.containsKey(item.series)) {
    //         groupedItems[item.series] = [];
    //       }
    //       groupedItems[item.series]!.add(item);
    //     }

    //
    //
    //
    //
    // groupedItems.forEach((series, items) {
    //   seriesTotals[series] = items.fold(0, (sum, item) {
    //     return sum + (item.price * item.qty * (1 - item.discount / 100));
    //   });
    // });

    final Map<String, TextEditingController> controllers = {};
    final Map<String, String?> errorMessages = {};
    final Map<String, String?> adD = {};

    cartItems.forEach((series, items) {
      controllers[series] = TextEditingController(
          text: addDiscounts[series] != null ? addDiscounts[series] : '');
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
                        'Apply Additional Discount',
                        style: TextStyle(
                          fontSize: 20,
                          fontWeight: FontWeight.bold,
                          fontFamily: 'Poppins',
                        ),
                      ),
                      const SizedBox(height: 10),
                      ...cartItems.entries.map((entry) {
                        final series = entry.key;
                        final items = entry.value;
                        // final total = seriesTotals[series]!;
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
                              'Till Now : ${items} %',
                              style: const TextStyle(
                                  fontSize: 14, color: Colors.grey),
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
                                    final discountType =
                                        seriesInfo['discountType'];
                                    final minDiscount =
                                        seriesInfo['minDiscount'] ?? 0;
                                    final maxDiscount =
                                        seriesInfo['maxDiscount'] ?? 100;

                                    String? errorMessage;
                                    if (discountType == 'flat') {
                                      if (newDiscount != minDiscount) {
                                        errorMessage =
                                            'Discount must be exactly $minDiscount%';
                                      }
                                    } else if (discountType == 'range') {
                                      if (newDiscount > maxDiscount - items) {
                                        errorMessage =
                                            'Discount must be between $minDiscount% and ${maxDiscount - items}%';
                                      }
                                    }
                                    // setState(() {
                                    //   if (errorMessage == null) {
                                    //     seriedDiscount[series] = newDiscount;
                                    //     for (var item in items) {
                                    //       item.discount = newDiscount;
                                    //     }
                                    //
                                    //     seriesTotals[series] =
                                    //         items.fold(0, (sum, item) {
                                    //           return sum +
                                    //               (item.price *
                                    //                   item.qty *
                                    //                   (1 - item.discount / 100));
                                    //         });
                                    //   }
                                    // });
                                    popupSetState(() {
                                      errorMessages[series] = errorMessage;
                                      if (errorMessage == null) {
                                        addDiscounts[series] = value;
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
                            style: TextStyle(
                                fontSize: 14,
                                color: Colors.white,
                                fontWeight: FontWeight.bold),
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

  Widget _buildNumberField(
      String label, String? value, Function(String) onChanged) {
    return TextFormField(
      keyboardType: TextInputType.number,
      controller: quantityController,
      decoration: InputDecoration(
        labelText: label,
        border: const OutlineInputBorder(),
      ),
      onChanged: onChanged,
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
  bool disApp;

  CartItem(
      {required this.itemType,
      required this.series,
      required this.name,
      required this.disApp,
      required this.discount,
      required this.productGroup,
      required this.total,
      required this.price,
      this.qty = 1,
      required this.itemId});
}
