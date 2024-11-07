import 'package:flutter/material.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';

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

  void _onCameraMove(CameraPosition position) {
    print("Zoom level: ${position.zoom}");
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
            onMapCreated: (GoogleMapController controller) {
              _mapController = controller;
            },
            onCameraMove: _onCameraMove,
          ),
          Positioned(
            bottom: 32,
            left: 16,
            right: 16,
            child: Container(
              height: 40,  // Set a smaller height
              width: double.infinity,  // Make it stretch horizontally if needed
              child: ElevatedButton(
                style: ElevatedButton.styleFrom(
                  padding: EdgeInsets.symmetric(vertical: 10, horizontal: 50), // Smaller padding
                  textStyle: TextStyle(fontSize: 14), // Smaller text size
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(10),  // Optional rounded corners
                  ),
                ),
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
