import 'package:flutter/material.dart';
import 'package:get_it/get_it.dart';
import 'dart:convert';
import '../models/colours.dart';
import '../widgets/bottom_navbar.dart';
import 'edit_profile_screen.dart';
import 'listing_detail_screen.dart';
import '../services/firebase_service.dart';
import '../services/listing_service.dart';

class ProfileScreen extends StatefulWidget {
  static const routeName = '/profile';
  const ProfileScreen({super.key});

  @override
  State<ProfileScreen> createState() => _ProfileScreenState();
}

class _ProfileScreenState extends State<ProfileScreen> {
  final FirebaseService fbService = GetIt.instance<FirebaseService>();
  final ListingService _listingService = GetIt.instance<ListingService>();
  final Color backgroundColor = AppColour.background;

  String userName = "Loading...";
  String userEmail = "Loading...";
  String userPhone = "";
  String? profileImageBase64;
  List<Map<String, dynamic>> userListings = [];
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadUserData();
  }

  Future<void> _loadUserData() async {
    setState(() => _isLoading = true);

    try {
      final user = fbService.getCurrentUser();
      if (user != null) {
        // Get data from Firebase Auth
        setState(() {
          userEmail = user.email ?? 'No email available';
        });

        // Get additional data from Firestore
        final firestoreProfile = await fbService.firestoreService.getUserProfile(user.uid);

        // Get user's listings
        final listings = await _listingService.getUserListings(user.uid);

        setState(() {
          userName = firestoreProfile?['displayName'] ?? user.displayName ?? 'No name set';
          userPhone = firestoreProfile?['phone'] ?? '';
          profileImageBase64 = firestoreProfile?['profileImageBase64'];
          userListings = listings;
        });
      }
    } catch (e) {
      print('Error loading user data: $e');
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error loading profile: ${e.toString()}')),
        );
      }
    } finally {
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }

  void _showListingOptions(BuildContext context, Map<String, dynamic> listing) {
    showModalBottomSheet(
      context: context,
      builder: (context) => Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          ListTile(
            leading: const Icon(Icons.visibility),
            title: const Text('View Listing'),
            onTap: () {
              Navigator.pop(context);
              Navigator.pushNamed(
                context,
                ListingDetailScreen.routeName,
                arguments: listing,
              ).then((_) => _loadUserData());
            },
          ),
          ListTile(
            leading: const Icon(Icons.edit),
            title: const Text('Edit Listing'),
            onTap: () {
              Navigator.pop(context);
              Navigator.pushNamed(
                context,
                '/edit-listing',
                arguments: listing,
              ).then((_) => _loadUserData());
            },
          ),
          ListTile(
            leading: const Icon(Icons.delete, color: Colors.red),
            title: const Text('Delete Listing'),
            onTap: () {
              Navigator.pop(context);
              _confirmDeleteListing(context, listing);
            },
          ),
        ],
      ),
    );
  }

  void _confirmDeleteListing(BuildContext context, Map<String, dynamic> listing) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Delete Listing'),
        content: Text('Are you sure you want to delete "${listing['title']}"?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () async {
              Navigator.pop(context);

              try {
                await _listingService.deleteListing(listing['id']);

                if (mounted) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(
                      content: Text('Listing deleted successfully'),
                      backgroundColor: Colors.green,
                    ),
                  );
                  _loadUserData(); // Refresh the listings
                }
              } catch (e) {
                if (mounted) {
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

  Widget _buildProfileImage() {
    if (profileImageBase64 != null && profileImageBase64!.isNotEmpty) {
      try {
        final bytes = base64Decode(profileImageBase64!);
        return CircleAvatar(
          radius: 60,
          backgroundImage: MemoryImage(bytes),
        );
      } catch (e) {
        print('Error decoding base64 image: $e');
      }
    }

    return CircleAvatar(
      radius: 60,
      backgroundColor: Colors.grey[300],
      child: const Icon(Icons.person, size: 60, color: Colors.white),
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
        size: 40,
        color: Colors.grey,
      ),
    );
  }

  Widget _buildListingCard(Map<String, dynamic> listing) {
    final title = listing['title'] ?? 'No Title';
    final price = listing['price']?.toString() ?? '0';
    final imageBase64 = listing['imageBase64'];

    return GestureDetector(
      onTap: () {
        Navigator.pushNamed(
          context,
          ListingDetailScreen.routeName,
          arguments: listing,
        ).then((_) => _loadUserData());
      },
      onLongPress: () {
        _showListingOptions(context, listing);
      },
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: 180,
            height: 180,
            margin: const EdgeInsets.symmetric(horizontal: 8),
            decoration: BoxDecoration(
              border: Border.all(),
              borderRadius: BorderRadius.circular(8),
            ),
            child: ClipRRect(
              borderRadius: BorderRadius.circular(8),
              child: _buildListingImage(imageBase64),
            ),
          ),
          const SizedBox(height: 8),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 8),
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
                  userName,
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
      bottomNavigationBar: const BottomNavBar(currentIndex: 2),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : SafeArea(
        child: RefreshIndicator(
          onRefresh: _loadUserData,
          child: SingleChildScrollView(
            physics: const AlwaysScrollableScrollPhysics(),
            child: Column(
              children: [
                const SizedBox(height: 24),

                // Profile Picture
                _buildProfileImage(),

                const SizedBox(height: 16),

                Text(
                  userName,
                  style: const TextStyle(fontSize: 28, fontWeight: FontWeight.bold),
                ),
                const SizedBox(height: 4),

                Text(
                  userEmail,
                  style: const TextStyle(color: Colors.grey),
                ),

                if (userPhone.isNotEmpty) ...[
                  const SizedBox(height: 4),
                  Text(
                    userPhone,
                    style: const TextStyle(color: Colors.grey),
                  ),
                ],

                const SizedBox(height: 8),

                ElevatedButton(
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppColour.primaryGreen,
                    foregroundColor: Colors.white,
                  ),
                  onPressed: () {
                    Navigator.pushNamed(context, EditProfileScreen.routeName)
                        .then((_) => _loadUserData());
                  },
                  child: const Text('Edit Profile'),
                ),
                const SizedBox(height: 24),

                // My Listings Section
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 16),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      const Text(
                        'My Listings',
                        style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
                      ),
                      Text(
                        '${userListings.length} items',
                        style: const TextStyle(color: Colors.grey),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 16),

                // Listings Grid
                if (userListings.isEmpty)
                  Padding(
                    padding: const EdgeInsets.all(32),
                    child: Column(
                      children: [
                        Icon(
                          Icons.inventory_2_outlined,
                          size: 64,
                          color: Colors.grey[400],
                        ),
                        const SizedBox(height: 16),
                        Text(
                          'No listings yet',
                          style: TextStyle(
                            fontSize: 18,
                            color: Colors.grey[600],
                          ),
                        ),
                        const SizedBox(height: 8),
                        Text(
                          'Tap the + button to add your first listing',
                          style: TextStyle(
                            color: Colors.grey[500],
                          ),
                          textAlign: TextAlign.center,
                        ),
                        const SizedBox(height: 16),
                        ElevatedButton.icon(
                          onPressed: () {
                            Navigator.pushNamed(context, '/add-listing')
                                .then((_) => _loadUserData());
                          },
                          icon: const Icon(Icons.add),
                          label: const Text('Add Listing'),
                          style: ElevatedButton.styleFrom(
                            backgroundColor: AppColour.primaryGreen,
                            foregroundColor: Colors.white,
                          ),
                        ),
                      ],
                    ),
                  )
                else
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 16),
                    child: GridView.builder(
                      shrinkWrap: true,
                      physics: const NeverScrollableScrollPhysics(),
                      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                        crossAxisCount: 2,
                        childAspectRatio: 0.72,
                        crossAxisSpacing: 10,
                        mainAxisSpacing: 10,
                      ),
                      itemCount: userListings.length,
                      itemBuilder: (context, index) {
                        return _buildListingCard(userListings[index]);
                      },
                    ),
                  ),
                const SizedBox(height: 16),
              ],
            ),
          ),
        ),
      ),
    );
  }
}