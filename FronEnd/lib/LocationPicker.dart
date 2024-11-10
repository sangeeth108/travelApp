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

  void _onMapCreated(GoogleMapController controller) {
    _mapController = controller;

    // Move the camera to the desired initial location
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
            onCameraMove: _onCameraMove,
          ),
          Positioned(
            bottom: 32,
            left: 55,
            right: 55,
            child: Container(
              height: 40,
              child: ElevatedButton(
                style: ElevatedButton.styleFrom(
                  padding: EdgeInsets.symmetric(vertical: 10, horizontal: 50),
                  textStyle: TextStyle(fontSize: 14),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(10),
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

// Example of how to use LocationPicker with the new default location
void main() {
  runApp(MaterialApp(
    home: LocationPicker(
      initialLocation: LatLng(6.922329701532135, 79.85313188284636),  // Default opening location
    ),
  ));
}
