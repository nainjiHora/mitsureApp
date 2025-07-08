import 'dart:convert';
import 'dart:io';
import 'package:file_picker/file_picker.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter/widgets.dart';
import 'package:http/http.dart' as http;
import 'package:image_picker/image_picker.dart';
import 'package:intl/intl.dart';
import 'package:mittsure/newApp/bookLoader.dart';
import 'package:mittsure/newApp/expenseList.dart';
import 'package:mittsure/newApp/reviewExpense.dart';
import 'package:mittsure/services/apiService.dart';
import 'package:mittsure/services/utils.dart';
import 'package:shared_preferences/shared_preferences.dart';

class AddExpenseScreen extends StatefulWidget {
  @override
  _AddExpenseScreenState createState() => _AddExpenseScreenState();
}

class _AddExpenseScreenState extends State<AddExpenseScreen> {
  final _formKey = GlobalKey<FormState>();

  DateTime selectedDate = DateTime.now();
  String? expenseType;
   String? expenseSubType;
  String? expensePurpose;
  String? partyType;
  String? party;
  bool viewpage = false;

  TextEditingController amount = TextEditingController();
  TextEditingController remark = TextEditingController();
  TextEditingController typeRemark = TextEditingController();
    TextEditingController subTypeRemark = TextEditingController();
  TextEditingController purposeremark = TextEditingController();
  bool isLoading = false;
  bool showtyperemark = false;
    bool subtypeRequired = false;
   bool showSubtyperemark = false;
  bool showPurposeremark = false;

  List<dynamic> schools = [];
  List<dynamic> distributors = [];
  File? selectedFile;
  final ImagePicker _picker = ImagePicker();

  final List<dynamic> expenseTypes = [];
  final List<dynamic> expenseSubTypes = [];
   List<dynamic> filteredSubTypes = [];
  final List<dynamic> expensePurposes = [];
  final List<dynamic> partyTypes = [];
  final List<dynamic> parties = [];

  void _pickFile() async {
    FilePickerResult? result = await FilePicker.platform.pickFiles();
    if (result != null && result.files.single.path != null) {
      setState(() {
        selectedFile = File(result.files.single.path!);
      });
    }
  }

  void onlyReview() {

    print(expenseType);
    print(expensePurpose);
     if (_formKey.currentState!.validate() &&
        selectedFile != null &&
        expensePurpose != null &&
        expenseType != null && (!subtypeRequired|| expenseSubType != null)){
    setState(() {
      viewpage = true;
    });
        }
        else{
          print("Dasda");
        }
  }

 backAndSubmit() {
  setState(() {
    viewpage = false;
  });

  // Delay until after widget tree is rebuilt
  WidgetsBinding.instance.addPostFrameCallback((_) {
    _reviewAndSubmit();
  });
}

