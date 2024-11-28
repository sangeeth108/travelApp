import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;

class TripDetailsPage extends StatefulWidget {
  final String tripId;

  TripDetailsPage({required this.tripId});

  @override
  _TripDetailsPageState createState() => _TripDetailsPageState();
}

class _TripDetailsPageState extends State<TripDetailsPage> {
  Map<String, dynamic>? tripDetails;
  Map<String, dynamic>? weatherDetails;
  List<dynamic> nearbyPlaces = [];
  bool isLoading = true;
  final TextEditingController _newParticipantController =
      TextEditingController();
  final String googleApiKey = 'AIzaSyDVgUx51rYmxJ5OxQ-F6ec0USEGeUWbHac';

  @override
  void initState() {
    super.initState();
    _fetchTripDetails();
  }

  Future<void> _fetchTripDetails() async {
    final tripUrl = 'http://26.149.114.62:5000/api/trips/${widget.tripId}';

    try {
      final response = await http.get(Uri.parse(tripUrl));

      if (response.statusCode == 200) {
        setState(() {
          tripDetails = json.decode(response.body);
        });
        //await _fetchWeatherDetails();
        await _fetchNearbyPlaces();
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Failed to load trip details.')),
        );
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('An error occurred. Please try again later.')),
      );
    }
  }

  /*Future<void> _fetchWeatherDetails() async {
    if (tripDetails == null) return;

    final latitude = tripDetails!['destination']['latitude'];
    final longitude = tripDetails!['destination']['longitude'];
    final weatherUrl =
        'https://api.openweathermap.org/data/2.5/weather?lat=$latitude&lon=$longitude&appid=392cb59f772e4361d30eeb6807906bcd&units=metric';

    try {
      final response = await http.get(Uri.parse(weatherUrl));

      if (response.statusCode == 200) {
        setState(() {
          weatherDetails = json.decode(response.body);
        });
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Failed to load weather details.')),
        );
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('An error occurred while fetching weather.')),
      );
    }
  }*/

  Future<void> _fetchNearbyPlaces() async {
    if (tripDetails == null) return;

    final latitude = tripDetails!['destination']['latitude'];
    final longitude = tripDetails!['destination']['longitude'];
    final placesUrl =
        'https://maps.googleapis.com/maps/api/place/nearbysearch/json?location=$latitude,$longitude&radius=10000&type=tourist_attraction&key=$googleApiKey';

    try {
      final response = await http.get(Uri.parse(placesUrl));

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        setState(() {
          nearbyPlaces = data['results'].take(5).toList(); // Show top 5 places
          isLoading = false;
        });
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Failed to load nearby places.')),
        );
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
            content: Text('An error occurred while fetching nearby places.')),
      );
    }
  }

  Future<void> _addParticipant() async {
    final newParticipant = _newParticipantController.text.trim();
    if (newParticipant.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Please enter a participant email.')),
      );
      return;
    }

    final url =
        'http://26.149.114.62:5000/api/trips/${widget.tripId}/add-participant';
    try {
      final response = await http.post(
        Uri.parse(url),
        headers: {'Content-Type': 'application/json'},
        body: json.encode({'participant': newParticipant}),
      );

      if (response.statusCode == 200) {
        setState(() {
          tripDetails!['participants'].add(newParticipant);
          _newParticipantController.clear();
        });
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Participant added successfully!')),
        );
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Failed to add participant.')),
        );
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('An error occurred. Please try again later.')),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text('Trip Details')),
      body: isLoading
          ? Center(child: CircularProgressIndicator())
          : tripDetails == null
              ? Center(child: Text('No trip details available.'))
              : Padding(
                  padding: EdgeInsets.all(16.0),
                  child: SingleChildScrollView(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          tripDetails!['tripName'] ?? 'Trip Name',
                          style: TextStyle(
                              fontSize: 24, fontWeight: FontWeight.bold),
                        ),
                        SizedBox(height: 16),
                        Text(
                          'Start Location: ${tripDetails!['startLocation']['latitude']}, ${tripDetails!['startLocation']['longitude']}',
                        ),
                        SizedBox(height: 8),
                        Text(
                          'Destination: ${tripDetails!['destination']['latitude']}, ${tripDetails!['destination']['longitude']}',
                        ),
                        SizedBox(height: 8),
                        Text(
                          'Start Date: ${tripDetails!['startDate']}',
                        ),
                        SizedBox(height: 8),
                        Text(
                          'End Date: ${tripDetails!['endDate']}',
                        ),
                        SizedBox(height: 8),
                        Text(
                          'Created By: ${tripDetails!['createdBy']}',
                        ),
                        SizedBox(height: 16),
                        Text('Participants:'),
                        for (var participant in tripDetails!['participants'])
                          Text(participant),
                        SizedBox(height: 20),
                        if (weatherDetails != null) ...[
                          Text(
                            'Weather at Destination:',
                            style: TextStyle(
                                fontSize: 18, fontWeight: FontWeight.bold),
                          ),
                          SizedBox(height: 8),
                          Text(
                            'Condition: ${weatherDetails!['weather'][0]['description']}',
                          ),
                          Text(
                            'Temperature: ${weatherDetails!['main']['temp']}°C',
                          ),
                          Text(
                            'Wind Speed: ${weatherDetails!['wind']['speed']} m/s',
                          ),
                          SizedBox(height: 20),
                        ],
                        Text(
                          'Nearby Places to Visit:',
                          style: TextStyle(
                              fontSize: 18, fontWeight: FontWeight.bold),
                        ),
                        SizedBox(height: 8),
                        for (var place in nearbyPlaces)
                          Text('- ${place['name']}'),
                        ElevatedButton(
                          onPressed: () {
                            Navigator.push(
                              context,
                              MaterialPageRoute(
                                builder: (context) => SeeMorePlacesPage(
                                  places: nearbyPlaces,
                                  latitude: tripDetails!['destination']
                                      ['latitude'],
                                  longitude: tripDetails!['destination']
                                      ['longitude'],
                                ),
                              ),
                            );
                          },
                          child: Text('See More'),
                        ),
                        SizedBox(height: 20),
                        TextField(
                          controller: _newParticipantController,
                          decoration: InputDecoration(
                            labelText: 'Add More Participant',
                            hintText: 'Enter participant email',
                          ),
                        ),
                        SizedBox(height: 10),
                        ElevatedButton(
                          onPressed: _addParticipant,
                          child: Text('Add Participant'),
                        ),
                      ],
                    ),
                  ),
                ),
    );
  }
}

