import 'package:flutter/material.dart';
import 'package:flutter_card_swiper/flutter_card_swiper.dart';
import 'package:wallpapers/views/mockup/mockup_updated_flow_screen.dart';
import '../services/pexels_service.dart';
import '../services/home_screen_service.dart';
import 'wallpaper_detail_screen.dart';
import 'mockup/mockup_category_screen.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  List<dynamic> _wallpapers = [];
  bool _isLoading = false;
  bool _isLoadingMore = false;
  bool _hasMoreData = true;
  String _searchQuery = 'wallpapers';
  int _currentPage = 1;
  int _displayPage = 1; // Add a separate variable for display
  int _currentIndex = 0;
  int _totalHits = 0;
  final int _perPage = 20;
  final TextEditingController _searchController = TextEditingController();

  @override
  void initState() {
    super.initState();
    _searchController.text = '';
    _loadWallpapers();
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  Future<void> _loadWallpapers({bool loadMore = false, bool forceRefresh = false}) async {
    // If we're not loading more and data is cached, use cached data
    if (!loadMore && !forceRefresh && HomeScreenService.isDataCached() && HomeScreenService.getCachedQuery() == _searchQuery) {
      if (mounted) {
        setState(() {
          _wallpapers = List.from(HomeScreenService.getCachedWallpapers());
          _totalHits = HomeScreenService.getCachedTotalHits();
          _isLoading = false;
          _hasMoreData = _wallpapers.length < _totalHits && _wallpapers.length < 500;
        });
      }
      return;
    }
    
    if (loadMore && (_isLoading || _isLoadingMore || !_hasMoreData)) return;

    setState(() {
      if (loadMore) {
        _isLoadingMore = true;
      } else {
        _isLoading = true;
        _currentPage = 1; // Reset to first page for new searches
        _displayPage = 1; // Reset display page as well
        if (!forceRefresh && !HomeScreenService.isDataCached()) {
          _wallpapers = [];
        }
        _hasMoreData = true;
        _totalHits = 0;
      }
    });

    try {
      // Add double quotes around the query
      final quotedQuery = '"$_searchQuery"';
      
      // Use only the Pexels service to fetch wallpapers
      final result = await PexelsService.fetchWallpapersBySearch(
          quotedQuery, _perPage, _currentPage);
      
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
          // Update display page to match current page
          _displayPage = _currentPage;
          // Increment page number AFTER loading data
          _currentPage++;
        });
        
        // Update cache with new data
        HomeScreenService.updateCache(_wallpapers, _searchQuery, _totalHits);
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

  Future<void> _performSearch() async {
    // Check if the widget is still mounted before updating state
    if (mounted) {
      setState(() {
        final userInput = _searchController.text.trim();
        // Use only the user input for search (no default prompt added)
        _searchQuery = userInput.isEmpty ? 'wallpapers' : userInput;
      });
      _loadWallpapers(forceRefresh: true);
    }
  }

  void _checkForPagination(int? currentIndex) {
    // Update current index for pagination display
    if (currentIndex != null) {
      // Check if the widget is still mounted before updating state
      if (mounted) {
        setState(() {
          _currentIndex = currentIndex;
        });
      }
      
      // Load more images when we reach the 17th image out of 20
      if (_wallpapers.length - currentIndex <= 3 && _hasMoreData && !_isLoadingMore) {
        _loadWallpapers(loadMore: true);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
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
        child: Column(
          children: [
            // Top row with back icon and filter sort icon
            Container(
              padding: const EdgeInsets.only(top: 50, left: 16, right: 16, bottom: 16),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  // iOS back icon at leading position
                  Text('Wallpapers'),
                  // Filter sort icon at trailing position
                  IconButton(
                    icon: const Icon(Icons.sort, color: Colors.white),
                    onPressed: () {
                      // Filter functionality (to be implemented)
                    },
                  ),
                ],
              ),
            ),
            // Search bar with rounded corners
            Container(
              margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
              decoration: BoxDecoration(
                color: Colors.white.withOpacity(0.2),
                borderRadius: BorderRadius.circular(30),
              ),
              child: TextField(
                controller: _searchController,
                style: const TextStyle(color: Colors.white),
                decoration: const InputDecoration(
                  hintText: 'Search wallpapers...',
                  hintStyle: TextStyle(color: Colors.white70),
                  border: InputBorder.none,
                  prefixIcon: Icon(Icons.search, color: Colors.white70),
                  contentPadding: EdgeInsets.symmetric(horizontal: 20, vertical: 15),
                ),
                onSubmitted: (_) => _performSearch(),
              ),
            ),
            // Content area with wallpaper swiper
            Expanded(
              child: Container(
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    begin: Alignment.centerRight,
                    end: Alignment.centerLeft,
                    colors: [
                      Colors.green.shade900.withOpacity(0.7), // Dark green on right side
                      Colors.transparent,    // Transparent on left side
                    ],
                  ),
                ),
                child: _isLoading && _wallpapers.isEmpty
                    ? const Center(
                        child: CircularProgressIndicator(
                          color: Colors.white,
                        ),
                      )
                    : _wallpapers.isEmpty
                        ? const Center(
                            child: Text(
                              'No images found',
                              style: TextStyle(
                                fontSize: 18,
                                fontWeight: FontWeight.bold,
                                color: Colors.white,
                              ),
                            ),
                          )
                        : Stack(
                            children: [
                              Column(
                                children: [
                                  Expanded(
                                    child: CardSwiper(
                                      cardsCount: _wallpapers.length,
                                      onSwipe: (previousIndex, currentIndex, direction) {
                                        // Check if we need to load more images
                                        _checkForPagination(currentIndex);
                                        // Handle swipe events if needed
                                        return true;
                                      },
                                      cardBuilder: (
                                        context,
                                        index,
                                        horizontalThresholdPercentage,
                                        verticalThresholdPercentage,
                                      ) {
                                        final wallpaper = _wallpapers[index];
                                        return GestureDetector(
                                          onTap: () {
                                            // Check if the widget is still mounted before navigating
                                            if (mounted) {
                                              Navigator.push(
                                                context,
                                                MaterialPageRoute(
                                                  builder: (context) => WallpaperDetailScreen(
                                                    // Use Pexels image URL structure
                                                    imageUrl: wallpaper['src']['large2x'],
                                                    category: 'wallpapers', // Default category for home screen images
                                                  ),
                                                ),
                                              );
                                            }
                                          },
                                          child: Center(
                                            child: Container(
                                              height: MediaQuery.of(context).size.height * 0.6, // 60% of screen height
                                              width: MediaQuery.of(context).size.width * 0.8, // 80% of screen width
                                              decoration: BoxDecoration(
                                                borderRadius: BorderRadius.circular(16),
                                                boxShadow: [
                                                  BoxShadow(
                                                    color: Colors.black.withOpacity(0.3),
                                                    blurRadius: 10,
                                                    offset: const Offset(0, 5),
                                                  ),
                                                ],
                                              ),
                                              child: ClipRRect(
                                                borderRadius: BorderRadius.circular(16),
                                                child: Image.network(
                                                  // Use Pexels image URL structure
                                                  wallpaper['src']['large2x'],
                                                  fit: BoxFit.contain, // Changed to contain for proper vertical display
                                                  loadingBuilder: (context, child, loadingProgress) {
                                                    // Show a subtle loading indicator only
                                                    if (loadingProgress == null) return child;
                                                    return Container(
                                                      color: Colors.grey[800],
                                                      child: Center(
                                                        child: CircularProgressIndicator(
                                                          value: loadingProgress.expectedTotalBytes != null
                                                              ? loadingProgress.cumulativeBytesLoaded /
                                                                  loadingProgress.expectedTotalBytes!
                                                              : null,
                                                          color: Colors.white38,
                                                          strokeWidth: 2,
                                                        ),
                                                      ),
                                                    );
                                                  },
                                                  errorBuilder: (context, error, stackTrace) {
                                                    return Container(
                                                      color: Colors.grey[800],
                                                      child: const Center(
                                                        child: Icon(
                                                          Icons.error_outline,
                                                          color: Colors.white,
                                                          size: 48,
                                                        ),
                                                      ),
                                                    );
                                                  },
                                                ),
                                              ),
                                            ),
                                          ),
                                        );
                                      },
                                    ),
                                  ),
                                  // Pagination numbers display - showing page/total pages
                                  Container(
                                    padding: const EdgeInsets.symmetric(vertical: 16),
                                    child: Text(
                                      'Page $_displayPage / ${(_totalHits > 0 ? ((_totalHits - 1) ~/ _perPage) + 1 : 1)}',
                                      style: const TextStyle(
                                        color: Colors.white,
                                        fontSize: 16,
                                        fontWeight: FontWeight.bold,
                                      ),
                                    ),
                                  ),
                                ],
                              ),
                              // Show loading indicator overlay when loading more
                              if (_isLoadingMore)
                                Container(
                                  color: Colors.black.withOpacity(0.3),
                                  child: const Center(
                                    child: CircularProgressIndicator(
                                      color: Colors.white,
                                      strokeWidth: 3,
                                    ),
                                  ),
                                ),
                            ],
                          ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}