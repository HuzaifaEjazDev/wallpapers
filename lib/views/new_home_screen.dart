import 'dart:math';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:cached_network_image/cached_network_image.dart';

import '../models/mockup/category_model.dart';
import '../viewmodels/product_provider.dart';

class NewHomeScreen extends StatefulWidget {
  const NewHomeScreen({super.key});

  @override
  State<NewHomeScreen> createState() => _NewHomeScreenState();
}

class _NewHomeScreenState extends State<NewHomeScreen> {
  List<CategoryModel> _randomCategories = [];
  bool _isLoading = true;
  String _error = '';

  @override
  void initState() {
    super.initState();
    _loadRandomCategories();
  }

  /// Fetches categories and selects 5 random ones
  Future<void> _loadRandomCategories() async {
    try {
      final productProvider = Provider.of<ProductProvider>(context, listen: false);
      
      // Fetch categories if not already loaded
      if (productProvider.categories.isEmpty) {
        await productProvider.fetchCategories();
      }
      
      // Select 5 random categories
      final allCategories = productProvider.categories;
      if (allCategories.isNotEmpty) {
        final random = Random();
        final randomCategories = <CategoryModel>[];
        
        // Make a copy of the list to avoid modifying the original
        final categoriesCopy = List<CategoryModel>.from(allCategories);
        
        // Select up to 5 random categories
        final count = min(5, categoriesCopy.length);
        for (int i = 0; i < count; i++) {
          final randomIndex = random.nextInt(categoriesCopy.length);
          randomCategories.add(categoriesCopy[randomIndex]);
          categoriesCopy.removeAt(randomIndex);
        }
        
        setState(() {
          _randomCategories = randomCategories;
          _isLoading = false;
        });
      } else {
        setState(() {
          _isLoading = false;
          _error = 'No categories found';
        });
      }
    } catch (e) {
      setState(() {
        _isLoading = false;
        _error = 'Failed to load categories: $e';
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Mockit'),
        backgroundColor: Colors.black,
        foregroundColor: Colors.white,
        flexibleSpace: Container(
          decoration: BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topCenter,
              end: Alignment.bottomCenter,
              colors: [
                Colors.green.shade900, // Dark green at top
                Colors.grey.shade900,  // Dark grey at bottom
              ],
            ),
          ),
        ),
      ),
      body: Container(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [
              Colors.green.shade900, // Dark green at top
              Colors.grey.shade900,  // Dark grey at bottom
            ],
          ),
        ),
        child: SingleChildScrollView(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Popular Mockups section
              const Padding(
                padding: EdgeInsets.all(24.0),
                child: Text(
                  'Popular Mockups',
                  style: TextStyle(
                    fontSize: 24,
                    fontWeight: FontWeight.bold,
                    color: Colors.white,
                  ),
                ),
              ),
              
              // Random categories horizontal scroll
              _buildCategoriesSection(),
              
              // Your creations section
              const Padding(
                padding: EdgeInsets.all(24.0),
                child: Text(
                  'Your creations',
                  style: TextStyle(
                    fontSize: 24,
                    fontWeight: FontWeight.bold,
                    color: Colors.white,
                  ),
                ),
              ),
              
              // Designs section
              const Padding(
                padding: EdgeInsets.all(24.0),
                child: Text(
                  'Designs',
                  style: TextStyle(
                    fontSize: 24,
                    fontWeight: FontWeight.bold,
                    color: Colors.white,
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  /// Builds the categories section with horizontal scroll
  Widget _buildCategoriesSection() {
    if (_isLoading) {
      return const Padding(
        padding: EdgeInsets.symmetric(horizontal: 24.0),
        child: Center(child: CircularProgressIndicator()),
      );
    }

    if (_error.isNotEmpty) {
      return Padding(
        padding: const EdgeInsets.all(24.0),
        child: Center(
          child: Text(
            _error,
            style: const TextStyle(color: Colors.white),
          ),
        ),
      );
    }

    if (_randomCategories.isEmpty) {
      return const Padding(
        padding: EdgeInsets.all(24.0),
        child: Center(
          child: Text(
            'No categories available',
            style: TextStyle(color: Colors.white),
          ),
        ),
      );
    }

    return SizedBox(
      height: 150,
      child: ListView.builder(
        scrollDirection: Axis.horizontal,
        itemCount: _randomCategories.length,
        itemBuilder: (context, index) {
          final category = _randomCategories[index];
          
          return Container(
            width: 120,
            margin: const EdgeInsets.only(left: 16),
            child: Column(
              children: [
                // Category image
                Container(
                  height: 100,
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(8),
                    color: Colors.grey[800],
                  ),
                  child: ClipRRect(
                    borderRadius: BorderRadius.circular(8),
                    child: category.image_url != null
                        ? CachedNetworkImage(
                            imageUrl: category.image_url!,
                            fit: BoxFit.cover,
                            placeholder: (context, url) => Container(
                              color: Colors.grey[700],
                              child: const Center(
                                child: CircularProgressIndicator(
                                  color: Colors.white30,
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
                          )
                        : Container(
                            color: Colors.grey[800],
                            child: const Icon(
                              Icons.category,
                              color: Colors.grey,
                            ),
                          ),
                  ),
                ),
                // Category title
                Padding(
                  padding: const EdgeInsets.only(top: 8),
                  child: Text(
                    category.title,
                    style: const TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.bold,
                      color: Colors.white,
                    ),
                    maxLines: 2,
                    textAlign: TextAlign.center,
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
              ],
            ),
          );
        },
      ),
    );
  }
}