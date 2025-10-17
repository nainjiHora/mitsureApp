import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:mittsure/newApp/bookLoader.dart';
import 'package:mittsure/screens/fileUpload.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../services/apiService.dart';
import 'package:flutter_typeahead/flutter_typeahead.dart';
import 'package:dropdown_textfield/dropdown_textfield.dart';
import 'orders.dart';

class CreateOrderScreen extends StatefulWidget {
  final payload;

  CreateOrderScreen({required this.payload});
  @override
  _CreateOrderScreenState createState() => _CreateOrderScreenState();
}

class _CreateOrderScreenState extends State<CreateOrderScreen> {
  String? _selectedTransporter;
  String? _selectedDistributor;
  String? _selectedStockist;
  String? _selectedWarehouse;
  String? _selectedRemark;
  String? orderRemark;
  bool isLoading = false;
  List<dynamic> remarks = [];

  List<dynamic> attach = [];
  String _selectedAddressType = 'Party Address';
  String _selectedConsentPerson = 'Party Address';
  bool uploadFileScreen = false;
  final Map<String, Map<String, String>> addressData = {
    'Party Address': {
      'address': '',
      'mobile': '',
      'email': '',
    },
    'Distributor Address': {
      'address': '',
      'mobile': '',
      'email': '',
    },
    'Stockist Address': {
      'address': '',
      'mobile': '',
      'email': '',
    },
  };

  final TextEditingController otpController = TextEditingController();
  final TextEditingController distriController = TextEditingController();

  Future<List<String>> fetchSuggestions(String query) async {
    try {
      List<dynamic> suggestions = distributors
          .where((ele) =>
              ele['distributorID'].contains(query) ||
              ele['DistributorName']
                  .toLowerCase()!
                  .contains(query.toLowerCase()))
          .toList()
          .map((ele) => ele['DistributorName'] + "-" + ele['distributorID'])
          .toList();
      return suggestions.map((item) => item.toString()).toList();
    } catch (e) {
      print('Error fetching suggestions: $e');
      return [];
    }
  }

  saveFiles(bool flag, arr) {
    setState(() {
      attach = arr;
      uploadFileScreen = flag;
    });
  }

  List<dynamic> warehouse = [];
  var transporters = {'Stockist': {}, 'Distributor': {}};
  List<dynamic> alltransporters = [];
  List<dynamic> distributors = [];
  List<dynamic> stockists = [];

