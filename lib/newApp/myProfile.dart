import 'dart:convert';
import 'package:flutter/material.dart';
// import 'package:geocoding/geocoding.dart';
import 'package:mittsure/newApp/MainMenuScreen.dart';
import 'package:mittsure/newApp/bookLoader.dart';
import 'package:mittsure/services/apiService.dart';
import 'package:mittsure/services/utils.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:geolocator/geolocator.dart';

class ProfilePage extends StatefulWidget {
  @override
  State<ProfilePage> createState() => _ProfilePageState();
}

class _ProfilePageState extends State<ProfilePage> {
  Map<String, dynamic>? userData;
  bool loading = true;

  @override
  void initState() {
    super.initState();
    loadUserData();
  }

  Future<void> loadUserData() async {
    final prefs = await SharedPreferences.getInstance();
    final userString = prefs.getString('user');
    if (userString != null) {
      setState(() {
        userData = jsonDecode(userString);
        loading = false;
      });
    }
  }

 Future<void> tagBaseLocation() async {
  setState(() {
    loading = true;
  });
  try {
    final serviceEnabled = await Geolocator.isLocationServiceEnabled();
    if (!serviceEnabled) {
      showSnackbar('Location services are disabled.');
      return;
    }

    var permission = await Geolocator.checkPermission();
    if (permission == LocationPermission.denied) {
      permission = await Geolocator.requestPermission();
    }

    if (permission == LocationPermission.deniedForever ||
        permission == LocationPermission.denied) {
      DialogUtils.showCommonPopup(
        context: context,
        message: 'Location permissions are denied.',
        isSuccess: false,
      );
      return;
    }

    final position = await Geolocator.getCurrentPosition(
      desiredAccuracy: LocationAccuracy.high,
    );

    // 🧭 Step 1: Reverse Geocode
  //   List<Placemark> placemarks = await placemarkFromCoordinates(
  //     position.latitude,
  //     position.longitude,
  //   );

  //   if (placemarks.isEmpty) {
  //     DialogUtils.showCommonPopup(
  //       context: context,
  //       message: 'Unable to fetch address. Try again.',
  //       isSuccess: false,
  //     );
  //     return;
  //   }
  

  //   final Placemark place = placemarks.first;
  // print(place);
  //   final address = '${place.subThoroughfare}, ${place.thoroughfare}, ${place.subLocality}, ${place.locality}, ${place.postalCode}';

  //   // ✅ Step 2: Show confirmation dialog
  //   bool? confirm = await showDialog(
  //     context: context,
  //     builder: (_) => AlertDialog(
  //       title: Text("Confirm Address"),
  //       content: Text("Do you want to tag this location?\n\n$address"),
  //       actions: [
  //         TextButton(
  //           onPressed: () => Navigator.pop(context, false),
  //           child: Text("Cancel"),
  //         ),
  //         ElevatedButton(
  //           onPressed: () => Navigator.pop(context, true),
  //           child: Text("Yes, Tag"),
  //         ),
  //       ],
  //     ),
  //   );

  //   if (confirm != true) {
  //     return;
  //   }

    // 🛰 Step 3: Proceed with tagBaseLocation API
    var body = {
      "ownerId": userData!['id'],
      "latitude": position.latitude,
      "longitude": position.longitude,
      "data": jsonEncode({
        "party": userData!['id'],
        "lat": position.latitude,
        "long": position.longitude,
      })
    };

    final response = await ApiService.post(
      endpoint: "/user/addBaseLocatioForUser",
      body: body,
    );

    if (response != null && response['status'] == false) {
      setState(() {
        userData!['latitude'] = position.latitude;
        userData!['longitude'] = position.longitude;
      });

      final prefs = await SharedPreferences.getInstance();
      prefs.setString('user', jsonEncode(userData));

      DialogUtils.showCommonPopup(
        context: context,
        message: response['message'],
        isSuccess: true,
      );
    } else {
      DialogUtils.showCommonPopup(
        context: context,
        message: response['message'],
        isSuccess: false,
      );
    }
  } catch (e) {
    print(e);
    print("above weeroor");
    DialogUtils.showCommonPopup(
      context: context,
      message: 'Something went wrong',
      isSuccess: false,
    );
  } finally {
    setState(() {
      loading = false;
    });
  }
}


