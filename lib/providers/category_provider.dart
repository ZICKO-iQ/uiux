import 'package:flutter/material.dart';
import '../services/pb_service.dart';
import '../models/category.dart';

class CategoryProvider extends ChangeNotifier {
  final _pbService = PocketbaseService();
  List<Category> _categories = [];
  bool _isLoading = false;
  String? _error;
  bool _isInitialized = false;
  String? _selectedCategoryId;

  List<Category> get categories => _categories;
  bool get isLoading => _isLoading;
  String? get error => _error;
  bool get isInitialized => _isInitialized;
  String? get selectedCategoryId => _selectedCategoryId;

  Future<void> loadCategories() async {
    if (_isInitialized) return;
    
    _isLoading = true;
    _error = null;
    notifyListeners();

    try {
      final pb = await _pbService.pb;
      final response = await pb.collection('categories').getFullList();
      _categories = response.map((record) => Category.fromRecord(record)).toList();
      _isInitialized = true;
      _error = null;
    } catch (e) {
      _error = 'Failed to load categories: ${e.toString()}';
      _categories = [];
      _isInitialized = false;
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  void selectCategory(String? categoryId) {
    _selectedCategoryId = categoryId;
    notifyListeners();
  }

  void clearSelection() {
    _selectedCategoryId = null;
    notifyListeners();
  }

  Category? getCategoryById(String id) {
    try {
      return _categories.firstWhere((category) => category.id == id);
    } catch (_) {
      return null;
    }
  }

  Future<void> refreshCategories() async {
    _isInitialized = false;
    await loadCategories();
  }

  void clearError() {
    _error = null;
    notifyListeners();
  }

  @override
  void dispose() {
    _pbService.pb.then((pb) => pb.collection('categories').unsubscribe());
    super.dispose();
  }
}
