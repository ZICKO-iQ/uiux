import 'package:flutter/material.dart';
import '../services/pb_service.dart';
import '../models/product.dart';

class ProductProvider extends ChangeNotifier {
  final _pbService = PocketbaseService();
  List<Product> _products = [];
  bool _isLoading = false;
  String? _error;
  bool _isInitialized = false;
  String _sortBy = 'none';

  List<Product> get products => _products;
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
    
    _isLoading = true;
    _error = null;
    notifyListeners();

    try {
      final pb = await _pbService.pb;
      final response = await pb.collection('products').getFullList(
        expand: 'category_id,brand_id'
      );
      _products = await Future.wait(
        response.map((record) => Product.fromRecord(record))
      );
      _isInitialized = true;
      _error = null;
      
      // Subscribe to realtime updates
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
    } catch (e) {
      _error = "Error loading products: ${e.toString()}";
      _isInitialized = false;
    } finally {
      _isLoading = false;
      notifyListeners();
    }
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