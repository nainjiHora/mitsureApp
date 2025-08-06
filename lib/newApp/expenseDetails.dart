import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

class ExpenseDetailScreen extends StatelessWidget {
  final Map<String, dynamic> expense;

  ExpenseDetailScreen({required this.expense});

  String formatDate(DateTime date) {
    return DateFormat('dd MMM yyyy').format(date);
  }

  Widget _buildDetailRow({required IconData icon, required String label, required String value}) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 6),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon, color: Colors.indigo[900], size: 20),
          SizedBox(width: 10),
          Expanded(
            child: RichText(
              text: TextSpan(
                style: TextStyle(color: Colors.black87, fontSize: 16),
                children: [
                  TextSpan(
                    text: "$label: ",
                    style: TextStyle(fontWeight: FontWeight.w600),
                  ),
                  TextSpan(
                    text: value,
                    style: TextStyle(fontWeight: FontWeight.w400),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final hasImage = expense['BillLink'] != null && expense['BillLink'].toString().isNotEmpty;

    return Scaffold(
      appBar: AppBar(
        title: Text("Expense Detail", style: TextStyle(color: Colors.white)),
        backgroundColor: Colors.indigo[900],
        iconTheme: IconThemeData(color: Colors.white),
        elevation: 4,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Card(
          elevation: 4,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                if (hasImage)
                  ClipRRect(
                    borderRadius: BorderRadius.circular(12),
                    child: Image.network(
                      "https://mittsureone.com:3001/file/${expense['BillLink']}",
                      height: 200,
                      width: double.infinity,
                      fit: BoxFit.contain,
                    ),
                  ),
                if (hasImage) SizedBox(height: 20),
                _buildDetailRow(
                    icon: Icons.currency_rupee,
                    label: "Amount",
                    value: "₹${expense['Amount']}"),
                _buildDetailRow(
                    icon: Icons.description,
                    label: "Purpose",
                    value: expense['expensePurposeName'] ?? 'N/A'),
                _buildDetailRow(
                    icon: Icons.category,
                    label: "Type",
                    value: expense['expenseTypeName'] ?? 'N/A'),
                _buildDetailRow(
                    icon: Icons.comment,
                    label: "Remarks",
                    value: expense['remarks'] ?? 'N/A'),
                if (expense['schoolName'] != null)
                  _buildDetailRow(
                      icon: Icons.school,
                      label: "School",
                      value: expense['schoolName']),
                if (expense['DistributorName'] != null)
                  _buildDetailRow(
                      icon: Icons.group,
                      label: "Distributor",
                      value: expense['DistributorName']),
                _buildDetailRow(
                    icon: Icons.person,
                    label: "Submitted By",
                    value: expense['name']),
                if (expense['Status'] != '0')
                  _buildDetailRow(
                      icon: Icons.verified_user,
                      label: "${expense['Status']=='1'?'Approved':'Rejected'} By",
                      value: expense['approvedByUser']),

                        if (expense['Status'] == '2')
                  _buildDetailRow(
                      icon: Icons.question_answer_outlined,
                      label: "Reason",
                      value: expense['reason']??" "),
                   
                Divider(height: 30, thickness: 1.2),
                _buildDetailRow(
                    icon: Icons.event,
                    label: "Date",
                    value: formatDate(expense['date'])),
                _buildDetailRow(
                    icon: Icons.access_time,
                    label: "Created At",
                    value: formatDate(expense['createdAt'])),

                    ElevatedButton.icon(
                      
                      onPressed: (){}, label:Text(expense['Status'] == '2'?"Rejected":expense['Status'] == '1'?'Approved':'Pending'),icon: Icon(expense['Status'] == '2'?Icons.no_accounts:expense['Status'] == '1'?Icons.verified:Icons.warning_amber_outlined,color:expense['Status'] == '2'? Colors.orange:expense['Status'] == '1'?Colors.green:Colors.yellow), )
              ],
            ),
          ),
        ),
      ),
    );
  }
}
