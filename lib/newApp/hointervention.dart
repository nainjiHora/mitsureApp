import 'dart:async';
import 'dart:convert';
import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter_typeahead/flutter_typeahead.dart';
import 'package:http/http.dart' as http;
import 'package:image_picker/image_picker.dart';
import 'package:path/path.dart';
import 'package:mittsure/newApp/MainMenuScreen.dart';
import 'package:mittsure/services/apiService.dart';
import 'package:mittsure/services/utils.dart';
import 'package:shared_preferences/shared_preferences.dart';

class HoInterventionScreen extends StatefulWidget {
  final dynamic payload;
  final dynamic answers;
  final interested;
  final meetingHappen;
  final visit;

  HoInterventionScreen(
      {required this.payload,
      this.answers,
      required this.interested,
       required this.meetingHappen,
      required this.visit});

  @override
  _HoInterventionScreenState createState() => _HoInterventionScreenState();
}

class _HoInterventionScreenState extends State<HoInterventionScreen> {
  bool hoInterventionNeeded = false;
  bool followUpRequired = false;
  bool mittsureAccountNeeded = false;
  final _formKey = GlobalKey<FormState>();

  // Controllers
  final TextEditingController schoolName = TextEditingController();
  final TextEditingController parentSchoolName = TextEditingController();
  final TextEditingController addressLine1 = TextEditingController();
  final TextEditingController addressLine2 = TextEditingController();
  final TextEditingController district = TextEditingController();
  final TextEditingController state = TextEditingController();
  final TextEditingController pincode = TextEditingController();
  final TextEditingController landmark = TextEditingController();
  final TextEditingController strength = TextEditingController();
  final TextEditingController email = TextEditingController();
  final TextEditingController website = TextEditingController();
  final TextEditingController makerName = TextEditingController();

  final TextEditingController makerContact = TextEditingController();
  List<dynamic> schoolTypeList = [];
  List<dynamic> categoryList = [];
  List<dynamic> mediumList = [];
  List<dynamic> gradeList = [];
  List<dynamic> customerTypeList = [];
  List<dynamic> boardList = [];
  List<dynamic> roles = [];

  bool skipOtp = true;

  final _schoolformKey = GlobalKey<FormState>();
  String? selectedCategory = null;
  String? selectedMedium = null;
  String? selectedGrade = null;
  String? selectedCustomerType = null;
  String? selectedBoard = null;
  String? selectedRole = null;

  final TextEditingController remarkController = TextEditingController();
  final TextEditingController followUpRemark = TextEditingController();
  final TextEditingController visitEndRemark = TextEditingController();
  final TextEditingController otherNumberController = TextEditingController();
  final TextEditingController otpController = TextEditingController();

  final TextEditingController schoolNameController = TextEditingController();
  final TextEditingController contactPersonController = TextEditingController();
  final TextEditingController accountMobileController = TextEditingController();
  final TextEditingController accountEmailController = TextEditingController();
  final TextEditingController prefDistributor = TextEditingController();
  final TextEditingController accountRemarksController =
      TextEditingController();

  DateTime? followUpDate;
  Timer? _otpTimer;
  int _remainingSeconds = 30;
  bool _canResendOtp = false;
  bool partyUpdateRequired = false;
  String selectedOption = 'Party';
  dynamic selectedValue;
  File? capturedImage;
  bool isLoading = false;
  List<dynamic> distributors = [];

  bool isValidIndianMobile(String mobile) {
    return RegExp(r'^[6-9]\d{9}$').hasMatch(mobile);
  }

  bool isValidEmail(String email) {
    return RegExp(r"^[\w-\.]+@([\w-]+\.)+[\w-]{2,4}$").hasMatch(email);
  }

