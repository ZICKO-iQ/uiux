import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:flutter/services.dart';
import '../../core/colors.dart';
import '../../providers/cart_provider.dart';
import '../../utils/formatters.dart';  // Add this import
import '../shared/app_bar.dart';
import 'cart_item_card.dart';

class CartPage extends StatelessWidget {
  const CartPage({super.key});

  String _formatCartDetails(CartProvider cart) {
    final StringBuffer buffer = StringBuffer();
    buffer.writeln('🛒 Shopping Cart Details');
    buffer.writeln('═══════════════════════');
    
    for (var item in cart.items) {
      buffer.writeln('📦 Product: ${item.title}');
      buffer.writeln('   Quantity: ${AppFormatters.formatQuantityWithUnit(item.quantity, item.unit)}');
      buffer.writeln('   Price: ${AppFormatters.formatPrice(item.price)}');
      buffer.writeln('   Subtotal: ${AppFormatters.formatPrice(item.price * item.quantity)}');
      buffer.writeln('───────────────────────');
    }
    
    buffer.writeln('💰 Total Amount: ${AppFormatters.formatPrice(cart.totalAmount)}');
    return buffer.toString();
  }

  Future<void> _copyToClipboard(BuildContext context, CartProvider cart) async {
    final String formattedText = _formatCartDetails(cart);
    await Clipboard.setData(ClipboardData(text: formattedText));
    
    if (context.mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Cart details copied to clipboard'),
          duration: Duration(seconds: 2),
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: CustomAppBar(title: 'Shopping Cart',
        onSearchTap: () {},),
      backgroundColor: Colors.grey[100],
      body: Consumer<CartProvider>(
        builder: (context, cart, child) {
          if (cart.items.isEmpty) {
            return Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(
                    Icons.shopping_cart_outlined,
                    size: 100,
                    color: Colors.grey[400],
                  ),
                  const SizedBox(height: 20),
                  Text(
                    'Your cart is empty',
                    style: TextStyle(
                      fontSize: 20,
                      color: Colors.grey[600],
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ],
              ),
            );
          }

          return Column(
            children: [
              Expanded(
                child: ListView.builder(
                  padding: const EdgeInsets.only(top: 12, bottom: 100),
                  itemCount: cart.items.length,
                  itemBuilder: (context, index) {
                    final item = cart.items[index];
                    return CartItemCard(
                      item: item,
                      onQuantityChanged: (quantity) {
                        cart.updateQuantity(item.id, quantity);
                      },
                      onDelete: () => cart.removeItem(item.id),
                    );
                  },
                ),
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                decoration: BoxDecoration(
                  color: AppColors.bgWhite,
                  borderRadius: const BorderRadius.vertical(
                    top: Radius.circular(20),
                  ),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withOpacity(0.05),
                      spreadRadius: 1,
                      blurRadius: 10,
                    ),
                  ],
                ),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        const Text(
                          'Total:',
                          style: TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        Text(
                          AppFormatters.formatPrice(cart.totalAmount),
                          style: const TextStyle(
                            fontSize: 20,
                            fontWeight: FontWeight.bold,
                            color: AppColors.primary,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 12),
                    SizedBox(
                      height: 45,
                      child: ElevatedButton(
                        onPressed: () {
                          final cart = Provider.of<CartProvider>(context, listen: false);
                          _copyToClipboard(context, cart);
                        },
                        style: ElevatedButton.styleFrom(
                          backgroundColor: AppColors.primary,
                          minimumSize: const Size(double.infinity, 45),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                        ),
                        child: const Text(
                          'Copy Cart',
                          style: TextStyle(
                            color: AppColors.textPrimary,
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          );
        },
      ),
    );
  }
}
