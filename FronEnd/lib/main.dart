import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'login_page.dart';
import 'home_page_user.dart';
import 'home_page_partner.dart';

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
            if (snapshot.hasData && snapshot.data!['token'] != null && snapshot.data!['role'] != null) {
              String role = snapshot.data!['role'];
              return role == 'partner' ? HomePagePartner() : HomePageUser();
            } else {
              // Navigate to LoginPage if token or role is null
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

    // Return a map with non-null checks to avoid issues in FutureBuilder
    return {
      'token': token ?? '', // Default empty string if null
      'role': role ?? '',   // Default empty string if null
    };
  }
}
