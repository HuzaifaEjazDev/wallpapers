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

  const MockupGeneratorScreen({
    super.key,
    required this.product,
    required this.variant,
  });

  @override
  State<MockupGeneratorScreen> createState() => _MockupGeneratorScreenState();
}

class _MockupGeneratorScreenState extends State<MockupGeneratorScreen> {
  File? _selectedImage;
  final ImagePicker _picker = ImagePicker();
  bool _isGenerating = false;
  bool _isUploading = false; // Added state for upload process

  // Printfile related state
  PrintfileResult? _printfileResult;
  bool _isLoadingPrintfiles = false;
  String? _printfileError;
  String? _selectedPlacement;

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

  @override
  void initState() {
    super.initState();
    _loadPrintfiles();
  }

  /// Loads printfiles for the current product
  Future<void> _loadPrintfiles() async {
    setState(() {
      _isLoadingPrintfiles = true;
      _printfileError = null;
    });

    try {
      final provider = Provider.of<ProductProvider>(context, listen: false);
      final result = await provider.getProductVariantPrintfiles(
        widget.product.id,
      );

      setState(() {
        _printfileResult = result;
        // Auto-select the placement if there's only one option available
        if (_printfileResult != null && _selectedPlacement == null) {
          final variantPrintfile = _printfileResult!.variant_printfiles
              .where((vp) => vp.variant_id == widget.variant.id)
              .firstOrNull;
          
          // Only auto-select if there's exactly one placement option
          if (variantPrintfile != null && variantPrintfile.placements.length == 1) {
            _selectedPlacement = variantPrintfile.placements.keys.first;
          }
        }
      });
    } catch (e) {
      setState(() {
        _printfileError = e.toString();
      });
    } finally {
      setState(() {
        _isLoadingPrintfiles = false;
      });
    }
  }

  /// Generates a mockup for the selected product and variant
  Future<void> _generateMockup() async {
    if (_selectedImage == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please select an image first')),
      );
      return;
    }

    // Check if a placement is selected (required for mockup generation)
    if (_selectedPlacement == null) {
      // Check if there's exactly one placement option
      bool hasSinglePlacement = false;
      String? singlePlacement;
      
      if (_printfileResult != null) {
        final variantPrintfile = _printfileResult!.variant_printfiles
            .where((vp) => vp.variant_id == widget.variant.id)
            .firstOrNull;
        
        if (variantPrintfile != null && variantPrintfile.placements.length == 1) {
          hasSinglePlacement = true;
          singlePlacement = variantPrintfile.placements.keys.first;
        }
      }
      
      // If there's only one placement option, use it automatically
      if (hasSinglePlacement && singlePlacement != null) {
        setState(() {
          _selectedPlacement = singlePlacement;
        });
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Please select a placement first')),
        );
        return;
      }
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
        placement: _selectedPlacement!, // Use the selected or auto-selected placement
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

                // Printfile Placement Selection
                _buildPrintfileSelectionSection(),
                const SizedBox(height: 32),

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

