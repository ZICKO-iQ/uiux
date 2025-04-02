import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:carousel_slider/carousel_slider.dart';
import '../../core/colors.dart';
import '../../models/product.dart';
import '../../providers/cart_provider.dart';
import '../../utils/formatters.dart'; // Add this import
import '../shared/app_bar.dart';
import '../../utils/image_validator.dart';
import '../../utils/quantity_validator.dart'; // Add this import
import '../../providers/product_provider.dart';

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
  double _quantity = 1.0; // Initialize with a default value
  int _selectedImageIndex = 0;
  late TextEditingController _quantityController;
  late Product _currentProduct;

  @override
  void initState() {
    super.initState();
    _currentProduct = widget.product;
    // Initialize quantity based on product unit
    _quantity = AppFormatters.getMinQuantity(_currentProduct.unit);
    _quantityController = TextEditingController(
        text: AppFormatters.formatQuantity(
            _quantity, _currentProduct.unit == ProductUnit.kilo));
  }

  @override
  void dispose() {
    _quantityController.dispose();
    super.dispose();
  }

  void _updateQuantity(double newValue) {
    final bool isKilo = _currentProduct.unit == ProductUnit.kilo;
    final double minQuantity =
        AppFormatters.getMinQuantity(_currentProduct.unit);

    if (newValue >= minQuantity) {
      final cartProvider = Provider.of<CartProvider>(context, listen: false);
      final (validatedQuantity, warning) = QuantityValidator.validateQuantity(
        productId: _currentProduct.id,
        requestedQuantity: newValue,
        cartProvider: cartProvider,
        context: context,
        product: _currentProduct,  // Add this line
      );

      if (warning != null) {
        _showSnackBar(
          warning,
          backgroundColor: AppColors.warning,
        );
      }

      final double roundedValue =
          AppFormatters.roundQuantity(validatedQuantity, _currentProduct.unit);
      setState(() {
        _quantity = roundedValue;
        _quantityController.text =
            AppFormatters.formatQuantity(roundedValue, isKilo);
      });
    }
  }

  void _showSnackBar(String message, {Color? backgroundColor}) {
    ScaffoldMessenger.of(context)
      ..removeCurrentSnackBar()  // Changed from clearSnackBars
      ..showSnackBar(
        SnackBar(
          content: Row(
            children: [
              Icon(
                Icons.check_circle_outline,
                color: AppColors.primary,
              ),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  message,
                  style: TextStyle(
                    color: AppColors.primary,
                    fontWeight: FontWeight.w500,
                  ),
                  overflow: TextOverflow.ellipsis,
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
  }

  Widget _buildImageCarousel() {
    if (_currentProduct.images.isEmpty) {
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
          items: _currentProduct.images.map((imageUrl) {
            return ValidatedNetworkImage(
              imageUrl: imageUrl,
              fit: BoxFit.contain,
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
            children: _currentProduct.images.asMap().entries.map((entry) {
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

  Widget _buildQuantitySelector() {
    final bool isKilo = _currentProduct.unit == ProductUnit.kilo;
    final double step = isKilo ? 0.25 : 1.0;
    final double minQuantity = isKilo ? 0.25 : 1.0;

    return Row(
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
            border: Border.all(color: AppColors.primary),
            borderRadius: BorderRadius.circular(12),
            color: AppColors.primaryLight.withOpacity(0.1),
          ),
          child: Row(
            children: [
              Material(
                color: Colors.transparent,
                child: InkWell(
                  borderRadius:
                      const BorderRadius.horizontal(left: Radius.circular(11)),
                  onTap: _quantity <= minQuantity
                      ? null
                      : () => _updateQuantity(_quantity - step),
                  child: Padding(
                    padding: const EdgeInsets.all(8.0),
                    child: Icon(
                      Icons.remove,
                      color: _quantity <= minQuantity
                          ? AppColors.notActiveBtn
                          : AppColors.primary,
                    ),
                  ),
                ),
              ),
              GestureDetector(
                onTap: () {
                  _quantityController.clear();
                  showDialog(
                    context: context,
                    barrierDismissible: false,
                    builder: (context) => AlertDialog(
                      backgroundColor: AppColors.bgWhite,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(16),
                      ),
                      title: Row(
                        children: [
                          Icon(
                            isKilo ? Icons.scale : Icons.numbers,
                            color: AppColors.primary,
                          ),
                          const SizedBox(width: 8),
                          const Text(
                            'Enter Quantity',
                            style: TextStyle(
                              color: AppColors.primary,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ],
                      ),
                      content: Container(
                        decoration: BoxDecoration(
                          color: AppColors.primaryLight.withOpacity(0.1),
                          borderRadius: BorderRadius.circular(12),
                        ),
                        padding: const EdgeInsets.symmetric(horizontal: 16),
                        child: TextField(
                          controller: _quantityController,
                          keyboardType: isKilo
                              ? const TextInputType.numberWithOptions(
                                  decimal: true)
                              : TextInputType.number,
                          decoration: InputDecoration(
                            border: InputBorder.none,
                            hintText: isKilo ? '0.25' : '1',
                            hintStyle: TextStyle(
                              color: AppColors.primary.withOpacity(0.5),
                            ),
                          ),
                          autofocus: true,
                          style: const TextStyle(
                            color: AppColors.primary,
                            fontSize: 20,
                            fontWeight: FontWeight.bold,
                          ),
                          textAlign: TextAlign.center,
                        ),
                      ),
                      actions: [
                        TextButton.icon(
                          onPressed: () {
                            _quantityController.text =
                                AppFormatters.formatQuantity(_quantity, isKilo);
                            Navigator.pop(context);
                          },
                          icon: const Icon(Icons.close),
                          label: const Text('Cancel'),
                          style: TextButton.styleFrom(
                            foregroundColor: AppColors.notActiveBtn,
                          ),
                        ),
                        FilledButton.icon(
                          onPressed: () {
                            try {
                              String value = _quantityController.text.trim();
                              if (value.isEmpty) {
                                _quantityController.text =
                                    AppFormatters.formatQuantity(
                                        _quantity, isKilo);
                              } else {
                                double newValue = double.parse(
                                    value.replaceAll(RegExp(r'[^0-9.]'), ''));
                                if (newValue >= minQuantity) {
                                  final cartProvider =
                                      Provider.of<CartProvider>(context,
                                          listen: false);
                                  final (validatedQuantity, warning) =
                                      QuantityValidator.validateQuantity(
                                    productId: _currentProduct.id,
                                    requestedQuantity: newValue,
                                    cartProvider: cartProvider,
                                    context: context,
                                    product: _currentProduct,  // Add this line
                                  );

                                  if (warning != null) {
                                    _showSnackBar(
                                      warning,
                                      backgroundColor: AppColors.warning,
                                    );
                                  }

                                  _updateQuantity(validatedQuantity);
                                } else {
                                  _quantityController.text =
                                      AppFormatters.formatQuantity(
                                          _quantity, isKilo);
                                }
                              }
                            } catch (e) {
                              _quantityController.text =
                                  AppFormatters.formatQuantity(
                                      _quantity, isKilo);
                            }
                            Navigator.pop(context);
                          },
                          icon: const Icon(Icons.check),
                          label: const Text('OK'),
                          style: FilledButton.styleFrom(
                            backgroundColor: AppColors.primary,
                            foregroundColor: AppColors.textPrimary,
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(8),
                            ),
                          ),
                        ),
                        const SizedBox(width: 8),
                      ],
                    ),
                  );
                },
                child: Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                  width: 80, // Add fixed width
                  alignment: Alignment.center, // Center the text
                  child: Text(
                    AppFormatters.formatQuantity(_quantity, isKilo),
                    style: const TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                      color: AppColors.primary,
                    ),
                  ),
                ),
              ),
              Material(
                color: Colors.transparent,
                child: InkWell(
                  borderRadius:
                      const BorderRadius.horizontal(right: Radius.circular(11)),
                  onTap: () => _updateQuantity(_quantity + step),
                  child: const Padding(
                    padding: EdgeInsets.all(8.0),
                    child: Icon(
                      Icons.add,
                      color: AppColors.primary,
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  @override
  Widget build(BuildContext context) {
    return Consumer<ProductProvider>(
      builder: (context, productProvider, child) {
        try {
          // Get the latest product data from provider
          _currentProduct = productProvider.products.firstWhere(
            (p) => p.id == widget.product.id,
          );
        } catch (e) {
          // Product was deleted, navigate back
          WidgetsBinding.instance.addPostFrameCallback((_) {
            Navigator.of(context).pop();
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(
                content: Text('This product is no longer available'),
                backgroundColor: AppColors.failed,
              ),
            );
          });
          return const SizedBox();
        }

        final bool hasDiscount = _currentProduct.discountPrice != null &&
            _currentProduct.discountPrice! > 0 &&
            _currentProduct.discountPrice! < _currentProduct.price;

        return Scaffold(
          backgroundColor: AppColors.bgWhite,
          appBar: CustomAppBar(title: _currentProduct.viewName),
          floatingActionButton: Consumer<CartProvider>(
            builder: (context, cart, child) {
              return FloatingActionButton.extended(
                onPressed: () {
                  try {
                    // Validate quantity before adding to cart
                    final (validatedQuantity, warning) =
                        QuantityValidator.validateQuantity(
                      productId: _currentProduct.id,
                      requestedQuantity: _quantity,
                      cartProvider: cart,
                      context: context,
                      product: _currentProduct,  // Add this line
                    );

                    if (warning != null) {
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
                              Expanded(
                                child: Text(
                                  warning,
                                  style: TextStyle(
                                    color: AppColors.warning,
                                    fontWeight: FontWeight.w500,
                                  ),
                                  overflow: TextOverflow.ellipsis,
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
                      if (validatedQuantity <= 0) return;
                    }

                    cart.addItem(_currentProduct, quantity: validatedQuantity);
                    _showSnackBar('Added ${AppFormatters.formatQuantity(validatedQuantity, _currentProduct.unit == ProductUnit.kilo)} ${_currentProduct.unit == ProductUnit.kilo ? "kg" : "item(s)"} to cart');
                  } catch (e) {
                    ScaffoldMessenger.of(context).hideCurrentSnackBar();
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(
                        content: Text('Failed to add item to cart'),
                        behavior: SnackBarBehavior.floating,
                        margin: const EdgeInsets.all(8),
                        backgroundColor: AppColors.failed,
                      ),
                    );
                  }
                },
                backgroundColor: AppColors.primary,
                icon: const Icon(
                  Icons.add_shopping_cart,
                  color: Colors.white,
                ),
                label: const Text(
                  'Add to Cart',
                  style: TextStyle(
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
                    // Warning Section
                    if (_currentProduct.quantity < 1)
                      Container(
                        padding: const EdgeInsets.all(12),
                        decoration: BoxDecoration(
                          color: Colors.red.withOpacity(0.1),
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: Row(
                          children: [
                            const Icon(Icons.warning_amber_rounded, color: Colors.red),
                            const SizedBox(width: 8),
                            const Expanded(
                              child: Text(
                                'This item may not be available.',
                                style: TextStyle(
                                  color: Colors.red,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                            ),
                          ],
                        ),
                      )
                    else if (_currentProduct.quantity < 15)
                      Container(
                        padding: const EdgeInsets.all(12),
                        decoration: BoxDecoration(
                          color: Colors.orange.withOpacity(0.1),
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: Row(
                          children: [
                            const Icon(Icons.warning_amber_rounded, color: Colors.orange),
                            const SizedBox(width: 8),
                            const Expanded(
                              child: Text(
                                'Only a few items left!',
                                style: TextStyle(
                                  color: Colors.orange,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                    const SizedBox(height: 16),

                    // Brand and Rating
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text(
                          _currentProduct.brand
                              .name, // Changed from product.brand to product.brand.name
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
                      _currentProduct.viewName,
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
                          Row(
                            crossAxisAlignment: CrossAxisAlignment.baseline,
                            textBaseline: TextBaseline.alphabetic,
                            children: [
                              Text(
                                AppFormatters.formatPrice(
                                    _currentProduct.discountPrice!),
                                style: const TextStyle(
                                  fontSize: 28,
                                  fontWeight: FontWeight.bold,
                                  color: AppColors.primary,
                                ),
                              ),
                              const SizedBox(width: 4),
                              Text(
                                '/ ${_currentProduct.unit == ProductUnit.kilo ? 'kilo' : 'piece'}',
                                style: TextStyle(
                                  fontSize: 16,
                                  color: Colors.grey[600],
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(width: 16),
                          Text(
                            AppFormatters.formatPrice(_currentProduct.price),
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
                              '${(((_currentProduct.price - _currentProduct.discountPrice!) / _currentProduct.price) * 100).round()}% OFF',
                              style: const TextStyle(
                                color: AppColors.primary,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ),
                        ] else ...[
                          Row(
                            crossAxisAlignment: CrossAxisAlignment.baseline,
                            textBaseline: TextBaseline.alphabetic,
                            children: [
                              Text(
                                AppFormatters.formatPrice(_currentProduct.price),
                                style: const TextStyle(
                                  fontSize: 28,
                                  fontWeight: FontWeight.bold,
                                  color: AppColors.primary,
                                ),
                              ),
                              const SizedBox(width: 4),
                              Text(
                                '/ ${_currentProduct.unit == ProductUnit.kilo ? 'kilo' : 'piece'}',
                                style: TextStyle(
                                  fontSize: 16,
                                  color: Colors.grey[600],
                                ),
                              ),
                            ],
                          ),
                        ],
                      ],
                    ),

                    const SizedBox(height: 24),

                    // Quantity Selector
                    _buildQuantitySelector(),

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
                      _currentProduct.description,
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
      },
    );
  }
}
