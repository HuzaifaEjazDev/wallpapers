import 'package:flutter/material.dart';
import '../services/pixabay_service.dart';
import '../widgets/cached_image.dart';
import 'category_wallpapers_screen.dart';

class CategoryScreen extends StatefulWidget {
  const CategoryScreen({super.key});

  @override
  State<CategoryScreen> createState() => _CategoryScreenState();
}

class _CategoryScreenState extends State<CategoryScreen> {
  late List<String> _categories;
  Map<String, List<dynamic>> _categoryWallpapers = {};
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadCategoriesAndWallpapers();
  }

  Future<void> _loadCategoriesAndWallpapers({bool forceRefresh = false}) async {
    setState(() {
      _isLoading = true;
    });

    try {
      // Check if data is already cached and we're not forcing a refresh
      if (PixabayService.isDataCached() && !forceRefresh) {
        // Use cached data
        _categories = PixabayService.getCachedCategories();
        for (String category in _categories) {
          final wallpapers = PixabayService.getCachedWallpapers(category);
          if (wallpapers != null) {
            _categoryWallpapers[category] = wallpapers;
          }
        }
      } else {
        // Fetch new data
        _categories = PixabayService.getRandomCategories();
        
        // Fetch 5 wallpapers for each category
        Map<String, List<dynamic>> newWallpapers = {};
        for (String category in _categories) {
          final wallpapers = await PixabayService.fetchWallpapersByCategory(category, 5);
          newWallpapers[category] = wallpapers;
          if (mounted) {
            setState(() {
              _categoryWallpapers[category] = wallpapers;
            });
          }
        }
        
        // Update cache with new data for next app start
        PixabayService.updateCache(_categories, newWallpapers);
      }
    } catch (error) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error loading categories: $error')),
        );
      }
    } finally {
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
    }
  }

  String _getThumbnailUrl(dynamic wallpaper) {
    // Use webformatURL and modify it to get a smaller size
    String webformatUrl = wallpaper['webformatURL'];
    // Replace _640 with _340 to get a smaller thumbnail
    return webformatUrl.replaceAll('_640', '_340');
  }

  Future<void> _refreshData() async {
    await _loadCategoriesAndWallpapers(forceRefresh: true);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Categories'),
        backgroundColor: Colors.green.shade900,
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: () => _loadCategoriesAndWallpapers(forceRefresh: true),
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
        child: RefreshIndicator(
          onRefresh: _refreshData,
          child: _isLoading
              ? const Center(
                  child: CircularProgressIndicator(
                    color: Colors.white,
                  ),
                )
              : ListView.builder(
                  itemCount: _categories.length,
                  itemBuilder: (context, index) {
                    final category = _categories[index];
                    final wallpapers = _categoryWallpapers[category] ?? [];
                    
                    return Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        // Category header with View More button
                        Padding(
                          padding: const EdgeInsets.fromLTRB(16.0, 16.0, 16.0, 8.0),
                          child: Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              Text(
                                category.toUpperCase(),
                                style: const TextStyle(
                                  fontSize: 20,
                                  fontWeight: FontWeight.bold,
                                  color: Colors.white,
                                ),
                              ),
                              TextButton(
                                onPressed: () {
                                  Navigator.push(
                                    context,
                                    MaterialPageRoute(
                                      builder: (context) => CategoryWallpapersScreen(
                                        category: category,
                                      ),
                                    ),
                                  );
                                },
                                child: const Text(
                                  'VIEW MORE',
                                  style: TextStyle(
                                    color: Colors.greenAccent,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ),
                        // Horizontal scrollable wallpapers
                        SizedBox(
                          height: MediaQuery.of(context).size.height * 0.25,
                          child: ListView.builder(
                            scrollDirection: Axis.horizontal,
                            itemCount: wallpapers.length,
                            itemBuilder: (context, wallpaperIndex) {
                              final wallpaper = wallpapers[wallpaperIndex];
                              final imageUrl = _getThumbnailUrl(wallpaper);
                              
                              return Padding(
                                padding: const EdgeInsets.only(
                                  left: 16.0,
                                  right: 8.0,
                                  bottom: 16.0,
                                ),
                                child: CachedImage(
                                  imageUrl: imageUrl,
                                  width: MediaQuery.of(context).size.width * 0.25,
                                  borderRadius: BorderRadius.circular(12),
                                ),
                              );
                            },
                          ),
                        ),
                      ],
                    );
                  },
                ),
        ),
      ),
    );
  }
}