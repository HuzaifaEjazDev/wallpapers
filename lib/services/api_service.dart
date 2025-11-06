import 'dart:convert';
import 'package:http/http.dart' as http;

/// Service class for handling API communications with Printful
/// Provides methods for products, categories, variants, and mockup generation
class ApiService {
  static const String baseUrl = 'https://api.printful.com';
  static const String bearerToken = 'IlGdogEDCu9p7Z4EKRtjpXhzWFRedViJqKQaWdSR';

  /// Gets default headers for API requests
  static Map<String, String> get headers => {
    'Content-Type': 'application/json',
    'Authorization': 'Bearer $bearerToken',
  };

  /// Gets headers for mockup API requests
  static Map<String, String> get mockupHeaders => {
    'Content-Type': 'application/json',
    'Authorization': 'Bearer $bearerToken',
  };

  /// Fetches products from the catalog with optional filtering
  static Future<Map<String, dynamic>> getProducts({
    int? limit,
    int? offset,
    String? search,
    int? categoryId,
  }) async {
    final uri = Uri.parse('$baseUrl/products').replace(
      queryParameters: {
        if (limit != null) 'limit': limit.toString(),
        if (offset != null) 'offset': offset.toString(),
        if (search != null) 'search': search,
        if (categoryId != null) 'category_id': categoryId.toString(),
      },
    );

    final response = await http.get(uri, headers: headers);

    if (response.statusCode == 200) {
      return json.decode(response.body);
    } else {
      throw Exception('Failed to load products: ${response.statusCode}');
    }
  }

  /// Fetches available product categories
  static Future<Map<String, dynamic>> getCategories() async {
    final response = await http.get(
      Uri.parse('$baseUrl/categories'),
      headers: headers,
    );

    if (response.statusCode == 200) {
      return json.decode(response.body);
    } else {
      throw Exception('Failed to load categories: ${response.statusCode}');
    }
  }

  /// Gets a specific product by ID
  static Future<Map<String, dynamic>> getProductById(int id) async {
    final response = await http.get(
      Uri.parse('$baseUrl/products/$id'),
      headers: headers,
    );

    if (response.statusCode == 200) {
      return json.decode(response.body);
    } else {
      throw Exception('Failed to load product: ${response.statusCode}');
    }
  }

  /// Fetches store products with optional pagination
  static Future<Map<String, dynamic>> getStoreProducts({
    int? limit,
    int? offset,
  }) async {
    final uri = Uri.parse('$baseUrl/store/products').replace(
      queryParameters: {
        if (limit != null) 'limit': limit.toString(),
        if (offset != null) 'offset': offset.toString(),
      },
    );

    final response = await http.get(uri, headers: headers);

    if (response.statusCode == 200) {
      return json.decode(response.body);
    } else {
      throw Exception('Failed to load store products: ${response.statusCode}');
    }
  }

  /// Gets a specific store product by ID
  static Future<Map<String, dynamic>> getStoreProductById(int id) async {
    final response = await http.get(
      Uri.parse('$baseUrl/store/products/$id'),
      headers: headers,
    );

    if (response.statusCode == 200) {
      return json.decode(response.body);
    } else {
      throw Exception('Failed to load store product: ${response.statusCode}');
    }
  }

  /// Gets product variants from store
  static Future<Map<String, dynamic>> getProductVariants(int productId) async {
    final response = await http.get(
      Uri.parse('$baseUrl/store/products/$productId/variants'),
      headers: headers,
    );

    if (response.statusCode == 200) {
      return json.decode(response.body);
    } else {
      throw Exception(
        'Failed to load product variants: ${response.statusCode}',
      );
    }
  }

  /// Gets catalog product variants
  static Future<Map<String, dynamic>> getCatalogProductVariants(
      int productId,
      ) async {
    final response = await http.get(
      Uri.parse('$baseUrl/products/$productId'),
      headers: headers,
    );

    if (response.statusCode == 200) {
      return json.decode(response.body);
    } else {
      throw Exception(
        'Failed to load catalog product variants: ${response.statusCode}',
      );
    }
  }

