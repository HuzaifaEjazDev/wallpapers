import 'dart:io';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:image_picker/image_picker.dart';

import '../../models/mockup/printfile_model.dart';
import '../../models/mockup/product_model.dart';
import '../../services/imgbb_service.dart'; // Added import for ImgBB service
import '../../viewmodels/mockup_provider.dart';
import '../../viewmodels/product_provider.dart';
import 'mockup_result_screen.dart';

class MockupGeneratorScreen extends StatefulWidget {
  final Product product;
  final Variant variant;
  final String? selectedPlacement; // Added selectedPlacement parameter

  const MockupGeneratorScreen({
    super.key,
    required this.product,
    required this.variant,
    this.selectedPlacement, // Added selectedPlacement parameter
  });

  @override
  State<MockupGeneratorScreen> createState() => _MockupGeneratorScreenState();
}

class _MockupGeneratorScreenState extends State<MockupGeneratorScreen> {
  File? _selectedImage;
  final ImagePicker _picker = ImagePicker();
  bool _isGenerating = false;
  bool _isUploading = false; // Added state for upload process

  /// Picks an image from gallery or camera
  Future<void> _pickImage(ImageSource source) async {
    try {
      final XFile? image = await _picker.pickImage(
        source: source,
        maxWidth: 2000,
        maxHeight: 2000,
        imageQuality: 90,
      );

      if (image != null) {
        setState(() {
          _selectedImage = File(image.path);
        });
      }
    } catch (e) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text('Error picking image: $e')));
    }
  }

  /// Generates a mockup for the selected product and variant
  Future<void> _generateMockup() async {
    print('Selected placement: ${widget.selectedPlacement}'); // Debug print
    
    if (_selectedImage == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please select an image first')),
      );
      return;
    }

    // Check if a placement is selected (required for mockup generation)
    if (widget.selectedPlacement == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please select a placement first')),
      );
      return;
    }

    setState(() {
      _isGenerating = true;
      _isUploading = true; // Set uploading state
    });

    String imageUrl = '';
    try {
      // Upload image to ImgBB
      try {
        imageUrl = await ImgBBService.uploadImage(_selectedImage!);
      } catch (e) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Failed to upload image: $e')),
        );
        return;
      } finally {
        setState(() {
          _isUploading = false;
        });
      }

      // Create mockup task using V1 API with the ImgBB URL
      final mockupProvider = Provider.of<MockupProvider>(
        context,
        listen: false,
      );

      await mockupProvider.createMockupTaskV1(
        productId: widget.product.id,
        variantId: widget.variant.id,
        format: 'jpg',
        width: 1800,
        imageUrl: imageUrl, // Use the ImgBB URL instead of static URL
        placementStyle: 'fit', // Use fit positioning by default
        placement: widget.selectedPlacement!, // Use the selected placement passed from previous screen
        printfileWidth: 1800,
        printfileHeight: 2400,
      );

      if (mockupProvider.taskKey != null) {
        // Navigate to result screen
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (context) => MockupResultScreen(
              taskKey: mockupProvider.taskKey!,
              product: widget.product,
              variant: widget.variant,
            ),
          ),
        );
      }
    } catch (e) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text('Error generating mockup: $e')));
    } finally {
      setState(() {
        _isGenerating = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Design Your Mockup'),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () => Navigator.pop(context),
        ),
      ),
      body: Container(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.center,
            colors: [
              Colors.green.shade900, // Dark green for top half
              Colors.grey.shade900,  // Dark grey for bottom half
            ],
          ),
        ),
        child: SingleChildScrollView(
          child: Padding(
            padding: const EdgeInsets.all(24),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                // Product Info
                Card(
                  child: Padding(
                    padding: const EdgeInsets.all(16),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          widget.product.title ?? 'Product',
                          style: const TextStyle(
                            fontSize: 20,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        const SizedBox(height: 8),
                        Text(
                          widget.variant.name ?? 'Variant',
                          style: TextStyle(fontSize: 16, color: Colors.grey[400]),
                        ),
                      ],
                    ),
                  ),
                ),
                const SizedBox(height: 24),

                // Upload Section
                Text(
                  'Upload Your Design',
                  style: const TextStyle(
                    fontSize: 24,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 16),

                // Image Preview or Upload Button
                if (_selectedImage != null)
                  Container(
                    height: 300,
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(16),
                      color: Colors.grey[900],
                    ),
                    child: ClipRRect(
                      borderRadius: BorderRadius.circular(16),
                      child: Image.file(_selectedImage!, fit: BoxFit.contain),
                    ),
                  )
                else
                  Container(
                    height: 300,
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(16),
                      border: Border.all(
                        color: Colors.grey[700]!,
                        width: 2,
                        style: BorderStyle.solid,
                      ),
                    ),
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(
                          Icons.cloud_upload_outlined,
                          size: 64,
                          color: Colors.grey[600],
                        ),
                        const SizedBox(height: 16),
                        Text(
                          'No image selected',
                          style: TextStyle(fontSize: 16, color: Colors.grey[400]),
                        ),
                      ],
                    ),
                  ),
                const SizedBox(height: 24),

                // Upload Buttons
                Row(
                  children: [
                    Expanded(
                      child: OutlinedButton.icon(
                        onPressed: () => _pickImage(ImageSource.gallery),
                        icon: const Icon(Icons.photo_library),
                        label: const Text('Gallery'),
                        style: OutlinedButton.styleFrom(
                          padding: const EdgeInsets.symmetric(vertical: 16),
                          side: const BorderSide(color: Colors.white), // White border
                          foregroundColor: Colors.white, // White text
                        ),
                      ),
                    ),
                    const SizedBox(width: 16),
                    Expanded(
                      child: OutlinedButton.icon(
                        onPressed: () => _pickImage(ImageSource.camera),
                        icon: const Icon(Icons.camera_alt),
                        label: const Text('Camera'),
                        style: OutlinedButton.styleFrom(
                          padding: const EdgeInsets.symmetric(vertical: 16),
                          side: const BorderSide(color: Colors.white), // White border
                          foregroundColor: Colors.white, // White text
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 32),

                // Generate Button
                SizedBox(
                  width: double.infinity,
                  child: ElevatedButton(
                    onPressed: _isGenerating || _isUploading ? null : _generateMockup,
                    style: ElevatedButton.styleFrom(
                      padding: const EdgeInsets.symmetric(vertical: 18),
                      backgroundColor: const Color(0xFF6C63FF), // Purple background
                      foregroundColor: Colors.white, // White text
                      disabledBackgroundColor: Colors.grey[800],
                    ),
                    child: _isGenerating
                        ? _isUploading
                            ? const Row(
                                mainAxisAlignment: MainAxisAlignment.center,
                                children: [
                                  SizedBox(
                                    height: 20,
                                    width: 20,
                                    child: CircularProgressIndicator(
                                      strokeWidth: 2,
                                      valueColor: AlwaysStoppedAnimation<Color>(
                                        Colors.white,
                                      ),
                                    ),
                                  ),
                                  SizedBox(width: 12),
                                  Text('Uploading Image...', style: TextStyle(color: Colors.white)),
                                ],
                              )
                            : const Row(
                                mainAxisAlignment: MainAxisAlignment.center,
                                children: [
                                  SizedBox(
                                    height: 20,
                                    width: 20,
                                    child: CircularProgressIndicator(
                                      strokeWidth: 2,
                                      valueColor: AlwaysStoppedAnimation<Color>(
                                        Colors.white,
                                      ),
                                    ),
                                  ),
                                  SizedBox(width: 12),
                                  Text('Generating Mockup...', style: TextStyle(color: Colors.white)),
                                ],
                              )
                        : const Text(
                            'Generate Mockup',
                            style: TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.bold,
                              color: Colors.white, // White text
                            ),
                          ),
                  ),
                ),
                const SizedBox(height: 16),

                // Info Text
                Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: const Color(0xFF6C63FF).withOpacity(0.1),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Row(
                    children: [
                      const Icon(Icons.info_outline, color: Color(0xFF6C63FF)),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Text(
                          'Upload your design and we\'ll generate a realistic mockup for you',
                          style: TextStyle(color: Colors.grey[300], fontSize: 14),
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}