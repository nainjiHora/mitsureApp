import 'dart:convert';
import 'dart:io';
import 'package:flutter/material.dart';
import 'package:geolocator/geolocator.dart';
import 'package:image_picker/image_picker.dart';
import 'package:http/http.dart' as http;
import 'package:mittsure/newApp/bookLoader.dart';
import 'package:mittsure/newApp/visitPartyDetail.dart';
import 'package:mittsure/services/apiService.dart';
import 'package:path/path.dart';
import 'package:shared_preferences/shared_preferences.dart';

class VisitCaptureScreen extends StatefulWidget {
  final visit;
  final type;
  final date;
  VisitCaptureScreen(
      {required this.visit, required this.type, required this.date});

  @override
  _VisitCaptureScreenState createState() => _VisitCaptureScreenState();
}

class _VisitCaptureScreenState extends State<VisitCaptureScreen> {
  final _formKey = GlobalKey<FormState>();

  List<dynamic> visitTypeOptions = [
    {"routeVisitType": "Select Visit Type", "routeVisitTypeID": ""}
  ];
  List<dynamic> asms = [];
  List<dynamic> rsms = [];
  List<dynamic> rms = [];

  List<dynamic> allUsers = [];
  bool isLoading = false;
  String? tagUserController = null;
  String? superwisorController = null;
  String? rsmController = null;
  String? visitType = null;
  final TextEditingController extraController = TextEditingController();

  double? latitude;
  double? longitude;

  File? _image;
  final ImagePicker _picker = ImagePicker();
   Map<String, dynamic> userData = {};
  getUserData() async {
    final prefs = await SharedPreferences.getInstance();
    final a = prefs.getString('user');
    if (a!.isNotEmpty) {
      setState(() {
        userData = jsonDecode(a ?? "");
        
      });
    }
  }

  @override
  void initState() {
    super.initState();
    getUserData();
    _fetchLocation();
    fetchPicklist();
  }

  _fetChAllRSM() async {
    try {
      setState(() {
        isLoading = true;
      });
      final response =
          await ApiService.post(endpoint: '/user/getUsers', body: {});

      if (response != null) {
        final data = response['data'];

        setState(() {
          rsms = data.where((e) => e['role'] == 'rsm').toList();
          asms = data.where((e) => e['role'] == 'asm').toList();
          rms = data.where((e) => e['role'] == 'se' && userData['id']!=e['id']).toList();
          allUsers = data;
          isLoading=false;
        });
      } else {
        throw Exception('Failed to load orders');
      }
    } catch (error) {
      print("Error fetching ojbjbjbjjrders: $error");
    } finally {}
  }

  _fetchAsm(id) async {
    setState(() {
      isLoading = true;
    });

    //   try {

    //     if(id!="") {
    //       final response = await ApiService.post(
    //         endpoint: '/user/getUserListBasedOnId'
    //         ,
    //         body: {"userId": id},
    //       );

    //       if (response != null) {
    //         final data = response['data'];
    //         setState(() {
    //           asmList = data;
    //           selectedSE="";
    //           seList=response['data1'];
    //           isLoading = false;
    //         });
    //       } else {
    //         throw Exception('Failed to load orders');
    //       }
    //     }else{
    setState(() {
      asms = allUsers
          .where((e) => e['role'] == 'asm' && e['reportingManager'] == id)
          .toList();
      // seList=allUsers.where((e)=>e['role']=='se').toList();
      superwisorController = asms[0]['id'];
         isLoading=false;
      // tagUserController = "";
    });
    //     }
    //   } catch (error) {
    //     print("Error fetching ojbjbjbjjrders: $error");
    //   } finally {

    //   }
  }

  _fetchSe(id) async {
    //   _fetchOrders(currentPage);
    //   try {
    setState(() {
      isLoading = true;
    });
    //     if(id!="") {
    //       final response = await ApiService.post(
    //         endpoint: '/user/getUserListBasedOnId'
    //         ,
    //         body: {"userId": id},
    //       );

    //       if (response != null) {
    //         final data = response['data'];
    //         setState(() {

    //           seList=data;
    //           isLoading = false;
    //         });
    //       } else {
    //         throw Exception('Failed to load orders');
    //       }
    //     }else{
    setState(() {
      rms = allUsers
          .where((e) => e['role'] == 'se' && e['reportingManager'] == id)
          .toList();
      tagUserController = rms[0]['id'];
      isLoading = false;
    });
    //     }
    //   } catch (error) {
    //     print("Error fetching orders: $error");
    //   } finally {
    //     setState(() {
    //       isLoading = false;
    //     });
    //   }
  }

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
    setState(() {
      isLoading=true;
    });

