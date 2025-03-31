import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:flutter/services.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:geolocator/geolocator.dart';
import 'dart:math' show sin, cos, sqrt, atan2, pi;
import '../../core/colors.dart';
import '../../providers/cart_provider.dart';
import '../../utils/formatters.dart';
import '../shared/app_bar.dart';
import 'cart_item_card.dart';

class CartPage extends StatefulWidget {
  const CartPage({super.key});

  @override
  State<CartPage> createState() => _CartPageState();
}

class _CartPageState extends State<CartPage> {
  final List<Map<String, dynamic>> branches = [
    {
      'name': 'Arkhasluk 1',
      'location': 'Near Al-Khasluk Main Square',
      'lat': 32.62601212555854,
      'lng': 44.003622600894936,
    },
    {
      'name': 'Arkhasluk 4',
      'location': 'Next to Al-Khasluk Health Center',
      'lat': 32.55735684497551,
      'lng': 44.04670641022626,
    },
    {
      'name': 'Arkhasluk 5',
      'location': 'Opposite to Al-Khasluk Mosque',
      'lat': 32.5648226892567,
      'lng': 44.02437023906183,
    },
    {
      'name': 'Arkhasluk 6',
      'location': 'Behind Al-Khasluk School',
      'lat': 32.607563547645476, 
      'lng': 44.0102665025351,
    },
    {
      'name': 'Arkhasluk 7',
      'location': 'Karbalaو al-Qadisya',
      'lat': 32.638120190015705, 
      'lng': 43.98174506974492,
    },
  ];

  final Map<String, String> branchPhones = {
    'Arkhasluk 1': '+9647729177964',
    'Arkhasluk 4': '+9647729177964',
    'Arkhasluk 5': '+9647729177964',
    'Arkhasluk 6': '+9647729177964',
    'Arkhasluk 7': '+9647729177964',
  };

  // Track if we're currently fetching location
  bool _isLoadingLocation = false;
  // Store user position when available
  Position? _userPosition;
  // Track if we've already started the background location fetch
  bool _locationFetchStarted = false;

  @override
  void initState() {
    super.initState();
    // Start background location fetch as soon as the page loads
    _startBackgroundLocationFetch();
  }

  // Start location fetch in the background without blocking UI
  void _startBackgroundLocationFetch() {
    if (_locationFetchStarted) return;
    _locationFetchStarted = true;
    
    // Get location in background without showing loading indicator
    _getCurrentLocation(showLoading: false).then((position) {
      if (position != null && mounted) {
        setState(() {
          _userPosition = position;
        });
      }
    });
  }

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
            child: const Text('Cancel', style: TextStyle(color: AppColors.failed)),
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

  // Updated to accept optional showLoading parameter
  Future<Position?> _getCurrentLocation({bool showLoading = true}) async {
    if (showLoading && mounted) {
      setState(() {
        _isLoadingLocation = true;
      });
    }

    try {
      // If we already have a position, return it immediately
      if (_userPosition != null) {
        return _userPosition;
      }

      // Check if location services are enabled
      bool serviceEnabled = await Geolocator.isLocationServiceEnabled();
      if (!serviceEnabled) {
        // Location services are not enabled
        if (!context.mounted) return null;
        _showStyledSnackBar(
          message: 'Location services are disabled. Please enable to find the nearest branch.',
          icon: Icons.location_off,
          isError: true,
        );
        return null;
      }

      // Check for location permission
      LocationPermission permission = await Geolocator.checkPermission();
      if (permission == LocationPermission.denied) {
        permission = await Geolocator.requestPermission();
        if (permission == LocationPermission.denied) {
          // Permissions are denied
          if (!context.mounted) return null;
          _showStyledSnackBar(
            message: 'Location permissions are denied. Unable to find nearest branch.',
            icon: Icons.location_disabled,
            isError: true,
          );
          return null;
        }
      }
      
      if (permission == LocationPermission.deniedForever) {
        // Permissions are permanently denied
        if (!context.mounted) return null;
        _showStyledSnackBar(
          message: 'Location permissions are permanently denied. Please enable in settings to find nearest branch.',
          icon: Icons.location_disabled,
          isError: true,
        );
        return null;
      }

      // Get current position with timeout to ensure we don't wait forever
      final position = await Geolocator.getCurrentPosition(
        desiredAccuracy: LocationAccuracy.high,
        timeLimit: const Duration(seconds: 5), // Add timeout for quicker response
      );
      
      return position;
    } catch (e) {
      if (showLoading && !context.mounted) return null;
      // Only show error for explicit location requests, not background ones
      if (showLoading && context.mounted) {
        _showStyledSnackBar(
          message: 'Failed to get location: $e',
          icon: Icons.error_outline,
          isError: true,
        );
      }
      return null;
    } finally {
      if (showLoading && mounted) {
        setState(() {
          _isLoadingLocation = false;
        });
      }
    }
  }