  /// Builds the printfile selection section UI
  Widget _buildPrintfileSelectionSection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Section header
        Row(
          children: [
            Icon(Icons.style_outlined, color: Colors.blue.shade700, size: 20),
            const SizedBox(width: 8),
            Text(
              'Select Printfile Placement',
              style: TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.bold,
                color: Colors.blue.shade700,
              ),
            ),
          ],
        ),
        const SizedBox(height: 12),

        // Loading state
        if (_isLoadingPrintfiles)
          Container(
            height: 80,
            child: const Center(child: CircularProgressIndicator()),
          )
        // Error state
        else if (_printfileError != null)
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: Colors.red.shade200),
            ),
            child: Row(
              children: [
                Icon(Icons.error_outline, color: Colors.red.shade600, size: 20),
                const SizedBox(width: 12),
                Expanded(
                  child: Text(
                    'Failed to load placement options',
                    style: TextStyle(color: Colors.red.shade700),
                  ),
                ),
                TextButton(
                  onPressed: _loadPrintfiles,
                  child: const Text('Retry'),
                ),
              ],
            ),
          )
        // Printfile options
        else if (_printfileResult != null) ...[
          // Available placements horizontal list
          _buildPlacementsList(),

          const SizedBox(height: 16),

          // Selected placement info
          if (_selectedPlacement != null) ...[
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: Colors.green.shade200),
              ),
              child: Row(
                children: [
                  Icon(
                    Icons.check_circle,
                    color: Colors.green.shade600,
                    size: 20,
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Selected Placement',
                          style: TextStyle(
                            fontWeight: FontWeight.bold,
                            color: Colors.green.shade700,
                          ),
                        ),
                        Text(
                          _printfileResult!
                                  .available_placements[_selectedPlacement] != null
                              ? _formatPlacementName(
                                  _printfileResult!.available_placements[_selectedPlacement]!)
                              : _formatPlacementName(_selectedPlacement!),
                          style: TextStyle(color: Colors.green.shade600),
                        ),
                      ],
                    ),
                  ),
                  IconButton(
                    onPressed: () {
                      setState(() {
                        _selectedPlacement = null;
                      });
                    },
                    icon: const Icon(Icons.clear, size: 18),
                    color: Colors.green.shade600,
                  ),
                ],
              ),
            ),
          ],
        ],
      ],
    );
  }

  /// Builds the list of available placement options
  Widget _buildPlacementsList() {
    if (_printfileResult == null) {
      return const SizedBox.shrink();
    }

    // Find placements for the selected variant
    final variantPrintfile = _printfileResult!.variant_printfiles
        .where((vp) => vp.variant_id == widget.variant.id)
        .firstOrNull;

    if (variantPrintfile == null) {
      return Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(borderRadius: BorderRadius.circular(12)),
        child: Text(
          'No placement options available for this variant',
          style: TextStyle(color: Colors.grey.shade700),
        ),
      );
    }

    // Auto-select the placement if there's only one option available and none is selected yet
    if (variantPrintfile.placements.length == 1 && _selectedPlacement == null) {
      setState(() {
        _selectedPlacement = variantPrintfile.placements.keys.first;
      });
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Available placements for this variant:',
          style: TextStyle(
            fontSize: 14,
            color: Colors.grey.shade600,
            fontWeight: FontWeight.w500,
          ),
        ),
        const SizedBox(height: 12),

        // Horizontal scrollable list of placement chips (show all options including single)
        SizedBox(
          height: 50,
          child: ListView.builder(
            scrollDirection: Axis.horizontal,
            itemCount: variantPrintfile.placements.length,
            itemBuilder: (context, index) {
              final entry = variantPrintfile.placements.entries.elementAt(
                index,
              );
              final placementName = entry.key;
              final printfileId = entry.value;
              final isSelected = _selectedPlacement == placementName;

              final placementDescription =
                  _printfileResult!.available_placements[placementName] != null
                      ? _formatPlacementName(_printfileResult!.available_placements[placementName]!)
                      : _formatPlacementName(placementName);

              return Container(
                margin: const EdgeInsets.only(right: 12),
                child: FilterChip(
                  label: Text(
                    _formatPlacementName(placementName),
                    style: TextStyle(
                      fontWeight: isSelected
                          ? FontWeight.bold
                          : FontWeight.normal,
                      fontSize: 12,
                    ),
                  ),
                  onSelected: (selected) {
                    setState(() {
                      if (selected) {
                        _selectedPlacement = placementName;
                      } else {
                        _selectedPlacement = null;
                      }
                    });
                  },
                  selected: isSelected,

                  selectedColor: Colors.blue.shade800,
                  checkmarkColor: Colors.blue.shade700,
                  side: BorderSide(
                    color: isSelected
                        ? Colors.blue.shade400
                        : Colors.grey.shade400,
                  ),
                  tooltip: '${_formatPlacementName(placementDescription)}\nPrintfile ID: $printfileId',
                ),
              );
            },
          ),
        ),
      ],
    );
  }

  /// Formats placement name for display: capitalize first letter and replace underscores with spaces
  String _formatPlacementName(String name) {
    if (name.isEmpty) return name;
    
    // Replace underscores with spaces
    String formatted = name.replaceAll('_', ' ');
    
    // Capitalize first letter
    if (formatted.length > 1) {
      formatted = '${formatted[0].toUpperCase()}${formatted.substring(1)}';
    } else {
      formatted = formatted.toUpperCase();
    }
    
    return formatted;
  }
}