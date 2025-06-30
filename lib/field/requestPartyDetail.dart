import 'package:flutter/material.dart';
import 'package:mittsure/field/partyRequest.dart';
import 'package:mittsure/newApp/MainMenuScreen.dart';
import 'package:mittsure/newApp/bookLoader.dart';
import 'package:mittsure/services/apiService.dart';
import 'package:mittsure/services/utils.dart';

class RequestPartyDetailScreen extends StatefulWidget {
  final String requestId;
  final id;

  const RequestPartyDetailScreen(
      {super.key, required this.requestId, required this.id});

  @override
  State<RequestPartyDetailScreen> createState() =>
      _RequestPartyDetailScreenState();
}

class _RequestPartyDetailScreenState extends State<RequestPartyDetailScreen> {
  Map<String, dynamic>? partyDetail;
  bool isLoading = true;

  @override
  void initState() {
    super.initState();
    fetchPartyDetails();
  }

  Future<void> fetchPartyDetails() async {
    try {
      final response = await ApiService.post(
        endpoint: '/party/getDistributorByID',
        body: {"id": widget.requestId},
      );

      if (response != null && response['status'] == false) {
        setState(() {
          partyDetail = response['data'][0];
          isLoading = false;
        });
      }
    } catch (e) {
      print('Error fetching party details: $e');
      setState(() {
        isLoading = false;
      });
    }
  }

