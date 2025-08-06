import 'dart:io';
import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:get_it/get_it.dart';
import "../models/colours.dart";
import '../services/listing_service.dart';

class EditListingScreen extends StatefulWidget {
  static const routeName = '/edit-listing';

  const EditListingScreen({super.key});

  @override
  State<EditListingScreen> createState() => _EditListingScreenState();
}

class _EditListingScreenState extends State<EditListingScreen> {
  final GlobalKey<FormState> _formKey = GlobalKey<FormState>();
  final TextEditingController _nameController = TextEditingController();
  final TextEditingController _priceController = TextEditingController();
  final TextEditingController _descriptionController = TextEditingController();

  final ListingService _listingService = GetIt.instance<ListingService>();
  final ImagePicker _picker = ImagePicker();

  Map<String, dynamic>? listing;
  XFile? _newImageFile;
  String? _currentImageBase64;
  bool _isLoading = false;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _loadListingData();
    });
  }

  void _loadListingData() {
    listing = ModalRoute.of(context)?.settings.arguments as Map<String, dynamic>?;

    if (listing != null) {
      _nameController.text = listing!['title'] ?? '';
      _priceController.text = listing!['price']?.toString() ?? '';
      _descriptionController.text = listing!['description'] ?? '';
      _currentImageBase64 = listing!['imageBase64'];
      setState(() {});
    }
  }

  @override
  void dispose() {
    _nameController.dispose();
    _priceController.dispose();
    _descriptionController.dispose();
    super.dispose();
  }

  Future<void> _selectImage() async {
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
                final pickedFile = await _picker.pickImage(
                  source: ImageSource.camera,
                  maxWidth: 800,
                  maxHeight: 800,
                  imageQuality: 70,
                );
                if (pickedFile != null) {
                  setState(() => _newImageFile = pickedFile);
                }
              },
            ),
            ListTile(
              leading: const Icon(Icons.photo),
              title: const Text('Choose from Gallery'),
              onTap: () async {
                Navigator.pop(context);
                final pickedFile = await _picker.pickImage(
                  source: ImageSource.gallery,
                  maxWidth: 800,
                  maxHeight: 800,
                  imageQuality: 70,
                );
                if (pickedFile != null) {
                  setState(() => _newImageFile = pickedFile);
                }
              },
            ),
            if (_currentImageBase64 != null || _newImageFile != null)
              ListTile(
                leading: const Icon(Icons.delete, color: Colors.red),
                title: const Text('Remove Image'),
                onTap: () {
                  Navigator.pop(context);
                  setState(() {
                    _newImageFile = null;
                    _currentImageBase64 = null;
                  });
                },
              ),
          ],
        ),
      ),
    );
  }

  Widget _buildImagePreview() {
    // Show new image if selected
    if (_newImageFile != null) {
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
              ? Image.network(_newImageFile!.path, fit: BoxFit.cover)
              : Image.file(File(_newImageFile!.path), fit: BoxFit.cover),
        ),
      );
    }

    // Show current image if exists
    if (_currentImageBase64 != null && _currentImageBase64!.isNotEmpty) {
      try {
        final bytes = base64Decode(_currentImageBase64!);
        return Container(
          width: 360,
          height: 360,
          decoration: BoxDecoration(
            border: Border.all(color: Colors.grey),
            borderRadius: BorderRadius.circular(8),
          ),
          child: ClipRRect(
            borderRadius: BorderRadius.circular(8),
            child: Image.memory(bytes, fit: BoxFit.cover),
          ),
        );
      } catch (e) {
        print('Error decoding image: $e');
      }
    }

    // Show placeholder
    return GestureDetector(
      onTap: _selectImage,
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
              Text('Add Image', style: TextStyle(color: Colors.grey)),
            ],
          ),
        ),
      ),
    );
  }

  Future<void> _updateListing() async {
    if (!_formKey.currentState!.validate() || listing == null) return;

    setState(() => _isLoading = true);

    try {
      final title = _nameController.text.trim();
      final price = double.tryParse(_priceController.text.trim()) ?? 0.0;
      final description = _descriptionController.text.trim();

      String? imageBase64 = _currentImageBase64;

      // If new image is selected, convert it
      if (_newImageFile != null) {
        imageBase64 = await _listingService.convertImageToBase64(_newImageFile!);
      } else if (_currentImageBase64 == null) {
        // Image was removed
        imageBase64 = null;
      }

      await _listingService.updateListing(
        listingId: listing!['id'],
        title: title,
        price: price,
        description: description,
        imageBase64: imageBase64,
      );

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Listing updated successfully!'),
            backgroundColor: Colors.green,
          ),
        );
        Navigator.pop(context);
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error updating listing: ${e.toString()}'),
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

  Future<void> _deleteListing() async {
    if (listing == null) return;

    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Delete Listing'),
        content: Text('Are you sure you want to delete "${listing!['title']}"?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () async {
              Navigator.pop(ctx); // Close dialog

              setState(() => _isLoading = true);

              try {
                await _listingService.deleteListing(listing!['id']);

                if (mounted) {
                  Navigator.pushNamedAndRemoveUntil(context, '/profile', (route) => false);
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

  @override
  Widget build(BuildContext context) {
    if (listing == null) {
      return Scaffold(
        backgroundColor: AppColour.background,
        appBar: AppBar(
          title: const Text('Edit Listing'),
          backgroundColor: Colors.transparent,
          foregroundColor: Colors.black,
          elevation: 0,
        ),
        body: const Center(
          child: Text('Listing data not found'),
        ),
      );
    }

    return Scaffold(
      backgroundColor: AppColour.background,
      appBar: AppBar(
        title: const Text('Edit Listing'),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () => Navigator.pop(context),
        ),
        backgroundColor: Colors.transparent,
        foregroundColor: Colors.black,
        elevation: 0,
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Form(
          key: _formKey,
          child: Column(
            children: [
              // Image Preview
              _buildImagePreview(),

              if (_currentImageBase64 != null || _newImageFile != null) ...[
                const SizedBox(height: 8),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                  children: [
                    TextButton.icon(
                      onPressed: _selectImage,
                      icon: const Icon(Icons.edit),
                      label: const Text('Change Image'),
                    ),
                    TextButton.icon(
                      onPressed: () {
                        setState(() {
                          _newImageFile = null;
                          _currentImageBase64 = null;
                        });
                      },
                      icon: const Icon(Icons.delete, color: Colors.red),
                      label: const Text('Remove Image'),
                      style: TextButton.styleFrom(foregroundColor: Colors.red),
                    ),
                  ],
                ),
              ],
              const SizedBox(height: 24),

              const Align(
                alignment: Alignment.centerLeft,
                child: Text('Listing Name', style: TextStyle(fontWeight: FontWeight.bold)),
              ),
              const SizedBox(height: 8),
              TextFormField(
                controller: _nameController,
                decoration: const InputDecoration(
                  hintText: 'Enter listing name',
                  border: OutlineInputBorder(),
                ),
                validator: (value) {
                  if (value == null || value.trim().isEmpty) {
                    return 'Please enter a listing name';
                  }
                  return null;
                },
              ),
              const SizedBox(height: 16),

              const Align(
                alignment: Alignment.centerLeft,
                child: Text('Price (\$)', style: TextStyle(fontWeight: FontWeight.bold)),
              ),
              const SizedBox(height: 8),
              TextFormField(
                controller: _priceController,
                decoration: const InputDecoration(
                  hintText: 'Enter price',
                  border: OutlineInputBorder(),
                ),
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
              const SizedBox(height: 16),

              const Align(
                alignment: Alignment.centerLeft,
                child: Text('Description', style: TextStyle(fontWeight: FontWeight.bold)),
              ),
              const SizedBox(height: 8),
              TextFormField(
                controller: _descriptionController,
                maxLines: 3,
                decoration: const InputDecoration(
                  hintText: 'Enter description',
                  border: OutlineInputBorder(),
                ),
                validator: (value) {
                  if (value == null || value.trim().isEmpty) {
                    return 'Please enter a description';
                  }
                  return null;
                },
              ),
              const SizedBox(height: 24),

              Row(
                children: [
                  Expanded(
                    child: ElevatedButton(
                      onPressed: _updateListing,
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.green,
                        foregroundColor: Colors.white,
                        padding: const EdgeInsets.symmetric(vertical: 12),
                      ),
                      child: const Text('Update Listing'),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: ElevatedButton(
                      onPressed: _deleteListing,
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.red,
                        foregroundColor: Colors.white,
                        padding: const EdgeInsets.symmetric(vertical: 12),
                      ),
                      child: const Text('Delete'),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}