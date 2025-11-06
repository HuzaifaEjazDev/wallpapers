import 'dart:convert';
import 'dart:typed_data';
import 'package:http/http.dart' as http;

class PixabayService {
  static const String _apiKey = '53072685-0770a12c564f2eb7a535baeb1';
  static const String _baseUrl = 'https://pixabay.com/api/';

  // List of accepted categories
  static final List<String> categories = [
    'backgrounds', 'fashion', 'nature', 'science', 'education', 'feelings',
    'health', 'people', 'religion', 'places', 'animals', 'industry',
    'computer', 'food', 'sports', 'transportation', 'travel', 'buildings',
    'business', 'music'
  ];

  // static final List<String> categories = [
  //   'backgrounds', 'fashion', 'nature', 'science',
  // ];

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

  /// Fetch wallpapers by search query with vertical orientation
  static Future<Map<String, dynamic>> fetchWallpapersBySearch(
      String query, int perPage, int page) async {
    // Use orientation=vertical to get vertical images
    // Remove min_width and min_height to avoid limiting results
    final url = Uri.parse(
        '$_baseUrl?key=$_apiKey&q=$query&image_type=photo&per_page=$perPage&page=$page&safesearch=true&order=relevant&orientation=vertical');

    try {
      final response = await http.get(url);

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        return {
          'hits': List.from(data['hits']),
          'totalHits': data['totalHits'] ?? 0,
        };
      } else {
        throw Exception('Failed to load wallpapers: ${response.statusCode}');
      }
    } catch (error) {
      throw Exception('Failed to load wallpapers: $error');
    }
  }

  /// Fetch wallpapers by category with vertical orientation
  static Future<List<dynamic>> fetchWallpapersByCategory(
      String category, int perPage) async {
    // Use orientation=vertical to get vertical images
    // Remove min_width and min_height to avoid limiting results
    final url = Uri.parse(
        '$_baseUrl?key=$_apiKey&category=$category&image_type=all&per_page=$perPage&safesearch=true&order=popular&orientation=vertical');

    try {
      final response = await http.get(url);

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        return List.from(data['hits']);
      } else {
        throw Exception('Failed to load wallpapers: ${response.statusCode}');
      }
    } catch (error) {
      throw Exception('Failed to load wallpapers: $error');
    }
  }

  /// Fetch wallpapers by category with vertical orientation and return total hits
  static Future<Map<String, dynamic>> fetchWallpapersByCategoryWithPagination(
      String category, int perPage, int page) async {
    // Use orientation=vertical to get vertical images
    // Remove min_width and min_height to avoid limiting results
    final url = Uri.parse(
        '$_baseUrl?key=$_apiKey&category=$category&image_type=all&per_page=$perPage&page=$page&safesearch=true&order=popular&orientation=vertical');

    try {
      final response = await http.get(url);

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        return {
          'hits': List.from(data['hits']),
          'totalHits': data['totalHits'] ?? 0,
        };
      } else {
        throw Exception('Failed to load wallpapers: ${response.statusCode}');
      }
    } catch (error) {
      throw Exception('Failed to load wallpapers: $error');
    }
  }
}