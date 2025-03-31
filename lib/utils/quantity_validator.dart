import 'package:flutter/material.dart';
import '../providers/cart_provider.dart';
import '../models/product.dart';

class QuantityValidator {
  /// Validates and adjusts quantity based on cart contents and product limits
  /// Returns a tuple of (adjusted quantity, warning message if any)
  static (double, String?) validateQuantity({
    required String productId,
    required double requestedQuantity,
    required CartProvider cartProvider,
    required BuildContext context,
    required Product product,  // Add product parameter
  }) {
    // Use product's maxQuantity and current quantity
    final double availableQuantity = product.quantity.toDouble();
    final double maxAllowedQuantity = product.maxQuantity.toDouble();
    
    // Check for zero or negative quantity
    if (requestedQuantity <= 0) {
      return (0.0, 'Invalid quantity');
    }
    
    // Get current cart quantity if item exists
    final existingQuantity = cartProvider.hasItem(productId) 
        ? cartProvider.getItemQuantity(productId)
        : 0.0;
        
    // First check max allowed quantity per order
    final totalRequestedQuantity = existingQuantity + requestedQuantity;
    if (totalRequestedQuantity > maxAllowedQuantity) {
      if (existingQuantity >= maxAllowedQuantity) {
        return (0.0, 'Maximum limit reached (${maxAllowedQuantity.toStringAsFixed(0)} items)');
      }
      final adjustedQuantity = maxAllowedQuantity - existingQuantity;
      return (
        adjustedQuantity,
        'Maximum ${maxAllowedQuantity.toStringAsFixed(0)} items per order',
      );
    }
    
    // Then check stock availability
    if (availableQuantity == 0) {
      // Allow minimum 5 items when quantity is 0
      final minQuantity = 5.0;
      if (existingQuantity + requestedQuantity > minQuantity) {
        final adjustedQuantity = minQuantity - existingQuantity;
        return (
          adjustedQuantity,
          'The item my not be available',
        );
      }
    } else if (totalRequestedQuantity > availableQuantity) {
      final adjustedQuantity = availableQuantity - existingQuantity;
      if (adjustedQuantity <= 0) {
        return (0.0, 'Out of stock');
      }
      return (
        adjustedQuantity,
        'Only ${availableQuantity.toStringAsFixed(0)} items available',
      );
    }
    
    return (requestedQuantity, null);
  }
}
