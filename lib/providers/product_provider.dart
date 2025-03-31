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
    try {
      final pb = await _pbService.pb;
      
      // Fetch all products initially with expanded relationships
      final records = await pb.collection('Products').getFullList(
        expand: 'category_id,brand_id',
      );
      
      // Convert records to Product objects and update state
      _products = await Future.wait(
        records.map((record) => Product.fromRecord(record))
      );
      
      print('Initially fetched ${_products.length} products');
      notifyListeners();

      // Set up real-time subscription with proper options
      pb.collection('Products').subscribe(
        '*',
        (e) async {
          try {
            switch (e.action) {
              case 'create':
                // Get full record with expanded relationships
                final newRecord = await pb.collection('Products').getOne(
                  e.record!.id,
                  expand: 'category_id,brand_id',
                );
                final newProduct = await Product.fromRecord(newRecord);
                _products.add(newProduct);
                print('New product added: ${newProduct.viewName}');
                break;
              case 'update':
                final updatedRecord = await pb.collection('Products').getOne(
                  e.record!.id,
                  expand: 'category_id,brand_id',
                );
                final index = _products.indexWhere((p) => p.id == e.record!.id);
                if (index != -1) {
                  final updatedProduct = await Product.fromRecord(updatedRecord);
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
      _error = 'Unable to connect to server. Please check your internet connection.';
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

  Future<void> loadProductsByCategory(String categoryId) async {
    _filteredProducts = getFilteredProducts(categoryId: categoryId);
    notifyListeners();
  }

  Future<void> loadProductsByBrand(String brandId) async {
    _filteredProducts = getFilteredProducts(brandId: brandId);
    notifyListeners();
  }

  void clearFilteredProducts() {
    _filteredProducts = [];
    _error = null;
    notifyListeners();
  }

  Future<void> refreshProducts() async {
    _isInitialized = false;
    await _init();
  }

  @override
  void dispose() {
    _pbService.pb.then((pb) => pb.collection('Products').unsubscribe());
    super.dispose();
  }
}