import '../models/product.dart';
import '../models/category.dart';
import '../models/brand.dart';
import 'pb_service.dart';

class CacheService {
  static final CacheService _instance = CacheService._internal();
  factory CacheService() => _instance;
  CacheService._internal();

  final _pbService = PocketbaseService();
  List<Product> _products = [];
  List<Category> _categories = [];
  List<Brand> _brands = [];
  bool _isInitialized = false;

  List<Product> get products => _products;
  List<Category> get categories => _categories;
  List<Brand> get brands => _brands;
  bool get isInitialized => _isInitialized;

  Future<void> initializeCache() async {
    if (_isInitialized) return;

    try {
      final pb = await _pbService.pb;

      // Fetch all products with expanded relationships
      final productsResult = await pb.collection('Products').getFullList(
        expand: 'category_id,brand_id',
      );
      _products = await Future.wait(
        productsResult.map((record) => Product.fromRecord(record))
      );

      // Fetch all categories
      final categoriesResult = await pb.collection('categories').getFullList();
      _categories = categoriesResult.map((record) => Category.fromRecord(record)).toList();

      // Fetch all brands
      final brandsResult = await pb.collection('brands').getFullList();
      _brands = brandsResult.map((record) => Brand.fromRecord(record)).toList();

      _isInitialized = true;
    } catch (e) {
      print('Cache initialization failed: $e');
      throw Exception('Failed to initialize cache: $e');
    }
  }

  Future<void> refreshCache() async {
    _isInitialized = false;
    await initializeCache();
  }

  void updateProduct(Product product) {
    final index = _products.indexWhere((p) => p.id == product.id);
    if (index != -1) {
      _products[index] = product;
    } else {
      _products.add(product);
    }
  }

  void removeProduct(String productId) {
    _products.removeWhere((p) => p.id == productId);
  }
}
