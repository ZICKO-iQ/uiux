import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../../core/colors.dart';
import '../../models/cart_item.dart';
import '../../models/product.dart';  // Add this import for ProductUnit
import '../../utils/image_validation.dart';

class CartItemCard extends StatefulWidget {  // Change to StatefulWidget
  final CartItem item;
  final Function(double) onQuantityChanged;  // Changed to double
  final VoidCallback onDelete;

  const CartItemCard({
    super.key,
    required this.item,
    required this.onQuantityChanged,
    required this.onDelete,
  });

  @override
  State<CartItemCard> createState() => _CartItemCardState();
}

class _CartItemCardState extends State<CartItemCard> {
  static final NumberFormat _currencyFormatter = NumberFormat.currency(
    symbol: '\$',
    decimalDigits: 0,  // Changed to 0 to remove decimal points
  );

  String _formatPrice(num price) {  // Changed parameter type to num
    return _currencyFormatter.format(price);
  }

  String _formatPriceWithUnit(num price, ProductUnit unit) {
    String formattedPrice = _currencyFormatter.format(price);
    return unit == ProductUnit.kilo ? '$formattedPrice/kg' : '$formattedPrice/piece';
  }

  String _formatQuantity(double quantity, bool isKilo) {
    if (isKilo) {
      // Only show the number with necessary decimals, without 'kg'
      return quantity.toStringAsFixed(2).replaceAll(RegExp(r'\.?0*$'), '');
    } else {
      return quantity.toInt().toString();
    }
  }

  Widget _buildQuantityControls() {
    final bool isKilo = widget.item.unit == ProductUnit.kilo;
    final double step = isKilo ? 0.25 : 1.0;
    final double minQuantity = isKilo ? 0.25 : 1.0;
    final double maxQuantity = 100.0;

    return Container(
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(12),
        color: AppColors.primaryLight.withOpacity(0.1),
        border: Border.all(color: AppColors.primary),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Material(
            color: Colors.transparent,
            child: InkWell(
              borderRadius: const BorderRadius.horizontal(left: Radius.circular(11)),
              onTap: widget.item.quantity <= minQuantity
                  ? null 
                  : () => widget.onQuantityChanged(widget.item.quantity - step),
              child: Padding(
                padding: const EdgeInsets.all(4.0),
                child: Icon(
                  Icons.remove,
                  size: 20,
                  color: widget.item.quantity <= minQuantity
                      ? AppColors.notActiveBtn 
                      : AppColors.primary,
                ),
              ),
            ),
          ),
          GestureDetector(
            onTap: () {
              final TextEditingController controller = TextEditingController();
              showDialog(
                context: context,  // Now we can use context directly
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
                      controller: controller,
                      keyboardType: isKilo 
                          ? const TextInputType.numberWithOptions(decimal: true)
                          : TextInputType.number,
                      decoration: InputDecoration(
                        border: InputBorder.none,
                        suffix: Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 8,
                            vertical: 4,
                          ),
                          decoration: BoxDecoration(
                            color: AppColors.primary.withOpacity(0.1),
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: Text(
                            isKilo ? 'kg' : 'pcs',
                            style: const TextStyle(
                              color: AppColors.primary,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ),
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
                      onPressed: () => Navigator.pop(context),
                      icon: const Icon(Icons.close),
                      label: const Text('Cancel'),
                      style: TextButton.styleFrom(
                        foregroundColor: AppColors.notActiveBtn,
                      ),
                    ),
                    FilledButton.icon(
                      onPressed: () {
                        try {
                          String value = controller.text.trim();
                          if (value.isNotEmpty) {
                            double newValue = double.parse(value.replaceAll(RegExp(r'[^0-9.]'), ''));
                            // Cap the value at maxQuantity
                            if (newValue > maxQuantity) {
                              newValue = maxQuantity;
                            }
                            if (newValue >= minQuantity) {
                              // Round to nearest step for kilo products
                              if (isKilo) {
                                newValue = (newValue / step).round() * step;
                              }
                              widget.onQuantityChanged(newValue);
                            }
                          }
                        } catch (e) {
                          // Invalid input, ignore
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
              padding: const EdgeInsets.symmetric(horizontal: 8),
              width: 60, // Increased from 60 to 72 to accommodate longer numbers
              alignment: Alignment.center,
              child: Text(
                _formatQuantity(widget.item.quantity, isKilo),
                style: const TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                  color: AppColors.primary,
                ),
              ),
            ),
          ),
          Material(
            color: Colors.transparent,
            child: InkWell(
              borderRadius: const BorderRadius.horizontal(right: Radius.circular(11)),
              onTap: widget.item.quantity >= maxQuantity 
                  ? null 
                  : () => widget.onQuantityChanged(widget.item.quantity + step),
              child: Padding(
                padding: const EdgeInsets.all(4.0),
                child: Icon(
                  Icons.add,
                  size: 20,
                  color: widget.item.quantity >= maxQuantity
                      ? AppColors.notActiveBtn
                      : AppColors.primary,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(15),
        boxShadow: [
          BoxShadow(
            color: Colors.grey.withOpacity(0.1),
            spreadRadius: 1,
            blurRadius: 10,
            offset: const Offset(0, 2),
          ),
        ],
        border: Border.all(
          color: AppColors.primaryLight.withOpacity(0.3),
          width: 1,
        ),
      ),
      child: Row(
        children: [
          Container(
            width: 120,
            height: 120,
            padding: const EdgeInsets.all(10),
            child: ClipRRect(
              borderRadius: BorderRadius.circular(10),
              child: ValidatedNetworkImage(
                imageUrl: widget.item.image,
                fit: BoxFit.cover,
              ),
            ),
          ),
          Expanded(
            child: Padding(
              padding: const EdgeInsets.all(12),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              widget.item.title,
                              style: const TextStyle(
                                fontSize: 16,
                                fontWeight: FontWeight.bold,
                                color: AppColors.textSecondary,
                              ),
                              maxLines: 2,
                              overflow: TextOverflow.ellipsis,
                            ),
                            const SizedBox(height: 4),
                            Container(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 8,
                                vertical: 2,
                              ),
                              decoration: BoxDecoration(
                                color: AppColors.primaryLight.withOpacity(0.2),
                                borderRadius: BorderRadius.circular(4),
                              ),
                              child: Text(
                                'Size: ${widget.item.size}',
                                style: TextStyle(
                                  color: Colors.grey[700],
                                  fontSize: 12,
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                      Material(
                        color: Colors.transparent,
                        child: InkWell(
                          borderRadius: BorderRadius.circular(20),
                          onTap: widget.onDelete,
                          child: const Padding(
                            padding: EdgeInsets.all(8.0),
                            child: Icon(
                              Icons.delete_outline,
                              color: Colors.red,
                              size: 24,
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 8),
                  Text(
                    _formatPriceWithUnit(widget.item.price, widget.item.unit),  // Updated price display
                    style: TextStyle(
                      color: Colors.grey[600],
                      fontSize: 14,
                    ),
                  ),
                  const SizedBox(height: 12),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    crossAxisAlignment: CrossAxisAlignment.center,
                    children: [
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Text(
                            'Subtotal',
                            style: TextStyle(
                              fontSize: 12,
                              color: Colors.grey,
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                          const SizedBox(height: 2),
                          Text(
                            _formatPrice((widget.item.price * widget.item.quantity).toDouble()),  // Convert to double for proper calculation
                            style: const TextStyle(
                              fontSize: 18,
                              fontWeight: FontWeight.bold,
                              color: AppColors.primary,
                            ),
                          ),
                        ],
                      ),
                      _buildQuantityControls(),
                    ],
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}
