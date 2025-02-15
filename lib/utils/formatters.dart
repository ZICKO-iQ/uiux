import 'package:intl/intl.dart';
import '../models/product.dart';

class AppFormatters {
  static final NumberFormat currencyFormatter = NumberFormat.currency(
    symbol: 'IQD ',
    decimalDigits: 0,
  );

  /// Formats a price to currency format (e.g., "$1,234")
  static String formatPrice(num price) {
    return currencyFormatter.format(price);
  }

  /// Formats a price with unit (e.g., "$1,234/kg" or "$1,234/piece")
  static String formatPriceWithUnit(num price, ProductUnit unit) {
    String formattedPrice = currencyFormatter.format(price);
    return unit == ProductUnit.kilo ? '$formattedPrice/kg' : '$formattedPrice/piece';
  }

  /// Formats quantity based on unit type
  /// For kilos: shows decimals (e.g., "1.25")
  /// For pieces: shows whole numbers (e.g., "1")
  static String formatQuantity(double quantity, bool isKilo) {
    if (isKilo) {
      return quantity.toStringAsFixed(2).replaceAll(RegExp(r'\.?0*$'), '');
    }
    return quantity.toInt().toString();
  }

  /// Formats quantity with unit (e.g., "1.25 kg" or "1 piece")
  static String formatQuantityWithUnit(double quantity, ProductUnit unit) {
    String formattedQuantity = formatQuantity(quantity, unit == ProductUnit.kilo);
    return unit == ProductUnit.kilo ? '$formattedQuantity kg' : '$formattedQuantity piece';
  }

  /// Constants for quantity constraints
  static const double minKiloQuantity = 0.25;
  static const double minPieceQuantity = 1.0;
  static const double maxQuantity = 100.0;
  static const double kiloStep = 0.25;
  static const double pieceStep = 1.0;

  /// Gets the minimum quantity based on unit type
  static double getMinQuantity(ProductUnit unit) {
    return unit == ProductUnit.kilo ? minKiloQuantity : minPieceQuantity;
  }

  /// Gets the quantity step based on unit type
  static double getQuantityStep(ProductUnit unit) {
    return unit == ProductUnit.kilo ? kiloStep : pieceStep;
  }

  /// Rounds quantity to nearest step based on unit
  static double roundQuantity(double quantity, ProductUnit unit) {
    if (unit == ProductUnit.kilo) {
      return (quantity / kiloStep).round() * kiloStep;
    }
    return quantity.roundToDouble();
  }
}
