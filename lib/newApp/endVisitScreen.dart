import 'dart:convert';
import 'dart:io';
import 'package:flutter/material.dart';
import 'package:geolocator/geolocator.dart';
import 'package:image_picker/image_picker.dart';
import 'package:http/http.dart' as http;
import 'package:mittsure/field/routes.dart';
import 'package:mittsure/newApp/bookLoader.dart';
import 'package:mittsure/newApp/productCategoryInput.dart';
import 'package:mittsure/newApp/visitPartyDetail.dart';
import 'package:mittsure/services/apiService.dart';
import 'package:mittsure/services/utils.dart';
import 'package:path/path.dart';
import 'package:shared_preferences/shared_preferences.dart';

class EndVisitScreen extends StatefulWidget {
  final visit;
  final type;
  final date;
  final visitId;
  EndVisitScreen({required this.visit, required this.type, required this.date,this.visitId});

  @override
  _EndVisitScreenState createState() => _EndVisitScreenState();
}

class _EndVisitScreenState extends State<EndVisitScreen> {
  final _formKey = GlobalKey<FormState>();

  List<dynamic> visitTypeOptions = [
    {"routeVisitType": "Select Visit Type", "routeVisitTypeID": ""}
  ];
  String? nextStep = null;
  String? visitOutcome = null;
  String? feedback = null;
  String? workDone = null;
  String? status = null;
  String? followUpDate = null;

  bool isLoading = false;
  TextEditingController contactPersonController = TextEditingController();
  TextEditingController phoneNumberController = TextEditingController();
  TextEditingController noOfbookController = TextEditingController();
  TextEditingController tentativeAmountController = TextEditingController();

  final TextEditingController extraController = TextEditingController();

  double? latitude;
  double? longitude;

  File? _image;
  final ImagePicker _picker = ImagePicker();

  @override
  void initState() {
    super.initState();
    _fetchLocation();
    fetchPicklist();
  }

  Map<dynamic, dynamic> dropdowns = {};

  Future<void> _fetchLocation() async {
    bool serviceEnabled = await Geolocator.isLocationServiceEnabled();
    if (!serviceEnabled) return;

    LocationPermission permission = await Geolocator.requestPermission();
    if (permission == LocationPermission.denied ||
        permission == LocationPermission.deniedForever) {
      return;
    }

    Position position = await Geolocator.getCurrentPosition(
        desiredAccuracy: LocationAccuracy.high);
    setState(() {
      latitude = position.latitude;
      longitude = position.longitude;
    });
  }

  Future<void> _captureImage() async {
    final XFile? photo = await _picker.pickImage(source: ImageSource.camera);
    if (photo != null) {
      setState(() {
        _image = File(photo.path);
      });
    }
  }

  fetchPicklist() async {
    final body = {};
    print("opip");

    try {
      final response = await ApiService.post(
        endpoint: '/visit/getDataForAppDropDown', // Use your API endpoint
        body: body,
      );

        print(response);
        print("pppresponse");
      if (response != null && response['status'] == false) {
        print("njinji");
        setState(() {
          print(widget.visit);
          contactPersonController.text=widget.visit['makerName']??"";
          phoneNumberController.text=widget.visit['makerContact']??"";
          dropdowns = response['data'];
        });
      } else {
        throw Exception('Failed to load orders');
      }
    } catch (error) {
      print("Error fetcffdfdhing orders: $error");
    }
  }

  Future<void> _submitForm(cont) async {
    
    if (_formKey.currentState!.validate() &&
        latitude != null &&
        longitude != null ) {
          setState(() {
            isLoading=true;
          });
      final uri = Uri.parse(
          'https://mittsure.qdegrees.com:3001/visit/endVisit'); // Change this

      final prefs = await SharedPreferences.getInstance();
      final hasData = prefs.getString('user') != null;
      var id = "";
      if (hasData) {
        id = jsonDecode(prefs.getString('user') ?? "")['id'];
      } else {
        return;
      }

      var request = http.MultipartRequest('POST', uri);
      request.fields['id'] = widget.visit['visitId']??widget.visitId;
      request.fields['ownerId'] = id;
      request.fields['endLat'] = latitude.toString();
      request.fields['endLong'] = longitude.toString();
      request.fields['contactPerson'] = contactPersonController.text ?? "";
      request.fields['status'] = status ?? "";
      request.fields['workDone'] = workDone ?? "";
      request.fields['noOfBook'] = noOfbookController.text ?? "";
      request.fields['phoneNumber'] = phoneNumberController.text ?? "";
      request.fields['tentativeAmount'] = tentativeAmountController.text ?? "";
      request.fields['feedback'] = feedback ?? "";
      request.fields['phone'] = widget.visit['makerContact'] ?? "";
      // request.fields['noVisitCount'] = feedback ?? "";
      request.fields['remark'] = extraController.text;
      request.fields['product_category'] = jsonEncode([]);
      request.fields['status_remark'] = extraController.text;
      request.fields['followUpDate'] = followUpDate ?? "";
      request.fields['visitOutcome'] = visitOutcome ?? "";
      request.fields['nextStep'] = nextStep ?? "";

      // request.files.add(
      //   await http.MultipartFile.fromPath(
      //     'end_image',
      //     _image!.path,
      //     filename: basename(_image!.path),
      //   ),
      // );
     print(request.fields);

      Navigator.push(
          cont,
          MaterialPageRoute(
              builder: (context) => ProductCategoryInput(payload:request,visit: widget.visit,)),
        );
   
    return;
      final response = await request.send();
      var respons = await http.Response.fromStream(response);

      final res = jsonDecode(respons.body);
     print(res);
      if (response.statusCode >= 200 &&
          response.statusCode < 300 &&
          res['status'] == false) {
        // Navigator.pushReplacement(
        //   cont,
        //   MaterialPageRoute(
        //       builder: (context) => RouteDetailsScreen(
        //           data: widget.visit, type: widget.type, date: widget.date,visitStatus: 4,)),
        // );
         Navigator.pushReplacement(
          cont,
          MaterialPageRoute(
              builder: (context) => CreatedRoutesPage()),
        );
      } else {
        setState(() {
          isLoading=false;
        });
        DialogUtils.showCommonPopup(context: cont, message: res['message'], isSuccess: false);
        // ScaffoldMessenger.of(cont).showSnackBar(
        //   SnackBar(content: Text(res['message'])),
        // );
      }
    } else {
      setState(() {
          isLoading=false;
        });
      ScaffoldMessenger.of(cont).showSnackBar(
        SnackBar(content: Text('Please fill all fields and capture image')),
      );
    }
  }

