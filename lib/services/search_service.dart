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
      final suggestions = <String>[];
      
      // Search products
      String productFilter = 'view_name ~ "$query"';
      if (filters != null && filters.isNotEmpty) {
        if (filters['category'] != null) {
          productFilter += ' && category_id = "${filters['category']}"';
        }
        if (filters['brand'] != null) {
          productFilter += ' && brand_id = "${filters['brand']}"';
        }
      }

      final productsResult = await pb.collection('products').getList(
        filter: productFilter,
        page: 1,
        perPage: limit,
      );

      suggestions.addAll(
        productsResult.items
            .map((record) => record.getStringValue('view_name'))
            .where((name) => name.isNotEmpty)
      );

      // If we have space for more suggestions, search categories and brands
      if (suggestions.length < limit) {
        final remainingLimit = limit - suggestions.length;
        
        // Search categories
        final categoriesResult = await pb.collection('categories').getList(
          filter: 'name ~ "$query"',
          page: 1,
          perPage: remainingLimit,
        );

        suggestions.addAll(
          categoriesResult.items
              .map((record) => "Category: ${record.getStringValue('name')}")
              .where((name) => name.isNotEmpty)
        );

        // Search brands if we still have space
        if (suggestions.length < limit) {
          final brandsResult = await pb.collection('brands').getList(
            filter: 'name ~ "$query"',
            page: 1,
            perPage: limit - suggestions.length,
          );

          suggestions.addAll(
            brandsResult.items
                .map((record) => "Brand: ${record.getStringValue('name')}")
                .where((name) => name.isNotEmpty)
          );
        }
      }

      return suggestions.take(limit).toList();
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
      List<Product> products = [];
      List<Category> categories = [];
      List<Brand> brands = [];

      // Search products first
      String productFilter = 'view_name ~ "$query"';
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

      final productsResult = await pb.collection('products').getList(
        filter: productFilter,
        sort: sortBy == null ? '-created' : _getSortString(sortBy),
        expand: 'category_id,brand_id',
        page: page,
        perPage: itemsPerPage,
      );

      products = await Future.wait(
        productsResult.items.map((record) => Product.fromRecord(record)).toList()
      );

      // If no products found or on first page, search categories and brands
      if (products.isEmpty || page == 1) {
        // Search categories
        final categoriesResult = await pb.collection('categories').getList(
          filter: 'name ~ "$query"',
          page: 1,
          perPage: 10,
        );
        
        categories = categoriesResult.items
            .map((record) => Category.fromRecord(record))
            .toList();

        // Search brands
        final brandsResult = await pb.collection('brands').getList(
          filter: 'name ~ "$query"',
          page: 1,
          perPage: 10,
        );
        
        brands = brandsResult.items
            .map((record) => Brand.fromRecord(record))
            .toList();
      }

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
