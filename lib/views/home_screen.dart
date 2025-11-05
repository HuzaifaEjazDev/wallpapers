import 'package:flutter/material.dart';
import 'package:flutter_card_swiper/flutter_card_swiper.dart';
// ignore: depend_on_referenced_packages
import 'package:http/http.dart' as http;
import 'dart:convert';

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

  Future<void> _loadWallpapers({bool loadMore = false}) async {
    if (loadMore && (_isLoading || _isLoadingMore || !_hasMoreData)) return;

    setState(() {
      if (loadMore) {
        _isLoadingMore = true;
      } else {
        _isLoading = true;
        _currentPage = 1; // Reset to first page for new searches
        _displayPage = 1; // Reset display page as well
        _wallpapers = [];
        _hasMoreData = true;
        _totalHits = 0;
      }
    });

    try {
      // Add double quotes around the query
      final quotedQuery = '"$_searchQuery"';
      final encodedQuery = Uri.encodeQueryComponent(quotedQuery);
      final url = Uri.parse(
          'https://pixabay.com/api/?key=53072685-0770a12c564f2eb7a535baeb1&q="$encodedQuery"&image_type=photo&category=backgrounds&per_page=$_perPage&page=$_currentPage&safesearch=true&order=relevant&min_width=1024&min_height=768&lang=en');

      final response = await http.get(url);

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        final List hits = data['hits'];
        final int totalHits = data['totalHits'] ?? 0;
        
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
      } else {
        setState(() {
          if (loadMore) {
            _isLoadingMore = false;
          } else {
            _isLoading = false;
          }
        });
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Failed to load wallpapers: ${response.statusCode}')),
        );
      }
    } catch (error) {
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

  Future<void> _performSearch() async {
    setState(() {
      final userInput = _searchController.text.trim();
      // Use only the user input for search (no default prompt added)
      _searchQuery = userInput.isEmpty ? 'wallpapers' : userInput;
    });
    _loadWallpapers();
  }

  void _checkForPagination(int? currentIndex) {
    // Update current index for pagination display
    if (currentIndex != null) {
      setState(() {
        _currentIndex = currentIndex;
      });
      
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
                  IconButton(
                    icon: const Icon(Icons.arrow_back_ios, color: Colors.white),
                    onPressed: () {
                      // Back functionality
                      Navigator.maybePop(context);
                    },
                  ),
                  // Filter sort icon at trailing position
                  IconButton(
                    icon: const Icon(Icons.sort, color: Colors.white),
                    onPressed: () {
                      // Filter functionality
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
                                        return Center(
                                          child: Container(
                                            height: MediaQuery.of(context).size.height * 0.6,
                                            width: MediaQuery.of(context).size.width * 0.8,
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
                                                wallpaper['largeImageURL'],
                                                fit: BoxFit.cover,
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