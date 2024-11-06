import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';

class AddListingPage extends StatefulWidget {
  @override
  _AddListingPageState createState() => _AddListingPageState();
}

class _AddListingPageState extends State<AddListingPage> {
  String email = '';
  @override
  void initState() {
    super.initState();
    _loadUserData();
  }

  final TextEditingController _nameController = TextEditingController();
  final TextEditingController _locationController = TextEditingController();
  final TextEditingController _descriptionController = TextEditingController();
  String _type = 'restaurant'; // Dropdown selection

  Future<void> _loadUserData() async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    setState(() {
      email = prefs.getString('email') ?? 'defaultEmail';
    });
  }

  Future<void> _submitListing() async {
  final response = await http.post(
    Uri.parse('http://26.149.114.62:5000/api/partners/addListing'),
    headers: {'Content-Type': 'application/json'},
    body: json.encode({
      'name': _nameController.text,
      'location': _locationController.text,
      'description': _descriptionController.text,
      'type': _type,
      'owner': email,
      // other necessary data
    }),
  );

  if (response.statusCode == 200) {
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(
      content: Text('Listing added successfully!'),
    ));

    // Clear the form fields after successful submission
    _nameController.clear();
    _locationController.clear();
    _descriptionController.clear();
    setState(() {
      _type = 'restaurant'; // Reset the dropdown value
    });
  } else {
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(
      content: Text('Failed to add listing.'),
    ));
  }
}


  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text('Add New Listing')),
      body: Padding(
        padding: EdgeInsets.all(16.0),
        child: Column(
          children: [
            TextField(
                controller: _nameController,
                decoration: InputDecoration(labelText: 'Name')),
            TextField(
                controller: _locationController,
                decoration: InputDecoration(labelText: 'Location')),
            TextField(
                controller: _descriptionController,
                decoration: InputDecoration(labelText: 'Description')),
            DropdownButton<String>(
              value: _type,
              onChanged: (String? newValue) {
                setState(() {
                  _type = newValue!;
                });
              },
              items: <String>['restaurant', 'resort']
                  .map<DropdownMenuItem<String>>((String value) {
                return DropdownMenuItem<String>(
                  value: value,
                  child: Text(value),
                );
              }).toList(),
            ),
            ElevatedButton(onPressed: _submitListing, child: Text('Submit'))
          ],
        ),
      ),
    );
  }
}
