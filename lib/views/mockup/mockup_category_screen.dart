import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../models/mockup/category_model.dart';
import '../../viewmodels/product_provider.dart';
import 'product_list_screen.dart';

class MockupCategoryScreen extends StatefulWidget {
  const MockupCategoryScreen({super.key});

  @override
  State<MockupCategoryScreen> createState() => _MockupCategoryScreenState();
}

class _MockupCategoryScreenState extends State<MockupCategoryScreen>
    with SingleTickerProviderStateMixin {
  late AnimationController _animationController;
  late Animation<double> _fadeAnimation;

  @override
  void initState() {
    super.initState();
    _animationController = AnimationController(
      duration: const Duration(milliseconds: 800),
      vsync: this,
    );
    _fadeAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(parent: _animationController, curve: Curves.easeInOut),
    );
    _animationController.forward();

    WidgetsBinding.instance.addPostFrameCallback((_) {
      Provider.of<ProductProvider>(context, listen: false).fetchCategories();
    });
  }

  @override
  void dispose() {
    _animationController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SafeArea(
        child: Consumer<ProductProvider>(
          builder: (context, provider, child) {
            if (provider.isLoading) {
              return const Center(child: CircularProgressIndicator());
            }

            if (provider.error != null) {
              return Center(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
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
              );
            }

            final categories = provider.categories;

            return FadeTransition(
              opacity: _fadeAnimation,
              child: CustomScrollView(
                slivers: [
                  SliverToBoxAdapter(
                    child: Padding(
                      padding: const EdgeInsets.all(24.0),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const SizedBox(height: 20),
                          const Text(
                            'Mockup Generator',
                            style: TextStyle(
                              fontSize: 36,
                              fontWeight: FontWeight.bold,
                              letterSpacing: -1,
                            ),
                          ),
                          const SizedBox(height: 8),
                          Text(
                            'Choose a category to get started',
                            style: TextStyle(
                              fontSize: 16,
                              color: Colors.grey[400],
                            ),
                          ),
                          const SizedBox(height: 32),
                        ],
                      ),
                    ),
                  ),
                  SliverPadding(
                    padding: const EdgeInsets.symmetric(horizontal: 16),
                    sliver: SliverGrid(
                      gridDelegate:
                      const SliverGridDelegateWithFixedCrossAxisCount(
                        crossAxisCount: 2,
                        childAspectRatio: 0.85,
                        crossAxisSpacing: 16,
                        mainAxisSpacing: 16,
                      ),
                      delegate: SliverChildBuilderDelegate((context, index) {
                        return _buildCategoryCard(categories[index], index);
                      }, childCount: categories.length),
                    ),
                  ),
                  const SliverToBoxAdapter(child: SizedBox(height: 32)),
                ],
              ),
            );
          },
        ),
      ),
    );
  }

  /// Handles category selection and navigation
  void _onCategoryTap(CategoryModel category) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => ProductListScreen(
          categoryName: category.title,
          categoryId: category.id,
        ),
      ),
    );
  }

  Widget _buildCategoryCard(CategoryModel category, int index) {
    return Card(
      margin: const EdgeInsets.all(16),
      elevation: 0,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: InkWell(
        /// Handles category selection and navigation
        onTap: () {
          _onCategoryTap(category);
        },
        child: Stack(
          children: [
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(16),
                color: Colors.grey[800],
                image: DecorationImage(
                  image: NetworkImage(category.image_url!),
                  fit: BoxFit.cover,
                ),
              ),
            ),
            const DecoratedBox(
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topCenter,
                  end: Alignment.bottomCenter,
                  colors: [Colors.transparent, Colors.black],
                ),
              ),
            ),
            Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    category.title,
                    style: const TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                      color: Colors.black,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
