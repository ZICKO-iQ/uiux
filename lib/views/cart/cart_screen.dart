import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:flutter/services.dart';
import 'package:url_launcher/url_launcher.dart';
import '../../core/colors.dart';
import '../../providers/cart_provider.dart';
import '../../utils/formatters.dart';  // Add this import
import '../shared/app_bar.dart';
import 'cart_item_card.dart';

class CartPage extends StatefulWidget {  // Changed to StatefulWidget
  const CartPage({super.key});

  @override
  State<CartPage> createState() => _CartPageState();
}

class _CartPageState extends State<CartPage> {
  final List<Map<String, dynamic>> branches = [  // Move branches to class field
    {
      'name': 'Arkhasluk 1',
      'location': 'Near Al-Khasluk Main Square',
      'lat': 32.3840,  // Add actual coordinates
      'lng': 20.8288,
    },
    {
      'name': 'Arkhasluk 4',
      'location': 'Next to Al-Khasluk Health Center',
      'lat': 32.3860,  // Add actual coordinates
      'lng': 20.8308,
    },
    {
      'name': 'Arkhasluk 5',
      'location': 'Opposite to Al-Khasluk Mosque',
      'lat': 32.3875,  // Add actual coordinates
      'lng': 20.8298,
    },
    {
      'name': 'Arkhasluk 6',
      'location': 'Behind Al-Khasluk School',
      'lat': 32.3855,  // Add actual coordinates
      'lng': 20.8318,
    },
    {
      'name': 'Arkhasluk 7',
      'location': 'Near Al-Khasluk Park',
      'lat': 32.3845,  // Add actual coordinates
      'lng': 20.8328,
    },
  ];

  final Map<String, String> branchPhones = {
    'Arkhasluk 1': '+9647729177964',
    'Arkhasluk 4': '+9647729177964',
    'Arkhasluk 5': '+9647729177964',
    'Arkhasluk 6': '+9647729177964',
    'Arkhasluk 7': '+9647729177964',
  };

  String _formatCartDetails(CartProvider cart, String? specialNote, String selectedBranch) {
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
    
    if (specialNote != null && specialNote.isNotEmpty) {
      buffer.writeln('\n📝 Special Note:');
      buffer.writeln(specialNote);
    }

    return buffer.toString();
  }