  final TextEditingController _addressController = TextEditingController();
  final TextEditingController _mobileController = TextEditingController();
  final TextEditingController _emailController = TextEditingController();
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
          _selectedTransporter = widget.payload['transport'];
          alltransporters = data;
        });
      } else {
        throw Exception('Failed to load orders');
      }
    } catch (error) {
      print("Error fetching orders: $error");
    }
  }

  fetchRemarks() async {
    final body = {};
    try {
      final response = await ApiService.post(
        endpoint: '/order/getRemarkinPicklist',
        body: body,
      );

      // Check if the response is valid
      if (response != null) {
        final data = response['data'];

        setState(() {
          remarks = data;
        });
      } else {
        throw Exception('Failed to load orders');
      }
    } catch (error) {
      print("Error fetching orders: $error");
    }
  }

  fetchWarehouse() async {
    final body = {};
    try {
      final response = await ApiService.post(
        endpoint: '/order/getWarehouseinPicklist',
        body: body,
      );

      // Check if the response is valid
      if (response != null) {
        final data = response['data'];

        setState(() {
          warehouse = data;
        });
      } else {
        throw Exception('Failed to load orders');
      }
    } catch (error) {
      print("Error fetching orders: $error");
    }
  }

  String formatAddress(Map<String, dynamic> addressData) {
    // Extract the fields, defaulting to an empty string if not found
    String addressLine1 = addressData['AddressLine1'] ?? '';
    String addressLine2 = addressData['AddressLine2'] ?? '';
    String state = addressData['State'] ?? '';
    String pincode = addressData['Pincode'] ?? '';

    // Build the address dynamically, skipping empty parts
    List<String> addressParts = [
      addressLine1,
      if (addressLine2.isNotEmpty) addressLine2,
      if (state.isNotEmpty) state,
      if (pincode.isNotEmpty) pincode,
    ];

    // Join the non-empty parts with a comma
    return addressParts.join(', ');
  }

  fetchDistributor() async {
    final body = {"ownerId": widget.payload['ownerId']};

    try {
      final response = await ApiService.post(
        endpoint: '/party/getAllDistri',
        body: body,
      );

      if (response != null) {
        final data = response['data'];

        setState(() {
          if (widget.payload['partyType'] != 'cQpLw8vwZf') {
            _selectedDistributor = widget.payload['partyId'];
            _selectedAddressType = 'Distributor Address';
            _selectedConsentPerson = 'Distributor Address';
            final a = data
                .where(
                    (distri) => distri['distributorID'] == _selectedDistributor)
                .toList()[0];

            addressData['Distributor Address']!['address'] = formatAddress(a);
            addressData['Distributor Address']!['email'] = a['email'] ?? "";
            addressData['Distributor Address']!['mobile'] =
                a['makerContact'] ?? "";
            var matchingTransporters = alltransporters
                .where((ele) => ele['transporterId'] == a['transporterId'])
                .toList();
            if (matchingTransporters.isNotEmpty) {
              transporters['Distributor'] = matchingTransporters[0];
            } else {
              transporters['Distributor'] = {};
            }
          }
          var obj = widget.payload['seriesDiscount'];
          var keys = obj.keys.toList();
          print(data.length);
          print("keys");
          int count = 0;
          final temp = [];

          for (var i = 0; i < data.length; i++) {
            if (data[i]['series'] != null) {
              List<dynamic> ser = jsonDecode(data[i]['series']);
              bool flag = false;
              for (var j = 0; j < keys.length; j++) {
                print(ser);
                print("9999");
                if (ser.contains(keys[j])) {
                } else {
                  flag = true;
                }
              }
              if (!flag) {
                temp.add(data[i]);
              }
            } else {
              temp.add(data[i]);
            }
          }

          distributors = temp;
        });
      } else {
        throw Exception('Failed to load orders');
      }
    } catch (error) {
      print("Error fetching orders: $error");
    }
  }

  fetchStockist() async {
    final body = {"ownerId": widget.payload['ownerId']};

    try {
      final response = await ApiService.post(
        endpoint: '/party/getStockist',
        body: body,
      );

      // Check if the response is valid
      if (response != null) {
        final data = response['data'];
        setState(() {
          print(data.length);
          stockists = data;
        });
      } else {
        throw Exception('Failed to load orders');
      }
    } catch (error) {
      print("Error fetching orders: $error");
    }
  }

  void _createOrder(flag) {
    if (_selectedTransporter == null ||
        _selectedDistributor == null ||
        _selectedStockist == null ||
        _selectedWarehouse == null ||
        _selectedRemark == null ||
        orderRemark == "") {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
            content: Text('Please fill all fields before creating an order.')),
      );
      return;
    }

    if (_selectedConsentPerson.toLowerCase() == 'stockist address' &&
        attach.length == 0) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Attachments can not be empty')),
      );
      return;
    }
    if (flag) {
      order(flag);
    } else {
      proceed(flag);
    }
  }

  Future<void> proceed(flag) async {
    setState(() {
      isLoading = true;
    });
    final prefs = await SharedPreferences.getInstance();
    final t = await prefs.getString('user');
    var id = "";
    if (t != null) {
      id = jsonDecode(t)['id'];
    }

    var body = {
      "mobile": addressData[_selectedConsentPerson!]!['mobile'],
      "token": id
    };

    try {
      final response = await ApiService.post(
        endpoint: '/user/sendOtpForOrder',
        body: body,
      );
      if (response != null && response['status'] == false) {
        setState(() {
          isLoading = false;
        });
        _showOtpDialog(flag);
      } else {
        _showErrorMessage("Failed to send Verification Code. Please try again.");
      }
    } catch (error) {
      print("Error sending Verification Code: $error");
      _showErrorMessage("Failed to send Verification Code. Please try again.");
    }
  }

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

  // Function to verify OTP
  Future<void> verifyOtp(flag) async {
    print(addressData[_selectedAddressType]!['mobile']);
    var body = {
      "mobile": addressData[_selectedConsentPerson]!['mobile'],
      "otp": otpController.text,
    };

    try {
      final response = await ApiService.post(
        endpoint: '/user/verifyOtp',
        body: body,
      );

      if (response != null && response['status'] == false) {
        Navigator.pop(context); // Close Verification Code dialog
        await order(flag); // Proceed to order
      } else {
        _showErrorMessage("Incorrect Verification Code. Please try again.");
      }
    } catch (error) {
      print("Error verifying Verification Code: $error");
      _showErrorMessage("Failed to verify Verification Code. Please try again.");
    }
  }

  consentDone(id) async {
    setState(() {
      isLoading = true;
    });
    var body = {};

    body['OrderId'] = id;

    try {
      print(body);
      final response = await ApiService.post(
        endpoint: '/order/updateApprovalAndSendMailWithPdf',
        body: body,
      );

      if (response != null) {
        Navigator.pushReplacement(
          context,
          MaterialPageRoute(builder: (context) => OrdersScreen(userReq: false,type: widget.payload['orderType'])),
        );
      } else {
        throw Exception('Failed to load orders');
      }
    } catch (error) {
      print("Error fetchidddddng orders: $error");
    }
  }

  Future<void> order(flag) async {
    var body = widget.payload;
    body['stockistId'] = _selectedStockist;
    body['distributorId'] = _selectedDistributor;
    body['transport'] = _selectedTransporter;
    body['mobileNo'] = addressData[_selectedAddressType]!['id']!;
    body['email'] = addressData[_selectedAddressType]!['email']!;
    body['address'] = addressData[_selectedAddressType]!['addId']!;
    body['otpConsent'] =
        "${_selectedConsentPerson.split(" ")[0]} (${addressData[_selectedConsentPerson]!['mobile']})";
    body['attachment'] = attach;
    body['remark'] = _selectedRemark;
    body['order_remark'] = orderRemark;
    body['saveLater'] = flag ? 1 : 0;
    body['warehouse'] = _selectedWarehouse;
    try {
      final response = await ApiService.post(
        endpoint: '/order/createOrder',
        body: body,
      );

      if (response != null && response['status'] == false) {
        if (flag) {
          Navigator.pushReplacement(
            context,
            MaterialPageRoute(builder: (context) => OrdersScreen(userReq: false,type: widget.payload['orderType'],)),
          );
        } else {
          consentDone(response["data1"]);
        }
      } else {
        throw Exception('Failed to create order');
      }
    } catch (error) {
      print("Error creating order: $error");
      _showErrorMessage("Failed to place the order. Please try again.");
    }
  }

  void _showOtpDialog(flag) {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) {
        return AlertDialog(
          title: Text(
            "Verification Code sent to ${addressData[_selectedConsentPerson]!['mobile']} (${_selectedConsentPerson.split(" ")[0]})",
            style: TextStyle(fontSize: 13),
          ),
          content: TextField(
            controller: otpController,
            keyboardType: TextInputType.number,
            decoration: InputDecoration(hintText: "Enter Verification Code"),
          ),
          actions: [
            TextButton(
              onPressed: () {
                Navigator.pop(context); // Close the dialog
              },
              child: Text("Cancel"),
            ),
            ElevatedButton(
              onPressed: () async {
                await verifyOtp(flag); 
              },
              child: Text("Submit"),
            ),
          ],
        );
      },
    );
  }

  initialiseData() {
    addressData['Party Address']!['address'] = widget.payload['address'];
    addressData['Party Address']!['mobile'] = widget.payload['mobileNo'];
    addressData['Party Address']!['email'] = widget.payload['email'];
    addressData['Party Address']!['id'] = widget.payload['partyId'];
    addressData['Party Address']!['addId'] = widget.payload['addressId'];
    fetchTransporter();
    fetchStockist();
    fetchDistributor();
    fetchWarehouse();
    fetchRemarks();
  }

  @override
  void initState() {
    super.initState();

    initialiseData();
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
        backgroundColor: Colors.indigo[900],
        title: Text(
          widget.payload['orderType'].toLowerCase()=='sales'?'Create Order':'Create Specimen Order',
          style: TextStyle(color: Colors.white),
        ),
      ),
      body: isLoading
          ? Center(
              child: BookPageLoader(),
            )
          : uploadFileScreen
              ? FileUploadScreen(
                  saveFiles: saveFiles,
                )
              : Padding(
                  padding: const EdgeInsets.all(16.0),
                  child: SingleChildScrollView(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        widget.payload['partyType'] == 'cQpLw8vwZf'
                            ? TypeAheadFormField<String>(
                                textFieldConfiguration: TextFieldConfiguration(
                                  controller: distriController,
                                  decoration: InputDecoration(
                                    border: OutlineInputBorder(),
                                    labelText: "Distributor Name",
                                    hintText: 'Enter Distributor Name or Id ',
                                  ),
                                ),
                                suggestionsCallback: (pattern) async {
                                  return await fetchSuggestions(pattern);
                                },
                                itemBuilder: (context, suggestion) {
                                  return ListTile(
                                    title: Text(suggestion),
                                  );
                                },
                                onSuggestionSelected: (suggestion) {
                                  print(suggestion);
                                  print("========gh===");
                                  final id = suggestion.split("D-")[1];
                                  final a = distributors
                                      .where((distri) =>
                                          distri['distributorID'] == "D-${id}")
                                      .toList()[0];
                                  setState(() {
                                    addressData['Distributor Address']![
                                        'address'] = formatAddress(a);
                                    addressData['Distributor Address']![
                                        'email'] = a['email'] ?? "";
                                    addressData['Distributor Address']![
                                        'mobile'] = a['makerContact'] ?? "";
                                    addressData['Distributor Address']!['id'] =
                                        "D-${id}" ?? "";
                                    addressData['Distributor Address']![
                                        'addId'] = a['addressId'] ?? "";
                                    var matchingTransporters = alltransporters
                                        .where((ele) =>
                                            ele['transporterId'] ==
                                            a['transporterId'])
                                        .toList();
                                    if (matchingTransporters.isNotEmpty) {
                                      transporters['Distributor'] =
                                          matchingTransporters[0];
                                    } else {
                                      transporters['Distributor'] = {};
                                    }
                                    distriController.text = suggestion;
                                    _selectedDistributor = "D-${id}";
                                  });
                                  // field.itemController.text = suggestion;
                                },
                                noItemsFoundBuilder: (context) => Padding(
                                  padding: const EdgeInsets.all(8.0),
                                  child: Text(
                                    'No Distributor Found',
                                    style: TextStyle(color: Colors.grey),
                                  ),
                                ),
                              )
                            : SizedBox(
                                height: 0,
                              ),
                        SizedBox(height: 12),
                        DropdownButtonFormField<String>(
                          decoration: InputDecoration(
                            labelText: "Stockist",
                            border: const OutlineInputBorder(),
                            contentPadding: const EdgeInsets.symmetric(
                                horizontal: 12, vertical: 14),
                          ),
                          value: _selectedStockist,
                          items: stockists
                              .map((item) => DropdownMenuItem(
                                  value: item['stockistID'].toString(),
                                  child: Text(item['StockistName'])))
                              .toList(),
                          onChanged: (onChanged) {
                            setState(() {
                              final a = stockists
                                  .where((distri) =>
                                      distri['stockistID'] == onChanged)
                                  .toList()[0];
                              addressData['Stockist Address']!['address'] =
                                  formatAddress(a);
                              addressData['Stockist Address']!['email'] =
                                  a['email'] ?? "";
                              addressData['Stockist Address']!['mobile'] =
                                  a['makerContact'] ?? "";
                              addressData['Stockist Address']!['id'] =
                                  onChanged ?? "";
                              addressData['Stockist Address']!['addId'] =
                                  a['addressId'] ?? "";

                              var matchingTransporters = alltransporters
                                  .where((ele) =>
                                      ele['transporterId'] ==
                                      a['transporterId'])
                                  .toList();
                              if (matchingTransporters.isNotEmpty) {
                                transporters['Stockist'] =
                                    matchingTransporters[0];
                              } else {
                                transporters['Stockist'] = {};
                              }
                            });
                            _selectedStockist = onChanged;
                          },
                        ),
                        SizedBox(
                          height: 10,
                        ),
                        DropdownButtonFormField<String>(
                          decoration: InputDecoration(
                            labelText: "Warehouse",
                            border: const OutlineInputBorder(),
                            contentPadding: const EdgeInsets.symmetric(
                                horizontal: 12, vertical: 14),
                          ),
                          value: _selectedWarehouse,
                          items: warehouse
                              .map((item) => DropdownMenuItem(
                                  value: item['wh_code'].toString(),
                                  child: Text(item['name'])))
                              .toList(),
                          onChanged: (onChanged) {
                            _selectedWarehouse = onChanged;
                          },
                        ),
                        _selectedDistributor != null &&
                                _selectedStockist != null
                            ? Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  // Title
                                  Text(
                                    "Choose Transporter:",
                                    style: TextStyle(
                                      fontSize: 16,
                                      fontWeight: FontWeight.bold,
                                      color: Colors.black87,
                                    ),
                                  ),
                                  const SizedBox(
                                      height:
                                          10), // Add spacing between title and options

                                  // Distributor Transporter Option
                                  ListTile(
                                    contentPadding: EdgeInsets.zero,
                                    dense: true,
                                    title: Text(
                                      transporters['Distributor']![
                                              'transporter_name'] ??
                                          "",
                                      style: TextStyle(
                                          fontSize: 14, color: Colors.black87),
                                    ),
                                    subtitle: Text(
                                      'Distributor',
                                      style: TextStyle(
                                          fontSize: 12, color: Colors.grey),
                                    ),
                                    leading: Radio<String>(
                                      value: transporters['Distributor']![
                                              'transporterId'] ??
                                          "",
                                      groupValue: _selectedTransporter,
                                      onChanged: (value) {
                                        setState(() {
                                          _selectedTransporter = value!;
                                        });
                                      },
                                    ),
                                  ),

                                  // Stockist Transporter Option (Only if available)
                                  if (transporters['Stockist']![
                                          'transporterId'] !=
                                      transporters['Distributor']![
                                          'transporterId'])
                                    ListTile(
                                      contentPadding: EdgeInsets.zero,
                                      dense: true,
                                      title: Text(
                                        transporters['Stockist']![
                                                'transporter_name'] ??
                                            "",
                                        style: TextStyle(
                                            fontSize: 14,
                                            color: Colors.black87),
                                      ),
                                      subtitle: Text(
                                        'Stockist',
                                        style: TextStyle(
                                            fontSize: 12, color: Colors.grey),
                                      ),
                                      leading: Radio<String>(
                                        value: transporters['Stockist']![
                                                'transporterId'] ??
                                            "",
                                        groupValue: _selectedTransporter,
                                        onChanged: (value) {
                                          setState(() {
                                            _selectedTransporter = value!;
                                          });
                                        },
                                      ),
                                    ),
                                ],
                              )
                            : SizedBox(),

                        SizedBox(height: 16),
                        Card(
                          shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(10)),
                          elevation: 3,
                          margin: const EdgeInsets.only(bottom: 20),
                          child: Padding(
                            padding: const EdgeInsets.all(
                                15), // Add padding inside the card for better spacing
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                // Title for the address type selection
                                Text(
                                  'Select Shipping Address :',
                                  style: TextStyle(
                                    fontSize: 16,
                                    fontWeight: FontWeight.bold,
                                    color: Colors.black87,
                                  ),
                                ),
                                const SizedBox(height: 10),

                                // Radio buttons for address type selection
                                Column(
                                  children: [
                                    widget.payload['partyType'] == 'cQpLw8vwZf'
                                        ? _buildAddressRadio(
                                            'School', 'Party Address')
                                        : SizedBox(
                                            height: 0,
                                          ),
                                    _buildAddressRadio(
                                        'Distributor', 'Distributor Address'),
                                    _buildAddressRadio(
                                        'Stockist', 'Stockist Address'),
                                  ],
                                ),
                                const SizedBox(height: 15),

                                // Display selected address details
                                if (_selectedAddressType != null &&
                                    addressData[_selectedAddressType!] !=
                                        null) ...[
                                  Divider(
                                      thickness: 1,
                                      color: Colors
                                          .grey[300]), // Add a separator line
                                  const SizedBox(height: 10),
                                  _buildDetailRow(
                                      'Address',
                                      addressData[_selectedAddressType!]![
                                              'address'] ??
                                          'N/A'),
                                  const SizedBox(height: 8),
                                  _buildDetailRow(
                                      'Mobile',
                                      addressData[_selectedAddressType!]![
                                              'mobile'] ??
                                          'N/A'),
                                  const SizedBox(height: 8),
                                  _buildDetailRow(
                                      'Email',
                                      addressData[_selectedAddressType!]![
                                              'email'] ??
                                          'N/A'),
                                ],
                              ],
                            ),
                          ),
                        ),
                        IconButton(
                          onPressed: () {
                            setState(() {
                              uploadFileScreen = true;
                            });
                          },
                          icon: Row(
                            children: [
                              Icon(Icons.upload_file, color: Colors.blue),
                              SizedBox(width: 8),
                              Text(
                                "Upload Attachments  ${attach.length > 0 ? '(' + attach.length.toString() + ' Uploaded)' : ""}",
                                style: TextStyle(
                                  fontWeight: FontWeight.bold,
                                  color: Colors.blue,
                                ),
                              ),
                            ],
                          ),
                        ),
                        SizedBox(height: 16),
