import 'dart:io';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:image_picker/image_picker.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:geolocator/geolocator.dart';
import 'LocationPicker.dart';

class AddListingPage extends StatefulWidget {
  @override
  _AddListingPageState createState() => _AddListingPageState();
}

class _AddListingPageState extends State<AddListingPage> {
  String email = '';
  LatLng? _selectedLocation;
  File? _selectedImage;

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

  Future<void> _pickImage() async {
    final pickedFile = await ImagePicker().pickImage(source: ImageSource.gallery);
    if (pickedFile != null) {
      setState(() {
        _selectedImage = File(pickedFile.path);
      });
    }
  }

  Future<void> _submitListing() async {
    if (_nameController.text.isEmpty ||
        _descriptionController.text.isEmpty ||
        _priceController.text.isEmpty ||
        _roomsController.text.isEmpty ||
        _selectedLocation == null ||
        _selectedImage == null) {
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(
        content: Text('Please fill all fields and select an image.'),
      ));
      return;
    }

    try {
      var request = http.MultipartRequest(
        'POST',
        Uri.parse('http://26.149.114.62:5000/api/addListing'),
      );

      request.fields['name'] = _nameController.text;
      request.fields['description'] = _descriptionController.text;
      request.fields['price'] = _priceController.text;
      request.fields['rooms'] = _roomsController.text;
      request.fields['amenities'] = _amenitiesController.text;
      request.fields['location[latitude]'] = _selectedLocation!.latitude.toString();
      request.fields['location[longitude]'] = _selectedLocation!.longitude.toString();
      request.fields['owner'] = email;

      request.files.add(await http.MultipartFile.fromPath('image', _selectedImage!.path));

      var response = await request.send();

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
      _selectedImage = null;
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
                onPressed: _pickImage,
                child: Text('Select Image'),
              ),
              if (_selectedImage != null)
                Image.file(
                  _selectedImage!,
                  height: 150,
                  width: 150,
                  fit: BoxFit.cover,
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
