import 'package:flutter/material.dart';
import 'package:get_it/get_it.dart';
import 'dart:convert';
import '../models/colours.dart';
import '../widgets/bottom_navbar.dart';
import 'edit_profile_screen.dart';
import 'own_listing_screen.dart';
import '../services/firebase_service.dart';

class ProfileScreen extends StatefulWidget {
  static const routeName = '/profile';
  const ProfileScreen({super.key});

  @override
  State<ProfileScreen> createState() => _ProfileScreenState();
}

class _ProfileScreenState extends State<ProfileScreen> {
  final FirebaseService fbService = GetIt.instance<FirebaseService>();
  final Color backgroundColor = AppColour.background;

  String userName = "Loading...";
  String userEmail = "Loading...";
  String userPhone = "";
  String? profileImageBase64;
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

        setState(() {
          userName = firestoreProfile?['displayName'] ?? user.displayName ?? 'No name set';
          userPhone = firestoreProfile?['phone'] ?? '';
          profileImageBase64 = firestoreProfile?['profileImageBase64'];
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

  String? _getSafeImageUrl(String? url) {
    if (url == null) return null;
    // Handle Google profile image URLs
    if (url.contains('googleusercontent.com')) {
      return url.replaceAll('s96-c', 's400-c'); // Get higher resolution image
    }
    return url;
  }

  void _showOptions(BuildContext context) {
    showModalBottomSheet(
      context: context,
      builder: (context) => Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          ListTile(
            leading: const Icon(Icons.edit),
            title: const Text('Edit Listing'),
            onTap: () {
              Navigator.pop(context);
              Navigator.pushNamed(context, EditProfileScreen.routeName)
                  .then((_) => _loadUserData());
            },
          ),
          ListTile(
            leading: const Icon(Icons.delete),
            title: const Text('Delete Listing'),
            onTap: () {
              Navigator.pop(context);
              _confirmDelete(context);
            },
          ),
        ],
      ),
    );
  }

  void _confirmDelete(BuildContext context) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Delete Listing'),
        content: const Text('Are you sure you want to delete this listing?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () {
              Navigator.pop(context);
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(content: Text('Listing deleted successfully')),
              );
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

                const Padding(
                  padding: EdgeInsets.symmetric(horizontal: 16),
                  child: Align(
                    alignment: Alignment.centerLeft,
                    child: Text(
                      'My Listings',
                      style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
                    ),
                  ),
                ),
                const SizedBox(height: 16),

                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 16),
                  child: GridView.count(
                    shrinkWrap: true,
                    crossAxisCount: 2,
                    childAspectRatio: 0.72,
                    physics: const NeverScrollableScrollPhysics(),
                    crossAxisSpacing: 10,
                    mainAxisSpacing: 10,
                    children: [
                      GestureDetector(
                        onTap: () {
                          Navigator.pushNamed(context, OwnListingScreen.routeName);
                        },
                        onLongPress: () {
                          _showOptions(context);
                        },
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Container(
                              width: 180,
                              height: 180,
                              margin: const EdgeInsets.symmetric(horizontal: 8),
                              padding: const EdgeInsets.all(8),
                              decoration: BoxDecoration(
                                border: Border.all(),
                                borderRadius: BorderRadius.circular(8),
                              ),
                              child: Image.asset(
                                'images/chair.png',
                                fit: BoxFit.contain,
                              ),
                            ),
                            const SizedBox(height: 8),
                            Padding(
                              padding: const EdgeInsets.symmetric(horizontal: 8),
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  const Text('Stylish Chair', style: TextStyle(fontSize: 16)),
                                  const Text('\$120', style: TextStyle(fontWeight: FontWeight.bold)),
                                  Text(userName, style: const TextStyle(color: Colors.grey)),
                                ],
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
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