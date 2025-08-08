import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:latlong2/latlong.dart';
import 'package:geolocator/geolocator.dart';
import 'package:geocoding/geocoding.dart';
import '../models/colours.dart';

class MapPickerScreen extends StatefulWidget {
  static const routeName = '/map-picker';

  const MapPickerScreen({super.key});

  @override
  State<MapPickerScreen> createState() => _MapPickerScreenState();
}

class _MapPickerScreenState extends State<MapPickerScreen> {
  final MapController _mapController = MapController();
  LatLng _selectedLocation = const LatLng(1.3521, 103.8198); // Singapore center
  String _selectedAddress = 'Loading...';
  bool _isLoading = false;
  final TextEditingController _searchController = TextEditingController();

  @override
  void initState() {
    super.initState();
    _getCurrentLocation();
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  Future<void> _getCurrentLocation() async {
    try {
      bool serviceEnabled = await Geolocator.isLocationServiceEnabled();
      if (!serviceEnabled) return;

      LocationPermission permission = await Geolocator.checkPermission();
      if (permission == LocationPermission.denied) {
        permission = await Geolocator.requestPermission();
        if (permission == LocationPermission.denied) return;
      }

      if (permission == LocationPermission.deniedForever) return;

      final position = await Geolocator.getCurrentPosition();
      setState(() {
        _selectedLocation = LatLng(position.latitude, position.longitude);
      });

      _mapController.move(_selectedLocation, 15.0);
      _getAddressFromCoordinates(_selectedLocation);
    } catch (e) {
      print('Error getting location: $e');
    }
  }

  Future<void> _getAddressFromCoordinates(LatLng location) async {
    setState(() => _isLoading = true);

    try {
      List<Placemark> placemarks = await placemarkFromCoordinates(
        location.latitude,
        location.longitude,
      );

      if (placemarks.isNotEmpty) {
        final placemark = placemarks.first;

        // Build a proper Singapore address format - handle null values safely
        List<String> addressParts = [];

        // Street number
        if (placemark.subThoroughfare?.isNotEmpty == true) {
          addressParts.add(placemark.subThoroughfare!);
        }

        // Street name
        if (placemark.thoroughfare?.isNotEmpty == true) {
          addressParts.add(placemark.thoroughfare!);
        }

        // Area/District
        if (placemark.subLocality?.isNotEmpty == true) {
          addressParts.add(placemark.subLocality!);
        }

        // City/Town
        if (placemark.locality?.isNotEmpty == true) {
          addressParts.add(placemark.locality!);
        }

        // Administrative area (if available)
        if (placemark.administrativeArea?.isNotEmpty == true &&
            placemark.administrativeArea != placemark.locality) {
          addressParts.add(placemark.administrativeArea!);
        }

        // Postal code and country
        if (placemark.postalCode?.isNotEmpty == true) {
          addressParts.add('Singapore ${placemark.postalCode}');
        } else {
          // Fallback to country if no postal code
          if (placemark.country?.isNotEmpty == true) {
            addressParts.add(placemark.country!);
          } else {
            addressParts.add('Singapore'); // Default fallback
          }
        }

        String finalAddress = addressParts.isNotEmpty
            ? addressParts.join(', ')
            : 'Lat: ${location.latitude.toStringAsFixed(6)}, Lng: ${location.longitude.toStringAsFixed(6)}';

        setState(() {
          _selectedAddress = finalAddress;
        });
      } else {
        // No placemarks found
        setState(() {
          _selectedAddress = 'Lat: ${location.latitude.toStringAsFixed(6)}, Lng: ${location.longitude.toStringAsFixed(6)}';
        });
      }
    } catch (e) {
      print('Error getting address: $e');
      setState(() {
        _selectedAddress = 'Lat: ${location.latitude.toStringAsFixed(6)}, Lng: ${location.longitude.toStringAsFixed(6)}';
      });
    } finally {
      setState(() => _isLoading = false);
    }
  }

  Future<void> _searchLocation(String query) async {
    if (query.trim().isEmpty) return;

    setState(() => _isLoading = true);

    try {
      // Try searching with Singapore context first
      List<Location> locations = [];

      // Try different search variations
      try {
        locations = await locationFromAddress('$query, Singapore');
      } catch (e) {
        print('First search attempt failed: $e');
        try {
          // Try without Singapore suffix if the query already contains it
          if (query.toLowerCase().contains('singapore')) {
            locations = await locationFromAddress(query);
          } else {
            // Try with different Singapore context
            locations = await locationFromAddress('Singapore, $query');
          }
        } catch (e2) {
          print('Second search attempt failed: $e2');
          // Final attempt with just the query
          locations = await locationFromAddress(query);
        }
      }

      if (locations.isNotEmpty) {
        final location = locations.first;
        final newLocation = LatLng(location.latitude, location.longitude);

        setState(() {
          _selectedLocation = newLocation;
        });

        _mapController.move(newLocation, 16.0);
        await _getAddressFromCoordinates(newLocation);
      } else {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('No results found for "$query"')),
          );
        }
      }
    } catch (e) {
      print('Search error: $e');
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Search failed. Please try a different location.')),
        );
      }
    } finally {
      setState(() => _isLoading = false);
    }
  }

  void _onMapTap(TapPosition tapPosition, LatLng point) {
    setState(() {
      _selectedLocation = point;
    });
    _getAddressFromCoordinates(point);
  }

  void _confirmLocation() {
    Navigator.pop(context, {
      'address': _selectedAddress,
      'latitude': _selectedLocation.latitude,
      'longitude': _selectedLocation.longitude,
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColour.background,
      appBar: AppBar(
        title: const Text('Select Location'),
        backgroundColor: AppColour.primaryGreen,
        foregroundColor: Colors.white,
        actions: [
          IconButton(
            onPressed: _confirmLocation,
            icon: const Icon(Icons.check),
            tooltip: 'Confirm Location',
          ),
        ],
      ),
      body: Column(
        children: [
          // Search Bar
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: Colors.white,
              boxShadow: [
                BoxShadow(
                  color: Colors.grey.withOpacity(0.1),
                  spreadRadius: 1,
                  blurRadius: 3,
                ),
              ],
            ),
            child: Row(
              children: [
                Expanded(
                  child: TextField(
                    controller: _searchController,
                    decoration: InputDecoration(
                      hintText: 'Search for a place in Singapore...',
                      prefixIcon: const Icon(Icons.search),
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(8),
                        borderSide: BorderSide(color: Colors.grey[300]!),
                      ),
                      contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                    ),
                    onSubmitted: _searchLocation,
                  ),
                ),
                const SizedBox(width: 8),
                ElevatedButton(
                  onPressed: () => _searchLocation(_searchController.text),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppColour.primaryGreen,
                    foregroundColor: Colors.white,
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                  ),
                  child: const Text('Search'),
                ),
              ],
            ),
          ),

          // Address display
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: Colors.white,
              border: Border(
                bottom: BorderSide(color: Colors.grey[300]!),
              ),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'Selected Address:',
                  style: TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w500,
                    color: Colors.grey,
                  ),
                ),
                const SizedBox(height: 4),
                _isLoading
                    ? const Row(
                  children: [
                    SizedBox(
                      width: 16,
                      height: 16,
                      child: CircularProgressIndicator(strokeWidth: 2),
                    ),
                    SizedBox(width: 8),
                    Text('Getting address...'),
                  ],
                )
                    : Text(
                  _selectedAddress,
                  style: const TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ],
            ),
          ),

          // Map
          Expanded(
            child: FlutterMap(
              mapController: _mapController,
              options: MapOptions(
                initialCenter: _selectedLocation,
                initialZoom: 15.0,
                onTap: _onMapTap,
                minZoom: 10.0,
                maxZoom: 18.0,
              ),
              children: [
                TileLayer(
                  urlTemplate: 'https://tile.openstreetmap.org/{z}/{x}/{y}.png',
                  userAgentPackageName: 'com.example.trashure',
                ),
                MarkerLayer(
                  markers: [
                    Marker(
                      point: _selectedLocation,
                      child: const Icon(
                        Icons.location_pin,
                        color: AppColour.primaryGreen,
                        size: 40,
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),

          // Instructions and Confirm Button
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: Colors.white,
              border: Border(
                top: BorderSide(color: Colors.grey[300]!),
              ),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'Instructions:',
                  style: TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                const SizedBox(height: 4),
                const Text(
                  '• Tap anywhere on the map to select a location\n• Use the search bar to find specific places\n• Your current location is used as default\n• Tap the checkmark to confirm your selection',
                  style: TextStyle(
                    fontSize: 12,
                    color: Colors.grey,
                  ),
                ),
                const SizedBox(height: 12),
                SizedBox(
                  width: double.infinity,
                  child: ElevatedButton(
                    onPressed: _confirmLocation,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppColour.primaryGreen,
                      foregroundColor: Colors.white,
                      padding: const EdgeInsets.symmetric(vertical: 12),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(8),
                      ),
                    ),
                    child: const Text('Confirm Location'),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}