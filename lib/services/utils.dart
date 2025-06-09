import 'package:flutter/material.dart';

class DialogUtils {
  static void showCommonPopup({
    required BuildContext context,
    required String message,
    required bool isSuccess,
    VoidCallback? onOkPressed,
  }) {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => Dialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 32),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              // Icon in a circle background
              Container(
                decoration: BoxDecoration(
                  color:
                      isSuccess ? Colors.green.shade100 : Colors.red.shade100,
                  shape: BoxShape.circle,
                ),
                padding: const EdgeInsets.all(16),
                child: Icon(
                  isSuccess ? Icons.check_circle : Icons.error,
                  size: 48,
                  color:
                      isSuccess ? Colors.green.shade700 : Colors.red.shade700,
                ),
              ),
              const SizedBox(height: 20),
              // Message
              Text(
                isSuccess ? "Success!" : "Error!",
                style: TextStyle(
                  fontSize: 20,
                  fontWeight: FontWeight.bold,
                  color:
                      isSuccess ? Colors.green.shade700 : Colors.red.shade700,
                ),
              ),
              const SizedBox(height: 12),
              Text(
                message,
                textAlign: TextAlign.center,
                style: const TextStyle(fontSize: 16, color: Colors.black87),
              ),
              const SizedBox(height: 24),
              // OK button
              ElevatedButton(
                onPressed: () {
                  Navigator.of(context).pop();
                  if (onOkPressed != null) {
                    print("kjkj");
                    onOkPressed(); 
                  }
                },
                style: ElevatedButton.styleFrom(
                  backgroundColor:
                      isSuccess ? Colors.green.shade600 : Colors.red.shade600,
                  padding:
                      const EdgeInsets.symmetric(horizontal: 32, vertical: 12),
                  shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(10)),
                  elevation: 3,
                ),
                child: const Text(
                  'OK',
                  style: TextStyle(fontSize: 16, color: Colors.white),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
