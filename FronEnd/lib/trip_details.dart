import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;

class TripDetailsPage extends StatefulWidget {
  final String tripId;  // Pass the trip ID to this page

  TripDetailsPage({required this.tripId});

  @override
  _TripDetailsPageState createState() => _TripDetailsPageState();
}

class _TripDetailsPageState extends State<TripDetailsPage> {
  Map<String, dynamic>? tripDetails;
  bool isLoading = true;

  @override
  void initState() {
    super.initState();
    _fetchTripDetails();
  }

  Future<void> _fetchTripDetails() async {
    final url = 'http://26.149.114.62:5000/api/trips/${widget.tripId}';

    try {
      final response = await http.get(Uri.parse(url));

      if (response.statusCode == 200) {
        setState(() {
          tripDetails = json.decode(response.body);
          isLoading = false;
        });
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Failed to load trip details.')),
        );
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('An error occurred. Please try again later.')),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text('Trip Details')),
      body: isLoading
          ? Center(child: CircularProgressIndicator())
          : tripDetails == null
              ? Center(child: Text('No trip details available.'))
              : Padding(
                  padding: EdgeInsets.all(16.0),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        tripDetails!['tripName'] ?? 'Trip Name',
                        style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
                      ),
                      SizedBox(height: 16),
                      Text(
                        'Start Location: ${tripDetails!['startLocation']['latitude']}, ${tripDetails!['startLocation']['longitude']}',
                      ),
                      SizedBox(height: 8),
                      Text(
                        'Destination: ${tripDetails!['destination']['latitude']}, ${tripDetails!['destination']['longitude']}',
                      ),
                      SizedBox(height: 8),
                      Text(
                        'Start Date: ${tripDetails!['startDate']}',
                      ),
                      SizedBox(height: 8),
                      Text(
                        'End Date: ${tripDetails!['endDate']}',
                      ),
                      SizedBox(height: 8),
                      Text(
                        'Created By: ${tripDetails!['createdBy']}',
                      ),
                      SizedBox(height: 8),
                      Text('Participants:'),
                      for (var participant in tripDetails!['participants'])
                        Text(participant),
                    ],
                  ),
                ),
    );
  }
}
