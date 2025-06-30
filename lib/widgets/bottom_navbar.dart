import 'package:flutter/material.dart';
import '../screens/home_screen.dart';
import '../screens/add_listing_screen.dart';
import '../screens/profile_screen.dart';
import '../screens/login_screen.dart';
import '../models/colours.dart';

class BottomNavBar extends StatelessWidget {
  final int currentIndex;

  const BottomNavBar({super.key, required this.currentIndex});

  void _onItemTapped(BuildContext context, int index) {
    if (index == currentIndex) return;

    switch (index) {
      case 0:
        Navigator.pushReplacementNamed(context, HomeScreen.routeName);
        break;
      case 1:
        Navigator.pushReplacementNamed(context, AddListingScreen.routeName);
        break;
      case 2:
        Navigator.pushReplacementNamed(context, ProfileScreen.routeName);
        break;
      case 3:
        Navigator.pushNamedAndRemoveUntil(
          context,
          LoginScreen.routeName,
          (route) => false,
        );
        break;
    }
  }

  @override
  Widget build(BuildContext context) {
    return BottomNavigationBar(
      currentIndex: currentIndex,
      onTap: (index) => _onItemTapped(context, index),
      backgroundColor: AppColour.secondaryGreen,
      selectedItemColor: Colors.black,
      unselectedItemColor: Colors.black54,
      type: BottomNavigationBarType.fixed,
      items: const [
        BottomNavigationBarItem(
          icon: Icon(Icons.search),
          label: 'Marketplace',
        ),
        BottomNavigationBarItem(
          icon: Icon(Icons.add_box, size: 30),
          label: 'Add Listing',
        ),
        BottomNavigationBarItem(
          icon: Icon(Icons.person),
          label: 'Profile',
        ),
        BottomNavigationBarItem(
          icon: Icon(Icons.logout),
          label: 'Logout',
        ),
      ],
    );
  }
}
