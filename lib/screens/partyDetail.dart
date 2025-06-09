import 'package:flutter/material.dart';
import 'package:mittsure/screens/commonLayout.js.dart';
import 'package:mittsure/screens/newOrder.dart';

class DistributorDetailsScreen extends StatefulWidget {
  final Map<String, dynamic> data;
  final type;

  DistributorDetailsScreen({Key? key, required this.data,this.type});

  @override
  State<DistributorDetailsScreen> createState() => _DistributorDetailsScreenState();
}

class _DistributorDetailsScreenState extends State<DistributorDetailsScreen> {
  @override
  Widget build(BuildContext context) {
    final distributor=widget.data;
    return CommonLayout(
      currentIndex: 0,
        title: widget.type=='school'?distributor['schoolName']:distributor['DistributorName'],
        child: ListView(
        padding: const EdgeInsets.all(16.0),
        children: [
          // Distributor Details Section
           SectionTitle(title: widget.type=='school'?'School Details':'Distributor Details'),
          DetailsRow(label: 'Name', value: widget.type=='school'?distributor['schoolName']:distributor['DistributorName'] ?? 'N/A'),
          DetailsRow(label: 'GST Number', value: distributor['GSTno'] ?? 'N/A'),
          DetailsRow(
            label: 'Created At',
            value: distributor['createdAt'] != null
                ? distributor['createdAt'].toString().substring(0, 10)
                : 'N/A',
          ),
          const Divider(),

          // Address Section
          const SectionTitle(title: 'Address Details'),
          DetailsRow(label: 'Pincode', value: distributor['Pincode'] ?? 'N/A'),
          DetailsRow(label: 'Address Line 1', value: distributor['AddressLine1'] ?? 'N/A'),
          DetailsRow(label: 'Landmark', value: distributor['Landmark'] ?? 'N/A'),
          DetailsRow(label: 'Coordinates', value: distributor['Landmark'] ?? 'N/A'),
          const Divider(),

          const SectionTitle(title: 'Contact Person Details'),
          DetailsRow(label: 'Name', value: distributor['name'] ?? 'N/A'),
          DetailsRow(label: 'Role', value: distributor['role'] ?? 'N/A'),
          DetailsRow(label: 'Contact Number', value: distributor['makerContact'] ?? 'N/A'),
          DetailsRow(label: 'Email', value: distributor['email'] ?? 'N/A'),
          const Divider(),

          
SizedBox(height:20,),
 true
                ? ElevatedButton.icon(
                    icon: Icon(
                      Icons.map,
                      color: Colors.white,
                    ),
                    style: ElevatedButton.styleFrom(
                      minimumSize: Size(10, 50),
                      backgroundColor: Colors.orange.shade400,
                    ),
                    onPressed: () {
                    
                    },
                    label: Text(
                      "Mark Location",
                      style: TextStyle(color: Colors.white),
                    ),
                  )
                : Container(),
                SizedBox(height: 5,),
                ElevatedButton.icon(
                    icon: Icon(
                      Icons.shop_two_outlined,
                      color: Colors.white,
                    ),
                    style: ElevatedButton.styleFrom(
                      minimumSize: Size(10, 50),
                      backgroundColor: Colors.green.shade400,
                    ),
                    onPressed: (){
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (context) =>
                      NewOrderScreen(party: widget.data,type: widget.type),
                ),
              );
            },
                    label: Text(
                      "Proceed to Order",
                      style: TextStyle(color: Colors.white),
                    ),
                  ),
                
          // ElevatedButton(
          //   style: ElevatedButton.styleFrom(
          //     minimumSize: Size(double.infinity, 50),
          //     backgroundColor: Colors.green.shade600,
          //   ),
          //   onPressed: (){
          //     Navigator.push(
          //       context,
          //       MaterialPageRoute(
          //         builder: (context) =>
          //             NewOrderScreen(party: widget.data,type: widget.type),
          //       ),
          //     );
          //   },
          //   child: Text("Proceed to Order", style: TextStyle(fontSize: 18, color: Colors.white)),
          // ),
        ],
      ),
    );
  }
}

// Section Title Widget
class SectionTitle extends StatelessWidget {
  final String title;

  const SectionTitle({Key? key, required this.title}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8.0),
      child: Text(
        title,
        style: const TextStyle(
          fontSize: 16,
          fontWeight: FontWeight.bold,
          color: Colors.black87,
        ),
      ),
    );
  }
}

// Details Row Widget
class DetailsRow extends StatelessWidget {
  final String label;
  final String value;

  const DetailsRow({Key? key, required this.label, required this.value}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4.0),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(
            label,
            style: const TextStyle(fontSize: 14, color: Colors.black54),
          ),
          Expanded(
            child: Text(
              value,
              textAlign: TextAlign.end,
              style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w500),
              overflow: TextOverflow.ellipsis,
            ),
          ),
        ],
      ),
    );
  }
}
