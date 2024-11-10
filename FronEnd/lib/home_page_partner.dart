import 'package:flutter/material.dart';
import 'package:flutter_application_1/add_listing_page.dart';
import 'package:flutter_application_1/manage_listings_page.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'login_page.dart';

class HomePagePartner extends StatefulWidget {
  @override
  _HomePagePartnerState createState() => _HomePagePartnerState();
}

class _HomePagePartnerState extends State<HomePagePartner> {
  String username = '';

  @override
  void initState() {
    super.initState();
    _loadUserData();
  }

  Future<void> _loadUserData() async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    setState(() {
      username = prefs.getString('username') ?? 'Partner';
    });
  }

  Future<void> _logout() async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    await prefs.remove('token');
    await prefs.remove('username');
    await prefs.remove('email');
    Navigator.of(context).pushReplacement(
      MaterialPageRoute(builder: (context) => LoginPage()),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Partner Home Page'),
        actions: [
          IconButton(
            icon: Icon(Icons.logout),
            onPressed: _logout,
          ),
        ],
      ),
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Text(
              '$username, Partner Dashboard!',
              style: TextStyle(fontSize: 24),
            ),
            SizedBox(height: 20),
            ElevatedButton(
              onPressed: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(builder: (context) => AddListingPage()),
                );
              },
              child: Text('Add New Listing'),
            ),
            SizedBox(height: 10),
            ElevatedButton(
              onPressed: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(builder: (context) => ManageListingsPage()),
                );
              },
              child: Text('Manage Listings'),
            ),
          ],
        ),
      ),
    );
  }
}
