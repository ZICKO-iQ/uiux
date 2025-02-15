import 'package:flutter/material.dart';
import 'package:uiux/models/product.dart';
import 'package:uiux/views/product/product_detail_screen.dart';
import 'package:provider/provider.dart';
import '../../core/colors.dart';
import '../../providers/cart_provider.dart';
import '../../utils/image_validator.dart';
import '../../utils/formatters.dart';  // Add this import
import '../../utils/quantity_validator.dart';  // Add this import

class BuildItemCard extends StatelessWidget {
  const BuildItemCard({
    super.key,
    required this.product,
  });

  final Product product;

  bool get _hasValidPrice => product.price > 0 || 
      (product.discountPrice != null && product.discountPrice! > 0);

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 4, vertical: 4),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.08),
            blurRadius: 12,
            spreadRadius: 2,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Stack(
        children: [
          Material(
            color: Colors.transparent,
            child: InkWell(
              borderRadius: BorderRadius.circular(16),
              onTap: () => Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (context) => ProductDetailScreen(product: product),
                ),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  _buildImageSection(),
                  Expanded(
                    child: Padding(
                      padding: const EdgeInsets.all(8),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            product.brand.name,  // Changed from product.brand to product.brand.name
                            style: TextStyle(
                              fontSize: 12,
                              color: Colors.grey[600],
                            ),
                          ),
                          const SizedBox(height: 4),
                          Text(
                            product.viewName,
                            style: const TextStyle(
                              fontSize: 14,
                              fontWeight: FontWeight.w600,
                            ),
                            maxLines: 2,
                            overflow: TextOverflow.ellipsis,
                          ),
                          const Spacer(),
                          _buildPriceSection(),
                        ],
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
          Positioned(
            top: 8,
            right: 8,
            child: Consumer<CartProvider>(
              builder: (context, cart, child) {
                final bool isInCart = cart.hasItem(product.id);
                final double quantity = cart.getItemQuantity(product.id);  // Changed from int to double

                return Container(
                  decoration: BoxDecoration(
                    color: _hasValidPrice ? AppColors.primary : Colors.grey,
                    borderRadius: BorderRadius.circular(8),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withOpacity(0.1),
                        blurRadius: 8,
                        offset: const Offset(0, 2),
                      ),
                    ],
                  ),
                  child: Material(
                    color: Colors.transparent,
                    child: InkWell(
                      borderRadius: BorderRadius.circular(8),
                      onTap: _hasValidPrice ? () {
                        final (adjustedQuantity, warning) = QuantityValidator.validateQuantity(
                          productId: product.id,
                          requestedQuantity: 1.0,
                          cartProvider: cart,
                          context: context,
                        );

                        if (adjustedQuantity > 0) {
                          cart.addItem(product);
                          
                          ScaffoldMessenger.of(context).hideCurrentSnackBar();
                          ScaffoldMessenger.of(context).showSnackBar(
                            SnackBar(
                              content: Text(
                                warning ?? (isInCart ? 'Increased quantity in cart' : 'Added to cart')
                              ),
                              duration: const Duration(milliseconds: 500),
                              behavior: SnackBarBehavior.floating,
                              margin: const EdgeInsets.all(8),
                              backgroundColor: warning != null ? AppColors.warning : AppColors.primary,
                            ),
                          );
                        } else if (warning != null) {
                          ScaffoldMessenger.of(context).hideCurrentSnackBar();
                          ScaffoldMessenger.of(context).showSnackBar(
                            SnackBar(
                              content: Text(warning),
                              duration: const Duration(milliseconds: 1000),
                              behavior: SnackBarBehavior.floating,
                              margin: const EdgeInsets.all(8),
                              backgroundColor: AppColors.warning,
                            ),
                          );
                        }
                      } : null,
                      child: Padding(
                        padding: const EdgeInsets.all(6),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Icon(
                              _hasValidPrice
                                ? (isInCart ? Icons.shopping_cart : Icons.add_shopping_cart_rounded)
                                : Icons.money_off,
                              color: Colors.white,
                              size: 20,
                            ),
                            if (isInCart && _hasValidPrice) ...[
                              const SizedBox(width: 4),
                              Text(
                                AppFormatters.formatQuantity(
                                  quantity,
                                  product.unit == ProductUnit.kilo
                                ),
                                style: const TextStyle(
                                  color: Colors.white,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                            ],
                          ],
                        ),
                      ),
                    ),
                  ),
                );
              },
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildPriceSection() {
    // Don't show price section if price is 0
    if (product.price == 0) {
      return const Text(
        'Price not available',
        style: TextStyle(
          fontSize: 14,
          color: Colors.grey,
          fontStyle: FontStyle.italic,
        ),
      );
    }

    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        if (product.discountPrice != null && product.discountPrice! > 0) ...[
          Text(
            AppFormatters.formatPrice(product.discountPrice!),
            style: const TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.bold,
              color: AppColors.primary,
            ),
          ),
          Text(
            AppFormatters.formatPrice(product.price),
            style: TextStyle(
              fontSize: 13,
              decoration: TextDecoration.lineThrough,
              color: Colors.grey[400],
            ),
          ),
        ] else
          Text(
            AppFormatters.formatPrice(product.price),
            style: const TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.bold,
              color: AppColors.primary,
            ),
          ),
      ],
    );
  }

  Widget _buildImageSection() {
    return Container(
      height: 150,
      decoration: BoxDecoration(
        borderRadius: const BorderRadius.vertical(top: Radius.circular(16)),
      ),
      child: ClipRRect(
        borderRadius: const BorderRadius.vertical(top: Radius.circular(16)),
        child: Center(
          child: product.images.isNotEmpty
              ? ValidatedNetworkImage(
                  imageUrl: product.images.first,
                  fit: BoxFit.contain,
                )
              : Image.asset(
                  'assets/images/placeholder.png',
                  fit: BoxFit.contain,
                ),
        ),
      ),
    );
  }
}
