import 'package:flutter/material.dart';
import 'package:flutter_application_1/edit_listing_page.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';

class ManageListingsPage extends StatefulWidget {
  @override
  _ManageListingsPageState createState() => _ManageListingsPageState();
}

class _ManageListingsPageState extends State<ManageListingsPage> {
  List<dynamic> _listings = [];

  @override
  void initState() {
    super.initState();
    _fetchListings();
  }

  // Fetch partner's listings from the backend
  Future<void> _fetchListings() async {
    final response = await http.get(
      Uri.parse('http://26.149.114.62:5000/api/partners/myListings'),
      headers: {'Content-Type': 'application/json'},
    );

    if (response.statusCode == 200) {
      setState(() {
        _listings = json.decode(response.body);
      });
    } else {
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(
        content: Text('Failed to load listings'),
      ));
    }
  }

  // Delete listing
  Future<void> _deleteListing(String listingId) async {
    final response = await http.delete(
      Uri.parse('http://26.149.114.62:5000/api/partners/deleteListing/$listingId'),
      headers: {'Content-Type': 'application/json'},
    );

    if (response.statusCode == 200) {
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(
        content: Text('Listing deleted successfully!'),
      ));
      _fetchListings(); // Refresh listings after deletion
    } else {
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(
        content: Text('Failed to delete listing'),
      ));
    }
  }

  // Navigate to edit page
  void _navigateToEditListing(String listingId) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => EditListingPage(listingId: listingId),
      ),
    ).then((value) {
      _fetchListings(); // Refresh listings after editing
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text('Manage Listings')),
      body: _listings.isEmpty
          ? Center(child: CircularProgressIndicator())
          : ListView.builder(
              itemCount: _listings.length,
              itemBuilder: (context, index) {
                final listing = _listings[index];
                return Card(
                  margin: EdgeInsets.all(8.0),
                  child: ListTile(
                    title: Text(listing['name']),
                    subtitle: Text('${listing['type']} - ${listing['location']}'),
                    trailing: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        IconButton(
                          icon: Icon(Icons.edit, color: Colors.blue),
                          onPressed: () => _navigateToEditListing(listing['id']),
                        ),
                        IconButton(
                          icon: Icon(Icons.delete, color: Colors.red),
                          onPressed: () => _deleteListing(listing['id']),
                        ),
                      ],
                    ),
                  ),
                );
              },
            ),
    );
  }
}
