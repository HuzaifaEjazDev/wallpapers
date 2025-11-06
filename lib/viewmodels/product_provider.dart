import 'package:flutter/foundation.dart';

import '../models/mockup/category_model.dart';
import '../models/mockup/printfile_model.dart';
import '../models/mockup/product_model.dart';
import '../services/api_service.dart';

class ProductProvider with ChangeNotifier {
  List<Product> _products = [];
  List<SyncProduct> _storeProducts = [];
  List<CategoryModel> _categories = [];
  bool _isLoading = false;
  String? _error;
  String _searchQuery = '';
  CategoryModel? _selectedCategory;

  List<Product> get products => _products;
  List<SyncProduct> get storeProducts => _storeProducts;
  List<CategoryModel> get categories => _categories;
  bool get isLoading => _isLoading;
  String? get error => _error;
  String get searchQuery => _searchQuery;
  CategoryModel? get selectedCategory => _selectedCategory;

  /// Fetches products from API with optional search and category filtering
  Future<void> fetchProducts({String? search}) async {
    _setLoading(true);
    _error = null;

    try {
      final response = await ApiService.getProducts(
        search: search,
        categoryId: _selectedCategory?.id,
      );

      List<dynamic> productList = [];

      // Handle different response formats
      if (response['result'] == null) {
        throw Exception('API response missing result field');
      } else if (response['result'] is List) {
        // Direct list format
        productList = response['result'] as List<dynamic>;
      } else if (response['result'] is Map) {
        final resultMap = response['result'] as Map<String, dynamic>;

        // Try different possible field names
        if (resultMap['products'] is List) {
          productList = resultMap['products'] as List<dynamic>;
        } else if (resultMap['data'] is List) {
          productList = resultMap['data'] as List<dynamic>;
        } else if (resultMap['items'] is List) {
          productList = resultMap['items'] as List<dynamic>;
        } else {
          // If no list found, try to find any list value in the map
          for (final value in resultMap.values) {
            if (value is List) {
              productList = value;
              break;
            }
          }
          if (productList.isEmpty) {
            throw Exception(
              'No product list found in API response. Available keys: ${resultMap.keys.toList()}',
            );
          }
        }
      } else {
        throw Exception(
          'Unexpected response format: result is ${response['result'].runtimeType}',
        );
      }

      // Parse products safely
      _products = [];
      for (int i = 0; i < productList.length; i++) {
        try {
          final json = productList[i];
          if (json is Map<String, dynamic>) {
            _products.add(Product.fromJson(json));
          }
        } catch (e) {
          // Continue with other products instead of failing completely
        }
      }

      notifyListeners();
    } catch (e) {
      _error = e.toString();
      notifyListeners();
    } finally {
      _setLoading(false);
    }
  }

  /// Fetches store products from API
  Future<void> fetchStoreProducts() async {
    _setLoading(true);
    _error = null;

    try {
      final response = await ApiService.getStoreProducts();
      if (response['result'] is List) {
        final productList = (response['result'] as List)
            .map((json) => SyncProduct.fromJson(json))
            .toList();
        _storeProducts = productList;
      } else {
        throw Exception('Unexpected response format: result is not a list');
      }
      notifyListeners();
    } catch (e) {
      _error = e.toString();
      notifyListeners();
    } finally {
      _setLoading(false);
    }
  }

  /// Fetches product categories from API
  Future<void> fetchCategories() async {
    _setLoading(true);
    _error = null;

    try {
      final response = await ApiService.getCategories();
      if (response['result'] is Map &&
          response['result']['categories'] is List) {
        final categoryList = (response['result']['categories'] as List).map((
          json,
        ) {
          try {
            return CategoryModel.fromJson(json as Map<String, dynamic>);
          } catch (e) {
            rethrow;
          }
        }).toList();
        _categories = categoryList;
      } else {
        throw Exception(
          'Unexpected response format: result.categories is not a list',
        );
      }
      notifyListeners();
    } catch (e) {
      _error = e.toString();
      notifyListeners();
    } finally {
      _setLoading(false);
    }
  }

