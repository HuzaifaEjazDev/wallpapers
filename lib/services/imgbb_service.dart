import 'dart:convert';
import 'dart:io';
import 'package:http/http.dart' as http;

class ImgBBService {
  static const String apiKey = 'c48054475b73e25bd38da2a2fc436e56';
  static const String baseUrl = 'https://api.imgbb.com/1/upload';

  /// Uploads an image file to ImgBB and returns the URL of the uploaded image
  static Future<String> uploadImage(File imageFile) async {
    try {
      final uri = Uri.parse('$baseUrl?key=$apiKey');
      
      final request = http.MultipartRequest('POST', uri);
      final multipartFile = await http.MultipartFile.fromPath(
        'image',
        imageFile.path,
      );
      
      request.files.add(multipartFile);
      
      final response = await request.send();
      final responseBody = await response.stream.bytesToString();
      
      if (response.statusCode == 200) {
        final Map<String, dynamic> data = json.decode(responseBody);
        if (data['success'] == true) {
          return data['data']['url'] as String;
        } else {
          throw Exception('ImgBB upload failed: ${data['error']['message']}');
        }
      } else {
        throw Exception('ImgBB upload failed with status: ${response.statusCode}');
      }
    } catch (e) {
      throw Exception('Failed to upload image to ImgBB: $e');
    }
  }
}