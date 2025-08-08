import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:get_it/get_it.dart';
import 'dart:convert';
import 'package:flutter_map/flutter_map.dart';
import 'package:latlong2/latlong.dart';
import 'package:share_plus/share_plus.dart';
import 'package:table_calendar/table_calendar.dart';
import '../models/colours.dart';
import '../services/listing_service.dart';
import 'edit_listing_screen.dart';

class ListingDetailScreen extends StatefulWidget {
  static const routeName = '/listing-detail';

  const ListingDetailScreen({super.key});

  @override
  State<ListingDetailScreen> createState() => _ListingDetailScreenState();
}

class _ListingDetailScreenState extends State<ListingDetailScreen> {
  final ListingService _listingService = GetIt.instance<ListingService>();
  bool _isLoading = false;
  bool _showMap = false;

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
      child: const Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.image_not_supported,
              size: 64,
              color: Colors.grey,
            ),
            SizedBox(height: 8),
            Text(
              'No Image',
              style: TextStyle(color: Colors.grey),
            ),
          ],
        ),
      ),
    );
  }

  bool _isCurrentUserListing(String listingUserId) {
    final currentUser = FirebaseAuth.instance.currentUser;
    return currentUser != null && currentUser.uid == listingUserId;
  }

  Future<void> _deleteListing(Map<String, dynamic> listing) async {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Delete Listing'),
        content: Text('Are you sure you want to delete "${listing['title']}"?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () async {
              Navigator.pop(ctx);
              setState(() => _isLoading = true);

              try {
                await _listingService.deleteListing(listing['id']);
                if (mounted) {
                  Navigator.pop(context);
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(
                      content: Text('Listing deleted successfully'),
                      backgroundColor: Colors.green,
                    ),
                  );
                }
              } catch (e) {
                if (mounted) {
                  setState(() => _isLoading = false);
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      content: Text('Error deleting listing: ${e.toString()}'),
                      backgroundColor: Colors.red,
                    ),
                  );
                }
              }
            },
            child: const Text('Delete', style: TextStyle(color: Colors.red)),
          ),
        ],
      ),
    );
  }

  void _shareListing(Map<String, dynamic> listing) {
    final title = listing['title'] ?? 'Item';
    final price = listing['price']?.toString() ?? '0';
    final description = listing['description'] ?? '';
    final sellerName = listing['sellerName'] ?? 'Unknown Seller';

    final shareText = '''
🛍️ Check out this item on Trashure!

📦 $title
💰 SGD \$${price}
👤 Seller: $sellerName

📝 $description

Download Trashure - Turn trash into treasure! 🌱
''';

    Share.share(shareText, subject: 'Trashure - $title');
  }

  void _schedulePickup(Map<String, dynamic> listing) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (context) => DraggableScrollableSheet(
        initialChildSize: 0.7,
        maxChildSize: 0.9,
        minChildSize: 0.5,
        builder: (context, scrollController) => _buildScheduleSheet(scrollController, listing),
      ),
    );
  }

  Widget _buildScheduleSheet(ScrollController scrollController, Map<String, dynamic> listing) {
    DateTime selectedDay = DateTime.now();
    TimeOfDay selectedTime = TimeOfDay.now();

    return StatefulBuilder(
      builder: (context, setModalState) => Container(
        padding: const EdgeInsets.all(20),
        child: Column(
          children: [
            Container(
              width: 40,
              height: 4,
              margin: const EdgeInsets.only(bottom: 20),
              decoration: BoxDecoration(
                color: Colors.grey[300],
                borderRadius: BorderRadius.circular(2),
              ),
            ),
            const Text(
              'Schedule Pickup',
              style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 20),

            Expanded(
              child: SingleChildScrollView(
                controller: scrollController,
                child: Column(
                  children: [
                    // Calendar placeholder
                    Container(
                      height: 300,
                      width: double.infinity,
                      decoration: BoxDecoration(
                        border: Border.all(color: Colors.grey[300]!),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: const Center(
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Icon(Icons.calendar_today, size: 48, color: Colors.grey),
                            SizedBox(height: 12),
                            Text('Calendar Widget', style: TextStyle(fontSize: 16, color: Colors.grey)),
                            Text('(Coming Soon)', style: TextStyle(fontSize: 12, color: Colors.grey)),
                          ],
                        ),
                      ),
                    ),

                    const SizedBox(height: 20),

                    // Time picker placeholder
                    Container(
                      padding: const EdgeInsets.all(16),
                      decoration: BoxDecoration(
                        border: Border.all(color: Colors.grey[300]!),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Row(
                        children: [
                          const Icon(Icons.access_time, color: AppColour.primaryGreen),
                          const SizedBox(width: 12),
                          const Text('Time:', style: TextStyle(fontWeight: FontWeight.w500)),
                          const Spacer(),
                          Text('${selectedTime.hour.toString().padLeft(2, '0')}:${selectedTime.minute.toString().padLeft(2, '0')}'),
                          const SizedBox(width: 8),
                          TextButton(
                            onPressed: () {
                              ScaffoldMessenger.of(context).showSnackBar(
                                const SnackBar(content: Text('Time picker coming soon!')),
                              );
                            },
                            child: const Text('Change'),
                          ),
                        ],
                      ),
                    ),

                    const SizedBox(height: 20),

                    ElevatedButton(
                      onPressed: () {
                        Navigator.pop(context);
                        ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(
                            content: Text('Pickup scheduled! (Demo - notifications coming soon)'),
                            backgroundColor: Colors.green,
                          ),
                        );
                      },
                      style: ElevatedButton.styleFrom(
                        backgroundColor: AppColour.primaryGreen,
                        padding: const EdgeInsets.symmetric(vertical: 16),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                      ),
                      child: const Text('Schedule Pickup', style: TextStyle(color: Colors.white)),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  void _openChat(Map<String, dynamic> listing) {
    // Chat placeholder
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('Chat feature coming soon! 💬'),
        backgroundColor: Colors.blue,
      ),
    );
  }

  Widget _buildLocationSection(Map<String, dynamic> listing) {
    final meetupLocation = listing['meetupLocation'];
    final latitude = listing['latitude'];
    final longitude = listing['longitude'];

    if (meetupLocation == null || meetupLocation.isEmpty) {
      return const SizedBox.shrink();
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'Meetup Location',
          style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
        ),
        const SizedBox(height: 12),

        Container(
          width: double.infinity,
          decoration: BoxDecoration(
            color: Colors.grey[50],
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: Colors.grey[200]!),
          ),
          child: Column(
            children: [
              // Location text
              Padding(
                padding: const EdgeInsets.all(16),
                child: Row(
                  children: [
                    const Icon(Icons.location_on, color: AppColour.primaryGreen),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Text(
                        meetupLocation,
                        style: const TextStyle(fontSize: 16),
                      ),
                    ),
                    TextButton(
                      onPressed: () => setState(() => _showMap = !_showMap),
                      child: Text(_showMap ? 'Hide Map' : 'Show Map'),
                    ),
                  ],
                ),
              ),

              // Map view
              if (_showMap && latitude != null && longitude != null)
                Container(
                  height: 200,
                  margin: const EdgeInsets.fromLTRB(16, 0, 16, 16),
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(color: Colors.grey[300]!),
                  ),
                  child: ClipRRect(
                    borderRadius: BorderRadius.circular(8),
                    child: FlutterMap(
                      options: MapOptions(
                        initialCenter: LatLng(latitude.toDouble(), longitude.toDouble()),
                        initialZoom: 15.0,
                      ),
                      children: [
                        TileLayer(
                          urlTemplate: 'https://tile.openstreetmap.org/{z}/{x}/{y}.png',
                          userAgentPackageName: 'com.example.trashure',
                        ),
                        MarkerLayer(
                          markers: [
                            Marker(
                              point: LatLng(latitude.toDouble(), longitude.toDouble()),
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
                )
              else if (_showMap)
                Container(
                  height: 200,
                  margin: const EdgeInsets.fromLTRB(16, 0, 16, 16),
                  decoration: BoxDecoration(
                    color: Colors.grey[100],
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(color: Colors.grey[300]!),
                  ),
                  child: const Center(
                    child: Text('Map coordinates not available'),
                  ),
                ),
            ],
          ),
        ),
        const SizedBox(height: 20),
      ],
    );
  }

  // Helper method to check if price was reduced
  Widget _buildPriceSection(Map<String, dynamic> listing) {
    final currentPrice = listing['price']?.toDouble() ?? 0.0;
    final originalPrice = listing['originalPrice']?.toDouble() ?? currentPrice;
    final priceHistory = listing['priceHistory'] as List<dynamic>? ?? [];

    // Check if price was reduced
    final bool priceReduced = originalPrice > currentPrice && priceHistory.length > 1;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        if (priceReduced) ...[
          // Show crossed out original price
          Text(
            'SGD \$${originalPrice.toStringAsFixed(2)}',
            style: TextStyle(
              fontSize: 20,
              color: Colors.grey[600],
              decoration: TextDecoration.lineThrough,
            ),
          ),
          const SizedBox(height: 4),
          Row(
            children: [
              Text(
                'SGD \$${currentPrice.toStringAsFixed(2)}',
                style: const TextStyle(
                  fontSize: 28,
                  fontWeight: FontWeight.bold,
                  color: AppColour.primaryGreen,
                ),
              ),
              const SizedBox(width: 8),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                decoration: BoxDecoration(
                  color: Colors.red,
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Text(
                  'REDUCED!',
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 12,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
            ],
          ),
        ] else ...[
          // Show normal price
          Text(
            'SGD \$${currentPrice.toStringAsFixed(2)}',
            style: const TextStyle(
              fontSize: 28,
              fontWeight: FontWeight.bold,
              color: AppColour.primaryGreen,
            ),
          ),
        ],
      ],
    );
  }

  @override
  Widget build(BuildContext context) {
    final Map<String, dynamic>? listing =
    ModalRoute.of(context)?.settings.arguments as Map<String, dynamic>?;

    if (listing == null) {
      return Scaffold(
        backgroundColor: AppColour.background,
        appBar: AppBar(
          title: const Text('Listing Not Found'),
          backgroundColor: Colors.transparent,
          foregroundColor: Colors.black,
          elevation: 0,
        ),
        body: const Center(
          child: Text('Listing data not found', style: TextStyle(fontSize: 18)),
        ),
      );
    }

    final title = listing['title'] ?? 'No Title';
    final description = listing['description'] ?? 'No Description';
    final imageBase64 = listing['imageBase64'];
    final sellerName = listing['sellerName'] ?? 'Unknown Seller';
    final listingUserId = listing['userId'] ?? '';
    final isOwnListing = _isCurrentUserListing(listingUserId);

    return Scaffold(
      backgroundColor: AppColour.background,
      appBar: AppBar(
        title: Text(isOwnListing ? 'Your Listing' : 'Listing Details'),
        backgroundColor: Colors.transparent,
        foregroundColor: Colors.black,
        elevation: 0,
        actions: [
          // Share button
          IconButton(
            onPressed: () => _shareListing(listing),
            icon: const Icon(Icons.share),
            tooltip: 'Share Listing',
          ),

          if (isOwnListing)
            PopupMenuButton<String>(
              onSelected: (value) {
                if (value == 'edit') {
                  Navigator.pushNamed(context, EditListingScreen.routeName, arguments: listing);
                } else if (value == 'delete') {
                  _deleteListing(listing);
                }
              },
              itemBuilder: (context) => [
                const PopupMenuItem(
                  value: 'edit',
                  child: Row(
                    children: [
                      Icon(Icons.edit, size: 20),
                      SizedBox(width: 8),
                      Text('Edit'),
                    ],
                  ),
                ),
                const PopupMenuItem(
                  value: 'delete',
                  child: Row(
                    children: [
                      Icon(Icons.delete, size: 20, color: Colors.red),
                      SizedBox(width: 8),
                      Text('Delete', style: TextStyle(color: Colors.red)),
                    ],
                  ),
                ),
              ],
            ),
        ],
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Listing image
            Container(
              width: double.infinity,
              height: 300,
              decoration: BoxDecoration(
                border: Border.all(color: Colors.grey),
                borderRadius: BorderRadius.circular(12),
              ),
              child: ClipRRect(
                borderRadius: BorderRadius.circular(12),
                child: _buildListingImage(imageBase64),
              ),
            ),
            const SizedBox(height: 20),

            // Title (most prominent)
            Text(
              title,
              style: const TextStyle(
                fontSize: 28,
                fontWeight: FontWeight.bold,
                color: Colors.black,
              ),
            ),
            const SizedBox(height: 12),

            // Price section with potential reduction indicator
            _buildPriceSection(listing),
            const SizedBox(height: 16),

            // Date of listing
            if (listing['createdAt'] != null) ...[
              Row(
                children: [
                  const Icon(Icons.calendar_today, size: 16, color: Colors.grey),
                  const SizedBox(width: 8),
                  Text(
                    'Posted on ${_formatDate(listing['createdAt'])}',
                    style: TextStyle(
                      fontSize: 14,
                      color: Colors.grey[600],
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 20),
            ],

            // Description section
            const Text(
              'Description',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 8),
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: Colors.grey[50],
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: Colors.grey[200]!),
              ),
              child: Text(
                description,
                style: const TextStyle(fontSize: 16, height: 1.5),
              ),
            ),
            const SizedBox(height: 20),

            // Location section
            _buildLocationSection(listing),

            // Seller information
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: Colors.grey[50],
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: Colors.grey[200]!),
              ),
              child: Row(
                children: [
                  CircleAvatar(
                    radius: 25,
                    backgroundColor: AppColour.primaryGreen,
                    child: Text(
                      sellerName.isNotEmpty ? sellerName[0].toUpperCase() : 'S',
                      style: const TextStyle(
                        color: Colors.white,
                        fontWeight: FontWeight.bold,
                        fontSize: 18,
                      ),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          isOwnListing ? 'You' : sellerName,
                          style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w600),
                        ),
                        Text(
                          isOwnListing ? 'This is your listing' : 'Seller',
                          style: TextStyle(fontSize: 14, color: Colors.grey[600]),
                        ),
                      ],
                    ),
                  ),
                  if (!isOwnListing)
                    IconButton(
                      onPressed: () => _openChat(listing),
                      icon: const Icon(Icons.chat_bubble_outline),
                      tooltip: 'Chat with Seller',
                    ),
                ],
              ),
            ),
            const SizedBox(height: 24),

            // Action buttons
            if (isOwnListing)
            // Owner buttons
              Row(
                children: [
                  Expanded(
                    child: ElevatedButton.icon(
                      style: ElevatedButton.styleFrom(
                        backgroundColor: AppColour.primaryGreen,
                        foregroundColor: Colors.white,
                        padding: const EdgeInsets.symmetric(vertical: 16),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                      ),
                      onPressed: () {
                        Navigator.pushNamed(context, EditListingScreen.routeName, arguments: listing);
                      },
                      icon: const Icon(Icons.edit),
                      label: const Text('Edit Listing'),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: ElevatedButton.icon(
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.red,
                        foregroundColor: Colors.white,
                        padding: const EdgeInsets.symmetric(vertical: 16),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                      ),
                      onPressed: () => _deleteListing(listing),
                      icon: const Icon(Icons.delete),
                      label: const Text('Delete'),
                    ),
                  ),
                ],
              )
            else
            // Buyer buttons
              Column(
                children: [
                  SizedBox(
                    width: double.infinity,
                    child: ElevatedButton.icon(
                      style: ElevatedButton.styleFrom(
                        backgroundColor: AppColour.primaryGreen,
                        foregroundColor: Colors.white,
                        padding: const EdgeInsets.symmetric(vertical: 16),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                      ),
                      onPressed: () async {
                        final result = await Navigator.pushNamed(context, '/qr-payment', arguments: listing);

                        if (result != null && result is Map && result['success'] == true) {
                          ScaffoldMessenger.of(context).showSnackBar(
                            SnackBar(
                              content: Text('Purchase successful! Order ID: ${result['orderId']}'),
                              backgroundColor: Colors.green,
                            ),
                          );
                        }
                      },
                      icon: const Icon(Icons.qr_code),
                      label: const Text('Buy with NETS QR'),
                    ),
                  ),
                  const SizedBox(height: 12),

                  Row(
                    children: [
                      Expanded(
                        child: OutlinedButton.icon(
                          style: OutlinedButton.styleFrom(
                            foregroundColor: AppColour.primaryGreen,
                            side: const BorderSide(color: AppColour.primaryGreen),
                            padding: const EdgeInsets.symmetric(vertical: 16),
                            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                          ),
                          onPressed: () => _openChat(listing),
                          icon: const Icon(Icons.chat),
                          label: const Text('Chat'),
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: OutlinedButton.icon(
                          style: OutlinedButton.styleFrom(
                            foregroundColor: Colors.orange,
                            side: const BorderSide(color: Colors.orange),
                            padding: const EdgeInsets.symmetric(vertical: 16),
                            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                          ),
                          onPressed: () => _schedulePickup(listing),
                          icon: const Icon(Icons.schedule),
                          label: const Text('Schedule'),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
          ],
        ),
      ),
    );
  }

  String _formatDate(dynamic timestamp) {
    try {
      if (timestamp == null) return 'Unknown';

      // Handle Firestore Timestamp
      if (timestamp.runtimeType.toString().contains('Timestamp')) {
        final DateTime date = timestamp.toDate();
        return '${date.day}/${date.month}/${date.year}';
      }

      return 'Unknown';
    } catch (e) {
      return 'Unknown';
    }
  }
}