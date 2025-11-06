import 'package:flutter/foundation.dart';

import '../services/api_service.dart';

class MockupProvider with ChangeNotifier {
  bool _isLoading = false;
  String? _error;
  String? _taskKey;
  Map<String, dynamic>? _mockupResult;

  bool get isLoading => _isLoading;
  String? get error => _error;
  String? get taskKey => _taskKey;
  Map<String, dynamic>? get mockupResult => _mockupResult;

  /// Fetches mockup task result and updates provider state
  Future<void> getMockupTaskResult(String taskKey) async {
    _setLoading(true);
    _error = null;

    try {
      await checkMockupTaskStatusV1(taskKey);
      notifyListeners();
    } catch (e) {
      _error = e.toString();
      notifyListeners();
    } finally {
      _setLoading(false);
    }
  }

  /// Retrieves product printfiles for mockup generation
  Future<Map<String, dynamic>> getProductPrintfiles(int productId) async {
    try {
      return await ApiService.getProductVariantPrintfiles(productId);
    } catch (e) {
      _error = e.toString();
      notifyListeners();
      rethrow;
    }
  }

  Map<String, dynamic>? _mockupStyles;

  Map<String, dynamic>? get mockupStyles => _mockupStyles;

  /// Fetches available mockup styles for a product
  Future<void> fetchMockupStyles(int productId) async {
    _setLoading(true);
    _error = null;

    try {
      final response = await ApiService.fetchMockupStyles(productId);
      _mockupStyles = response['result'];
      notifyListeners();
    } catch (e) {
      _error = e.toString();
      notifyListeners();
    } finally {
      _setLoading(false);
    }
  }

  /// Creates a mockup generation task using V2 API
  Future<void> createMockupTaskV2({
    required int productId,
    required List<int> variantIds,
    required List<int> mockupStyleIds,
    String format = 'png',
    int? mockupWidthPx,
    String orientation = 'vertical',
    List<Map<String, dynamic>>? placements,
    Map<String, dynamic>? productOptions,
  }) async {
    _setLoading(true);
    _error = null;

    try {
      final response = await ApiService.createMockupTaskV2(
        productId: productId,
        variantIds: variantIds,
        mockupStyleIds: mockupStyleIds,
        format: format,
        mockupWidthPx: mockupWidthPx,
        orientation: orientation,
        placements: placements,
        productOptions: productOptions,
      );
      _taskKey = response['result']['task_key'];
      notifyListeners();
    } catch (e) {
      _error = e.toString();
      notifyListeners();
    } finally {
      _setLoading(false);
    }
  }

  /// Creates a mockup generation task using V1 API with enhanced error handling
  Future<void> createMockupTaskV1({
    required int productId,
    required int variantId,
    required String format,
    required int width,
    required String imageUrl,
    required String placementStyle,
    int? printfileWidth,
    int? printfileHeight,
    Map<String, dynamic>? productOptions,
  }) async {
    _setLoading(true);
    _error = null;

    try {
      final response = await ApiService.createMockupTaskV1(
        productId: productId,
        variantId: variantId,
        format: format,
        width: width,
        imageUrl: imageUrl,
        placementStyle: placementStyle,
        printfileWidth: printfileWidth,
        printfileHeight: printfileHeight,
        productOptions: productOptions,
      );
      _taskKey = response['result']['task_key'];
      notifyListeners();
    } catch (e) {
      _error = e.toString();

      // Provide more specific error handling for common issues
      if (e.toString().contains('No printfiles available')) {
        _error =
            'This product variant does not support mockup generation. Please try a different variant.';
      } else if (e.toString().contains(
        'does not exist or is not available for mockup generation',
      )) {
        _error =
            'This product variant is not available for mockup generation. Please select a different product.';
      } else if (e.toString().contains(
        'Failed to create V1 mockup task: 400',
      )) {
        _error =
            'Invalid mockup configuration. Please check your design and try again.';
      } else if (e.toString().contains('Failed to load printfiles: 400')) {
        _error =
            'This variant cannot be used for mockup generation. Please try another product.';
      } else if (e.toString().contains('API rate limit exceeded')) {
        _error = e.toString(); // Use the detailed rate limit message
      }

      notifyListeners();
    } finally {
      _setLoading(false);
    }
  }

  /// Gets available placement options for a product variant
  Future<List<String>> getAvailablePlacements(
    int productId,
    int variantId,
  ) async {
    try {
      final printfilesResponse = await ApiService.getProductVariantPrintfiles(
        productId,
      );
      final result = printfilesResponse['result'] as Map<String, dynamic>;

      // Extract placements from variant_printfiles
      final variantPrintfiles = result['variant_printfiles'] as List? ?? [];
      List<String> placements = [];

      if (variantPrintfiles.isNotEmpty) {
        // Find the specific variant or use the first one
        final targetVariant =
            variantPrintfiles.firstWhere(
                  (vp) => vp['variant_id'] == variantId,
                  orElse: () => variantPrintfiles.first,
                )
                as Map<String, dynamic>;

        final placementsMap =
            targetVariant['placements'] as Map<String, dynamic>?;
        if (placementsMap != null) {
          placements = placementsMap.keys.toList();
        }
      }

      // Fallback to available_placements if variant_printfiles doesn't work
      if (placements.isEmpty) {
        final availablePlacements =
            result['available_placements'] as Map<String, dynamic>?;
        if (availablePlacements != null) {
          placements = availablePlacements.keys.toList();
        }
      }

      return placements;
    } catch (e) {
      return [];
    }
  }

  /// Checks the status of a mockup generation task
  Future<String?> checkMockupTaskStatusV1(String taskKey) async {
    try {
      final response = await ApiService.checkMockupTaskStatusV1(taskKey);
      final result = response['result'];
      final status = result['status'];

      if (status == 'completed') {
        _mockupResult = result;
      } else if (status == 'failed') {
        _error = result['error'] ?? 'Mockup generation failed';
      }

      notifyListeners();
      return status;
    } catch (e) {
      _error = e.toString();
      notifyListeners();
      return null;
    }
  }

  /// Clears any existing error state
  void clearError() {
    _error = null;
    notifyListeners();
  }

  /// Clears mockup result and related data
  void clearMockupResult() {
    _mockupResult = null;
    _taskKey = null;
    _mockupStyles = null;
    notifyListeners();
  }

  /// Updates mockup task result and notifies listeners
  void updateMockupResult(Map<String, dynamic> result) {
    _mockupResult = result;
    notifyListeners();
  }

  /// Sets loading state and notifies listeners
  void _setLoading(bool loading) {
    _isLoading = loading;
    notifyListeners();
  }
}
