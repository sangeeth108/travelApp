import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;

class BookingPage extends StatelessWidget {
  final String listingId;

  BookingPage({required this.listingId});

  Future<void> _bookListing() async {
    final response = await http.post(
      Uri.parse('http://26.149.114.62:5000/api/bookings'),
      headers: {'Content-Type': 'application/json'},
      body: json.encode({
        'listingId': listingId,
        'bookingDate': DateTime.now().toIso8601String(), // Example booking date
      }),
    );

    if (response.statusCode == 200) {
      // Show success message
    } else {
      // Show error message
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text('Booking Page')),
      body: Center(
        child: ElevatedButton(
          onPressed: _bookListing,
          child: Text('Book Now'),
        ),
      ),
    );
  }
}