  Future<String?> _showNoteDialog(BuildContext context, CartProvider cart) async {
    final noteController = TextEditingController();
    
    return showDialog<String>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Add Special Note'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Text('Would you like to add a special note to your order?'),
            const SizedBox(height: 16),
            TextField(
              controller: noteController,
              decoration: const InputDecoration(
                hintText: 'Enter your note here (optional)',
                border: OutlineInputBorder(),
              ),
              maxLines: 3,
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () {
              Navigator.pop(context, noteController.text);
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.primary,
              foregroundColor: AppColors.textPrimary,
            ),
            child: const Text('Next'),
          ),
        ],
      ),
    );
  }

  double _calculateDistance(double lat1, double lon1, double lat2, double lon2) {
    // Simple Euclidean distance for demonstration
    // In production, use Haversine formula for more accurate results
    return ((lat2 - lat1) * (lat2 - lat1) + (lon2 - lon1) * (lon2 - lon1));
  }

  Map<String, dynamic> _findNearestBranch(double userLat, double userLng) {
    return branches.reduce((curr, next) {
      double currDist = _calculateDistance(
        userLat, 
        userLng, 
        curr['lat'] as double, 
        curr['lng'] as double
      );
      double nextDist = _calculateDistance(
        userLat, 
        userLng, 
        next['lat'] as double, 
        next['lng'] as double
      );
      return currDist < nextDist ? curr : next;
    });
  }

  Future<String?> _showBranchDialog(BuildContext context, {Map<String, dynamic>? nearestBranch}) async {
    bool showOtherBranches = false;
    String? selectedBranchName = nearestBranch?['name'] as String?;

    return showDialog<String>(
      context: context,
      barrierDismissible: false,
      builder: (context) => StatefulBuilder(
        builder: (context, setState) => AlertDialog(
          title: Row(
            children: const [
              Icon(Icons.location_on, color: AppColors.primary),
              SizedBox(width: 8),
              Text('Select Branch'),
            ],
          ),
          content: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Container(
                  padding: const EdgeInsets.all(12),
                  margin: const EdgeInsets.only(bottom: 16),
                  decoration: BoxDecoration(
                    color: AppColors.primaryLight.withOpacity(0.2),
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(color: AppColors.primary.withOpacity(0.3)),
                  ),
                  child: Column(
                    children: [
                      Row(
                        children: [
                          Icon(
                            selectedBranchName == nearestBranch?['name'] 
                                ? Icons.near_me 
                                : Icons.store,
                            color: AppColors.primary
                          ),
                          const SizedBox(width: 8),
                          Expanded(
                            child: Text(
                              selectedBranchName == nearestBranch?['name']
                                  ? 'Nearest branch to you:'
                                  : 'Your selected branch:',
                              style: TextStyle(
                                color: AppColors.textGrey,
                                fontSize: 14,
                              ),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 8),
                      Text(
                        selectedBranchName ?? '',
                        style: const TextStyle(
                          fontWeight: FontWeight.bold,
                          fontSize: 16,
                          color: AppColors.primary,
                        ),
                      ),
                    ],
                  ),
                ),
                TextButton.icon(
                  onPressed: () {
                    setState(() {
                      showOtherBranches = !showOtherBranches;
                    });
                  },
                  icon: Icon(
                    showOtherBranches ? Icons.expand_less : Icons.expand_more,
                    color: AppColors.textSecondary,
                  ),
                  label: Text(
                    showOtherBranches ? 'Hide Other Branches' : 'Show Other Branches',
                    style: const TextStyle(color: AppColors.textSecondary),
                  ),
                ),
                if (showOtherBranches) ...[
                  const SizedBox(height: 16),
                  ...branches
                      .where((branch) => branch['name'] != selectedBranchName)
                      .map((branch) => Container(
                            margin: const EdgeInsets.only(bottom: 8),
                            child: ListTile(
                              leading: const Icon(Icons.store, color: AppColors.primary),
                              title: Text(
                                branch['name'] as String,
                                style: const TextStyle(
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                              subtitle: Text(
                                branch['location'] as String,
                                style: TextStyle(
                                  color: AppColors.textGrey,
                                  fontSize: 12,
                                ),
                              ),
                              onTap: () {
                                setState(() {
                                  selectedBranchName = branch['name'] as String;
                                  showOtherBranches = false;
                                });
                              },
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(8),
                              ),
                              tileColor: AppColors.primaryLight.withOpacity(0.1),
                              contentPadding: const EdgeInsets.symmetric(
                                horizontal: 16,
                                vertical: 8,
                              ),
                            ),
                          ))
                      .toList(),
                ],
              ],
            ),
          ),
          actions: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                TextButton(
                  onPressed: () => Navigator.pop(context),
                  child: const Text('Cancel'),
                ),
                ElevatedButton.icon(
                  onPressed: () => Navigator.pop(context, selectedBranchName),
                  label: const Text('Confirm'),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppColors.primary,
                    foregroundColor: AppColors.textPrimary,
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _sendToWhatsApp(String message, String branchName) async {
    final phone = branchPhones[branchName];
    if (phone == null) return;

    // Clean the phone number and ensure proper format
    final cleanPhone = phone.replaceAll(RegExp(r'[^0-9]'), '');
    
    // Try both URL formats for better compatibility
    final urls = [
      Uri.parse('https://wa.me/$cleanPhone?text=${Uri.encodeComponent(message)}'),
      Uri.parse('whatsapp://send?phone=$cleanPhone&text=${Uri.encodeComponent(message)}'),
    ];

    bool launched = false;
    for (var url in urls) {
      try {
        if (await canLaunchUrl(url)) {
          launched = await launchUrl(
            url,
            mode: LaunchMode.externalApplication,
          );
          if (launched) break;
        }
      } catch (e) {
        print('Error launching WhatsApp: $e');
      }
    }

    if (!launched) {
      if (!context.mounted) return;
      // Fallback to clipboard
      await Clipboard.setData(ClipboardData(text: message));
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Could not open WhatsApp. Cart details copied to clipboard instead.'),
          duration: Duration(seconds: 3),
        ),
      );
    }
  }

  Future<void> _processOrder(BuildContext context, CartProvider cart) async {
    try {
      const userLat = 32.3850;
      const userLng = 20.8300;
      
      final nearestBranch = _findNearestBranch(userLat, userLng);
      
      final String? note = await _showNoteDialog(context, cart);
      if (!context.mounted) return;
      
      final String? selectedBranch = await _showBranchDialog(
        context,
        nearestBranch: nearestBranch,
      );
      
      if (!context.mounted || selectedBranch == null) return;
      
      final String formattedText = _formatCartDetails(cart, note, selectedBranch);
      await _sendToWhatsApp(formattedText, selectedBranch);
      
    } catch (e) {
      if (!context.mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Failed to process order'),
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
      backgroundColor: AppColors.bgWhite,  // Changed from Colors.grey[100]
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
                    color: AppColors.textGrey,  // Changed from Colors.grey[400]
                  ),
                  const SizedBox(height: 20),
                  Text(
                    'Your cart is empty',
                    style: TextStyle(
                      fontSize: 20,
                      color: AppColors.textGrey,  // Changed from Colors.grey[600]
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
                      color: AppColors.textSecondary.withOpacity(0.05),  // Changed from Colors.black
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
                          _processOrder(context, cart);
                        },
                        style: ElevatedButton.styleFrom(
                          backgroundColor: AppColors.primary,
                          minimumSize: const Size(double.infinity, 45),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                        ),
                        child: const Text(
                          'Send to WhatsApp',
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