  Widget _buildDropdown(String label, List<dynamic> items, keyId, keyName,
      String? value, ValueChanged<String?> onChanged) {
        print(label);
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 3.0),
      child: DropdownButtonFormField<String>(
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
      ),
    );
  }

Widget _buildTextField(String label, TextEditingController controller) {
  return Padding(
    padding: const EdgeInsets.symmetric(vertical: 3.0),
    child: TextFormField(
      controller: controller,
      decoration: InputDecoration(
        labelText: label,
        border: OutlineInputBorder(
          borderSide: BorderSide(width: 1.0, color: Colors.black),
        ),
        enabledBorder: OutlineInputBorder(
          borderSide: BorderSide(width: 1.0, color: Colors.black),
        ),
        focusedBorder: OutlineInputBorder(
          borderSide: BorderSide(width: 1.0, color: Colors.blue), // Optional: different color when focused
        ),
      ),
      validator: (value) => value == null || value.isEmpty ? 'Required' : null,
    ),
  );
}

  bool includeCompanion = false;

  @override
  Widget build(BuildContext context) {
    return WillPopScope(
      onWillPop: ()async{
         Navigator.pushReplacement(
          context,
          MaterialPageRoute(
              builder: (context) => RouteDetailsScreen(
                  data: widget.visit, type: widget.type, date: widget.date,visitStatus: 3,)),
        );
        return false;
      },
      child: Stack(
        children: [
          Scaffold(
            appBar: AppBar(
              title: Text('End Visit', style: TextStyle(color: Colors.white)),
              iconTheme: IconThemeData(color: Colors.white),
              backgroundColor: Colors.indigo[900],
            ),
            body: Padding(
              padding: const EdgeInsets.all(16.0),
              child: Form(
                key: _formKey,
                child: ListView(
                  children: [
                    _buildTextField('Contact Person', contactPersonController),
                    _buildTextField('Mobile Number', phoneNumberController),
                    _buildDropdown(
                        'Visit Status',
                        dropdowns['statusType'],
                        "statusTypeId",
                        'statusTypeName',
                        status,
                        (val) => setState(() {
                              status = val;
                            })),
                    _buildDropdown(
                        'Work Done',
                        dropdowns['workDone'],
                        "workDoneTableId",
                        'workDoneName',
                        workDone,
                        (val) => setState(() {
                              workDone = val;
                            })),
                             _buildDropdown(
                        'Feedback',
                        dropdowns['feedback'],
                        "feedbackId",
                        'feedbackName',
                        feedback,
                        (val) => setState(() {
                              feedback = val;
                            })),
                          
                          _buildDropdown(
                        'Next Step',
                        dropdowns['nextStep'],
                        "nextStepTableId",
                        'nextStepName',
                        nextStep,
                        (val) => setState(() {
                              nextStep = val;
                            })),
                             _buildDropdown(
                        'Visit OutCome',
                        dropdowns['visitOutcome'],
                        "id",
                        'name',
                        visitOutcome,
                        (val) => setState(() {
                              visitOutcome = val;
                            })),
                    SizedBox(height: 16),
                    Row(
                      children: [
                        Icon(Icons.location_on),
                        SizedBox(width: 8),
                        Text(latitude != null && longitude != null
                            ? 'Lat: ${latitude!.toStringAsFixed(5)}, Long: ${longitude!.toStringAsFixed(5)}'
                            : 'Fetching location...'),
                      ],
                    ),
                    SizedBox(height: 16),
                    // Text('Capture Image:',
                    //     style: TextStyle(fontWeight: FontWeight.bold)),
                    // SizedBox(height: 8),
                    // _image != null
                    //     ? Image.file(_image!, height: 200)
                    //     : Text('Image Mandatory'),
                    // ElevatedButton.icon(
                    //   icon: Icon(Icons.camera_alt),
                    //   label: Text('Capture from Camera'),
                    //   onPressed: _captureImage,
                    // ),
                    SizedBox(height: 14),
                    ElevatedButton.icon(
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.green,
                        foregroundColor: Colors.white,
                      ),
                      icon: Icon(Icons.check),
                      label: Text('Proceed'),
                      onPressed: () {
                        _submitForm(context);
                      },
                    ),
                  ],
                ),
              ),
            ),
          ),
          if (isLoading) const BookPageLoader(),
        ],
      ),
    );
  }
}
