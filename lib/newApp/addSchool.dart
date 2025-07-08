import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:mittsure/screens/Party.dart';
import 'dart:convert';
import 'package:mittsure/services/apiService.dart';
import 'package:mittsure/services/utils.dart';

class AddSchoolForm extends StatefulWidget {
  @override
  _AddSchoolFormState createState() => _AddSchoolFormState();
}

class _AddSchoolFormState extends State<AddSchoolForm> {
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
  final TextEditingController ownerId = TextEditingController();

  // Dropdown values
  String? selectedSchoolType=null;
  String? selectedCategory=null;
  String? selectedMedium=null;
  String? selectedGrade=null;
  String? selectedCustomerType=null;
  String? selectedBoard=null;
   String? selectedRole=null;

  // Picklist data
  List<dynamic> schoolTypeList = [];
  List<dynamic> categoryList = [];
  List<dynamic> mediumList = [];
  List<dynamic> gradeList = [];
  List<dynamic> customerTypeList = [];
  List<dynamic> boardList = [];
  List<dynamic> roles = [];

  bool onboardForErp = false;
  bool isLoading = true;

  @override
  void initState() {
    super.initState();
    fetchAllPicklists();
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
        roles=responses[6]['data'];


        isLoading = false;
      });
    } catch (e) {
      print('Error fetching picklists: $e');
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Failed to load dropdown data')));
    }
  }

  void submitForm() async {
    if (_formKey.currentState!.validate()) {
      final payload = {
        "addressLine1": addressLine1.text,
        "addressLine2": addressLine2.text,
        "board": selectedBoard,
        "customer_type": int.tryParse(selectedCustomerType??""),
        "district": district.text,
        "email": email.text,
        "grade": [selectedGrade],
        "landmark": landmark.text,
        "makerContact": makerContact.text,
        "makerName": makerName.text,
        "makerRole": selectedRole??"",
        "medium": selectedMedium,
        "onboardforErp": onboardForErp,
        "ownerId": ownerId.text,
        "parentSchoolName": parentSchoolName.text,
        "pincode": pincode.text,
        "registrationNo": "",
        "schoolCategory": selectedCategory,
        "schoolName": schoolName.text,
        "school_type": int.tryParse(selectedSchoolType??""),
        "state": state.text,
        "strength": strength.text,
        "website": website.text,
        "created_role": "rm"
      };

      final response =await ApiService.post(endpoint: "/party/addPartySchool", body: payload);

      if (response!=null && response["status"]==false) {
      DialogUtils.showCommonPopup(context: context, message: "School Added Successfully", isSuccess: true,onOkPressed: (){
          Navigator.pushReplacement(
                          context,
                          MaterialPageRoute(
                            builder: (context) => PartyScreen()
                          ),
                        );
      });
      } else {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Failed to add school')));
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text('Add School')),
      body: isLoading
          ? Center(child: CircularProgressIndicator())
          : SingleChildScrollView(
              padding: EdgeInsets.all(16),
              child: Form(
                key: _formKey,
                child: Column(
                  children: [
                    buildTextField(controller: schoolName, label: 'School Name'),
                    buildDropdownFromList('School Type', schoolTypeList, 'id', 'name', selectedSchoolType, (val) => setState(() => selectedSchoolType = val)),
                    buildTextField(controller: parentSchoolName, label: 'Parent School Name'),
                    buildDropdownFromList('Board', boardList, 'boardId', 'boardName', selectedBoard, (val) => setState(() => selectedBoard = val)),
                    buildDropdownFromList('Medium', mediumList, 'mediumTableId', 'mediumName', selectedMedium, (val) => setState(() => selectedMedium = val)),
                    buildDropdownFromList('Category', categoryList, 'id', 'name', selectedCategory, (val) => setState(() => selectedCategory = val)),
                    buildDropdownFromList('Customer Type', customerTypeList, 'id', 'name', selectedCustomerType, (val) => setState(() => selectedCustomerType = val)),
                    buildDropdownFromList('Grade', gradeList, 'gradeId', 'gradeName', selectedGrade, (val) => setState(() => selectedGrade = val)),
                    buildTextField(controller: addressLine1, label: 'Address Line 1'),
                    buildTextField(controller: addressLine2, label: 'Address Line 2'),
                    buildTextField(controller: district, label: 'District'),
                    buildTextField(controller: state, label: 'State'),
                    buildTextField(controller: pincode, label: 'Pincode'),
                    buildTextField(controller: landmark, label: 'Landmark'),
                    buildTextField(controller: strength, label: 'Strength'),
                    buildTextField(controller: email, label: 'Email'),
                    buildTextField(controller: website, label: 'Website'),
                    buildDropdownFromList('Decision Maker Role', roles, 'contactPersonRoleId', "roleName", selectedRole, (value) { 
                      selectedRole=value;
                    }),
                    
                    buildTextField(controller: makerName, label: 'Maker Name'),
                    buildTextField(controller: makerContact, label: 'Maker Contact'),

                    SizedBox(height: 10),
              
                    ElevatedButton(onPressed: submitForm, child: Text('Submit')),
                  ],
                ),
              ),
            ),
    );
  }

  Widget buildTextField({required TextEditingController controller, required String label}) {
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
          contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 14),
        ),
        value: value,
        items: items
            .map((item) => DropdownMenuItem<String>(
                  value: item[keyId].toString(),
                  child: Text(item[keyName] ?? ""),
                ))
            .toList(),
        onChanged: onChanged,
        validator: (val) => val == null || val.isEmpty ? 'Please select $label' : null,
      ),
    );
  }
}
