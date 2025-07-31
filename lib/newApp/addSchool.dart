import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:mittsure/newApp/bookLoader.dart';
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
    try{
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
      setState(() {
        isLoading=true;
      });

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
         DialogUtils.showCommonPopup(context: context, message: "Failed to add school", isSuccess: false);
        
      }
    }
    }catch(e){
       DialogUtils.showCommonPopup(context: context, message: "Something Went Wrong, Please Check Pincode", isSuccess: false);
    }
    finally{
      setState(() {
        isLoading=false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text('Add School')),
      body: isLoading
          ? Center(child: BookPageLoader())
          : SingleChildScrollView(
              padding: EdgeInsets.all(16),
              child: Form(
                key: _formKey,
                child: Column(
                  children: [
                    
                    buildTextField(controller: schoolName, label: 'School Name',req: true),
                    buildDropdownFromList('School Type', schoolTypeList, 'id', 'name', selectedSchoolType, (val) => setState(() => selectedSchoolType = val),true),
                    buildTextField(controller: parentSchoolName, label: 'Parent School Name',req: false),
                    buildDropdownFromList('Board', boardList, 'boardId', 'boardName', selectedBoard, (val) => setState(() => selectedBoard = val),false),
                    buildDropdownFromList('Medium', mediumList, 'mediumTableId', 'mediumName', selectedMedium, (val) => setState(() => selectedMedium = val),false),
                    buildDropdownFromList('Category', categoryList, 'id', 'name', selectedCategory, (val) => setState(() => selectedCategory = val),false),
                    buildDropdownFromList('Customer Type', customerTypeList, 'id', 'name', selectedCustomerType, (val) => setState(() => selectedCustomerType = val),true),
                    buildDropdownFromList('Grade', gradeList, 'gradeId', 'gradeName', selectedGrade, (val) => setState(() => selectedGrade = val),false),
                    buildTextField(controller: addressLine1, label: 'Address Line 1',req: true),
                    buildTextField(controller: addressLine2, label: 'Address Line 2',req:false),
                    buildTextField(controller: pincode, label: 'Pincode',req:true),
                    buildTextField(controller: landmark, label: 'Landmark',req:false),
                    buildTextField(controller: strength, label: 'Strength',req:false),
                    buildTextField(controller: email, label: 'Email',req:false),
                    buildTextField(controller: website, label: 'Website',req:false),
                    buildDropdownFromList('Decision Maker Role', roles, 'contactPersonRoleId', "roleName", selectedRole, (value) { 
                      selectedRole=value;
                    },true),
                    
                    buildTextField(controller: makerName, label: 'Decision Maker Name',req:true),
                    buildTextField(controller: makerContact, label: 'Decision Maker Contact Number',req:true),

                    SizedBox(height: 10),
              
                    ElevatedButton(onPressed: submitForm, child: Text('Submit')),
                  ],
                ),
              ),
            ),
    );
  }

  Widget buildTextField({required TextEditingController controller, required String label,required bool req}) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 6),
      child: TextFormField(
        controller: controller,
        decoration: InputDecoration(
          labelText: label,
          border: OutlineInputBorder(),
        ),
        validator: (val) => (val == null || val.isEmpty)&&req ? 'Required' : null,
      ),
    );
  }

  Widget buildDropdownFromList(
    String label,
    List<dynamic> items,
    String keyId,
    String keyName,
    String? value,
    ValueChanged<String?> onChanged, bool req
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
        validator: (val) => (val == null || val.isEmpty )&&req? 'Please select $label' : null,
      ),
    );
  }
}
