import 'package:flutter/material.dart';
import '../services/pb_service.dart';
import '../models/product.dart';
import '../models/category.dart';

class ProductProvider extends ChangeNotifier {
  final _pb = PocketbaseService().pb;
  List<Product> _products = [];
  List<Product> get products => _products;
  
  List<Category> _categories = [];
  List<Category> get categories => _categories;

  bool _isLoading = false;
  String? _error;
  
  bool get isLoading => _isLoading;
  String? get error => _error;

  Future<void> loadProducts() async {
    _isLoading = true;
    _error = null;
    notifyListeners();

    try {
      final response = await _pb.collection('Products').getFullList(expand: 'category_id');
      _products = await Future.wait(
        response.map((record) => Product.fromRecord(record))
      );
      
      final categoryResponse = await _pb.collection('Categories').getFullList();
      _categories = categoryResponse.map((record) => Category.fromRecord(record)).toList();
      
      notifyListeners();
      
      _pb.collection('Products').subscribe('*', (e) async {
        switch (e.action) {
          case 'create':
            final newProduct = await Product.fromRecord(e.record!);
            _products.add(newProduct);
            break;
          case 'update':
            final index = _products.indexWhere((p) => p.id == e.record!.id);
            if (index != -1) {
              final updatedProduct = await Product.fromRecord(e.record!);
              _products[index] = updatedProduct;
            }
            break;
          case 'delete':
            _products.removeWhere((p) => p.id == e.record!.id);
            break;
        }
        notifyListeners();
      });
    } catch (e) {
      _error = e.toString();
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  @override
  void dispose() {
    _pb.collection('Products').unsubscribe();
    super.dispose();
  }
}