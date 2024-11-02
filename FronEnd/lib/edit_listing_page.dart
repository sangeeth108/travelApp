import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';

class EditListingPage extends StatefulWidget {
  final String listingId;

  EditListingPage({required this.listingId});

  @override
  _EditListingPageState createState() => _EditListingPageState();
}

class _EditListingPageState extends State<EditListingPage> {
  final _formKey = GlobalKey<FormState>();
  TextEditingController _nameController = TextEditingController();
  TextEditingController _typeController = TextEditingController();
  TextEditingController _locationController = TextEditingController();
  
  @override
  void initState() {
    super.initState();
    _fetchListingDetails();
  }

  // Fetch listing details from the backend
  Future<void> _fetchListingDetails() async {
    final response = await http.get(
      Uri.parse('http://26.149.114.62:5000/api/partners/getListing/${widget.listingId}'),
      headers: {'Content-Type': 'application/json'},
    );

    if (response.statusCode == 200) {
      final listing = json.decode(response.body);
      setState(() {
        _nameController.text = listing['name'];
        _typeController.text = listing['type'];
        _locationController.text = listing['location'];
      });
    } else {
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(
        content: Text('Failed to load listing details'),
      ));
    }
  }

  // Update listing
  Future<void> _updateListing() async {
    if (_formKey.currentState!.validate()) {
      final response = await http.put(
        Uri.parse('http://26.149.114.62:5000/api/partners/updateListing/${widget.listingId}'),
        headers: {'Content-Type': 'application/json'},
        body: json.encode({
          'name': _nameController.text,
          'type': _typeController.text,
          'location': _locationController.text,
        }),
      );

      if (response.statusCode == 200) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(
          content: Text('Listing updated successfully!'),
        ));
        Navigator.pop(context, true); // Return to previous screen
      } else {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(
          content: Text('Failed to update listing'),
        ));
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text('Edit Listing')),
      body: Padding(
        padding: EdgeInsets.all(16.0),
        child: Form(
          key: _formKey,
          child: Column(
            children: [
              TextFormField(
                controller: _nameController,
                decoration: InputDecoration(labelText: 'Name'),
                validator: (value) {
                  if (value == null || value.isEmpty) {
                    return 'Please enter a name';
                  }
                  return null;
                },
              ),
              TextFormField(
                controller: _typeController,
                decoration: InputDecoration(labelText: 'Type'),
                validator: (value) {
                  if (value == null || value.isEmpty) {
                    return 'Please enter a type';
                  }
                  return null;
                },
              ),
              TextFormField(
                controller: _locationController,
                decoration: InputDecoration(labelText: 'Location'),
                validator: (value) {
                  if (value == null || value.isEmpty) {
                    return 'Please enter a location';
                  }
                  return null;
                },
              ),
              SizedBox(height: 20),
              ElevatedButton(
                onPressed: _updateListing,
                child: Text('Update Listing'),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