  /// Gets a specific variant by ID
  static Future<Map<String, dynamic>> getVariantById(int id) async {
    final response = await http.get(
      Uri.parse('$baseUrl/store/variants/$id'),
      headers: headers,
    );

    if (response.statusCode == 200) {
      return json.decode(response.body);
    } else {
      throw Exception('Failed to load variant: ${response.statusCode}');
    }
  }

  /// Gets product variant printfiles for mockup generation
  static Future<Map<String, dynamic>> getProductVariantPrintfiles(
      int productId, {
        String? orientation,
        String? technique,
        String? storeId,
      }) async {
    final uri = Uri.parse('$baseUrl/mockup-generator/printfiles/$productId')
        .replace(
      queryParameters: {
        if (orientation != null) 'orientation': orientation,
        if (technique != null) 'technique': technique,
      },
    );

    final headersWithStore = Map<String, String>.from(headers);
    if (storeId != null) {
      headersWithStore['X-PF-Store-Id'] = storeId;
    }

    final response = await http.get(uri, headers: headersWithStore);

    if (response.statusCode == 200) {
      return json.decode(response.body);
    } else {
      throw Exception(
        'Failed to load product variant printfiles: ${response.statusCode}',
      );
    }
  }

  /// Gets layout templates for a variant
  static Future<Map<String, dynamic>> getLayoutTemplates(int variantId) async {
    final response = await http.get(
      Uri.parse('$baseUrl/mockup-generator/templates/$variantId'),
      headers: headers,
    );

    if (response.statusCode == 200) {
      return json.decode(response.body);
    } else {
      throw Exception('Failed to load templates: ${response.statusCode}');
    }
  }

  /// Fetches mockup styles for a catalog product (V2 API)
  static Future<Map<String, dynamic>> fetchMockupStyles(int productId) async {
    final response = await http.get(
      Uri.parse('$baseUrl/v2/catalog-products/$productId/mockup-styles'),
      headers: headers,
    );

    if (response.statusCode == 200) {
      return json.decode(response.body);
    } else {
      throw Exception('Failed to load mockup styles: ${response.statusCode}');
    }
  }

  /// Creates a mockup generation task using V2 API
  static Future<Map<String, dynamic>> createMockupTaskV2({
    required int productId,
    required List<int> variantIds,
    required List<int> mockupStyleIds,
    String format = 'png',
    int? mockupWidthPx,
    String orientation = 'vertical',
    List<Map<String, dynamic>>? placements,
    Map<String, dynamic>? productOptions,
  }) async {
    final body = json.encode({
      'format': format,
      if (mockupWidthPx != null) 'mockup_width_px': mockupWidthPx,
      'products': [
        {
          'source': 'catalog',
          'mockup_style_ids': mockupStyleIds,
          'catalog_product_id': productId,
          'catalog_variant_ids': variantIds,
          'orientation': orientation,
          if (placements != null) 'placements': placements,
          if (productOptions != null) 'product_options': productOptions,
        },
      ],
    });

    final response = await http.post(
      Uri.parse('$baseUrl/v2/mockup-tasks'),
      headers: headers,
      body: body,
    );

    if (response.statusCode == 200) {
      return json.decode(response.body);
    } else {
      throw Exception(
        'Failed to create V2 mockup task: ${response.statusCode}',
      );
    }
  }

