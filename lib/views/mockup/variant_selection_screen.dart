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

  // Printfile related state (now visible for UI)
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
        
        // Load printfiles for the selected variant
        if (mounted) {
          _loadPrintfiles();
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
                            selectedPlacement: _selectedPlacement, // Pass the selected placement
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

          // Printfile Placement Selection
          _buildPrintfileSelectionSection(),

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
                              selectedPlacement: _selectedPlacement, // Pass the selected placement
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
                          _selectedPlacement = null; // Reset placement when color changes
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

  /// Builds the printfile selection section UI (same as mockup_generator_screen.dart)
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
      ),
    );
  }

  /// Builds the list of available placement options (same as mockup_generator_screen.dart)
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

  /// Loads printfiles for the selected variant (same as mockup_generator_screen.dart)
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
    // Require both a variant and a placement to be selected
    return _selectedVariant != null && _selectedPlacement != null;
  }
}