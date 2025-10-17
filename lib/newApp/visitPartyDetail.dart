import 'dart:async';
import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:flutter/material.dart';
// import 'package:geocoding/geocoding.dart';
import 'package:geolocator/geolocator.dart';
import 'package:intl/intl.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:mittsure/field/routes.dart';
import 'package:mittsure/newApp/MainMenuScreen.dart';
import 'package:mittsure/newApp/bookLoader.dart';
import 'package:mittsure/newApp/endVisitScreen.dart';
import 'package:mittsure/newApp/meetinghappen.dart';
import 'package:mittsure/newApp/routeItems.dart';
import 'package:mittsure/newApp/visitCaptureScreen.dart';
import 'package:mittsure/screens/commonLayout.js.dart';
import 'package:mittsure/screens/newOrder.dart';
import 'package:mittsure/services/apiService.dart';
import 'package:mittsure/services/utils.dart';
import 'package:shared_preferences/shared_preferences.dart';

class RouteDetailsScreen extends StatefulWidget {
  final Map<String, dynamic> data;
  final type;
  final date;
  final visitStatus;
  final userReq;
  final visitId;

  RouteDetailsScreen(
      {Key? key,
      required this.data,
      required this.type,
      required this.date,
      required this.userReq,
      required this.visitStatus,
      this.visitId});

  @override
  State<RouteDetailsScreen> createState() => _RouteDetailsScreenState();
}

class _RouteDetailsScreenState extends State<RouteDetailsScreen> {
  Map<dynamic, dynamic> distributor = {};
  int visitCount = 0;
  var latestVisit = {};
  String selectedOption = 'Party';
  Timer? _otpTimer;
  int _remainingSeconds = 30;
  bool _canResendOtp = false;
  bool skipOtp = true;
  final TextEditingController otherNumberController = TextEditingController();
  final TextEditingController otpController = TextEditingController();
  List<dynamic> visitTypeOptions = [
    {"routeVisitType": "Select Visit Type", "routeVisitTypeID": ""}
  ];
  String? visitType = "";
  DateTime? selectedDate;
  int status = 6;
  String? meetingScreen;

  formatDateTime(String start, String end) {
    final inputFormat = DateFormat('yyyy-MM-dd HH:mm:ss');
    final dateFormat = DateFormat('MMMM d, yyyy'); // e.g., June 3, 2025
    final timeFormat = DateFormat('hh:mm a'); // e.g., 07:00 AM

    final startDateTime = inputFormat.parse(start);
    final endDateTime = inputFormat.parse(end);

    final date = dateFormat.format(startDateTime);
    final startTime = timeFormat.format(startDateTime);
    final endTime = timeFormat.format(endDateTime);

    return "$date ($startTime-$endTime)";
  }

  fetchlastVisit() async {
    setState(() {
      isLoading = true;
    });
    final body = {"partyId": widget.data['partyId']};

    try {
      final response = await ApiService.post(
        endpoint: '/visit/fetchCurrentVisit', // Use your API endpoint
        body: body,
      );

      if (response != null && response['status'] == false) {
        print(response);
        print("ssssss");
        setState(() {
          visitCount = response['data']['totalCount'];
          latestVisit = response['data']['latestVisit'];
          print(latestVisit);
        });
      } else {}
    } catch (error) {
      print("Error fething orders: $error");
    } finally {
      setState(() {
        isLoading = false;
      });
    }
  }

  fetchdecisionmaker() async {
    setState(() {
      isLoading = true;
    });
    final body = {"visitId": widget.data['visitId']??widget.visitId};

    try {
      final response = await ApiService.post(
        endpoint: '/visit/getDecisionMaker', // Use your API endpoint
        body: body,
      );

      if (response != null && response['success'] == true) {
        print(response);
        print("ssssss");
        setState(() {
         meetingScreen=response['rows']['meeting_with_decision_maker'];
        });
      } else {}
    } catch (error) {
      print("Error fething orders: $error");
    } finally {
      setState(() {
        isLoading = false;
      });
    }
  }

  fetchPicklist() async {
    print(widget.data);
    final body = {};

    try {
      final response = await ApiService.post(
        endpoint: '/picklist/getRouteVisitType', // Use your API endpoint
        body: body,
      );

      if (response != null && response['status'] == false) {
        setState(() {
          visitTypeOptions.addAll(response['data']);

          if (widget.visitStatus != null) {
            status = widget.visitStatus;
          } else {
            status = widget.data['visited_status'];
          }
        });
      } else {
        throw Exception('Failed to get picklist');
      }
    } catch (error) {
      print("Error fetcffng orders: $error");
    }
  }