  /// Creates a mockup generation task using V1 API with enhanced placement handling
  static Future<Map<String, dynamic>> createMockupTaskV1({
    required int productId,
    required int variantId,
    required String format,
    required int width,
    required String imageUrl,
    required String placementStyle,
    required String placement,
    int? printfileWidth,
    int? printfileHeight,
    Map<String, dynamic>? productOptions,
  }) async {
    print('Placement Style: $placement');
    // Calculate positioning based on placement style
    final position = _calculatePosition(
      placementStyle: placementStyle,
      imageWidth: width,
      printfileWidth: printfileWidth ?? 1800,
      printfileHeight: printfileHeight ?? 2400,
    );

    final body = json.encode({
      'variant_ids': [variantId],
      'format': format,
      'width': width,
      if (productOptions != null) 'product_options': productOptions,
      'files': [
        {
          'placement': placement,
          'image_url': imageUrl, // Use the dynamic imageUrl parameter instead of hardcoded URL
          'position': position,
        },
      ],
    });

    print(body);

    final response = await http.post(
      Uri.parse('$baseUrl/mockup-generator/create-task/$productId'),
      headers: headers,
      body: body,
    );

    print(response.body);

    if (response.statusCode == 200) {
      return json.decode(response.body);
    } else {
      // Handle rate limiting - stop trying and inform user
      if (response.statusCode == 429) {
        final errorData = json.decode(response.body);
        final message = errorData['result']?.toString() ?? '';

        // Extract wait time from message like "Please try again after 54 seconds"
        final waitMatch = RegExp(r'(\d+)\s+seconds').firstMatch(message);
        if (waitMatch != null) {
          final waitSeconds = int.parse(waitMatch.group(1)!);
          throw Exception(
            'API rate limit exceeded. Please try again in ${waitSeconds} seconds. This is a temporary limitation from the mockup service.',
          );
        } else {
          throw Exception(
            'API rate limit exceeded. Please try again in a few minutes. This is a temporary limitation from the mockup service.',
          );
        }
      }

      // Add small delay for other errors to avoid rate limiting
      await Future.delayed(Duration(milliseconds: 1000));

      throw Exception(
        'Failed to create V1 mockup task: ${response.statusCode}',
      );
    }
  }

  /// Checks the status of a mockup generation task
  static Future<Map<String, dynamic>> checkMockupTaskStatusV1(
      String taskKey,
      ) async {
    final response = await http.get(
      Uri.parse('$baseUrl/mockup-generator/task?task_key=$taskKey'),
      headers: headers,
    );

    if (response.statusCode == 200) {
      return json.decode(response.body);
    } else {
      throw Exception(
        'Failed to check mockup task status: ${response.statusCode}',
      );
    }
  }

  /// Calculates positioning for mockup placement based on style
  static Map<String, dynamic> _calculatePosition({
    required String placementStyle,
    required int imageWidth,
    required int printfileWidth,
    required int printfileHeight,
  }) {
    switch (placementStyle) {
      case 'fit':
      // Fit the image within the print area while maintaining aspect ratio
        final aspectRatio = imageWidth / printfileHeight;
        final fittedWidth = printfileWidth;
        final fittedHeight = (printfileWidth / aspectRatio).round();
        return {
          'area_width': printfileWidth,
          'area_height': printfileHeight,
          'width': fittedWidth,
          'height': fittedHeight,
          'top': ((printfileHeight - fittedHeight) / 2).round(),
          'left': 0,
        };

      case 'fill':
      // Fill the entire print area
        return {
          'area_width': printfileWidth,
          'area_height': printfileHeight,
          'width': printfileWidth,
          'height': printfileHeight,
          'top': 0,
          'left': 0,
        };

      case 'sticker':
      // Center the image as a sticker
        final stickerSize = (printfileWidth * 0.8).round();
        return {
          'area_width': printfileWidth,
          'area_height': printfileHeight,
          'width': stickerSize,
          'height': stickerSize,
          'top': ((printfileHeight - stickerSize) / 2).round(),
          'left': ((printfileWidth - stickerSize) / 2).round(),
        };

      case 'reset':
      default:
      // Default positioning
        return {
          'area_width': printfileWidth,
          'area_height': printfileHeight,
          'width': imageWidth,
          'height': (imageWidth * printfileHeight / printfileWidth).round(),
          'top': 0,
          'left': 0,
        };
    }
  }
}
