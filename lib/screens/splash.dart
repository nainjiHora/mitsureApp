import 'dart:async';

import 'package:flutter/material.dart';
import 'package:mittsure/newApp/MainMenuScreen.dart';
import 'package:mittsure/screens/home.dart';
import 'package:mittsure/screens/login.dart';
import 'package:mittsure/screens/mainMenu.dart';

import 'package:shared_preferences/shared_preferences.dart';



class SplashScreen extends StatefulWidget {
  const SplashScreen({super.key});

  @override
  State<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends State<SplashScreen>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _animation;

  @override
  void initState() {
    super.initState();

    _controller = AnimationController(
      duration: const Duration(seconds: 3),
      vsync: this,
    );

    _animation = CurvedAnimation(
      parent: _controller,
      curve: Curves.easeOutBack,
    );

    _controller.addListener(() {
      setState(() {});
    });

    _controller.forward();
    Timer(const Duration(seconds: 3), () {
      if (mounted) {
        _checkForExistingSession();
      }
    });

  }



  Future<void> _checkForExistingSession() async {
    final prefs = await SharedPreferences.getInstance();
    final hasData = prefs.getString('user') != null;

    if (hasData) {
      Navigator.pushReplacement(
        context,
        MaterialPageRoute(builder: (context) => MainMenuScreen()), // Route to HomePage
      );
    } else {
      Navigator.pushReplacement(
        context,
        MaterialPageRoute(builder: (context) => LoginScreen()), // Route to HomePage
      );
    }
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Container(
        color: Colors.white,
        child: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Image.asset(
                'assets/images/logo.png',
                height: 200.0,
              ),
              const SizedBox(height: 20.0),
              const Text(
                'All in One',
                textAlign: TextAlign.center,
                style: TextStyle(

                  fontSize: 20.0,
                  color: Colors.white,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
