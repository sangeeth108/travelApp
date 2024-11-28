import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:geolocator/geolocator.dart';
import 'LocationPicker.dart'; // Import the LocationPicker widget

class AddListingPage extends StatefulWidget {
  @override
  _AddListingPageState createState() => _AddListingPageState();
}

class _AddListingPageState extends State<AddListingPage> {
  String email = '';
  LatLng? _selectedLocation;

  final TextEditingController _nameController = TextEditingController();
  final TextEditingController _locationController = TextEditingController();
  final TextEditingController _descriptionController = TextEditingController();
  final TextEditingController _priceController = TextEditingController();
  final TextEditingController _roomsController = TextEditingController();
  final TextEditingController _amenitiesController = TextEditingController();

  @override
  void initState() {
    super.initState();
    _loadUserData();
  }

  Future<void> _loadUserData() async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    setState(() {
      email = prefs.getString('email') ?? 'defaultEmail';
    });
  }

  Future<void> _selectLocation() async {
    // Check for location permissions
    LocationPermission permission = await Geolocator.checkPermission();
    if (permission == LocationPermission.denied ||
        permission == LocationPermission.deniedForever) {
      permission = await Geolocator.requestPermission();
      if (permission != LocationPermission.whileInUse &&
          permission != LocationPermission.always) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Location permission is required.')),
        );
        return;
      }
    }

    // Get current position
    Position position = await Geolocator.getCurrentPosition(
      desiredAccuracy: LocationAccuracy.high,
    );
    LatLng initialLocation = LatLng(position.latitude, position.longitude);

    // Navigate to LocationPicker screen to select location
    LatLng? pickedLocation = await Navigator.of(context).push(
      MaterialPageRoute(
        builder: (context) => LocationPicker(initialLocation: initialLocation),
      ),
    );

    if (pickedLocation != null) {
      setState(() {
        _selectedLocation = pickedLocation;
        _locationController.text =
            '${_selectedLocation!.latitude}, ${_selectedLocation!.longitude}';
      });
    }
  }

  Future<void> _submitListing() async {
    // Validate required fields
    if (_nameController.text.isEmpty ||
        _descriptionController.text.isEmpty ||
        _priceController.text.isEmpty ||
        _roomsController.text.isEmpty ||
        _selectedLocation == null) {
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(
        content: Text('Please fill all fields and select a location.'),
      ));
      return;
    }

    try {
      final response = await http.post(
        Uri.parse('http://26.149.114.62:5000/api/addListing'),
        headers: {'Content-Type': 'application/json'},
        body: json.encode({
          'name': _nameController.text,
          'description': _descriptionController.text,
          'price': double.parse(_priceController.text),
          'rooms': int.parse(_roomsController.text),
          'amenities': _amenitiesController.text.split(','),
          'location': {
            'latitude': _selectedLocation!.latitude,
            'longitude': _selectedLocation!.longitude,
          },
          'owner': email,
        }),
      );

      if (response.statusCode == 200) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(
          content: Text('Listing added successfully!'),
        ));
        _clearFields();
      } else {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(
          content: Text('Failed to add listing. Please try again.'),
        ));
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(
        content: Text('An error occurred. Please try again later.'),
      ));
    }
  }

  void _clearFields() {
    _nameController.clear();
    _locationController.clear();
    _descriptionController.clear();
    _priceController.clear();
    _roomsController.clear();
    _amenitiesController.clear();
    setState(() {
      _selectedLocation = null;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text('Add New Listing')),
      body: Padding(
        padding: EdgeInsets.all(16.0),
        child: SingleChildScrollView(
          child: Column(
            children: [
              TextField(
                controller: _nameController,
                decoration: InputDecoration(labelText: 'Hotel Name'),
              ),
              TextField(
                controller: _descriptionController,
                decoration: InputDecoration(labelText: 'Description'),
                maxLines: 3,
              ),
              TextField(
                controller: _priceController,
                keyboardType: TextInputType.number,
                decoration: InputDecoration(labelText: 'Price per Night'),
              ),
              TextField(
                controller: _roomsController,
                keyboardType: TextInputType.number,
                decoration: InputDecoration(labelText: 'Number of Rooms'),
              ),
              TextField(
                controller: _amenitiesController,
                decoration: InputDecoration(
                  labelText: 'Amenities (comma-separated)',
                ),
              ),
              TextField(
                controller: _locationController,
                readOnly: true,
                decoration: InputDecoration(labelText: 'Location (Lat, Lng)'),
              ),
              ElevatedButton(
                onPressed: _selectLocation,
                child: Text('Select Location on Map'),
              ),
              ElevatedButton(
                onPressed: _submitListing,
                child: Text('Submit Listing'),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
