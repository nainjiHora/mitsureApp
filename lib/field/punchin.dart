import 'dart:async';
import 'dart:io';
import 'package:flutter/material.dart';
import 'package:geolocator/geolocator.dart';
import 'package:google_mlkit_text_recognition/google_mlkit_text_recognition.dart';
import 'package:image_picker/image_picker.dart';

class PunchScreen extends StatefulWidget {
  @override
  _PunchScreenState createState() => _PunchScreenState();
}

class _PunchScreenState extends State<PunchScreen> {
  bool _isPunchedIn = false;
  bool _isPunchedOut = false;
  DateTime? _punchInTime;
  DateTime? _punchOutTime;
  Duration _workDuration = Duration.zero;

  File? _startImage;
  File? _endImage;

  final TextEditingController _startKmController = TextEditingController();
  final TextEditingController _endKmController = TextEditingController();
  final TextEditingController _descriptionController = TextEditingController();

  String _selectedWorkType = '';
  String? _punchInLatLng;
  String? _punchOutLatLng;

  List<String> workTypes = ["Installation", "Repair", "Maintenance"];

  Future<void> _pickImage(bool isStart) async {
    final pickedFile = await ImagePicker().pickImage(source: ImageSource.camera);
    if (pickedFile != null) {
      File image = File(pickedFile.path);
      String km = await _readTextFromImage(image);
      setState(() {
        if (isStart) {
          _startImage = image;
          _startKmController.text = km;
        } else {
          _endImage = image;
          _endKmController.text = km;
        }
      });
    }
  }

  Future<String> _readTextFromImage(File image) async {
    final inputImage = InputImage.fromFile(image);
    final textRecognizer = TextRecognizer();
    final recognizedText = await textRecognizer.processImage(inputImage);
    String extractedText = recognizedText.text;
    RegExp regExp = RegExp(r'\d{4,6}');
    Match? match = regExp.firstMatch(extractedText);
    return match?.group(0) ?? '';
  }

  Future<String?> _getCurrentLocation() async {
    bool serviceEnabled = await Geolocator.isLocationServiceEnabled();
    if (!serviceEnabled) {
      _showMessage('Location services are disabled.');
      return null;
    }

    LocationPermission permission = await Geolocator.checkPermission();
    if (permission == LocationPermission.deniedForever) {
      _showMessage('Location permission is permanently denied.');
      return null;
    }

    if (permission == LocationPermission.denied) {
      permission = await Geolocator.requestPermission();
      if (permission != LocationPermission.whileInUse &&
          permission != LocationPermission.always) {
        _showMessage('Location permission denied.');
        return null;
      }
    }

    Position position = await Geolocator.getCurrentPosition();
    return "${position.latitude}, ${position.longitude}";
  }

  void _submitPunchIn() async {
    if (_startImage == null ||
        _startKmController.text.isEmpty ||
        _selectedWorkType.isEmpty ||
        _descriptionController.text.isEmpty) {
      _showMessage("Please complete all fields before submitting.");
      return;
    }

    String? location = await _getCurrentLocation();
    if (location == null) return;

    setState(() {
      _punchInTime = DateTime.now();
      _isPunchedIn = true;
      _punchInLatLng = location;
    });

    _showMessage("Punch In Successful at $location");
  }

  void _submitPunchOut() async {
    if (_endImage == null || _endKmController.text.isEmpty) {
      _showMessage("Please capture end meter image.");
      return;
    }

    String? location = await _getCurrentLocation();
    if (location == null) return;

    setState(() {
      _punchOutTime = DateTime.now();
      _workDuration = _punchOutTime!.difference(_punchInTime!);
      _isPunchedOut = true;
      _punchOutLatLng = location;
    });

    _showMessage("Punch Out Successful at $location");
  }

