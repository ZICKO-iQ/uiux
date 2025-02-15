import 'package:flutter/material.dart';
import '../providers/cart_provider.dart';

class QuantityValidator {
  /// Default maximum quantity if none is specified
  static const double defaultMaxQuantity = 100.0;

  /// Validates and adjusts quantity based on cart contents
  /// Returns a tuple of (adjusted quantity, warning message if any)
  static (double, String?) validateQuantity({
    required String productId,
    required double requestedQuantity,
    required CartProvider cartProvider,
    required BuildContext context,
    double? maxQuantity,
  }) {
    final double effectiveMaxQuantity = maxQuantity ?? defaultMaxQuantity;
    final String maxQuantityDisplay = effectiveMaxQuantity.toStringAsFixed(0);
    
    // Check for zero or negative quantity
    if (requestedQuantity <= 0) {
      return (0.0, 'Maximum quantity is $maxQuantityDisplay');
    }
    
    // Get current cart quantity if item exists
    final existingQuantity = cartProvider.hasItem(productId) 
        ? cartProvider.getItemQuantity(productId)
        : 0.0;
    
    // Check if new total would exceed maximum
    if (existingQuantity + requestedQuantity > effectiveMaxQuantity) {
      final adjustedQuantity = effectiveMaxQuantity - existingQuantity;
      return (
        adjustedQuantity,
        'Maximum quantity is $maxQuantityDisplay',
      );
    }
    
    return (requestedQuantity, null);
  }
}
