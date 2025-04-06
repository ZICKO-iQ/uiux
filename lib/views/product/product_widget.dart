import 'package:flutter/material.dart';
import 'package:uiux/models/product.dart';
import 'package:uiux/views/product/product_detail_screen.dart';
import 'package:provider/provider.dart';
import '../../core/colors.dart';
import '../../providers/cart_provider.dart';
import '../../utils/image_validator.dart';
import '../../utils/formatters.dart';  // Add this import
import '../../utils/quantity_validator.dart';  // Add this import

class BuildItemCard extends StatefulWidget {
  const BuildItemCard({
    super.key,
    required this.product,
    this.loadingDelayIndex = 0,
  });

  final Product product;
  final int loadingDelayIndex;

  @override
  State<BuildItemCard> createState() => _BuildItemCardState();
}

class _BuildItemCardState extends State<BuildItemCard> with AutomaticKeepAliveClientMixin {
  @override
  bool get wantKeepAlive => true;

  bool get _hasValidPrice => widget.product.price > 0 || 
      (widget.product.discountPrice != null && widget.product.discountPrice! > 0);

  @override
  Widget build(BuildContext context) {
    super.build(context);  // Required by AutomaticKeepAliveClientMixin

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
                  builder: (context) => ProductDetailScreen(product: widget.product),
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
                                  widget.product.brand.name,
                                  style: TextStyle(
                                    fontSize: brandFontSize * 0.85, // Made slightly smaller
                                    color: Colors.grey[600],
                                  ),
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                ),
                                const SizedBox(height: 1),
                                Text(
                                  widget.product.viewName,
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
          if (widget.product.quantity < 15) // Show circular icon for low quantity
            Positioned(
              top: 8,
              left: 8,
              child: Container(
                width: 24,
                height: 24,
                decoration: BoxDecoration(
                  color: widget.product.quantity < 1 ? Colors.red : Colors.orange, // Red for <1, Orange for <15
                  shape: BoxShape.circle,
                ),
                child: const Center(
                  child: Text(
                    '!',
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
              ),
            ),
          Positioned(
            top: 8,
            right: 8,
            child: Consumer<CartProvider>(
              builder: (context, cart, child) {
                final bool isInCart = cart.hasItem(widget.product.id);
                final double quantity = cart.getItemQuantity(widget.product.id);  // Changed from int to double

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
                          productId: widget.product.id,
                          requestedQuantity: 1.0,
                          cartProvider: cart,
                          context: context,
                          product: widget.product,  // Add this line
                        );

                        if (adjustedQuantity > 0) {
                          cart.addItem(widget.product);
                          
                          ScaffoldMessenger.of(context)
                            ..removeCurrentSnackBar()  // Changed from hideCurrentSnackBar
                            ..showSnackBar(
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
                          ScaffoldMessenger.of(context)
                            ..removeCurrentSnackBar()  // Changed from hideCurrentSnackBar
                            ..showSnackBar(
                            SnackBar(
                              content: Row(
                                children: [
                                  Icon(
                                    Icons.warning_amber_rounded,
                                    color: AppColors.warning,
                                  ),
                                  const SizedBox(width: 8),
                                  Text(
                                    warning,
                                    style: TextStyle(
                                      color: AppColors.warning,
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
                                side: BorderSide(color: AppColors.warning.withOpacity(0.3), width: 1),
                              ),
                              backgroundColor: Colors.white,
                              elevation: 4,
                              duration: const Duration(seconds: 2),
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
                                  widget.product.unit == ProductUnit.kilo
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
      mainAxisAlignment: MainAxisAlignment.start, // Changed from spaceBetween
      children: [
        if (widget.product.discountPrice != null && widget.product.discountPrice! > 0) ...[
          Text(
            AppFormatters.formatPrice(widget.product.discountPrice!), // Show IQD with discount price
            style: const TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.bold,
              color: AppColors.primary,
            ),
          ),
          const SizedBox(width: 4),
          Text(
            widget.product.price.toString(), // Hide IQD from original price
            style: TextStyle(
              fontSize: 12,
              decoration: TextDecoration.lineThrough,
              color: Colors.grey[400],
            ),
          ),
        ] else
          Text(
            AppFormatters.formatPrice(widget.product.price),
            style: const TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.bold,
              color: AppColors.primary,
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
          child: widget.product.images.isNotEmpty
              ? FutureBuilder(
                  future: Future.delayed(
                    Duration(milliseconds: widget.loadingDelayIndex * 10),
                    () => widget.product.images.first,
                  ),
                  builder: (context, snapshot) {
                    if (!snapshot.hasData) {
                      return const Center(
                        child: CircularProgressIndicator(
                          strokeWidth: 2,
                          valueColor: AlwaysStoppedAnimation<Color>(AppColors.primary),
                        ),
                      );
                    }
                    return ValidatedNetworkImage(
                      imageUrl: snapshot.data!,
                      fit: BoxFit.cover,
                    );
                  },
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
