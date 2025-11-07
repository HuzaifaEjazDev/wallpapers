import 'dart:io';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:image_picker/image_picker.dart';

import '../../models/mockup/category_model.dart';
import '../../models/mockup/product_model.dart';
import '../../models/mockup/printfile_model.dart';
import '../../services/imgbb_service.dart';
import '../../viewmodels/product_provider.dart';
import '../../viewmodels/mockup_provider.dart';
import 'mockup_result_screen.dart';

class MockupUpdatedFlowScreen extends StatefulWidget {
  const MockupUpdatedFlowScreen({super.key});

  @override
  State<MockupUpdatedFlowScreen> createState() => _MockupUpdatedFlowScreenState();
}

class _MockupUpdatedFlowScreenState extends State<MockupUpdatedFlowScreen>
    with SingleTickerProviderStateMixin {
  int? _selectedCategoryId;
  String? _selectedCategoryName;
  Product? _selectedProduct;
  
  // Variant selection state
  List<Variant> _variants = [];
  String? _selectedColor;
  Variant? _selectedVariant;
  
  // Printfile related state
  PrintfileResult? _printfileResult;
  bool _isLoadingPrintfiles = false;
  String? _printfileError;
  String? _selectedPlacement;
  
  // Image selection state
  File? _selectedImage;
  final ImagePicker _picker = ImagePicker();
  bool _isGenerating = false;
  bool _isUploading = false;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      Provider.of<ProductProvider>(context, listen: false).fetchCategories();
    });
  }

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
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error picking image: $e')),
        );
      }
    }
  }

  /// Generates a mockup for the selected product and variant
  Future<void> _generateMockup() async {
    if (_selectedImage == null) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Please select an image first')),
        );
      }
      return;
    }

    // Check if a placement is selected (required for mockup generation)
    if (_selectedPlacement == null) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Please select a placement first')),
        );
      }
      return;
    }

    if (mounted) {
      setState(() {
        _isGenerating = true;
        _isUploading = true; // Set uploading state
      });
    }

    String imageUrl = '';
    try {
      // Upload image to ImgBB
      try {
        imageUrl = await ImgBBService.uploadImage(_selectedImage!);
      } catch (e) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('Failed to upload image: $e')),
          );
        }
        return;
      } finally {
        if (mounted) {
          setState(() {
            _isUploading = false;
          });
        }
      }

      // Create mockup task using V1 API with the ImgBB URL
      final mockupProvider = Provider.of<MockupProvider>(
        context,
        listen: false,
      );

      await mockupProvider.createMockupTaskV1(
        productId: _selectedProduct!.id,
        variantId: _selectedVariant!.id,
        format: 'jpg',
        width: 1800,
        imageUrl: imageUrl, // Use the ImgBB URL instead of static URL
        placementStyle: 'fit', // Use fit positioning by default
        placement: _selectedPlacement!, // Use the selected placement
        printfileWidth: 1800,
        printfileHeight: 2400,
      );

      if (mockupProvider.taskKey != null && mounted) {
        // Navigate to result screen
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (context) => MockupResultScreen(
              taskKey: mockupProvider.taskKey!,
              product: _selectedProduct!,
              variant: _selectedVariant!,
            ),
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error generating mockup: $e')),
        );
      }
    } finally {
      if (mounted) {
        setState(() {
          _isGenerating = false;
        });
      }
    }
  }

  /// Loads product variants from API or cache
  Future<void> _loadVariants(Product product) async {
    try {
      // First check if variants are already in the product
      if (product.variants != null && product.variants!.isNotEmpty) {
        setState(() {
          _variants = product.variants!;
        });
      } else {
        // Fetch variants from API
        final productProvider = Provider.of<ProductProvider>(context, listen: false);
        final variants = await productProvider.getCatalogProductVariants(product.id);
        setState(() {
          _variants = variants;
        });
      }

      // Auto-select first color if colors exist, otherwise auto-select first variant
      if (_variants.isNotEmpty) {
        final uniqueColors = _getUniqueColors();
        if (uniqueColors.isNotEmpty) {
          _selectedColor = uniqueColors.first;
          // Auto-select first variant for the selected color
          final colorVariants = _getVariantsForSelectedColor();
          if (colorVariants.isNotEmpty) {
            _selectedVariant = colorVariants.first;
          }
        } else {
          // No colors available, auto-select first variant
          _selectedVariant = _variants.first;
        }
        
        // Load printfiles for the selected variant
        _loadPrintfiles(product);
      }
    } catch (e) {
      setState(() {
        // Handle error
      });
    }
  }

  /// Gets list of unique colors from variants
  List<String> _getUniqueColors() {
    final colors = _variants
        .where((variant) => variant.color != null && variant.color!.isNotEmpty)
        .map((variant) => variant.color!)
        .toSet()
        .toList();
    return colors;
  }

  /// Checks if colors are available for variants
  bool _hasColorsAvailable() {
    return _getUniqueColors().isNotEmpty;
  }

  /// Gets variants for the selected color
  List<Variant> _getVariantsForSelectedColor() {
    if (_selectedColor == null) return [];
    return _variants
        .where((variant) => variant.color == _selectedColor)
        .toList();
  }

  /// Loads printfiles for the selected variant
  Future<void> _loadPrintfiles(Product product) async {
    if (_selectedVariant == null) return;

    setState(() {
      _isLoadingPrintfiles = true;
      _printfileError = null;
    });

    try {
      final provider = Provider.of<ProductProvider>(context, listen: false);
      final result = await provider.getProductVariantPrintfiles(product.id);

      setState(() {
        _printfileResult = result;
        // Auto-select the placement if there's only one option available
        if (_printfileResult != null && _selectedPlacement == null) {
          final variantPrintfile = _printfileResult!.variant_printfiles
              .where((vp) => vp.variant_id == _selectedVariant!.id)
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

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Mockup Generator'),
        backgroundColor: Colors.black,
        foregroundColor: Colors.white,
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
        child: SafeArea(
          child: Consumer<ProductProvider>(
            builder: (context, provider, child) {
              return SingleChildScrollView(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Header section
                    const Padding(
                      padding: EdgeInsets.all(24.0),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'Select a Category',
                            style: TextStyle(
                              fontSize: 36,
                              fontWeight: FontWeight.bold,
                              letterSpacing: -1,
                            ),
                          ),
                          SizedBox(height: 8),
                          Text(
                            'Choose a category to get started',
                            style: TextStyle(
                              fontSize: 16,
                              color: Colors.grey,
                            ),
                          ),
                        ],
                      ),
                    ),
                    
                    // Categories section
                    _buildCategoriesSection(provider),
                    
                    // Products section
                    _buildProductsSection(provider),
                    
                    // Product details section (variants, colors, placements)
                    if (_selectedProduct != null) ...[
                      const SizedBox(height: 32),
                      _buildProductDetailsSection(),
                    ],
                    
                    // Image upload section
                    if (_selectedProduct != null && _selectedVariant != null && _selectedPlacement != null)
                      _buildImageUploadSection(),
                    
                    // Generate button
                    if (_selectedProduct != null && _selectedVariant != null && _selectedPlacement != null)
                      Padding(
                        padding: const EdgeInsets.all(24),
                        child: SizedBox(
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
                      ),
                  ],
                ),
              );
            },
          ),
        ),
      ),
    );
  }

  /// Builds the categories selection section
  Widget _buildCategoriesSection(ProductProvider provider) {
    if (provider.isLoading && provider.categories.isEmpty) {
      return const Padding(
        padding: EdgeInsets.symmetric(horizontal: 24.0),
        child: Center(child: CircularProgressIndicator()),
      );
    }

    if (provider.error != null && provider.categories.isEmpty) {
      return Padding(
        padding: const EdgeInsets.all(24.0),
        child: Center(
          child: Column(
            children: [
              Text('Error: ${provider.error}'),
              const SizedBox(height: 16),
              ElevatedButton(
                onPressed: () {
                  provider.clearError();
                  provider.fetchCategories();
                },
                child: const Text('Retry'),
              ),
            ],
          ),
        ),
      );
    }

    final categories = provider.categories;

    return SizedBox(
      height: 120,
      child: ListView.builder(
        scrollDirection: Axis.horizontal,
        itemCount: categories.length,
        itemBuilder: (context, index) {
          final category = categories[index];
          final isSelected = _selectedCategoryId == category.id;
          
          return Container(
            width: 100,
            margin: const EdgeInsets.only(left: 16, right: 8),
            child: InkWell(
              onTap: () {
                setState(() {
                  _selectedCategoryId = category.id;
                  _selectedCategoryName = category.title;
                  _selectedProduct = null; // Reset product selection
                  _selectedVariant = null; // Reset variant selection
                  _selectedPlacement = null; // Reset placement selection
                  _selectedImage = null; // Reset image selection
                });
                
                // Fetch products for the selected category
                final productProvider = Provider.of<ProductProvider>(context, listen: false);
                productProvider.fetchProductsByCategory(category.id);
              },
              child: Stack(
                children: [
                  Container(
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(16),
                      color: Colors.grey[800],
                      border: Border.all(
                        color: isSelected ? const Color(0xFF6C63FF) : Colors.transparent,
                        width: 2,
                      ),
                    ),
                    child: ClipRRect(
                      borderRadius: BorderRadius.circular(16),
                      child: CachedNetworkImage(
                        imageUrl: category.image_url!,
                        fit: BoxFit.cover,
                        placeholder: (context, url) => Container(
                          color: Colors.grey[700],
                          child: const Center(
                            child: CircularProgressIndicator(
                              color: Color(0xFF6C63FF),
                            ),
                          ),
                        ),
                        errorWidget: (context, url, error) => Container(
                          color: Colors.grey[800],
                          child: const Icon(
                            Icons.category,
                            color: Colors.grey,
                          ),
                        ),
                      ),
                    ),
                  ),
                  // Black gradient overlay
                  Container(
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(16),
                      gradient: const LinearGradient(
                        begin: Alignment.topCenter,
                        end: Alignment.bottomCenter,
                        colors: [
                          Colors.transparent,
                          Colors.black54,
                        ],
                      ),
                    ),
                  ),
                  // Category title
                  Padding(
                    padding: const EdgeInsets.all(8.0),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      mainAxisAlignment: MainAxisAlignment.end,
                      children: [
                        Text(
                          category.title,
                          style: const TextStyle(
                            fontSize: 12,
                            fontWeight: FontWeight.bold,
                            color: Colors.white,
                          ),
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          );
        },
      ),
    );
  }

  /// Builds the products section
  Widget _buildProductsSection(ProductProvider provider) {
    // Only show products section if a category is selected
    if (_selectedCategoryId == null) {
      return const Padding(
        padding: EdgeInsets.all(24.0),
        child: Center(
          child: Text(
            'Please select a category to view products',
            style: TextStyle(
              fontSize: 16,
              color: Colors.grey,
            ),
          ),
        ),
      );
    }

    // Show loading indicator when fetching products
    if (provider.isLoading && provider.products.isEmpty) {
      return const Padding(
        padding: EdgeInsets.all(24.0),
        child: Center(child: CircularProgressIndicator()),
      );
    }

    // Show error if there's an issue fetching products
    if (provider.error != null && provider.products.isEmpty) {
      return Padding(
        padding: const EdgeInsets.all(24.0),
        child: Center(
          child: Column(
            children: [
              Icon(Icons.error_outline, size: 64, color: Colors.grey[600]),
              const SizedBox(height: 16),
              Text(
                'Error loading products',
                style: TextStyle(fontSize: 18, color: Colors.grey[400]),
              ),
              const SizedBox(height: 8),
              Text(
                provider.error!.contains('type')
                    ? 'Data format error - please try again'
                    : provider.error!,
                style: TextStyle(fontSize: 14, color: Colors.grey[600]),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 24),
              ElevatedButton.icon(
                onPressed: () {
                  provider.clearError();
                  provider.fetchProductsByCategory(_selectedCategoryId!);
                },
                icon: const Icon(Icons.refresh),
                label: const Text('Retry'),
              ),
            ],
          ),
        ),
      );
    }

    final products = provider.products;

    if (products.isEmpty) {
      return Padding(
        padding: const EdgeInsets.all(24.0),
        child: Center(
          child: Column(
            children: [
              Icon(
                Icons.inventory_2_outlined,
                size: 64,
                color: Colors.grey[600],
              ),
              const SizedBox(height: 16),
              Text(
                'No products found',
                style: TextStyle(fontSize: 18, color: Colors.grey[400]),
              ),
            ],
          ),
        ),
      );
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.all(24.0),
          child: Text(
            'Products in $_selectedCategoryName',
            style: const TextStyle(
              fontSize: 24,
              fontWeight: FontWeight.bold,
            ),
          ),
        ),
        SizedBox(
          height: 250,
          child: ListView.builder(
            scrollDirection: Axis.horizontal,
            itemCount: products.length,
            itemBuilder: (context, index) {
              return Container(
                width: 150,
                margin: const EdgeInsets.only(left: 16, right: 8),
                child: _buildProductCard(products[index]),
              );
            },
          ),
        ),
      ],
    );
  }

  /// Builds a product card
  Widget _buildProductCard(Product product) {
    final isSelected = _selectedProduct?.id == product.id;
    
    return Card(
      elevation: isSelected ? 8 : 2,
      shadowColor: isSelected ? const Color(0xFF6C63FF) : null,
      child: InkWell(
        onTap: () {
          setState(() {
            _selectedProduct = product;
            _selectedVariant = null; // Reset variant selection
            _selectedPlacement = null; // Reset placement selection
            _selectedImage = null; // Reset image selection
          });
          
          // Load variants for the selected product
          _loadVariants(product);
        },
        borderRadius: BorderRadius.circular(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Expanded(
              child: Container(
                decoration: BoxDecoration(
                  borderRadius: const BorderRadius.vertical(
                    top: Radius.circular(16),
                  ),
                  color: Colors.grey[900],
                  border: Border.all(
                    color: isSelected ? const Color(0xFF6C63FF) : Colors.transparent,
                    width: 2,
                  ),
                ),
                child: product.image != null
                    ? ClipRRect(
                        borderRadius: const BorderRadius.vertical(
                          top: Radius.circular(16),
                        ),
                        child: CachedNetworkImage(
                          imageUrl: product.image!,
                          width: double.infinity,
                          fit: BoxFit.cover,
                          placeholder: (context, url) => Center(
                            child: CircularProgressIndicator(
                              color: Theme.of(context).colorScheme.primary,
                            ),
                          ),
                          errorWidget: (context, url, error) => const Icon(
                            Icons.image_not_supported,
                            size: 48,
                            color: Colors.grey,
                          ),
                        ),
                      )
                    : const Center(
                        child: Icon(Icons.image, size: 48, color: Colors.grey),
                      ),
              ),
            ),
            Padding(
              padding: const EdgeInsets.all(12),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    product.title ?? 'No Name',
                    style: const TextStyle(
                      fontWeight: FontWeight.bold,
                      fontSize: 14,
                    ),
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                  ),
                  if (product.brand != null) ...[
                    const SizedBox(height: 4),
                    Text(
                      product.brand!,
                      style: TextStyle(color: Colors.grey[400], fontSize: 12),
                    ),
                  ],
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  /// Builds the product details section (variants, colors, placements)
  Widget _buildProductDetailsSection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Product header
        Container(
          padding: const EdgeInsets.all(24),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                _selectedProduct!.title ?? 'Product',
                style: const TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
              ),
              if (_selectedProduct!.brand != null) ...[
                const SizedBox(height: 4),
                Text(
                  'Brand: ${_selectedProduct!.brand}',
                  style: TextStyle(fontSize: 16, color: Colors.grey[400]),
                ),
              ],
              if (_selectedProduct!.type != null) ...[
                const SizedBox(height: 4),
                Text(
                  'Type: ${_selectedProduct!.type}',
                  style: TextStyle(fontSize: 16, color: Colors.grey[400]),
                ),
              ],
            ],
          ),
        ),
        
        // Color selection section
        if (_hasColorsAvailable()) _buildColorSelectionSection(),
        
        // Printfile placement selection section
        _buildPrintfileSelectionSection(),
      ],
    );
  }

  /// Builds the color selection section
  Widget _buildColorSelectionSection() {
    final uniqueColors = _getUniqueColors();
    
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Choose Color',
            style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 12),
          SizedBox(
            height: 120,
            child: ListView.builder(
              scrollDirection: Axis.horizontal,
              itemCount: uniqueColors.length,
              itemBuilder: (context, index) {
                final color = uniqueColors[index];
                final colorVariants = _variants
                    .where((v) => v.color == color)
                    .toList();
                final firstVariant = colorVariants.isNotEmpty
                    ? colorVariants.first
                    : null;
                final isSelected = _selectedColor == color;

                return Container(
                  margin: const EdgeInsets.only(right: 12),
                  child: InkWell(
                    onTap: () {
                      setState(() {
                        _selectedColor = color;
                        _selectedVariant = firstVariant;
                        _selectedPlacement = null; // Reset placement when color changes
                        _selectedImage = null; // Reset image selection
                      });
                      // Load printfiles for the new variant
                      _loadPrintfiles(_selectedProduct!);
                    },
                    child: Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 16,
                        vertical: 8,
                      ),
                      decoration: BoxDecoration(
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(
                          color: isSelected
                              ? const Color(0xFF6C63FF)
                              : Colors.grey[600]!,
                          width: isSelected ? 3 : 1,
                        ),
                      ),
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          if (firstVariant?.image != null)
                            ClipRRect(
                              borderRadius: const BorderRadius.vertical(
                                top: Radius.circular(9),
                              ),
                              child: CachedNetworkImage(
                                imageUrl: firstVariant!.image!,
                                height: 60,
                                width: 80,
                                fit: BoxFit.cover,
                              ),
                            )
                          else
                            Container(
                              height: 60,
                              width: 80,
                              decoration: BoxDecoration(
                                color: Colors.grey[800],
                                borderRadius: const BorderRadius.vertical(
                                  top: Radius.circular(9),
                                ),
                              ),
                              child: const Icon(Icons.image, size: 24),
                            ),
                          Padding(
                            padding: const EdgeInsets.all(8),
                            child: Text(
                              color,
                              style: const TextStyle(
                                fontSize: 12,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                );
              },
            ),
          ),
        ],
      ),
    );
  }

  /// Builds the printfile selection section
  Widget _buildPrintfileSelectionSection() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
      child: Column(
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
                    onPressed: () => _loadPrintfiles(_selectedProduct!),
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
      ),
    );
  }

  /// Builds the list of available placement options
  Widget _buildPlacementsList() {
    if (_printfileResult == null) {
      return const SizedBox.shrink();
    }

    // Find placements for the selected variant
    final variantPrintfile = _printfileResult!.variant_printfiles
        .where((vp) => vp.variant_id == _selectedVariant?.id)
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

  /// Builds the image upload section
  Widget _buildImageUploadSection() {
    return Container(
      padding: const EdgeInsets.all(24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Upload Your Design',
            style: TextStyle(
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