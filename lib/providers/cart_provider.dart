import 'package:flutter/foundation.dart';
import '../models/cart_item.dart';
import '../models/product.dart';
import '../services/cart_storage.dart';
import '../services/pb_service.dart';

class CartProvider with ChangeNotifier {
  final List<CartItem> _items = [];
  final CartStorage _storage = CartStorage();
  final _pbService = PocketbaseService();
  bool _initialized = false;
  // Add storage for last removed item to enable undo
  CartItem? _lastRemovedItem;
  int? _lastRemovedIndex;
  
  CartProvider() {
    _loadCartFromStorage();
    _initializeRealTimeSync();
  }
  
  // Load cart items from storage when provider is initialized
  Future<void> _loadCartFromStorage() async {
    if (_initialized) return;
    
    try {
      final loadedItems = await _storage.loadCartItems();
      if (loadedItems.isNotEmpty) {
        _items.clear();
        _items.addAll(loadedItems);
        notifyListeners();
      }
    } catch (e) {
      print('Error loading cart: $e');
    } finally {
      _initialized = true;
    }
  }
  
  // Save cart to storage whenever it changes
  Future<void> _saveCartToStorage() async {
    try {
      await _storage.saveCartItems(_items);
    } catch (e) {
      print('Error saving cart: $e');
    }
  }
  
  void _initializeRealTimeSync() async {
    try {
      final pb = await _pbService.pb;
      
      pb.collection('Products').subscribe('*', (e) async {
        try {
          switch (e.action) {
            case 'update':
              final index = _items.indexWhere((item) => item.id == e.record!.id);
              if (index != -1) {
                // Safely handle price fields
                int newPrice;
                final discountPrice = e.record!.data['discount_price'];
                final regularPrice = e.record!.data['price'];
                
                // Use discount price if available and greater than 0, otherwise use regular price
                if (discountPrice != null && discountPrice > 0) {
                  newPrice = discountPrice;
                } else {
                  newPrice = regularPrice;
                }
                
                // Update cart item if price changed
                if (_items[index].price != newPrice) {
                  _items[index].price = newPrice;
                  notifyListeners();
                  await _saveCartToStorage();
                }
              }
              break;
              
            case 'delete':
              // Remove item from cart if product is deleted
              if (_items.any((item) => item.id == e.record!.id)) {
                removeItem(e.record!.id);
              }
              break;
          }
        } catch (error) {
          print('Error processing cart real-time update: $error');
        }
      });
    } catch (e) {
      print('Error initializing cart real-time sync: $e');
    }
  }

  @override
  void dispose() {
    _pbService.pb.then((pb) => pb.collection('Products').unsubscribe());
    super.dispose();
  }
  
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

    final existingItemIndex = _items.indexWhere((item) => item.id == product.id);
    
    if (existingItemIndex >= 0) {
      // Item already exists, increase quantity
      final newQuantity = _items[existingItemIndex].quantity + quantity;
      if (newQuantity <= product.maxQuantity) {
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
          quantity: quantity,
          size: 'Default',
          unit: product.unit,
          maxQuantity: product.maxQuantity, // Add the maxQuantity here
        ),
      );
    }
    
    notifyListeners();
    _saveCartToStorage();
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
        maxQuantity: 5, // Add default maxQuantity
      ),
    );
    return item.quantity;
  }

  // Modified to store the removed item for potential undo
  CartItem removeItem(String id) {
    final index = _items.indexWhere((item) => item.id == id);
    if (index >= 0) {
      // Store the item and its position before removal
      _lastRemovedItem = _items[index];
      _lastRemovedIndex = index;
      
      // Remove the item
      final removedItem = _items.removeAt(index);
      notifyListeners();
      _saveCartToStorage(); // Save cart after changes
      return removedItem;
    }
    throw Exception('Item not found in cart');
  }

  // New method to undo last removal
  bool undoRemove() {
    if (_lastRemovedItem != null && _lastRemovedIndex != null) {
      // Insert the item back at its original position if possible
      if (_lastRemovedIndex! <= _items.length) {
        _items.insert(_lastRemovedIndex!, _lastRemovedItem!);
      } else {
        _items.add(_lastRemovedItem!);
      }
      
      // Reset the stored item
      _lastRemovedItem = null;
      _lastRemovedIndex = null;
      
      notifyListeners();
      _saveCartToStorage(); // Save cart after changes
      return true;
    }
    return false;
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
        _saveCartToStorage(); // Save cart after changes
      }
    }
  }
  
  // Method to clear the entire cart
  void clearCart() {
    _items.clear();
    _lastRemovedItem = null;
    _lastRemovedIndex = null;
    notifyListeners();
    _storage.clearCart(); // Clear stored data
  }
}