class SeeMorePlacesPage extends StatefulWidget {
  final double latitude;
  final double longitude;

  SeeMorePlacesPage({required this.latitude, required this.longitude, required List places});

  @override
  _SeeMorePlacesPageState createState() => _SeeMorePlacesPageState();
}

class _SeeMorePlacesPageState extends State<SeeMorePlacesPage> {
  List<dynamic> touristAttractions = [];
  List<dynamic> hotels = [];
  List<dynamic> restaurants = [];
  List<dynamic> sortedPlaces = []; // List to hold the sorted places
  bool isLoading = true;
  final String googleApiKey = 'AIzaSyDVgUx51rYmxJ5OxQ-F6ec0USEGeUWbHac'; // Replace with your API key

  String selectedCategory = 'Tourist Attractions'; // Default selection for the dropdown

  // Fetch places based on the selected category
  Future<void> _fetchNearbyPlaces(String category) async {
    String placeType = '';

    if (category == 'Tourist Attractions') {
      placeType = 'tourist_attraction';
    } else if (category == 'Restaurants') {
      placeType = 'restaurant';
    }
    final placesUrl =
        'https://maps.googleapis.com/maps/api/place/nearbysearch/json?location=${widget.latitude},${widget.longitude}&radius=10000&type=$placeType&key=$googleApiKey';

    try {
      final response = await http.get(Uri.parse(placesUrl));

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        setState(() {
          touristAttractions = [];
          restaurants = [];

          for (var place in data['results']) {
            if (place['types'] != null) {
              if (place['types'].contains('tourist_attraction')) {
                touristAttractions.add(place);
              } else if (place['types'].contains('restaurant')) {
                restaurants.add(place);
              }
            }
          }
          _updateCategory(category);
          isLoading = false;
        });
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Failed to load nearby places.')),
        );
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('An error occurred while fetching nearby places.')),
      );
    }
  }

  // Function to update the list based on the selected category
  void _updateCategory(String category) {
    setState(() {
      selectedCategory = category;
      if (category == 'Tourist Attractions') {
        sortedPlaces = touristAttractions;
      } else if (category == 'Restaurants') {
        sortedPlaces = restaurants;
      }
    });
  }

  @override
  void initState() {
    super.initState();
    _fetchNearbyPlaces(selectedCategory); // Fetch places on initial load
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text('Nearby Places')),
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.all(8.0),
            child: DropdownButton<String>(
              value: selectedCategory,
              onChanged: (String? newValue) {
                if (newValue != null) {
                  _updateCategory(newValue); // Update category
                  _fetchNearbyPlaces(newValue); // Fetch places based on new category
                }
              },
              items: <String>['Tourist Attractions', 'Restaurants']
                  .map<DropdownMenuItem<String>>((String value) {
                return DropdownMenuItem<String>(
                  value: value,
                  child: Text(value),
                );
              }).toList(),
            ),
          ),
          Expanded(
            child: isLoading
                ? Center(child: CircularProgressIndicator())
                : sortedPlaces.isEmpty
                    ? Center(child: Text('No nearby places found.'))
                    : ListView.builder(
                        itemCount: sortedPlaces.length,
                        itemBuilder: (context, index) {
                          return ListTile(
                            title: Text(sortedPlaces[index]['name']),
                            subtitle: Text(
                              sortedPlaces[index]['vicinity'] ?? 'No location data available',
                            ),
                          );
                        },
                      ),
          ),
        ],
      ),
    );
  }
}