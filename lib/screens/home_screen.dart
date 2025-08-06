import 'package:flutter/material.dart';
import 'package:get_it/get_it.dart';
import 'dart:convert';
import 'package:trashure/models/colours.dart';
import '../widgets/bottom_navbar.dart';
import '../services/listing_service.dart';

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
  final TextEditingController _searchController = TextEditingController();

  List<Map<String, dynamic>> _listings = [];
  List<Map<String, dynamic>> _filteredListings = [];
  bool _isLoading = true;
  String _searchQuery = '';

  @override
  void initState() {
    super.initState();
    _loadListings();
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
            // Search Bar
            Padding(
              padding: const EdgeInsets.all(12),
              child: Container(
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
            ),

            // Listings Grid
            Expanded(
              child: _isLoading
                  ? const Center(child: CircularProgressIndicator())
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
              ),
            ),
          ],
        ),
      ),
      bottomNavigationBar: const BottomNavBar(currentIndex: 0),
    );
  }
}