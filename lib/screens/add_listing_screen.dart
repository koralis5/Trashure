import 'package:flutter/material.dart';
import '../widgets/bottom_navbar.dart';
import '../widgets/custom_text_field.dart';
import '../screens/select_listing_image.dart';
import '../models/colours.dart';

class AddListingScreen extends StatelessWidget {
  static const String routeName = '/add-listing';

  const AddListingScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final TextEditingController nameController = TextEditingController();
    final TextEditingController priceController = TextEditingController();
    final TextEditingController descriptionController = TextEditingController();

    return Scaffold(
      backgroundColor: AppColour.background,
      appBar: AppBar(
        title: const Text("Add Listing"),
        backgroundColor: AppColour.primaryGreen,
        foregroundColor: Colors.white,
      ),
      bottomNavigationBar: const BottomNavBar(currentIndex: 1),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: ListView(
          children: [
            GestureDetector(
              onTap: () {
                Navigator.pushNamed(context, SelectListingImage.routeName);
              },
              child: Container(
                width: 360,
                height: 360,
                decoration: BoxDecoration(
                  color: AppColour.secondaryGreen,
                  border: Border.all(color: Colors.grey),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: const Center(
                  child: CircleAvatar(
                    radius: 30,
                    backgroundColor: Colors.black,
                    child: Icon(Icons.add, color: Colors.white, size: 30),
                  ),
                ),
              ),
            ),
            const SizedBox(height: 20),

            //Listing Name
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'Listing Name',
                  style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                ),
                const SizedBox(height: 8),
                CustomTextField(
                  hintText: 'Enter listing name',
                  controller: nameController,
                ),
              ],
            ),
            const SizedBox(height: 20),

            //Price
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'Price',
                  style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                ),
                const SizedBox(height: 8),
                CustomTextField(
                  hintText: 'Enter price',
                  controller: priceController,
                  keyboardType: TextInputType.number,
                ),
              ],
            ),
            const SizedBox(height: 20),

            //Description
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'Description',
                  style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                ),
                const SizedBox(height: 8),
                CustomTextField(
                  hintText: 'Enter description',
                  controller: descriptionController,
                  keyboardType: TextInputType.multiline,
                ),
              ],
            ),
            const SizedBox(height: 30),

            //Submit
            ElevatedButton(
              onPressed: () {
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColour.primaryGreen,
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(vertical: 16),
              ),
              child: const Text('Add Listing'),
            ),
          ],
        ),
      ),
    );
  }
}
