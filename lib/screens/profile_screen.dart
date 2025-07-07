import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'edit_profile_screen.dart';
import '../models/colours.dart';
import '../widgets/bottom_navbar.dart';
import 'own_listing_screen.dart';

class ProfileScreen extends StatefulWidget {
  static const routeName = '/profile';
  const ProfileScreen({super.key});

  @override
  State<ProfileScreen> createState() => _ProfileScreenState();
}

class _ProfileScreenState extends State<ProfileScreen> {
  final Color backgroundColor = AppColour.background;
  final Color navBarColor = AppColour.primaryGreen;
  final User? currentUser = FirebaseAuth.instance.currentUser;
  String userName = "Loading...";
  String userEmail = "Loading...";

  @override
  void initState() {
    super.initState();
    _loadUserData();
  }

  void _loadUserData() {
    if (currentUser != null) {
      setState(() {
        userName = currentUser!.displayName ?? "No name set";
        userEmail = currentUser!.email ?? "No email available";
      });
    }
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
              Navigator.pushNamed(context, EditProfileScreen.routeName);
            },
          ),
          ListTile(
            leading: const Icon(Icons.delete),
            title: const Text('Delete Listing'),
            onTap: () {
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

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: backgroundColor,
      bottomNavigationBar: const BottomNavBar(currentIndex: 2),
      body: SafeArea(
        child: SingleChildScrollView(
          child: Column(
            children: [
              const SizedBox(height: 24),

              // Profile Picture
              CircleAvatar(
                radius: 60,
                backgroundColor: Colors.grey,
                child: currentUser?.photoURL != null
                    ? ClipOval(
                  child: Image.network(
                    currentUser!.photoURL!,
                    width: 120,
                    height: 120,
                    fit: BoxFit.cover,
                  ),
                )
                    : const Icon(Icons.person, size: 60, color: Colors.white),
              ),
              const SizedBox(height: 16),

              // Name
              Text(
                userName,
                style: const TextStyle(fontSize: 28, fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 4),

              // Email
              Text(
                userEmail,
                style: const TextStyle(color: Colors.grey),
              ),
              const SizedBox(height: 8),

              // Edit Profile Button
              ElevatedButton(
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColour.primaryGreen,
                  foregroundColor: Colors.white,
                ),
                onPressed: () {
                  Navigator.pushNamed(context, EditProfileScreen.routeName)
                      .then((_) => _loadUserData()); // Refresh after editing
                },
                child: const Text('Edit Profile'),
              ),
              const SizedBox(height: 24),

              // Listing Title
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

              // Listing Card
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
                                const Text('Stylish Chair',
                                    style: TextStyle(fontSize: 16)),
                                const Text('\$120',
                                    style:
                                    TextStyle(fontWeight: FontWeight.bold)),
                                Text(userName,
                                    style: const TextStyle(color: Colors.grey)),
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
    );
  }
}