import 'package:flutter/material.dart';
import 'package:flutter_card_swiper/flutter_card_swiper.dart';
import 'package:wallpapers/models/wallpaper.dart';
import 'package:wallpapers/services/pixabay_service.dart';

class WallpapersScreen extends StatefulWidget {
  const WallpapersScreen({super.key});

  @override
  State<WallpapersScreen> createState() => _WallpapersScreenState();
}

class _WallpapersScreenState extends State<WallpapersScreen> {
  late PixabayService _pixabayService;
  List<Wallpaper> _wallpapers = [];
  bool _isLoading = true;
  String _searchQuery = 'wallpapers';
  final TextEditingController _searchController = TextEditingController();

  @override
  void initState() {
    super.initState();
    _pixabayService = PixabayService();
    _searchController.text = ''; // Empty text when app starts
    _searchQuery = 'wallpapers'; // Default query for initial search
    _loadWallpapers();
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  Future<void> _loadWallpapers() async {
    setState(() {
      _isLoading = true;
    });

    try {
      final wallpapers = await _pixabayService.searchWallpapers(_searchQuery);
      setState(() {
        _wallpapers = wallpapers;
        _isLoading = false;
      });
    } catch (error) {
      setState(() {
        _isLoading = false;
      });
      // Show error message
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Failed to load wallpapers: $error')),
      );
    }
  }

  Future<void> _performSearch() async {
    setState(() {
      // Combine user input with "wallpapers" for more targeted search
      final userInput = _searchController.text.trim();
      _searchQuery = userInput.isEmpty
          ? 'wallpapers'
          : '$userInput wallpapers';
    });
    _loadWallpapers();
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
              Colors.grey.shade900, // Dark grey for bottom half
            ],
          ),
        ),
        child: Column(
          children: [
            // Top row with back icon and filter sort icon
            Container(
              padding: const EdgeInsets.only(top: 50, left: 16, right: 16, bottom: 8), // Reduced bottom padding
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
              margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 4), // Reduced vertical margin
              decoration: BoxDecoration(
                color: Colors.white.withOpacity(0.2),
                borderRadius: BorderRadius.circular(30),
              ),
              child: TextField(
                controller: _searchController,
                style: const TextStyle(color: Colors.white),
                decoration: const InputDecoration(
                  hintText: 'search for wallpaper',
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
                      Colors.transparent, // Transparent on left side
                    ],
                  ),
                ),
                child: _isLoading
                    ? const Center(
                        child: CircularProgressIndicator(
                          color: Colors.white,
                        ),
                      )
                    : _wallpapers.isEmpty
                        ? const Center(
                            child: Text(
                              'No wallpapers found',
                              style: TextStyle(
                                fontSize: 18,
                                fontWeight: FontWeight.bold,
                                color: Colors.white,
                              ),
                            ),
                          )
                        : CardSwiper(
                            cardsCount: _wallpapers.length,
                            onSwipe: (previousIndex, currentIndex, direction) {
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
                                  height: MediaQuery.of(context).size.height * 0.6, // Reduced height
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
                                      wallpaper.imageUrl,
                                      fit: BoxFit.cover,
                                      loadingBuilder: (context, child, loadingProgress) {
                                        if (loadingProgress == null) return child;
                                        return Center(
                                          child: CircularProgressIndicator(
                                            value: loadingProgress.expectedTotalBytes != null
                                                ? loadingProgress.cumulativeBytesLoaded /
                                                    loadingProgress.expectedTotalBytes!
                                                : null,
                                            color: Colors.white,
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
            ),
          ],
        ),
      ),
    );
  }
}