import 'package:flutter/material.dart';
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

class MatchResult {
  final bool isMatch;
  final int score;

  MatchResult(this.isMatch, this.score);
}

class SearchService {
  final _pbService = PocketbaseService();

  int _getMinimumMatchesRequired(int queryLength) {
    if (queryLength < 3) return queryLength; // For very short queries
    if (queryLength <= 5) return 3; // Original minimum
    if (queryLength <= 10) return (queryLength * 0.5).ceil(); // 50% of query length
    if (queryLength <= 20) return (queryLength * 0.4).ceil(); // 40% of query length
    return (queryLength * 0.3).ceil(); // 30% for very long queries
  }

  MatchResult _fuzzyMatchWithScore(String text, String query) {
    if (query.isEmpty) return MatchResult(true, 0);
    if (text.isEmpty) return MatchResult(false, 0);

    text = text.replaceAll(' ', '').toLowerCase();
    query = query.replaceAll(' ', '').toLowerCase();

    int minimumMatches = _getMinimumMatchesRequired(query.length);

    if (query.length < 3) {
      int textIndex = 0;
      int queryIndex = 0;

      while (textIndex < text.length && queryIndex < query.length) {
        if (text[textIndex] == query[queryIndex]) {
          queryIndex++;
        }
        textIndex++;
      }

      return MatchResult(queryIndex == query.length, queryIndex);
    } else {
      int matches = 0;
      List<bool> usedIndices = List.filled(text.length, false);

      for (int i = 0; i < query.length; i++) {
        for (int j = 0; j < text.length; j++) {
          if (!usedIndices[j] && text[j] == query[i]) {
            matches++;
            usedIndices[j] = true;
            break;
          }
        }
      }

      // Calculate bonus points for consecutive matches and position
      int consecutiveMatches = 0;
      int positionBonus = 0;
      for (int i = 0; i < text.length; i++) {
        if (usedIndices[i]) {
          consecutiveMatches++;
          // Give bonus points for matches near the start
          positionBonus += (text.length - i);
        } else {
          consecutiveMatches = 0;
        }
      }

      int score = matches * 10 + consecutiveMatches * 5 + positionBonus;
      return MatchResult(matches >= minimumMatches, score);
    }
  }