  Future<void> _submitRequest(BuildContext context) async {
    setState(() => isLoading = true);


   
   if (partyUpdateRequired && !_schoolformKey.currentState!.validate()) {
      _showSnackbar("Please enter a Party Update Data", context);
      setState(() => isLoading = false);
      return;
   }


    if (hoInterventionNeeded && remarkController.text.trim().isEmpty) {
      _showSnackbar("Please enter a remark.", context);
      setState(() => isLoading = false);
      return;
    }
    if (visitEndRemark.text.trim().isEmpty) {
      _showSnackbar("Please enter a visit End Remark.", context);
      setState(() => isLoading = false);
      return;
    }

    if (followUpRequired && (followUpDate == null||followUpRemark.text.trim().isEmpty)) {
      _showSnackbar("Please select a follow-up date and enter remark", context);
      setState(() => isLoading = false);
      return;
    }

    if (mittsureAccountNeeded) {
      if (!_formKey.currentState!.validate()) {
        setState(() => isLoading = false);
        return;
      }
    }


    final pcat = {"interested": widget.interested, "data": widget.answers};
    final uri = Uri.parse('https://mittsure.qdegrees.com:3001/visit/endVisit');
    var request = http.MultipartRequest('POST', uri);

    widget.payload.fields.forEach((key, value) {
      request.fields[key] = value;
    });

    var a = distributors
        .where((element) =>
            element['DistributorName'] == prefDistributor.text.trim())
        .toList();

    if (a.length > 0) {
      selectedValue = a[0]['distributorID'];
    }

    request.fields['preferred_distributor'] =
        jsonEncode({"id": selectedValue, "name": prefDistributor.text});

    request.fields['otp_number'] = !skipOtp
        ? ""
        : selectedOption == 'Other'
            ? otherNumberController.text
            : widget.payload.fields['phone'];
    request.fields['ho_need'] = hoInterventionNeeded.toString();
    request.fields['noVisitCount'] = '0';
    request.fields['otpMode'] = selectedOption;
    request.fields['tentativeAmount'] = '0';
    request.fields['decisionMaker'] = widget.meetingHappen;
    request.fields['product_category'] = jsonEncode(pcat);
    request.fields['remark'] = followUpRemark.text;
    request.fields['vistEndRemark']=visitEndRemark.text;



     if (partyUpdateRequired) {
      request.fields['partyUpdate'] = partyUpdateRequired?'true':'false';
       final partyUpdateData = {
        "addressLine1": addressLine1.text,
        "addressLine2": addressLine2.text,
        "board": selectedBoard,
        "email": email.text,
        "grade": [selectedGrade],
        "makerContact": makerContact.text,
        "makerName": makerName.text,
        "makerRole": selectedRole??"",
        "medium": selectedMedium,
        "pincode": pincode.text,
        "schoolName": schoolName.text,
        'distributor':jsonEncode({"id": selectedValue, "name": prefDistributor.text})
      };
       request.fields['partyUpdateData'] = jsonEncode(partyUpdateData);
    }

    if (hoInterventionNeeded) {
      request.fields['ho_need_remark'] = remarkController.text.trim();
    }

    if (followUpRequired && followUpDate != null) {
      request.fields['follow_up_required'] = followUpRequired.toString();
      request.fields['followUpDate'] =
          (followUpDate!.millisecondsSinceEpoch / 1000).toString();
    }

    final accountFormJson = {
      "account_needed": mittsureAccountNeeded,
      "school_name":
          mittsureAccountNeeded ? schoolNameController.text.trim() : "",
      "contact_person":
          mittsureAccountNeeded ? contactPersonController.text.trim() : "",
      "mobile":
          mittsureAccountNeeded ? accountMobileController.text.trim() : "",
      "email": mittsureAccountNeeded ? accountEmailController.text.trim() : "",
      "remarks":
          mittsureAccountNeeded ? accountRemarksController.text.trim() : "",
    };
    request.fields['mittstoreAccountNeeded'] = jsonEncode(accountFormJson);

    request.fields['otp_skip'] = !skipOtp ? 'Yes' : 'No';
    

    try {
      print(request.fields);
      final response = await request.send();
      var respons = await http.Response.fromStream(response);
      final res = jsonDecode(respons.body);

      if (response.statusCode >= 200 &&
          response.statusCode < 300 &&
          res['status'] == false) {

          Navigator.pushAndRemoveUntil(
            context,
            MaterialPageRoute(builder: (_) => MainMenuScreen()),
            (_) => false,
          );

      } else {
        DialogUtils.showCommonPopup(
            context: context, message: res['message'], isSuccess: false);
        setState(() => isLoading = false);
      }
    } catch (e) {
      DialogUtils.showCommonPopup(
          context: context, message: "Something went wrong", isSuccess: false);
      setState(() => isLoading = false);
    }
  }

