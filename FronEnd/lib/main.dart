import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'login_page.dart';
import 'home_page_user.dart';  // Import HomePageUser
import 'home_page_partner.dart'; // Import HomePagePartner

void main() {
  runApp(MyApp());
}

class MyApp extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Travel App',
      theme: ThemeData(primarySwatch: Colors.blue),
      home: FutureBuilder<Map<String, dynamic>>(
        future: _checkLoginAndRole(),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return Center(child: CircularProgressIndicator());
          } else {
            if (snapshot.data != null) {
              String role = snapshot.data!['role'];
              return role == 'partner' ? HomePagePartner() : HomePageUser();
            } else {
              return LoginPage();
            }
          }
        },
      ),
    );
  }

  static Future<Map<String, dynamic>> _checkLoginAndRole() async {
  SharedPreferences prefs = await SharedPreferences.getInstance();
  String? token = prefs.getString('token');
  String? role = prefs.getString('role');

  // Return a map indicating whether the user is logged in and their role
  return {
    'token': token,
    'role': role,
  };
}

}
