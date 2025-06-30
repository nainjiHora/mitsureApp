import 'package:flutter/material.dart';
import 'package:mittsure/services/apiService.dart';
import 'package:mittsure/services/utils.dart';

class SpecimenReqDetail extends StatefulWidget {
  final String id;
  final bool userReq;

  const SpecimenReqDetail({super.key, required this.id, required this.userReq});

  @override
  State<SpecimenReqDetail> createState() => _SpecimenReqDetailState();
}

class _SpecimenReqDetailState extends State<SpecimenReqDetail> {
  bool isLoading = false;
  Map<String, List<dynamic>> groupedData = {};

  @override
  void initState() {
    super.initState();
    fetchDetail();
  }

  Future<void> fetchDetail() async {
    setState(() => isLoading = true);
    try {
      final response = await ApiService.post(
        endpoint: '/specimen/getSpecimenItemsById',
        body: {
          "specimenId": widget.id,
          "pageNumber": 0,
          "recordPerPage": 100,
        },
      );

      if (response != null && response['status'] == false) {
        final List<dynamic> data = response['data'];

        final Map<String, List<dynamic>> grouped = {};

        for (var item in data) {
          final key = item['seriesCategory'] ?? 'Unknown';
          grouped.putIfAbsent(key, () => []).add(item);
        }

        setState(() {
          groupedData = grouped;
        });
      }
    } catch (e) {
      DialogUtils.showCommonPopup(
        context: context,
        message: "Something went wrong while fetching details.",
        isSuccess: false,
      );
    } finally {
      setState(() => isLoading = false);
    }
  }

  void _approveRequest(item) async {
    // print(item);
    // return;
    setState(() {
      isLoading = true;
    });
    try {
      final response = await ApiService.post(
        endpoint: '/Specimen/approveRejectSpecimenToUser',
        body: {
          "isDirectApproval": false,
          "approvalStatus": "1",
          "specimenLineItemsId": item['specimenLineItemsId'],
          "specimenId": item['allottedSpecimenId']
        },
      );
      setState(() {
        isLoading = false;
      });
      if (response != null && response['status'] == false) {
        DialogUtils.showCommonPopup(
            context: context, message: "Approved Sucessfully", isSuccess: true);
            fetchDetail();
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

  void _rejectRequestWithRemark(item) {
    print(item);
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
                  endpoint: '/Specimen/approveRejectSpecimenToUser',
                  body: {
                    "isDirectApproval": false,
                    "approvalStatus": "2",
                    "reason": remark,
                    "specimenLineItemsId": item['specimenLineItemsId'],
                    "specimenId": item['allottedSpecimenId']
                  },
                );
                setState(() {
                  isLoading = false;
                });
                if (response != null && response['status'] == false) {
                  DialogUtils.showCommonPopup(
                      context: context, message: "Rejected ", isSuccess: true);
                      fetchDetail();
                }
              } catch (e) {
                print(e);
                DialogUtils.showCommonPopup(
                    context: context,
                    message: "Something Went Wrong",
                    isSuccess: false);
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

  Widget _buildStatusBadge(dynamic status) {
    print(status);
    String label = '';
    Color color = Colors.grey;

    switch (status['status']) {
      case 1:
        label ='Approved';
        color = Colors.green;
        break;
      case 2:
        label = 'Rejected';
        color =Colors.red;
        break;
   
      default:
        return const SizedBox(); // No badge for unknown status
    }
     return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: color.withOpacity(0.1),
        border: Border.all(color: color),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Text(
        label,
        style: TextStyle(
          color: color,
          fontSize: 12,
          fontWeight: FontWeight.bold,
        ),
      ),
    );
  }

  Widget _detailRow(String label, String? value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 2),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
              width: 90,
              child: Text(
                "$label:",
                style: TextStyle(fontWeight: FontWeight.w600),
              )),
          Expanded(
              child:
                  Text(value ?? "-", style: TextStyle(color: Colors.black87)))
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text("Specimen Request Detail"),
        backgroundColor: Colors.indigo[900],
        iconTheme: IconThemeData(color: Colors.white),
        titleTextStyle: TextStyle(color: Colors.white, fontSize: 20),
      ),
      body: isLoading
          ? Center(child: CircularProgressIndicator())
          : groupedData.isEmpty
              ? Center(child: Text("No items found"))
              : ListView.builder(
                  padding: const EdgeInsets.all(16),
                  itemCount: groupedData.keys.length,
                  itemBuilder: (context, index) {
                    final category = groupedData.keys.elementAt(index);
                    final items = groupedData[category]!;

                    return Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          "Series: $category",
                          style: TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                            color: Colors.indigo,
                          ),
                        ),
                        const SizedBox(height: 10),
                        ...items.map((item) => Card(
                              margin: const EdgeInsets.only(bottom: 16),
                              shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(12)),
                              elevation: 3,
                              child: Padding(
                                padding: const EdgeInsets.all(16),
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      item['nameSku'] ?? "Unnamed Book",
                                      style: TextStyle(
                                          fontSize: 16,
                                          fontWeight: FontWeight.bold),
                                    ),
                                    const SizedBox(height: 8),
                                    _detailRow("Medium", item['mediumTableId']),
                                    _detailRow("Class", item['classId']),
                                    _detailRow("Board", item['boardId']),
                                    _detailRow("Quantity",
                                        item['quantity'].toString()),
                                    const SizedBox(height: 12),
                                    item['status']==0 &&widget.userReq==true?Row(
                                      children: [
                                        Expanded(
                                          child: ElevatedButton.icon(
                                            onPressed: () =>
                                                _approveRequest(item),
                                            icon: Icon(Icons.check,
                                                color: Colors.white),
                                            label: Text(
                                              "Approve",
                                              style: TextStyle(
                                                  color: Colors.white),
                                            ),
                                            style: ElevatedButton.styleFrom(
                                                backgroundColor: Colors.green),
                                          ),
                                        ),
                                        SizedBox(width: 12),
                                        Expanded(
                                          child: ElevatedButton.icon(
                                            onPressed: () =>
                                                _rejectRequestWithRemark(item),
                                            icon: Icon(Icons.close,
                                                color: Colors.white),
                                            label: Text(
                                              "Reject",
                                              style: TextStyle(
                                                  color: Colors.white),
                                            ),
                                            style: ElevatedButton.styleFrom(
                                                backgroundColor: Colors.red),
                                          ),
                                        ),
                                      ],
                                    ):Row(children: [_buildStatusBadge(item)],)
                                  ],
                                ),
                              ),
                            ))
                      ],
                    );
                  },
                ),
    );
  }
}
