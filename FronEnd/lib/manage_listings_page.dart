import 'package:flutter/material.dart';
import 'package:flutter_application_1/edit_listing_page.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';

import 'package:shared_preferences/shared_preferences.dart';

class ManageListingsPage extends StatefulWidget {
  @override
  _ManageListingsPageState createState() => _ManageListingsPageState();
}

class _ManageListingsPageState extends State<ManageListingsPage> {
  List<dynamic> _listings = [];
  bool _isLoading = true;
  String email = '';

  @override
  void initState() {
    super.initState();
    _loadUserData().then((_) {
      _fetchListings();
    });
  }

  Future<void> _loadUserData() async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    setState(() {
      email = prefs.getString('email') ?? 'defaultEmail';
    });
  }

  // Fetch partner's listings from the backend
  Future<void> _fetchListings() async {
    setState(() {
      _isLoading = true;
    });
    try {
      final response = await http.get(
        Uri.parse('http://26.149.114.62:5000/api/partners/myListings?owner=$email'),
        headers: {'Content-Type': 'application/json'},
      );

      if (response.statusCode == 200) {
        setState(() {
          _listings = json.decode(response.body);
          _isLoading = false;
        });
      } else {
        setState(() {
          _isLoading = false;
        });
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(
          content: Text('Failed to load listings'),
        ));
      }
    } catch (e) {
      setState(() {
        _isLoading = false;
      });
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(
        content: Text('Error: $e'),
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
      body: _isLoading
          ? Center(child: CircularProgressIndicator())
          : _listings.isEmpty
              ? Center(child: Text('No listings available'))
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
                            //IconButton(
                              //icon: Icon(Icons.edit, color: Colors.blue),
                              //onPressed: () => _navigateToEditListing(listing['_id']),
                           // ),
                            IconButton(
                              icon: Icon(Icons.delete, color: Colors.red),
                              onPressed: () => _deleteListing(listing['_id']),
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
