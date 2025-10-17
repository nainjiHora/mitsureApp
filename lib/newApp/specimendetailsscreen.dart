import 'package:flutter/material.dart';
import 'package:mittsure/newApp/specimenList.dart';
import 'package:mittsure/services/apiService.dart';
import 'package:mittsure/services/utils.dart';

class SpecimenDetailsScreen extends StatefulWidget {
  final Map<String, dynamic> specimenDetails;
  final tab;

  const SpecimenDetailsScreen({Key? key, required this.specimenDetails,required this.tab}) : super(key: key);

  @override
  State<SpecimenDetailsScreen> createState() => _SpecimenDetailsScreenState();
}

class _SpecimenDetailsScreenState extends State<SpecimenDetailsScreen> {

  bool isLoading=false;
  Widget infoRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 150,
            child: Text(
              "$label:",
              style: const TextStyle(
                  fontWeight: FontWeight.bold, color: Colors.black87),
            ),
          ),
          Expanded(
            child: Text(
              value,
              style: const TextStyle(color: Colors.black54),
            ),
          ),
        ],
      ),
    );
  }

  void _showActionDialog(BuildContext context, String action,String allotQ) {
    final _quantityController = TextEditingController();
    final _allotedquantityController = TextEditingController(text: allotQ);
    final _remarkController = TextEditingController();

    showDialog(
      context: context,
      builder: (_) => AlertDialog(
        title: Text(widget.specimenDetails['nameSku']?.toString() ?? ''),
        content: SingleChildScrollView(
          child: Column(
            children: [
              TextField(
                controller: _allotedquantityController,
                keyboardType: TextInputType.number,
                readOnly: true,
                decoration: const InputDecoration(
                  labelText: " Alloted Quantity",
                  border: OutlineInputBorder(),
                ),
              ),
              TextField(
                controller: _quantityController,
                keyboardType: TextInputType.number,
                decoration: const InputDecoration(
                  labelText: "Quantity",
                  border: OutlineInputBorder(),
                ),
              ),
              const SizedBox(height: 12),
              TextField(
                controller: _remarkController,
                maxLines: 3,
                decoration: const InputDecoration(
                  labelText: "Remark",
                  border: OutlineInputBorder(),
                ),
              ),
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text("Cancel"),
          ),
          ElevatedButton(
            onPressed: () {
              final quantity = _quantityController.text;
              final remark = _remarkController.text;

              if (quantity.isEmpty) {
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text("Quantity is required")),
                );
                return;
              }

              // Call your API here
              _submitAction(action, quantity, remark);

              Navigator.pop(context);
            },
            child: const Text("Submit"),
          ),
        ],
      ),
    );
  }

  void _submitAction(String action, String quantity, String remark) async{




    setState(() => isLoading = true);



    Map<String, dynamic> body = {
      "id": widget.specimenDetails['id'],
      "is_accept": action,
      "action_remark": remark,
      "accepted_quantity": quantity,

    };
    print(body);
    try {
      final response = await ApiService.post(
        endpoint: '/specimen/acceptedSpecimenToUser',
        body: body,
      );

      if (response != null && response['success'] == true
      ) {
        DialogUtils.showCommonPopup(context: context, message: response['message'], isSuccess: true,onOkPressed: (){
          Navigator.pushReplacement(
              context,
              MaterialPageRoute(
                  builder: (context) => SpecimenScreen(tab:widget.tab))
          );
        });
      } else {
DialogUtils.showCommonPopup(context: context, message: response['message'], isSuccess: false);
      }
    } catch (error) {
      print("Error fetching visits: $error");
      DialogUtils.showCommonPopup(context: context, message: "Something Went Wrong", isSuccess: false);
    } finally {
      setState(() => isLoading = false);
    }

  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        backgroundColor: Colors.indigo[900],
        iconTheme: const IconThemeData(color: Colors.white),
        title: const Text(
          "Specimen Details",
          style: TextStyle(color: Colors.white, fontSize: 20),
        ),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            Card(
              elevation: 5,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Header
                    Center(
                      child: Text(
                        widget.specimenDetails['nameSku']?.toString() ?? '',
                        style: const TextStyle(
                            fontSize: 20,
                            fontWeight: FontWeight.bold,
                            color: Colors.indigo),
                      ),
                    ),
                    const Divider(height: 20, thickness: 1.5),

                    // Owner Info
                    const Text(
                      "Owner Information",
                      style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                          color: Colors.black87),
                    ),
                    const SizedBox(height: 8),
                    infoRow("Owner Name", widget.specimenDetails['owner_name'] ?? widget.specimenDetails['user_name'] ?? ''),
                    infoRow("Username", widget.specimenDetails['owner_username'] ?? widget.specimenDetails['user_username'] ?? ''),
                    infoRow("Reporting Manager", widget.specimenDetails['reporting_manager_name'] ?? ''),
                    infoRow("Role", widget.specimenDetails['role_name'] ?? ''),

                    const SizedBox(height: 16),

                    // SKU Info
                    const Text(
                      "Specimen Info",
                      style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                          color: Colors.black87),
                    ),
                    const SizedBox(height: 8),
                    infoRow("SKU Code", widget.specimenDetails['sku_code'] ?? ''),
                    infoRow("Series Name", widget.specimenDetails['series_name'] ?? ''),
                    infoRow("Class", widget.specimenDetails['class_name'] ?? ''),
                    infoRow("Medium", widget.specimenDetails['medium_name'] ?? ''),
                    infoRow("Subject", widget.specimenDetails['subject_name'] ?? ''),
                    infoRow("Board", widget.specimenDetails['board_name'] ?? ''),
                    infoRow("Unit Price", widget.specimenDetails['unitPrice']?.toString() ?? widget.specimenDetails['amount']?.toString() ?? ''),
                    infoRow("Quantity", widget.specimenDetails['quantity'].toString()),

                    const SizedBox(height: 16),

                    // Status
                    const Text(
                      "Status",
                      style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                          color: Colors.black87),
                    ),
                    const SizedBox(height: 8),
                    infoRow(
                        "Approval Status",
                        widget.specimenDetails['approvalStatus'] == 1
                            ? "Approved"
                            : "Pending"),
                    // infoRow("Created At", widget.specimenDetails['createdAt'] ?? ''),
                    infoRow("Alloted By ", widget.specimenDetails['created_by_name'] ?? ''),
                  ],
                ),
              ),
            ),

            const SizedBox(height: 20),

            // Action Buttons
            if(widget.tab==3)
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceEvenly,
              children: [
                ElevatedButton(
                  onPressed: () => _showActionDialog(context, "1",widget.specimenDetails['quantity'].toString()),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.green,
                    padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 12),
                  ),
                  child: const Text("Accept",style: TextStyle(color: Colors.white)),
                ),
                // ElevatedButton(
                //   onPressed: () => _showActionDialog(context, "2"),
                //   style: ElevatedButton.styleFrom(
                //     backgroundColor: Colors.red,
                //     padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 12),
                //   ),
                //   child: const Text("Reject",style: TextStyle(color: Colors.white),),
                // ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
