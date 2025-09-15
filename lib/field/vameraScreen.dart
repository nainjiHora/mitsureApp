import 'dart:io';
import 'package:flutter/material.dart';
import 'package:camera/camera.dart';
import 'package:google_mlkit_text_recognition/google_mlkit_text_recognition.dart';
import 'package:image_cropper/image_cropper.dart';
import 'package:mittsure/newApp/bookLoader.dart';

class KMReadingCameraScreen extends StatefulWidget {
  final bool bike;
 final void Function(String imagePath, String reading, bool isManual) onReadingCaptured;

  const KMReadingCameraScreen({
    required this.onReadingCaptured,
    required this.bike,
  });

  @override
  _KMReadingCameraScreenState createState() => _KMReadingCameraScreenState();
}

class _KMReadingCameraScreenState extends State<KMReadingCameraScreen> {
  CameraController? _cameraController;
  List<CameraDescription>? _cameras;
  File? _capturedImage;
  bool _isProcessing = false;

  @override
  void initState() {
    super.initState();

    _initCamera();
  }

  Future<void> _initCamera() async {
    _cameras = await availableCameras();
    final camera = _cameras!
        .firstWhere((cam) => cam.lensDirection == CameraLensDirection.back);
    _cameraController = CameraController(camera, ResolutionPreset.high,enableAudio: false);
    await _cameraController!.initialize();
    if (mounted) setState(() {});
  }

  Future<void> _takePicture() async {
    if (_cameraController == null || _isProcessing) return;
    final file = await _cameraController!.takePicture();
    _capturedImage = File(file.path);

    if (widget.bike) {
      _showCropConfirmDialog();
    } else {
      _showNormalConfirmDialog();
    }
  }

  Future<void> _showCropConfirmDialog() async {
    if (_capturedImage == null) return;

    final croppedFile = await ImageCropper().cropImage(
      sourcePath: _capturedImage!.path,
      aspectRatio: CropAspectRatio(ratioX: 5, ratioY: 2),
      compressFormat: ImageCompressFormat.jpg,
      uiSettings: [
        AndroidUiSettings(
          toolbarTitle: 'Crop KM Area',
          lockAspectRatio: false,
        ),
        IOSUiSettings(title: 'Crop KM Area'),
      ],
    );

    if (!mounted) return;

    if (croppedFile != null) {
      _processCroppedImage(File(croppedFile.path));
    } else {
      setState(() => _capturedImage = null);
    }
  }

  Future<void> _showNormalConfirmDialog() async {
    if (_capturedImage == null) return;

    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text('Use this image?'),
        content: Image.file(_capturedImage!),
        actions: [
          TextButton(
            onPressed: () {
              Navigator.pop(ctx);
              setState(() => _capturedImage = null);
            },
            child: Text('Retake'),
          ),
          ElevatedButton(
            onPressed: () {
              Navigator.pop(ctx);
              widget.onReadingCaptured(_capturedImage!.path, '',false);
            },
            child: Text('Confirm'),
          ),
        ],
      ),
    );
  }

  String normalizeMeterReading(String input) {
    return input
        .replaceAll(RegExp(r'[iIlL]'), '1')
        .replaceAll(RegExp(r'[oO]'), '0')
        .replaceAll(RegExp(r'[bB]'), '8')
        .replaceAll(RegExp(r'[sS]'), '5')
        .replaceAll(RegExp(r'[eE]'), '3')
        .replaceAll(RegExp(r'[^0-9]'), '');
  }

  Future<void> _processCroppedImage(File imageFile) async {
    setState(() => _isProcessing = true);
    final inputImage = InputImage.fromFile(imageFile);
    final textRecognizer = TextRecognizer(script: TextRecognitionScript.latin);

    try {
      final recognizedText = await textRecognizer.processImage(inputImage);
      final rawText = recognizedText.text;
      final cleanedText = normalizeMeterReading(rawText);
      _showReadingPopup(cleanedText, imageFile.path);
    } catch (e) {
      print('Error recognizing text: $e');
      _showReadingPopup('', imageFile.path);
    } finally {
      await textRecognizer.close();
      setState(() => _isProcessing = false);
    }
  }

 void _showReadingPopup(String reading, String imagePath) {
  TextEditingController manualController = TextEditingController();
  bool mandError = false;

  showDialog(
    context: context,
    builder: (ctx) {
      return StatefulBuilder(
        builder: (context, setState) {
          return AlertDialog(
            title: Text('Is this the correct reading?'),
            content: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(reading.trim().isEmpty ? 'No text detected.' : reading),
                SizedBox(height: 12),
                Text("If incorrect, enter manually below:"),
                TextField(
                  controller: manualController,
                  keyboardType: TextInputType.number,
                  decoration: InputDecoration(
                    hintText: 'Enter KM Reading',
                    border: OutlineInputBorder(),
                  ),
                ),
                if (mandError)
                  Padding(
                    padding: const EdgeInsets.only(top: 8.0),
                    child: Text(
                      "Please add Meter Reading as seen in the Picture taken",
                      style: TextStyle(color: Colors.red, fontSize: 15),
                    ),
                  ),
              ],
            ),
            actions: [
              TextButton(
                onPressed: () {
                  Navigator.pop(ctx);
                  setState(() => _capturedImage = null); // this is outer setState
                },
                child: Text('Retake'),
              ),
              ElevatedButton(
                onPressed: () {
                  final manualReading = manualController.text.trim();
                  if (manualReading.isNotEmpty) {
                    Navigator.pop(ctx);
                    widget.onReadingCaptured(imagePath, manualReading, true);
                  } else {
                    
                    setState(() {
                      mandError = true;
                    });
                  }
                },
                child: Text('Confirm'),
              ),
            ],
          );
        },
      );
    },
  );
}

  @override
  void dispose() {
    _cameraController?.dispose();
    super.dispose();
  }



  @override
  Widget build(BuildContext context) {
    if (_cameraController == null || !_cameraController!.value.isInitialized) {
      return Center(child: BookPageLoader());
    }

    return Scaffold(
      body: Stack(
        children: [
          Center(
            child: AspectRatio(
              aspectRatio: _cameraController!.value.aspectRatio,
              child: CameraPreview(_cameraController!),
            ),
          ),
          if (widget.bike)
            Positioned.fill(
              child: CustomPaint(
                painter: SlipOverlayPainter(),
              ),
            ),
          Positioned(
            bottom: 30,
            left: 0,
            right: 0,
            child: Center(
              child: ElevatedButton.icon(
                onPressed: _takePicture,
                icon: Icon(Icons.camera),
                label: Text('Capture'),
                style: ElevatedButton.styleFrom(
                  padding: EdgeInsets.symmetric(horizontal: 24, vertical: 12),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class SlipOverlayPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()..color = Colors.black.withOpacity(0.6);
    final slipHeight = 80.0;
    final centerY = size.height / 2;
    final topRect = Rect.fromLTRB(0, 0, size.width, centerY - slipHeight / 2);
    final bottomRect =
        Rect.fromLTRB(0, centerY + slipHeight / 2, size.width, size.height);

    canvas.drawRect(topRect, paint);
    canvas.drawRect(bottomRect, paint);

    final borderPaint = Paint()
      ..color = Colors.black
      ..style = PaintingStyle.stroke
      ..strokeWidth = 4;

    final borderRect = Rect.fromLTRB(
        16, centerY - slipHeight / 2, size.width - 16, centerY + slipHeight / 2);
    canvas.drawRect(borderRect, borderPaint);
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}
