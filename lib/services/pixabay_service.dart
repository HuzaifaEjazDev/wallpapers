import 'dart:convert';
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

  /// Get random 5 categories from the accepted categories list
  static List<String> getRandomCategories() {
    final List<String> shuffled = List.from(categories)..shuffle();
    return shuffled.take(5).toList();
  }

  /// Fetch wallpapers by category
  static Future<List<dynamic>> fetchWallpapersByCategory(
      String category, int perPage) async {
    final url = Uri.parse(
        '$_baseUrl?key=$_apiKey&category=$category&image_type=photo&per_page=$perPage&safesearch=true&order=popular&min_width=1024&min_height=768&lang=en');

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
}