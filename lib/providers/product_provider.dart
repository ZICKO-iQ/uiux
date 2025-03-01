import 'package:flutter/material.dart';
import '../services/pb_service.dart';
import '../models/product.dart';

class ProductProvider extends ChangeNotifier {
  final _pbService = PocketbaseService();
  List<Product> _products = [];
  List<Product> _filteredProducts = []; // Add this for filtered view
  bool _isLoading = false;
  String? _error;
  bool _isInitialized = false;
  String _sortBy = 'none';

  // Getters
  List<Product> get products => _products;
  List<Product> get filteredProducts => _filteredProducts; // Add this getter
  bool get isLoading => _isLoading;
  String? get error => _error;
  bool get isInitialized => _isInitialized;
  String get sortBy => _sortBy;

  List<Product> getFilteredProducts({String? categoryId, String? brandId}) {
    return _products.where((product) {
      bool matchesCategory = categoryId == null || product.category.id == categoryId;
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
    }
    return sortedProducts;
  }

  void setSortBy(String sortBy) {
    _sortBy = sortBy;
    notifyListeners();
  }

  List<String> getBrandsForCategory(String? categoryId) {
    if (categoryId == null) {
      return _products
          .map((p) => p.brand.id)
          .toSet()
          .toList();
    }
    
    return _products
        .where((p) => p.category.id == categoryId)
        .map((p) => p.brand.id)
        .toSet()
        .toList();
  }

  Future<void> loadProducts() async {
    if (_isInitialized) return;
    await _loadProductsWithFilter();
    _isInitialized = true;
    
    // Subscribe to realtime updates
    final pb = await _pbService.pb;
    pb.collection('products').subscribe('*', (e) async {
      try {
        switch (e.action) {
          case 'create':
            final newProduct = await Product.fromRecord(e.record!);
            _products.add(newProduct);
            break;
          case 'update':
            final index = _products.indexWhere((p) => p.id == e.record!.id);
            if (index != -1) {
              final updatedProduct = await Product.fromRecord(e.record!);
              _products[index] = updatedProduct;
            }
            break;
          case 'delete':
            _products.removeWhere((p) => p.id == e.record!.id);
            break;
        }
        notifyListeners();
      } catch (e) {
        print('Error processing realtime update: $e');
      }
    });
  }

  Future<void> loadProductsByCategory(String categoryId) async {
    await _loadProductsWithFilter(filter: 'category_id = "$categoryId"', isFiltered: true);
  }

  Future<void> loadProductsByBrand(String brandId) async {
    await _loadProductsWithFilter(filter: 'brand_id = "$brandId"', isFiltered: true);
  }

  Future<void> _loadProductsWithFilter({String? filter, bool isFiltered = false}) async {
    _isLoading = true;
    _error = null;
    notifyListeners();

    try {
      final pb = await _pbService.pb;
      final response = await pb.collection('products').getFullList(
        filter: filter,
        expand: 'category_id,brand_id'
      );
      
      final loadedProducts = await Future.wait(
        response.map((record) => Product.fromRecord(record))
      );

      if (isFiltered) {
        _filteredProducts = loadedProducts;
      } else {
        _products = loadedProducts;
      }
      _error = null;
    } catch (e) {
      _error = 'Unable to connect to server. Please check your internet connection.';
      if (isFiltered) {
        _filteredProducts = [];
      } else {
        _products = [];
        _isInitialized = false;
      }
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

  Future<void> refreshProducts() async {
    _isInitialized = false;
    await loadProducts();
  }

  @override
  void dispose() {
    _pbService.pb.then((pb) => pb.collection('products').unsubscribe());
    super.dispose();
  }
}