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

  String _normalizeText(String text) {
    return text.toLowerCase().replaceAll(RegExp(r'\s+'), '');
  }

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

  int _calculateMatchScore(String text, List<String> queryChars) {
    final normalizedText = _normalizeText(text);
    int score = 0;
    int consecutiveMatches = 0;
    int lastMatchIndex = -1;

    for (int i = 0; i < normalizedText.length; i++) {
      if (queryChars.contains(normalizedText[i])) {
        score += 10; // Base score for each match
        
        // Bonus for consecutive matches
        if (lastMatchIndex == i - 1) {
          consecutiveMatches++;
          score += consecutiveMatches * 5;
        } else {
          consecutiveMatches = 0;
        }
        
        // Bonus for matches near the start
        score += (normalizedText.length - i);
        
        lastMatchIndex = i;
      }
    }
    return score;
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
      final normalizedQuery = _normalizeText(query);
      final queryChars = normalizedQuery.split('');

      // Get products
      List<String> productFilterConditions = [];
      if (filters != null && filters.isNotEmpty) {
        if (filters['category'] != null) {
          productFilterConditions.add('category_id = "${filters['category']}"');
        }
        if (filters['brand'] != null) {
          productFilterConditions.add('brand_id = "${filters['brand']}"');
        }
        if (filters['price_range'] != null && filters['price_range'] is RangeValues) {
          final range = filters['price_range'] as RangeValues;
          productFilterConditions.add('(price >= ${range.start} && price <= ${range.end})');
        }
      }

      // Build character-based search conditions
      if (queryChars.isNotEmpty) {
        final charConditions = queryChars.map((char) => 'view_name ~ "$char"').join(' && ');
        productFilterConditions.add('($charConditions)');
      }

      final productsResult = await pb.collection('products').getList(
        filter: productFilterConditions.join(' && '),
        sort: sortBy == null ? '-created' : _getSortString(sortBy),
        expand: 'category_id,brand_id',
        page: page,
        perPage: itemsPerPage * 2, // Get more items for filtering
      );

      // Process products and group by category and brand
      final categoryMatchCount = <String, int>{};
      final brandMatchCount = <String, int>{};
      final Map<String, Map<String, List<Product>>> productsByCategoryAndBrand = {};
      
      // First pass: Count matches and group products
      for (var record in productsResult.items) {
        final product = await Product.fromRecord(record);
        final normalizedName = _normalizeText(product.viewName);
        
        if (queryChars.every((char) => normalizedName.contains(char))) {
          final categoryId = product.category.id;
          final brandId = product.brand.id;
          
          // Count category matches
          categoryMatchCount[categoryId] = (categoryMatchCount[categoryId] ?? 0) + 1;
          
          // Count brand matches within category
          brandMatchCount[brandId] = (brandMatchCount[brandId] ?? 0) + 1;
          
          // Group products by category and brand
          productsByCategoryAndBrand.putIfAbsent(categoryId, () => {});
          productsByCategoryAndBrand[categoryId]!.putIfAbsent(brandId, () => []);
          productsByCategoryAndBrand[categoryId]![brandId]!.add(product);
        }
      }

      // Sort categories by match count
      final sortedCategories = categoryMatchCount.entries.toList()
        ..sort((a, b) => b.value.compareTo(a.value));

      // Build final product list with nested sorting
      final List<Product> matchingProducts = [];
      
      for (var categoryEntry in sortedCategories) {
        final categoryId = categoryEntry.key;
        final brandProducts = productsByCategoryAndBrand[categoryId]!;
        
        // Sort brands within this category by match count
        final sortedBrands = brandProducts.entries.toList()
          ..sort((a, b) => (brandMatchCount[b.key] ?? 0).compareTo(brandMatchCount[a.key] ?? 0));
        
        // Add products from each brand, sorted by match score
        for (var brandEntry in sortedBrands) {
          final products = brandEntry.value;
          products.sort((a, b) => 
            _calculateMatchScore(b.viewName, queryChars)
            .compareTo(_calculateMatchScore(a.viewName, queryChars))
          );
          matchingProducts.addAll(products);
        }
      }

      // Handle pagination
      final startIndex = (page - 1) * itemsPerPage;
      final endIndex = startIndex + itemsPerPage;
      final List<Product> pagedProducts;
      
      if (startIndex < matchingProducts.length) {
        pagedProducts = matchingProducts.sublist(
          startIndex,
          endIndex < matchingProducts.length ? endIndex : matchingProducts.length
        );
      } else {
        pagedProducts = [];
      }

      List<Category> categories = [];
      List<Brand> brands = [];

      if (page == 1) {
        final categoriesResult = await pb.collection('categories').getList(
          filter: queryChars.map((char) => 'name ~ "$char"').join(' && '),
          page: 1,
          perPage: 10,
        );
        
        // Score categories and sort by match count
        final scoredCategories = categoriesResult.items
            .map((record) => Category.fromRecord(record))
            .where((category) => queryChars.every(
              (char) => _normalizeText(category.name).contains(char)
            ))
            .map((category) => MapEntry(
              category,
              (categoryMatchCount[category.id] ?? 0) * 1000 + // Prioritize by match count
              _calculateMatchScore(category.name, queryChars)
            ))
            .toList()
          ..sort((a, b) => b.value.compareTo(a.value));
        
        categories = scoredCategories.map((e) => e.key).toList();

        final brandsResult = await pb.collection('brands').getList(
          filter: queryChars.map((char) => 'name ~ "$char"').join(' && '),
          page: 1,
          perPage: 10,
        );
        
        // Score and sort brands
        final scoredBrands = brandsResult.items
            .map((record) => Brand.fromRecord(record))
            .where((brand) => queryChars.every(
              (char) => _normalizeText(brand.name).contains(char)
            ))
            .map((brand) => MapEntry(
              brand,
              _calculateMatchScore(brand.name, queryChars)
            ))
            .toList()
          ..sort((a, b) => b.value.compareTo(a.value));
        
        brands = scoredBrands.map((e) => e.key).toList();
      }

      return SearchResult(
        products: pagedProducts,
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