  Future<void> fetchAllPicklists() async {
    try {
      final responses = await Future.wait([
        ApiService.post(endpoint: '/picklist/getSchoolTypeList', body: {}),
        ApiService.post(endpoint: '/picklist/getSchoolCategory', body: {}),
        ApiService.post(endpoint: '/picklist/getMedium', body: {}),
        ApiService.post(endpoint: '/picklist/getGrade', body: {}),
        ApiService.post(endpoint: '/picklist/getCustomerTypeList', body: {}),
        ApiService.post(endpoint: '/picklist/getBoard', body: {}),
        ApiService.post(endpoint: '/picklist/getContactPersonRole', body: {}),
      ]);

      setState(() {
        schoolTypeList = responses[0]['data'] ?? [];
        categoryList = responses[1]['data'] ?? [];
        mediumList = responses[2]['data'] ?? [];
        gradeList = responses[3]['data'] ?? [];
        customerTypeList = responses[4]['data'] ?? [];
        boardList = responses[5]['data'] ?? [];
        roles = widget.visit['partyType']==1||widget.visit['partyType']=="1"?responses[6]['data']:responses[6]['data2'];
        final a = roles
            .where((element) =>
                element['roleName'] == widget.visit['decisionMakerRole'])
            .toList();

        if (a.length > 0) {
          selectedRole = a[0]['contactPersonRoleId'];
        }
        print(mediumList);

        final b = mediumList
            .where((element) => element['mediumName'] == widget.visit['Medium'])
            .toList();

        if (b.length > 0) {
          selectedMedium = b[0]['mediumTableId'];
        }
        print(boardList);
        final c = boardList
            .where((element) => element['boardName'] == widget.visit['Board'])
            .toList();

        if (c.length > 0) {
          selectedBoard = c[0]['boardId'];
        }
        selectedGrade = widget.visit['Grade'];

        isLoading = false;
      });
    } catch (e) {
      print('Error fetching picklists: $e');
    }
  }

  Future<void> _sendOtp(context) async {
    final prefs = await SharedPreferences.getInstance();
    final t = await prefs.getString('user');
    var id = t != null ? jsonDecode(t)['id'] : "";

    var body = {
      "mobile": selectedOption == 'Other'
          ? otherNumberController.text
          : widget.payload.fields['phone'],
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
        Navigator.pushAndRemoveUntil(
          context,
          MaterialPageRoute(builder: (_) => MainMenuScreen()),
          (_) => false,
        );
      }
    } catch (error) {
      _showPopup("Failed to send OTP. Please try later.", false, context);
      Navigator.pushAndRemoveUntil(
        context,
        MaterialPageRoute(builder: (_) => MainMenuScreen()),
        (_) => false,
      );
    }
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

  void _showSnackbar(String msg, cont) {
    ScaffoldMessenger.of(cont).showSnackBar(SnackBar(content: Text(msg)));
  }

  void _showPopup(String message, bool success, cont) {
    DialogUtils.showCommonPopup(
        context: cont, message: message, isSuccess: success);
  }

  @override
  void initState() {
    // TODO: implement initState
    super.initState();
    print(widget.visit['partyType']);
    print("po");
    fetchAllPicklists();
    contactPersonController.text = widget.visit['makerName'] ?? "";
    accountMobileController.text = widget.visit['makerContact'] ?? "";
    schoolNameController.text =
        widget.visit['schoolName'] ?? widget.visit['DistributorName'] ?? "";

    email.text = widget.visit['email'] ?? "N/A";
    accountEmailController.text = widget.visit['email'] ?? "N/A";
    makerContact.text = widget.visit['makerContact'] ?? "N/A";
    makerName.text = widget.visit['makerName'] ?? "N/A";
    pincode.text = widget.visit['Pincode'] ?? "N/A";
    addressLine2.text = widget.visit['AddressLine2'] ?? "N/A";
    addressLine1.text = widget.visit['AddressLine1'] ?? "N/A";
    schoolName.text = widget.visit['partyType']==1||widget.visit['partyType']=="1"?widget.visit['schoolName']:widget.visit['DistributorName'] ?? "N/A";

    getUserData();
  }

  var userData = {};

  getUserData() async {
    final prefs = await SharedPreferences.getInstance();
    final a = prefs.getString('user');
    if (a!.isNotEmpty) {
      setState(() {
        userData = jsonDecode(a ?? "");
      });
      fetchDistributor();
    }
  }

