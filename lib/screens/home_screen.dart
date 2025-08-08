import 'package:flutter/material.dart';
import 'package:get_it/get_it.dart';
import 'dart:convert';
import 'package:geolocator/geolocator.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:latlong2/latlong.dart';
import 'package:trashure/models/colours.dart';
import '../widgets/bottom_navbar.dart';
import '../services/listing_service.dart';
import '../services/notification_service.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});
  static const routeName = '/home';

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  final Color backgroundColor = AppColour.background;
  final Color navBarColor = AppColour.primaryGreen;
  final ListingService _listingService = GetIt.instance<ListingService>();
  final NotificationService _notificationService = GetIt.instance<NotificationService>();
  final TextEditingController _searchController = TextEditingController();

  List<Map<String, dynamic>> _listings = [];
  List<Map<String, dynamic>> _filteredListings = [];
  bool _isLoading = true;
  String _searchQuery = '';
  bool _isMapView = false;
  Position? _currentPosition;

  @override
  void initState() {
    super.initState();
    _initializeServices();
    _loadListings();
    _getCurrentLocation();
  }

  Future<void> _initializeServices() async {
    await _notificationService.initialize();
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
        _currentPosition = position;
      });
    } catch (e) {
      print('Error getting location: $e');
    }
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  Future<void> _loadListings() async {
    setState(() => _isLoading = true);

    try {
      final listings = await _listingService.getAllListings();
      setState(() {
        _listings = listings;
        _filteredListings = listings;
        _isLoading = false;
      });
    } catch (e) {
      setState(() => _isLoading = false);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error loading listings: ${e.toString()}')),
        );
      }
    }
  }

  void _filterListings(String query) {
    setState(() {
      _searchQuery = query;
      if (query.isEmpty) {
        _filteredListings = _listings;
      } else {
        _filteredListings = _listings.where((listing) {
          final title = listing['title']?.toString().toLowerCase() ?? '';
          final seller = listing['sellerName']?.toString().toLowerCase() ?? '';
          final description = listing['description']?.toString().toLowerCase() ?? '';
          final searchLower = query.toLowerCase();

          return title.contains(searchLower) ||
              seller.contains(searchLower) ||
              description.contains(searchLower);
        }).toList();
      }
    });
  }

  Widget _buildMapView() {
    if (_currentPosition == null) {
      return const Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            CircularProgressIndicator(),
            SizedBox(height: 16),
            Text('Getting your location...'),
          ],
        ),
      );
    }

    // Filter listings with valid coordinates
    final listingsWithCoords = _filteredListings.where((listing) {
      return listing['latitude'] != null && listing['longitude'] != null;
    }).toList();

    return FlutterMap(
      options: MapOptions(
        initialCenter: LatLng(_currentPosition!.latitude, _currentPosition!.longitude),
        initialZoom: 12.0,
      ),
      children: [
        TileLayer(
          urlTemplate: 'https://tile.openstreetmap.org/{z}/{x}/{y}.png',
          userAgentPackageName: 'com.example.trashure',
        ),
        MarkerLayer(
          markers: [
            // User location marker
            Marker(
              point: LatLng(_currentPosition!.latitude, _currentPosition!.longitude),
              child: const CircleAvatar(
                radius: 10,
                backgroundColor: Colors.blue,
                child: Icon(Icons.person, color: Colors.white, size: 12),
              ),
            ),
            // Listing markers
            ...listingsWithCoords.map((listing) => Marker(
              point: LatLng(
                listing['latitude'].toDouble(),
                listing['longitude'].toDouble(),
              ),
              child: GestureDetector(
                onTap: () {
                  Navigator.pushNamed(context, '/listing-detail', arguments: listing);
                },
                child: Container(
                  padding: const EdgeInsets.all(4),
                  decoration: BoxDecoration(
                    color: AppColour.primaryGreen,
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Text(
                    'SGD\$${listing['price']}',
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 10,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
              ),
            )).toList(),
          ],
        ),
      ],
    );
  }

  Widget _buildListingImage(String? imageBase64) {
    if (imageBase64 != null && imageBase64.isNotEmpty) {
      try {
        final bytes = base64Decode(imageBase64);
        return Image.memory(
          bytes,
          fit: BoxFit.cover,
          width: double.infinity,
          height: double.infinity,
        );
      } catch (e) {
        print('Error decoding listing image: $e');
      }
    }

    return Container(
      color: Colors.grey[200],
      child: const Icon(
        Icons.image_not_supported,
        size: 50,
        color: Colors.grey,
      ),
    );
  }

  Widget _buildListingCard(Map<String, dynamic> listing) {
    final title = listing['title'] ?? 'No Title';
    final price = listing['price']?.toString() ?? '0';
    final seller = listing['sellerName'] ?? 'Unknown Seller';
    final imageBase64 = listing['imageBase64'];

    return GestureDetector(
      onTap: () {
        // Navigate to listing detail screen
        Navigator.pushNamed(
          context,
          '/listing-detail',
          arguments: listing,
        );
      },
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: 180,
            height: 180,
            margin: const EdgeInsets.symmetric(horizontal: 8),
            decoration: BoxDecoration(
              border: Border.all(color: Colors.grey),
              borderRadius: BorderRadius.circular(8),
            ),
            child: ClipRRect(
              borderRadius: BorderRadius.circular(8),
              child: _buildListingImage(imageBase64),
            ),
          ),
          const SizedBox(height: 8),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 12),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: const TextStyle(fontSize: 16),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
                Text(
                  '\$$price',
                  style: const TextStyle(fontWeight: FontWeight.bold),
                ),
                Text(
                  seller,
                  style: const TextStyle(color: Colors.grey),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: backgroundColor,
      body: SafeArea(
        child: Column(
          children: [
            // Search Bar with view toggle
            Padding(
              padding: const EdgeInsets.all(12),
              child: Column(
                children: [
                  Container(
                    decoration: BoxDecoration(
                      border: Border.all(),
                      borderRadius: BorderRadius.circular(4),
                    ),
                    child: Row(
                      children: [
                        const Padding(
                          padding: EdgeInsets.all(8.0),
                          child: Icon(Icons.search, size: 28),
                        ),
                        Expanded(
                          child: TextField(
                            controller: _searchController,
                            decoration: const InputDecoration(
                              hintText: 'Search listings...',
                              border: InputBorder.none,
                            ),
                            onChanged: _filterListings,
                          ),
                        ),
                        if (_searchQuery.isNotEmpty)
                          IconButton(
                            icon: const Icon(Icons.clear),
                            onPressed: () {
                              _searchController.clear();
                              _filterListings('');
                            },
                          ),
                      ],
                    ),
                  ),

                  const SizedBox(height: 8),

                  // View toggle buttons
                  Row(
                    children: [
                      Expanded(
                        child: ElevatedButton.icon(
                          onPressed: () => setState(() => _isMapView = false),
                          icon: const Icon(Icons.grid_view, size: 16),
                          label: const Text('Grid'),
                          style: ElevatedButton.styleFrom(
                            backgroundColor: !_isMapView ? AppColour.primaryGreen : Colors.grey[200],
                            foregroundColor: !_isMapView ? Colors.white : Colors.black,
                            elevation: 0,
                          ),
                        ),
                      ),
                      const SizedBox(width: 8),
                      Expanded(
                        child: ElevatedButton.icon(
                          onPressed: () => setState(() => _isMapView = true),
                          icon: const Icon(Icons.map, size: 16),
                          label: const Text('Map'),
                          style: ElevatedButton.styleFrom(
                            backgroundColor: _isMapView ? AppColour.primaryGreen : Colors.grey[200],
                            foregroundColor: _isMapView ? Colors.white : Colors.black,
                            elevation: 0,
                          ),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),

            // Content area
            Expanded(
                child: _isLoading
                    ? const Center(child: CircularProgressIndicator())
                    : _isMapView
                    ? _buildMapView()
                    : _filteredListings.isEmpty
                    ? Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(
                        _searchQuery.isNotEmpty ? Icons.search_off : Icons.inventory_2_outlined,
                        size: 64,
                        color: Colors.grey,
                      ),
                      const SizedBox(height: 16),
                      Text(
                        _searchQuery.isNotEmpty
                            ? 'No listings found for "$_searchQuery"'
                            : 'No listings available',
                        style: const TextStyle(
                          fontSize: 16,
                          color: Colors.grey,
                        ),
                      ),
                      if (_searchQuery.isEmpty) ...[
                        const SizedBox(height: 8),
                        const Text(
                          'Be the first to add a listing!',
                          style: TextStyle(color: Colors.grey),
                        ),
                      ],
                    ],
                  ),
                )
                    : RefreshIndicator(
                  onRefresh: _loadListings,
                  child: GridView.builder(
                    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                    gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                      crossAxisCount: 2,
                      childAspectRatio: 0.72,
                      mainAxisSpacing: 10,
                      crossAxisSpacing: 10,
                    ),
                    itemCount: _filteredListings.length,
                    itemBuilder: (context, index) {
                      return _buildListingCard(_filteredListings[index]);
                    },
                  ),
                )
            ),
          ],
        ),
      ),
      bottomNavigationBar: const BottomNavBar(currentIndex: 0),
    );
  }
}