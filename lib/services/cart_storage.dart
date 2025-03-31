import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';
import '../models/cart_item.dart';
import '../models/product.dart';

class CartStorage {
  static const String _cartKey = 'shopping_cart_items';
  
  // Save cart items to SharedPreferences
  Future<bool> saveCartItems(List<CartItem> items) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final List<Map<String, dynamic>> serializedItems = items.map((item) {
        return {
          'id': item.id,
          'title': item.title,
          'price': item.price,
          'image': item.image,
          'quantity': item.quantity,
          'size': item.size,
          'unit': item.unit.index, // Save enum as index
          'maxQuantity': item.maxQuantity, // Add this line
        };
      }).toList();
      
      final String jsonData = jsonEncode(serializedItems);
      return await prefs.setString(_cartKey, jsonData);
    } catch (e) {
      print('Error saving cart data: $e');
      return false;
    }
  }
  
  // Load cart items from SharedPreferences
  Future<List<CartItem>> loadCartItems() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final String? jsonData = prefs.getString(_cartKey);
      
      if (jsonData == null || jsonData.isEmpty) {
        return [];
      }
      
      final List<dynamic> decodedData = jsonDecode(jsonData);
      
      return decodedData.map<CartItem>((item) {
        return CartItem(
          id: item['id'],
          title: item['title'],
          price: item['price'],
          image: item['image'],
          quantity: item['quantity'].toDouble(),
          size: item['size'],
          unit: ProductUnit.values[item['unit']], // Convert index back to enum
          maxQuantity: item['maxQuantity'] ?? 5, // Add this line with default value
        );
      }).toList();
    } catch (e) {
      print('Error loading cart data: $e');
      return [];
    }
  }
  
  // Clear all cart items
  Future<bool> clearCart() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      return await prefs.remove(_cartKey);
    } catch (e) {
      print('Error clearing cart data: $e');
      return false;
    }
  }
}
