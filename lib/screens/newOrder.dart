import 'dart:convert';
import 'dart:ffi';

import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter/widgets.dart';
import 'package:intl/intl.dart';
import 'package:mittsure/screens/CartScreen.dart';
import 'package:mittsure/services/utils.dart';
import 'package:multi_select_flutter/chip_display/multi_select_chip_display.dart';
import 'package:multi_select_flutter/dialog/multi_select_dialog_field.dart';
import 'package:multi_select_flutter/util/multi_select_item.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../services/apiService.dart';
import 'login.dart';

class NewOrderScreen extends StatefulWidget {
  final party;
  final type;

  const NewOrderScreen({super.key, required this.party, required this.type});

  @override
  State<NewOrderScreen> createState() => _NewOrderScreenState();
}

class _NewOrderScreenState extends State<NewOrderScreen> {
  // Form fields
  String? orderType;
  String? bookType;
  String? productType;

  int seriesDisc = 0;
  List<dynamic> selectedPro=[];
  String? shippingError;
 bool isLoading=false;
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
  List<dynamic> filteredSeries = [];
  List<dynamic> specimenSeries = [];
  List<dynamic> classes = [];
  List<dynamic> specimenClasses = [];
  List<dynamic> specimenProducts = [];
  List<dynamic> filteredClass = [];
  List<dynamic> mediums = [];
  List<dynamic> products = [];
  List<dynamic> filteredProducts = [];
  List<dynamic> partyType = [];
  List<dynamic> mittplusTypes = [];
  List<dynamic> groups = [];
  List<dynamic> filteredGroups = [];

