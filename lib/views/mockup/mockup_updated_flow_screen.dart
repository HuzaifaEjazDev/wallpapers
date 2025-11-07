import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:cached_network_image/cached_network_image.dart';

import '../../models/mockup/category_model.dart';
import '../../models/mockup/product_model.dart';
import '../../viewmodels/product_provider.dart';
import 'variant_selection_screen.dart';

class MockupUpdatedFlowScreen extends StatefulWidget {
  const MockupUpdatedFlowScreen({super.key});

  @override
  State<MockupUpdatedFlowScreen> createState() => _MockupUpdatedFlowScreenState();
}

class _MockupUpdatedFlowScreenState extends State<MockupUpdatedFlowScreen>
    with SingleTickerProviderStateMixin {
  int? _selectedCategoryId;
  String? _selectedCategoryName;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      Provider.of<ProductProvider>(context, listen: false).fetchCategories();
    });
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
    return Card(
      child: InkWell(
        onTap: () {
          Navigator.push(
            context,
            MaterialPageRoute(
              builder: (context) => VariantSelectionScreen(product: product),
            ),
          );
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
}