import 'package:flutter/material.dart';
import '../models/product.dart';
import '../models/category.dart';
import '../models/brand.dart';
import 'cache_service.dart';

// Move CategoryBrandScore outside SearchService class
class CategoryBrandScore {
  final String categoryId;
  final Map<String, int> brandScores;
  final int totalScore;

  CategoryBrandScore(this.categoryId, Map<String, int> brandScores)
      : this.brandScores = Map<String, int>.from(brandScores),
        this.totalScore = brandScores.values.fold(0, (sum, count) => sum + count);
}

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
  final _cacheService = CacheService();

  String _normalizeText(String text) {
    return text.toLowerCase().replaceAll(RegExp(r'\s+'), '');
  }

  bool _containsSameCharacters(String text, String query) {
    final normalizedText = _normalizeText(text);
    final normalizedQuery = _normalizeText(query);
    
    // Check if text contains the query as a substring first
    if (normalizedText.contains(normalizedQuery)) {
      return true;
    }
    
    // If not, then check for character frequency
    final textChars = _normalizeText(text).split('')..sort();
    final queryChars = _normalizeText(query).split('')..sort();
    
    // Create character frequency maps
    final textFreq = <String, int>{};
    final queryFreq = <String, int>{};
    
    for (var char in textChars) {
      textFreq[char] = (textFreq[char] ?? 0) + 1;
    }
    
    for (var char in queryChars) {
      queryFreq[char] = (queryFreq[char] ?? 0) + 1;
    }
    
    // Check if text contains all query characters
    for (var entry in queryFreq.entries) {
      if (!textFreq.containsKey(entry.key) || textFreq[entry.key]! < entry.value) {
        return false;
      }
    }
    
    return true;
  }

  int _calculateCharacterMatchScore(String text, String query) {
    final normalizedText = _normalizeText(text);
    final queryChars = _normalizeText(query).split('').toSet();
    int score = 0;
    
    // Award points for character matches
    for (var char in queryChars) {
      if (normalizedText.contains(char)) {
        score += 10;
        // Bonus points for characters appearing in same position
        if (normalizedText.indexOf(char) == _normalizeText(query).indexOf(char)) {
          score += 5;
        }
      }
    }
    
    // Bonus for length similarity
    score += 100 - (normalizedText.length - query.length).abs();
    
    return score;
  }

  int _calculateSequenceMatchScore(String text, String query) {
    final normalizedText = _normalizeText(text);
    final normalizedQuery = _normalizeText(query);
    
    // First check for exact substring match
    if (normalizedText.contains(normalizedQuery)) {
      // Give very high score for substring matches
      int positionBonus = normalizedText.indexOf(normalizedQuery) == 0 ? 20000 : 15000;
      return positionBonus + (normalizedText.length - normalizedQuery.length) * 10;
    }
    
    // If no exact substring match, look for partial matches
    int maxScore = 0;
    List<String> textWords = normalizedText.split(' ');
    
    for (var word in textWords) {
      int currentScore = 0;
      
      // Check if word starts with query
      if (word.startsWith(normalizedQuery)) {
        currentScore = 10000;
      }
      // Check if word ends with query
      else if (word.endsWith(normalizedQuery)) {
        currentScore = 8000;
      }
      // Check if word contains query
      else if (word.contains(normalizedQuery)) {
        currentScore = 5000;
      }
      // Check for partial word match
      else {
        int matchingChars = 0;
        int consecutiveChars = 0;
        int maxConsecutive = 0;
        
        for (int i = 0; i < word.length && matchingChars < normalizedQuery.length; i++) {
          if (normalizedQuery.contains(word[i])) {
            matchingChars++;
            consecutiveChars++;
            maxConsecutive = maxConsecutive > consecutiveChars ? maxConsecutive : consecutiveChars;
          } else {
            consecutiveChars = 0;
          }
        }
        
        if (matchingChars >= (normalizedQuery.length * 0.7)) {
          currentScore = 1000 + (maxConsecutive * 100) + (matchingChars * 50);
        }
      }
      
      maxScore = maxScore > currentScore ? maxScore : currentScore;
    }
    
    return maxScore;
  }

  Map<String, int> _calculateCategoryScores(List<Product> matchingProducts) {
    final categoryScores = <String, int>{};
    
    for (var product in matchingProducts) {
      categoryScores[product.category.id] = 
          (categoryScores[product.category.id] ?? 0) + 1;
    }
    
    return categoryScores;
  }

  Future<List<String>> getSearchSuggestions(String query, {
    int limit = 5,
    Map<String, dynamic>? filters,
  }) async {
    if (query.trim().isEmpty) return [];

    try {
      if (!_cacheService.isInitialized) {
        await _cacheService.initializeCache();
      }

      final suggestions = <String>[];
      final normalizedQuery = _normalizeText(query);
      
      // Score products based on character matching
      var scoredProducts = _cacheService.products
          .where((product) => _containsSameCharacters(product.viewName, normalizedQuery))
          .map((product) => MapEntry(
            product.viewName,
            _calculateCharacterMatchScore(product.viewName, query)
          ))
          .toList()
        ..sort((a, b) => b.value.compareTo(a.value));

      suggestions.addAll(
        scoredProducts
            .map((entry) => entry.key)
            .take(limit)
      );

      // Add category and brand suggestions if there's room
      if (suggestions.length < limit) {
        final remainingLimit = limit - suggestions.length;
        
        var categories = _cacheService.categories
            .where((category) => _containsSameCharacters(category.name, normalizedQuery))
            .map((category) => "Category: ${category.name}")
            .take(remainingLimit);
        
        suggestions.addAll(categories);

        if (suggestions.length < limit) {
          var brands = _cacheService.brands
              .where((brand) => _containsSameCharacters(brand.name, normalizedQuery))
              .map((brand) => "Brand: ${brand.name}")
              .take(limit - suggestions.length);
          
          suggestions.addAll(brands);
        }
      }

      return suggestions;
    } catch (e) {
      throw Exception('Failed to get search suggestions: $e');
    }
  }

  Map<String, CategoryBrandScore> _calculateHierarchicalScores(List<Product> matchingProducts) {
    try {
      final scores = <String, CategoryBrandScore>{};
      
      for (var product in matchingProducts) {
        final categoryId = product.category.id;
        final brandId = product.brand.id;
        
        if (!scores.containsKey(categoryId)) {
          scores[categoryId] = CategoryBrandScore(categoryId, {});
        }
        
        var brandScores = scores[categoryId]!.brandScores;
        brandScores[brandId] = (brandScores[brandId] ?? 0) + 1;
        
        // Create a new CategoryBrandScore instance with updated scores
        scores[categoryId] = CategoryBrandScore(categoryId, brandScores);
      }
      
      return scores;
    } catch (e) {
      print('Error calculating hierarchical scores: $e');
      return {};
    }
  }

  bool _hasPartialMatch(String text, String query, double threshold) {
    final textChars = _normalizeText(text).split('').toSet();
    final queryChars = _normalizeText(query).split('').toSet();
    
    int matchCount = 0;
    for (var char in queryChars) {
      if (textChars.contains(char)) {
        matchCount++;
      }
    }
    
    return (matchCount / queryChars.length) >= threshold;
  }

  List<Product> _getFallbackResults(
    List<Product> products,
    String query,
    {double threshold = 0.6}
  ) {
    final scoredProducts = products.map((product) {
      final textChars = _normalizeText(product.viewName).split('').toSet();
      final queryChars = _normalizeText(query).split('').toSet();
      
      int matchCount = queryChars
          .where((char) => textChars.contains(char))
          .length;
      
      double matchPercentage = matchCount / queryChars.length;
      
      if (matchPercentage >= threshold) {
        // Combine different scoring methods with weighted importance
        int charMatchScore = _calculateCharacterMatchScore(product.viewName, query);
        int sequenceScore = _calculateSequenceMatchScore(product.viewName, query);
        int finalScore = sequenceScore * 2 + charMatchScore; // Prioritize sequence matches
        
        return MapEntry(product, finalScore);
      }
      return null;
    })
    .whereType<MapEntry<Product, int>>()
    .toList()
    ..sort((a, b) => b.value.compareTo(a.value));

    return scoredProducts.map((e) => e.key).toList();
  }

  bool _isPartialMatch(String text, String query) {
    final normalizedText = _normalizeText(text);
    final normalizedQuery = _normalizeText(query);
    
    // Check direct substring match first
    if (normalizedText.contains(normalizedQuery)) {
      return true;
    }

    // Split text into words and check each word for partial matches
    final words = normalizedText.split(' ');
    for (var word in words) {
      if (word.contains(normalizedQuery) || normalizedQuery.contains(word)) {
        return true;
      }
    }

    return false;
  }

  Future<SearchResult> search(
    String query, {
    required int page,
    required int itemsPerPage,
    String? sortBy,
    Map<String, dynamic>? filters,
  }) async {
    try {
      if (!_cacheService.isInitialized) {
        await _cacheService.initializeCache();
      }

      final normalizedQuery = _normalizeText(query);

      // First pass: Look for exact and partial matches
      var filteredProducts = _cacheService.products.where((product) {
        if (filters != null && filters.isNotEmpty) {
          if (filters['category'] != null && product.category.id != filters['category']) {
            return false;
          }
          if (filters['brand'] != null && product.brand.id != filters['brand']) {
            return false;
          }
          if (filters['price_range'] != null && filters['price_range'] is RangeValues) {
            final range = filters['price_range'] as RangeValues;
            if (product.price < range.start || product.price > range.end) {
              return false;
            }
          }
        }
        
        return _isPartialMatch(product.viewName, query);
      }).toList();

      // If no matches found, try fallback with character matching
      if (filteredProducts.isEmpty) {
        filteredProducts = _getFallbackResults(
          _cacheService.products.where((product) {
            if (filters != null && filters.isNotEmpty) {
              if (filters['category'] != null && product.category.id != filters['category']) {
                return false;
              }
              if (filters['brand'] != null && product.brand.id != filters['brand']) {
                return false;
              }
              if (filters['price_range'] != null && filters['price_range'] is RangeValues) {
                final range = filters['price_range'] as RangeValues;
                return product.price >= range.start && product.price <= range.end;
              }
            }
            return true;
          }).toList(),
          query,
          threshold: 0.6
        );
      }

      // Score and sort all matching products
      var scoredProducts = filteredProducts.map((product) {
        int score = 0;
        final normalizedName = _normalizeText(product.viewName);
        
        // Highest score for exact matches
        if (normalizedName == normalizedQuery) {
          score += 100000;
        }
        // High score for containing the full query
        else if (normalizedName.contains(normalizedQuery)) {
          score += 50000;
        }
        // Medium score for query containing the word
        else if (normalizedQuery.contains(normalizedName)) {
          score += 25000;
        }
        
        // Add sequence and character match scores
        score += _calculateSequenceMatchScore(product.viewName, query);
        score += _calculateCharacterMatchScore(product.viewName, query);
        
        return MapEntry(product, score);
      }).toList()
        ..sort((a, b) => b.value.compareTo(a.value));

      filteredProducts = scoredProducts.map((e) => e.key).toList();

      // Calculate hierarchical scores
      final hierarchicalScores = _calculateHierarchicalScores(filteredProducts);

      // Score products and organize by category and brand
      var organizedProducts = <Product>[];
      var matchingCategories = <Category>[];
      var matchingBrands = <Brand>[];

      if (hierarchicalScores.isNotEmpty) {
        // Sort categories by total matching products
        var sortedCategories = hierarchicalScores.entries.toList()
          ..sort((a, b) => b.value.totalScore.compareTo(a.value.totalScore));

        for (var categoryEntry in sortedCategories) {
          try {
            final category = _cacheService.categories
                .firstWhere((c) => c.id == categoryEntry.key);
            
            // Sort brands within this category by their match counts
            var sortedBrands = categoryEntry.value.brandScores.entries.toList()
              ..sort((a, b) => b.value.compareTo(a.value));

            // Add category to results if on first page
            if (page == 1) {
              matchingCategories.add(category);
            }

            // Add products organized by category and brand
            for (var brandEntry in sortedBrands) {
              final brand = _cacheService.brands
                  .firstWhere((b) => b.id == brandEntry.key);
              
              // Add brand to results if on first page
              if (page == 1 && !matchingBrands.contains(brand)) {
                matchingBrands.add(brand);
              }

              // Add products for this category-brand combination
              var categoryBrandProducts = filteredProducts
                  .where((p) => 
                      p.category.id == category.id && 
                      p.brand.id == brand.id)
                  .toList()
                ..sort((a, b) => 
                    _calculateCharacterMatchScore(b.viewName, query)
                    .compareTo(_calculateCharacterMatchScore(a.viewName, query)));
              
              organizedProducts.addAll(categoryBrandProducts);
            }
          } catch (e) {
            print('Error processing category ${categoryEntry.key}: $e');
            continue;
          }
        }
      }

      // Handle pagination
      final startIndex = (page - 1) * itemsPerPage;
      final List<Product> pagedProducts = startIndex < organizedProducts.length
          ? organizedProducts
              .skip(startIndex)
              .take(itemsPerPage)
              .toList()
          : [];

      return SearchResult(
        products: pagedProducts,
        categories: matchingCategories,
        brands: matchingBrands,
      );
    } catch (e) {
      throw Exception('Failed to perform search: $e');
    }
  }
}