  void _logout() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.clear();
    Navigator.push(
      context,
      MaterialPageRoute(
          builder: (context) => LoginScreen()), // Route to HomePage
    );
  }

  removeMittPlus(){

    if(orderType.toString().toLowerCase()!='sales'){
      setState(() {
        filteredGroups.removeWhere((element) => element['id']=='6HPipXSLx5');
      });
    }else{

      setState(() {
        filteredGroups=[...groups];
      });
    }
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
      selectedProduct=null;
      List<dynamic> prod=orderType.toString().toLowerCase()!='sales'?specimenProducts:products;
      filteredProducts = prod
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
    productItems=[];
    if (productGroup == "6HPipXSLx5") {
      productItems =
          mittplusProducts.where((element) => element['id'] == value).toList();
productItems[0]['seriesCategory']=productItems[0]['id'];
      print(productItems);
    } else {
      productItems=
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

      // Check if the response is valid
      if (response != null) {
        final data = response['data'];
        print(data);
        print("mittplus producs");
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
      selectedProduct=null;
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

  fetchTransporter() async {
    final body = {};

    try {
      final response = await ApiService.post(
        endpoint: '/party/getTransporter',
        body: body,
      );

      // Check if the response is valid
      if (response != null) {
        final data = response['data'];
        setState(() {
          selectedTransporter = widget.party['transporterId'];
          transporters = data;
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
  filterSeries(){

    List<dynamic> b =[];
    if(orderType.toString().toLowerCase()=='sales'){
      b=series;
      setState(() {
        filteredSeries=series;
      });
    }else {
      b=series.where((ee) {
        print(ee);
        return ee['specimen'] != null &&
            ee['specimen'].toString().toLowerCase() == 'true';
      }).toList();

      setState(() {
        filteredSeries = b;
      });
    }
  }

  fetchProduct() async {
    try {
      setState(() {
        isLoading=true;
      });
      if(orderType.toString().toLowerCase()!='sales'){
        getProductSpecimenINventory();
      }

        final response = await ApiService.post(
          endpoint:orderType.toString().toLowerCase()!='sales'?'/product/getSpecimenProduct': '/product/getProduct', // Use your API endpoint
          body: {},
        );

        // Check if the response is valid
        if (response != null) {
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
    finally{
      setState(() {
        isLoading=false;
      });
    }
  }

  bool checkInventory(value){
    print(value);
    List<dynamic> a=specimenProducts.where((element) => element['skuId']==value).toList();
    print(a);
    if(a.length>0 && a[0]['quantity']>=int.parse(quantityController.text)){
      return true;
    }else{
      return false;
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

          if (widget.party['series'] != null) {
            List<dynamic> a = jsonDecode(widget.party["series"]);

            List<dynamic> b = response['series_list'].where((ee) {
              var seriesId = ee['seriesTableId'];

              return a.contains(
                  seriesId); // Ensure `a` is a List and contains correct types
            }).toList();

            series = b;
            filteredSeries=b;
          } else {
            series = response['series_list'];
          }

          classes = response['class_list'];
          mediums = response['medium_list'];
          groups = response['productGroup_list'];
          filteredGroups = response['productGroup_list'];
          partyType = response['partyType_list'];
          shippingAddressController.text = widget.party['AddressLine1'] ?? "";
          emailController.text = widget.party['email'] ?? "";
          phoneNumberController.text = widget.party['makerContact'] ?? "";
        });
      } else {
        throw Exception('Failed to load orders');
      }
    } catch (error) {
      print("Error fetcffdfdhing orders: $error");
    }
    finally{
      setState(() {
        isLoading=false;
      });
    }
  }

  getProductSpecimenINventory() async {
    setState(() {
      isLoading=true;
    });
    final prefs = await SharedPreferences.getInstance();
    final t = await prefs.getString('user');
    var id = t != null ? jsonDecode(t)['id'] : "";
    final body = {
      'user_id':id
    };

    try {
      final response = await ApiService.post(
        endpoint: '/specimen/getProductWithSeries',
        body: body,
      );

      // Check if the response is valid
      if (response != null) {
        setState(() {
          List<dynamic> b=[];
          List<dynamic> c=[];
          List<dynamic> d=[];
          for (int i = 0; i < response['data'].length; i++) {
            var seriesItem = {
              "seriesTableId": response['data'][i]['seriesCategory'],
              "seriesName": response['data'][i]['seriesName']
            };

            if (!b.any((item) => item['seriesTableId'] == seriesItem['seriesTableId'])) {
              b.add(seriesItem);
            }

            var classItem = {
              "classId": response['data'][i]['classId'],
              "className": response['data'][i]['className']
            };

            if (!c.any((item) => item['classId'] == classItem['classId'])) {
              c.add(classItem);
            }
          }

          specimenSeries=b;
          specimenClasses=c;
          specimenProducts=response['data'];
        });
      } else {
        throw Exception('Failed to load orders');
      }
    } catch (error) {
      print("Error fetcffdfdhing orders: $error");
    }
    finally{
      setState(() {
        isLoading=false;
      });
    }
  }

  @override
  void initState() {
    // TODO: implement initState
    super.initState();
    fetchPicklist();
    fetchMittplusProducts();
    fetchMittplusItems();
    // getProductSpecimenINventory();
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
          widget.party['schoolName'] ?? widget.party['DistributorName'],
          style: TextStyle(color: Colors.white, fontSize: 18),
        ),
        backgroundColor: Colors.indigo[900],
        centerTitle: true,
        actions: [
          IconButton(
            icon: const Icon(Icons.exit_to_app, color: Colors.white),
            onPressed: _logout,
          ),
        ],
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _buildSection(
              title: "Order Details",
              children: [
                _buildDropdown(
                    'Order Type',
                    [
                      {"id": 'Sales', "name": 'Sales'},
                      {"id": 'Specimen', "name": 'Specimen'}
                    ],
                    "id",
                    'name',
                    orderType, (value) {
                  setState(() {
                    orderType = value;
                    selectedProduct = null;
                    selectedClass = null;
                    selectedSeries = null;
                    allSets=[];
                    setQuantity = null;
                    selectedOrders = [];
                    filteredProducts=[];
                    filteredSeries=[];
                    productGroup = null;
                    allSets=[];
                    selectedOrders=[];
                    fetchProduct();
                    filterSeries();
                    removeMittPlus();
                  });


                }),

                const SizedBox(height: 12),
                _buildDropdown(
                    'Product Group', filteredGroups, "id", "name", productGroup,
                    (value) {
                  setState(() {
                    productGroup = value;
                    selectedPro=[];
                    selectedProduct = null;
                    bookType = 'Choose from Individual Book';
                    productType = null;
                  });
                }),
                const SizedBox(height: 12),
                productGroup == "6HPipXSLx5"
                    ? _buildDropdown('Product Type', mittplusTypes, "id",
                        "name", productType, (value) {
                        setState(() {
                          productType = value;
                          filterMittplusItems(value);
                        });
                      })
                    : SizedBox(
                        height: 0,
                      )

              ],
            ),

            if (bookType == 'Choose from Individual Book' &&
                productGroup != "6HPipXSLx5")
              _buildSection(
                title: "Product Details",
                children: [
                  _buildDropdown('Series', orderType.toString().toLowerCase()!='sales'?specimenSeries:filteredSeries, "seriesTableId",
                      "seriesName", selectedSeries, (value) {
                        List<dynamic> prodr=orderType.toString().toLowerCase()!='sales'?specimenProducts:products;

                    List<dynamic> pro = prodr
                        .where((ele) => ele['seriesCategory'] == value)
                        .map((ele) => ele['classId'] as String)
                        .toList();

                    var disc = series
                        .where((element) => element['seriesTableId'] == value)
                        .toList();

                    setState(() {
                      selectedClass = null;
                      List<dynamic> cls=orderType.toString().toLowerCase()!='sales'?specimenClasses:classes;
                      filteredClass = cls
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
                  // _buildDropdown('Product', filteredProducts, "skuId",
                  //     "nameSku", selectedProduct, (value) {
                  //   setState(() => selectedProduct = value);
                  //   addProductIems(value);
                  // }),

                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        "Select Products",
                        style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                      ),
                      SizedBox(height: 8),
                      Container(
                        decoration: BoxDecoration(
                          border: Border.all(color: Colors.grey), // Border color
                          borderRadius:
                          BorderRadius.circular(8), // Optional: rounded corners
                        ),
                        padding: EdgeInsets.symmetric(
                            horizontal: 12, vertical: 4), // Optional: inner spacing
                        child: MultiSelectDialogField(
                          items: filteredProducts
                              .map<MultiSelectItem<String>>(
                                (opt) => MultiSelectItem<String>(
                              opt['skuId'].toString(),
                              opt['nameSku'].toString(),
                            ),
                          )
                              .toList(),
                          title: Text("Select Products"),
                          selectedColor: Colors.blue,
                          decoration:
                          BoxDecoration(), // Needed to remove internal field's decoration
                          initialValue: (selectedPro??[])
                              .map<String>((e) => e.toString())
                              .toList(),
    onConfirm: (values) {
                            setState(() {

                              selectedPro=values;
                            });
                          },
                          chipDisplay: MultiSelectChipDisplay(),

                        ),
                      ),
                    ],
                  ),
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
                  // _buildDropdown('Product', filteredMittplusItems, "id",
                  //     "product_name", selectedProduct, (value) {
                  //   setState(() => selectedProduct = value);
                  //   addProductIems(value);
                  // }),
                  Container(
                    decoration: BoxDecoration(
                      border: Border.all(color: Colors.grey), // Border color
                      borderRadius:
                      BorderRadius.circular(8), // Optional: rounded corners
                    ),
                    padding: EdgeInsets.symmetric(
                        horizontal: 12, vertical: 4), // Optional: inner spacing
                    child: MultiSelectDialogField(
                      items: filteredMittplusItems
                          .map<MultiSelectItem<String>>(
                            (opt) => MultiSelectItem<String>(
                          opt['id'].toString(),
                          opt['product_name'].toString(),
                        ),
                      )
                          .toList(),
                      title: Text("Select Products"),
                      selectedColor: Colors.blue,
                      decoration:
                      BoxDecoration(), // Needed to remove internal field's decoration
                      initialValue: (selectedPro??[])
                          .map<String>((e) => e.toString())
                          .toList(),
                      onConfirm: (values) {
                        setState(() {

                          selectedPro=values;
                        });
                      },
                      chipDisplay: MultiSelectChipDisplay(),

                    ),
                  ),

                  SizedBox(height: 5),
                  _buildNumberField('Quantity', bookQuantity, (value) {
                    setState(() => setQuantity = value);
                  }),
                ],
              ),
            bookType == 'Choose from Set' ||
                    bookType == 'Choose from Individual Book' ||
                    productGroup == "6HPipXSLx5"
                ? Row(
                    mainAxisAlignment: MainAxisAlignment.end,
                    children: [
                      ElevatedButton.icon(
                        onPressed: () {


                          if (
                              setQuantity != null &&
                              setQuantity != '0' && selectedPro.length>0 ) {

                            setState(() {

                              bool stable=true;
                              if(orderType.toString().toLowerCase()!='sales')
                              {
                                for (int i = 0; i < selectedPro.length; i++) {
                                  stable = checkInventory(selectedPro[i]);

                                  if (!stable) {
                                    break;
                                  }
                                }
                              }
                              if(stable) {
                                for (int i = 0; i < selectedPro.length; i++) {
                                  addProductIems(selectedPro[i]);


                                  allSets.add({
                                    "id": bookType == "Choose from Set"
                                        ? selectedSet
                                        : selectedPro[i],
                                    "quantity": setQuantity,
                                    "type": bookType,
                                    "productGroup": productGroup
                                  });

                                  selectedOrders.add({
                                    "data": bookType == "Choose from Set"
                                        ? [...setItems]
                                        : [...productItems],
                                    "quantity": setQuantity,
                                    "group": productGroup,
                                    "discount": seriesDisc,
                                    "orderType": orderType
                                  });
                                }

                                selectedSet = null;
                                selectedProduct = null;
                                selectedPro = [];
                                setQuantity = '0';
                                quantityController.text = '0';
                                productItems = [];
                              }else{
                                DialogUtils.showCommonPopup(context: context, message: "You Do not have enough stock", isSuccess: false);
                              }
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
                : SizedBox(),
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
                  onPressed: _submitForm,
                  child: const Text('Create Order',
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

    final prefs = await SharedPreferences.getInstance();
    final userString = prefs.getString('user');
    var userData;
    if (userString != null) {
      userData = jsonDecode(userString);
    }

    if (orderType == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Please fill all required fields'),
          backgroundColor: Colors.red,
        ),
      );
      return;
    }
    if (selectedOrders.length == 0) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Please Select Atleast 1 Product'),
          backgroundColor: Colors.red,
        ),
      );
      return;
    }

    DateTime now = DateTime.now();
    int milliseconds = now.millisecondsSinceEpoch;
    final obj = {
      "address": shippingAddressController.text,
      "approvalStatus": "0",
      "date": milliseconds,
      "discount": "0",
      "email": emailController.text,
      "mobileNo": phoneNumberController.text,
      "orderType": orderType,
      "ownerId":
          userData['role'] == "se" ? userData['id'] : widget.party['ownerId'],
      "partyId": widget.party['schoolId'] ?? widget.party['distributorID'],
      "addressId": widget.party['addressId'],
      "partyType": widget.type == 'distributor' ? "P6E9TGXewd" : "cQpLw8vwZf",
      "totalAmount": 0,
      "transport": selectedTransporter,
      "transporter_name": getNameTransporter(selectedTransporter)
    };

    try {
      Navigator.push(
        context,
        MaterialPageRoute(
            builder: (context) => CartScreen(
                  payload: obj,
                  orders: selectedOrders,
                  series: series,
                )), // Route to HomePage
      );
    } catch (error) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Error: $error'),
          backgroundColor: Colors.red,
        ),
      );
    }
  }
}
