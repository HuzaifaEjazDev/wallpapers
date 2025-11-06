import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:cached_network_image/cached_network_image.dart';
import '../../models/mockup/printfile_model.dart';
import '../../models/mockup/product_model.dart';
import '../../viewmodels/product_provider.dart';
import 'mockup_generator_screen.dart';

/// Screen for selecting product variants (color, size) and viewing printfile options
class VariantSelectionScreen extends StatefulWidget {
  final Product product;

  const VariantSelectionScreen({super.key, required this.product});

  @override
  State<VariantSelectionScreen> createState() => _VariantSelectionScreenState();
}

class _VariantSelectionScreenState extends State<VariantSelectionScreen> {
  List<Variant> _variants = [];
  bool _isLoadingVariants = false;
  String? _error;

  // Selection state
  String? _selectedColor;
  Variant? _selectedVariant;

  // Printfile related state (keep these for functionality but hide UI)
  PrintfileResult? _printfileResult;
  bool _isLoadingPrintfiles = false;
  String? _printfileError;
  String? _selectedPlacement;

  @override
  void initState() {
    super.initState();
    _loadVariants();
  }

  /// Loads product variants from API or cache
  Future<void> _loadVariants() async {
    if (mounted) {
      setState(() {
        _isLoadingVariants = true;
        _error = null;
      });
    }

    try {
      // First check if variants are already in the product
      if (widget.product.variants != null &&
          widget.product.variants!.isNotEmpty) {
        if (mounted) {
          setState(() {
            _variants = widget.product.variants!;
          });
        }
      } else {
        // Fetch variants from API
        final productProvider = Provider.of<ProductProvider>(
          context,
          listen: false,
        );
        final variants = await productProvider.getCatalogProductVariants(
          widget.product.id,
        );
        if (mounted) {
          setState(() {
            _variants = variants;
          });
        }
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
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _error = e.toString();
        });
      }
    } finally {
      if (mounted) {
        setState(() {
          _isLoadingVariants = false;
        });
      }
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

  /// Gets the first variant for selected color
  Variant? _getSelectedColorVariant() {
    final colorVariants = _getVariantsForSelectedColor();
    return colorVariants.isNotEmpty ? colorVariants.first : null;
  }

  @override
  Widget build(BuildContext context) {
    final uniqueColors = _getUniqueColors();
    final hasColors = _hasColorsAvailable();
    final selectedColorVariant = hasColors
        ? _getSelectedColorVariant()
        : _selectedVariant;

    return Scaffold(
      appBar: AppBar(
        title: Text(widget.product.title ?? 'Product Variants'),
        backgroundColor: Colors.black,
        foregroundColor: Colors.white,
        actions: [
          if (_selectedVariant != null)
            IconButton(
              icon: const Icon(Icons.arrow_forward),
              onPressed: _canProceedToMockup()
                  ? () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (context) => MockupGeneratorScreen(
                            product: widget.product,
                            variant: _selectedVariant!,
                          ),
                        ),
                      );
                    }
                  : null,
            ),
        ],
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
        child: _buildBody(uniqueColors, hasColors, selectedColorVariant),
      ),
    );
  }

  /// Builds the main body content
  Widget _buildBody(
    List<String> uniqueColors,
    bool hasColors,
    Variant? selectedColorVariant,
  ) {
    if (_isLoadingVariants) {
      return const Center(child: CircularProgressIndicator());
    }

    if (_error != null) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Text('Error: $_error'),
            const SizedBox(height: 16),
            ElevatedButton(
              onPressed: _loadVariants,
              child: const Text('Retry'),
            ),
          ],
        ),
      );
    }

    if (_variants.isEmpty) {
      return const Center(
        child: Text('No variants available for this product'),
      );
    }

    return SingleChildScrollView(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          // Product Header
          _buildProductHeader(),

          // Color Selection (if available)
          if (hasColors) _buildColorSelectionSection(uniqueColors),

          // Action Button at the end
          if (_selectedVariant != null)
            Padding(
              padding: const EdgeInsets.all(24),
              child: ElevatedButton.icon(
                onPressed: _canProceedToMockup()
                    ? () {
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (context) => MockupGeneratorScreen(
                              product: widget.product,
                              variant: _selectedVariant!,
                            ),
                          ),
                        );
                      }
                    : null,
                icon: const Icon(Icons.arrow_forward),
                label: const Text('Proceed to Mockup Generation'),
                style: ElevatedButton.styleFrom(
                  padding: const EdgeInsets.symmetric(vertical: 16),
                  backgroundColor: const Color(0xFF6C63FF), // Purple background
                  foregroundColor: Colors.white, // White text
                  textStyle: const TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                  ),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                  elevation: 8,
                ),
              ),
            ),
        ],
      ),
    );
  }

  /// Builds the product header section
  Widget _buildProductHeader() {
    return Container(
      padding: const EdgeInsets.all(24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            widget.product.title ?? 'Product',
            style: const TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
          ),
          if (widget.product.brand != null) ...[
            const SizedBox(height: 4),
            Text(
              'Brand: ${widget.product.brand}',
              style: TextStyle(fontSize: 16, color: Colors.grey[400]),
            ),
          ],
          if (widget.product.type != null) ...[
            const SizedBox(height: 4),
            Text(
              'Type: ${widget.product.type}',
              style: TextStyle(fontSize: 16, color: Colors.grey[400]),
            ),
          ],
        ],
      ),
    );
  }

  /// Builds the color selection section
  Widget _buildColorSelectionSection(List<String> uniqueColors) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Choose Color',
            style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
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
                      if (mounted) {
                        setState(() {
                          _selectedColor = color;
                          _selectedVariant = firstVariant;
                          _selectedPlacement = null;
                        });
                      }
                      // Load printfiles only if the widget is still mounted
                      if (mounted) {
                        _loadPrintfiles();
                      }
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

  /// Builds the size selection section for selected color
  Widget _buildSizeSelectionSection() {
    // Hide the size selection UI as requested
    return Container();
  }

  /// Builds direct variant selection when no colors are available
  Widget _buildDirectVariantSelection() {
    // Hide the variant selection UI as requested
    return Container();
  }

  /// Builds the printfile options section UI
  Widget _buildPrintfileOptionsSection() {
    // Completely hide the printfile options section UI as requested
    return Container();
  }

  /// Builds the list of placement options for the selected variant
  Widget _buildPlacementsList() {
    // Hide the placement options UI as requested
    return Container();
  }

  /// Loads printfiles for the selected variant
  Future<void> _loadPrintfiles() async {
    if (_selectedVariant == null) return;

    if (mounted) {
      setState(() {
        _isLoadingPrintfiles = true;
        _printfileError = null;
      });
    }

    try {
      final provider = Provider.of<ProductProvider>(context, listen: false);
      final result = await provider.getProductVariantPrintfiles(
        widget.product.id,
      );

      if (mounted) {
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
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _printfileError = e.toString();
        });
      }
    } finally {
      if (mounted) {
        setState(() {
          _isLoadingPrintfiles = false;
        });
      }
    }
  }

  /// Checks if user can proceed to mockup generation
  bool _canProceedToMockup() {
    // Only require a variant to be selected, not a placement
    // since we've removed the placement UI from this screen
    return _selectedVariant != null;
  }
}