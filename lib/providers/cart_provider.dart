import 'package:flutter/foundation.dart';
import '../models/cart_item.dart';
import '../models/product.dart';

class CartProvider with ChangeNotifier {
  final List<CartItem> _items = [];
  
  List<CartItem> get items => [..._items];
  
  int get totalAmount => _items.fold(
    0,
    (sum, item) => sum + (item.price * item.quantity),
  );

  void addItem(Product product, {int quantity = 1}) {
    // Validate price before adding to cart
    if (product.price <= 0 && (product.discountPrice == null || product.discountPrice! <= 0)) {
      throw Exception('Cannot add item with invalid price to cart');
    }

    final existingItemIndex = _items.indexWhere((item) => item.id == product.id);
    
    if (existingItemIndex >= 0) {
      // Item already exists, increase quantity
      _items[existingItemIndex].quantity += quantity;
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
          quantity: quantity,
          size: 'Default',
        ),
      );
    }
    notifyListeners();
  }

  bool hasItem(String productId) {
    return _items.any((item) => item.id == productId);
  }

  int getItemQuantity(String productId) {
    final item = _items.firstWhere(
      (item) => item.id == productId,
      orElse: () => CartItem(
        id: '',
        title: '',
        price: 0,
        image: '',
        quantity: 0,
        size: '',
      ),
    );
    return item.quantity;
  }

  void removeItem(String id) {
    _items.removeWhere((item) => item.id == id);
    notifyListeners();
  }

  void updateQuantity(String id, int quantity) {
    final index = _items.indexWhere((item) => item.id == id);
    if (index >= 0) {
      _items[index].quantity = quantity;
      notifyListeners();
    }
  }
}
