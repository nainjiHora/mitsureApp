import 'dart:convert';
import 'package:open_filex/open_filex.dart'; // For opening different file types
import 'package:photo_view/photo_view.dart'; // For viewing images in full screen
import 'package:photo_view/photo_view_gallery.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:mittsure/screens/commonLayout.js.dart';
import 'package:mittsure/screens/returnItems.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../services/apiService.dart';
import 'orders.dart';

class OrderDetailsScreen extends StatefulWidget {
  final order;
  final bool userReq;
  final type;
  OrderDetailsScreen({required this.order,required this.userReq,required this.type});

  @override
  State<OrderDetailsScreen> createState() => _OrderDetailsScreenState();
}

class _OrderDetailsScreenState extends State<OrderDetailsScreen> {

  Map<String,dynamic> userData={};
  String _selectedOption = '';
  bool isLoading=false;
  String otpMobile="";
  getUserData() async{
    final prefs = await SharedPreferences.getInstance();
    final a = prefs.getString('user') ;
    if(a!.isNotEmpty) {
      setState(() {
        userData = jsonDecode(a??"");

      });
    }
  }
  void _showSuccessMessage(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(message), backgroundColor: Colors.green),
    );
  }

  List<dynamic> orderItems = [];

  approveRejectOrder(status,remark)async{
   setState(() {
     isLoading=true;
   });


    var body={};
    body['ownerId']=userData['id'];
    body['approvalStatus']=status;
    body['id']=widget.order['orderId'];
    body['reason']=remark;
    body['orderId']=widget.order['orderId'];
    try {

      final response = await ApiService.post(
        endpoint:userData['role']!='asm'? '/order/updateOrder':'/order/updateAsmApproval',
        body: body,
      );

      if (response != null) {
        setState(() {
          isLoading = false;
        });
        Navigator.pushReplacement(
          context,
          MaterialPageRoute(builder: (context) => OrdersScreen(userReq:widget.userReq,type: widget.type,)),
        );
      } else {
        throw Exception('Failed to load orders');
      }
    } catch (error) {
      print("Error fetchidddddng orders: $error");
    } finally {
      setState(() {
        isLoading = false;
      });
    }
  }

  fetchOrderItems() async {
    final body = {
      "id": widget.order['orderId']
    };

    try {
      final response = await ApiService.post(
        endpoint: '/order/fetchOrderItem', // Use your API endpoint
        body: body,
      );

      if (response != null) {
        final data = response['data'];
        setState(() {
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
    print(widget.order);
    fetchOrderItems();
    getUserData();
  }

  // Function to show the list of items in a dialog
  void _showOrderItemsDialog() {
    print(widget.order);
    showDialog(
      context: context,
      builder: (context) {
        return Dialog(
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12.0),
          ),
          child: Padding(
            padding: const EdgeInsets.all(16.0),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                const Text(
                  'Order Items',
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 10),
                orderItems.isEmpty
                    ? const Text('No items found')
                    : Flexible(
                  child: ListView.builder(
                    shrinkWrap: true,
                    itemCount: orderItems.length,
                    itemBuilder: (context, index) {
                      final item = orderItems[index];
                      return ListTile(
                        title: Text(
                          "${item['nameSku'] ?? item['product_name']} (${item['sku_code']})",
                        ),
                        subtitle: Text(
                          'Quantity: ${item['QTY']} | Unit Price: Rs.${item['Price']}',
                        ),
                      );
                    },
                  ),
                ),
                const SizedBox(height: 10),
                TextButton(
                  onPressed: () {
                    Navigator.pop(context); // Close the dialog
                  },
                  child: const Text('Close'),
                ),
              ],
            ),
          ),
        );
      },
    );
  }


  @override
  Widget build(BuildContext context) {
    print(widget.order);
    return CommonLayout(
    title:widget.order['so_id'] ?? "Order",
       currentIndex: 1,
      child: ListView(
        padding: const EdgeInsets.all(16.0),
        children: [
          const SectionTitle(title: 'Order Details'),
          OrderDetailsRow(label: 'Party', value: widget.order['schoolName'] ?? widget.order['DistributorName']),
          OrderDetailsRow(
            label: 'Date',
            value: DateFormat('dd MMM yyyy')
                .format(DateTime.parse(widget.order['createdAt'].toString())),
          ),
          OrderDetailsRow(label: 'Remark', value: widget.order['remark']??""),
          const Divider(),
          const SectionTitle(title: 'Item Details'),
          GestureDetector(
            onTap: _showOrderItemsDialog, // Show dialog on tap
            child: OrderDetailsRow(
              label: 'Order Items',
              value: orderItems.length.toString(),
            ),
          ),
          OrderDetailsRow(label: 'Sub Total', value: '₹' + widget.order['originalAmount']==null?"0":widget.order['originalAmount'] ),
          OrderDetailsRow(label: 'Discount', value: "${(double.parse(widget.order['originalAmount'])-double.parse(widget.order['totalAmount'])).toString()}" ?? "0"),
          OrderDetailsRow(label: 'Total', value: '₹' + widget.order['totalAmount'] ?? ""),
          const SizedBox(height: 16),
          Row(
            children: [
              Center(
                child: TextButton.icon(
                  onPressed: () {
                    _showOrderItemsDialog();
                  },
                  icon: const Icon(Icons.show_chart, color: Colors.blue),
                  label: const Text('Show Items', style: TextStyle(color: Colors.blue)),
                ),
              ),
              widget.order['approvalStatus']!=2?Center(
                child: TextButton.icon(
                  onPressed: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(builder: (context) => ReturnItemsScreen(order: widget.order)), // Route to HomePage
                    );
                  },
                  icon: const Icon(Icons.refresh, color: Colors.blue),
                  label: const Text('Return Order', style: TextStyle(color: Colors.blue)),
                ),
              ):SizedBox(height: 0,),
            ],
          ),
          const Divider(),
          const SectionTitle(title: 'Delivery Details'),
          OrderDetailsRow(label: 'Order Type', value: widget.order['orderType']),
          OrderDetailsRow(label: 'Address', value: widget.order['Address']),
          OrderDetailsRow(label: 'Contact Person', value: widget.order['name']),
          OrderDetailsRow(label: 'Contact Number', value: widget.order['mobileNo'].toString()),
          OrderDetailsRow(label: 'E-mail Id', value: widget.order['emailId']),
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [

              Center(
                child: TextButton.icon(
                  onPressed: () {
                  _showAttachmentsDialog(context);
                  },
                  icon: const Icon(Icons.file_copy_sharp, color: Colors.blue),
                  label: const Text('View Attachments', style: TextStyle(color: Colors.blue)),
                ),
              ),
            ],
          ),
          widget.order['approvalStatus']==6? Row(
            mainAxisAlignment: MainAxisAlignment.spaceEvenly,
            children: [
              ElevatedButton(

                  onPressed: _showConsentDialog,

                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.indigo[900],
                  padding: EdgeInsets.symmetric(horizontal: 24, vertical: 12),
                ),
                child: Text('Take Consent', style: TextStyle(color: Colors.white)),
              ),
              ElevatedButton(

                onPressed: _showDeleteDialog,

                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.red,
                  padding: EdgeInsets.symmetric(horizontal: 24, vertical: 12),
                ),
                child: Text('Discard', style: TextStyle(color: Colors.white)),
              ),

            ],
          ):SizedBox(height: 0,),
          (userData['role']!='se'&&userData["role"]!="asm"&&widget.order['approvalStatus']==0)||(userData["role"]=="asm"&&widget.order['asmApproval']==0&& widget.order['approvalStatus']==0)? Row(
            mainAxisAlignment: MainAxisAlignment.spaceEvenly,
            children: [
              ElevatedButton(
                onPressed: () {
                  approveRejectOrder(1, "Approved");
                },
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.green,
                  padding: EdgeInsets.symmetric(horizontal: 24, vertical: 12),
                ),
                child: Text('Accept', style: TextStyle(color: Colors.white)),
              ),
              ElevatedButton(
                onPressed: () {
                  _showRejectDialog(context);
                },
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.red,
                  padding: EdgeInsets.symmetric(horizontal: 24, vertical: 12),
                ),
                child: Text('Reject', style: TextStyle(color: Colors.white)),
              ),
            ],
          ):SizedBox(height: 0,)

        ],
      ),
    );
  }
  Future<void> proceed() async {
    setState(() {
      isLoading=true;
    });
    var id="";
    if(_selectedOption=='Stockist') {
      id=widget.order['stockistId'];
    }else if(_selectedOption=='Distributor'){
id=widget.order['partyId'].contains('S-')? widget.order['distributorIDforSchool']:widget.order['partyId'];
    }else{
id=widget.order['partyId'];
    }

    var body = {
      "id": id
    };

    try {
      final response = await ApiService.post(
        endpoint: '/user/sendOtpParty',
        body: body,
      );
      if (response != null && response['status'] == false) {
        setState(() {
          otpMobile=response['mobile'];
          isLoading=false;
        });
        _showOtpDialog();
      }else{
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text("Fail"), backgroundColor: Colors.red),
        );
      }


    }catch(error){
      print("Error sending Verification Code: $error");

    }
  }
  void _showDeleteDialog() {
    showDialog(
      context: context,
      builder: (context) {
        return StatefulBuilder( // Add StatefulBuilder to manage state inside dialog
          builder: (context, setDialogState) {
            return AlertDialog(
              title: Text(" ${widget.order['so_id']}"),
              content: Text(
                "Are you sure to Discard this order , Discarded order will not be available later."
              ),

              actions: [
                ElevatedButton(
                  onPressed: () {
                     discardOrder(widget.order['orderId']);
                  },
                  child: Text("Discard"),
                ),
                ElevatedButton(
                  onPressed: () {
     Navigator.pop(context);
                  },
                  child: Text("Cancel"),
                )
              ],
            );
          },
        );
      },
    );
  }

  discardOrder(id) async{
    setState(() {
      isLoading=true;
    });
    var body = {
      "id": id

    };

    try {
      final response = await ApiService.post(
        endpoint: '/order/deleteOrder',
        body: body,
      );

      if (response != null && response['status'] == true) {
        Navigator.pushReplacement(
          context,
          MaterialPageRoute(builder: (context) => OrdersScreen(userReq:widget.userReq,type: widget.type,)),
        );
      } else {

      }
    } catch (error) {
      print("Error verifying Verification Code: $error");

    }
  }
  void _showConsentDialog() {
    showDialog(
      context: context,
      builder: (context) {
        return StatefulBuilder( // Add StatefulBuilder to manage state inside dialog
          builder: (context, setDialogState) {
            return AlertDialog(
              title: Text("Take Consent"),
              content: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  widget.order['partyId'].contains('S-')
                      ? RadioListTile(
                    title: Text("School"),
                    value: "School",
                    groupValue: _selectedOption,
                    onChanged: (value) {
                      setDialogState(() { // Use setDialogState to update state within dialog
                        _selectedOption = value.toString();
                      });
                    },
                  )
                      : SizedBox(height: 0),
                  RadioListTile(
                    title: Text("Distributor"),
                    value: "Distributor",
                    groupValue: _selectedOption,
                    onChanged: (value) {
                      setDialogState(() {
                        _selectedOption = value.toString();
                      });
                    },
                  ),
                  RadioListTile(
                    title: Text("Stockist"),
                    value: "Stockist",
                    groupValue: _selectedOption,
                    onChanged: (value) {
                      setDialogState(() {
                        _selectedOption = value.toString();
                      });
                    },
                  ),
                ],
              ),
              actions: [
                ElevatedButton(
                  onPressed: () {
                    if (_selectedOption.isNotEmpty) {
                      Navigator.pop(context); // Close popup
                      setState(() {}); // Update main widget state if needed
                      proceed();
                    } else {
                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(content: Text("Please select an option")),
                      );
                    }
                  },
                  child: Text("Proceed"),
                ),
              ],
            );
          },
        );
      },
    );
  }
  Future<void> verifyOtp(flag) async {
setState(() {
  isLoading=true;
});
    var body = {
      "mobile": otpMobile,
      "otp": flag.text,
    };

    try {
      final response = await ApiService.post(
        endpoint: '/user/verifyOtp',
        body: body,
      );

       if (response != null && response['status'] == false) {

        await consentDone(); // Proceed to order
      } else {

      }
    } catch (error) {
      print("Error verifying Verification Code: $error");

    }
  }

  consentDone() async{

    setState(() {
      isLoading=true;
    });
    var body={};
    body['ownerId']=userData['id'];
    body['OrderId']=widget.order['orderId'];

    try {
       print(body);
      final response = await ApiService.post(
        endpoint: '/order/updateApprovalAndSendMailWithPdf',
        body: body,
      );

      if (response != null) {

        Navigator.pushReplacement(
          context,
          MaterialPageRoute(builder: (context) => OrdersScreen(userReq:widget.userReq,type: widget.type,)),
        );
      } else {
        throw Exception('Failed to load orders');
      }
    } catch (error) {
      print("Error fetchidddddng orders: $error");
    }
  }


  void _showOtpDialog() {
    TextEditingController otpController = TextEditingController();

    showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: Text("Enter Verification Code"),
          content: TextField(
            controller: otpController,
            keyboardType: TextInputType.number,
            decoration: InputDecoration(labelText: "Verification Code"),
          ),
          actions: [
            ElevatedButton(
              onPressed: () {
                verifyOtp(otpController);
              },
              child: Text("Submit"),
            ),
          ],
        );
      },
    );
  }

  void _showRejectDialog(BuildContext context) {
    TextEditingController _remarkController = TextEditingController();

    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: Text('Enter Remark'),
          content: TextField(
            controller: _remarkController,
            decoration: InputDecoration(hintText: "Enter your remark"),
            maxLines: 3,
          ),
          actions: [
            TextButton(
              onPressed: () {
                Navigator.of(context).pop(); // Close the popup
              },
              child: Text('Cancel'),
            ),
            ElevatedButton(
              onPressed: () {
                String remark = _remarkController.text.trim();
                if (remark.isNotEmpty) {
                  approveRejectOrder(2,remark);
                  Navigator.pop(context);

                } else {
                  // Show error if no remark entered
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(content: Text('Please enter a Remark')),
                  );
                }
              },
              child: Text('Submit',style: TextStyle(color: Colors.white),),
              style: ElevatedButton.styleFrom(backgroundColor: Colors.indigo[900]),
            ),
          ],
        );
      },
    );
  }
  void _showAttachmentsDialog(BuildContext context) {
    final attachments = jsonDecode(widget.order['attachment']) ?? [];

    showDialog(
      context: context,
      builder: (context) {
        return Dialog(
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12.0),
          ),
          child: Padding(
            padding: const EdgeInsets.all(16.0),
            child: SingleChildScrollView(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const Text(
                    'Attachments',
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 10),
                  attachments.isEmpty
                      ? const Text('No items found')
                      : ListView.builder(
                    shrinkWrap: true,
                    itemCount: attachments.length,
                    itemBuilder: (context, index) {
                      final attachment = attachments[index];
                      final fileName = attachment['originalName'] ?? 'Unknown File';
                      // final fileUrl = "https://mittsure.qdegrees.com:3001/file/${attachment['fileName']}";
                      final fileUrl = "https://mittsure.qdegrees.com:3001/file/${attachment['fileName']}";// File URL to open
print(fileUrl);
                      return ListTile(
                        leading: _getFileIcon(fileName),
                        title: Text(fileName),
                        onTap: () => _openFile(context, fileUrl, fileName),
                      );
                    },
                  ),
                  const SizedBox(height: 10),
                  TextButton(
                    onPressed: () => Navigator.pop(context),
                    child: const Text('Close'),
                  ),
                ],
              ),
            ),
          ),
        );
      },
    );
  }
}
void _showImageDialog(BuildContext context, String imageUrl) {
  showDialog(
    context: context,
    builder: (context) {
      return Dialog(
        backgroundColor: Colors.black,
        child: PhotoView(
          imageProvider: NetworkImage(imageUrl),
        ),
      );
    },
  );
}
void _openFile(BuildContext context, String fileUrl, String fileName) {
  if (fileUrl.isEmpty) return;

  if (fileName.endsWith('.jpg') || fileName.endsWith('.png') || fileName.endsWith('.jpeg')) {
    _showImageDialog(context, fileUrl);
  } else {
    OpenFilex.open(fileUrl);
  }
}
Widget _getFileIcon(String fileName) {
  if (fileName.endsWith('.jpg') || fileName.endsWith('.png') || fileName.endsWith('.jpeg')) {
    return const Icon(Icons.image, color: Colors.blue);
  } else if (fileName.endsWith('.pdf')) {
    return const Icon(Icons.picture_as_pdf, color: Colors.red);
  } else if (fileName.endsWith('.doc') || fileName.endsWith('.docx')) {
    return const Icon(Icons.description, color: Colors.blueAccent);
  } else if (fileName.endsWith('.xls') || fileName.endsWith('.xlsx')) {
    return const Icon(Icons.table_chart, color: Colors.green);
  } else {
    return const Icon(Icons.insert_drive_file, color: Colors.grey);
  }
}
// Section Title Widget
class SectionTitle extends StatelessWidget {
  final String title;

  const SectionTitle({super.key, required this.title});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8.0),
      child: Text(
        title,
        style: const TextStyle(
          fontSize: 16,
          fontWeight: FontWeight.bold,
          color: Colors.black87,
        ),
      ),
    );
  }
}

// Order Details Row Widget
class OrderDetailsRow extends StatelessWidget {
  final String label;
  final String value;

  const OrderDetailsRow({
    super.key,
    required this.label,
    required this.value,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4.0),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(
            label,
            style: TextStyle(fontSize: 14, color: Colors.black54),
          ),
          Text(
            value,
            style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w500),
          ),
        ],
      ),
    );
  }
  // Function to show the attachments dialog


}
