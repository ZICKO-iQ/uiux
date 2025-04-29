import 'package:flutter/material.dart';
import '../models/product.dart';
import '../services/pb_service.dart';

class ProductProvider extends ChangeNotifier {
  final _pbService = PocketbaseService();
  List<Product> _products = [];
  List<Product> _filteredProducts = []; // Add this for filtered view
  bool _isLoading = false;
  String? _error;
  bool _isInitialized = false;
  String _sortBy = 'none';

  ProductProvider() {
    _init();
  }

  Future<void> _init() async {
    _isLoading = true;
    _error = null;
    notifyListeners();

    try {
      final pb = await _pbService.pb;

      // Fetch all products initially with expanded relationships
      final records = await pb.collection('Products').getFullList(
            expand: 'category_id,brand_id',
          );

      // Convert records to Product objects and update state
      _products = await Future.wait(
          records.map((record) => Product.fromRecord(record)));

      // Shuffle products on initial load
      _products.shuffle();

      print('Initially fetched ${_products.length} products');
      notifyListeners();

      // Set up real-time subscription with proper options
      pb.collection('Products').subscribe(
        '*',
        (e) async {
          try {
            // Assume you have a helper method to get the previous version of the product
            // This could be stored in a local cache or state management solution.
            final previousProduct = _products.firstWhere(
              (p) => p.id == e.record!.id,
            );

            // Get full record with expanded relationships
            final updatedRecord = await pb.collection('Products').getOne(
                  e.record!.id,
                  expand: 'category_id,brand_id',
                );

            // Create a Product instance from the updated record
            final updatedProduct = await Product.fromRecord(updatedRecord);

            // Check if the price or discount_price have changed
            bool shouldUpdate = false;
            if (previousProduct.price != updatedProduct.price ||
                previousProduct.discountPrice != updatedProduct.discountPrice) {
              shouldUpdate = true;
            }

            if (!shouldUpdate) {
              // If neither price nor discount_price changed, do nothing.
              return;
            }

            // Handle actions based on the realtime event
            switch (e.action) {
              case 'create':
                _products.add(updatedProduct);
                print('New product added: ${updatedProduct.viewName}');
                break;
              case 'update':
                final index = _products.indexWhere((p) => p.id == e.record!.id);
                if (index != -1) {
                  // Update product while maintaining its position
                  _products[index] = updatedProduct;
                  print('Product updated: ${updatedProduct.viewName}');
                }
                break;
              case 'delete':
                _products.removeWhere((p) => p.id == e.record!.id);
                print('Product deleted: ${e.record!.id}');
                break;
            }

            // Update filtered products if needed
            if (_filteredProducts.isNotEmpty) {
              _filteredProducts = getFilteredProducts();
            }

            notifyListeners();
          } catch (error) {
            print('Error processing realtime update: $error');
          }
        },
      );

      _isInitialized = true;
    } catch (e) {
      print('Error in ProductProvider init: $e');
      _error =
          'Unable to connect to server. Please check your internet connection.';
      _products = [];
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  // Getters
  List<Product> get products => _products;
  List<Product> get filteredProducts => _filteredProducts; // Add this getter
  bool get isLoading => _isLoading;
  String? get error => _error;
  bool get isInitialized => _isInitialized;
  String get sortBy => _sortBy;

  List<Product> getFilteredProducts({String? categoryId, String? brandId}) {
    return _products.where((product) {
      bool matchesCategory =
          categoryId == null || product.category.id == categoryId;
      bool matchesBrand = brandId == null || product.brand.id == brandId;
      return matchesCategory && matchesBrand;
    }).toList();
  }

  List<Product> getSortedProducts(List<Product> products) {
    final sortedProducts = List<Product>.from(products);
    switch (_sortBy) {
      case 'price_asc':
        sortedProducts.sort((a, b) => a.price.compareTo(b.price));
        break;
      case 'price_desc':
        sortedProducts.sort((a, b) => b.price.compareTo(a.price));
        break;
      case 'name_asc':
        sortedProducts.sort((a, b) => a.viewName.compareTo(b.viewName));
        break;
      case 'name_desc':
        sortedProducts.sort((a, b) => b.viewName.compareTo(a.viewName));
        break;
      case 'quantity_asc': // Add sorting by quantity ascending
        sortedProducts.sort((a, b) => a.quantity.compareTo(b.quantity));
        break;
      case 'quantity_desc': // Add sorting by quantity descending
        sortedProducts.sort((a, b) => b.quantity.compareTo(a.quantity));
        break;
    }
    return sortedProducts;
  }

  void setSortBy(String sortBy) {
    _sortBy = sortBy;
    notifyListeners();
  }

  List<String> getBrandsForCategory(String? categoryId) {
    if (categoryId == null) {
      return _products.map((p) => p.brand.id).toSet().toList();
    }

    return _products
        .where((p) => p.category.id == categoryId)
        .map((p) => p.brand.id)
        .toSet()
        .toList();
  }

  Future<void> loadProductsByCategory(String categoryId) async {
    _isLoading = true;
    _error = null;
    notifyListeners();

    try {
      final pb = await _pbService.pb;
      final records = await pb.collection('Products').getFullList(
            expand: 'category_id,brand_id',
            filter: 'category_id = "${categoryId}"',
          );

      final products = await Future.wait(
          records.map((record) => Product.fromRecord(record)));
      _filteredProducts = products;
      _error = null;
    } catch (e) {
      _error = 'Unable to load products. Please check your connection.';
      _filteredProducts = [];
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  Future<void> loadProductsByBrand(String brandId) async {
    _isLoading = true;
    _error = null;
    notifyListeners();

    try {
      final pb = await _pbService.pb;
      final records = await pb.collection('Products').getFullList(
            expand: 'category_id,brand_id',
            filter: 'brand_id = "${brandId}"',
          );

      final products = await Future.wait(
          records.map((record) => Product.fromRecord(record)));
      _filteredProducts = products;
      _error = null;
    } catch (e) {
      _error = 'Unable to load products. Please check your connection.';
      _filteredProducts = [];
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  Future<void> refreshProducts() async {
    _isLoading = true;
    _error = null;
    notifyListeners();

    try {
      final pb = await _pbService.pb;
      final records = await pb.collection('Products').getFullList(
            expand: 'category_id,brand_id',
          );

      _products = await Future.wait(
          records.map((record) => Product.fromRecord(record)));

      // Refresh filtered products if any
      if (_filteredProducts.isNotEmpty) {
        _filteredProducts = getFilteredProducts();
      }

      _products.shuffle();
      _error = null;
      _isInitialized = true;
    } catch (e) {
      _error = 'Unable to refresh products. Please check your connection.';
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  void clearFilteredProducts() {
    _filteredProducts = [];
    _error = null;
    notifyListeners();
  }

  @override
  void dispose() {
    _pbService.pb.then((pb) => pb.collection('Products').unsubscribe());
    super.dispose();
  }
}