  void _showMessage(String message) {
    
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(message), backgroundColor: Colors.green),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.blueGrey[50],
      appBar: AppBar(
        title: Text('Work Punch'),
        backgroundColor: Colors.teal,
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: SingleChildScrollView(
          child: Column(
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceAround,
                children: [
                  _buildTimeCard("Punch In", _punchInTime),
                  _buildTimeCard("Punch Out", _punchOutTime),
                ],
              ),
              const SizedBox(height: 20),
              !_isPunchedIn ? _buildPunchInForm() : _buildPunchOutForm(),
              if (_punchInLatLng != null)
                Text("Punched In at: $_punchInLatLng", style: TextStyle(color: Colors.teal[700])),
              if (_punchOutLatLng != null)
                Text("Punched Out at: $_punchOutLatLng", style: TextStyle(color: Colors.teal[700])),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildTimeCard(String title, DateTime? time) {
    return Card(
      elevation: 4,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      color: Colors.white,
      child: Container(
        width: 150,
        padding: EdgeInsets.all(16),
        child: Column(
          children: [
            Text(title, style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
            const SizedBox(height: 8),
            Text(time != null ? _formatTime(time) : "00 : 00",
                style: TextStyle(fontSize: 24, color: Colors.teal)),
          ],
        ),
      ),
    );
  }

  String _formatTime(DateTime time) {
    return "${time.hour.toString().padLeft(2, '0')} : ${time.minute.toString().padLeft(2, '0')}";
  }

  Widget _buildPunchInForm() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _buildImagePicker(_startImage, true),
        const SizedBox(height: 10),
        _buildTextField("Start KM", _startKmController),
        const SizedBox(height: 10),
        _buildDropdown(),
        const SizedBox(height: 10),
        _buildTextField("Work Description", _descriptionController, maxLines: 3),
        const SizedBox(height: 20),
        _buildSubmitButton("Submit Punch In", _submitPunchIn),
      ],
    );
  }

  Widget _buildPunchOutForm() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _buildImagePicker(_endImage, false),
        const SizedBox(height: 10),
        _buildTextField("End KM", _endKmController),
        const SizedBox(height: 20),
        _buildSubmitButton("Submit Punch Out", _submitPunchOut),
      ],
    );
  }

  Widget _buildImagePicker(File? image, bool isStart) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        image != null
            ? Image.file(image, height: 200, width: double.infinity, fit: BoxFit.cover)
            : Container(
          height: 200,
          color: Colors.grey[300],
          child: Icon(Icons.camera_alt, size: 100, color: Colors.white),
        ),
        const SizedBox(height: 10),
        Row(
          mainAxisAlignment: MainAxisAlignment.end,
          children: [
            ElevatedButton.icon(
              onPressed: () => _pickImage(isStart),
              icon: Icon(Icons.camera_alt),
              label: Text(image == null ? "Capture Image" : "Retake"),
              style: ElevatedButton.styleFrom(backgroundColor: Colors.teal),
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildTextField(String label, TextEditingController controller, {int maxLines = 1}) {
    return TextField(
      controller: controller,
      maxLines: maxLines,
      decoration: InputDecoration(
        labelText: label,
        border: OutlineInputBorder(borderRadius: BorderRadius.circular(10)),
      ),
    );
  }

  Widget _buildDropdown() {
    return DropdownButtonFormField<String>(
      value: _selectedWorkType.isEmpty ? null : _selectedWorkType,
      items: workTypes
          .map((type) => DropdownMenuItem(value: type, child: Text(type)))
          .toList(),
      onChanged: (value) {
        setState(() {
          _selectedWorkType = value!;
        });
      },
      decoration: InputDecoration(
        labelText: "Work Type",
        border: OutlineInputBorder(borderRadius: BorderRadius.circular(10)),
      ),
    );
  }

  Widget _buildSubmitButton(String text, VoidCallback onPressed) {
    return Center(
      child: ElevatedButton(
        onPressed: onPressed,
        child: Text(text, style: TextStyle(fontSize: 16)),
        style: ElevatedButton.styleFrom(
          padding: EdgeInsets.symmetric(horizontal: 40, vertical: 12),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
          backgroundColor: Colors.green,
        ),
      ),
    );
  }
}