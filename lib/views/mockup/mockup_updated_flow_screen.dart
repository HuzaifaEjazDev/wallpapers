import 'dart:io';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:image_picker/image_picker.dart';
import 'package:dio/dio.dart';
import 'package:path_provider/path_provider.dart';
import '../../models/mockup/category_model.dart';
import '../../models/mockup/product_model.dart';
import '../../models/mockup/printfile_model.dart';
import '../../services/imgbb_service.dart';
import '../../viewmodels/product_provider.dart';
import '../../viewmodels/mockup_provider.dart';
import 'mockup_result_screen.dart';

class MockupUpdatedFlowScreen extends StatefulWidget {
  final String? preselectedImageUrl;
  final int? preselectedCategoryId; // Add this parameter
  final String? preselectedCategoryName; // Add this parameter

  const MockupUpdatedFlowScreen({super.key, this.preselectedImageUrl, this.preselectedCategoryId, this.preselectedCategoryName});

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
  
  // Scroll controller for categories
  final ScrollController _categoryScrollController = ScrollController();

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) {
        final productProvider = Provider.of<ProductProvider>(context, listen: false);
        productProvider.fetchCategories();
        
        // If a preselected image URL is provided, set it as the selected image
        if (widget.preselectedImageUrl != null) {
          // We'll need to download the image and set it as a file
          _downloadAndSetPreselectedImage(widget.preselectedImageUrl!);
        }
        
        // If a preselected category is provided, set it as the selected category
        if (widget.preselectedCategoryId != null && widget.preselectedCategoryName != null) {
          setState(() {
            _selectedCategoryId = widget.preselectedCategoryId;
            _selectedCategoryName = widget.preselectedCategoryName;
          });
          
          // Fetch products for the selected category
          productProvider.fetchProductsByCategory(widget.preselectedCategoryId!);
          
          // Scroll to the selected category after a short delay to ensure the list is built
          Future.delayed(const Duration(milliseconds: 100), () {
            if (mounted) {
              _scrollToSelectedCategory();
            }
          });
        }
      }
    });
  }

  @override
  void dispose() {
    _categoryScrollController.dispose();
    super.dispose();
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
    print('Building MockupUpdatedFlowScreen');
    print('Preselected image URL: ${widget.preselectedImageUrl}');
    print('Selected image path: ${_selectedImage?.path}');
    print('Preselected category ID: ${widget.preselectedCategoryId}');
    print('Selected category ID: $_selectedCategoryId');
    
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
                    // Info message when preselected image is available - full width just after AppBar
                    if (widget.preselectedImageUrl != null)
                      Container(
                        width: double.infinity,
                        padding: const EdgeInsets.all(16),
                        color: Colors.white, // White background
                        child: const Row(
                          children: [
                            Icon(
                              Icons.info,
                              color: Colors.black, // Black "i" icon
                              size: 20,
                            ),
                            SizedBox(width: 8),
                            Expanded(
                              child: Text(
                                'The Wallpaper Image is selected for Mockup. Now Select other options and click to generate the Mockup.',
                                style: TextStyle(
                                  fontSize: 14,
                                  color: Colors.black, // Black text
                                  fontWeight: FontWeight.w500,
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                    
                    // Header section with reduced text size
                    const Padding(
                      padding: EdgeInsets.all(24.0),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'Select a Category',
                            style: TextStyle(
                              fontSize: 24, // Reduced from 36 to 24
                              fontWeight: FontWeight.bold,
                              letterSpacing: -1,
                            ),
                          ),
                          SizedBox(height: 8),
                          Text(
                            'Choose a category to get started',
                            style: TextStyle(
                              fontSize: 14, // Reduced from 16 to 14
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
                    
                    // Image upload section - show when product, variant, and placement are selected OR when there's a preselected image
                    if ((_selectedProduct != null && _selectedVariant != null && _selectedPlacement != null) || widget.preselectedImageUrl != null)
                      _buildImageUploadSection(),
                    
                    // Generate button - show when product, variant, and placement are selected (no image requirement)
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
      height: 130, // Increased height to accommodate text below
      child: ListView.builder(
        controller: _categoryScrollController, // Add the controller
        scrollDirection: Axis.horizontal,
        itemCount: categories.length,
        itemBuilder: (context, index) {
          final category = categories[index];
          final isSelected = _selectedCategoryId == category.id;
          
          return Container(
            width: 100, // Fixed width for all categories
            margin: const EdgeInsets.only(left: 4, right: 0), // Further reduced horizontal spacing
            child: Column(
              children: [
                // Category image container with fixed size
                InkWell(
                  onTap: () {
                    setState(() {
                      _selectedCategoryId = category.id;
                      _selectedCategoryName = category.title;
                      _selectedProduct = null; // Reset product selection
                      _selectedVariant = null; // Reset variant selection
                      _selectedPlacement = null; // Reset placement selection
                      // Only reset image selection if there's no preselected image
                      if (widget.preselectedImageUrl == null) {
                        _selectedImage = null;
                      }
                    });
                    
                    // Fetch products for the selected category
                    final productProvider = Provider.of<ProductProvider>(context, listen: false);
                    productProvider.fetchProductsByCategory(category.id);
                  },
                  child: Container(
                    width: 90,
                    height: 90,
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(8), // Increased radius
                      color: Colors.grey[800],
                      border: Border.all(
                        color: isSelected ? Colors.green : Colors.transparent, // Green border when selected
                        width: 2,
                      ),
                    ),
                    child: ClipRRect(
                      borderRadius: BorderRadius.circular(6), // Match the container radius
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
                ),
                // Category title below the image container
                Padding(
                  padding: const EdgeInsets.only(top: 8, left: 4, right: 4), // Space outside the container
                  child: Text(
                    category.title,
                    style: const TextStyle(
                      fontSize: 11, // Consistent font size
                      fontWeight: FontWeight.bold,
                      color: Colors.white,
                    ),
                    maxLines: 2, // Allow up to 2 lines
                    textAlign: TextAlign.center,
                    overflow: TextOverflow.ellipsis,
                    softWrap: true, // Allow text to wrap
                  ),
                ),
              ],
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
          height: 200, // Fixed height
          child: ListView.builder(
            scrollDirection: Axis.horizontal,
            itemCount: products.length,
            itemBuilder: (context, index) {
              return Container(
                width: 120, // Reduced width
                margin: const EdgeInsets.only(left: 6, right: 6), // Reduced spacing
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
      shadowColor: isSelected ? Colors.green : null, // Green shadow when selected
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(8), // Reduced radius
        side: BorderSide(
          color: isSelected ? Colors.green : Colors.transparent, // Green border when selected
          width: 2,
        ),
      ),
      child: InkWell(
        onTap: () {
          setState(() {
            _selectedProduct = product;
            _selectedVariant = null; // Reset variant selection
            _selectedPlacement = null; // Reset placement selection
            // Only reset image selection if there's no preselected image
            if (widget.preselectedImageUrl == null) {
              _selectedImage = null;
            }
          });
          
          // Load variants for the selected product
          _loadVariants(product);
        },
        borderRadius: BorderRadius.circular(8), // Match the card radius
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Expanded(
              child: Container(
                decoration: BoxDecoration(
                  borderRadius: const BorderRadius.vertical(
                    top: Radius.circular(8), // Match the card radius
                  ),
                  color: Colors.grey[900],
                ),
                child: product.image != null
                    ? ClipRRect(
                        borderRadius: const BorderRadius.vertical(
                          top: Radius.circular(8), // Match the container radius
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
              padding: const EdgeInsets.all(8), // Reduced padding
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    product.title ?? 'No Name',
                    style: const TextStyle(
                      fontWeight: FontWeight.bold,
                      fontSize: 12, // Reduced font size
                    ),
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                  ),
                  if (product.brand != null) ...[
                    const SizedBox(height: 2), // Reduced spacing
                    Text(
                      product.brand!,
                      style: TextStyle(color: Colors.grey[400], fontSize: 10), // Reduced font size
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
        // Color selection section
        if (_hasColorsAvailable()) _buildColorSelectionSection(),
        
        // Printfile placement selection section
        _buildPrintfileSelectionSection(),
        
        // Display selected product image below placement selection
        if (_selectedProduct != null && _selectedVariant != null)
          Padding(
            padding: const EdgeInsets.all(24),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'Selected Product Preview',
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 12),
                Container(
                  width: 120, // Updated width
                  height: 170, // Updated height
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(8),
                    color: Colors.grey[900],
                  ),
                  child: _selectedVariant?.image != null
                      ? ClipRRect(
                          borderRadius: BorderRadius.circular(8),
                          child: CachedNetworkImage(
                            imageUrl: _selectedVariant!.image!,
                            width: 120, // Updated width
                            height: 170, // Updated height
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
              ],
            ),
          ),
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
            height: 50, // Reduced height for better design
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
                        // Only reset image selection if there's no preselected image
                        if (widget.preselectedImageUrl == null) {
                          _selectedImage = null;
                        }
                      });
                      // Load printfiles for the new variant
                      _loadPrintfiles(_selectedProduct!);
                    },
                    child: Container(
                      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4), // Added horizontal padding, reduced vertical padding
                      decoration: BoxDecoration(
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(
                          color: isSelected
                              ? Colors.green
                              : Colors.grey[600]!,
                          width: isSelected ? 3 : 1,
                        ),
                      ),
                      child: Center(
                        child: Text(
                          color,
                          style: const TextStyle(
                            fontSize: 12,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
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

            // Selected placement info - removed the green container
            if (_selectedPlacement != null) ...[
              Padding(
                padding: const EdgeInsets.only(top: 8),
                child: Text(
                  'Selected Placement: ${_formatPlacementName(_selectedPlacement!)}',
                  style: const TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.bold,
                    color: Colors.white,
                  ),
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

          // Image Preview - show when image is selected (either preselected or user uploaded)
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
            // Show nothing when no image is selected (don't show loading indicator after initial load)
            const SizedBox.shrink(),
          
          const SizedBox(height: 24),

          // Single Upload Button with white border - disabled when preselected image is available
          SizedBox(
            width: double.infinity,
            child: OutlinedButton.icon(
              onPressed: widget.preselectedImageUrl != null ? null : _showImageSourceBottomSheet,
              icon: const Icon(Icons.cloud_upload_outlined),
              label: const Text('Upload your Image'),
              style: OutlinedButton.styleFrom(
                padding: const EdgeInsets.symmetric(vertical: 16),
                side: BorderSide(
                  color: widget.preselectedImageUrl != null 
                    ? Colors.grey // Grey border when disabled
                    : Colors.white, // White border when enabled
                ),
                foregroundColor: widget.preselectedImageUrl != null 
                  ? Colors.grey // Grey text when disabled
                  : Colors.white, // White text when enabled
                backgroundColor: widget.preselectedImageUrl != null 
                  ? Colors.grey.withOpacity(0.3) // Light grey background when disabled
                  : null, // No background when enabled
                textStyle: const TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                ),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  /// Shows bottom sheet with image source options
  void _showImageSourceBottomSheet() {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      builder: (BuildContext context) {
        return Container(
          decoration: BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topCenter,
              end: Alignment.bottomCenter,
              colors: [
                Colors.green.shade900, // Dark green for top
                Colors.grey.shade900,  // Dark grey for bottom
              ],
            ),
            borderRadius: const BorderRadius.vertical(top: Radius.circular(20)),
          ),
          child: Padding(
            padding: const EdgeInsets.all(24),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                // Handle bar
                Container(
                  width: 40,
                  height: 4,
                  decoration: BoxDecoration(
                    color: Colors.grey[600],
                    borderRadius: BorderRadius.circular(2),
                  ),
                ),
                const SizedBox(height: 24),
                
                const Text(
                  'Select Image Source',
                  style: TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                    color: Colors.white,
                  ),
                ),
                const SizedBox(height: 24),
                
                // Gallery Option
                ListTile(
                  leading: const Icon(
                    Icons.photo_library,
                    color: Colors.white,
                    size: 30,
                  ),
                  title: const Text(
                    'Gallery',
                    style: TextStyle(
                      fontSize: 18,
                      color: Colors.white,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                  onTap: () {
                    Navigator.pop(context);
                    _pickImage(ImageSource.gallery);
                  },
                ),
                
                const SizedBox(height: 16),
                
                // Camera Option
                ListTile(
                  leading: const Icon(
                    Icons.camera_alt,
                    color: Colors.white,
                    size: 30,
                  ),
                  title: const Text(
                    'Camera',
                    style: TextStyle(
                      fontSize: 18,
                      color: Colors.white,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                  onTap: () {
                    Navigator.pop(context);
                    _pickImage(ImageSource.camera);
                  },
                ),
                
                const SizedBox(height: 16),
              ],
            ),
          ),
        );
      },
    );
  }

  /// Downloads and sets a preselected image from URL
  Future<void> _downloadAndSetPreselectedImage(String imageUrl) async {
    try {
      // Download the image using Dio
      final dio = Dio();
      final tempDir = await getTemporaryDirectory();
      final tempPath = '${tempDir.path}/preselected_image_${DateTime.now().millisecondsSinceEpoch}.jpg';
      
      await dio.download(imageUrl, tempPath);
      
      // Set the downloaded image as the selected image
      setState(() {
        _selectedImage = File(tempPath);
      });
      
      // Debug print to check if image is set
      print('Preselected image set: ${_selectedImage?.path}');
      
      // Show a snackbar to confirm the image was loaded
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Image loaded successfully')),
        );
      }
    } catch (e) {
      print('Failed to load preselected image: $e');
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Failed to load preselected image: $e')),
        );
      }
    }
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

  /// Scrolls to the selected category in the horizontal list
  void _scrollToSelectedCategory() {
    if (_selectedCategoryId == null || !_categoryScrollController.hasClients) {
      return;
    }
    
    // Get the provider to access the categories list
    final productProvider = Provider.of<ProductProvider>(context, listen: false);
    final categories = productProvider.categories;
    
    // Find the index of the selected category
    final selectedIndex = categories.indexWhere((category) => category.id == _selectedCategoryId);
    
    if (selectedIndex != -1) {
      // Calculate the scroll position to center the selected category
      // Each category item is 100px wide with 4px left margin
      final itemWidth = 100.0;
      final itemMargin = 4.0;
      final scrollPosition = (selectedIndex * (itemWidth + itemMargin)) - (MediaQuery.of(context).size.width / 2) + (itemWidth / 2);
      
      // Animate to the calculated position
      _categoryScrollController.animateTo(
        scrollPosition.clamp(0.0, _categoryScrollController.position.maxScrollExtent),
        duration: const Duration(milliseconds: 300),
        curve: Curves.easeInOut,
      );
    }
  }
}