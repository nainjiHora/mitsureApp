import 'dart:async';
import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:mittsure/newApp/MainMenuScreen.dart';
import 'package:mittsure/services/apiService.dart';
import 'package:mittsure/services/utils.dart';
import 'package:shared_preferences/shared_preferences.dart';

class HoInterventionScreen extends StatefulWidget {
  final payload;
  final answers;

  HoInterventionScreen({required this.payload, this.answers});

  @override
  _HoInterventionScreenState createState() => _HoInterventionScreenState();
}

class _HoInterventionScreenState extends State<HoInterventionScreen> {
  bool hoInterventionNeeded = false;
  String selectedOption = 'Party';
  final TextEditingController otherNumberController = TextEditingController();
  final TextEditingController otpController = TextEditingController();
  bool isLoading = false;

  Timer? _otpTimer;
  int _remainingSeconds = 30;
  bool _canResendOtp = false;

  Future<void> _submitRequest() async {
    setState(() {
      isLoading = true;
    });

    final uri = Uri.parse('https://mittsure.qdegrees.com:3001/visit/endVisit');
    var request = http.MultipartRequest('POST', uri);

    widget.payload.fields.forEach((key, value) {
      request.fields[key] = value;
    });

    request.fields['otp_number'] = selectedOption == 'Other'
        ? otherNumberController.text
        : widget.payload.fields['phone'];
    request.fields['ho_need'] = hoInterventionNeeded.toString();
    request.fields['noVisitCount'] = '0';
    request.fields['tentativeAmount'] = '0';
    request.fields['product_category'] = jsonEncode(widget.answers);

    print(request.fields);
    print("paydata");
    

    try {
      final response = await request.send();
      var respons = await http.Response.fromStream(response);
      final res = jsonDecode(respons.body);

      if (response.statusCode >= 200 &&
          response.statusCode < 300 &&
          res['status'] == false) {
        _sendOtp();
      } else {
        setState(() {
          isLoading = false;
        });
        DialogUtils.showCommonPopup(
            context: context, message: res['message'], isSuccess: false);
      }
    } catch (e) {
      setState(() {
        isLoading = false;
      });
      DialogUtils.showCommonPopup(
          context: context, message: "Something went wrong", isSuccess: false);
    }
  }

  Future<void> _sendOtp() async {
    final prefs = await SharedPreferences.getInstance();
    final t = await prefs.getString('user');
    var id = "";
    if (t != null) {
      id = jsonDecode(t)['id'];
    }

    var body = {
      "mobile": selectedOption == 'Other'
          ? otherNumberController.text
          : widget.payload.fields['phone'],
      "token": id
    };

    try {
      final response = await ApiService.post(
        endpoint: '/user/sendOtp',
        body: body,
      );
      if (response != null && response['status'] == false) {
        setState(() {
          isLoading = false;
        });
        _startOtpTimer();
        _showOtpDialog();
      } else {
        DialogUtils.showCommonPopup(
            context: context, message: response["message"], isSuccess: false);
      }
    } catch (error) {
      DialogUtils.showCommonPopup(
          context: context,
          message: "Failed to send OTP. Please try again.",
          isSuccess: false);
    }
  }

  void _startOtpTimer() {
    _remainingSeconds = 30;
    _canResendOtp = false;
    _otpTimer?.cancel();

    _otpTimer = Timer.periodic(Duration(seconds: 1), (timer) {
      setState(() {
        if (_remainingSeconds > 0) {
          _remainingSeconds--;
        } else {
          _canResendOtp = true;
          _otpTimer?.cancel();
        }
      });
    });
  }

  Future<void> _submitOtp() async {
    setState(() {
      isLoading = true;
    });

    var body = {
      "mobile": selectedOption == 'Other'
          ? otherNumberController.text
          : widget.payload.fields['phone'],
      "otp": otpController.text,
      "visitId": widget.payload.fields['id']
    };

    try {
      final response = await ApiService.post(
        endpoint: '/visit/verifyOtpForVisit',
        body: body,
      );

      if (response != null && response['status'] == false) {
        Navigator.pushAndRemoveUntil(
          context,
          MaterialPageRoute(builder: (context) => MainMenuScreen()),
          (route) => false,
        );
      } else {
        DialogUtils.showCommonPopup(
            context: context,
            message: "Incorrect OTP. Please try again.",
            isSuccess: false);
      }
    } catch (error) {
      DialogUtils.showCommonPopup(
          context: context,
          message: "Failed to verify OTP. Please try again.",
          isSuccess: false);
    } finally {
      setState(() {
        isLoading = false;
      });
    }
  }

  void _showOtpDialog() {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (_) => WillPopScope(
        onWillPop: () async => false,
        child: StatefulBuilder(
          builder: (context, setState) => AlertDialog(
            title: Text("Enter OTP"),
            content: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                TextField(
                  controller: otpController,
                  maxLength: 6,
                  keyboardType: TextInputType.number,
                  decoration: InputDecoration(hintText: "Enter 6-digit OTP"),
                ),
                SizedBox(height: 10),
                if (!_canResendOtp)
                  Text("Resend OTP in $_remainingSeconds seconds"),
                if (_canResendOtp)
                  TextButton(
                    onPressed: () {
                      Navigator.of(context).pop(); // close current dialog
                      _sendOtp(); // re-send OTP and reopen dialog
                    },
                    child: Text("Resend OTP"),
                  ),
              ],
            ),
            actions: [
              ElevatedButton(
                onPressed: () {
                  if (otpController.text.length == 6) {
                    _submitOtp();
                  } else {
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(content: Text("Please enter a valid 6-digit OTP")),
                    );
                  }
                },
                child: Text("Submit"),
              ),
            ],
          ),
        ),
      ),
    );
  }

  @override
  void dispose() {
    _otpTimer?.cancel();
    otherNumberController.dispose();
    otpController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text("HO Intervention")),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          children: [
            CheckboxListTile(
              title: Text("HO Intervention Needed"),
              value: hoInterventionNeeded,
              onChanged: (value) {
                setState(() {
                  hoInterventionNeeded = value!;
                });
              },
            ),
            Text("Otp Mode", style: TextStyle(fontSize: 20)),
            ListTile(
              title: Text('Party'),
              leading: Radio(
                value: 'Party',
                groupValue: selectedOption,
                onChanged: (value) {
                  setState(() => selectedOption = value.toString());
                },
              ),
            ),
            ListTile(
              title: Text('Other'),
              leading: Radio(
                value: 'Other',
                groupValue: selectedOption,
                onChanged: (value) {
                  setState(() => selectedOption = value.toString());
                },
              ),
            ),
            if (selectedOption == 'Other')
              TextField(
                controller: otherNumberController,
                keyboardType: TextInputType.phone,
                decoration: InputDecoration(labelText: "Enter phone number"),
              ),
            Spacer(),
            ElevatedButton(
              onPressed: isLoading
                  ?null
                  : () {
                      if (selectedOption == 'Other' &&
                          otherNumberController.text.isEmpty) {
                        ScaffoldMessenger.of(context).showSnackBar(
                          SnackBar(content: Text("Please enter the number")),
                        );
                      } else {
                        _submitRequest();
                      }
                    },
              child: isLoading
                  ? CircularProgressIndicator(
                      valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                    )
                  : Text("Submit"),
              style: ElevatedButton.styleFrom(
                minimumSize: Size.fromHeight(50),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
