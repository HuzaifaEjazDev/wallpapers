import 'dart:async';
import 'pexels_service.dart';

class HomeScreenService {
  // Cache for home screen wallpapers
  static List<dynamic> _cachedWallpapers = [];
  static String _cachedQuery = 'wallpapers';
  static int _cachedTotalHits = 0;
  static bool _isDataCached = false;
  
  /// Check if data is cached
  static bool isDataCached() {
    return _isDataCached && _cachedWallpapers.isNotEmpty;
  }
  
  /// Get cached wallpapers
  static List<dynamic> getCachedWallpapers() {
    return _cachedWallpapers;
  }
  
  /// Get cached query
  static String getCachedQuery() {
    return _cachedQuery;
  }
  
  /// Get cached total hits
  static int getCachedTotalHits() {
    return _cachedTotalHits;
  }
  
  /// Update cache with new data
  static void updateCache(List<dynamic> wallpapers, String query, int totalHits) {
    _cachedWallpapers = wallpapers;
    _cachedQuery = query;
    _cachedTotalHits = totalHits;
    _isDataCached = true;
  }
  
  /// Preload home screen data
  static Future<void> preloadHomeScreenData() async {
    try {
      // Use only the Pexels service to fetch wallpapers
      final result = await PexelsService.fetchWallpapersBySearch(
          '"wallpapers"', 20, 1);
      
      final List hits = result['hits'];
      final int totalHits = result['totalHits'] ?? 0;
      
      // Update cache with preloaded data
      updateCache(hits, 'wallpapers', totalHits);
    } catch (error) {
      // If preloading fails, we'll fall back to on-demand loading
      print('Home screen preloading failed: $error');
    }
  }
}