  fetchDistributor() async {
    final body = {"ownerId": userData['id']};

    try {
      final response = await ApiService.post(
        endpoint: '/party/getAllDistri',
        body: body,
      );

      if (response != null) {
        final data = response['data'];
        distributors = data;
      } else {
        throw Exception('Failed to load orders');
      }
    } catch (error) {
      print("Error fetching orders: $error");
    }
  }

  @override
  void dispose() {
    _otpTimer?.cancel();
    remarkController.dispose();
    otherNumberController.dispose();
    otpController.dispose();
    followUpRemark.dispose();
    schoolNameController.dispose();
    contactPersonController.dispose();
    accountMobileController.dispose();
    accountEmailController.dispose();
    accountRemarksController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title:
            const Text('Submit Visit', style: TextStyle(color: Colors.white)),
        backgroundColor: Colors.indigo,
        iconTheme: const IconThemeData(color: Colors.white),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            CheckboxListTile(
              title: Text("HO Actionable Items",
                  style: TextStyle(fontWeight: FontWeight.bold)),
              value: hoInterventionNeeded,
              onChanged: (value) =>
                  setState(() => hoInterventionNeeded = value!),
            ),
            if (hoInterventionNeeded)
              TextField(
                controller: remarkController,
                decoration: InputDecoration(
                    labelText: "Remark For HO", border: OutlineInputBorder()),
                maxLines: 1,
              ),
            SizedBox(height: 12),
            CheckboxListTile(
              title: Text("Follow-up Required"),
              value: followUpRequired,
              onChanged: (value) => setState(() => followUpRequired = value!),
            ),
            if (followUpRequired)
              ListTile(
                title: Text(followUpDate == null
                    ? "Select Follow-up Date"
                    : "Follow-up: ${followUpDate!.day}-${followUpDate!.month}-${followUpDate!.year}"),
                trailing: Icon(Icons.calendar_today),
                onTap: () async {
                  final picked = await showDatePicker(
                    context: context,
                    initialDate: DateTime.now(),
                    firstDate: DateTime.now(),
                    lastDate: DateTime(2100),
                  );
                  if (picked != null) setState(() => followUpDate = picked);
                },
              ),
            if (followUpRequired)
            Divider(height: 24),
            if (followUpRequired)
            TextField(
              controller: followUpRemark,
              decoration: InputDecoration(
                  labelText: "Follow Up Remark", border: OutlineInputBorder()),
              maxLines: 1,
            ),
            if((widget.visit['partyType']==1||widget.visit['partyType']=="1")&&widget.meetingHappen!=null && widget.meetingHappen.toString().toLowerCase()=="yes")
            Divider(height: 24),
            if((widget.visit['partyType']==1||widget.visit['partyType']=="1")&&widget.meetingHappen!=null && widget.meetingHappen.toString().toLowerCase()=="yes")
            CheckboxListTile(
              title: Text("Mittstore Account Needed"),
              value: mittsureAccountNeeded,
              onChanged: (value) =>
                  setState(() => mittsureAccountNeeded = value!),
            ),
            if (mittsureAccountNeeded)
              Container(
                margin: EdgeInsets.symmetric(vertical: 16),
                padding: EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: Colors.grey[100],
                  border: Border.all(color: Colors.indigo),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Form(
                  key: _formKey,
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text("Mittstore Account Details",
                          style: TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.bold,
                              color: Colors.indigo)),
                      SizedBox(height: 12),
                      TextFormField(
                        controller: schoolNameController,
                        decoration: InputDecoration(
                          labelText: 'Party Name',
                          border: OutlineInputBorder(),
                        ),
                        validator: (val) => val == null || val.trim().isEmpty
                            ? "Required"
                            : null,
                      ),
                      SizedBox(height: 12),
                      TextFormField(
                        controller: contactPersonController,
                        decoration: InputDecoration(
                          labelText: 'Contact Person',
                          border: OutlineInputBorder(),
                        ),
                        validator: (val) => val == null || val.trim().isEmpty
                            ? "Required"
                            : null,
                      ),
                      SizedBox(height: 12),
                      TextFormField(
                        controller: accountMobileController,
                        keyboardType: TextInputType.phone,
                        decoration: InputDecoration(
                          labelText: 'Mobile Number',
                          border: OutlineInputBorder(),
                        ),
                        validator: (val) => !isValidIndianMobile(val ?? "")
                            ? "Invalid mobile"
                            : null,
                      ),
                      SizedBox(height: 12),
                      TextFormField(
                        controller: accountEmailController,
                        keyboardType: TextInputType.emailAddress,
                        decoration: InputDecoration(
                          labelText: 'Email ID',
                          border: OutlineInputBorder(),
                        ),
                        validator: (val) =>
                            !isValidEmail(val ?? "") ? "Invalid email" : null,
                      ),
                      SizedBox(height: 12),
                      TextFormField(
                        controller: accountRemarksController,
                        maxLines: 1,
                        decoration: InputDecoration(
                          labelText: 'Remarks (optional)',
                          border: OutlineInputBorder(),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
              // if(widget.visit['partyType']==1||widget.visit['partyType']=="1")
            CheckboxListTile(
              title: Text("Party Update"),
              value: partyUpdateRequired,
              onChanged: (value) =>
                  setState(() => partyUpdateRequired = value!),
            ),
            Divider(height: 24),
            if (partyUpdateRequired)
              Container(
                margin: EdgeInsets.symmetric(vertical: 16),
                padding: EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: Colors.grey[100],
                  border: Border.all(color: Colors.indigo),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Form(
                  key: _schoolformKey,
                  child: Column(
                    children: [
                      buildTextField(
                          controller: schoolName, label: 'School Name'),
                      buildTextField(
                          controller: addressLine1, label: 'Address Line 1'),
                      // buildTextField(
                      //     controller: addressLine2, label: 'Address Line 2'),
                      buildTextField(controller: pincode, label: 'Pincode'),
                      buildDropdownFromList(
                          'Decision Maker Role',
                          roles,
                          'contactPersonRoleId',
                          "roleName",
                          selectedRole, (value) {
                        selectedRole = value;
                      }),
                      buildTextField(
                          controller: makerName, label: 'Maker Name'),
                      buildTextField(
                          controller: makerContact, label: 'Maker Contact'),
                      buildTextField(controller: email, label: 'Email'),
                      if(widget.visit['partyType']==1||widget.visit['partyType']=="1")
                      buildDropdownFromList(
                          'Board',
                          boardList,
                          'boardId',
                          'boardName',
                          selectedBoard,
                          (val) => setState(() => selectedBoard = val)),
                          if(widget.visit['partyType']==1||widget.visit['partyType']=="1")
                      buildDropdownFromList(
                          'Grade',
                          gradeList,
                          'gradeId',
                          'gradeName',
                          selectedGrade,
                          (val) => setState(() => selectedGrade = val)),
                          if(widget.visit['partyType']==1||widget.visit['partyType']=="1")
                      buildDropdownFromList(
                          'Medium',
                          mediumList,
                          'mediumTableId',
                          'mediumName',
                          selectedMedium,
                          (val) => setState(() => selectedMedium = val)),
                    ],
                  ),
                ),
              ),
              if((widget.visit['partyType']==1||widget.visit['partyType']=="1")&&widget.meetingHappen!=null && widget.meetingHappen.toString().toLowerCase()=="yes")
            Divider(height: 24),
            if((widget.visit['partyType']==1||widget.visit['partyType']=="1")&&widget.meetingHappen!=null && widget.meetingHappen.toString().toLowerCase()=="yes")
            Text(
              "Preferred Distributor",
              style: TextStyle(fontWeight: FontWeight.bold),
            ),
            SizedBox(height: 10,),
            if((widget.visit['partyType']==1||widget.visit['partyType']=="1")&&widget.meetingHappen!=null && widget.meetingHappen.toString().toLowerCase()=="yes")
            TypeAheadFormField<Map<String, dynamic>>(
              textFieldConfiguration: TextFieldConfiguration(
                controller: prefDistributor,
                decoration: InputDecoration(
                  labelText: 'Enter or Select Preferred Distributor',
                  border: OutlineInputBorder(),
                ),
              ),
              suggestionsCallback: (pattern) {
                return distributors
                    .where((dist) => dist['DistributorName']
                        .toLowerCase()
                        .contains(pattern.toLowerCase()))
                    .cast<Map<String, dynamic>>();
              },
              itemBuilder: (context, suggestion) {
                return ListTile(
                  title: Text(suggestion['DistributorName']),
                );
              },
              onSuggestionSelected: (suggestion) {
                prefDistributor.text = suggestion['DistributorName'];
                // selectedValue = suggestion['distributorID'];
              },
            ),
            Divider(height: 24),
            TextField(
              controller: visitEndRemark,
              decoration: InputDecoration(
                  labelText: "Visit End Remark", border: OutlineInputBorder()),
              maxLines: 1,
            ),
            SizedBox(height: 10,),
           
            SizedBox(
              width: double.infinity,
              child: ElevatedButton.icon(
                onPressed: isLoading
                    ? null
                    : () {
                        
                          _submitRequest(context);
                        
                      },
                icon: isLoading
                    ? CircularProgressIndicator(color: Colors.white)
                    : Icon(Icons.edit_note_outlined, color: Colors.white),
                label: Text("End visit",
                    style: TextStyle(color: Colors.white)),
                style: ElevatedButton.styleFrom(
                  padding: EdgeInsets.symmetric(vertical: 14),
                  backgroundColor: Colors.indigo,
                  textStyle: TextStyle(fontSize: 16),
                ),
              ),
            ),
          ],
        ),
      ),
    );
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
              title: Text("Enter OTP"),
              content: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  TextField(
                    controller: otpController,
                    keyboardType: TextInputType.number,
                    maxLength: 6,
                    decoration: InputDecoration(hintText: "Enter 6-digit OTP"),
                  ),
                  SizedBox(height: 8),
                  canResendOtp
                      ? TextButton(
                          onPressed: () {
                            timer?.cancel();
                            Navigator.pop(context);
                            _sendOtp(cont);
                          },
                          child: Text("Resend OTP"),
                        )
                      : Text("Resend in $remainingSeconds seconds"),
                ],
              ),
              actions: [
                ElevatedButton(
                  onPressed: () {
                    if (otpController.text.length == 6) {
                      timer?.cancel();
                      Navigator.pop(context);
                      _submitOtp(cont);
                    } else {
                      _showSnackbar("Please enter a valid 6-digit OTP", cont);
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

  Future<void> _submitOtp(cont) async {
    setState(() => isLoading = true);

    var body = {
      "mobile": selectedOption == 'Other'
          ? otherNumberController.text
          : widget.payload.fields['phone'],
      "otp": otpController.text,
      "visitId": widget.payload.fields['id']
    };

    try {
      final response = await ApiService.post(
        endpoint: '/visit/verifyOtpForVisit',
        body: body,
      );

      if (response != null && response['status'] == false) {
        Navigator.pushAndRemoveUntil(
          cont,
          MaterialPageRoute(builder: (_) => MainMenuScreen()),
          (_) => false,
        );
      } else {
        _showPopup("Incorrect OTP. Please try again.", false, context);
        setState(() => isLoading = false);
      }
    } catch (_) {
      _showPopup("Failed to verify OTP. Please try again.", false, context);
      setState(() => isLoading = false);
    } finally {
      setState(() => isLoading = false);
    }
  }

  Widget buildTextField(
      {required TextEditingController controller, required String label}) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 6),
      child: TextFormField(
        controller: controller,
        decoration: InputDecoration(
          labelText: label,
          border: OutlineInputBorder(),
        ),
        validator: (val) => val == null || val.isEmpty ? 'Required' : null,
      ),
    );
  }

  Widget buildDropdownFromList(
    String label,
    List<dynamic> items,
    String keyId,
    String keyName,
    String? value,
    ValueChanged<String?> onChanged,
  ) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: DropdownButtonFormField<String>(
        decoration: InputDecoration(
          labelText: label,
          border: OutlineInputBorder(borderRadius: BorderRadius.circular(8)),
          contentPadding:
              const EdgeInsets.symmetric(horizontal: 12, vertical: 14),
        ),
        value: value,
        items: items
            .map((item) => DropdownMenuItem<String>(
                  value: item[keyId].toString(),
                  child: Text(item[keyName] ?? ""),
                ))
            .toList(),
        onChanged: onChanged,
        validator: (val) =>
            val == null || val.isEmpty ? 'Please select $label' : null,
      ),
    );
  }
}
