import 'package:flutter/material.dart';
import '../services/pb_service.dart';
import '../models/category.dart';

class CategoryProvider extends ChangeNotifier {
  final _pb = PocketbaseService().pb;
  List<Category> _categories = [];
  List<Category> get categories => _categories;

  Future<void> loadCategories() async {
    try {
      final response = await _pb.collection('Categories').getFullList();
      _categories = response.map((record) => Category.fromRecord(record)).toList();
      notifyListeners();
    } catch (e) {
      print('Error: $e');
    }
  }

  @override
  void dispose() {
    _pb.collection('Categories').unsubscribe();
    super.dispose();
  }
}