  double _calculateDistance(double lat1, double lon1, double lat2, double lon2) {
    // Implement Haversine formula for accurate distance calculation
    const radius = 6371.0; // Earth radius in kilometers
    
    // Convert to radians
    final dLat = (lat2 - lat1) * (pi / 180);
    final dLon = (lon2 - lon1) * (pi / 180);
    
    final a = sin(dLat / 2) * sin(dLat / 2) +
              cos(lat1 * (pi / 180)) * cos(lat2 * (pi / 180)) *
              sin(dLon / 2) * sin(dLon / 2);
              
    final c = 2 * atan2(sqrt(a), sqrt(1 - a));
    
    return radius * c; // Distance in kilometers
  }

  Map<String, dynamic> _findNearestBranch(double userLat, double userLng) {
    // Use proper distance calculation to find nearest branch
    Map<String, dynamic>? nearest;
    double minDistance = double.infinity;
    
    for (var branch in branches) {
      final distance = _calculateDistance(
        userLat, 
        userLng, 
        branch['lat'] as double, 
        branch['lng'] as double
      );
      
      if (distance < minDistance) {
        minDistance = distance;
        nearest = branch;
      }
    }
    
    return nearest ?? branches.first;
  }

  // Modified to work with or without a nearest branch
  Future<String?> _showBranchDialog(BuildContext context, {Map<String, dynamic>? nearestBranch}) async {
    bool showOtherBranches = nearestBranch == null;
    // If we don't have a nearest branch, default to first one but show all branches
    String? selectedBranchName = nearestBranch?['name'] as String? ?? branches.first['name'] as String;

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
                            nearestBranch != null && selectedBranchName == nearestBranch['name'] 
                                ? Icons.near_me 
                                : Icons.store,
                            color: AppColors.primary
                          ),
                          const SizedBox(width: 8),
                          Expanded(
                            child: Text(
                              nearestBranch != null && selectedBranchName == nearestBranch['name']
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
                        selectedBranchName!,
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
                  child: const Text('Cancel', style: TextStyle(color: AppColors.failed)),
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
      _showStyledSnackBar(
        message: 'Could not open WhatsApp. Cart details copied to clipboard instead.',
        icon: Icons.content_copy,
      );
    }
  }

  // Updated to use cached location if available
  Future<void> _processOrder(BuildContext context, CartProvider cart) async {
    try {
      // Get the note first, so we don't delay UI interaction
      final String? note = await _showNoteDialog(context, cart);
      if (!context.mounted) return;
      
      Map<String, dynamic>? nearestBranch;
      
      // Use cached position if available
      if (_userPosition != null) {
        nearestBranch = _findNearestBranch(
          _userPosition!.latitude,
          _userPosition!.longitude
        );
      } else {
        // Try to get location quickly, but don't block UI too long
        final position = await _getCurrentLocation(showLoading: true);
        
        if (position != null) {
          _userPosition = position;
          nearestBranch = _findNearestBranch(
            position.latitude,
            position.longitude
          );
        }
        // If we can't get location quickly, proceed without it
      }
      
      if (!context.mounted) return;
      
      // Show branch dialog - works with or without nearest branch data
      final String? selectedBranch = await _showBranchDialog(
        context,
        nearestBranch: nearestBranch,
      );
      
      if (!context.mounted || selectedBranch == null) return;
      
      final String formattedText = _formatCartDetails(cart, note, selectedBranch);
      await _sendToWhatsApp(formattedText, selectedBranch);
      
    } catch (e) {
      if (!context.mounted) return;
      _showStyledSnackBar(
        message: 'Failed to process order: $e',
        icon: Icons.error_outline,
        isError: true,
      );
    }
  }

