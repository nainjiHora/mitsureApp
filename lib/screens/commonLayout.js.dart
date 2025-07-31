import 'package:flutter/material.dart';
import 'package:mittsure/newApp/MainMenuScreen.dart';
import 'package:mittsure/screens/Party.dart';
import 'package:mittsure/screens/collection.dart';
import 'package:mittsure/screens/home.dart';
import 'package:mittsure/screens/login.dart';
import 'package:mittsure/screens/orders.dart';
import 'package:mittsure/screens/returnedOrders.dart';
import 'package:shared_preferences/shared_preferences.dart';

class CommonLayout extends StatefulWidget {
  final String title;
  final Widget child; // Content of the screen
  final int currentIndex; // Index for the selected bottom navigation item

  const CommonLayout({
    required this.title,
    required this.child,
    required this.currentIndex,
    Key? key,
  }) : super(key: key);

  @override
  State<CommonLayout> createState() => _CommonLayoutState();
}

class _CommonLayoutState extends State<CommonLayout> {
  
  void _logout() {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: const Text("Logout"),
          content: const Text("Are you sure you want to logout?"),
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
                final prefs = await SharedPreferences.getInstance();
                await prefs.remove("user");
                await prefs.remove("Token");
                Navigator.pushReplacement(
                  context,
                  MaterialPageRoute(builder: (context) => LoginScreen()),
                );
              },
              child: const Text("Logout"),
            ),
          ],
        );
      },
    );
  }


  void _onTabSelected(int index) {
    switch (index) {
      case 0:
        Navigator.push(
          context,
          MaterialPageRoute(builder: (context) => PartyScreen()),
        );
        break;
      case 1:
        Navigator.push(
          context,
          MaterialPageRoute(builder: (context) => OrdersScreen(userReq:false)),
        );
        break;
      case 2:
        showComingSoonPopup(context);
        // Navigator.push(
        //   context,
        //   MaterialPageRoute(builder: (context) => CollectionScreen()),
        // );
        break;
      case 3:
        // Navigator.push(
        //   context,
        //   MaterialPageRoute(builder: (context) => ReturnOrders()),
        // );
      showComingSoonPopup(context);
        break;
    }
  }

  void showComingSoonPopup(BuildContext context) {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title:  Text("Oops! Try again later! we're on it! 🔧"),
          // content: Text('This functionality is coming soon.'),
          actions: [
            TextButton(
              onPressed: () {
                Navigator.of(context).pop(); // Close the dialog
              },
              child: Text('OK'),
            ),
          ],
        );
      },
    );
  }

  void _navigateToHome() {
    // Handle navigation to the Home screen
    Navigator.pushAndRemoveUntil(
                context,
                MaterialPageRoute(builder: (context) => MainMenuScreen()),
                (route) => false, // remove all previous routes
              );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        leading: IconButton(
          icon: Icon(Icons.arrow_back, color: Colors.white),
          onPressed: () {
            Navigator.pop(context);
          },
        ),
        title: Text(widget.title, style: TextStyle(fontSize: 18, color: Colors.white)),
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
        backgroundColor: Colors.indigo[900],
      ),
      body: widget.child, // Main content for the screen
      bottomNavigationBar: BottomNavigationBar(
        currentIndex: widget.currentIndex,
        onTap: (index) {
          if (index == 2) {
            _navigateToHome(); // Center "Home" button navigation
          } else {
            _onTabSelected(index > 2 ? index - 1 : index); // Adjust for the home button in the middle
          }
        },
        backgroundColor: Colors.indigo[900],
        selectedItemColor: Colors.white,
     
        unselectedItemColor: Colors.white,
        type: BottomNavigationBarType.fixed,
        items: const [
          BottomNavigationBarItem(
            icon: Icon(Icons.group),
            label: 'Parties',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.shopping_cart),
            label: 'Orders',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.home),
            label: 'Home',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.attach_money),
            label: 'Collection',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.assignment_return),
            label: 'Return Orders',
          ),
        ],
      ),
    );
  }
}