// Add Dropdown for Remarks
                        DropdownButtonFormField<String>(
                          decoration: InputDecoration(
                            labelText: "Remarks",
                            border: OutlineInputBorder(),
                            contentPadding: EdgeInsets.symmetric(
                                horizontal: 12, vertical: 14),
                          ),
                          value: _selectedRemark,
                          items: remarks.map((remark) {
                            return DropdownMenuItem(
                              value: remark['name'].toString(),
                              child: Text(remark['name']),
                            );
                          }).toList(),
                          onChanged: (value) {
                            setState(() {
                              _selectedRemark = value;
                            });
                          },
                        ),
                        SizedBox(
                          height: 10,
                        ),
                        TextField(
                          onChanged: (value) {
                            orderRemark = value;
                          },
                          maxLength: 200, // Character limit
                          maxLines: null, // Allows multi-line input
                          decoration: InputDecoration(
                            border: OutlineInputBorder(),
                            labelText: 'Enter Remark (max 200 chars)',
                            counterText: "", // Hides default counter
                          ),
                          inputFormatters: [
                            LengthLimitingTextInputFormatter(
                                200), // Limits input length
                          ],
                        ),
                        Card(
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                          elevation: 4,
                          margin: const EdgeInsets.symmetric(
                              vertical: 15, horizontal: 10),
                          child: Padding(
                            padding: const EdgeInsets.all(16.0),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                // Title
                                Text(
                                  "Choose Consent Person:  (for Verification Code)",
                                  style: TextStyle(
                                    fontSize: 16,
                                    fontWeight: FontWeight.bold,
                                    color: Colors.black87,
                                  ),
                                ),
                                const SizedBox(height: 10),

                                // Party Option
                                widget.payload['partyType'] == 'cQpLw8vwZf'
                                    ? ListTile(
                                        contentPadding: EdgeInsets.zero,
                                        dense: true,
                                        title: Text(
                                          'School',
                                          style: TextStyle(
                                              fontSize: 14,
                                              color: Colors.black87),
                                        ),
                                        leading: Radio<String>(
                                          value: 'Party Address',
                                          groupValue: _selectedConsentPerson,
                                          onChanged: (value) {
                                            setState(() {
                                              _selectedConsentPerson = value!;
                                            });
                                          },
                                        ),
                                      )
                                    : SizedBox(
                                        height: 0,
                                      ),

                                // Distributor Option
                                ListTile(
                                  contentPadding: EdgeInsets.zero,
                                  dense: true,
                                  title: Text(
                                    'Distributor',
                                    style: TextStyle(
                                        fontSize: 14, color: Colors.black87),
                                  ),
                                  leading: Radio<String>(
                                    value: 'Distributor Address',
                                    groupValue: _selectedConsentPerson,
                                    onChanged: (value) {
                                      setState(() {
                                        _selectedConsentPerson = value!;
                                      });
                                    },
                                  ),
                                ),

                                // Stockist Option
                                ListTile(
                                  contentPadding: EdgeInsets.zero,
                                  dense: true,
                                  title: Text(
                                    'Stockist',
                                    style: TextStyle(
                                        fontSize: 14, color: Colors.black87),
                                  ),
                                  leading: Radio<String>(
                                    value: 'Stockist Address',
                                    groupValue: _selectedConsentPerson,
                                    onChanged: (value) {
                                      setState(() {
                                        _selectedConsentPerson = value!;
                                      });
                                    },
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),

                        SizedBox(height: 24),
                        ElevatedButton(
                          style: ElevatedButton.styleFrom(
                            minimumSize: Size(double.infinity, 50),
                            backgroundColor: Colors.green,
                          ),
                          onPressed: () {
                            _createOrder(false);
                          },
                          child: Text("Order",
                              style:
                                  TextStyle(fontSize: 18, color: Colors.white)),
                        ),
                        SizedBox(
                          height: 5,
                        ),
                        ElevatedButton(
                          style: ElevatedButton.styleFrom(
                            minimumSize: Size(double.infinity, 50),
                            backgroundColor: Colors.indigo[900],
                          ),
                          onPressed: () {
                            _createOrder(true);
                          },
                          child: Text("Save For Later",
                              style:
                                  TextStyle(fontSize: 18, color: Colors.white)),
                        ),
                      ],
                    ),
                  ),
                ),
    );
  }

  Widget _buildAddressRadio(String title, String value) {
    return ListTile(
      contentPadding: EdgeInsets.zero,
      dense: true,
      title: Text(
        title,
        style: TextStyle(fontSize: 14, color: Colors.black87),
      ),
      leading: Radio<String>(
        value: value,
        groupValue: _selectedAddressType,
        onChanged: (value) {
          setState(() {
            _selectedAddressType = value!;
          });
        },
      ),
    );
  }

  Widget _buildDetailRow(String label, String value) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          '$label: ',
          style: TextStyle(
            fontWeight: FontWeight.bold,
            fontSize: 14,
            color: Colors.black87,
          ),
        ),
        Expanded(
          child: Text(
            value,
            style: TextStyle(fontSize: 14, color: Colors.black54),
          ),
        ),
      ],
    );
  }
}
