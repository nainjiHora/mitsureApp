import 'dart:convert';

import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter/widgets.dart';
import 'package:mittsure/newApp/MainMenuScreen.dart';
import 'package:mittsure/newApp/specimenList.dart';
import 'package:mittsure/screens/CartScreen.dart';
import 'package:mittsure/screens/login.dart';
import 'package:mittsure/services/utils.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../services/apiService.dart';

class SpecimenRequestScreen extends StatefulWidget {

  final seList;
  final tab;

  SpecimenRequestScreen({required this.seList,required this.tab});

  @override
  State<SpecimenRequestScreen> createState() => _SpecimenRequestScreenState();
}

class _SpecimenRequestScreenState extends State<SpecimenRequestScreen> {
  // Form fields
  String? orderType;
  String? bookType;
  String? productType;
  int seriesDisc = 0;
  String? shippingError;
  String? selectedSE;

  String? productGroup;
  List<dynamic> selectedOrders = [];
  List<dynamic> mittplusProducts = [];
  List<dynamic> filteredMittplusItems = [];
  int totalAmount = 0;
  // Choose from Set
  String? selectedSet;
  String? setQuantity;
  List<dynamic> setItems = [];
  List<dynamic> allSets = [];
  List<dynamic> productItems = [];
  // Individual Book
  String? selectedSeries;
  String? selectedClass;
  String? selectedMedium;
  String? selectedProduct;
  String? bookQuantity;
  TextEditingController remark = TextEditingController();

  // Transporter
  String? selectedTransporter;

  // Remarks
  final TextEditingController quantityController = TextEditingController();

  // Shipping details
  bool addShippingDetails = false;
  final TextEditingController shippingAddressController =
      TextEditingController();
  final TextEditingController phoneNumberController = TextEditingController();
  final TextEditingController discountController = TextEditingController();
  final TextEditingController emailController = TextEditingController();
  // Dummy dropdown data
  List<dynamic> transporters = [];
  List<dynamic> sets = [];
  List<dynamic> series = [];
  List<dynamic> classes = [];
  List<dynamic> filteredClass = [];
  List<dynamic> mediums = [];
  List<dynamic> products = [];
  List<dynamic> filteredProducts = [];
  List<dynamic> partyType = [];
  List<dynamic> mittplusTypes = [];
  List<dynamic> groups = [];

