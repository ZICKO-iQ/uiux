import 'product.dart';

class CartItem {
  final String id;
  final String title;
  final int price;
  final String image;
  int quantity;
  final String size;

  CartItem({
    required this.id,
    required this.title,
    required this.price,
    required this.image,
    required this.quantity,
    required this.size,
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
      quantity: 1,
      size: 'Default',
    );
  }
}
