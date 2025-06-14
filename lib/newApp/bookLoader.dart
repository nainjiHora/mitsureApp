import 'package:flutter/material.dart';
import 'package:lottie/lottie.dart';

class BookPageLoader extends StatelessWidget {
  final String message;

  const BookPageLoader({super.key, this.message = 'Loading your books...'});

  @override
  Widget build(BuildContext context) {
    return Container(
      color: Colors.white.withOpacity(0.9),
      child: Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            SizedBox(
              width: 150,
              height: 150,
              child: Lottie.asset('assets/images/loader.json'),
            ),
            const SizedBox(height: 16),
            Text(
              message,
              style: const TextStyle(fontSize: 16, color: Colors.white),
            ),
          ],
        ),
      ),
    );
  }
}
