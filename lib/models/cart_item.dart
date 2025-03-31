import 'product.dart';

class CartItem {
  final String id;
  final String title;
  int price; // Change from final to allow updates
  final String image;
  double quantity;
  final String size;
  final ProductUnit unit;
  final int maxQuantity; // Add this field

  CartItem({
    required this.id,
    required this.title,
    required this.price,
    required this.image,
    required this.quantity,
    required this.size,
    required this.unit,
    required this.maxQuantity, // Add this parameter
  });

  factory CartItem.fromProduct(Product product) {
    if (product.price == 0) {
      throw Exception('Cannot add product with no price to cart');
    }
    
    return CartItem(
      id: product.id,
      title: product.viewName,
      price: product.discountPrice != null && product.discountPrice! > 0
          ? product.discountPrice!
          : product.price,
      image: product.images.first,
      quantity: product.unit == ProductUnit.kilo ? 0.25 : 1,  // Default quantity based on unit
      size: 'Default',
      unit: product.unit,
      maxQuantity: product.maxQuantity, // Add this parameter
    );
  }

  get name => null;

  get product => null;

  get viewName => null;
}
