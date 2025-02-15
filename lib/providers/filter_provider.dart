import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../models/brand.dart';  // Add this import
import 'product_provider.dart';
import 'category_provider.dart';
import 'brand_provider.dart';
import '../models/product.dart';

class FilterProvider extends ChangeNotifier {
  String? get selectedCategoryId => _categoryProvider?.selectedCategoryId;
  String? get selectedBrandId => _brandProvider?.selectedBrandId;
  String get sortBy => _productProvider?.sortBy ?? 'none';

  CategoryProvider? _categoryProvider;
  BrandProvider? _brandProvider;
  ProductProvider? _productProvider;

  void initialize(BuildContext context) {
    _categoryProvider = context.read<CategoryProvider>();
    _brandProvider = context.read<BrandProvider>();
    _productProvider = context.read<ProductProvider>();
  }

  void applyFilters({
    String? categoryId,
    String? brandId,
    String? sortBy,
  }) {
    if (_categoryProvider != null && _brandProvider != null && _productProvider != null) {
      _categoryProvider!.selectCategory(categoryId);
      _brandProvider!.selectBrand(brandId);
      if (sortBy != null) {
        _productProvider!.setSortBy(sortBy);
      }
      notifyListeners();
    }
  }

  List<Product> getFilteredAndSortedProducts() {
    if (_productProvider == null) return [];
    
    final filtered = _productProvider!.getFilteredProducts(
      categoryId: selectedCategoryId,
      brandId: selectedBrandId,
    );
    
    return _productProvider!.getSortedProducts(filtered);
  }

  List<Brand> getAvailableBrandsForCategory() {
    if (_productProvider == null || _brandProvider == null) return [];
    
    // If no category is selected, return all brands
    if (selectedCategoryId == null) {
      return List<Brand>.from(_brandProvider!.brands)
        ..sort((a, b) => a.name.compareTo(b.name));
    }
    
    // Otherwise, return brands for selected category
    final brandIds = _productProvider!.getBrandsForCategory(selectedCategoryId);
    return _brandProvider!.brands
        .where((brand) => brandIds.contains(brand.id))
        .toList()
      ..sort((a, b) => a.name.compareTo(b.name));
  }

  bool get hasActiveFilters => 
    selectedCategoryId != null || 
    selectedBrandId != null || 
    sortBy != 'none';

  void clearAllFilters() {
    _categoryProvider?.clearSelection();
    _brandProvider?.clearSelection();
    _productProvider?.setSortBy('none');
  }

  String getActiveFiltersText() {
    List<String> activeFilters = [];
    
    if (selectedCategoryId != null) {
      final category = _categoryProvider?.getCategoryById(selectedCategoryId!);
      if (category != null) activeFilters.add(category.name);
    }
    
    if (selectedBrandId != null) {
      final brand = _brandProvider?.getBrandById(selectedBrandId!);
      if (brand != null) activeFilters.add(brand.name);
    }
    
    switch (sortBy) {
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

  int getCategoryItemCount(String? categoryId) {
    if (_productProvider == null) return 0;
    return _productProvider!.getFilteredProducts(categoryId: categoryId).length;
  }

  int getBrandItemCount(String? brandId, [String? categoryId]) {
    if (_productProvider == null) return 0;
    return _productProvider!.getFilteredProducts(
      brandId: brandId,
      categoryId: categoryId,
    ).length;
  }
}
