import 'dart:convert';
import 'package:http/http.dart' as http;

class PexelsService {
  static const String _apiKey = 'RuNc8QzME0FOw0YA6Xfd7FSbsRwKGgLlakDm3hJqK04JksKHychkYoDL';
  static const String _baseUrl = 'https://api.pexels.com/v1/';
  
  // Pexels API limits
  static const int MAX_PER_PAGE = 80;
  static const int MAX_TOTAL_RESULTS = 500;
  
  // Define a list of categories
  static final List<String> categories = [
    'backgrounds', 'fashion', 'nature', 'science', 'education', 'feelings',
    'health', 'people', 'religion', 'places', 'animals', 'industry',
    'computer', 'food', 'sports', 'transportation', 'travel', 'buildings',
    'business', 'music'
  ];

  // Cache for category wallpapers
  static Map<String, List<dynamic>> _categoryCache = {};
  static List<String> _cachedCategories = [];
  static bool _isPreloading = false;

  /// Get random 5 categories from the accepted categories list
  static List<String> getRandomCategories() {
    final List<String> shuffled = List.from(categories)..shuffle();
    return shuffled.take(5).toList();
  }

  /// Preload category data in the background
  static Future<void> preloadCategories() async {
    if (_isPreloading) return;
    
    _isPreloading = true;
    try {
      // Get random 5 categories
      _cachedCategories = getRandomCategories();
      
      // Clear previous cache
      _categoryCache = {};
      
      // Fetch 5 wallpapers for each category
      for (String category in _cachedCategories) {
        final wallpapers = await fetchWallpapersByCategory(category, 5);
        _categoryCache[category] = wallpapers;
      }
    } catch (error) {
      // If preloading fails, we'll fall back to on-demand loading
      print('Preloading failed: $error');
    } finally {
      _isPreloading = false;
    }
  }

  /// Get cached categories
  static List<String> getCachedCategories() {
    return _cachedCategories;
  }

  /// Get cached wallpapers for a category
  static List<dynamic>? getCachedWallpapers(String category) {
    return _categoryCache[category];
  }

  /// Check if data is cached
  static bool isDataCached() {
    return _cachedCategories.isNotEmpty && _categoryCache.isNotEmpty;
  }

  /// Update cache with new data
  static void updateCache(List<String> categories, Map<String, List<dynamic>> wallpapers) {
    _cachedCategories = categories;
    _categoryCache = wallpapers;
  }

  /// Fetch wallpapers by search query from Pexels with vertical orientation
  /// perPage is limited to 80 by Pexels API
  static Future<Map<String, dynamic>> fetchWallpapersBySearch(
      String query, int perPage, int page) async {
    // Ensure perPage doesn't exceed Pexels limit
    final int safePerPage = perPage > MAX_PER_PAGE ? MAX_PER_PAGE : perPage;
    // Ensure we don't request pages beyond the API limit
    final int safePage = (page - 1) * safePerPage < MAX_TOTAL_RESULTS ? page : 
                        (MAX_TOTAL_RESULTS ~/ safePerPage) + 1;
    
    final url = Uri.parse(
        '${_baseUrl}search?query=$query&per_page=$safePerPage&page=$safePage&orientation=portrait');

    try {
      final response = await http.get(
        url,
        headers: {
          'Authorization': _apiKey,
        },
      );

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        return {
          'hits': List.from(data['photos']),
          'totalHits': data['total_results'] > MAX_TOTAL_RESULTS ? MAX_TOTAL_RESULTS : data['total_results'],
        };
      } else {
        throw Exception('Failed to load wallpapers: ${response.statusCode}');
      }
    } catch (error) {
      throw Exception('Failed to load wallpapers: $error');
    }
  }

  /// Fetch wallpapers by category from Pexels with vertical orientation
  /// perPage is limited to 80 by Pexels API
  static Future<List<dynamic>> fetchWallpapersByCategory(
      String category, int perPage) async {
    // Ensure perPage doesn't exceed Pexels limit
    final int safePerPage = perPage > MAX_PER_PAGE ? MAX_PER_PAGE : perPage;
    
    final url = Uri.parse(
        '${_baseUrl}search?query=$category&per_page=$safePerPage&orientation=portrait');

    try {
      final response = await http.get(
        url,
        headers: {
          'Authorization': _apiKey,
        },
      );

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        return List.from(data['photos']);
      } else {
        throw Exception('Failed to load wallpapers: ${response.statusCode}');
      }
    } catch (error) {
      throw Exception('Failed to load wallpapers: $error');
    }
  }

  /// Fetch wallpapers by category with pagination from Pexels with vertical orientation
  /// perPage is limited to 80 by Pexels API
  static Future<Map<String, dynamic>> fetchWallpapersByCategoryWithPagination(
      String category, int perPage, int page) async {
    // Ensure perPage doesn't exceed Pexels limit
    final int safePerPage = perPage > MAX_PER_PAGE ? MAX_PER_PAGE : perPage;
    // Ensure we don't request pages beyond the API limit
    final int safePage = (page - 1) * safePerPage < MAX_TOTAL_RESULTS ? page : 
                        (MAX_TOTAL_RESULTS ~/ safePerPage) + 1;
    
    final url = Uri.parse(
        '${_baseUrl}search?query=$category&per_page=$safePerPage&page=$safePage&orientation=portrait');

    try {
      final response = await http.get(
        url,
        headers: {
          'Authorization': _apiKey,
        },
      );

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        return {
          'hits': List.from(data['photos']),
          'totalHits': data['total_results'] > MAX_TOTAL_RESULTS ? MAX_TOTAL_RESULTS : data['total_results'],
        };
      } else {
        throw Exception('Failed to load wallpapers: ${response.statusCode}');
      }
    } catch (error) {
      throw Exception('Failed to load wallpapers: $error');
    }
  }
}