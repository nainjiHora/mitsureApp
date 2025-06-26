import 'dart:io';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:intl/intl.dart';

class ReviewExpenseScreen extends StatelessWidget {
  final DateTime date;
  final String expenseType, expensePurpose, partyType, party, remark, amount;
  final File file;

  const ReviewExpenseScreen({
    required this.date,
    required this.expenseType,
    required this.expensePurpose,
    required this.partyType,
    required this.party,
    required this.remark,
    required this.amount,
    required this.file,
  });

  Future<void> submitExpense(BuildContext context) async {
    final uri = Uri.parse('https://your-api-endpoint.com/submitExpense');
    var request = http.MultipartRequest('POST', uri);

    request.fields['date'] = DateFormat('yyyy-MM-dd').format(date);
    request.fields['expenseType'] = expenseType;
    request.fields['expensePurpose'] = expensePurpose;
    request.fields['partyType'] = partyType;
    request.fields['party'] = party;
    request.fields['amount'] = amount;
    request.fields['remark'] = remark;

    request.files.add(await http.MultipartFile.fromPath('billFile', file.path));

    var response = await request.send();

    if (response.statusCode == 200) {
      ScaffoldMessenger.of(context)
          .showSnackBar(SnackBar(content: Text("Expense submitted successfully.")));
      Navigator.popUntil(context, (route) => route.isFirst);
    } else {
      ScaffoldMessenger.of(context)
          .showSnackBar(SnackBar(content: Text("Submission failed.")));
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text("Review Expense"),
        backgroundColor: Colors.indigo,
      ),
      body: Padding(
        padding: EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text("Date: ${DateFormat('dd MMM yyyy').format(date)}"),
            Text("Expense Type: $expenseType"),
            Text("Expense Purpose: $expensePurpose"),
            Text("Amount: ₹ $amount"),
            Text("Party Type: $partyType"),
            Text("Party: $party"),
            Text("Remark: $remark"),
            Text("File: ${file.path.split('/').last}"),

            SizedBox(height: 20),
            Center(
              child: ElevatedButton(
                onPressed: () => submitExpense(context),
                child: Text("Submit"),
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.green,
                  padding: EdgeInsets.symmetric(horizontal: 24, vertical: 14),
                ),
              ),
            )
          ],
        ),
      ),
    );
  }
}
