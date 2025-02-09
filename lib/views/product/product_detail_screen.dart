import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:carousel_slider/carousel_slider.dart';
import 'package:uiux/core/colors.dart';
import 'package:uiux/models/product.dart';
import 'package:uiux/providers/cart_provider.dart';
import 'package:uiux/views/shared/app_bar.dart';
import 'package:intl/intl.dart';
import '../../utils/image_validation.dart';

class ProductDetailScreen extends StatefulWidget {
  final Product product;

  const ProductDetailScreen({
    super.key,
    required this.product,
  });

  @override
  State<ProductDetailScreen> createState() => _ProductDetailScreenState();
}

class _ProductDetailScreenState extends State<ProductDetailScreen> {
  int _quantity = 1;
  int _selectedImageIndex = 0;
  final NumberFormat _currencyFormatter = NumberFormat.currency(
    symbol: '\$',
    decimalDigits: 0, // Set to 0 to remove decimal places
  );

  String _formatPrice(dynamic price) {
    if (price == null) return '';
    return _currencyFormatter.format(price.toInt()); // Convert to int instead of double
  }

  Widget _buildImageCarousel() {
    if (widget.product.images.isEmpty) {
      return Container(
        height: 300,
        color: Colors.grey[200],
        child: const Center(
          child: Icon(Icons.image_not_supported, size: 50, color: Colors.grey),
        ),
      );
    }

    return Stack(
      children: [
        CarouselSlider(
          options: CarouselOptions(
            height: 300,
            viewportFraction: 1,
            onPageChanged: (index, reason) {
              setState(() => _selectedImageIndex = index);
            },
          ),
          items: widget.product.images.map((imageUrl) {
            return ValidatedNetworkImage(
              imageUrl: imageUrl,
              fit: BoxFit.fitHeight,
              width: double.infinity,
            );
          }).toList(),
        ),
        Positioned(
          bottom: 16,
          left: 0,
          right: 0,
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: widget.product.images.asMap().entries.map((entry) {
              return Container(
                width: 8,
                height: 8,
                margin: const EdgeInsets.symmetric(horizontal: 4),
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: _selectedImageIndex == entry.key
                      ? AppColors.primary
                      : Colors.grey.withOpacity(0.5),
                ),
              );
            }).toList(),
          ),
        ),
      ],
    );
  }

  @override
  Widget build(BuildContext context) {
    final bool hasDiscount = widget.product.discountPrice != null && 
                           widget.product.discountPrice! > 0 && 
                           widget.product.discountPrice! < widget.product.price;
    
    return Scaffold(
      backgroundColor: AppColors.bgWhite,
      appBar: CustomAppBar(title: widget.product.viewName),
      floatingActionButton: Consumer<CartProvider>(
        builder: (context, cart, child) {
          final bool isInCart = cart.hasItem(widget.product.id);
          
          return FloatingActionButton.extended(
            onPressed: () {
              try {
                cart.addItem(widget.product, quantity: _quantity);
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(
                    content: Text(
                      isInCart 
                        ? 'Updated quantity in cart' 
                        : 'Added $_quantity item(s) to cart'
                    ),
                    duration: const Duration(milliseconds: 500),
                    behavior: SnackBarBehavior.floating,
                    margin: const EdgeInsets.all(8),
                  ),
                );
              } catch (e) {
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(
                    content: Text('Failed to add item to cart'),
                    backgroundColor: Colors.red,
                  ),
                );
              }
            },
            backgroundColor: AppColors.primary,
            icon: Icon(
              isInCart ? Icons.shopping_cart : Icons.add_shopping_cart,
              color: Colors.white,
            ),
            label: Text(
              isInCart ? 'Update Cart' : 'Add to Cart',
              style: const TextStyle(
                color: Colors.white,
                fontSize: 16,
                fontWeight: FontWeight.bold,
              ),
            ),
          );
        },
      ),
      body: ListView(
        children: [
          _buildImageCarousel(),
          Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Brand and Rating
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      widget.product.brand,
                      style: TextStyle(
                        color: Colors.grey[600],
                        fontSize: 16,
                      ),
                    ),
                    Row(
                      children: [
                        const Icon(Icons.star, color: Colors.amber, size: 20),
                        const Text('4.5 '),
                        Text(
                          '(2.5k reviews)',
                          style: TextStyle(color: Colors.grey[600]),
                        ),
                      ],
                    ),
                  ],
                ),

                const SizedBox(height: 8),
                
                // Product Name
                Text(
                  widget.product.viewName,
                  style: const TextStyle(
                    fontSize: 24,
                    fontWeight: FontWeight.bold,
                  ),
                ),

                const SizedBox(height: 16),

                // Price Section
                Row(
                  children: [
                    if (hasDiscount) ...[
                      Text(
                        _formatPrice(widget.product.discountPrice!),
                        style: const TextStyle(
                          fontSize: 28,
                          fontWeight: FontWeight.bold,
                          color: AppColors.primary,
                        ),
                      ),
                      const SizedBox(width: 16),
                      Text(
                        _formatPrice(widget.product.price),
                        style: const TextStyle(
                          fontSize: 18,
                          decoration: TextDecoration.lineThrough,
                          color: Colors.grey,
                        ),
                      ),
                      const SizedBox(width: 8),
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 8,
                          vertical: 4,
                        ),
                        decoration: BoxDecoration(
                          color: AppColors.primary.withOpacity(0.1),
                          borderRadius: BorderRadius.circular(4),
                        ),
                        child: Text(
                          '${(((widget.product.price - widget.product.discountPrice!) / widget.product.price) * 100).round()}% OFF',
                          style: const TextStyle(
                            color: AppColors.primary,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                    ] else ...[
                      Text(
                        _formatPrice(widget.product.price),
                        style: const TextStyle(
                          fontSize: 28,
                          fontWeight: FontWeight.bold,
                          color: AppColors.primary,
                        ),
                      ),
                    ],
                  ],
                ),

                const SizedBox(height: 24),

                // Quantity Selector
                Row(
                  children: [
                    const Text(
                      'Quantity:',
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(width: 16),
                    Container(
                      decoration: BoxDecoration(
                        border: Border.all(color: Colors.grey),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Row(
                        children: [
                          IconButton(
                            icon: const Icon(Icons.remove),
                            onPressed: _quantity <= 1 
                                ? null // Disable button when quantity is 1
                                : () => setState(() => _quantity--),
                            style: IconButton.styleFrom(
                              foregroundColor: _quantity <= 1 
                                  ? Colors.grey 
                                  : null,
                            ),
                          ),
                          Text(
                            '$_quantity',
                            style: const TextStyle(fontSize: 16),
                          ),
                          IconButton(
                            icon: const Icon(Icons.add),
                            onPressed: () => setState(() => _quantity++),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),

                const SizedBox(height: 24),

                // Delivery Info
                Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: Colors.grey[100],
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Row(
                        children: [
                          Icon(Icons.local_shipping_outlined),
                          SizedBox(width: 8),
                          Text(
                            'Delivery Information',
                            style: TextStyle(
                              fontWeight: FontWeight.bold,
                              fontSize: 16,
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 8),
                      Text(
                        'Free delivery for orders above \$50',
                        style: TextStyle(color: Colors.grey[600]),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        'Estimated delivery: 2-4 business days',
                        style: TextStyle(color: Colors.grey[600]),
                      ),
                    ],
                  ),
                ),

                const SizedBox(height: 24),

                // Description
                const Text(
                  'Description',
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  widget.product.description,
                  style: TextStyle(
                    color: Colors.grey[700],
                    height: 1.5,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