  // Add this new method to show confirmation dialog before clearing cart
  Future<void> _confirmClearCart(BuildContext context) async {
    final bool? result = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: Row(
          children: const [
            Icon(Icons.delete_forever, color: Colors.red),
            SizedBox(width: 8),
            Text('Clear Cart'),
          ],
        ),
        content: const Text(
          'Are you sure you want to remove all items from your cart? This action cannot be undone.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(context, true),
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.red,
              foregroundColor: Colors.white,
            ),
            child: const Text('Clear All'),
          ),
        ],
      ),
    );

    if (result == true) {
      if (context.mounted) {
        // Clear the cart
        final cart = Provider.of<CartProvider>(context, listen: false);
        cart.clearCart();
        
        // Show confirmation with styled snackbar
        _showStyledSnackBar(
          message: 'Your cart has been cleared',
          icon: Icons.delete_sweep,
          duration: const Duration(seconds: 2),
        );
      }
    }
  }

  // Add this helper method to show styled snackbars
  void _showStyledSnackBar({
    required String message,
    SnackBarAction? action,
    Duration? duration,
    IconData? icon,
    bool isError = false,
    bool isSuccess = false,
  }) {
    if (!context.mounted) return;
    
    ScaffoldMessenger.of(context).clearSnackBars();
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Row(
          children: [
            // Show icon if provided
            if (icon != null) ...[
              Icon(
                icon,
                color: isError 
                  ? Colors.white 
                  : (isSuccess ? Colors.white : AppColors.textPrimary),
                size: 20,
              ),
              const SizedBox(width: 12),
            ],
            Expanded(
              child: Text(
                message,
                style: TextStyle(
                  color: isError 
                    ? Colors.white
                    : (isSuccess ? Colors.white : AppColors.textSecondary),
                  fontSize: 14,
                  fontWeight: FontWeight.w500,
                ),
              ),
            ),
          ],
        ),
        duration: duration ?? const Duration(seconds: 3),
        action: action,
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(12),
        ),
        margin: const EdgeInsets.all(8),
        padding: const EdgeInsets.symmetric(
          horizontal: 16, 
          vertical: 12,
        ),
        backgroundColor: isError 
            ? AppColors.failed 
            : (isSuccess ? AppColors.primary : Colors.white),
        elevation: 4,
      ),
    );
  }

  // Updated method to handle item removal with undo functionality - removed redundant restore notification
  void _handleItemRemove(BuildContext context, String itemId, String itemTitle) {
    final cart = Provider.of<CartProvider>(context, listen: false);
    
    try {
      // Check if this is the last item before removing
      final removedItem = cart.removeItem(itemId);
      
      // Show snackbar with undo option
      _showStyledSnackBar(
        message: '${removedItem.title} removed from cart',
        icon: Icons.remove_shopping_cart,
        action: SnackBarAction(
          label: 'UNDO',
          textColor: AppColors.primary,
          onPressed: () {
            // Try to undo the removal without showing another snackbar
            cart.undoRemove();
            // No additional snackbar needed as the item reappearing in the cart is feedback enough
          },
        ),
      );
    } catch (e) {
      if (context.mounted) {
        _showStyledSnackBar(
          message: 'Error removing item: $e',
          icon: Icons.error_outline,
          isError: true,
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: CustomAppBar(title: 'Shopping Cart',
        onSearchTap: () {},),
      backgroundColor: AppColors.bgWhite,
      body: Consumer<CartProvider>(
        builder: (context, cart, child) {
          // Start background location fetch if not already started
          if (!_locationFetchStarted) {
            _startBackgroundLocationFetch();
          }
          
          if (cart.items.isEmpty) {
            return Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(
                    Icons.shopping_cart_outlined,
                    size: 100,
                    color: AppColors.textGrey,
                  ),
                  const SizedBox(height: 20),
                  Text(
                    'Your cart is empty',
                    style: TextStyle(
                      fontSize: 20,
                      color: AppColors.textGrey,
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
                      onDelete: () => _handleItemRemove(context, item.id, item.title),
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
                      color: AppColors.textSecondary.withOpacity(0.05),
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
                    Row(
                      children: [
                        // Fix the clear cart button
                        Expanded(
                          // Increase flex from 1 to 2 to give more space for the text
                          flex: 2,
                          child: SizedBox(
                            height: 45,
                            child: OutlinedButton(
                              onPressed: () => _confirmClearCart(context),
                              style: OutlinedButton.styleFrom(
                                foregroundColor: Colors.red,
                                side: const BorderSide(color: Colors.red, width: 1.5),
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(12),
                                ),
                                padding: EdgeInsets.zero, // Reduce padding
                              ),
                              child: const Row(
                                mainAxisAlignment: MainAxisAlignment.center,
                                children: [
                                  Icon(
                                    Icons.delete_outline,
                                    color: Colors.red,
                                    size: 20, // Slightly smaller icon
                                  ),
                                  SizedBox(width: 4), // Less space
                                  Text(
                                    "Clear",
                                    style: TextStyle(
                                      color: Colors.red,
                                      fontWeight: FontWeight.bold,
                                      fontSize: 13, // Slightly smaller text
                                    ),
                                    maxLines: 1, // Force single line
                                    overflow: TextOverflow.visible,
                                  ),
                                ],
                              ),
                            ),
                          ),
                        ),
                        const SizedBox(width: 12),
                        // Main WhatsApp button
                        Expanded(
                          // Reduce flex from 3 to 2 since the clear button is wider
                          flex: 3,
                          child: SizedBox(
                            height: 45,
                            child: ElevatedButton(
                              onPressed: _isLoadingLocation
                                  ? null
                                  : () {
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
                              child: _isLoadingLocation
                                  ? const Row(
                                      mainAxisAlignment: MainAxisAlignment.center,
                                      children: [
                                        SizedBox(
                                          width: 20,
                                          height: 20,
                                          child: CircularProgressIndicator(
                                            color: AppColors.textPrimary,
                                            strokeWidth: 3,
                                          ),
                                        ),
                                        SizedBox(width: 12),
                                        Text(
                                          'Getting location...',
                                          style: TextStyle(
                                            color: AppColors.textPrimary,
                                            fontSize: 16,
                                            fontWeight: FontWeight.bold,
                                          ),
                                        ),
                                      ],
                                    )
                                  : const Text(
                                      'Send to WhatsApp',
                                      style: TextStyle(
                                        color: AppColors.textPrimary,
                                        fontSize: 16,
                                        fontWeight: FontWeight.bold,
                                      ),
                                    ),
                            ),
                          ),
                        ),
                      ],
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
