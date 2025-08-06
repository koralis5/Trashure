import 'dart:io';
import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:get_it/get_it.dart';
import '../widgets/bottom_navbar.dart';
import '../widgets/custom_text_field.dart';
import '../models/colours.dart';
import '../services/listing_service.dart';
import '../services/firestore_service.dart';

class AddListingScreen extends StatefulWidget {
  static const String routeName = '/add-listing';

  const AddListingScreen({super.key});

  @override
  State<AddListingScreen> createState() => _AddListingScreenState();
}

class _AddListingScreenState extends State<AddListingScreen> {
  final GlobalKey<FormState> _formKey = GlobalKey<FormState>();
  final TextEditingController nameController = TextEditingController();
  final TextEditingController priceController = TextEditingController();
  final TextEditingController descriptionController = TextEditingController();

  final ListingService _listingService = GetIt.instance<ListingService>();
  final FirestoreService _firestoreService = GetIt.instance<FirestoreService>();
  final ImagePicker _picker = ImagePicker();

  XFile? _imageFile;
  bool _isLoading = false;
  String? _sellerName;

  @override
  void initState() {
    super.initState();
    _loadSellerName();
  }

  @override
  void dispose() {
    nameController.dispose();
    priceController.dispose();
    descriptionController.dispose();
    super.dispose();
  }

  Future<void> _loadSellerName() async {
    final user = FirebaseAuth.instance.currentUser;
    if (user != null) {
      try {
        final profile = await _firestoreService.getUserProfile(user.uid);
        setState(() {
          _sellerName = profile?['displayName'] ?? user.displayName ?? 'Unknown Seller';
        });
      } catch (e) {
        setState(() {
          _sellerName = user.displayName ?? 'Unknown Seller';
        });
      }
    }
  }