    try {
      final response = await ApiService.post(
        endpoint: '/picklist/getRouteVisitType', // Use your API endpoint
        body: body,
      );
      if (response != null && response['status'] == false) {
        setState(() {
          visitTypeOptions.addAll(response['data']);
          visitType = widget.visit['visitType'];
          isLoading=false;
        });
      } else {
        throw Exception('Failed to load orders');
      }
    } catch (error) {
      print("Error fetcffdfdhing orders: $error");
    }
  }

  Future<void> _submitForm(cont) async {
    if (widget.visit['visited_status'] != 0) {
      print("Visit has already started or its done");
      return;
    }
    if (_formKey.currentState!.validate() &&
        latitude != null &&
        longitude != null &&
        _image != null) {
      final uri = Uri.parse(
          'https://mittsure.qdegrees.com:3001/visit/startVisit'); // Change this

      final prefs = await SharedPreferences.getInstance();
      final hasData = prefs.getString('user') != null;
      var id = "";
      if (hasData) {
        id = jsonDecode(prefs.getString('user') ?? "")['id'];
      } else {
        return;
      }

      setState(() {
        isLoading = true;
      });
      var request = http.MultipartRequest('POST', uri);
      request.fields['ownerId'] = id;
      request.fields['partyId'] = widget.visit['partyId'];
      request.fields['partyType'] = widget.visit['partyType'].toString();
      request.fields['start_lat'] = latitude.toString();
      request.fields['start_long'] = longitude.toString();
      request.fields['tag_User'] = tagUserController ?? "";
      request.fields['superwisor'] = superwisorController ?? "";
      request.fields['visitEntryType'] = visitType ?? "";
      request.fields['extra'] = extraController.text;

      request.files.add(
        await http.MultipartFile.fromPath(
          'start_image',
          _image!.path,
          filename: basename(_image!.path),
        ),
      );

      final response = await request.send();
      var respons = await http.Response.fromStream(response);

      final res = jsonDecode(respons.body);

      if (response.statusCode >= 200 &&
          response.statusCode < 300 &&
          res['status'] == false) {
        Navigator.pushReplacement(
          cont,
          MaterialPageRoute(
              builder: (context) => RouteDetailsScreen(
                    data: widget.visit,
                    type: widget.type,
                    date: widget.date,
                    visitStatus: 1,
                    visitId: res['data']['visitId'],
                  )),
        );
      } else {
        setState(() {
          isLoading = false;
        });
        ScaffoldMessenger.of(cont).showSnackBar(
          SnackBar(content: Text(res['message'])),
        );
      }
    } else {
      setState(() {
        isLoading = false;
      });
      ScaffoldMessenger.of(cont).showSnackBar(
        SnackBar(content: Text('Please fill all fields and capture image')),
      );
    }
  }

  Widget _buildDropdown(String label, List<dynamic> items, keyId, keyName,
      String? value, ValueChanged<String?> onChanged) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 5.0),
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
      padding: const EdgeInsets.symmetric(vertical: 2.0),
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
            borderSide: BorderSide(
                width: 1.0,
                color: Colors.blue), // Optional: different color when focused
          ),
        ),
        validator: (value) =>
            value == null || value.isEmpty ? 'Required' : null,
      ),
    );
  }

  bool includeCompanion = false;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Start Visit', style: TextStyle(color: Colors.white)),
        iconTheme: IconThemeData(color: Colors.white),
        backgroundColor: Colors.indigo[900],
      ),
      body: isLoading
          ? Center(
              child: BookPageLoader(),
            )
          : Padding(
              padding: const EdgeInsets.all(16.0),
              child: Form(
                key: _formKey,
                child: ListView(
                  children: [
                    CheckboxListTile(
                      title: Text('Tag Colleague'),
                      value: includeCompanion,
                      onChanged: (value) async {
                        setState(() {
                          includeCompanion = value ?? false;
                        });
                        if (includeCompanion) {
                          await _fetChAllRSM();
                        }
                      },
                    ),
                    if (includeCompanion) ...[
                      _buildDropdown(
                        'Select VP',
                        rsms,
                        'id',
                        'name',
                        rsmController,
                        (value) {
                          setState(() {
                            rsmController = value;
                            _fetchAsm(value);
                          });
                        },
                      ),
                      _buildDropdown(
                        'Select CH',
                        asms,
                        'id',
                        'name',
                        superwisorController,
                        (value) {
                          setState(() {
                            superwisorController = value;
                            _fetchSe(value);
                          });
                        },
                      ),
                      _buildDropdown(
                        'Select RM',
                        rms,
                        'id',
                        'name',
                        tagUserController,
                        (value) {
                          setState(() {
                            tagUserController = value;
                          });
                        },
                      ),
                    ],
                    _buildDropdown(
                        'Visit Type',
                        visitTypeOptions,
                        "routeVisitTypeID",
                        'routeVisitType',
                        visitType,
                        (val) => setState(() {
                              visitType = val;
                            })),
                    _buildTextField('Extra Notes', extraController),
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
                    Text('Capture Image:',
                        style: TextStyle(fontWeight: FontWeight.bold)),
                    SizedBox(height: 8),
                    _image != null
                        ? Image.file(_image!, height: 200)
                        : Text('No image captured'),
                    ElevatedButton.icon(
                      icon: Icon(Icons.camera_alt),
                      label: Text('Capture from Camera'),
                      onPressed: _captureImage,
                    ),
                    SizedBox(height: 24),
                    ElevatedButton.icon(
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.green,
                        foregroundColor: Colors.white,
                      ),
                      icon: Icon(Icons.check),
                      label: Text('Submit'),
                      onPressed: () {
                        _submitForm(context);
                      },
                    ),
                  ],
                ),
              ),
            ),
    );
  }
}