  Future<void> fetchAndConfirmAddressFromGoogle({
  required BuildContext context
}) async {

  final serviceEnabled = await Geolocator.isLocationServiceEnabled();
    if (!serviceEnabled) {
      DialogUtils.showCommonPopup(context: context,message: 'Location services are disabled.',isSuccess: false);
      return;
    }

    var permission = await Geolocator.checkPermission();
    if (permission == LocationPermission.denied) {
      permission = await Geolocator.requestPermission();
    }

    if (permission == LocationPermission.deniedForever ||
        permission == LocationPermission.denied) {
      DialogUtils.showCommonPopup(
        context: context,
        message: 'Location permissions are denied.',
        isSuccess: false,
      );
      return;
    }
    setState(() {
    isLoading=true;
  });

    final position = await Geolocator.getCurrentPosition(
      desiredAccuracy: LocationAccuracy.high,
    );
final googleApiKey= dotenv.env['GOOGLE_MAPS_API_KEY'];
print(googleApiKey);
  // 🧭 Step 1: Reverse Geocode using Google Maps API
  final url = Uri.parse(
    'https://maps.googleapis.com/maps/api/geocode/json?latlng=${position.latitude},${position.longitude}&key=$googleApiKey',
  );

  final response = await http.get(url);

  if (response.statusCode != 200) {
    DialogUtils.showCommonPopup(
      context: context,
      message: 'Unable to connect to Google Maps. Try again.',
      isSuccess: false,
    );
    return;
  }

  final data = json.decode(response.body);
  setState(() {
    isLoading=false;
  });

  if (data['status'] != 'OK' || data['results'].isEmpty) {
    DialogUtils.showCommonPopup(
      context: context,
      message: 'Unable to fetch address. Try again.',
      isSuccess: false,
    );
    return;
  }

  final address = data['results'][0]['formatted_address'];
  print('📍 Address from Google API: $address');

  // ✅ Step 2: Show confirmation dialog
  bool? confirm = await showDialog<bool>(
    context: context,
    builder: (_) => AlertDialog(
      title: Text("Confirm Address"),
      content: Text("Do you want to tag this location?\n\n$address"),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context, false),
          child: Text("Cancel"),
        ),
        ElevatedButton(
          onPressed: () => Navigator.pop(context, true),
          child: Text("Yes, Tag"),
        ),
      ],
    ),
  );

  if (confirm != true) {
    return;
  }

 tagLocation(position.latitude,position.longitude);
}

  tagLocation(lat,long) async {
    print(":plplpl");
    try {
      setState(() {
        isLoading = true;
      });



      final body = {
        "lat": lat.toString(),
        "long": long.toString(),
        "type": widget.type.toString(),
        "id": widget.data['addressId'],
        "data": jsonEncode({
          "party": widget.data['partyId'],
          "lat": lat.toString(),
          "long": long.toString(),
        })
      };

      final response = await ApiService.post(
        endpoint: '/party/markLocation',
        body: body,
      );

      print(response);

      if (response != null && response['success'] == true) {
        setState(() {
          widget.data['lat'] = lat;
          widget.data['long'] = long;
          DialogUtils.showCommonPopup(
              context: context, message: "Location Marked", isSuccess: true);
          isLoading = false;
        });
      } else {
        DialogUtils.showCommonPopup(
            context: context, message: response['message'], isSuccess: false);
        setState(() {
          isLoading = false;
        });
      }
    } catch (error) {
      DialogUtils.showCommonPopup(
          context: context, message: "Something Went Wrong", isSuccess: false);
      setState(() {
        isLoading = false;
      });
    }
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

  Future<void> _pickDate(change) async {
    final now = DateTime.now();
    final DateTime? picked = await showDatePicker(
      context: context,
      initialDate: now.add(const Duration(days: 0)),
      firstDate: now.add(const Duration(days: 0)),
      lastDate: now.add(const Duration(days: 7)),
    );
    if (picked != null) {
      change(() {
        selectedDate = picked;
      });
    }
  }

  Future<void> showFormDialog({
    required BuildContext context,
    required void Function() onSubmit,
  }) async {
    await showDialog(
      context: context,
      builder: (BuildContext dialogContext) {
        return StatefulBuilder(
          builder: (context, setState) {
            return AlertDialog(
              title: const Text('Update Data'),
              content: SizedBox(
                height: 150,
                child: Padding(
                  padding: const EdgeInsets.all(10),
                  child: Column(
                    children: [
                      _buildDropdown(
                          'Visit Type',
                          visitTypeOptions,
                          "routeVisitTypeID",
                          'routeVisitType',
                          visitType,
                          (val) => setState(() {
                                visitType = val;
                              })),
                      const SizedBox(height: 12),
                      TextFormField(
                        readOnly: true,
                        onTap: () {
                          _pickDate(setState);
                        },
                        decoration: InputDecoration(
                          hintText: selectedDate == null
                              ? 'Choose date'
                              : "${selectedDate!.day}-${selectedDate!.month}-${selectedDate!.year}",
                          labelText: selectedDate == null
                              ? 'Choose date'
                              : "${selectedDate!.day}-${selectedDate!.month}-${selectedDate!.year}",
                          suffixIcon: const Icon(Icons.calendar_today),
                          border: const OutlineInputBorder(),
                          contentPadding: const EdgeInsets.symmetric(
                              horizontal: 12, vertical: 14),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
              actions: <Widget>[
                TextButton(
                  child: const Text('Cancel'),
                  onPressed: () => Navigator.of(dialogContext).pop(),
                ),
                ElevatedButton(
                  child: const Text('Submit'),
                  onPressed: () {
                    Navigator.of(dialogContext).pop();
                    onSubmit();
                  },
                ),
              ],
            );
          },
        );
      },
    );
  }

  Future<void> showDeleteConfirmationDialog({
    required BuildContext context,
    required VoidCallback onConfirm,
  }) async {
    return showDialog(
      context: context,
      builder: (BuildContext dialogContext) {
        return AlertDialog(
          title: const Text(
            'Confirm Remove',
            style: TextStyle(color: Colors.black),
          ),
          content: const Text(
            'Are you sure you want to remove this from route plan? This action cannot be undone.',
          ),
          actions: <Widget>[
            TextButton(
              child: const Text('Cancel'),
              onPressed: () {
                Navigator.of(dialogContext).pop(); // Close dialog
              },
            ),
            ElevatedButton(
              style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
              child: const Text(
                'Confirm',
                style: TextStyle(color: Colors.white),
              ),
              onPressed: () {
                Navigator.of(dialogContext).pop(); // Close dialog
                onConfirm(); // Trigger the deletion
              },
            ),
          ],
        );
      },
    );
  }

  var userData = {};
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
    // TODO: implement initState
    super.initState();
    fetchdecisionmaker();
    fetchPicklist();
    fetchlastVisit();
    getUserData();

    distributor = widget.data;
  }

  bool isLoading = false;

  void deleteRoutes() async {
    setState(() {
      isLoading = true;
    });

    final body = {
      "routeLineItemId": widget.data['route_line_items_id'],
    };

    try {
      final response = await ApiService.post(
        endpoint: '/routePlan/deleteOfRoutParty',
        body: body,
      );

      if (response != null && response['success'] == true) {
        Navigator.push(
            context,
            MaterialPageRoute(
                builder: (context) => CreatedRoutesPage(userReq: false)));
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

  void _approveRequest() async {
    setState(() {
      isLoading = true;
    });
    try {
      final response = await ApiService.post(
        endpoint: '/routeplan/approvePartialRouteNotification',
        body: {
          "isDirectApproval": false,
          "approvalStatus": "1",
          "route_line_items_id": widget.data['route_line_items_id'],
          "id": widget.data['routeId']
        },
      );
      setState(() {
        isLoading = false;
      });
      if (response != null && response['status'] == false) {
        DialogUtils.showCommonPopup(
            context: context, message: "Approved Sucessfully", isSuccess: true,onOkPressed: (){
              Navigator.pushReplacement(
          context,
          MaterialPageRoute(
            builder: (context) => ItemListPage(
              date: widget.date,
              id: widget.data['routeId'],
              userReq: widget.userReq,
            
            ),
          ),
        );
            });
      }
       
      
    } catch (e) {
      print(e);
      DialogUtils.showCommonPopup(
          context: context, message: "Something Went Wrong", isSuccess: false);
    } finally {
      setState(() {
        isLoading = false;
      });
    }
  }

  Future<void> _sendOtp(cont) async {
    final prefs = await SharedPreferences.getInstance();
    final t = await prefs.getString('user');
    var id = t != null ? jsonDecode(t)['id'] : "";

    var body = {
      "mobile": selectedOption == 'Other'
          ? otherNumberController.text
          : widget.data['makerContact'],
      "token": id
    };

    try {
      final response =
          await ApiService.post(endpoint: '/user/sendOtp', body: body);
      if (response != null && response['status'] == false) {
        setState(() => isLoading = false);
        _startOtpTimer();
        _showOtpDialog(context);
      } else {
        _showPopup(response["message"], false, context);
      }
    } catch (error) {
      _showPopup("Failed to send Verification Code. Please try later.", false, context);
      Navigator.pushAndRemoveUntil(
        context,
        MaterialPageRoute(builder: (_) => MainMenuScreen()),
        (_) => false,
      );
    }
  }

  void _showPopup(String message, bool success, cont) {
    DialogUtils.showCommonPopup(
        context: cont, message: message, isSuccess: success);
  }

  void _startOtpTimer() {
    setState(() {
      _remainingSeconds = 30;
      _canResendOtp = false;
    });

    _otpTimer?.cancel();
    _otpTimer = Timer.periodic(Duration(seconds: 1), (timer) {
      if (_remainingSeconds > 0) {
        setState(() => _remainingSeconds--);
      } else {
        setState(() => _canResendOtp = true);
        _otpTimer?.cancel();
      }
    });
  }

  void _showOtpDialog(BuildContext cont) {
    late StateSetter dialogSetState;
    int remainingSeconds = 120;
    bool canResendOtp = false;
    Timer? timer;

    void startTimer() {
      timer = Timer.periodic(Duration(seconds: 1), (t) {
        if (remainingSeconds > 1) {
          remainingSeconds--;
          dialogSetState(() {});
        } else {
          t.cancel();
          canResendOtp = true;
          dialogSetState(() {});
        }
      });
    }

    showDialog(
      context: cont,
      barrierDismissible: false,
      builder: (_) {
        return StatefulBuilder(
          builder: (context, setState) {
            dialogSetState = setState;
            if (timer == null) startTimer();

            return AlertDialog(
              title: Text("Enter verification Code"),
              content: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  TextField(
                    controller: otpController,
                    keyboardType: TextInputType.number,
                    maxLength: 6,
                    decoration: InputDecoration(hintText: "Enter 6-digit code"),
                  ),
                  SizedBox(height: 8),
                  canResendOtp
                      ? TextButton(
                          onPressed: () {
                            timer?.cancel();
                            Navigator.pop(context);
                            _sendOtp(cont);
                          },
                          child: Text("Resend Verification Code"),
                        )
                      : Text("Resend in $remainingSeconds seconds"),
                ],
              ),
              actions: [
                ElevatedButton(
                  onPressed: () {
                    setState((){
                      skipOtp=false;
                    });
                    startMeeting("end");
                  },
                  child: Text("Skip"),
                ),
                ElevatedButton(
                  onPressed: () {
                    if (otpController.text.length == 6) {
                      timer?.cancel();
                      Navigator.pop(context);
                      _submitOtp(cont);
                    } else {
                      _showSnackbar("Please enter a valid 6-digit Verification Code", cont);
                    }
                  },
                  child: Text("Submit"),
                ),
              ],
            );
          },
        );
      },
    );
  }

  void _showSnackbar(String msg, cont) {
    ScaffoldMessenger.of(cont).showSnackBar(SnackBar(content: Text(msg)));
  }

  Future<void> _submitOtp(cont) async {
    
    var body = {
      "mobile": selectedOption == 'Other'
          ? otherNumberController.text
          : widget.data['phone'],
      "otp": otpController.text,
      "visitId": widget.data['visitId'] ?? widget.visitId,
    };

    try {
     
      final response = await ApiService.post(
        endpoint: '/visit/verifyOtpForVisit',
        body: body,
      );

      if (response != null && response['status'] == false) {
        startMeeting("end");
      } else {
        _showPopup("Incorrect Verification Code. Please try again.", false, context);
        setState(() => isLoading = false);
      }
    } catch (_) {
      _showPopup("Failed to verify Verification Code. Please try again.", false, context);
      setState(() => isLoading = false);
    } finally {
      setState(() => isLoading = false);
    }
  }

  void _rejectRequestWithRemark() {
    final TextEditingController remarkController = TextEditingController();

    showDialog(
      context: context,
      builder: (_) => AlertDialog(
        title: Text("Enter Rejection Remark"),
        content: TextField(
          controller: remarkController,
          maxLines: 3,
          decoration: InputDecoration(
            hintText: "Type remark here...",
            border: OutlineInputBorder(),
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text("Cancel"),
          ),
          ElevatedButton(
            onPressed: () async {
              final remark = remarkController.text.trim();
              if (remark.isEmpty) return;

              // Close the dialog first
              Navigator.pop(context);

              setState(() {
                isLoading = true;
              });

              try {
                final response = await ApiService.post(
                  endpoint: '/routeplan/approvePartialRouteNotification',
                  body: {
                    "isDirectApproval": false,
                    "approvalStatus": "2",
                    "reason": remark,
                    "route_line_items_id": widget.data['route_line_items_id'],
                    "id": widget.data['routeId']
                  },
                );
                setState(() {
                  isLoading = false;
                });
                if (response != null && response['status'] == false) {
                  DialogUtils.showCommonPopup(
                      context: context, message: "Rejected ", isSuccess: true,onOkPressed: (){
                        Navigator.pushReplacement(
          context,
          MaterialPageRoute(
            builder: (context) => ItemListPage(
              date: widget.date,
              id: widget.data['routeId'],
              userReq: widget.userReq,
              
            ),
          ),
        );
                      });
                }
              } catch (e) {
                print(e);
                DialogUtils.showCommonPopup(
                    context: context,
                    message: "Something Went Wrong",
                    isSuccess: false);
              } finally {
                setState(() {
                  isLoading = false;
                });
              }
            },
            child: Text("Submit"),
          ),
        ],
      ),
    );
  }

  Future<void> startMeeting(String filter) async {
    final prefs = await SharedPreferences.getInstance();
    final hasData = prefs.getString('user') != null;
    var id = "";
    if (hasData) {
      id = jsonDecode(prefs.getString('user') ?? "")['id'];
    } else {
      return;
    }

    final body = {
      "id": widget.data['visitId'] ?? widget.visitId, // visit id
      "ownerId": id,
      'otp_skip': !skipOtp ? 'Yes' : 'No',
      'otpMode': selectedOption,
      'otp_number': !skipOtp
          ? ""
          : selectedOption == 'Other'
              ? otherNumberController.text
              : widget.data['makerContact']
    };


    try {
    setState(() {
      isLoading = true;
    });
      final response = await ApiService.post(
        endpoint: filter == "end"
            ? '/visit/endMeetingVisit'
            : '/visit/startMeetingVisit',
        body: body,
      );
      if (response != null && response['status'] == false) {
        setState(() {
          isLoading = false;
          status = filter == 'end' ? 3 : 2;
        });
        DialogUtils.showCommonPopup(
            context: context,
            message: filter == 'end' ? "Meeting Ended" : "Meeting Started",
            isSuccess: true);
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(response['message'])),
        );
      }
    } catch (error) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(error.toString())),
      );
    }
  }

  void _submitRoutes() async {
    setState(() {
      isLoading = true;
    });
    final prefs = await SharedPreferences.getInstance();
    final hasData = prefs.getString('user') != null;
    var id = "";
    if (hasData) {
      id = jsonDecode(prefs.getString('user') ?? "")['id'];
    } else {
      return;
    }

    final body = {
      "owner_id": id,
      "date": selectedDate.toString().substring(0, 11),
      "routeLineItemId": widget.data['route_line_items_id'],
      "visitType": visitType
    };

    try {
      final response = await ApiService.post(
        endpoint: '/routePlan/updateDateOfRoutParty',
        body: body,
      );

      if (response != null && response['success'] == true) {
        Navigator.push(
            context,
            MaterialPageRoute(
                builder: (context) => CreatedRoutesPage(userReq: false)));
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

  getFVR(obj, key) {
    if (obj == null || obj == "") {
      return null;
    } else {
      final a = jsonDecode(obj);
      return a[key].toString();
    }
  }

  bool isToday(String dateString) {
    final date = DateTime.parse(dateString); // Make sure format is 'yyyy-MM-dd'
    final now = DateTime.now();
    return date.year == now.year &&
        date.month == now.month &&
        date.day == now.day;
  }

  void _showOtpBottomSheet(cont) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
      ),
      builder: (context) {
        return StatefulBuilder(
          builder: (context, setModalState) {
            return Padding(
              padding: EdgeInsets.only(
                bottom: MediaQuery.of(context).viewInsets.bottom,
                top: 16,
                left: 16,
                right: 16,
              ),
              child: SingleChildScrollView(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    CheckboxListTile(
                      title: const Text("Verify Visit with Verification Code"),
                      value: skipOtp,
                      onChanged: (value) =>
                          setModalState(() => skipOtp = value!),
                    ),
                    if (skipOtp) ...[
                      const SizedBox(height: 10),
                      const Text(
                        "Message Send To",
                        style: TextStyle(
                            fontWeight: FontWeight.bold, fontSize: 16),
                      ),
                      ListTile(
                        title: const Text('Registered Mobile Number'),
                        leading: Radio(
                          value: 'Party',
                          groupValue: selectedOption,
                          onChanged: (value) => setModalState(
                              () => selectedOption = value.toString()),
                        ),
                      ),
                      ListTile(
                        title: const Text('Other'),
                        leading: Radio(
                          value: 'Other',
                          groupValue: selectedOption,
                          onChanged: (value) => setModalState(
                              () => selectedOption = value.toString()),
                        ),
                      ),
                      if (selectedOption == 'Other')
                        TextField(
                          controller: otherNumberController,
                          keyboardType: TextInputType.phone,
                          decoration: const InputDecoration(
                            labelText: "Enter phone number",
                            border: OutlineInputBorder(),
                          ),
                        ),
                    ],
                    const SizedBox(height: 20),
                    Row(children: [
                      SizedBox(width: 150,
                        child: ElevatedButton(
                          
                          style: ButtonStyle(backgroundColor: MaterialStateProperty.all(Colors.green)),
                        
                          onPressed: () {
                            if(skipOtp){
                            Navigator.pop(context);
                            _sendOtp(cont);
                            
                            }else{
                              Navigator.pop(context);
                              startMeeting("end");
                            }
                          },
                          child:  Row(
                            mainAxisAlignment: MainAxisAlignment.spaceAround,
                            children: [
                              Padding(
                                padding: const EdgeInsets.all(8.0),
                                child: Icon(Icons.arrow_circle_right,color: Colors.white,),
                              ),
                              Padding(
                                padding: const EdgeInsets.all(8.0),
                                child: Text("Proceed",style: TextStyle(color: Colors.white)),
                              ),
                            ],
                          ),
                        ),
                      ),
                     
                    ]),
                  ],
                ),
              ),
            );
          },
        );
      },
    );
  }

  void showEndPopup(BuildContext context) {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: Text("Are you sure to end the meeting?"),
          actions: [
            TextButton(
              onPressed: () {
                Navigator.of(context).pop();
                _showOtpBottomSheet(context);
              },
              child: Text('Yes'),
            ),
            TextButton(
              onPressed: () {
                Navigator.of(context).pop(); // Close the dialog
              },
              child: Text('No'),
            ),
          ],
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return WillPopScope(
      onWillPop: () async {
        Navigator.pushReplacement(
          context,
          MaterialPageRoute(
            builder: (context) => ItemListPage(
              date: widget.date,
              id: widget.data['routeId'],
              userReq: widget.userReq,
             
            ),
          ),
        );
        return false; // Prevent default back navigation
      },
      child: Scaffold(
        appBar: AppBar(
          backgroundColor: Colors.indigo[900],
          iconTheme: IconThemeData(color: Colors.white),
          title: Text(
            widget.type == 1
                ? distributor['schoolName']
                : distributor['DistributorName'],
            style: TextStyle(color: Colors.white, fontSize: 20),
          ),
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
        body: isLoading
            ? Center(
                child: BookPageLoader(),
              )
            : meetingScreen==null&&status==1?MeetingHappen(visitId:widget.visitId??widget.data['visitId'],
                            visitStatus:widget.visitStatus,
                            userReq:widget.userReq,
                            date:widget.date,
                            type:widget.type,
                            data:widget.data) :ListView(
                padding: const EdgeInsets.all(16.0),
                children: [
                  Container(
                    color: Colors.indigo[50],
                    child: Padding(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 15, vertical: 10),
                      child: Column(
                        children: [
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              Text(
                                "No. of Visits:  ",
                                style: TextStyle(fontWeight: FontWeight.bold),
                              ),
                              Text(
                                "${visitCount.toString()}",
                                style: TextStyle(fontWeight: FontWeight.bold),
                              )
                            ],
                          ),
                          visitCount > 0
                              ? Row(
                                  mainAxisAlignment:
                                      MainAxisAlignment.spaceBetween,
                                  children: [
                                    Text(
                                      "Last Visit :  ",
                                      style: TextStyle(
                                          fontWeight: FontWeight.bold),
                                    ),
                                    Text(
                                      "${formatDateTime(latestVisit['startTime'], latestVisit['endTime'])}",
                                      style: TextStyle(
                                          fontWeight: FontWeight.bold),
                                    )
                                  ],
                                )
                              : Container(),
                        ],
                      ),
                    ),
                  ),
                  // Distributor Details Section
                  SectionTitle(
                      title: widget.type == 1
                          ? 'School Details'
                          : 'Distributor Details'),
                  DetailsRow(
                      label: 'Name',
                      value: widget.type == 1
                          ? distributor['schoolName']
                          : distributor['DistributorName'] ?? 'N/A'),

//  DetailsRow(
//                       label: 'ID',
//                       value: widget.type == 1
//                           ? distributor['schoolId']
//                           : distributor['distributorID'] ?? 'N/A'),

 DetailsRow(
                      label: 'Address', value: distributor['AddressLine1'] ?? 'N/A'),
                       DetailsRow(
                      label: 'Board', value: distributor['boardName'] ?? 'N/A'),

                       DetailsRow(
                      label: 'Medium', value: distributor['mediumName'] ?? 'N/A'),

                  DetailsRow(
                      label: 'Pincode', value: distributor['Pincode'] ?? 'N/A'),

                  const Divider(),

                  const SectionTitle(title: 'Contact Person Details'),
                  DetailsRow(
                      label: 'Name', value: distributor['makerName'] ?? 'N/A'),
                  DetailsRow(
                      label: 'Role', value: distributor['decisionMakerRole'] ?? 'N/A'),
                  DetailsRow(
                      label: 'Contact Number',
                      value: distributor['makerContact'] ?? 'N/A'),
                  DetailsRow(
                      label: 'Email', value: distributor['email'] ?? 'N/A'),
                  const Divider(),

                  const SectionTitle(title: 'Last Visit Details'),
                  DetailsRow(
                      label: 'HO Action Needed',
                      value: latestVisit['ho_need'] == 'true'
                          ? 'Yes'
                          : 'No' ?? 'N/A'),
                  DetailsRow(
                      label: 'HO Remark',
                      value: latestVisit['ho_need_remark'] ?? 'N/A'),
                  DetailsRow(
                      label: 'Further Visit Required',
                      value: getFVR(latestVisit['furtherVisitRequired'],
                              'visit_required') ??
                          'N/A'),
                  DetailsRow(
                      label: 'Reason',
                      value: getFVR(
                              latestVisit['furtherVisitRequired'], "reason") ??
                          'N/A'),
                  const Divider(),

                  DetailsRow(
                      label: 'Assigned RM',
                      value: distributor['ownerName'] ?? 'N/A'),
                  if(distributor['extra_detail'] != null)
                  const SectionTitle(title: 'Extra Details'),
                  if(distributor['extra_detail'] != null)
                  ...(distributor['extra_detail'] as Map<String, dynamic>).entries.map((entry) {
                    // Capitalize and format the key for display as label
                    String label = entry.key.replaceAll('_', ' ').split(' ').map((word) {
                      return word[0].toUpperCase() + word.substring(1);
                    }).join(' ');

                    String value = entry.value?.toString() ?? 'N/A';

                    return DetailsRow(label: label, value: value);
                  }).toList(),
                  // Additional Information Section
                  //           const SectionTitle(title: 'Additional Information'),
                  //           DetailsRow(label: 'PAN Number', value: distributor['panNumber'] ?? 'N/A'),
                  //           DetailsRow(label: 'Transporter Name', value: distributor['transporter_name'] ?? 'N/A'),
                  //           DetailsRow(label: 'KYC Received', value: distributor['kycRecieved'] == 1 ? 'Yes' : 'No'),
                  // SizedBox(height:10,),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceAround,
                    children: [
                      status == 0
                          ? ElevatedButton.icon(
                              icon: Icon(
                                Icons.edit,
                                color: Colors.white,
                              ),
                              style: ElevatedButton.styleFrom(
                                fixedSize: Size(150, 50),
                                backgroundColor: Colors.indigo[900],
                              ),
                              onPressed: () {
                                showFormDialog(
                                  context: context,
                                  onSubmit: () {
                                    _submitRoutes();
                                  },
                                );
                              },
                              label: Text(
                                "Edit",
                                style: TextStyle(color: Colors.white),
                              ),
                            )
                          : Container(),
                      status == 0
                          ? ElevatedButton.icon(
                              icon: Icon(
                                Icons.delete_forever,
                                color: Colors.white,
                              ),
                              style: ElevatedButton.styleFrom(
                                fixedSize: Size(150, 50),
                                backgroundColor: Colors.red,
                              ),
                              onPressed: () {
                                showDeleteConfirmationDialog(
                                  context: context,
                                  onConfirm: () {
                                    deleteRoutes();
                                  },
                                );
                              },
                              label: Text(
                                "Delete",
                                style: TextStyle(color: Colors.white),
                              ),
                            )
                          : Container(),
                    ],
                  ),
                  SizedBox(
                    height: 6,
                  ),
                  userData['role'] != 'se'
                      ? Row(
                          mainAxisAlignment: MainAxisAlignment.spaceAround,
                          children: [
                            widget.data['status'] == 0 && userData['role'] != 'se'
                                ? ElevatedButton.icon(
                                    icon: Icon(
                                      Icons.check,
                                      color: Colors.white,
                                    ),
                                    style: ElevatedButton.styleFrom(
                                      fixedSize: Size(150, 50),
                                      backgroundColor: Colors.green[900],
                                    ),
                                    onPressed: () {
                                      _approveRequest();
                                    },
                                    label: Text(
                                      "Approve",
                                      style: TextStyle(color: Colors.white),
                                    ),
                                  )
                                : Container(),
                            widget.data['status'] == 0 && userData['role'] != 'se'
                                ? ElevatedButton.icon(
                                    icon: Icon(
                                      Icons.close,
                                      color: Colors.white,
                                    ),
                                    style: ElevatedButton.styleFrom(
                                      fixedSize: Size(150, 50),
                                      backgroundColor: Colors.orange.shade600,
                                    ),
                                    onPressed: () {
                                      _rejectRequestWithRemark();
                                    },
                                    label: Text(
                                      "Reject",
                                      style: TextStyle(color: Colors.white),
                                    ),
                                  )
                                : Container(),
                          ],
                        )
                      : Container(),
                  SizedBox(
                    height: 6,
                  ),
                  (userData['role'] == 'se'||userData['role']=='asm') &&
                          status == 0 &&
                          widget.data['status'] == 1 &&
                          isToday(widget.date) &&
                          widget.data['lat'] == null &&
                          widget.data['long'] == null
                      ? ElevatedButton.icon(
                          icon: Icon(
                            Icons.map,
                            color: Colors.white,
                          ),
                          style: ElevatedButton.styleFrom(
                            minimumSize: Size(10, 50),
                            backgroundColor: Colors.orange.shade400,
                          ),
                          onPressed: () {
                            // tagLocation();
                            fetchAndConfirmAddressFromGoogle(context: context);
                          },
                          label: Text(
                            "Tag Location",
                            style: TextStyle(color: Colors.white),
                          ),
                        )
                      : Container(),
                  SizedBox(
                    height: 10,
                  ),
                  (userData['role'] == 'se'||userData['role']=='asm') &&
                          status == 0 &&
                          widget.data['ownerId']==userData['id']&&
                          widget.data['status'] == 1 &&
                          isToday(widget.date) &&
                          widget.data['lat'] != null &&
                          widget.data['long'] != null
                      ? ElevatedButton.icon(
                          icon: Icon(
                            Icons.start_outlined,
                            color: Colors.white,
                          ),
                          style: ElevatedButton.styleFrom(
                            minimumSize: Size(10, 50),
                            backgroundColor: Colors.green,
                          ),
                          onPressed: () {
                            Navigator.push(
                              context,
                              MaterialPageRoute(
                                builder: (context) => VisitCaptureScreen(
                                  visit: widget.data,
                                  date: widget.data,
                                  type: widget.type,
                                ),
                              ),
                            );
                          },
                          label: Text(
                            "Start Visit",
                            style: TextStyle(color: Colors.white),
                          ),
                        )
                      : Container(),
                  (userData['role'] == 'se'||userData['role']=='asm') && status == 1
                      ? ElevatedButton.icon(
                          icon: Icon(
                            Icons.start_outlined,
                            color: Colors.white,
                          ),
                          style: ElevatedButton.styleFrom(
                            minimumSize: Size(10, 50),
                            backgroundColor: Colors.green,
                          ),
                          onPressed: () {
                            startMeeting("start");
                          },
                          label: Text(
                            "Start Meeting",
                            style: TextStyle(color: Colors.white),
                          ),
                        )
                      : Container(),
                  (userData['role'] == 'se'||userData['role']=='asm') && status == 2
                      ? ElevatedButton.icon(
                          icon: Icon(
                            Icons.start_outlined,
                            color: Colors.white,
                          ),
                          style: ElevatedButton.styleFrom(
                            minimumSize: Size(10, 50),
                            backgroundColor: Colors.green,
                          ),
                          onPressed: () {
                            showEndPopup(context);
                          },
                          label: Text(
                            "End Meeting",
                            style: TextStyle(color: Colors.white),
                          ),
                        )
                      : Container(),
                  (userData['role'] == 'se'||userData['role']=='asm') && status == 3
                      ? ElevatedButton.icon(
                          icon: Icon(
                            Icons.start_outlined,
                            color: Colors.white,
                          ),
                          style: ElevatedButton.styleFrom(
                            minimumSize: Size(10, 50),
                            backgroundColor: Colors.green,
                          ),
                          onPressed: () {
                            Navigator.push(
                              context,
                              MaterialPageRoute(
                                builder: (context) => EndVisitScreen(
                                    visit: widget.data,
                                    date: widget.date,
                                    type: widget.type,
                                    meetingHappen:meetingScreen??"",
                                    visitId: widget.visitId),
                              ),
                            );
                          },
                          label: Text(
                            "End Visit",
                            style: TextStyle(color: Colors.white),
                          ),
                        )
                      : Container()
                ],
              ),
      ),
    );
  }
}

// Section Title Widget
class SectionTitle extends StatelessWidget {
  final String title;

  const SectionTitle({Key? key, required this.title}) : super(key: key);

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

// Details Row Widget
class DetailsRow extends StatelessWidget {
  final String label;
  final String value;

  const DetailsRow({Key? key, required this.label, required this.value})
      : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4.0),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(
            label,
            style: const TextStyle(fontSize: 14, color: Colors.black54),
          ),
          Expanded(
            child: Text(
              value,
              textAlign: TextAlign.end,
              style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w500),

            ),
          ),
        ],
      ),
    );
  }
}