  Future<void> _selectListingImage() async {
    showModalBottomSheet(
      context: context,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
      ),
      builder: (context) => SafeArea(
        child: Wrap(
          children: [
            ListTile(
              leading: const Icon(Icons.camera_alt),
              title: const Text('Take a Photo'),
              onTap: () async {
                Navigator.pop(context);
                try {
                  final pickedFile = await _picker.pickImage(
                    source: ImageSource.camera,
                    maxWidth: 800,
                    maxHeight: 800,
                    imageQuality: 70,
                  );
                  if (pickedFile != null && mounted) {
                    setState(() => _imageFile = pickedFile);
                  }
                } catch (e) {
                  if (mounted) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(content: Text('Error taking photo: ${e.toString()}')),
                    );
                  }
                }
              },
            ),
            ListTile(
              leading: const Icon(Icons.photo),
              title: const Text('Choose from Gallery'),
              onTap: () async {
                Navigator.pop(context);
                try {
                  final pickedFile = await _picker.pickImage(
                    source: ImageSource.gallery,
                    maxWidth: 800,
                    maxHeight: 800,
                    imageQuality: 70,
                  );
                  if (pickedFile != null && mounted) {
                    setState(() => _imageFile = pickedFile);
                  }
                } catch (e) {
                  if (mounted) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(content: Text('Error selecting image: ${e.toString()}')),
                    );
                  }
                }
              },
            ),
            if (_imageFile != null)
              ListTile(
                leading: const Icon(Icons.delete, color: Colors.red),
                title: const Text('Remove Image'),
                onTap: () {
                  Navigator.pop(context);
                  setState(() => _imageFile = null);
                },
              ),
          ],
        ),
      ),
    );
  }

  Widget _buildImagePreview() {
    if (_imageFile != null) {
      return Container(
        width: 360,
        height: 360,
        decoration: BoxDecoration(
          border: Border.all(color: Colors.grey),
          borderRadius: BorderRadius.circular(8),
        ),
        child: ClipRRect(
          borderRadius: BorderRadius.circular(8),
          child: kIsWeb
              ? Image.network(_imageFile!.path, fit: BoxFit.cover)
              : Image.file(File(_imageFile!.path), fit: BoxFit.cover),
        ),
      );
    }

    return GestureDetector(
      onTap: _selectListingImage,
      child: Container(
        width: 360,
        height: 360,
        decoration: BoxDecoration(
          color: AppColour.secondaryGreen,
          border: Border.all(color: Colors.grey),
          borderRadius: BorderRadius.circular(8),
        ),
        child: const Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              CircleAvatar(
                radius: 30,
                backgroundColor: Colors.black,
                child: Icon(Icons.add, color: Colors.white, size: 30),
              ),
              SizedBox(height: 8),
              Text(
                'Add Image',
                style: TextStyle(color: Colors.grey),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Future<void> _submitListing() async {
    if (!_formKey.currentState!.validate()) return;

    final user = FirebaseAuth.instance.currentUser;
    if (user == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please log in to create a listing')),
      );
      return;
    }

    if (_sellerName == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Error loading seller information')),
      );
      return;
    }

    setState(() => _isLoading = true);

    try {
      final title = nameController.text.trim();
      final price = double.tryParse(priceController.text.trim()) ?? 0.0;
      final description = descriptionController.text.trim();

      // Convert image to base64 if provided
      String? imageBase64;
      if (_imageFile != null) {
        imageBase64 = await _listingService.convertImageToBase64(_imageFile!);
        if (imageBase64 == null) {
          throw Exception('Failed to process image');
        }
      }

      // Create the listing
      final listingId = await _listingService.createListing(
        userId: user.uid,
        title: title,
        price: price,
        description: description,
        sellerName: _sellerName!,
        imageBase64: imageBase64,
      );

      if (listingId != null && mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Listing created successfully!'),
            backgroundColor: Colors.green,
          ),
        );

        // Clear the form
        nameController.clear();
        priceController.clear();
        descriptionController.clear();
        setState(() => _imageFile = null);

        // Navigate to home or profile
        Navigator.pushReplacementNamed(context, '/home');
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error creating listing: ${e.toString()}'),
            backgroundColor: Colors.red,
          ),
        );
      }
    } finally {
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColour.background,
      appBar: AppBar(
        title: const Text("Add Listing"),
        backgroundColor: AppColour.primaryGreen,
        foregroundColor: Colors.white,
      ),
      bottomNavigationBar: const BottomNavBar(currentIndex: 1),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : Padding(
        padding: const EdgeInsets.all(16.0),
        child: Form(
          key: _formKey,
          child: ListView(
            children: [
              // Image Preview/Selector
              _buildImagePreview(),
              if (_imageFile != null) ...[
                const SizedBox(height: 8),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                  children: [
                    TextButton.icon(
                      onPressed: _selectListingImage,
                      icon: const Icon(Icons.edit),
                      label: const Text('Change Image'),
                    ),
                    TextButton.icon(
                      onPressed: () => setState(() => _imageFile = null),
                      icon: const Icon(Icons.delete, color: Colors.red),
                      label: const Text('Remove Image'),
                      style: TextButton.styleFrom(foregroundColor: Colors.red),
                    ),
                  ],
                ),
              ],
              const SizedBox(height: 20),

              // Listing Name
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
                    validator: (value) {
                      if (value == null || value.trim().isEmpty) {
                        return 'Please enter a listing name';
                      }
                      return null;
                    },
                  ),
                ],
              ),
              const SizedBox(height: 20),

              // Price
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    'Price (\$)',
                    style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                  ),
                  const SizedBox(height: 8),
                  CustomTextField(
                    hintText: 'Enter price',
                    controller: priceController,
                    keyboardType: TextInputType.number,
                    validator: (value) {
                      if (value == null || value.trim().isEmpty) {
                        return 'Please enter a price';
                      }
                      final price = double.tryParse(value.trim());
                      if (price == null || price < 0) {
                        return 'Please enter a valid price';
                      }
                      return null;
                    },
                  ),
                ],
              ),
              const SizedBox(height: 20),

              // Description
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
                    validator: (value) {
                      if (value == null || value.trim().isEmpty) {
                        return 'Please enter a description';
                      }
                      return null;
                    },
                  ),
                ],
              ),
              const SizedBox(height: 30),

              // Submit Button
              ElevatedButton(
                onPressed: _submitListing,
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
      ),
    );
  }
}