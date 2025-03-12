import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';
import 'dart:convert';

import 'home.dart';

class LoginScreen extends StatefulWidget {
  @override
  _LoginScreenState createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  final TextEditingController _usernameController = TextEditingController();
  final TextEditingController _passwordController = TextEditingController();
  bool _obscureText = true; // State to toggle password visibility
  bool _rememberMe = false; // State for the "Remember Me" checkbox

  @override
  void initState() {
    super.initState();
    _loadSavedCredentials(); // Load saved credentials on app start
  }

  Future<void> _loadSavedCredentials() async {
    final prefs = await SharedPreferences.getInstance();
    final savedUsername = prefs.getString('savedUsername');
    final savedPassword = prefs.getString('savedPassword');
    final rememberMe = prefs.getBool('rememberMe') ?? false;

    if (rememberMe) {
      setState(() {
        _rememberMe = true;
        _usernameController.text = savedUsername ?? '';
        _passwordController.text = savedPassword ?? '';
      });
    }
  }

  Future<void> _saveCredentials() async {
    final prefs = await SharedPreferences.getInstance();
    if (_rememberMe) {
      await prefs.setString('savedUsername', _usernameController.text);
      await prefs.setString('savedPassword', _passwordController.text);
      await prefs.setBool('rememberMe', true);
    } else {
      await prefs.remove('savedUsername');
      await prefs.remove('savedPassword');
      await prefs.setBool('rememberMe', false);
    }
  }

  // API Call Function
  Future<void> signIn() async {
    final String username = _usernameController.text;
    final String password = _passwordController.text;

    if (username.isEmpty || password.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text("Please enter username and password")),
      );
      return;
    }

    // final String apiUrl = "https://mittsureone.com:3001/user/signin";
    // Replace with your API endpoint
    final String apiUrl = "https://mittsure.qdegrees.com:3001/user/signin";
    try {
      final response = await http.post(
        Uri.parse(apiUrl),
        headers: {"Content-Type": "application/json"},
        body: jsonEncode({
          "username": username,
          "password": password,
        }),
      );

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        if (data['status'] == false) {
          final prefs = await SharedPreferences.getInstance();
          await prefs.setString('user', jsonEncode(data['user']));
          await prefs.setString('Token', data['token']);

          await _saveCredentials(); // Save credentials if "Remember Me" is checked

          Navigator.pushReplacement(
            context,
            MaterialPageRoute(builder: (context) => HomePage()),
          );
        } else {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text(data['message'])),
          );
        }
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text("Login failed. Please try again.")),
        );
      }
    } catch (e) {
      print(e);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text("An error occurred: $e")),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SingleChildScrollView(
        child: Column(
          children: [
            // Top Section with Curved Design
            Container(
              height: 420,
              decoration: const BoxDecoration(
                color: Colors.indigo,
                borderRadius: BorderRadius.only(
                  bottomLeft: Radius.circular(80),
                ),
              ),
              child: Stack(
                alignment: Alignment.center,
                children: [
                  Positioned(
                    top: 80,
                    child: Container(
                      height: 210,
                      width: 210,
                      decoration: const BoxDecoration(
                        shape: BoxShape.circle,
                        color: Colors.white,
                      ),
                      child: Center(
                        child: Image.asset(
                          'assets/images/logo.png',
                          height: 170,
                          width: 170,
                          fit: BoxFit.contain,
                        ),
                      ),
                    ),
                  ),
                  const Positioned(
                    left: 40,
                    bottom: 20,
                    child: RotatedBox(
                      quarterTurns: 3,
                      child: Text(
                        "Sign in",
                        style: TextStyle(
                          fontSize: 50,
                          fontWeight: FontWeight.bold,
                          color: Colors.white54,
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),

            const SizedBox(height: 20),

            const Text(
              "Sign in to continue",
              style: TextStyle(
                color: Colors.black54,
                fontSize: 16,
              ),
            ),

            const SizedBox(height: 40),

            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 30),
              child: Column(
                children: [
                  TextField(
                    controller: _usernameController,
                    decoration: InputDecoration(
                      hintText: "User Name",
                      prefixIcon: Icon(Icons.person),
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                    ),
                  ),
                  const SizedBox(height: 20),
                  TextField(
                    controller: _passwordController,
                    obscureText: _obscureText,
                    decoration: InputDecoration(
                      hintText: "Password",
                      prefixIcon: Icon(Icons.lock),
                      suffixIcon: IconButton(
                        icon: Icon(
                          _obscureText ? Icons.visibility_off : Icons.visibility,
                        ),
                        onPressed: () {
                          setState(() {
                            _obscureText = !_obscureText;
                          });
                        },
                      ),
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                    ),
                  ),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.start,
                    children: [
                      Checkbox(
                        value: _rememberMe,
                        onChanged: (value) {
                          setState(() {
                            _rememberMe = value!;
                          });
                        },
                      ),
                      const Text("Remember Me"),
                    ],
                  ),
                ],
              ),
            ),

            const SizedBox(height: 40),

            GestureDetector(
              onTap: () {
                signIn();
              },
              child: Container(
                height: 60,
                width: 60,
                decoration: BoxDecoration(
                  color: Colors.blueAccent,
                  shape: BoxShape.circle,
                ),
                child: const Icon(
                  Icons.arrow_forward,
                  color: Colors.white,
                  size: 30,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
