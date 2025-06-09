
import 'package:flutter/material.dart';
import 'package:permission_handler/permission_handler.dart';

class MeterPunchScreen extends StatefulWidget {
  @override
  _MeterPunchScreenState createState() => _MeterPunchScreenState();
}

class _MeterPunchScreenState extends State<MeterPunchScreen> {
  final _hoursController = TextEditingController();
  final _minutesController = TextEditingController();
  final _startKmController = TextEditingController();
  final _endKmController = TextEditingController();
  final _descriptionController = TextEditingController();

  String? _selectedWorkType;
  final List<String> _workTypes = ['Delivery', 'Maintenance', 'Inspection'];



  Future<void> _requestPermissions() async {

    if (await Permission.camera.isGranted && await Permission.locationWhenInUse.isGranted) {
      // Safe to proceed
    } else {
      Map<Permission, PermissionStatus> statuses = await [
        Permission.camera,
        Permission.locationWhenInUse, // or Permission.location
      ].request();

      if (statuses[Permission.camera]!.isPermanentlyDenied ||
          statuses[Permission.locationWhenInUse]!.isPermanentlyDenied) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
                'Some permissions are permanently denied. Please enable them in settings.'),
            action: SnackBarAction(
              label: 'Settings',
              onPressed: () {
                openAppSettings();
              },
            ),
          ),
        );
      }
    }
  }

  // Future<void> _handlePunch(bool isPunchIn) async {
  //   var status = await Permission.camera.status;

  //   if (status.isDenied || status.isPermanentlyDenied) {
  //     await Permission.camera.request();
  //     status = await Permission.camera.status;

  //     if (status.isPermanentlyDenied) {
  //       ScaffoldMessenger.of(context).showSnackBar(
  //         SnackBar(
  //           content: Text('Camera permission permanently denied. Please enable it from settings.'),
  //           action: SnackBarAction(
  //             label: 'Open Settings',
  //             onPressed: () => openAppSettings(),
  //           ),
  //         ),
  //       );
  //       return;
  //     } else if (!status.isGranted) {
  //       ScaffoldMessenger.of(context).showSnackBar(
  //         SnackBar(content: Text('Camera permission denied')),
  //       );
  //       return;
  //     }
  //   }

  //   final pickedFile = await ImagePicker().pickImage(source: ImageSource.camera);
  //   if (pickedFile == null) return;

  //   final inputImage = InputImage.fromFile(File(pickedFile.path));
  //   final textRecognizer = GoogleMlKit.vision.textRecognizer();
  //   final recognizedText = await textRecognizer.processImage(inputImage);
  //   final text = recognizedText.text;
  //   await textRecognizer.close();

  //   final matches = RegExp(r'\d+').allMatches(text).map((m) => m.group(0)).toList();
  //   if (matches.isNotEmpty) {
  //     final extractedNumber = matches.first;

  //     setState(() {
  //       if (isPunchIn) {
  //         _punchInTime = DateTime.now();
  //         _startKmController.text = extractedNumber!;
  //       } else {
  //         final punchOutTime = DateTime.now();
  //         if (_punchInTime != null) {
  //           final duration = punchOutTime.difference(_punchInTime!);
  //           final totalMinutes = duration.inMinutes;
  //           _hoursController.text = (totalMinutes ~/ 60).toString();
  //           _minutesController.text = (totalMinutes % 60).toString();
  //         }
  //         _endKmController.text = extractedNumber!;
  //       }
  //     });
  //   } else {
  //     ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('No number detected from image')));
  //   }
  // }


  @override
  void initState() {
    // TODO: implement initState
    super.initState();

       _requestPermissions();

  }
  @override
  void dispose() {
    _hoursController.dispose();
    _minutesController.dispose();
    _startKmController.dispose();
    _endKmController.dispose();
    _descriptionController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text("Punch Meter Reading")),
      body: SingleChildScrollView(
        padding: EdgeInsets.all(16),
        child: Column(
          children: [
            Row(
              children: [
                Expanded(
                  child: TextField(
                    controller: _hoursController,
                    readOnly: true,
                    decoration: InputDecoration(labelText: 'Hours'),
                  ),
                ),
                SizedBox(width: 16),
                Expanded(
                  child: TextField(
                    controller: _minutesController,
                    readOnly: true,
                    decoration: InputDecoration(labelText: 'Minutes'),
                  ),
                ),
              ],
            ),
            SizedBox(height: 20),
            // ElevatedButton(
            //   onPressed: () => _handlePunch(true),
            //   child: Text("Punch In"),
            // ),
            SizedBox(height: 10),
            TextField(
              controller: _startKmController,
              readOnly: true,
              decoration: InputDecoration(labelText: 'Start KM (From Image)'),
            ),
            SizedBox(height: 20),
            DropdownButtonFormField<String>(
              value: _selectedWorkType,
              items: _workTypes
                  .map((type) => DropdownMenuItem(
                value: type,
                child: Text(type),
              ))
                  .toList(),
              onChanged: (val) {
                setState(() {
                  _selectedWorkType = val;
                });
              },
              decoration: InputDecoration(labelText: 'Work Type'),
            ),
            SizedBox(height: 10),
            TextField(
              controller: _descriptionController,
              maxLines: 3,
              decoration: InputDecoration(labelText: 'Description'),
            ),
            SizedBox(height: 20),
            // ElevatedButton(
            //   onPressed: () => _handlePunch(false),
            //   child: Text("Punch Out"),
            // ),
            SizedBox(height: 10),
            TextField(
              controller: _endKmController,
              readOnly: true,
              decoration: InputDecoration(labelText: 'End KM (From Image)'),
            ),
          ],
        ),
      ),
    );
  }
}
