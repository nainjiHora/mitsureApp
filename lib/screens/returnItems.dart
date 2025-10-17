import 'package:flutter/material.dart';
import 'package:mittsure/screens/commonLayout.js.dart';
import 'package:mittsure/screens/orders.dart';

import '../services/apiService.dart';

class ReturnItemsScreen extends StatefulWidget {
  final order;
  ReturnItemsScreen({required this.order});
  @override
  _ReturnItemsScreenState createState() => _ReturnItemsScreenState();
}

class _ReturnItemsScreenState extends State<ReturnItemsScreen> {
   List<dynamic> orderItems = [];

   List<dynamic> returnItems = [];
 List<dynamic> reasons=[];

 getReasonById(value){
   final a=reasons.where((element) => element['id']==value);
   final aList = a.toList();
   return aList[0]['name'];
 }

 fetchReasons() async{

   final body = {};
       try {
         final response = await ApiService.post(
           endpoint: '/picklist/getReturnReason', // API endpoint
           body: body,
         );
         if (response != null && response['status'] == false) {
           setState(() {
             reasons=response['data'];
           });
         } else {
           _showSuccessMessage(response['message'],false);
         }
       } catch (error) {
         print("Error during return request: $error");
       }
     }


  void _addItemToReturn( item, int quantity, String reason) {
    setState(() {
      for (var order in orderItems) {
        if (item['itemId'] == order["itemId"]) {
          if (order['QTY'] >= quantity) {
            order['QTY'] -= quantity;
          } else {
            print('Error: Not enough quantity to subtract');
          }
          break;
        }
      }
      returnItems.add({'name': item['productGroup']=='6HPipXSLx5'?item['product_name']:item['nameSku'],'itemId':item['itemId'], 'qty': quantity, 'reason': reason});
    });
  }
   void _removeItemFromReturn(int index) {
     showDialog(
       context: context,
       builder: (BuildContext context) {
         return AlertDialog(
           title: Text("Confirm Deletion"),
           content: Text("Are you sure you want to remove this item from Return?"),
           actions: [
             TextButton(
               onPressed: () {
                 // Close the dialog without deleting
                 Navigator.of(context).pop();
               },
               child: Text("Cancel"),
             ),
             TextButton(
               onPressed: () {
                 // Proceed with deletion
                 setState(() {
                   final item = returnItems[index];
                   for (var order in orderItems) {
                     if (item['itemId'] == order["itemId"]) {
                       order['QTY'] += item['qty'];
                       break;
                     }
                   }
                   returnItems.removeAt(index);
                 });
                 Navigator.of(context).pop(); // Close the dialog after deletion
               },
               child: Text("Delete"),
             ),
           ],
         );
       },
     );
   }