  void _approveRequest() async {
    setState(() {
      isLoading = true;
    });
    try {
      final response = await ApiService.post(
        endpoint: '/party/updateLatLongApprovalStatus',
        body: {
          "requestId": widget.id,
          "status": "1",
          "party_type": "distributor",
          "remark": "",
          "request_type_id": "30"
        },
      );
      setState(() {
        isLoading = false;
      });
      if (response != null && response['success'] == true) {
        ScaffoldMessenger.of(context)
            .showSnackBar(SnackBar(content: Text("Approved successfully")));
        Navigator.pop(context);
        Navigator.pushReplacement(
          context,
          MaterialPageRoute(
            builder: (context) => MainMenuScreen(),
          ),
        );
      }
    } catch (e) {
      print(e);
      DialogUtils.showCommonPopup(
          context: context, message: "Something Went Wrong", isSuccess: false);
    } finally {
      setState(() {
        isLoading = false;
      });
    }
  }
void _rejectRequestWithRemark() {
  final TextEditingController remarkController = TextEditingController();

  showDialog(
    context: context,
    builder: (_) => AlertDialog(
      title: Text("Enter Rejection Remark"),
      content: TextField(
        controller: remarkController,
        maxLines: 3,
        decoration: InputDecoration(
          hintText: "Type remark here...",
          border: OutlineInputBorder(),
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context),
          child: Text("Cancel"),
        ),
        ElevatedButton(
          onPressed: () async {
            final remark = remarkController.text.trim();
            if (remark.isEmpty) return;

            // Close the dialog first
            Navigator.pop(context);

            setState(() {
              isLoading = true;
            });

            try {
              final response = await ApiService.post(
                endpoint: '/party/updateLatLongApprovalStatus',
                body: {
                  "requestId": widget.id,
                  "status": "2",
                  "party_type": "distributor",
                  "remark": remark,
                  "request_type_id": "30"
                },
              );

              if (response != null && response['success'] == true) {
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(content: Text("Rejected successfully")),
                );

                // Wait a frame to let the SnackBar settle
                await Future.delayed(Duration(milliseconds: 300));

                // Navigate to next screen
                Navigator.pushReplacement(
                  context,
                  MaterialPageRoute(builder: (context) => MainMenuScreen()),
                );
              } else {
                DialogUtils.showCommonPopup(
                  context: context,
                  message: "Rejection failed",
                  isSuccess: false,
                );
              }
            } catch (e) {
              print(e);
              DialogUtils.showCommonPopup(
                context: context,
                message: "Something Went Wrong",
                isSuccess: false,
              );
            } finally {
              setState(() {
                isLoading = false;
              });
            }
          },
          child: Text("Submit"),
        ),
      ],
    ),
  );
}


  Widget _detailCard({required String title, required String value}) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 6),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 140,
            child: Text(
              "$title:",
              style: TextStyle(fontWeight: FontWeight.w600, fontSize: 16),
            ),
          ),
          Expanded(
            child: Text(
              value.isEmpty ? "-" : value,
              style: TextStyle(fontSize: 16),
            ),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return WillPopScope(
      onWillPop: () async {
        Navigator.pushReplacement(
          context,
          MaterialPageRoute(
            builder: (context) => PartyReqScreen(),
          ),
        );
        return false;
      },
      child: Scaffold(
        appBar: AppBar(
          title: Text('Party Request Details'),
          backgroundColor: Colors.indigo[900],
          iconTheme: IconThemeData(color: Colors.white),
          titleTextStyle: TextStyle(color: Colors.white, fontSize: 20),
        ),
        body: isLoading
            ? Center(child: BookPageLoader())
            : partyDetail == null
                ? Center(child: Text("No data found"))
                : SingleChildScrollView(
                    padding: const EdgeInsets.all(16.0),
                    child: Column(
                      children: [
                        Card(
                          elevation: 3,
                          shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(12)),
                          child: Padding(
                            padding: const EdgeInsets.all(16.0),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                _detailCard(
                                    title: "Distributor",
                                    value:
                                        partyDetail!['DistributorName'] ?? ""),
                                _detailCard(
                                    title: "Address Line 1",
                                    value: partyDetail!['AddressLine1'] ?? ""),
                                _detailCard(
                                    title: "Address Line 2",
                                    value: partyDetail!['AddressLine2'] ?? ""),
                                _detailCard(
                                    title: "Landmark",
                                    value: partyDetail!['Landmark'] ?? ""),
                                _detailCard(
                                    title: "Cluster",
                                    value: partyDetail!['cluster_name']
                                            ?.toString() ??
                                        ""),
                                _detailCard(
                                    title: "District",
                                    value: partyDetail!['District'] ?? ""),
                                _detailCard(
                                    title: "State",
                                    value: partyDetail!['State'] ?? ""),
                                _detailCard(
                                    title: "Pincode",
                                    value: partyDetail!['Pincode'] ?? ""),
                                _detailCard(
                                    title: "Email",
                                    value: partyDetail!['email'] ?? ""),
                                _detailCard(
                                    title: "Maker Name",
                                    value: partyDetail!['makerName'] ?? ""),
                                _detailCard(
                                    title: "Maker Contact",
                                    value: partyDetail!['makerContact'] ?? ""),
                                _detailCard(
                                    title: "Added By",
                                    value: partyDetail!['name'] ?? ""),
                                // Uncomment below if makerRoleName is required
                                // _detailCard(title: "Maker Role", value: partyDetail!['makerRoleName'] ?? ""),
                              ],
                            ),
                          ),
                        ),
                        const SizedBox(height: 24),
                        Row(
                          children: [
                            Expanded(
                              child: ElevatedButton.icon(
                                onPressed: _approveRequest,
                                icon: Icon(
                                  Icons.check,
                                  color: Colors.white,
                                ),
                                label: Text(
                                  "Approve",
                                  style: TextStyle(color: Colors.white),
                                ),
                                style: ElevatedButton.styleFrom(
                                  backgroundColor: Colors.green,
                                  padding: EdgeInsets.symmetric(vertical: 14),
                                  shape: RoundedRectangleBorder(
                                      borderRadius: BorderRadius.circular(8)),
                                ),
                              ),
                            ),
                            const SizedBox(width: 16),
                            Expanded(
                              child: ElevatedButton.icon(
                                onPressed: _rejectRequestWithRemark,
                                icon: Icon(
                                  Icons.close,
                                  color: Colors.white,
                                ),
                                label: Text(
                                  "Reject",
                                  style: TextStyle(color: Colors.white),
                                ),
                                style: ElevatedButton.styleFrom(
                                  backgroundColor: Colors.red,
                                  padding: EdgeInsets.symmetric(vertical: 14),
                                  shape: RoundedRectangleBorder(
                                      borderRadius: BorderRadius.circular(8)),
                                ),
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
      ),
    );
  }
}
