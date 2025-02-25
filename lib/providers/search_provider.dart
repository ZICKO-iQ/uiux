import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'dart:async';
import '../models/product.dart';
import '../models/category.dart';
import '../models/brand.dart';
import '../services/search_service.dart';

class SearchProvider with ChangeNotifier {
  final SearchService _searchService = SearchService();
  SharedPreferences? _prefs;
  static const String _searchHistoryKey = 'search_history';
  static const int _maxHistoryItems = 10;
  
  bool _isLoading = false;
  List<Product> _products = [];
  List<Category> _categories = [];
  List<Brand> _brands = [];
  List<String> _suggestions = [];
  List<String> _searchHistory = [];
  String? _error;
  String _sortBy = 'relevance';
  Map<String, dynamic> _filters = {};
  int _currentPage = 1;
  static const int _itemsPerPage = 20;
  bool _hasMoreItems = true;

  SearchProvider() {
    _initPrefs();
  }

  Future<void> _initPrefs() async {
    try {
      if (!await _checkPlatformReady()) {
        _error = 'Platform not ready for SharedPreferences';
        return;
      }
      
      try {
        _prefs = await SharedPreferences.getInstance();
      } catch (e) {
        _error = 'Failed to initialize SharedPreferences: $e';
        return;
      }
      
      await _loadSearchHistory();
    } catch (e) {
      _error = 'Failed to initialize preferences: $e';
      _searchHistory = [];
    } finally {
      notifyListeners();
    }
  }

  Future<bool> _checkPlatformReady() async {
    try {
      WidgetsFlutterBinding.ensureInitialized();
      return true;
    } catch (e) {
      return false;
    }
  }

  Future<void> _loadSearchHistory() async {
    try {
      if (_prefs == null) {
        _searchHistory = [];
        return;
      }
      
      _searchHistory = _prefs!.getStringList(_searchHistoryKey) ?? [];
    } catch (e) {
      _error = 'Failed to load search history: $e';
      _searchHistory = [];
    }
  }

  // Getters
  bool get isLoading => _isLoading;
  List<Product> get products => _products;
  List<Category> get categories => _categories;
  List<Brand> get brands => _brands;
  List<String> get suggestions => _suggestions;
  List<String> get searchHistory => _searchHistory;
  String? get error => _error;
  String get sortBy => _sortBy;
  Map<String, dynamic> get filters => _filters;
  bool get hasMoreItems => _hasMoreItems;

  // Search History Methods
  Future<void> addToSearchHistory(String query) async {
    if (query.trim().isEmpty || _prefs == null) return;

    try {
      _searchHistory.remove(query);
      _searchHistory.insert(0, query);
      
      if (_searchHistory.length > _maxHistoryItems) {
        _searchHistory = _searchHistory.sublist(0, _maxHistoryItems);
      }
      
      await _prefs!.setStringList(_searchHistoryKey, _searchHistory);
    } catch (e) {
      _error = 'Failed to save search history: $e';
    }
    notifyListeners();
  }

  Future<void> clearSearchHistory() async {
    if (_prefs == null) return;
    
    try {
      _searchHistory.clear();
      await _prefs!.remove(_searchHistoryKey);
    } catch (e) {
      _error = 'Failed to clear search history: $e';
    }
    notifyListeners();
  }

  // Search and Filter Methods
  void setSort(String sortBy) {
    _sortBy = sortBy;
    _currentPage = 1;
    _products = [];
    notifyListeners();
  }

  void setFilter(String key, dynamic value) {
    _filters[key] = value;
    _currentPage = 1;
    _products = [];
    notifyListeners();
  }

  void clearFilters() {
    _filters.clear();
    _currentPage = 1;
    _products = [];
    notifyListeners();
  }

  Future<void> getSuggestions(String query) async {
    if (query.trim().isEmpty) {
      _suggestions = _searchHistory.take(5).toList();
      notifyListeners();
      return;
    }

    try {
      _suggestions = await _searchService.getSearchSuggestions(
        query,
        filters: _filters,
      );
    } catch (e) {
      _error = 'Failed to get suggestions: $e';
      _suggestions = [];
    }
    notifyListeners();
  }

  Future<void> performSearch(String query) async {
    if (_isLoading || query.trim().isEmpty) return;
    
    _isLoading = true;
    _error = null;
    
    if (_currentPage == 1) {
      _products = [];
      _categories = [];
      _brands = [];
      notifyListeners();
    }

    try {
      final results = await _searchService.search(
        query,
        page: _currentPage,
        itemsPerPage: _itemsPerPage,
        sortBy: _sortBy,
        filters: _filters,
      );

      if (_currentPage == 1) {
        _products = results.products;
        _categories = results.categories;
        _brands = results.brands;
      } else {
        _products.addAll(results.products);
      }

      _hasMoreItems = results.products.length >= _itemsPerPage;
      _currentPage++;
      await addToSearchHistory(query);
      
    } catch (e) {
      _error = 'Search failed: $e';
      if (_currentPage == 1) {
        _products = [];
        _categories = [];
        _brands = [];
      }
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  Future<void> loadMoreResults(String query) async {
    if (_isLoading || !_hasMoreItems) return;
    await performSearch(query);
  }

  void clearSearch() {
    _products = [];
    _categories = [];
    _brands = [];
    _suggestions = [];
    _error = null;
    _currentPage = 1;
    _hasMoreItems = true;
    notifyListeners();
  }

  List<Product> getFilteredAndSortedProducts() {
    List<Product> filteredProducts = List.from(_products);
    
    // Apply filters
    if (_filters.isNotEmpty) {
      filteredProducts = filteredProducts.where((product) {
        return _filters.entries.every((filter) {
          switch (filter.key) {
            case 'price_range':
              final range = filter.value as RangeValues;
              return product.price >= range.start && product.price <= range.end;
            case 'category':
              return product.category.id == filter.value;
            case 'brand':
              return product.brand.id == filter.value;
            default:
              return true;
          }
        });
      }).toList();
    }

    // Apply sorting
    switch (_sortBy) {
      case 'price_asc':
        filteredProducts.sort((a, b) => a.price.compareTo(b.price));
        break;
      case 'price_desc':
        filteredProducts.sort((a, b) => b.price.compareTo(a.price));
        break;
      case 'name_asc':
        filteredProducts.sort((a, b) => a.viewName.compareTo(b.viewName));
        break;
      case 'name_desc':
        filteredProducts.sort((a, b) => b.viewName.compareTo(a.viewName));
        break;
    }

    return filteredProducts;
  }

  @override
  void dispose() {
    // Clean up if needed
    super.dispose();
  }
}