   void _submitReturn()  async {
      final body = {
        "orderId": widget.order['orderId'],
        "partyId": widget.order['partyId'],
        "item": returnItems,
        "returnReason":returnItems[0]['reason']
      };

      try {
        final response = await ApiService.post(
          endpoint: '/order/returnOrderItems', // API endpoint
          body: body,
        );

        if (response != null && response['status'] == false) {
          _showSuccessMessage("Return Requested",true);
          Navigator.pushReplacement(
            context,
            MaterialPageRoute(builder: (context) => OrdersScreen(userReq: false,type: 'Specimen',)),
          );

        } else {
          _showSuccessMessage(response['message'],false);
        }
      } catch (error) {
        print("Error during return request: $error");
      }
    }
    void _showSuccessMessage(String message,bool status) {
     ScaffoldMessenger.of(context).showSnackBar(
       SnackBar(content: Text(message), backgroundColor: status?Colors.green:Colors.red),
     );
   }
  fetchOrderItems()async{
    final body = {
      "id":widget.order['orderId']
    };

    try {

      final response = await ApiService.post(
        endpoint: '/order/fetchOrderItem',  // Use your API endpoint
        body: body,
      );


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
    fetchReasons();
    fetchOrderItems();
  }
  @override
  Widget build(BuildContext context) {
    return CommonLayout(

        title:'Return Items',
      currentIndex: 4,
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          children: [
            Expanded(
              child: _buildOrderItemsTable(),
            ),
            SizedBox(height: 16),
            Expanded(
              child: _buildReturnItemsList(),
            ),
            SizedBox(height: 16),
            ElevatedButton(

              onPressed: _submitReturn,
              child: Text('Proceed'),
              style: ElevatedButton.styleFrom(
                minimumSize: Size(double.infinity, 48),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildOrderItemsTable() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Order Items',
          style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
        ),
        Expanded(
          child: ListView.builder(
            itemCount: orderItems.length,
            itemBuilder: (context, index) {
              final item = orderItems[index];
              return Card(
                child: item['QTY']>0?ListTile(
                  title: Text(item['productGroup']=='6HPipXSLx5'?item['product_name']:item['nameSku']),
                  subtitle: Text('Quantity: ${item['QTY']} | Unit Price: Rs.${item['Price']}'),
                  onTap: () {
                    _showAddToReturnDialog(item);
                  },
                ):null,
              );
            },
          ),
        ),
      ],
    );
  }

  Widget _buildReturnItemsList() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Items to Return',
          style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
        ),
        Expanded(
          child: ListView.builder(
            itemCount: returnItems.length,
            itemBuilder: (context, index) {
              final item = returnItems[index];
              return Card(
                child: ListTile(
                  title: Text(item['name']),
                  subtitle: Text('Quantity: ${item['qty']} | Reason: ${getReasonById(item['reason'])}'),
                  trailing: IconButton(
                    icon: Icon(Icons.delete, color: Colors.red),
                    onPressed: () => _removeItemFromReturn(index),
                  ),
                ),
              );
            },
          ),
        ),
      ],
    );
  }

   void _showAddToReturnDialog(Map<String, dynamic> item) {
     final TextEditingController quantityController = TextEditingController();
     String? selectedReason;
     String? quantityError;

     showDialog(
       context: context,
       builder: (context) {
         return StatefulBuilder(
           builder: (context, setState) {
             return AlertDialog(
               title: Text('Return ${item['productGroup']=='6HPipXSLx5'?item['product_name']:item['nameSku']}'),
               content: Column(
                 mainAxisSize: MainAxisSize.min,
                 children: [
                   TextField(
                     controller: quantityController,
                     decoration: InputDecoration(
                       labelText: 'Quantity',
                       errorText: quantityError,
                     ),
                     keyboardType: TextInputType.number,
                     onChanged: (value) {
                       final quantity = int.tryParse(value);
                       setState(() {
                         if (quantity == null || quantity > item['QTY'] || quantity <= 0) {
                           quantityError = 'Enter a valid quantity (max ${item['QTY']})';
                         } else {
                           quantityError = null;
                         }
                       });
                     },
                   ),
                   _buildDropdown('Reason', reasons,"id",'name', selectedReason, (value) {
                     setState(() => selectedReason = value);
                   }),

                 ],
               ),
               actions: [
                 TextButton(
                   onPressed: () => Navigator.of(context).pop(),
                   child: Text('Cancel'),
                 ),
                 ElevatedButton(
                   onPressed: () {
                     final quantity = int.tryParse(quantityController.text);
                     if (quantity == null || quantity > item['QTY'] || quantity <= 0) {
                       setState(()=>{
                       quantityError = 'Enter a valid quantity (max ${item['QTY']})'
                       });
                       } else {
                       if (quantity != null) {
                         _addItemToReturn(item, quantity, selectedReason!);
                         Navigator.of(context).pop();
                       }
                     }

                   },
                   child: Text('Add'),
                 ),
               ],
             );
           },
         );
       },
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
       items: items.map((item) => DropdownMenuItem(value: item![keyId]!.toString(), child: Text(item[keyName]))).toList(),
       onChanged: onChanged,
     );
   }
}