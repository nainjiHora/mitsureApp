import 'dart:convert';
import 'dart:ffi';

import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter/widgets.dart';
import 'package:intl/intl.dart';
import 'package:mittsure/screens/CartScreen.dart';
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
  String ?shippingError;

String? productGroup;
List <dynamic> selectedOrders=[];
List <dynamic> mittplusProducts=[];
  List <dynamic> filteredMittplusItems=[];
 int totalAmount=0;
  // Choose from Set
  String? selectedSet;
  String? setQuantity;
  List<dynamic> setItems=[];
  List<dynamic> allSets=[];
 List<dynamic> productItems=[];
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
  final TextEditingController shippingAddressController = TextEditingController();
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
   List<dynamic> partyType=[];
   List<dynamic> mittplusTypes=[];
   List <dynamic> groups=[];

  void _logout() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.clear();
    Navigator.push(
      context,
      MaterialPageRoute(builder: (context) => LoginScreen()), // Route to HomePage
    );
  }

String getNameTransporter(value){

    final a=transporters.where((element) => element['transporterId']==value).toList();
    return a.length>0?a[0]['transporter_name']:"";
}

  filterProductsBySeries(value){
// setState(() {
//
//   filteredProducts=products.where((e)=>e['seriesCategory']==value&&(selectedClass==null||selectedClass==e['classId'])&&(selectedMedium==null||selectedMedium==e['mediumTableId'])).toList();
// });
  }
  filterProductsByClass(value){
    setState(() {
      filteredProducts=products.where((e)=>e['classId']==value&&(selectedSeries==null||selectedSeries==e['seriesCategory'])&&(selectedMedium==null||selectedMedium==e['mediumTableId'])).toList();
    });
  }
  filterProductsByMedium(value){
    // setState(() {
    //
    //   filteredProducts=products.where((e)=>e['mediumTableId']==value&&(selectedClass==null||selectedClass==e['classId'])&&(selectedSeries==null||selectedSeries==e['seriesCategory'])).toList();
    // });
  }
   String getNameById(item){
      var aList="";

if(item['productGroup']=="6HPipXSLx5"){

  final a = mittplusProducts.where((element) => element['id'] == item['id']);

  aList = a.toList()[0]['product_name'];
}else {
  if (item['type'] == "Choose from Set") {
    final a = sets.where((element) => element['seriesId'] == item['id']);

    aList = a.toList()[0]['nameSeries'];
  } else {
    final a = products.where((element) => element['skuId'] == item['id']);

    aList = a.toList()[0]['nameSku'];
  }
}
    return aList.length>20?aList.substring(0,20)+"...":aList;
  }


  addProductIems(value) {

    if (productGroup == "6HPipXSLx5") {
      productItems=
          mittplusProducts.where((element) => element['id'] == value).toList();

    } else {
      productItems=products.where((element) => element['skuId'] == value).toList();
    }
  }
fetchMittplusProducts() async{
  final body = {};

  try {

    final response = await ApiService.post(
      endpoint: '/picklist/getProductTypeMittplus',
      body: body,
    );

    // Check if the response is valid
    if (response != null) {

      final  data = response['data'];
      setState(() {
        mittplusTypes=data;
      });



    } else {
      throw Exception('Failed to load orders');
    }
  } catch (error) {
    print("Error fetchinjg orders: $error");
  }

}

filterMittplusItems(value){
    setState(() {

      filteredMittplusItems=mittplusProducts.where((ele)=>ele['productType']==value).toList();
    });
}

