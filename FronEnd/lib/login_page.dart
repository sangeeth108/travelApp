import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';
import 'home_page_user.dart'; // Import User home page
import 'home_page_partner.dart'; // Import Partner home page
import 'signup_page.dart';

class LoginPage extends StatefulWidget {
  @override
  _LoginPageState createState() => _LoginPageState();
}

class _LoginPageState extends State<LoginPage> {
  final TextEditingController _emailController = TextEditingController();
  final TextEditingController _passwordController = TextEditingController();

  Future<void> _login() async {
    final response = await http.post(
      Uri.parse('http://26.149.114.62:5000/api/auth/login'),
      headers: {'Content-Type': 'application/json'},
      body: json.encode({
        'email': _emailController.text,
        'password': _passwordController.text,
      }),
    );

    // Inside _login method
if (response.statusCode == 200) {
  final data = json.decode(response.body);
  SharedPreferences prefs = await SharedPreferences.getInstance();
  await prefs.setString('token', data['token']);
  await prefs.setString('role', data['user']['role']);
  await prefs.setString('username', data['user']['name']);
  await prefs.setString('email', data['user']['email']);
  String role = data['user']['role']; // Get the user role from the response

  // Navigate based on user role
  if (role == 'user') {
    Navigator.pushReplacement(
      context,
      MaterialPageRoute(builder: (context) => HomePageUser()), // User home page
    );
  } else if (role == 'partner') {
    Navigator.pushReplacement(
      context,
      MaterialPageRoute(builder: (context) => HomePagePartner()), // Partner home page
    );
  }
}
 else {
      // Check for specific error messages from the response if available
      final errorData = json.decode(response.body);
      _showErrorDialog(
          errorData['message'] ?? 'Login failed: Invalid credentials');
    }
  }

  void _showErrorDialog(String message) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text('Error'),
        content: Text(message),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: Text('OK'),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text('Login')),
      body: Padding(
        padding: EdgeInsets.all(16.0),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            TextField(
              controller: _emailController,
              decoration: InputDecoration(labelText: 'Email'),
            ),
            TextField(
              controller: _passwordController,
              decoration: InputDecoration(labelText: 'Password'),
              obscureText: true,
            ),
            SizedBox(height: 20),
            ElevatedButton(
              onPressed: _login,
              child: Text('Login'),
            ),
            SizedBox(height: 10),
            TextButton(
              onPressed: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(builder: (context) => SignupPage()),
                );
              },
              child: Text('Don’t have an account? Sign up here'),
            ),
          ],
        ),
      ),
    );
  }
}