  void _reviewAndSubmit() {
    if (_formKey.currentState!.validate() &&
        selectedFile != null &&
        expensePurpose != null &&
        expenseType != null&& (!subtypeRequired|| expenseSubType != null)) {
      _formKey.currentState!.save();
      print("plpl");
      setState(() {
        isLoading = true;
      });
      uploadFiles();
    } else if (selectedFile == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text("Please upload a bill file.")),
      );
    } else {
      DialogUtils.showCommonPopup(
          context: context,
          message: "Expense Type And Purpose is mandatory",
          isSuccess: false);
    }
  }

  Future<void> uploadFiles() async {
    try {
      if (selectedFile == null) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text("Please select files before submitting.")),
        );
        return;
      }

      var request = http.MultipartRequest(
        'POST',
        Uri.parse(
            'https://mittsure.qdegrees.com:3001/user/uploadMultipleImages'),
        // Uri.parse('https://mittsureone.com:3001/user/uploadMultipleImages'),
      );

      request.files.add(
        await http.MultipartFile.fromPath(
          'files', // Key name for the array in the API
          selectedFile!.path,
        ),
      );

      var response = await request.send();

      if (response.statusCode == 200) {
        String responseBody = await response.stream.bytesToString();

        var jsonResponse = jsonDecode(responseBody);

        saveForm(jsonResponse['files'][0]['path']);
      } else {
        setState(() {
          isLoading = false;
        });
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text("Failed to upload files.")),
        );
      }
    } catch (e) {
      DialogUtils.showCommonPopup(
          context: context, message: "Something Went Wrong", isSuccess: false);
    } finally {
      setState(() {
        isLoading = false;
      });
    }
  }

  saveForm(url) async {
    final prefs = await SharedPreferences.getInstance();
    final hasData = prefs.getString('user') != null;
    var id = "";
    if (hasData) {
      id = jsonDecode(prefs.getString('user') ?? "")['id'];
    } else {
      return;
    }

    final pyload = {
      "date": selectedDate.toString(),
      "approvedBy": null,
      "expenseType": expenseType ?? "",
      "expenseSubType":expenseSubType??"",
      "remark": remark.text,
      "partyId": party,
      "amount": amount.text,
      "expensePurpose": expensePurpose ?? "",
      "type": partyType,
      "employeeId": id,
      "billLink": url,
      "purposeRemark":purposeremark.text,
      "typeRemark":typeRemark.text,
      "subTypeRemark":subTypeRemark.text
    };

    try {
      final response = await ApiService.post(
        endpoint: '/expense/createExpense',
        body: pyload,
      );
      if (response != null && response['status'] == false) {
        
        Navigator.pushReplacement(
          context,
          MaterialPageRoute(builder: (context) => ExpenseListScreen()),
        );
      } else {
        DialogUtils.showCommonPopup(
            context: context, message: response['message'], isSuccess: false);
      }
    } catch (error) {
      print("Error fetchidddddng orders: $error");
    } finally {
      setState(() {
        isLoading = false;
      });
    }
  }

  @override
  void initState() {
    // TODO: implement initState
    super.initState();
    fetchPicklist();
    fetchPicklist1();
    fetchPicklist2();
  }

  fetchPicklist() async {
    final body = {};

    try {
      final response = await ApiService.post(
        endpoint: '/picklist/getExpenseType', // Use your API endpoint
        body: body,
      );
      print(response);
      print("dadada");
      if (response != null && response['status'] == false) {
        setState(() {
          expenseTypes.addAll(response['data']);
        });
      } else {
        throw Exception('Failed to load orders');
      }
    } catch (error) {
      print("Error fetcffdfdhing orders: $error");
    }
  }


    fetchPicklist2() async {
    final body = {};

    try {
      final response = await ApiService.post(
        endpoint: '/picklist/getExpenseSubType', // Use your API endpoint
        body: body,
      );
      print(response);

      if (response != null ) {
        setState(() {
          print(response['data']);
          expenseSubTypes.addAll(response['data']);
        });
      } else {
        throw Exception('Failed to load orders');
      }
    } catch (error) {
      print(error);
      print("Error fdhing orders: $error");
    }
  }

  Future<void> _showFileSourceOptions() async {
    showModalBottomSheet(
      context: context,
      builder: (context) => SafeArea(
        child: Wrap(
          children: [
            ListTile(
              leading: Icon(Icons.camera_alt),
              title: Text('Take Photo'),
              onTap: () async {
                final XFile? image =
                    await _picker.pickImage(source: ImageSource.camera);
                if (image != null) {
                  setState(() => selectedFile = File(image.path));
                }
                Navigator.pop(context);
              },
            ),
            ListTile(
              leading: Icon(Icons.photo_library),
              title: Text('Choose from Gallery'),
              onTap: () async {
                final XFile? image =
                    await _picker.pickImage(source: ImageSource.gallery);
                if (image != null) {
                  setState(() => selectedFile = File(image.path));
                }
                Navigator.pop(context);
              },
            ),
          ],
        ),
      ),
    );
  }

  fetchPicklist1() async {
    final body = {};

    try {
      final response = await ApiService.post(
        endpoint: '/picklist/getExpensePurpose', // Use your API endpoint
        body: body,
      );
      if (response != null && response['status'] == false) {
        setState(() {
          print(response['data']);
          expensePurposes.addAll(response['data']);
        });
      } else {
        throw Exception('Failed to load orders');
      }
    } catch (error) {
      print("Error fetcffdfdhing orders: $error");
    }
  }

  Future<void> _fetchOrders(String filter) async {
    setState(() {
      isLoading = true;
      party = null;
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
      "ownerId": id,
    };
    if ((partyType == "1" && schools.length == 0) ||
        (partyType == "0" && distributors.length == 0)) {
      try {
        final response = await ApiService.post(
          endpoint:
              partyType == "1" ? '/party/getAllSchool' : '/party/getAllDistri',
          body: body,
        );
        if (response != null) {
          final data = response['data'];
          setState(() {
            if (partyType == "1") {
              schools = data;
            } else {
              distributors = data;
            }
            isLoading = false;
          });
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
    } else {
      setState(() {
        isLoading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return WillPopScope(
      onWillPop: ()async{
        if(viewpage){
          setState(() {
            viewpage=false;
          });
        }else{
           Navigator.pushReplacement(
          context,
          MaterialPageRoute(
            builder: (context) =>ExpenseListScreen()
          ),
        );
        }
        return false;
        
      },
      child: Scaffold(
        appBar: AppBar(
          title: Text(
            viewpage?"Review Expense" :"Add Expense",
            style: TextStyle(color: Colors.white),
          ),
          iconTheme: IconThemeData(color: Colors.white),
          backgroundColor: Colors.indigo[900],
        ),
        body: Stack(children: [
           Visibility(
            visible: viewpage && selectedFile!=null,
             child: ReviewExpenseScreen(
                  onsubmit:backAndSubmit,
                  purposes: expensePurposes,
                  types:expenseTypes,
                    date: selectedDate,
                    subType:expenseSubType??"",
                    subTypeRemark:subTypeRemark.text,
                    expensePurpose: expensePurpose ?? "",
                    expenseType: expenseType ?? "",
                    party: party ?? "",
                    partyType: partyType ?? "",
                    remark: remark.text,
                    amount: amount.text,
                    typeRemark:typeRemark.text,
                    purposeremark:purposeremark.text
                  ),
           ),
              Visibility(
                visible: !viewpage,
                child: SingleChildScrollView(
                  child: Form(
                      key: _formKey,
                      child: Column(children: [
                        // Date
                        ListTile(
                          title: Text(
                              "Date: ${DateFormat('dd MMM yyyy').format(selectedDate)}"),
                          trailing: Icon(Icons.calendar_today),
                          onTap: () async {
                            DateTime? picked = await showDatePicker(
                              context: context,
                              initialDate: selectedDate,
                              firstDate: DateTime.now().subtract(Duration(days: 6)),
                              lastDate: DateTime.now(),
                            );
                            if (picked != null) {
                              setState(() => selectedDate = picked);
                            }
                          },
                        ),
                        SizedBox(height: 10),
                          
                        _buildDropdown(
                            'Expense Type',
                            expenseTypes,
                            "expenseTypeId",
                            "expenseTypeName",
                            expenseType, (value) {
                          setState(() {
                           expenseSubType=null;
                            var b=expenseSubTypes.where((element) => element['expenseTypeId']==value||element['expenseTypeId']==""||element['expenseTypeId']==null).toList();
                            print(b);
                            filteredSubTypes=b;
                            var a = expenseTypes
                                .where(
                                    (element) => element['expenseTypeId'] == value)
                                .toList();
                            if (a[0]['textBox'] == 1 || a[0]['textBox'] == "1") {
                              showtyperemark = true;
                            } else {
                              typeRemark.text = "";
                              showtyperemark = false;
                            }
                            if(a[0]['subTypeRequired']==1||a[0]['subTypeRequired']=="1"){
                            subtypeRequired = true;
                            }else{
                              subtypeRequired=false;
                            }
                            expenseType=value;
                          });
                        }),
                        if (showtyperemark)
                          _buildTextField(
                            label: 'Expense Type Description',
                            controller: typeRemark,
                            validator: (value) {
                              if (value == null || value.trim().isEmpty) {
                                return 'Description is required';
                              }
                              return null;
                            },
                          ),
                          if(subtypeRequired)
                          _buildDropdown(
                            'Expense Sub Type',
                            filteredSubTypes,
                            "id",
                            "name",
                            expenseSubType, (value) {
                          setState(() {
                            print(value);
                            print(expenseSubTypes);
                            var a = expenseSubTypes
                          
                                .where(
                                    (element) => element['id'].toString() == value)
                                .toList();
                            if (a[0]['textBox'] == 1 || a[0]['textBox'] == "1") {
                              showSubtyperemark = true;
                            } else {
                              subTypeRemark.text = "";
                              showSubtyperemark = false;
                            }
                            expenseSubType = value;
                          });
                        }),
                         if (showSubtyperemark)
                          _buildTextField(
                            label: 'Expense Sub Type Description',
                            controller: subTypeRemark,
                            validator: (value) {
                              if (value == null || value.trim().isEmpty) {
                                return 'Description is required';
                              }
                              return null;
                            },
                          ),
                        _buildDropdown(
                            'Expense Purpose',
                            expensePurposes,
                            "expensePurposeId",
                            "expensePurposeName",
                            expensePurpose, (value) {
                          setState(() {
                            var a = expensePurposes
                                .where((element) =>
                                    element['expensePurposeId'] == value)
                                .toList();
                            if (a[0]['textBox'] == 1 || a[0]['textBox'] == "1") {
                              showPurposeremark = true;
                            } else {
                              showPurposeremark = false;
                              purposeremark.text = "";
                            }
                            expensePurpose = value;
                          });
                        }),
                        if (showPurposeremark)
                          _buildTextField(
                            label: 'Expense Purpose Description',
                            controller: purposeremark,
                            validator: (value) {
                              if (value == null || value.trim().isEmpty) {
                                return 'Description is required';
                              }
                              return null;
                            },
                          ),
                          
                        _buildTextField(
                          controller: amount,
                          label: "Amount",
                          inputType: TextInputType.number,
                          validator: (value) {
                            if (value == null || value.trim().isEmpty) {
                              return 'Amount is required';
                            }
                            return null;
                          },
                        ),
                          
                        const SizedBox(height: 12),
                        _buildDropdown(
                            'Party Type',
                            [
                              {"id": "", "name": "Select Party Type"},
                              {"id": "1", "name": "School"},
                              {"id": "0", "name": "Distributor"}
                            ],
                            "id",
                            'name',
                            partyType, (val) {
                          setState(() => partyType = val);
                          _fetchOrders(val ?? "");
                        }),
                        const SizedBox(height: 12),
                        partyType == '1'
                            ? _buildDropdown(
                                'Select School',
                                schools,
                                "schoolId",
                                'schoolName',
                                party,
                                (val) => setState(() {
                                      party = val;
                                    }))
                            : _buildDropdown(
                                'Select Distributor',
                                distributors,
                                "distributorID",
                                'DistributorName',
                                party,
                                (val) => setState(() {
                                      party = val;
                                    })),
                        const SizedBox(height: 20),
                          
                        _buildTextField(controller: remark, label: "Remark"),
                        SizedBox(height: 10),
                          
                        Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            GestureDetector(
                              onTap: _showFileSourceOptions,
                              child: Container(
                                width: double.infinity,
                                padding: EdgeInsets.symmetric(vertical: 16),
                                margin: EdgeInsets.symmetric(
                                    horizontal: 8, vertical: 12),
                                decoration: BoxDecoration(
                                  border:
                                      Border.all(color: Colors.indigo, width: 1.5),
                                  borderRadius: BorderRadius.circular(10),
                                ),
                                child: Row(
                                  mainAxisAlignment: MainAxisAlignment.center,
                                  children: [
                                    Icon(Icons.upload_file, color: Colors.indigo),
                                    SizedBox(width: 10),
                                    Text(
                                      selectedFile == null
                                          ? "Upload Bill (Camera/Gallery)"
                                          : "Change Uploaded Bill",
                                      style: TextStyle(
                                          color: Colors.indigo,
                                          fontWeight: FontWeight.bold),
                                    ),
                                  ],
                                ),
                              ),
                            ),
                            if (selectedFile != null &&
                                (selectedFile!.path.endsWith(".jpg") ||
                                    selectedFile!.path.endsWith(".jpeg") ||
                                    selectedFile!.path.endsWith(".png")))
                              Container(
                                margin: EdgeInsets.symmetric(horizontal: 8),
                                child: ClipRRect(
                                  borderRadius: BorderRadius.circular(10),
                                  child: Image.file(
                                    selectedFile!,
                                    height: 180,
                                    width: double.infinity,
                                    fit: BoxFit.contain,
                                  ),
                                ),
                              ),
                            if (selectedFile != null &&
                                !(selectedFile!.path.endsWith(".jpg") ||
                                    selectedFile!.path.endsWith(".jpeg") ||
                                    selectedFile!.path.endsWith(".png")))
                              Padding(
                                padding:
                                    const EdgeInsets.symmetric(horizontal: 12.0),
                                child: Text(
                                  selectedFile!.path.split('/').last,
                                  style: TextStyle(fontWeight: FontWeight.bold),
                                ),
                              ),
                          ],
                        ),
                          
                        SizedBox(height: 20),
                        ElevatedButton(
                          onPressed: onlyReview,
                          child: Text("Review & Submit",
                              style: TextStyle(color: Colors.white)),
                          style: ElevatedButton.styleFrom(
                            backgroundColor: Colors.green,
                            padding:
                                EdgeInsets.symmetric(horizontal: 24, vertical: 14),
                          ),
                        ),
                      ]),
                    ),
                ),
              ),
          if (isLoading) BookPageLoader()
        ]),
      ),
    );
  }

  Widget _buildTextField({
    TextEditingController? controller,
    required String label,
    TextInputType? inputType,
    List<TextInputFormatter>? formatter,
    FormFieldSetter<String>? onSaved,
    FormFieldValidator<String>? validator,
  }) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 8),
      child: TextFormField(
        controller: controller,
        keyboardType: inputType,
        inputFormatters: formatter,
        decoration: InputDecoration(
          labelText: label,
          border: OutlineInputBorder(borderRadius: BorderRadius.circular(8)),
          contentPadding:
              const EdgeInsets.symmetric(horizontal: 12, vertical: 14),
        ),
        validator: validator,
        onSaved: onSaved,
      ),
    );
  }

  Widget _buildDropdown(String label, List<dynamic> items, keyId, keyName,
      String? value, ValueChanged<String?> onChanged) {
    return Padding(
      padding: const EdgeInsets.all(8.0),
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
}
