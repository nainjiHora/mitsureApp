import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

class PunchDetailsPopup extends StatefulWidget {
  final String meterReading;

  PunchDetailsPopup({required this.meterReading});

  @override
  _PunchDetailsPopupState createState() => _PunchDetailsPopupState();
}

class _PunchDetailsPopupState extends State<PunchDetailsPopup> {
  final _formKey = GlobalKey<FormState>();
  final Map<String, dynamic> _formData = {
    'km': '',
    'worktype': '',
    'remark': '',
    'kmChanged': false,
  };

  late TextEditingController _kmController;
  late String initialKM;

  String? selectedWorkType;

  @override
  void initState() {
    super.initState();
    initialKM = widget.meterReading;
    _kmController = TextEditingController(text: widget.meterReading);
    _kmController.addListener(() {
      _formData['kmChanged'] = _kmController.text.trim() != initialKM.trim();
    });
  }

  @override
  void dispose() {
    _kmController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: Text('Add Punch Details'),
      content: Form(
        key: _formKey,
        child: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              // KM field
              TextFormField(
                controller: _kmController,
                decoration: InputDecoration(labelText: "Meter reading (KM)"),
                keyboardType: TextInputType.number,
                inputFormatters: [
                  FilteringTextInputFormatter.digitsOnly,
                ],
                validator: (val) =>
                val == null || val.isEmpty ? 'Required' : null,
                onSaved: (val) => _formData['km'] = val ?? '',
              ),

              // Work type dropdown
              DropdownButtonFormField<String>(
                value: selectedWorkType,
                decoration: InputDecoration(labelText: "Work Type"),
                items: ['Visit', 'Office'].map((type) {
                  return DropdownMenuItem(
                    value: type,
                    child: Text(type),
                  );
                }).toList(),
                onChanged: (value) {
                  setState(() {
                    selectedWorkType = value;
                  });
                },
                validator: (val) =>
                val == null || val.isEmpty ? 'Please select work type' : null,
                onSaved: (val) => _formData['worktype'] = val ?? '',
              ),

              // Remark (conditionally required)
              TextFormField(
                decoration: InputDecoration(labelText: "Remark"),
                validator: (val) {
                  if (selectedWorkType == 'Office' &&
                      (val == null || val.trim().isEmpty)) {
                    return 'Remark required for Office';
                  }
                  return null;
                },
                onSaved: (val) => _formData['remark'] = val ?? '',
              ),
            ],
          ),
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context, null),
          child: Text("Cancel"),
        ),
        ElevatedButton(
          onPressed: () {
            if (_formKey.currentState!.validate()) {
              _formKey.currentState!.save();
              Navigator.pop(context, _formData);
            }
          },
          child: Text("Save"),
        ),
      ],
    );
  }
}
