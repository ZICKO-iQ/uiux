import 'package:flutter/material.dart';
import 'package:pocketbase/pocketbase.dart';
import '../models/product.dart';
import '../models/category.dart';
import '../models/brand.dart';
import 'pb_service.dart';

class SearchResult {
  final List<Product> products;
  final List<Category> categories;
  final List<Brand> brands;

  SearchResult({
    required this.products,
    required this.categories,
    required this.brands,
  });
}

class SearchService {
  final _pbService = PocketbaseService();

  Future<List<String>> getSearchSuggestions(
    String query, {
    int limit = 5,
    Map<String, dynamic>? filters,
  }) async {
    if (query.trim().isEmpty) return [];

    try {
      final pb = await _pbService.pb;
      
      // Build filter string
      String filterStr = 'view_name ~ "$query"';
      if (filters != null && filters.isNotEmpty) {
        if (filters['category'] != null) {
          filterStr += ' && category_id = "${filters['category']}"';
        }
        if (filters['brand'] != null) {
          filterStr += ' && brand_id = "${filters['brand']}"';
        }
      }

      final productsResult = await pb.collection('products').getList(
        filter: filterStr,
        page: 1,
        perPage: limit,
      );

      return productsResult.items
          .map((record) => record.getStringValue('view_name'))
          .where((name) => name.isNotEmpty)
          .toList();
    } catch (e) {
      throw Exception('Failed to get search suggestions: $e');
    }
  }

  Future<SearchResult> search(
    String query, {
    required int page,
    required int itemsPerPage,
    String? sortBy,
    Map<String, dynamic>? filters,
  }) async {
    try {
      final pb = await _pbService.pb;
      
      // Build filter string
      List<String> filterConditions = ['view_name ~ "$query"'];
      
      if (filters != null && filters.isNotEmpty) {
        if (filters['category'] != null) {
          filterConditions.add('category_id = "${filters['category']}"');
        }
        if (filters['brand'] != null) {
          filterConditions.add('brand_id = "${filters['brand']}"');
        }
        if (filters['price_range'] != null && filters['price_range'] is RangeValues) {
          final range = filters['price_range'] as RangeValues;
          filterConditions.add('(price >= ${range.start} && price <= ${range.end})');
        }
      }

      final filterStr = filterConditions.join(' && ');

      // Build sort string
      String sortStr = sortBy == null ? '-created' : _getSortString(sortBy);

      final productsResult = await pb.collection('products').getList(
        filter: filterStr,
        sort: sortStr,
        expand: 'category_id,brand_id',
        page: page,
        perPage: itemsPerPage,
      );

      final products = await Future.wait(
        productsResult.items.map((record) => Product.fromRecord(record)).toList()
      );

      final categoryIds = products.map((p) => p.category.id).toSet();
      final brandIds = products.map((p) => p.brand.id).toSet();

      final categories = await _fetchCategories(pb, categoryIds);
      final brands = await _fetchBrands(pb, brandIds);

      return SearchResult(
        products: products,
        categories: categories,
        brands: brands,
      );
    } catch (e) {
      throw Exception('Failed to perform search: $e');
    }
  }

  String _getSortString(String sortBy) {
    switch (sortBy) {
      case 'price_asc':
        return 'price';
      case 'price_desc':
        return '-price';
      case 'name_asc':
        return 'view_name';
      case 'name_desc':
        return '-view_name';
      default:
        return '-created';
    }
  }

  Future<List<Category>> _fetchCategories(PocketBase pb, Set<String> ids) async {
    if (ids.isEmpty) return [];
    
    final result = await pb.collection('categories').getList(
      filter: 'id ?~ "${ids.join('|')}"',
    );
    
    return result.items.map((record) => Category.fromRecord(record)).toList();
  }

  Future<List<Brand>> _fetchBrands(PocketBase pb, Set<String> ids) async {
    if (ids.isEmpty) return [];
    
    final result = await pb.collection('brands').getList(
      filter: 'id ?~ "${ids.join('|')}"',
    );
    
    return result.items.map((record) => Brand.fromRecord(record)).toList();
  }
}