  Future<void> releaseBaseLocation() async {
    setState(() {
      loading = true;
    });
    try {
      final position = await Geolocator.getCurrentPosition(
          desiredAccuracy: LocationAccuracy.high);

      var body = {
        "ownerId": userData!['id'],
        "data": jsonEncode({
          "party": userData!['id'],
          "lat": userData!['latitude'],
          "long": userData!['longitude'],
          
        })
      };
      final response = await ApiService.post(
          endpoint: "/user/releaseBaseLocatioForUser", body: body);

      if (response != null && response['status'] == false) {
        setState(() {
          userData!['latitude'] = null;
          userData!['longitude'] = null;
        });

        final prefs = await SharedPreferences.getInstance();
        prefs.setString('user', jsonEncode(userData));
        DialogUtils.showCommonPopup(
            context: context, message: response['message'], isSuccess: true);
      } else {
        DialogUtils.showCommonPopup(
            context: context, message: response['message'], isSuccess: false);
      }
    } catch (e) {
      DialogUtils.showCommonPopup(
          context: context, message: 'Something Went Wrong', isSuccess: false);
    } finally {
      setState(() {
        loading = false;
      });
    }
  }

  void releaseBase() {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: Row(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              Icon(
                Icons.warning,
                color: Colors.orange.shade400,
              ),
              SizedBox(
                width: 10,
              ),
              Text(
                "Release base location",
                style: TextStyle(fontSize: 20),
              ),
            ],
          ),
          content: Text("Are you sure you want to release the base Location?"),
          actions: [
            TextButton(
              onPressed: () {
                Navigator.of(context).pop(); // Close the dialog
              },
              child: const Text("Cancel"),
            ),
            TextButton(
              onPressed: () async {
                Navigator.of(context).pop(); // Close the dialog
                releaseBaseLocation();
              },
              child: const Text("Yes"),
            ),
          ],
        );
      },
    );
  }

  void showSnackbar(String msg) {
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(msg)));
  }

  @override
  Widget build(BuildContext context) {
    final bool isTagged = userData?['latitude'] != null;

    return Scaffold(
      appBar: AppBar(
        iconTheme: IconThemeData(color: Colors.white),
        title: Text(
          "My Profile",
          style: TextStyle(color: Colors.white, fontSize: 18),
        ),
        backgroundColor: Colors.indigo[900],
        centerTitle: true,
        actions: [
          IconButton(
            icon: const Icon(Icons.home, color: Colors.white),
            onPressed: () {
              Navigator.pushAndRemoveUntil(
                context,
                MaterialPageRoute(builder: (context) => MainMenuScreen()),
                (route) => false, // remove all previous routes
              );
            },
          ),
        ],
      ),
      body: loading
          ? BookPageLoader()
          : Column(
              children: [
                Container(
                  width: double.infinity,
                  padding: EdgeInsets.symmetric(vertical: 30),
                  color: Colors.white,
                  child: Column(
                    children: [
                      CircleAvatar(
                          radius: 40,
                          backgroundColor: Colors.white,
                          child: Icon(
                            Icons.account_circle_rounded,
                            size: 100,
                          )),
                      SizedBox(height: 10),
                      Text(
                        userData?['name'] ?? '',
                        style: TextStyle(
                            color: Colors.indigo.shade600,
                            fontSize: 30,
                            fontWeight: FontWeight.bold),
                      ),
                    ],
                  ),
                ),
                Expanded(
                  child: ListView(
                    padding: EdgeInsets.all(16),
                    children: [
                      profileTile(Icons.data_usage_rounded, "Role",
                          userData?['role_name']),
                      profileTile(
                          Icons.phone_android, "Mobile", userData?['mobno']),
                      profileTile(Icons.map, "Cluster",
                          userData?['clusterName'].toString()),
                      profileTile(Icons.sensor_occupied, "Reporting Manager",
                          userData?['managerName']),
                      profileTile(Icons.map_sharp, "Base Location",
                          isTagged ? "Tagged" : "Not Tagged"),
                    ],
                  ),
                ),
                Container(
                  padding: EdgeInsets.all(16),
                  width: double.infinity,
                  child: ElevatedButton.icon(
                    onPressed: () {
                      if (isTagged) {
                        releaseBase();
                      } else {
                        tagBaseLocation();
                      }
                    },
                    icon: Icon(
                      isTagged ? Icons.remove_circle : Icons.map_outlined,
                      color: Colors.white,
                    ),
                    label: Text(
                      isTagged ? "Release Base Location" : "Tag Base Location",
                      style: TextStyle(fontSize: 16, color: Colors.white),
                    ),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: isTagged ? Colors.red : Colors.green,
                      padding: EdgeInsets.symmetric(vertical: 14),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                    ),
                  ),
                ),
              ],
            ),
    );
  }

  Widget profileTile(IconData icon, String title, String? value) {
    return ListTile(
      leading: Icon(icon, color: Colors.deepPurple),
      title: Text(title),
      subtitle: Text(value ?? 'Not Available'),
    );
  }

  String getInitials(String? name) {
    if (name == null || name.isEmpty) return "U";
    var parts = name.trim().split(" ");
    if (parts.length == 1) return parts[0][0].toUpperCase();
    return (parts[0][0] + parts[1][0]).toUpperCase();
  }
}