  void _logout() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.clear();
    Navigator.pushAndRemoveUntil(
      context,
      MaterialPageRoute(builder: (context) => LoginScreen()),
      (route) => false, // remove all previous routes
    );
  }

  String getNameTransporter(value) {
    final a = transporters
        .where((element) => element['transporterId'] == value)
        .toList();
    return a.length > 0 ? a[0]['transporter_name'] : "";
  }

  filterProductsBySeries(value) {
// setState(() {
//
//   filteredProducts=products.where((e)=>e['seriesCategory']==value&&(selectedClass==null||selectedClass==e['classId'])&&(selectedMedium==null||selectedMedium==e['mediumTableId'])).toList();
// });
  }
  filterProductsByClass(value) {
    setState(() {
      filteredProducts = products
          .where((e) =>
              e['classId'] == value &&
              (selectedSeries == null ||
                  selectedSeries == e['seriesCategory']) &&
              (selectedMedium == null || selectedMedium == e['mediumTableId']))
          .toList();
    });
  }

  filterProductsByMedium(value) {
    // setState(() {
    //
    //   filteredProducts=products.where((e)=>e['mediumTableId']==value&&(selectedClass==null||selectedClass==e['classId'])&&(selectedSeries==null||selectedSeries==e['seriesCategory'])).toList();
    // });
  }
  String getNameById(item) {
    var aList = "";

    if (item['productGroup'] == "6HPipXSLx5") {
      final a =
          mittplusProducts.where((element) => element['id'] == item['id']);

      aList = a.toList()[0]['product_name'];
    } else {
      if (item['type'] == "Choose from Set") {
        final a = sets.where((element) => element['seriesId'] == item['id']);

        aList = a.toList()[0]['nameSeries'];
      } else {
        final a = products.where((element) => element['skuId'] == item['id']);

        aList = a.toList()[0]['nameSku'];
      }
    }
    return aList.length > 20 ? aList.substring(0, 20) + "..." : aList;
  }

  addProductIems(value) {
    if (productGroup == "6HPipXSLx5") {
      productItems =
          mittplusProducts.where((element) => element['id'] == value).toList();
    } else {
      productItems =
          products.where((element) => element['skuId'] == value).toList();
    }
  }

  fetchMittplusProducts() async {
    final body = {};

    try {
      final response = await ApiService.post(
        endpoint: '/picklist/getProductTypeMittplus',
        body: body,
      );
      print(response);
      // Check if the response is valid
      if (response != null) {
        final data = response['data'];
        setState(() {
          mittplusTypes = data;
        });
      } else {
        throw Exception('Failed to load orders');
      }
    } catch (error) {
      print("Error fetchinjg orders: $error");
    }
  }

  filterMittplusItems(value) {
    setState(() {
      filteredMittplusItems =
          mittplusProducts.where((ele) => ele['productType'] == value).toList();
    });
  }

  fetchMittplusItems() async {
    final body = {"pageNumber": 0};

    try {
      final response = await ApiService.post(
        endpoint: '/product/getProductMittplus',
        body: body,
      );

      if (response != null) {
        final data = response['data'];
        setState(() {
          mittplusProducts = data;
        });
      } else {
        throw Exception('Failed to load orders');
      }
    } catch (error) {
      print("Error fetching orders: $error");
    }
  }

  addSetItems(value) async {
    selectedSet = value;
    final body = {"id": value};

    try {
      final response = await ApiService.post(
        endpoint: '/product/fetchProductById',
        body: body,
      );

      // Check if the response is valid
      if (response != null) {
        final data = response['data'];
        setState(() {
          setItems = data;
        });
      } else {
        throw Exception('Failed to load orders');
      }
    } catch (error) {
      print("Error fetching orders: $error");
    }
  }

  fetchSets() async {
    try {
      final response = await ApiService.post(
        endpoint: '/product/fetchSeries', // Use your API endpoint
        body: {},
      );

      // Check if the response is valid
      if (response != null) {
        final data = response['data'];

        setState(() {
          sets = data;
        });
      } else {
        throw Exception('Failed to load orders');
      }
    } catch (error) {
      print("Error fetching orders: $error");
    }
  }

  fetchProduct() async {
    try {
      final response = await ApiService.post(
        endpoint: '/product/getSpecimenProduct', // Use your API endpoint
        body: {},
      );

      // Check if the response is valid
      if (response != null) {
        print(response['data']);
        final data = response['data'];

        setState(() {
          products = data;
          // print(products.length);
          // filteredProducts=data;
        });
      } else {
        throw Exception('Failed to load orders');
      }
    } catch (error) {
      print("Error fetching orders: $error");
    }
  }

  fetchPicklist() async {
    final body = {};

    try {
      final response = await ApiService.post(
        endpoint: '/order/getDropdownListForOrder', // Use your API endpoint
        body: body,
      );

      // Check if the response is valid
      if (response != null) {
        setState(() {
          series = response['series_list'].where((ee) {
            print(ee);
            return ee['specimen'] != null &&
                ee['specimen'].toString().toLowerCase() == 'true';
          }).toList();
          classes = response['class_list'];
          mediums = response['medium_list'];
          groups = response['productGroup_list'];
          partyType = response['partyType_list'];
        });
      } else {
        throw Exception('Failed to load orders');
      }
    } catch (error) {
      print("Error fetcffdfdhing orders: $error");
    }
  }

  void showRemarkPopup(BuildContext context) {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: Text("Why do you need this ?"),
          actions: [
            Column(
              children: [
                Padding(
                  padding: const EdgeInsets.symmetric(vertical: 3.0),
                  child: TextFormField(
                    controller: remark,
                    decoration: InputDecoration(
                      labelText: "Remark",
                      border: OutlineInputBorder(
                        borderSide: BorderSide(width: 1.0, color: Colors.black),
                      ),
                      enabledBorder: OutlineInputBorder(
                        borderSide: BorderSide(width: 1.0, color: Colors.black),
                      ),
                      focusedBorder: OutlineInputBorder(
                        borderSide: BorderSide(width: 1.0, color: Colors.blue),
                      ),
                    ),
                    validator: (value) =>
                        value == null || value.isEmpty ? 'Required' : null,
                  ),
                ),
                Row(
                  children: [
                    TextButton(
                      onPressed: () {
                        if (remark.text != null) {
                          Navigator.pop(context);
                          _submitForm();
                        }
                      },
                      child: Text('Submit Request'),
                    ),
                    TextButton(
                      onPressed: () {
                        Navigator.of(context).pop(); // Close the dialog
                      },
                      child: Text('Cancel'),
                    ),
                  ],
                ),
              ],
            ),
          ],
        );
      },
    );
  }

  @override
  void initState() {
    // TODO: implement initState
    super.initState();

    fetchPicklist();
    fetchProduct();
    fetchSets();
    fetchMittplusProducts();
    fetchMittplusItems();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF5F5F5), // Light grey background
      appBar: AppBar(
        leading: IconButton(
          icon: Icon(Icons.arrow_back, color: Colors.white),
          onPressed: () {
            Navigator.pop(context);
          },
        ),
        title: Text(
          "Request Specimen",
          style: TextStyle(color: Colors.white, fontSize: 18),
        ),
        backgroundColor: Colors.indigo[900],
        centerTitle: true,
        actions: [
          IconButton(
            icon: const Icon(Icons.home, color: Colors.white),
            onPressed: () {
              Navigator.pushAndRemoveUntil(
                context,
                MaterialPageRoute(builder: (context) => MainMenuScreen()),
                (route) => false, // remove all previous routes
              );
            },
          ),
        ],
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // _buildSection(
            //   title: "Order Details",
            //   children: [
                // _buildDropdown(
                //     'Product Group', groups, "id", "name", productGroup,
                //     (value) {
                //   setState(() {
                //     productGroup = value;
                //     selectedProduct = null;
                //     bookType = 'Choose from Individual Book';
                //     productType = null;
                //   });
                // }),
                // const SizedBox(height: 12),
                // productGroup == "6HPipXSLx5"
                //     ? _buildDropdown('Product Type', mittplusTypes, "id",
                //         "name", productType, (value) {
                //         setState(() {
                //           productType = value;
                //           filterMittplusItems(value);
                //         });
                //       })
                //     : SizedBox(
                //         height: 0,
                //       )
                // _buildDropdown('Book Type',
                //     [{"id":"Choose from Set","name":'Choose from Set'}, {"id":'Choose from Individual Book',"name":'Choose from Individual Book'}],"id","name", bookType, (value) {
                //       setState(() {
                //         bookType=value;
                //         if(value=="Choose from Individual Book"){
                //           fetchProduct();
                //         }
                //
                //       });
                //     }),
            //   ],
            // ),
           if(widget.tab==2)
            DropdownButtonFormField<String>(
              value: selectedSE,
              decoration: InputDecoration(
                labelText: 'Select RM',
                border: OutlineInputBorder(),
                contentPadding: EdgeInsets.symmetric(
                    horizontal: 10, vertical: 8),
              ),
              style: TextStyle(fontSize: 14),
              dropdownColor: Colors.white,
              items: [

                ...widget.seList.map((rsm) {
                  return DropdownMenuItem<String>(
                    value: rsm['id'].toString(),
                    child: Text(rsm['name'],
                        style: TextStyle(
                            fontSize: 14, color: Colors.black)),
                  );
                }).toList(),
              ],
              onChanged: (value) {
                selectedSE = value ?? "";

              },
            ),
            if (bookType == 'Choose from Set')
              _buildSection(
                title: "Product Details",
                children: [
                  _buildDropdown(
                      'Choose Set', sets, "seriesId", "nameSeries", selectedSet,
                      (value) {
                    setState(() {
                      addSetItems(value);
                    });
                  }),
                  SizedBox(height: 12),
                  _buildNumberField('Quantity', setQuantity, (value) {
                    setState(() => setQuantity = value);
                  }),
                ],
              ),
            // if (bookType == 'Choose from Individual Book' &&
            //     productGroup != "6HPipXSLx5")
              _buildSection(
                title: "Product Details",
                children: [
                  _buildDropdown('Series', series, "seriesTableId",
                      "seriesName", selectedSeries, (value) {
                    List<dynamic> pro = products
                        .where((ele) => ele['seriesCategory'] == value)
                        .map((ele) => ele['classId'] as String)
                        .toList();
                    var disc = series
                        .where((element) => element['seriesTableId'] == value)
                        .toList();

                    setState(() {
                      selectedClass = null;
                      filteredClass = classes
                          .where((ele) => pro.contains(ele['classId']))
                          .toList();
                      filteredProducts = [];
                      selectedSeries = value;
                      seriesDisc =
                          disc!.length == 0 ? 0 : disc[0]['maxDiscount'];
                      filterProductsBySeries(value);
                    });
                  }),
                  SizedBox(height: 5),
                  _buildDropdown('Class', filteredClass, "classId", "className",
                      selectedClass, (value) {
                    setState(() {
                      selectedClass = value;
                      filterProductsByClass(value);
                    });
                  }),
                  SizedBox(height: 5),
                  _buildDropdown('Product', filteredProducts, "skuId",
                      "nameSku", selectedProduct, (value) {
                    setState(() => selectedProduct = value);
                    addProductIems(value);
                  }),
                  SizedBox(height: 5),
                  _buildNumberField('Quantity', bookQuantity, (value) {
                    setState(() => setQuantity = value);
                  }),
                ],
              ),
            if (productGroup == "6HPipXSLx5")
              _buildSection(
                title: "Product Details",
                children: [
                  _buildDropdown('Product', filteredMittplusItems, "id",
                      "product_name", selectedProduct, (value) {
                    setState(() => selectedProduct = value);
                    addProductIems(value);
                  }),
                  SizedBox(height: 5),
                  _buildNumberField('Quantity', bookQuantity, (value) {
                    setState(() => setQuantity = value);
                  }),
                ],
              ),
            // bookType == 'Choose from Set' ||
            //         bookType == 'Choose from Individual Book' ||
            //         productGroup == "6HPipXSLx5"
            //     ?
                Row(
                    mainAxisAlignment: MainAxisAlignment.end,
                    children: [
                      ElevatedButton.icon(
                        onPressed: () {
                          if ((selectedSet != null ||
                                  selectedProduct != null) &&
                              setQuantity != null &&
                              setQuantity != '0') {
                            setState(() {
                              allSets.add({
                                "id": bookType == "Choose from Set"
                                    ? selectedSet
                                    : selectedProduct,
                                "quantity": setQuantity,
                                "type": bookType,
                                "productGroup": productGroup
                              });

                              selectedOrders.add({
                                "product": productItems[0],
                                "data":[...productItems],
                                "quantity": setQuantity,
                                "group": productGroup,
                              });

                              selectedSet = null;
                              selectedProduct = null;
                              setQuantity = '0';
                              quantityController.text = '0';
                              productItems = [];
                            });
                          }
                        },
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.green,

                          shape: RoundedRectangleBorder(
                            borderRadius:
                                BorderRadius.circular(12), // Rounded corners
                          ),
                          padding: EdgeInsets.symmetric(
                              horizontal: 16, vertical: 12), // Padding
                          elevation: 4, // Shadow effect
                        ),
                        icon: Icon(
                          Icons.add,
                          size: 20,
                          color: Colors.white,
                        ), // Icon before the text
                        label: Text(
                          'Add Product',
                          style: TextStyle(
                            fontSize: 16,
                            color: Colors.white,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                    ],
                  )

                // Row(
                //   mainAxisAlignment: MainAxisAlignment.end,
                //   children: [
                //     GestureDetector(
                //       onTap: (){
                //         if((selectedSet!=null||selectedProduct!=null)&&setQuantity!=null&&setQuantity!='0') {
                //           setState(() {
                //             allSets.add(
                //                 {"id": bookType=="Choose from Set"?selectedSet:selectedProduct, "quantity": setQuantity,"type":bookType,"productGroup":productGroup});
                //
                //             selectedOrders.add({
                //               "data": bookType=="Choose from Set"?[...setItems]:[...productItems],
                //               "quantity": setQuantity,
                //               "group": productGroup,
                //               "orderType":productItems[0]['type']=='set'?'Choose from Set':'Choose from Individual Book'
                //             });
                //
                //
                //             selectedSet = null;
                //             selectedProduct=null;
                //             setQuantity = '0';
                //             quantityController.text='0';
                //             productItems=[];
                //           });
                //         }
                //       },
                //       child: Row(
                //         children: [
                //           Icon(Icons.add,color:Colors.blue),
                //
                //           Text(
                //             'Add Product',
                //             style: TextStyle(
                //               color: Colors.blue,
                //               fontSize: 15,
                //               decoration: TextDecoration.none,
                //             ),
                //           ),
                //         ],
                //       ),
                //     ),
                //
                //   ],
                // )
                ,
            const SizedBox(height: 20),
            _buildSection(title: "Added Products", children: [
              Container(
                height: 55 * (allSets.length).toDouble(),
                width: double.infinity,
                child: allSets.length > 0
                    ? ListView.builder(
                        itemCount: allSets.length,
                        itemBuilder: (context, index) {
                          final item = allSets[index];
                          return Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              Container(
                                margin: const EdgeInsets.symmetric(
                                    vertical: 5,
                                    horizontal:
                                        10), // Add some spacing around rows
                                padding: const EdgeInsets.all(
                                    8), // Add padding inside the row
                                decoration: BoxDecoration(
                                  color: Colors
                                      .blue[50], // Light blue background color
                                  border: Border.all(
                                      color: Colors.blue,
                                      width: 1), // Blue border
                                  borderRadius: BorderRadius.circular(
                                      8), // Rounded corners
                                ),
                                child: Row(
                                  mainAxisAlignment:
                                      MainAxisAlignment.spaceAround,
                                  children: [
                                    Text(
                                      getNameById(item),
                                      style: const TextStyle(
                                          fontSize: 14,
                                          fontWeight: FontWeight
                                              .bold), // Add styling to the text
                                    ),
                                    SizedBox(
                                        width:
                                            56), // Add spacing between elements
                                    Text(
                                      item['quantity'] ?? "",
                                      style: const TextStyle(
                                          fontSize: 16,
                                          fontWeight: FontWeight
                                              .bold), // Add styling to the text
                                    ),
                                  ],
                                ),
                              ),
                              GestureDetector(
                                onTap: () {
                                  setState(() {
                                    allSets.removeAt(index);
                                    selectedOrders.removeAt(index);
                                  });
                                },
                                child: Icon(
                                  Icons.delete,
                                  color: Colors.red,
                                ),
                              )
                            ],
                          );
                        },
                        physics: NeverScrollableScrollPhysics(),
                      )
                    : Text("No Products Added"),
              ),
            ]),
            Center(
              child: SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.indigo[900],
                    padding: const EdgeInsets.symmetric(vertical: 14),
                  ),
                  onPressed: () {
                    if(widget.tab==2){
                      distribute(context);
                    }else {
                      showRemarkPopup(context);
                    }
                  },
                  child:  Text(widget.tab==2?"Distribute to RM":'Create Request',
                      style: TextStyle(color: Colors.white)),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSection(
      {required String title, required List<Widget> children}) {
    return Card(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
      elevation: 3,
      margin: const EdgeInsets.only(bottom: 20),
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              title,
              style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 8),
            ...children,
          ],
        ),
      ),
    );
  }

  Widget _buildPrefilledField(String label, String value) {
    return TextFormField(
      initialValue: value,
      readOnly: true,
      decoration: InputDecoration(
        labelText: label,
        border: const OutlineInputBorder(),
      ),
    );
  }

  Widget _buildDropdown(String label, List<dynamic> items, keyId, keyName,
      String? value, ValueChanged<String?> onChanged) {
    return DropdownButtonFormField<String>(
      decoration: InputDecoration(
        labelText: label,
        border: const OutlineInputBorder(),
        contentPadding:
            const EdgeInsets.symmetric(horizontal: 12, vertical: 14),
      ),
      value: value,
      items: items
          .map((item) => DropdownMenuItem(
              value: item![keyId]!.toString(),
              child: Text(item[keyName] ?? "")))
          .toList(),
      onChanged: onChanged,
    );
  }

  complete() {
    if(widget.tab==2){
      Navigator.pushReplacement(
          context,
          MaterialPageRoute(
            builder: (context) => SpecimenScreen(tab: widget.tab,),
          ));
    }else {
      Navigator.pushReplacement(
          context,
          MaterialPageRoute(
            builder: (context) => SpecimenScreen(tab: widget.tab,),
          ));
    }
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

  void _submitForm() async {

    try{
    final prefs = await SharedPreferences.getInstance();
    final userString = prefs.getString('user');
    var userData;
    if (userString != null) {
      userData = jsonDecode(userString);
    }
    if (selectedOrders.length == 0) {
      DialogUtils.showCommonPopup(
          context: context,
          message: "Please Select Atleast 1 Product",
          isSuccess: false);

      return;
    }

    DateTime now = DateTime.now();
    int milliseconds = now.millisecondsSinceEpoch;
    final obj = {
      "status": "0",
      "date": milliseconds,
      "remarks": remark.text,
      "ownerId": userData['id'],
      "products": selectedOrders
    };
    print(obj);
    // try {
    final response = await ApiService.post(
      endpoint: '/specimen/addSpecimenToUser',
      body: obj,
    );

    print(response);

    if (response != null && response['status'] == false) {
      DialogUtils.showCommonPopup(
          context: context,
          message: "Request Raised",
          isSuccess: true,
          onOkPressed: () {
            complete();
          });
    } else {
      DialogUtils.showCommonPopup(
        context: context,
        message: response['message'],
        isSuccess: false,
      );
    }
    } catch (error) {
      print(error);
      DialogUtils.showCommonPopup(
        context: context,
        message: "Something Went Wrong",
        isSuccess: false,
      );
    }
  }


distribute(context) async{


    try{
      final prefs = await SharedPreferences.getInstance();
      final userString = prefs.getString('user');
      var userData;
      if (userString != null) {
        userData = jsonDecode(userString);
      }
      if (selectedOrders.length == 0) {
        DialogUtils.showCommonPopup(
            context: context,
            message: "Please Select Atleast 1 Product",
            isSuccess: false);

        return;
      }


      final obj = {


       "role":"se",
        "skuList":selectedOrders,
        "userId": selectedSE,

      };
      print(obj);
      // try {
      final response = await ApiService.post(
        endpoint: '/specimen/saveAllotSpecimen', // Use your API endpoint
        body: obj,
      );

      print(response);

      if (response != null && response['status'] == false) {
        DialogUtils.showCommonPopup(
            context: context,
            message: response['message'],
            isSuccess: true,
            onOkPressed: () {
              complete();
            });
      } else {
        DialogUtils.showCommonPopup(
          context: context,
          message: response['message'],
          isSuccess: false,
        );
      }
    } catch (error) {
      print(error);
      DialogUtils.showCommonPopup(
        context: context,
        message: "Something Went Wrong",
        isSuccess: false,
      );
    }
  }

}
