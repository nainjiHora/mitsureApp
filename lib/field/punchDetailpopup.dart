import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:mittsure/newApp/bookLoader.dart';
import 'package:mittsure/services/apiService.dart';

class PunchDetailsPopup extends StatefulWidget {
  final String meterReading;
  final bool punchIn;

  const PunchDetailsPopup({
    Key? key,
    required this.meterReading,
    required this.punchIn,
  }) : super(key: key);

  @override
  _PunchDetailsPopupState createState() => _PunchDetailsPopupState();
}

class _PunchDetailsPopupState extends State<PunchDetailsPopup> {
  final _formKey = GlobalKey<FormState>();
  final Map<String, dynamic> _formData = {
    'km': '',
    'worktype': '',
    'visitType': '',
    'vehicleType': '',
    'remark': '',
    'kmChanged': false,
  };

  late TextEditingController _kmController;
  late String initialKM;

  String? selectedWorkType;
    String? selectedcity;
  String? selectedVisitType;
  String? selectedVehicleType;

  bool isLoading = false;
  List<dynamic> visitMode = [];
  List<dynamic> worktype = [];
  List<dynamic> transportMode = [];
   List<dynamic> city = [];

  @override
  void initState() {
    super.initState();
    getPicklist();
    // initialKM = widget.meterReading;
    // _kmController = TextEditingController(text: widget.meterReading);
    // _kmController.addListener(() {
    //   _formData['kmChanged'] = _kmController.text.trim() != initialKM.trim();
    // });
  }

  @override
  void dispose() {
    _kmController.dispose();
    super.dispose();
  }

  Future<void> getPicklist() async {
    setState(() => isLoading = true);

    try {
      final response = await ApiService.post(
        endpoint: '/attendance/getAttendanceDropdown',
        body: {},
      );

      if (response != null) {
        final data = response['data'];
        print(data);
        setState(() {
          transportMode = data['transport_mode'];
          worktype = data['work_type'];
          visitMode = data['visit_mode'];
          city = data['city'];
        });
      }
    } catch (error) {
      debugPrint("Error fetching dropdowns: $error");
    } finally {
      setState(() => isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title:  Text(widget.punchIn?'Add Punch Details':"Are you Sure to punch out ?", style: TextStyle(fontWeight: FontWeight.bold)),
      content: Stack(
        children: [
          Form(
            key: _formKey,
            child: SingleChildScrollView(
              child: Padding(
                padding: const EdgeInsets.all(4.0),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    // _buildTextField(
                    //   controller: _kmController,
                    //   label: "Meter Reading (KM)",
                    //   inputType: TextInputType.number,
                    //   formatter: [FilteringTextInputFormatter.digitsOnly],
                    //   onSaved: (val) => _formData['km'] = val ?? '',
                    //   validator: (val) => val == null || val.isEmpty ? 'Required' : null,
                    // ),

                    if (widget.punchIn)
                      _buildDropdown("Work Type", worktype, "id", "name", selectedWorkType, (value) {
                        setState(() {
                          selectedWorkType = value;
                          _formData['worktype'] = worktype.firstWhere(
                            (element) => element['id'].toString() == value,
                            orElse: () => '',
                          );
                          selectedVisitType = null;
                          selectedVehicleType = null;
                        });
                      }),

                    if (selectedWorkType == "10") ...[
                      _buildDropdown("Visit Type", visitMode, "id", "name", selectedVisitType, (value) {
                        setState(() {
                          selectedVisitType = value;
                          _formData['visitType'] = visitMode.firstWhere(
                            (element) => element['id'].toString() == value,
                            orElse: () => '',
                          );
                        });
                      }),
                       if (selectedVisitType == "5") 
                      _buildDropdown("City", city, "id", "name", selectedcity, (value) {
                        setState(() {
                         selectedcity=value;
                          _formData['city'] = city.firstWhere(
                            (element) => element['id'].toString() == value,
                            orElse: () => '',
                          );
                        });
                      }),
                      _buildDropdown("Transport Mode", transportMode, "id", "name", selectedVehicleType, (value) {
                        setState(() {
                          selectedVehicleType = value;
                          _formData['vehicleType'] = transportMode.firstWhere(
                            (element) => element['id'].toString() == value,
                            orElse: () => '',
                          );
                        });
                      }),
                    ],

                    if (selectedWorkType == '11')
                      _buildTextField(
                        label: "Remark",
                        onSaved: (val) => _formData['remark'] = val ?? '',
                        validator: (val) {
                          if ((val == null || val.trim().isEmpty)) return 'Remark required';
                          return null;
                        },
                      ),
                  ],
                ),
              ),
            ),
          ),
          if (isLoading)
            const Positioned.fill(child: BookPageLoader()),
        ],
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context, null),
          child: const Text("Cancel"),
        ),
        ElevatedButton(
          onPressed: () {
            if (_formKey.currentState!.validate()) {
              _formKey.currentState!.save();
              Navigator.pop(context, _formData);
            }
          },
          child:  Text(widget.punchIn?"Save":"Yes"),
        ),
      ],
    );
  }

  Widget _buildDropdown(
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

  Widget _buildTextField({
    TextEditingController? controller,
    required String label,
    TextInputType? inputType,
    List<TextInputFormatter>? formatter,
    FormFieldSetter<String>? onSaved,
    FormFieldValidator<String>? validator,
  }) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: TextFormField(
        controller: controller,
        keyboardType: inputType,
        inputFormatters: formatter,
        decoration: InputDecoration(
          labelText: label,
          border: OutlineInputBorder(borderRadius: BorderRadius.circular(8)),
          contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 14),
        ),
        validator: validator,
        onSaved: onSaved,
      ),
    );
  }
}
