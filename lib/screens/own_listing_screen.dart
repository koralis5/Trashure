import 'package:flutter/material.dart';
import '../models/colours.dart';
import 'edit_listing_screen.dart';

class OwnListingScreen extends StatelessWidget {
  static const routeName = '/own-listing';

  const OwnListingScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColour.background,
      appBar: AppBar(
        title: const Text('Your Listing'),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () => Navigator.pop(context),
        ),
        backgroundColor: Colors.transparent,
        foregroundColor: Colors.black,
        elevation: 0,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            // Listing image
            Container(
              width: 360,
              height: 360,
              decoration: BoxDecoration(
                border: Border.all(color: Colors.grey),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Image.asset(
                'images/chair.png',
                fit: BoxFit.cover,
              ),
            ),
            const SizedBox(height: 24),

            const Align(
              alignment: Alignment.centerLeft,
              child: Text(
                'Stylish Chair',
                style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
              ),
            ),
            const SizedBox(height: 8),
            const Align(
              alignment: Alignment.centerLeft,
              child: Text('\$120'),
            ),
            const SizedBox(height: 8),
            const Align(
              alignment: Alignment.centerLeft,
              child: Text('A modern and stylish chair perfect for any room.'),
            ),
            const SizedBox(height: 24),

            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                style: ElevatedButton.styleFrom(backgroundColor: AppColour.primaryGreen, foregroundColor: Colors.white),
                onPressed: () {
                  Navigator.pushNamed(context, EditListingScreen.routeName);
                },
                child: const Text('Edit Listing'),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
