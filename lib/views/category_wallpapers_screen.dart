import 'package:flutter/material.dart';
import '../services/pexels_service.dart';
import '../widgets/cached_image.dart';
import 'wallpaper_detail_screen.dart';

class CategoryWallpapersScreen extends StatefulWidget {
  final String category;
  
  const CategoryWallpapersScreen({super.key, required this.category});

  @override
  State<CategoryWallpapersScreen> createState() => _CategoryWallpapersScreenState();
}

class _CategoryWallpapersScreenState extends State<CategoryWallpapersScreen> {
  List<dynamic> _wallpapers = [];
  bool _isLoading = false;
  bool _isLoadingMore = false;
  bool _hasMoreData = true;
  int _currentPage = 1;
  final int _perPage = 20; // 20 images per page as requested
  final String _apiKey = '53072685-0770a12c564f2eb7a535baeb1';
  late ScrollController _scrollController;
  int _totalHits = 0;

  @override
  void initState() {
    super.initState();
    _scrollController = ScrollController();
    _scrollController.addListener(_scrollListener);
    _loadWallpapers();
  }

  @override
  void dispose() {
    _scrollController.removeListener(_scrollListener);
    _scrollController.dispose();
    super.dispose();
  }

  void _scrollListener() {
    // Load more when we're at 85% of the scroll position
    if (_scrollController.position.pixels >=
        _scrollController.position.maxScrollExtent * 0.85) {
      if (!_isLoading && !_isLoadingMore && _hasMoreData) {
        _loadWallpapers(loadMore: true);
      }
    }
  }

  Future<void> _loadWallpapers({bool loadMore = false}) async {
    if (loadMore && (_isLoading || _isLoadingMore || !_hasMoreData)) return;

    setState(() {
      if (loadMore) {
        _isLoadingMore = true;
      } else {
        _isLoading = true;
        _currentPage = 1;
        _wallpapers = [];
        _hasMoreData = true;
        _totalHits = 0;
      }
    });

    try {
      // Use only the Pexels service to fetch wallpapers
      final result = await PexelsService.fetchWallpapersByCategoryWithPagination(
          widget.category, _perPage, _currentPage);
      
      final List hits = result['hits'];
      final int totalHits = result['totalHits'] ?? 0;
      
      // Check if the widget is still mounted before updating state
      if (mounted) {
        setState(() {
          if (loadMore) {
            _wallpapers.addAll(hits);
            _isLoadingMore = false;
            // Check if we've reached the end of available data
            // The API limits to 500 total hits per query, so we check against that
            if (hits.isEmpty || _wallpapers.length >= totalHits || _wallpapers.length >= 500) {
              _hasMoreData = false;
            }
          } else {
            _wallpapers = hits;
            _totalHits = totalHits;
            _isLoading = false;
            _hasMoreData = hits.isNotEmpty && hits.length >= _perPage && _wallpapers.length < 500 && _wallpapers.length < totalHits;
          }
          // Increment page number AFTER loading data
          _currentPage++;
        });
      }
    } catch (error) {
      // Check if the widget is still mounted before updating state
      if (mounted) {
        setState(() {
          if (loadMore) {
            _isLoadingMore = false;
          } else {
            _isLoading = false;
          }
        });
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Failed to load wallpapers: $error')),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('${widget.category.toUpperCase()} WALLPAPERS'),
        backgroundColor: Colors.green.shade900,
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
              Colors.green.shade900,
              Colors.grey.shade900,
            ],
          ),
        ),
        child: _isLoading && _wallpapers.isEmpty
            ? const Center(
                child: CircularProgressIndicator(
                  color: Colors.white,
                ),
              )
            : RefreshIndicator(
                onRefresh: () => _loadWallpapers(),
                child: GridView.builder(
                  controller: _scrollController,
                  gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                    crossAxisCount: 3, // 3 images per row
                    crossAxisSpacing: 8,
                    mainAxisSpacing: 8,
                    childAspectRatio: 0.7,
                  ),
                  itemCount: _wallpapers.length + (_hasMoreData && _isLoadingMore ? 1 : 0),
                  itemBuilder: (context, index) {
                    if (index == _wallpapers.length && _hasMoreData && _isLoadingMore) {
                      // Show loading indicator at the end
                      return const Center(
                        child: CircularProgressIndicator(
                          color: Colors.white,
                        ),
                      );
                    }
                    
                    final wallpaper = _wallpapers[index];
                    // Use Pexels image URL structure
                    String imageUrl = wallpaper['src']['medium'];
                    
                    // Use large image for full screen view
                    String largeImageUrl = wallpaper['src']['large2x'];
                    
                    return GestureDetector(
                      onTap: () {
                        // Check if the widget is still mounted before navigating
                        if (mounted) {
                          Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (context) => WallpaperDetailScreen(
                                imageUrl: largeImageUrl,
                                category: widget.category,
                              ),
                            ),
                          );
                        }
                      },
                      child: ClipRRect(
                        borderRadius: BorderRadius.circular(12),
                        child: CachedImage(
                          imageUrl: imageUrl,
                          width: double.infinity,
                          fit: BoxFit.cover,
                        ),
                      ),
                    );
                  },
                ),
              ),
      ),
    );
  }
}