fetchMittplusItems() async {
  final body = {
    "pageNumber":0
  };

  try {

    final response = await ApiService.post(
      endpoint: '/product/getProductMittplus',
      body: body,
    );

    if (response != null) {

      final  data = response['data'];
      setState(() {

        mittplusProducts=data;

      });



    } else {
      throw Exception('Failed to load orders');
    }
  } catch (error) {
    print("Error fetching orders: $error");
  }

}

  addSetItems(value) async {
    selectedSet=value;
    final body = {"id":value};

    try {

      final response = await ApiService.post(
        endpoint: '/product/fetchProductById',
        body: body,
      );

      // Check if the response is valid
      if (response != null) {

        final  data = response['data'];
        setState(() {
          setItems=data;
        });



      } else {
        throw Exception('Failed to load orders');
      }
    } catch (error) {
      print("Error fetching orders: $error");
    }
  }


  fetchTransporter()async{
    final body = {};

    try {

      final response = await ApiService.post(
        endpoint: '/party/getTransporter',
        body: body,
      );

      // Check if the response is valid
      if (response != null) {

        final  data = response['data'];
        setState(() {
          selectedTransporter=widget.party['transporterId'];
              transporters=data;
        });



      } else {
        throw Exception('Failed to load orders');
      }
    } catch (error) {
      print("Error fetching orders: $error");
    }
  }

  fetchSets()async{


    try {

      final response = await ApiService.post(
        endpoint: '/product/fetchSeries',  // Use your API endpoint
        body: {},
      );

      // Check if the response is valid
      if (response != null) {

        final  data = response['data'];

        setState(() {
          sets=data;
        });


      } else {
        throw Exception('Failed to load orders');
      }
    } catch (error) {
      print("Error fetching orders: $error");
    }
  }
  fetchProduct()async{


    try {

      final response = await ApiService.post(
        endpoint: '/product/getProduct',  // Use your API endpoint
        body: {},
      );

      // Check if the response is valid
      if (response != null) {
print(response['data']);
        final  data = response['data'];

        setState(() {
          products=data;
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

  fetchPicklist()async{

    final body = {

    };

    try {

      final response = await ApiService.post(
        endpoint: '/order/getDropdownListForOrder',  // Use your API endpoint
        body: body,
      );

      // Check if the response is valid
      if (response != null) {

        setState(() {
          series=response['series_list'];

          classes=response['class_list'];
          mediums=response['medium_list'];
          groups=response['productGroup_list'];
          partyType=response['partyType_list'];
          shippingAddressController.text=widget.party['AddressLine1'];
          emailController.text=widget.party['email'];
          phoneNumberController.text=widget.party['makerContact'];
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
    // TODO: implement initState
    super.initState();
    fetchPicklist();
    fetchProduct();
    fetchTransporter();
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
        title:  Text(
          widget.party['schoolName']??widget.party['DistributorName'],
          style: TextStyle(color: Colors.white, fontSize: 18),
        ),
        backgroundColor:  Colors.indigo,
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

                _buildDropdown('Order Type', [{"id":'Sales',"name":'Sales'}],"id",'name', orderType, (value) {
                  setState(() => orderType = value);
                }),
                // _buildDropdown('Order Type', [{"id":'Sales',"name":'Sales'}, {"id":'Specimen',"name":'Specimen'}],"id",'name', orderType, (value) {
                //   setState(() => orderType = value);
                // }),
                const SizedBox(height: 12),
                _buildDropdown('Product Group',groups,"id","name", productGroup, (value) {
                  setState(() {
                    productGroup= value;
                    selectedProduct=null;
                    bookType='Choose from Individual Book';
                    productType=null;
                  });

                }),
                const SizedBox(height: 12),
                productGroup=="6HPipXSLx5"?
                _buildDropdown('Product Type', mittplusTypes,"id","name", productType, (value) {
                      setState(() {
                        productType=value;
                          filterMittplusItems(value);

                      });
                    })
                    :SizedBox(height: 0,)
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
              ],
            ),

            if (bookType == 'Choose from Set')
              _buildSection(
                title: "Product Details",
                children: [
                  _buildDropdown('Choose Set', sets,"seriesId","nameSeries", selectedSet, (value) {
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

            if (bookType == 'Choose from Individual Book'&&productGroup!="6HPipXSLx5")
              _buildSection(
                title: "Individual Book Details",
                children: [
                  _buildDropdown('Series', series,"seriesTableId","seriesName", selectedSeries, (value) {
                    List<dynamic> pro = products
                        .where((ele) => ele['seriesCategory'] == value)
                        .map((ele) => ele['classId'] as String)
                        .toList();

                    setState((){
                      filteredClass = classes
                          .where((ele) => pro.contains(ele['classId']))
                          .toList();
                      selectedSeries = value;filterProductsBySeries(value);
                    });
                  }),
                  SizedBox(height: 5),
                  _buildDropdown('Class', filteredClass,"classId","className", selectedClass, (value) {
                    setState(() {selectedClass = value;filterProductsByClass(value);});
                  }),

                  SizedBox(height: 5),
                  _buildDropdown('Product', filteredProducts,"skuId","nameSku", selectedProduct, (value) {
                    setState(() => selectedProduct = value);
                    addProductIems(value);
                  }),
                  SizedBox(height: 5),
                  _buildNumberField('Quantity', bookQuantity, (value) {
                    setState(() => setQuantity = value);
                  }),
                ],
              ),
            if (productGroup=="6HPipXSLx5")
              _buildSection(
                title: "Product Details",
                children: [

                  _buildDropdown('Product', filteredMittplusItems,"id","product_name",selectedProduct, (value) {
                    setState(() => selectedProduct = value);
                    addProductIems(value);
                  }),
                  SizedBox(height: 5),
                  _buildNumberField('Quantity', bookQuantity, (value) {
                    setState(() => setQuantity = value);
                  }),
                ],
              ),


            bookType == 'Choose from Set'||bookType == 'Choose from Individual Book'||productGroup=="6HPipXSLx5"?
            Row(
              mainAxisAlignment: MainAxisAlignment.end,
              children: [
                ElevatedButton.icon(
                  onPressed: () {
                    if((selectedSet!=null||selectedProduct!=null)&&setQuantity!=null&&setQuantity!='0') {
                  setState(() {
                    allSets.add(
                        {"id": bookType=="Choose from Set"?selectedSet:selectedProduct, "quantity": setQuantity,"type":bookType,"productGroup":productGroup});

                    selectedOrders.add({
                      "data": bookType=="Choose from Set"?[...setItems]:[...productItems],
                      "quantity": setQuantity,
                      "group": productGroup,
                      "orderType":productItems[0]['type']=='set'?'Choose from Set':'Choose from Individual Book'
                    });


                    selectedSet = null;
                    selectedProduct=null;
                    setQuantity = '0';
                    quantityController.text='0';
                    productItems=[];
                  });
                }
                  },
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.green,

                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12), // Rounded corners
                    ),
                    padding: EdgeInsets.symmetric(horizontal: 16, vertical: 12), // Padding
                    elevation: 4, // Shadow effect
                  ),
                  icon: Icon(Icons.add, size: 20,color: Colors.white,), // Icon before the text
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
                :SizedBox(),
            const SizedBox(height: 20),


            _buildSection(title: "Added Products",
    children: [
      Container(
        height: 55*(allSets.length).toDouble(),
        width: double.infinity,
        child: allSets.length>0?ListView.builder(
                  itemCount: allSets.length,
                  itemBuilder: (context, index) {
                    final item = allSets[index];
                    return Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Container(
                          margin: const EdgeInsets.symmetric(vertical: 5, horizontal: 10), // Add some spacing around rows
                          padding: const EdgeInsets.all(8), // Add padding inside the row
                          decoration: BoxDecoration(
                            color: Colors.blue[50], // Light blue background color
                            border: Border.all(color: Colors.blue, width: 1), // Blue border
                            borderRadius: BorderRadius.circular(8), // Rounded corners
                          ),
                          child: Row(
                            mainAxisAlignment: MainAxisAlignment.spaceAround,
                            children: [
                              Text(
                                getNameById(item),
                                style: const TextStyle(fontSize: 14, fontWeight: FontWeight.bold), // Add styling to the text
                              ),
                              SizedBox(width: 56), // Add spacing between elements
                              Text(
                                item['quantity']??"",
                                style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold), // Add styling to the text
                              ),
                            ],
                          ),
                        ),
                        GestureDetector(
                          onTap:(){
                            setState(() {
                              allSets.removeAt(index);
                              selectedOrders.removeAt(index);
                            });
                          },
                          child: Icon(Icons.delete,color: Colors.red,),
                        )
                      ],
                    );
                  },
          physics: NeverScrollableScrollPhysics(),
        ):Text("No Products Added"),
      ),
    ]
    ),
            Center(
              child: SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  style: ElevatedButton.styleFrom(
                    backgroundColor:  Colors.indigo,
                    padding: const EdgeInsets.symmetric(vertical: 14),
                  ),
                  onPressed: _submitForm,
                  child: const Text('Create Order', style: TextStyle(color: Colors.white)),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSection({required String title, required List<Widget> children}) {
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

  Widget _buildDropdown(
      String label, List<dynamic> items,keyId,keyName, String? value, ValueChanged<String?> onChanged) {

    return DropdownButtonFormField<String>(
      decoration: InputDecoration(
        labelText: label,
        border: const OutlineInputBorder(),
        contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 14),
      ),
      value: value,
      items: items.map((item) => DropdownMenuItem(value: item![keyId]!.toString(), child: Text(item[keyName]??""))).toList(),
      onChanged: onChanged,
    );
  }

  Widget _buildNumberField(String label, String? value, Function(String) onChanged) {
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

  Widget _buildTextArea(String label, TextEditingController controller,String err,int maxli) {
    return TextField(
      controller: controller,
      maxLines: maxli,
      decoration: InputDecoration(
        labelText: label,
        border: const OutlineInputBorder(),
        errorText: err==""?null:err
      ),
    );
  }

  void _submitForm() async {
    print(widget.party['ownerId']);
    final prefs = await SharedPreferences.getInstance();
    final userString = prefs.getString('user');
    var userData;
    if(userString!=null){
      userData=jsonDecode(userString);
    }
    print(userData['role']);
    print(userData['id']);
    print("====");
    if (orderType == null ) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Please fill all required fields'),
          backgroundColor: Colors.red,
        ),
      );
      return;
    }
    if (selectedOrders.length == 0 ) {
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
    final  obj={
      "address": shippingAddressController.text,
    "approvalStatus": "0",
    "date": milliseconds,
    "discount": "0",
    "email": emailController.text,
    "mobileNo": phoneNumberController.text,
    "orderType":orderType,
    "ownerId": userData['role']=="se"?userData['id']:widget.party['ownerId'],
    "partyId": widget.party['schoolId']??widget.party['distributorID'],
      "addressId":widget.party['addressId'],
    "partyType": widget.type=='distributor'?"P6E9TGXewd":"cQpLw8vwZf",
    "totalAmount": 0,
    "transport": selectedTransporter,
      "transporter_name":getNameTransporter(selectedTransporter)
  };


    try {

      Navigator.push(
        context,
        MaterialPageRoute(builder: (context)=>CartScreen(payload:obj,orders:selectedOrders,series: series,)), // Route to HomePage
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
