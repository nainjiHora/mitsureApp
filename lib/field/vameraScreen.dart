import 'dart:io';
import 'package:flutter/material.dart';
import 'package:camera/camera.dart';
import 'package:google_mlkit_text_recognition/google_mlkit_text_recognition.dart';
import 'package:image_cropper/image_cropper.dart';
import 'package:path_provider/path_provider.dart';

class KMReadingCameraScreen extends StatefulWidget {
  final void Function(String imagePath, String reading) onReadingCaptured;

  const KMReadingCameraScreen({required this.onReadingCaptured});

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
    _cameraController = CameraController(camera, ResolutionPreset.high);
    await _cameraController!.initialize();
    if (mounted) setState(() {});
  }

  Future<void> _takePicture() async {
    if (_cameraController == null || _isProcessing) return;
    final file = await _cameraController!.takePicture();
    setState(() => _capturedImage = File(file.path));
    _showCropConfirmDialog();
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
          initAspectRatio: CropAspectRatioPreset.original,
          lockAspectRatio: false,
        ),
        IOSUiSettings(title: 'Crop KM Area'),
      ],
    );

    if (!mounted) return;

    if (croppedFile != null) {
      // Show confirm/retake dialog
      showDialog(
        context: context,
        builder: (ctx) => AlertDialog(
          title: Text('Use this image?'),
          content: Image.file(File(croppedFile.path)),
          actions: [
            TextButton(
              onPressed: () {
                Navigator.pop(ctx);
                _capturedImage = null;
              },
              child: Text('Retake'),
            ),
            ElevatedButton(
              onPressed: () async {
                Navigator.pop(ctx);
                _processCroppedImage(File(croppedFile.path));
              },
              child: Text('Confirm'),
            ),
          ],
        ),
      );
    } else {
      setState(() => _capturedImage = null);
    }
  }

  String normalizeMeterReading(String input) {
    return input
        .replaceAll(RegExp(r'[iIlL]'), '1')
        .replaceAll(RegExp(r'[oO]'), '0')
        .replaceAll(RegExp(r'[bB]'), '8')
        .replaceAll(RegExp(r'[sS]'), '5')
        .replaceAll(RegExp(r'[eE]'), '3')
        .replaceAll(RegExp(r'[^0-9]'), ''); // remove any remaining non-digits
  }

  Future<void> _processCroppedImage(File imageFile) async {
    setState(() => _isProcessing = true);

    final inputImage = InputImage.fromFile(imageFile);
    final textRecognizer = TextRecognizer(script: TextRecognitionScript.latin);

    try {
      final recognizedText = await textRecognizer.processImage(inputImage);
      setState(() => _isProcessing = false);
      final rawText = recognizedText.text;
      final cleanedText = normalizeMeterReading(rawText);
      _showReadingPopup(cleanedText, imageFile.path);
    } catch (e) {
      setState(() => _isProcessing = false);
      // Handle error here, e.g., show an error popup or log
      print('Error recognizing text: $e');
    } finally {
      await textRecognizer.close();
    }
  }

  void _showReadingPopup(String reading, String imagePath) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text('Detected Reading'),
        content: Text(reading.trim().isEmpty ? 'No text detected.' : reading),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: Text('Close'),
          ),
          ElevatedButton(
            onPressed: () {
              Navigator.pop(ctx);
              widget.onReadingCaptured(imagePath, reading);
            },
            child: Text('Use This'),
          ),
        ],
      ),
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
      return Center(child: CircularProgressIndicator());
    }

    return Scaffold(
      body: Stack(
        children: [
          // Camera preview
          Center(
            child: AspectRatio(
              aspectRatio: _cameraController!.value.aspectRatio,
              child: CameraPreview(_cameraController!),
            ),
          ),
          // Overlay with transparent slip
          Positioned.fill(
            child: CustomPaint(
              painter: SlipOverlayPainter(),
            ),
          ),
          // Capture button
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

    final slipHeight = 80.0; // Height of the visible slip
    final centerY = size.height / 2;
    final topRect = Rect.fromLTRB(0, 0, size.width, centerY - slipHeight / 2);
    final bottomRect =
        Rect.fromLTRB(0, centerY + slipHeight / 2, size.width, size.height);

    // Draw dimmed top and bottom regions
    canvas.drawRect(topRect, paint);
    canvas.drawRect(bottomRect, paint);

    // Draw border around the transparent slip area
    final borderPaint = Paint()
      ..color = Colors.black
      ..style = PaintingStyle.stroke
      ..strokeWidth = 4;

    final borderRect = Rect.fromLTRB(16, centerY - slipHeight / 2,
        size.width - 16, centerY + slipHeight / 2);
    canvas.drawRect(borderRect, borderPaint);
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}
