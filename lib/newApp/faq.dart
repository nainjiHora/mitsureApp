import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:flutter_html/flutter_html.dart';
import 'package:mittsure/services/apiService.dart';

class FAQScreen extends StatefulWidget {
  const FAQScreen({Key? key}) : super(key: key);

  @override
  State<FAQScreen> createState() => _FAQScreenState();
}

class _FAQScreenState extends State<FAQScreen> {
  String? htmlContent;

  @override
  void initState() {
    super.initState();
    _fetchHtmlFromApi();
  }

  Future<void> _fetchHtmlFromApi() async {
    try {
      final response = await ApiService.post(
        endpoint: '/picklist/getFAQ', // Use your API endpoint
        body: {"type":"faq"},
      );

 
      if (response != null && (response['status'] == true||response['status'] == "true")) {
        setState(() {
          htmlContent = response['data'][0]['name'];
          
        });
      } else {
        setState(() {
          htmlContent = "<h3 style='color:red'>Failed to load HTML</h3>";
        });
      }
    } catch (e) {
      setState(() {
        htmlContent = "<h3 style='color:red'>Error: $e</h3>";
      });
    }
  }



  @override
  Widget build(BuildContext context) {
    return  Scaffold(
        
        appBar: AppBar(
          iconTheme: IconThemeData(color: Colors.white),
          title: Text('FAQ', style: TextStyle(color: Colors.white)),
          backgroundColor: Colors.indigo[900],
          elevation: 0,
        ),
        body: htmlContent == null
          ? const Center(child: CircularProgressIndicator())
          : SingleChildScrollView(
              child: Html(data: htmlContent),
            ),
    );
  }
}
