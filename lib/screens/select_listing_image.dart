import 'package:flutter/material.dart';

class SelectListingImage extends StatelessWidget {
  static const routeName = '/select-listing-image';

  const SelectListingImage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Select Listing Image'),
        backgroundColor: Colors.green,
        foregroundColor: Colors.white,
      ),
      body: const Center(
        child: Text(
          'Image picker coming soon!',
          style: TextStyle(fontSize: 18),
        ),
      ),
    );
  }
}
