import 'package:flutter/material.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'package:intl/intl.dart';

class CreateTripPage extends StatefulWidget {
  @override
  _CreateTripScreenState createState() => _CreateTripScreenState();
}

class _CreateTripScreenState extends State<CreateTripPage> {
  final TextEditingController _tripNameController = TextEditingController();
  final TextEditingController _participantsController = TextEditingController(); // Controller for participants input
  DateTime? _startDate;
  DateTime? _endDate;
  LatLng? _startLocation;
  LatLng? _destination;

  // Save email to SharedPreferences (example for login/signup flow)
  Future<void> saveEmail(String email) async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    await prefs.setString('email', email);
  }

  // Retrieve email from SharedPreferences
  Future<String?> _getEmail() async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    return prefs.getString('email');
  }

  Future<void> _pickLocation(bool isStartLocation) async {
    LatLng initialLocation = LatLng(6.922329701532135, 79.85313188284636);
    LatLng? pickedLocation = await Navigator.of(context).push(
      MaterialPageRoute(
        builder: (context) => LocationPicker(initialLocation: initialLocation),
      ),
    );

    if (pickedLocation != null) {
      setState(() {
        if (isStartLocation) {
          _startLocation = pickedLocation;
        } else {
          _destination = pickedLocation;
        }
      });
    }
  }

  Future<void> _createTrip() async {
    String? email = await _getEmail();

    if (email == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Please log in to create a trip.')),
      );
      return;
    }

    final response = await http.post(
      Uri.parse('http://26.149.114.62:5000/api/trips/create'), // Replace with your actual API endpoint
      headers: {'Content-Type': 'application/json'},
      body: json.encode({
        'trip_name': _tripNameController.text,
        'start_location': {
          'latitude': _startLocation!.latitude,
          'longitude': _startLocation!.longitude,
        },
        'destination': {
          'latitude': _destination!.latitude,
          'longitude': _destination!.longitude,
        },
        'start_date': DateFormat('yyyy-MM-dd').format(_startDate!),
        'end_date': DateFormat('yyyy-MM-dd').format(_endDate!),
        'created_by': email,
        'participants': _participantsController.text.split(','), // Split participants by comma
      }),
    );

    if (response.statusCode == 200) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Trip created successfully!')),
      );

      // Clear form fields after success
      _tripNameController.clear();
      _participantsController.clear(); // Clear participants field
      setState(() {
        _startDate = null;
        _endDate = null;
        _startLocation = null;
        _destination = null;
      });
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Failed to create trip. Try again.')),
      );
    }
  }

  Future<void> _selectDate(BuildContext context, bool isStartDate) async {
    DateTime? pickedDate = await showDatePicker(
      context: context,
      initialDate: DateTime.now(),
      firstDate: DateTime.now(),
      lastDate: DateTime(2100),
    );

    if (pickedDate != null) {
      setState(() {
        if (isStartDate) {
          _startDate = pickedDate;
        } else {
          _endDate = pickedDate;
        }
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text('Create Trip')),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          children: [
            TextField(
              controller: _tripNameController,
              decoration: InputDecoration(labelText: 'Trip Name'),
            ),
            SizedBox(height: 10),
            ElevatedButton(
              onPressed: () => _selectDate(context, true),
              child: Text(_startDate == null
                  ? 'Select Start Date'
                  : 'Start Date: ${DateFormat('yyyy-MM-dd').format(_startDate!)}'),
            ),
            SizedBox(height: 10),
            ElevatedButton(
              onPressed: () => _selectDate(context, false),
              child: Text(_endDate == null
                  ? 'Select End Date'
                  : 'End Date: ${DateFormat('yyyy-MM-dd').format(_endDate!)}'),
            ),
            SizedBox(height: 10),
            ElevatedButton(
              onPressed: () => _pickLocation(true),
              child: Text(
                  _startLocation == null ? 'Pick Start Location' : 'Start Location Selected'),
            ),
            SizedBox(height: 10),
            ElevatedButton(
              onPressed: () => _pickLocation(false),
              child: Text(
                  _destination == null ? 'Pick Destination' : 'Destination Selected'),
            ),
            SizedBox(height: 20),
            TextField(
              controller: _participantsController,
              decoration: InputDecoration(
                labelText: 'Participants (comma-separated emails)',
                hintText: 'Enter participant emails separated by commas',
              ),
            ),
            SizedBox(height: 20),
            ElevatedButton(
              onPressed: _createTrip,
              child: Text('Create Trip'),
            ),
          ],
        ),
      ),
    );
  }
}

// LocationPicker Widget for selecting locations on Google Maps
class LocationPicker extends StatefulWidget {
  final LatLng initialLocation;

  LocationPicker({required this.initialLocation});

  @override
  _LocationPickerState createState() => _LocationPickerState();
}

class _LocationPickerState extends State<LocationPicker> {
  late GoogleMapController _mapController;
  LatLng? _pickedLocation;

  @override
  void initState() {
    super.initState();
    _pickedLocation = widget.initialLocation;
  }

  void _onMapTapped(LatLng position) {
    setState(() {
      _pickedLocation = position;
    });
  }

  void _confirmLocation() {
    if (_pickedLocation != null) {
      Navigator.of(context).pop(_pickedLocation);
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Please select a location.')),
      );
    }
  }

  void _onMapCreated(GoogleMapController controller) {
    _mapController = controller;
    _mapController.moveCamera(
      CameraUpdate.newLatLng(widget.initialLocation),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text('Pick Location')),
      body: Stack(
        children: [
          GoogleMap(
            initialCameraPosition: CameraPosition(
              target: widget.initialLocation,
              zoom: 5,
            ),
            markers: _pickedLocation != null
                ? {
                    Marker(
                      markerId: MarkerId('picked-location'),
                      position: _pickedLocation!,
                      draggable: true,
                      onDragEnd: (newPosition) {
                        setState(() {
                          _pickedLocation = newPosition;
                        });
                      },
                    ),
                  }
                : {},
            onTap: _onMapTapped,
            onMapCreated: _onMapCreated,
          ),
          Positioned(
            bottom: 32,
            left: 55,
            right: 55,
            child: Container(
              height: 40,
              child: ElevatedButton(
                onPressed: _confirmLocation,
                child: Text('Confirm Location'),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
