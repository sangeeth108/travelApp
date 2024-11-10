import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:flutter_application_1/create_trip.dart';
import 'package:flutter_application_1/listings.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:http/http.dart' as http;
import 'login_page.dart';
import 'trip_details.dart';

class HomePageUser extends StatefulWidget {
  @override
  _HomePageUserState createState() => _HomePageUserState();
}

class _HomePageUserState extends State<HomePageUser> {
  String username = '';
  String email = '';
  List<dynamic> trips = []; // List to store user-related trips

  @override
  void initState() {
    super.initState();
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    _loadUserData();
  }

  // Load user data from SharedPreferences
  Future<void> _loadUserData() async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    setState(() {
      username = prefs.getString('username') ?? '';
      email = prefs.getString('email') ?? '';
    });
    _fetchUserTrips();  // Fetch the trips after loading user data
  }

  // Fetch user trips from the server
  Future<void> _fetchUserTrips() async {
    try {
      final response = await http.get(
          Uri.parse('http://26.149.114.62:5000/api/trips/user?email=$email'));
      if (response.statusCode == 200) {
        setState(() {
          trips = json.decode(response.body);
        });
      } else {
        print('Failed to load trips');
      }
    } catch (e) {
      print('Error fetching trips: $e');
    }
  }

  // Logout the user by clearing the shared preferences and redirecting to the login page
  Future<void> _logout() async {
  SharedPreferences prefs = await SharedPreferences.getInstance();
  await prefs.remove('token');
  await prefs.remove('role');
  await prefs.remove('username');
  await prefs.remove('email');
  Navigator.of(context).pushReplacement(
    MaterialPageRoute(builder: (context) => LoginPage()),
  );
}

  // Navigate to trip details page
  void _goToTripDetails(String tripId) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => TripDetailsPage(tripId: tripId),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('User Home Page'),
        actions: [
          IconButton(
            icon: Icon(Icons.refresh),
            onPressed: _fetchUserTrips, // Refresh trips when pressed
          ),
          IconButton(
            icon: Icon(Icons.logout),
            onPressed: _logout,
          ),
        ],
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              '$username, User Dashboard',
              style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
            ),
            SizedBox(height: 20),
            ElevatedButton(
              onPressed: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(builder: (context) => ListingsPage()),
                );
              },
              child: Text('Bookings'),
            ),
            SizedBox(height: 10),
            ElevatedButton(
              onPressed: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(builder: (context) => CreateTripPage()),
                );
              },
              child: Text('Create Trip'),
            ),
            SizedBox(height: 30),
            Text(
              'Your Trips',
              style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
            ),
            Expanded(
              child: trips.isEmpty
                  ? Center(
                      child: Text(
                        'Currently, no trips available.',
                        style: TextStyle(fontSize: 18, fontStyle: FontStyle.italic),
                      ),
                    )
                  : ListView.builder(
                      itemCount: trips.length,
                      itemBuilder: (context, index) {
                        final trip = trips[index];
                        return ListTile(
                          title: Text(trip['tripName'] ?? 'Unnamed Trip'),
                          subtitle: Text(
                              trip['tripDescription'] ?? 'No description available'),
                          onTap: () => _goToTripDetails(trip['_id']),
                        );
                      },
                    ),
            ),
          ],
        ),
      ),
    );
  }
}
