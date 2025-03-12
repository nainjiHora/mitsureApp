import 'dart:convert';
import 'dart:io';
import 'package:flutter/material.dart';
import 'package:file_picker/file_picker.dart';
import 'package:http/http.dart' as http;

class FileUploadScreen extends StatefulWidget {
  final Function saveFiles;

  FileUploadScreen({required this.saveFiles});

  @override
  _FileUploadScreenState createState() => _FileUploadScreenState();
}

class _FileUploadScreenState extends State<FileUploadScreen> {
  List<File> selectedFiles = [];

  // Function to pick multiple files
  Future<void> pickFiles() async {
    FilePickerResult? result = await FilePicker.platform.pickFiles(
      type: FileType.custom,
      allowedExtensions: ['jpg', 'png', 'pdf', 'doc', 'docx'],
      allowMultiple: true,
    );

    if (result != null) {
      setState(() {
        selectedFiles.addAll(result.paths.map((path) => File(path!)).toList());
      });
    }
  }

  // Function to upload files to the API
  Future<void> uploadFiles() async {
    if (selectedFiles.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text("Please select files before submitting.")),
      );
      return;
    }

    var request = http.MultipartRequest(
      'POST',
      Uri.parse('https://mittsure.qdegrees.com:3001/user/uploadMultipleImages'),
      // Uri.parse('https://mittsureone.com:3001/user/uploadMultipleImages'),
    );

    for (var file in selectedFiles) {
      request.files.add(
        await http.MultipartFile.fromPath(
          'files', // Key name for the array in the API
          file.path,
        ),
      );
    }

    var response = await request.send();

    if (response.statusCode == 200) {
      String responseBody = await response.stream.bytesToString();

      var jsonResponse = jsonDecode(responseBody);
      widget.saveFiles(false, jsonResponse['files']);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text("Files uploaded successfully!")),
      );
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text("Failed to upload files.")),
      );
    }
  }

  // Function to determine the file icon based on its type
  Widget getFileIcon(String fileName) {
    if (fileName.endsWith('.jpg') || fileName.endsWith('.png')) {
      return Icon(Icons.image, size: 40, color: Colors.blue);
    } else if (fileName.endsWith('.pdf')) {
      return Icon(Icons.picture_as_pdf, size: 40, color: Colors.red);
    } else if (fileName.endsWith('.doc') || fileName.endsWith('.docx')) {
      return Icon(Icons.description, size: 40, color: Colors.green);
    } else {
      return Icon(Icons.insert_drive_file, size: 40, color: Colors.grey);
    }
  }

  // Function to show a confirmation dialog for file deletion
  Future<void> showDeleteConfirmation(int index) async {
    bool? confirmDelete = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: Text("Delete File"),
        content: Text("Are you sure you want to delete this file?"),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false), // Cancel
            child: Text("Cancel"),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context, true), // Confirm
            child: Text("Delete"),
          ),
        ],
      ),
    );

    if (confirmDelete == true) {
      setState(() {
        selectedFiles.removeAt(index);
      });
    }
  }

  // Function to handle the back button press
  Future<bool> handleBack() async {
    widget.saveFiles(false, []);
    return true; // Allow the default back action
  }

  @override
  Widget build(BuildContext context) {
    return WillPopScope(
      onWillPop: handleBack,
      child: Scaffold(

        body: Padding(
          padding: const EdgeInsets.all(16.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              ElevatedButton.icon(
                onPressed: pickFiles,
                icon: Icon(Icons.upload_file),
                label: Text("Select Files"),
                style: ElevatedButton.styleFrom(
                  padding: EdgeInsets.symmetric(horizontal: 20, vertical: 12),
                  textStyle: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                ),
              ),
              SizedBox(height: 20),
              Expanded(
                child: selectedFiles.isEmpty
                    ? Center(
                  child: Text(
                    "No files selected.",
                    style: TextStyle(fontSize: 16, color: Colors.grey),
                  ),
                )
                    : GridView.builder(
                  gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                    crossAxisCount: 2,
                    crossAxisSpacing: 10,
                    mainAxisSpacing: 10,
                  ),
                  itemCount: selectedFiles.length,
                  itemBuilder: (context, index) {
                    File file = selectedFiles[index];
                    return Card(
                      elevation: 4,
                      child: Stack(
                        children: [
                          Column(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              getFileIcon(file.path),
                              SizedBox(height: 8),
                              Text(
                                file.path.split('/').last,
                                textAlign: TextAlign.center,
                                overflow: TextOverflow.ellipsis,
                                maxLines: 2,
                                style: TextStyle(fontSize: 14),
                              ),
                            ],
                          ),
                          Positioned(
                            top: 5,
                            right: 5,
                            child: IconButton(
                              icon: Icon(Icons.delete, color: Colors.red),
                              onPressed: () => showDeleteConfirmation(index),
                            ),
                          ),
                        ],
                      ),
                    );
                  },
                ),
              ),
              SizedBox(height: 20),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                children: [
                  ElevatedButton(
                    onPressed: uploadFiles,
                    child: Text("Submit"),
                    style: ElevatedButton.styleFrom(
                      padding: EdgeInsets.symmetric(horizontal: 24, vertical: 12),
                    ),
                  ),
                  OutlinedButton(
                    onPressed: () {
                      widget.saveFiles(false, []);
                      Navigator.pop(context);
                    },
                    child: Text("Cancel"),
                    style: OutlinedButton.styleFrom(
                      padding: EdgeInsets.symmetric(horizontal: 24, vertical: 12),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}
