import 'package:flutter/material.dart';
import 'package:mittsure/screens/Party.dart';
import 'package:mittsure/services/apiService.dart';
import 'package:mittsure/services/utils.dart';
import 'package:multi_select_flutter/chip_display/multi_select_chip_display.dart';
import 'package:multi_select_flutter/dialog/multi_select_dialog_field.dart';
import 'package:multi_select_flutter/util/multi_select_item.dart';

class AddDistributorForm extends StatefulWidget {
  @override
  _AddDistributorFormState createState() => _AddDistributorFormState();
}

class _AddDistributorFormState extends State<AddDistributorForm> {
  final _formKey = GlobalKey<FormState>();

  // Controllers
  final TextEditingController addressLine1 = TextEditingController();
  final TextEditingController addressLine2 = TextEditingController();
  final TextEditingController distributorName = TextEditingController();
  final TextEditingController district = TextEditingController();
  final TextEditingController state = TextEditingController();
  final TextEditingController pincode = TextEditingController();
  final TextEditingController landmark = TextEditingController();
  final TextEditingController email = TextEditingController();
  final TextEditingController makerName = TextEditingController();
  final TextEditingController makerContact = TextEditingController();
  final TextEditingController ownerId = TextEditingController();

  // Dropdown values
  String? selectedCluster;
  String? selectedRole;
  List<String> selectedSeries = [];

  // Picklist data
  List<dynamic> clusterList = [];
  List<dynamic> seriesList = [];
  List<dynamic> roles = [];

  bool isLoading = true;

  @override
  void initState() {
    super.initState();
    fetchPicklists();
  }

  Future<void> fetchPicklists() async {
    try {
      final responses = await Future.wait([
        ApiService.post(endpoint: '/party/getClusterInPicklist', body: {}),
        ApiService.post(endpoint: '/product/getSeriesCategory', body: {}),
        ApiService.post(endpoint: '/picklist/getContactPersonRole', body: {}),
      ]);

      setState(() {
        clusterList = responses[0]['data'] ?? [];
        seriesList = responses[1]['data'] ?? [];
        roles = responses[2]['data2'] ?? [];
        isLoading = false;
      });
    } catch (e) {
      print('Error loading picklists: $e');
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Failed to load dropdown data')));
    }
  }

  void submitForm() async {
    if (_formKey.currentState!.validate()) {
      final payload = {
        "addressLine1": addressLine1.text,
        "addressLine2": addressLine2.text,
        "cluster": int.tryParse(selectedCluster ?? ""),
        "distributorName": distributorName.text,
        "district": district.text,
        "email": email.text,
        "landmark": landmark.text,
        "makerContact": makerContact.text,
        "makerName": makerName.text,
        "makerRole": selectedRole ?? "",
        "ownerId": ownerId.text,
        "pincode": pincode.text,
        "series": selectedSeries,
        "state": state.text,
      };

      final response = await ApiService.post(
        endpoint: "/party/addDistributor",
        body: payload,
      );

      if (response != null && response["status"] == false) {
         DialogUtils.showCommonPopup(context: context, message: "Distributor Added Successfully", isSuccess: true,onOkPressed: (){
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
      appBar: AppBar(title: Text('Add Distributor')),
      body: isLoading
          ? Center(child: CircularProgressIndicator())
          : SingleChildScrollView(
              padding: EdgeInsets.all(16),
              child: Form(
                key: _formKey,
                child: Column(
                  children: [
                    buildTextField(controller: addressLine1, label: 'Address'),
                    
                    buildTextField(controller: distributorName, label: 'Distributor Name'),
                    buildDropdownFromList('Cluster', clusterList, 'id', 'name', selectedCluster,
                        (val) => setState(() => selectedCluster = val)),
                    buildDropdownMultiSelect('Series', seriesList, selectedSeries,'seriesTableId','seriesName',(values) {
                    setState(() {
                     selectedSeries=values;
                    });
                  }),
                   
                    buildTextField(controller: pincode, label: 'Pincode'),
                    buildTextField(controller: landmark, label: 'Landmark'),
                    buildTextField(controller: email, label: 'Email'),
                    buildDropdownFromList('Decision Maker Role', roles, 'contactPersonRoleId', "roleName",
                        selectedRole, (value) => setState(() => selectedRole = value)),
                    buildTextField(controller: makerName, label: 'Maker Name'),
                    buildTextField(controller: makerContact, label: 'Maker Contact'),
                    
                    SizedBox(height: 20),
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

  Widget buildDropdownMultiSelect(String label, List items, List<String> selected,id,key,onconfirm) {
    return Container(
                decoration: BoxDecoration(
                  border: Border.all(color: Colors.grey), // Border color
                  borderRadius:
                      BorderRadius.circular(8), // Optional: rounded corners
                ),
                padding: EdgeInsets.symmetric(
                    horizontal: 12, vertical: 4), // Optional: inner spacing
                child: MultiSelectDialogField(
                  items: items
                      .map<MultiSelectItem<String>>(
                        (opt) => MultiSelectItem<String>(
                          opt[id].toString(),
                          opt[key].toString(),
                        ),
                      )
                      .toList(),
                  title: Text(label),
                  selectedColor: Colors.blue,
                  decoration:
                      BoxDecoration(), // Needed to remove internal field's decoration
                  initialValue: selected
                      .map<String>((e) => e.toString())
                      .toList(),
                  onConfirm: onconfirm,
                  chipDisplay: MultiSelectChipDisplay(),
                ),
              );
  }
  

}
