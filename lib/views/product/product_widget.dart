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
    final screenWidth = MediaQuery.of(context).size.width;
    final isLandscape = MediaQuery.of(context).orientation == Orientation.landscape;
    final imageHeight = isLandscape 
        ? (screenWidth / 3) * 0.5  // Changed from 4 to 3 columns, and 0.6 to 0.5
        : (screenWidth / 2) * 0.6;

    // Calculate font sizes based on orientation
    final brandFontSize = isLandscape ? screenWidth * 0.02 : screenWidth * 0.028;
    final nameFontSize = isLandscape ? screenWidth * 0.022 : screenWidth * 0.032;

    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 2, vertical: 2), // Reduced margin
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12), // Smaller radius
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.06), // Lighter shadow
            blurRadius: 8,
            spreadRadius: 1,
            offset: const Offset(0, 2),
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
                  SizedBox(
                    height: imageHeight,
                    child: _buildImageSection(),
                  ),
                  Expanded(
                    child: Padding(
                      padding: const EdgeInsets.all(6), // Reduced padding
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        mainAxisAlignment: MainAxisAlignment.spaceBetween, // Change this
                        children: [
                          Flexible(  // Add Flexible here
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                Text(
                                  product.brand.name,
                                  style: TextStyle(
                                    fontSize: brandFontSize * 0.85, // Made slightly smaller
                                    color: Colors.grey[600],
                                  ),
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                ),
                                const SizedBox(height: 1),
                                Text(
                                  product.viewName,
                                  style: TextStyle(
                                    fontSize: nameFontSize * 1.1, // Made slightly bigger
                                    fontWeight: FontWeight.w500, // Less bold
                                    height: 1.2, // Added line height
                                  ),
                                  maxLines: 1, // Changed from 2 to 1
                                  overflow: TextOverflow.ellipsis,
                                ),
                              ],
                            ),
                          ),
                          const SizedBox(height: 2),  // Reduced spacing
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
                              content: Row(
                                children: [
                                  Icon(
                                    Icons.check_circle_outline,
                                    color: AppColors.primary,
                                  ),
                                  const SizedBox(width: 8),
                                  Text(
                                    'Added to cart',
                                    style: TextStyle(
                                      color: AppColors.primary,
                                      fontWeight: FontWeight.w500,
                                    ),
                                  ),
                                ],
                              ),
                              behavior: SnackBarBehavior.floating,
                              margin: const EdgeInsets.all(10),
                              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(8),
                                side: BorderSide(color: AppColors.primary.withOpacity(0.3), width: 1),
                              ),
                              backgroundColor: Colors.white,
                              elevation: 4,
                              duration: const Duration(seconds: 1),
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
    if (!_hasValidPrice) {
      return const Text(
        'Price not available',
        style: TextStyle(
          fontSize: 12,
          color: Colors.grey,
          fontStyle: FontStyle.italic,
        ),
        maxLines: 1,
        overflow: TextOverflow.ellipsis,
      );
    }

    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      mainAxisSize: MainAxisSize.min,  // Add this
      children: [
        if (product.discountPrice != null && product.discountPrice! > 0) ...[
          Flexible(
            child: Text(
              AppFormatters.formatPrice(product.discountPrice!),
              style: const TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.bold,
                color: AppColors.primary,
              ),
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
          ),
          const SizedBox(width: 4),
          Flexible(
            child: Text(
              AppFormatters.formatPrice(product.price),
              style: TextStyle(
                fontSize: 12,
                decoration: TextDecoration.lineThrough,
                color: Colors.grey[400],
              ),
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
          ),
        ] else
          Flexible(
            child: Text(
              AppFormatters.formatPrice(product.price),
              style: const TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.bold,
                color: AppColors.primary,
              ),
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
          ),
      ],
    );
  }

  Widget _buildImageSection() {
    return Container(
      decoration: const BoxDecoration(
        borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
      ),
      child: ClipRRect(
        borderRadius: const BorderRadius.vertical(top: Radius.circular(16)),
        child: Center(
          child: product.images.isNotEmpty
              ? ValidatedNetworkImage(
                  imageUrl: product.images.first,
                  fit: BoxFit.cover,
                )
              : Image.asset(
                  'assets/images/placeholder.png',
                  fit: BoxFit.cover,
                ),
        ),
      ),
    );
  }
}
