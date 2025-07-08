import 'dart:io';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:mittsure/services/utils.dart';

class ReviewExpenseScreen extends StatelessWidget {
  final DateTime date;
  final String expenseType;
  final String expensePurpose;
  final String partyType;
  final String party;
  final String remark;
  final String purposeremark;
  final String typeRemark;
  final String amount;
  // final File file;
  final types;
  final purposes;
  final onsubmit;
  final subType;
  final subTypeRemark;

  const ReviewExpenseScreen({
    
    super.key,
    required this.onsubmit,
    required this.subType,
    required this.subTypeRemark,
    required this.date,
    required this.purposes,
    required this.types,
    required this.expenseType,
    required this.expensePurpose,
    required this.partyType,
    required this.party,
    required this.remark,
    required this.purposeremark,
    required this.typeRemark,
    required this.amount,
    // required this.file,
  });

  String getTypeName(id) {
    var a = types.where((element) => element['expenseTypeId'] == expenseType).toList();
    return a.isEmpty ? "" : a[0]['expenseTypeName'];
  }

  String getpurposeName(id) {
    var a = purposes.where((element) => element['expensePurposeId'] == expensePurpose).toList();
    return a.isEmpty ? "" : a[0]['expensePurposeName'];
  }

  Future<void> submitExpense(BuildContext context) async {
   onsubmit();
  }

  bool _isImage(String path) {
    final ext = path.toLowerCase();
    return ext.endsWith('.png') ||
        ext.endsWith('.jpg') ||
        ext.endsWith('.jpeg') ||
        ext.endsWith('.gif') ||
        ext.endsWith('.bmp') ||
        ext.endsWith('.webp');
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      
      backgroundColor: Colors.grey.shade100,
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Card(
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
          elevation: 4,
          child: Padding(
            padding: const EdgeInsets.all(20),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _sectionTitle("Basic Info"),
                _buildRow("Date", DateFormat('dd MMM yyyy').format(date)),
                _buildRow("Expense Type", getTypeName(expenseType)),
                if (typeRemark.trim().isNotEmpty)
                  _buildRow("Type Remark", typeRemark),
                _buildRow("Expense Purpose", getpurposeName(expensePurpose)),
                if (purposeremark.trim().isNotEmpty)
                  _buildRow("Purpose Remark", purposeremark),
                const Divider(height: 30),

                _sectionTitle("Party Details"),
                _buildRow("Party Type", partyType),
                _buildRow("Party", party),
                _buildRow("Remark", remark),
                const Divider(height: 30),

                _sectionTitle("Amount"),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
                  decoration: BoxDecoration(
                    color: Colors.green.shade100,
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Text(
                    "₹ $amount",
                    style: TextStyle(
                      fontWeight: FontWeight.bold,
                      fontSize: 18,
                      color: Colors.green.shade800,
                    ),
                  ),
                ),

                const SizedBox(height: 24),
                _sectionTitle("Attached File"),
                const SizedBox(height: 10),
                // ClipRRect(
                //   borderRadius: BorderRadius.circular(12),
                //   child: _isImage(file.path)
                //       ? Image.file(
                //           file,
                //           height: 200,
                //           width: double.infinity,
                //           fit: BoxFit.cover,
                //         )
                //       : Container(
                //           height: 100,
                //           width: double.infinity,
                //           color: Colors.grey.shade200,
                //           child: Center(
                //             child: Row(
                //               mainAxisSize: MainAxisSize.min,
                //               children: [
                //                 const Icon(Icons.insert_drive_file, color: Colors.grey),
                //                 const SizedBox(width: 8),
                //                 Text(
                //                   file.path.split('/').last,
                //                   style: const TextStyle(color: Colors.black54),
                //                 ),
                //               ],
                //             ),
                //           ),
                //         ),
                // ),
                const SizedBox(height: 30),

                Center(
                  child: ElevatedButton.icon(
                    onPressed: () => submitExpense(context),
                    icon: const Icon(Icons.check_circle_outline,color: Colors.white,),
                    label: const Text("Submit Expense", style: TextStyle(fontSize: 16,color: Colors.white)),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.green.shade600,
                      padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 16),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(30)),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _sectionTitle(String title) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 10),
      child: Text(
        title,
        style: const TextStyle(
          fontSize: 18,
          fontWeight: FontWeight.w600,
          color: Colors.black87,
        ),
      ),
    );
  }

  Widget _buildRow(String title, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 6.0),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            "$title: ",
            style: const TextStyle(fontWeight: FontWeight.w600, color: Colors.black87),
          ),
          Expanded(
            child: Text(
              value,
              style: const TextStyle(color: Colors.black87),
            ),
          ),
        ],
      ),
    );
  }
}
