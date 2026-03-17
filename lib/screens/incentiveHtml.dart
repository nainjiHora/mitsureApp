import 'package:flutter/material.dart';
import 'package:flutter_html/flutter_html.dart';

import '../newApp/wbView.dart';
import '../services/apiService.dart';

class IncentiveNew extends StatefulWidget {
  const IncentiveNew({super.key});

  @override
  State<IncentiveNew> createState() => _IncentiveNewState();
}

class _IncentiveNewState extends State<IncentiveNew> {

  String? htmlContent;

  @override
  void initState() {
    super.initState();
    _fetchHtmlFromApi();
  }

  Future<void> _fetchHtmlFromApi() async {
    try {
      final response = await ApiService.post(
        endpoint: '/incentive/getIncentiveHTML',
        body: {"type": "incentive"},
      );

      print(response);

      if (response != null &&
          (response['status'] == true || response['status'] == "true")) {

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

    return Scaffold(
      appBar: AppBar(
        iconTheme: const IconThemeData(color: Colors.white),
        title: const Text(
          'Incentive',
          style: TextStyle(color: Colors.white),
        ),
        backgroundColor: Colors.indigo,
        elevation: 0,
      ),

      body: htmlContent == null
          ? const Center(
        child: CircularProgressIndicator(),
      )
          : SingleChildScrollView(
        child: Html(
          data: htmlContent,
          onAnchorTap: (
              String? url,
              Map<String, String> attributes,
              element,
              ) {
            if (url != null) {
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (context) => InAppWebView(url: url),
                ),
              );
            }
          },
        ),
      ),
    );
  }
}