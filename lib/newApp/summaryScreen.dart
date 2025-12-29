import 'dart:convert';

import 'package:flutter/material.dart';
class VisitSummaryScreen extends StatelessWidget {
  final Map<String, dynamic> data;
  final submit;
  final cont;

  const VisitSummaryScreen({super.key, required this.cont,required this.data,required this.submit});

  @override
  Widget build(BuildContext context) {
    print(data);
    return Scaffold(
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            Expanded(
              child: SingleChildScrollView(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [

                    const Text(
                      "Basic Information",
                      style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                    ),
                    const Divider(),

                    summaryRow("Contact Person Name", data["contactPerson"]),
                    summaryRow("Contact Person Phone", data["phoneNumber"]),
                    // summaryRow("Alt Phone", data["phoneNumber"]),
                    summaryRow("Meeting happen", data["decisionMaker"]),
                    // summaryRow("Party Type", data["partyType"]),

                    const SizedBox(height: 16),
                    const Text(
                      "Visit Details",
                      style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                    ),
                    const Divider(),

                    summaryRow("Further Visit Required", jsonDecode(data["furtherVisitRequired"])["visit_required"].toString().toLowerCase()=='true'?"Yes":"No"),
                    summaryRow("Work Done", data["workDone"]),
                    // summaryRow("Feedback", data["feedback"]),
                    // summaryRow("Remark", data["remark"]),
                    // summaryRow("Visit End Remark", data["vistEndRemark"]),

                    const SizedBox(height: 16),
                    const Text(
                      "Follow Up",
                      style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                    ),
                    const Divider(),

                    summaryRow(
                      "Follow Up Required",
                      data["follow_up_required"]==true|| data["follow_up_required"]=="true" ? "Yes" : "No",
                    ),
                    if(data["follow_up_required"]==true|| data["follow_up_required"]=="true" )
                    summaryRow(
                      "Follow Up Date",
                      new DateTime.fromMillisecondsSinceEpoch((double.parse(data["followUpDate"])*1000).toInt()).toString().substring(0,11)
                      // Date.(data["followUpDate"]),
                    ),
                    summaryRow(
                        "Follow Up Remark",
                        data['remark']
                    ),

                    const SizedBox(height: 16),
                    const Text(
                      "Distributor",
                      style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                    ),
                    const Divider(),

                    summaryRow(
                      "Distributor ID",
                      jsonDecode(data["preferred_distributor"])?["id"],
                    ),
                    summaryRow(
                      "Distributor Name",
                      jsonDecode(data["preferred_distributor"])?["name"],
                    ),

                    const SizedBox(height: 16),
                    const Text(
                      "HO Requirement",
                      style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                    ),
                    const Divider(),

                    summaryRow(
                      "HO Needed",
                      data["ho_need"]==true||data["ho_need"]=="true" ? "Yes" : "No",
                    ),
                    summaryRow(
                      "HO Remark",
                      data["ho_need_remark"],
                    ),
                    // const Text(
                    //   "Remarks",
                    //   style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                    // ),
                    // const Divider(),
                    //
                    // summaryRow(
                    //   "Start Remark",
                    //   data["remark"],
                    // ),
                    // summaryRow(
                    //   "End Remark",
                    //   data["visitEndRemark"],
                    // ),
                    const Text(
                      "OTHERS",
                      style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                    ),
                    const Divider(),

                    summaryRow(
                      "Mittstore Account Needed",
                      jsonDecode(data['mittstoreAccountNeeded'])['account_needed'].toString().toLowerCase()=='false'?"No":"Yes"
                    ),
                  ],
                ),
              ),
            ),

            // SUBMIT BUTTON
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.green, // 👈 green background
                  foregroundColor: Colors.white, // 👈 text color
                  padding: const EdgeInsets.symmetric(vertical: 14),
                ),
                onPressed: () {
                  submit(cont,true);
                },
                child: const Text("Submit"),
              ),
            ),

          ],
        ),
      ),
    );
  }
}

Widget summaryRow(String label, dynamic value) {
  return Padding(
    padding: const EdgeInsets.symmetric(vertical: 6),
    child: Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        SizedBox(
          width: 150,
          child: Text(
            label,
            style: const TextStyle(fontWeight: FontWeight.w600),
          ),
        ),
        Expanded(
          child: Text(
            value?.toString().isNotEmpty == true ? value.toString() : "-",
          ),
        ),
      ],
    ),
  );
}