  /// Fetches products by category with optional search
  Future<void> fetchProductsByCategory(int categoryId, {String? search}) async {
    _setLoading(true);
    _error = null;

    try {
      final response = await ApiService.getProducts(
        search: search,
        categoryId: categoryId,
      );

      List<dynamic> productList = [];

      // Handle different response formats
      if (response['result'] == null) {
        throw Exception('API response missing result field');
      } else if (response['result'] is List) {
        // Direct list format
        productList = response['result'] as List<dynamic>;
      } else if (response['result'] is Map) {
        final resultMap = response['result'] as Map<String, dynamic>;

        // Try different possible field names
        if (resultMap['products'] is List) {
          productList = resultMap['products'] as List<dynamic>;
        } else if (resultMap['data'] is List) {
          productList = resultMap['data'] as List<dynamic>;
        } else if (resultMap['items'] is List) {
          productList = resultMap['items'] as List<dynamic>;
        } else {
          // If no list found, try to find any list value in the map
          for (final value in resultMap.values) {
            if (value is List) {
              productList = value;
              break;
            }
          }
          if (productList.isEmpty) {
            throw Exception(
              'No product list found in API response. Available keys: ${resultMap.keys.toList()}',
            );
          }
        }
      } else {
        throw Exception(
          'Unexpected response format: result is ${response['result'].runtimeType}',
        );
      }

      // Parse products safely
      _products = [];
      for (int i = 0; i < productList.length; i++) {
        try {
          final json = productList[i];
          if (json is Map<String, dynamic>) {
            _products.add(Product.fromJson(json));
          }
        } catch (e) {
          // Continue with other products instead of failing completely
        }
      }

      notifyListeners();
    } catch (e) {
      _error = e.toString();
      notifyListeners();
    } finally {
      _setLoading(false);
    }
  }

  /// Gets a specific product by ID
  Future<Product> getProductById(int id) async {
    try {
      final response = await ApiService.getProductById(id);
      try {
        return Product.fromJson(response['result']['product']);
      } catch (e) {
        rethrow;
      }
    } catch (e) {
      _error = e.toString();
      notifyListeners();
      rethrow;
    }
  }

  /// Gets catalog product variants for a product
  Future<List<Variant>> getCatalogProductVariants(int productId) async {
    try {
      final response = await ApiService.getCatalogProductVariants(productId);
      if (response['result'] is Map && response['result']['variants'] is List) {
        final variants = response['result']['variants'] as List;
        return variants.map((json) {
          try {
            return Variant.fromJson(json as Map<String, dynamic>);
          } catch (e) {
            rethrow;
          }
        }).toList();
      } else {
        throw Exception(
          'Unexpected response format: result.variants is not a list',
        );
      }
    } catch (e) {
      _error = e.toString();
      notifyListeners();
      rethrow;
    }
  }

  /// Gets product variant printfiles for mockup generation
  Future<PrintfileResult> getProductVariantPrintfiles(
    int productId, {
    String? orientation,
    String? technique,
    String? storeId,
  }) async {
    try {
      final response = await ApiService.getProductVariantPrintfiles(
        productId,
        orientation: orientation,
        technique: technique,
        storeId: storeId,
      );

      if (response['result'] != null) {
        return PrintfileResult.fromJson(
          response['result'] as Map<String, dynamic>,
        );
      } else {
        throw Exception('Unexpected response format: result is null');
      }
    } catch (e) {
      _error = e.toString();
      notifyListeners();
      rethrow;
    }
  }

  /// Sets search query and filters products
  void setSearchQuery(String query) {
    _searchQuery = query;
    notifyListeners();
  }

  /// Clears any existing error state
  void clearError() {
    _error = null;
    notifyListeners();
  }

  /// Sets loading state and notifies listeners
  void _setLoading(bool loading) {
    _isLoading = loading;
    notifyListeners();
  }

  /// Gets filtered products based on search query
  List<Product> get filteredProducts {
    if (_searchQuery.isEmpty) return _products;

    return _products.where((product) {
      final name = product.title?.toLowerCase() ?? '';
      final brand = product.brand?.toLowerCase() ?? '';
      final type = product.type?.toLowerCase() ?? '';
      final query = _searchQuery.toLowerCase();

      return name.contains(query) ||
          brand.contains(query) ||
          type.contains(query);
    }).toList();
  }

  /// Gets filtered store products based on search query
  List<SyncProduct> get filteredStoreProducts {
    if (_searchQuery.isEmpty) return _storeProducts;

    return _storeProducts.where((product) {
      final name = product.title?.toLowerCase() ?? '';
      final query = _searchQuery.toLowerCase();

      return name.contains(query);
    }).toList();
  }
}
