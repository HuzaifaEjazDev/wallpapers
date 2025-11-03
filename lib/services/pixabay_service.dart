import 'dart:convert';
import 'package:http/http.dart' as http;
import '../models/wallpaper.dart';

class PixabayService {
  static const String _baseUrl = 'https://pixabay.com/api/';
  final String _apiKey = '53072685-0770a12c564f2eb7a535baeb1'; // Your API key

  Future<List<Wallpaper>> searchWallpapers(String query) async {
    // Encode the query to handle special characters
    final encodedQuery = Uri.encodeQueryComponent(query);
    // Optimize for exact matching with specific parameters
    final url = Uri.parse(
        '$_baseUrl?&key=$_apiKey&q=$encodedQuery&image_type=photo&category=backgrounds&per_page=50&safesearch=true&order=relevant&min_width=1024&min_height=768&lang=en');

    try {
      final response = await http.get(url);

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        final List hits = data['hits'];
        
        // For exact matching, we want the most relevant results first
        // Return all results without additional filtering to preserve exact matches
        return hits.map((e) => Wallpaper.fromJson(e)).toList();
      } else {
        throw Exception('Failed to load wallpapers: ${response.statusCode}');
      }
    } catch (error) {
      throw Exception('Failed to load wallpapers: $error');
    }
  }
}