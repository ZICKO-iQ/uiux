import 'package:flutter/material.dart';
import '../services/pb_service.dart';
import '../models/brand.dart';

class BrandProvider extends ChangeNotifier {
  final _pbService = PocketbaseService();
  List<Brand> _brands = [];
  bool _isLoading = false;
  String? _error;
  bool _isInitialized = false;
  String? _selectedBrandId;

  List<Brand> get brands => _brands;
  bool get isLoading => _isLoading;
  String? get error => _error;
  bool get isInitialized => _isInitialized;
  String? get selectedBrandId => _selectedBrandId;

  Future<void> loadBrands() async {
    if (_isInitialized) return;

    _isLoading = true;
    _error = null;
    notifyListeners();

    try {
      final pb = await _pbService.pb;
      final response = await pb.collection('brands').getFullList();
      _brands = response.map((record) => Brand.fromRecord(record)).toList();
      _isInitialized = true;
      _error = null;
    } catch (e) {
      _error = 'Failed to load brands: ${e.toString()}';
      _brands = [];
      _isInitialized = false;
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  void selectBrand(String? brandId) {
    _selectedBrandId = brandId;
    notifyListeners();
  }

  void clearSelection() {
    _selectedBrandId = null;
    notifyListeners();
  }

  Brand? getBrandById(String id) {
    try {
      return _brands.firstWhere((brand) => brand.id == id);
    } catch (_) {
      return Brand.defaultBrand;
    }
  }

  Future<void> refreshBrands() async {
    _isInitialized = false;
    await loadBrands();
  }

  @override
  void dispose() {
    _pbService.pb.then((pb) => pb.collection('brands').unsubscribe());
    super.dispose();
  }
}
