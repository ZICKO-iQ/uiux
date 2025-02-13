import 'package:flutter/foundation.dart';
import '../models/cart_item.dart';
import '../models/product.dart';

class CartProvider with ChangeNotifier {
  final List<CartItem> _items = [];
  
  List<CartItem> get items => [..._items];
  
  int get totalAmount => _items.fold(
    0,
    (sum, item) => sum + (item.price * item.quantity).round(),
  );

  void addItem(Product product, {double? quantity}) {
    // Validate price before adding to cart
    if (product.price <= 0 && (product.discountPrice == null || product.discountPrice! <= 0)) {
      throw Exception('Cannot add item with invalid price to cart');
    }

    quantity ??= product.unit == ProductUnit.kilo ? 0.25 : 1.0;
    final double maxQuantity = 100.0;

    final existingItemIndex = _items.indexWhere((item) => item.id == product.id);
    
    if (existingItemIndex >= 0) {
      // Item already exists, increase quantity
      final newQuantity = _items[existingItemIndex].quantity + quantity;
      if (newQuantity <= maxQuantity) {
        _items[existingItemIndex].quantity = newQuantity;
      }
    } else {
      // Add new item
      _items.add(
        CartItem(
          id: product.id,
          title: product.viewName,
          price: product.discountPrice != null && product.discountPrice! > 0 
              ? product.discountPrice!
              : product.price,
          image: product.images.first,
          quantity: quantity <= maxQuantity ? quantity : maxQuantity,
          size: 'Default',
          unit: product.unit,
        ),
      );
    }
    notifyListeners();
  }

  bool hasItem(String productId) {
    return _items.any((item) => item.id == productId);
  }

  double getItemQuantity(String productId) {
    final item = _items.firstWhere(
      (item) => item.id == productId,
      orElse: () => CartItem(
        id: '',
        title: '',
        price: 0,
        image: '',
        quantity: 0,
        size: '',
        unit: ProductUnit.piece,
      ),
    );
    return item.quantity;
  }

  void removeItem(String id) {
    _items.removeWhere((item) => item.id == id);
    notifyListeners();
  }

  void updateQuantity(String id, double quantity) {
    final index = _items.indexWhere((item) => item.id == id);
    if (index >= 0) {
      final item = _items[index];
      final minQuantity = item.unit == ProductUnit.kilo ? 0.25 : 1.0;
      final maxQuantity = 100.0;
      
      // Cap the quantity at maxQuantity
      if (quantity > maxQuantity) {
        quantity = maxQuantity;
      }
      
      if (quantity >= minQuantity) {
        _items[index].quantity = quantity;
        notifyListeners();
      }
    }
  }
}
