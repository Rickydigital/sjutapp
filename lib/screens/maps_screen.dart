import 'package:flutter/material.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:geolocator/geolocator.dart';
import 'package:flutter_typeahead/flutter_typeahead.dart';
import 'package:webview_flutter/webview_flutter.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:sjut/services/api_service.dart'; // Import your ApiService

class MapScreen extends StatefulWidget {
  const MapScreen({super.key});

  @override
  MapScreenState createState() => MapScreenState();
}

class MapScreenState extends State<MapScreen> {
  LatLng _currentPosition = const LatLng(-6.1736, 35.8684); // Default fallback
  bool _isLocationReady = false;
  late GoogleMapController _mapController;
  late WebViewController _webViewController;
  String? _selectedLocation;
  final TextEditingController _typeAheadController = TextEditingController();
  List<Map<String, dynamic>> _locations = [];
  final ApiService _apiService = ApiService(); // Instantiate ApiService

  @override
  void initState() {
    super.initState();
    _getCurrentLocation();
    _fetchVenues();
    _webViewController = WebViewController()
      ..setJavaScriptMode(JavaScriptMode.unrestricted)
      ..setBackgroundColor(const Color(0x00000000))
      ..loadRequest(Uri.parse('https://www.google.com'));
  }

  // Fetch venues using ApiService
  Future<void> _fetchVenues() async {
    try {
      final venues = await _apiService.fetchVenues();
      if (mounted) {
        setState(() {
          _locations = venues;
        });
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error fetching venues: $e')),
        );
      }
    }
  }

  // Fetch the user's current location
  Future<void> _getCurrentLocation() async {
    bool serviceEnabled;
    LocationPermission permission;

    serviceEnabled = await Geolocator.isLocationServiceEnabled();
    if (!serviceEnabled) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Location services are disabled')),
        );
      }
      setState(() => _isLocationReady = false);
      return;
    }

    permission = await Geolocator.checkPermission();
    if (permission == LocationPermission.denied) {
      permission = await Geolocator.requestPermission();
      if (permission == LocationPermission.denied) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Location permission denied')),
          );
        }
        setState(() => _isLocationReady = false);
        return;
      }
    }

    Position position = await Geolocator.getCurrentPosition(desiredAccuracy: LocationAccuracy.high);
    if (mounted) {
      setState(() {
        _currentPosition = LatLng(position.latitude, position.longitude);
        _isLocationReady = true;
      });
    }
  }

  // Handle location selection
  void _onLocationSelected(Map<String, dynamic> location) {
    final position = LatLng(location['lat'], location['lng']);
    _mapController.animateCamera(
      CameraUpdate.newLatLngZoom(position, 18.0),
    );
    setState(() => _selectedLocation = location['name']);

    // Load Street View in WebView
    final streetViewUrl =
        'https://www.google.com/maps/@${location['lat']},${location['lng']},3a,75y,90t/data=!3m6!1e1!3m4!1s!2e0!7i13312!8i6656';
    _webViewController.loadRequest(Uri.parse(streetViewUrl));
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Street View loaded below')),
      );
    }
  }

  // Launch directions in Google Maps app
  Future<void> _launchDirections(LatLng destination) async {
    if (!_isLocationReady) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Current location not available')),
        );
      }
      return;
    }
    final url =
        'https://www.google.com/maps/dir/?api=1&origin=${_currentPosition.latitude},${_currentPosition.longitude}&destination=${destination.latitude},${destination.longitude}&travelmode=walking';
    if (await canLaunchUrl(Uri.parse(url))) {
      await launchUrl(Uri.parse(url));
    } else {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Could not launch directions')),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('St. John\'s University Map'),
      ),
      body: Column(
        children: [
          // Location search
          Padding(
            padding: const EdgeInsets.all(8.0),
            child: TypeAheadField<Map<String, dynamic>>(
              builder: (context, controller, focusNode) {
                return TextField(
                  controller: _typeAheadController,
                  focusNode: focusNode,
                  decoration: const InputDecoration(
                    labelText: 'Search or Select Location',
                    border: OutlineInputBorder(),
                  ),
                );
              },
              suggestionsCallback: (pattern) async {
                return _locations
                    .where((location) => location['name'].toLowerCase().contains(pattern.toLowerCase()))
                    .toList();
              },
              itemBuilder: (context, Map<String, dynamic> suggestion) {
                return ListTile(
                  title: Text(suggestion['name']),
                );
              },
              onSelected: _onLocationSelected,
            ),
          ),
          // Map View
          Expanded(
            flex: 2,
            child: GoogleMap(
              mapType: MapType.normal,
              initialCameraPosition: const CameraPosition(
                target: LatLng(-6.1736, 35.8684), // St. John's as fallback
                zoom: 16.0,
              ),
              onMapCreated: (GoogleMapController controller) {
                _mapController = controller;
              },
              markers: {
                for (var location in _locations)
                  Marker(
                    markerId: MarkerId(location['name']),
                    position: LatLng(location['lat'], location['lng']),
                    infoWindow: InfoWindow(title: location['name']),
                  ),
                if (_isLocationReady)
                  Marker(
                    markerId: const MarkerId('currentLocation'),
                    position: _currentPosition,
                    icon: BitmapDescriptor.defaultMarkerWithHue(BitmapDescriptor.hueBlue),
                    infoWindow: const InfoWindow(title: 'You are here'),
                  ),
              },
            ),
          ),
          // Street View WebView
          SizedBox(
            height: 300,
            child: WebViewWidget(
              controller: _webViewController,
            ),
          ),
        ],
      ),
      floatingActionButton: Column(
        mainAxisAlignment: MainAxisAlignment.end,
        children: [
          FloatingActionButton(
            heroTag: 'directions',
            onPressed: () {
              if (_selectedLocation != null) {
                final selected = _locations.firstWhere((loc) => loc['name'] == _selectedLocation);
                _launchDirections(LatLng(selected['lat'], selected['lng']));
              } else {
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text('Please select a location first')),
                );
              }
            },
            child: const Icon(Icons.directions),
          ),
          const SizedBox(height: 10),
          FloatingActionButton(
            heroTag: 'myLocation',
            onPressed: () {
              if (_isLocationReady) {
                _mapController.animateCamera(
                  CameraUpdate.newLatLng(_currentPosition),
                );
              } else {
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text('Current location not available')),
                );
              }
            },
            child: const Icon(Icons.my_location),
          ),
        ],
      ),
    );
  }
}