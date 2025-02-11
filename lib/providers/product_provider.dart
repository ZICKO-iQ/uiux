import 'package:flutter/material.dart';
import '../services/pb_service.dart';
import '../models/product.dart';
import '../models/category.dart';

class ProductProvider extends ChangeNotifier {
  final _pb = PocketbaseService().pb;
  List<Product> _products = [];
  List<Product> get products => _products;
  
  List<Category> _categories = [];
  List<Category> get categories => _categories;

  bool _isLoading = false;
  String? _error;
  
  bool get isLoading => _isLoading;
  String? get error => _error;

  bool _isInitialized = false;
  bool get isInitialized => _isInitialized;

  String? _selectedCategoryId;
  String? _selectedBrand;
  String _sortBy = 'none'; // none, price_asc, price_desc, name_asc, name_desc

  String? get selectedCategoryId => _selectedCategoryId;
  String? get selectedBrand => _selectedBrand;
  String get sortBy => _sortBy;

  bool get hasActiveFilters => 
    _selectedCategoryId != null || 
    _selectedBrand != null || 
    _sortBy != 'none';

  String getActiveFiltersText() {
    List<String> activeFilters = [];
    
    if (_selectedCategoryId != null) {
      final category = _categories.firstWhere((c) => c.id == _selectedCategoryId);
      activeFilters.add(category.name);
    }
    
    if (_selectedBrand != null) {
      activeFilters.add(_selectedBrand!);
    }
    
    switch (_sortBy) {
      case 'price_asc':
        activeFilters.add('Price ⬆');
        break;
      case 'price_desc':
        activeFilters.add('Price ⬇');
        break;
      case 'name_asc':
        activeFilters.add('Name A-Z');
        break;
      case 'name_desc':
        activeFilters.add('Name Z-A');
        break;
    }
    
    return activeFilters.isEmpty ? '' : activeFilters.join(' • ');
  }

  List<String> get availableBrands {
    return _products.map((p) => p.brand).toSet().toList()..sort();
  }

  List<Product> get filteredAndSortedProducts {
    List<Product> result = List.from(_products);
    
    // Apply category filter
    if (_selectedCategoryId != null) {
      result = result.where((p) => p.category.id == _selectedCategoryId).toList();
    }
    
    // Apply brand filter
    if (_selectedBrand != null) {
      result = result.where((p) => p.brand == _selectedBrand).toList();
    }
    
    // Apply sorting
    switch (_sortBy) {
      case 'price_asc':
        result.sort((a, b) => a.price.compareTo(b.price));
        break;
      case 'price_desc':
        result.sort((a, b) => b.price.compareTo(a.price));
        break;
      case 'name_asc':
        result.sort((a, b) => a.viewName.compareTo(b.viewName));
        break;
      case 'name_desc':
        result.sort((a, b) => b.viewName.compareTo(a.viewName));
        break;
    }
    
    return result;
  }

  void setFilters({String? categoryId, String? brand}) {
    _selectedCategoryId = categoryId;
    _selectedBrand = brand;
    notifyListeners();
  }

  void setSortBy(String sortBy) {
    _sortBy = sortBy;
    notifyListeners();
  }

  void clearFilters() {
    _selectedCategoryId = null;
    _selectedBrand = null;
    _sortBy = 'none';
    notifyListeners();
  }

  Future<void> loadProducts() async {
    if (_isInitialized) return; // Skip if already initialized
    
    _isLoading = true;
    _error = null;
    notifyListeners();

    try {
      final response = await _pb.collection('Products').getFullList(expand: 'category_id');
      _products = await Future.wait(
        response.map((record) => Product.fromRecord(record))
      );
      
      final categoryResponse = await _pb.collection('Categories').getFullList();
      _categories = categoryResponse.map((record) => Category.fromRecord(record)).toList();
      
      _isInitialized = true; // Mark as initialized
      _isLoading = false;
      _error = null;
      notifyListeners();
      
      _pb.collection('Products').subscribe('*', (e) async {
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
          _error = "Error processing realtime update: ${e.toString()}";
          notifyListeners();
        }
      });
    } catch (e) {
      _error = "Error loading products: ${e.toString()}";
      _isLoading = false;
      _isInitialized = false; // Reset initialization on error
      notifyListeners();
    }
  }

  Future<void> refreshProducts() async {
    _error = null;
    _isInitialized = false; // Reset initialization flag to force reload
    notifyListeners();
    await loadProducts();
  }

  int getCategoryCount(String? categoryId) {
    if (categoryId == null) return _products.length;
    return _products.where((p) => p.category.id == categoryId).length;
  }

  int getBrandCount(String? brand, [String? categoryId]) {
    if (brand == null) return categoryId == null 
        ? _products.length 
        : _products.where((p) => p.category.id == categoryId).length;
        
    var filteredProducts = _products.where((p) => p.brand == brand);
    if (categoryId != null) {
      filteredProducts = filteredProducts.where((p) => p.category.id == categoryId);
    }
    return filteredProducts.length;
  }

  @override
  void dispose() {
    _pb.collection('Products').unsubscribe();
    super.dispose();
  }
}