import 'package:flutter/material.dart';
import 'package:mittsure/newApp/wbView.dart';
import 'package:webview_flutter/webview_flutter.dart';
import 'package:flutter_html/flutter_html.dart';
import 'package:mittsure/services/apiService.dart';
import 'package:url_launcher/url_launcher.dart';

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
        body: {"type": "faq"},
      );

      if (response != null &&
          (response['status'] == true || response['status'] == "true")) {
        setState(() {
          htmlContent = response['data'][0]['name'];
          print(htmlContent);
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
    return Scaffold(
      appBar: AppBar(
        iconTheme: IconThemeData(color: Colors.white),
        title: Text('FAQ', style: TextStyle(color: Colors.white)),
        backgroundColor: Colors.indigo[900],
        elevation: 0,
      ),
      body: htmlContent == null
          ? const Center(child: CircularProgressIndicator())
          : SingleChildScrollView(
              child: Html(
              data: htmlContent,
              onAnchorTap:
                  (String? url, Map<String, String> attributes, element) async {
                if (url != null) {
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (context) => InAppWebView(url: url),
                    ),
                  );
                }
              },
            )),
    );
  }
}