  Future<List<String>> getSearchSuggestions(
    String query, {
    int limit = 5,
    Map<String, dynamic>? filters,
  }) async {
    if (query.trim().isEmpty) return [];

    try {
      final pb = await _pbService.pb;
      final suggestions = <String>[];
      
      // Get all products first (within a reasonable limit)
      String productFilter = '';
      if (filters != null && filters.isNotEmpty) {
        List<String> filterConditions = [];
        if (filters['category'] != null) {
          filterConditions.add('category_id = "${filters['category']}"');
        }
        if (filters['brand'] != null) {
          filterConditions.add('brand_id = "${filters['brand']}"');
        }
        if (filterConditions.isNotEmpty) {
          productFilter = filterConditions.join(' && ');
        }
      }

      final productsResult = await pb.collection('products').getList(
        filter: productFilter,
        page: 1,
        perPage: 100, // Get more items for better fuzzy matching
      );

      // Apply fuzzy matching with scoring
      var scoredSuggestions = productsResult.items
          .map((record) {
            String name = record.getStringValue('view_name');
            var matchResult = _fuzzyMatchWithScore(name, query);
            return MapEntry(name, matchResult);
          })
          .where((entry) => entry.value.isMatch)
          .toList()
        ..sort((a, b) => b.value.score.compareTo(a.value.score));

      suggestions.addAll(
        scoredSuggestions
            .map((entry) => entry.key)
            .take(limit)
      );

      // If we have space for more suggestions, search categories and brands
      if (suggestions.length < limit) {
        final remainingLimit = limit - suggestions.length;
        
        final categoriesResult = await pb.collection('categories').getList(
          page: 1,
          perPage: 50,
        );

        var scoredCategories = categoriesResult.items
            .map((record) {
              String name = "Category: ${record.getStringValue('name')}";
              var matchResult = _fuzzyMatchWithScore(name, query);
              return MapEntry(name, matchResult);
            })
            .where((entry) => entry.value.isMatch)
            .toList()
          ..sort((a, b) => b.value.score.compareTo(a.value.score));

        suggestions.addAll(
          scoredCategories
              .map((entry) => entry.key)
              .take(remainingLimit)
        );

        if (suggestions.length < limit) {
          final brandsResult = await pb.collection('brands').getList(
            page: 1,
            perPage: 50,
          );

          var scoredBrands = brandsResult.items
              .map((record) {
                String name = "Brand: ${record.getStringValue('name')}";
                var matchResult = _fuzzyMatchWithScore(name, query);
                return MapEntry(name, matchResult);
              })
              .where((entry) => entry.value.isMatch)
              .toList()
            ..sort((a, b) => b.value.score.compareTo(a.value.score));

          suggestions.addAll(
            scoredBrands
                .map((entry) => entry.key)
                .take(limit - suggestions.length)
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

      // Get all products first (with pagination)
      List<String> filterConditions = [];
      
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

      final productsResult = await pb.collection('products').getList(
        filter: filterConditions.isEmpty ? '' : filterConditions.join(' && '),
        sort: sortBy == null ? '-created' : _getSortString(sortBy),
        expand: 'category_id,brand_id',
        page: page,
        perPage: itemsPerPage * 3, // Get more items for better matching
      );

      final allProducts = await Future.wait(
        productsResult.items.map((record) => Product.fromRecord(record)).toList()
      );

      // First pass: Get initial scores and identify the best matching product
      var initialScoredProducts = allProducts
          .map((product) {
            var matchResult = _fuzzyMatchWithScore(product.viewName, query);
            return MapEntry(product, matchResult);
          })
          .where((entry) => entry.value.isMatch)
          .toList()
        ..sort((a, b) => b.value.score.compareTo(a.value.score));

      // Get the brand and category of the best matching product
      String? topBrandId;
      String? topCategoryId;
      if (initialScoredProducts.isNotEmpty) {
        var topProduct = initialScoredProducts.first.key;
        topBrandId = topProduct.brand.id;
        topCategoryId = topProduct.category.id;
      }

      // Second pass: Adjust scores with brand and category priority
      var scoredProducts = allProducts
          .map((product) {
            var matchResult = _fuzzyMatchWithScore(product.viewName, query);
            int baseScore = matchResult.score;
            
            // Massive boost for same brand as top result
            if (product.brand.id == topBrandId) {
              baseScore += 1000000; // Very high priority for same brand
            }
            // Medium boost for same category
            if (product.category.id == topCategoryId) {
              baseScore += 10000; // Medium priority for same category
            }

            return MapEntry(
              product,
              MatchResult(
                matchResult.isMatch,
                baseScore
              )
            );
          })
          .where((entry) => entry.value.isMatch)
          .toList()
        ..sort((a, b) => b.value.score.compareTo(a.value.score));

      products = scoredProducts
          .map((entry) => entry.key)
          .take(itemsPerPage)
          .toList();

      // If no products found or on first page, search categories and brands
      if (products.isEmpty || page == 1) {
        final categoriesResult = await pb.collection('categories').getList(
          page: 1,
          perPage: 50,
        );
        
        var scoredCategories = categoriesResult.items
            .map((record) => Category.fromRecord(record))
            .map((category) {
              var matchResult = _fuzzyMatchWithScore(category.name, query);
              return MapEntry(category, matchResult);
            })
            .where((entry) => entry.value.isMatch)
            .toList()
          ..sort((a, b) => b.value.score.compareTo(a.value.score));

        categories = scoredCategories
            .map((entry) => entry.key)
            .take(10)
            .toList();

        final brandsResult = await pb.collection('brands').getList(
          page: 1,
          perPage: 50,
        );
        
        var scoredBrands = brandsResult.items
            .map((record) => Brand.fromRecord(record))
            .map((brand) {
              var matchResult = _fuzzyMatchWithScore(brand.name, query);
              return MapEntry(brand, matchResult);
            })
            .where((entry) => entry.value.isMatch)
            .toList()
          ..sort((a, b) => b.value.score.compareTo(a.value.score));

        brands = scoredBrands
            .map((entry) => entry.key)
            .take(10)
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
}
