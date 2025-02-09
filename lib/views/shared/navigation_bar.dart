import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:uiux/core/colors.dart';
import 'package:uiux/providers/navigation_provider.dart';
import 'package:uiux/providers/cart_provider.dart';  // Add this import
import 'dart:ui';

class CustomNavigationBar extends StatelessWidget {
  final int selectedIndex;
  final Function(int) onTabTapped;

  CustomNavigationBar({required this.selectedIndex, required this.onTabTapped});

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.8),
        borderRadius: BorderRadius.circular(25),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 30,
            offset: Offset(0, 10),
          ),
        ],
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(25),
        child: BackdropFilter(
          filter: ImageFilter.blur(sigmaX: 5, sigmaY: 5),
          child: Container(
            height: 65,
            padding: EdgeInsets.symmetric(horizontal: 20),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceAround,
              children: [
                _buildNavItem(context, 0, Icons.home_outlined, 'Home'),
                _buildNavItem(context, 1, Icons.grid_view_rounded, 'Category'),
                _buildNavItem(context, 2, Icons.shopping_bag_outlined, 'Cart'),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildNavItem(BuildContext context, int index, IconData icon, String label) {
    final isSelected = selectedIndex == index;
    
    return GestureDetector(
      onTap: () {
        onTabTapped(index);
        Provider.of<NavigationProvider>(context, listen: false).setSelectedIndex(index);
      },
      child: AnimatedContainer(
        duration: Duration(milliseconds: 400),
        curve: Curves.easeOutCubic,
        padding: EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        margin: EdgeInsets.symmetric(vertical: 4),
        decoration: BoxDecoration(
          color: isSelected ? AppColors.activeBtn.withOpacity(0.1) : Colors.transparent,
          borderRadius: BorderRadius.circular(15),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            SizedBox(
              width: 40,
              height: 40,
              child: Stack(
                clipBehavior: Clip.none,
                children: [
                  TweenAnimationBuilder(
                    duration: Duration(milliseconds: 300),
                    curve: Curves.easeOutCubic,
                    tween: ColorTween(
                      begin: AppColors.notActiveBtn,
                      end: isSelected ? AppColors.activeBtn : AppColors.notActiveBtn,
                    ),
                    builder: (context, Color? color, Widget? child) {
                      return AnimatedContainer(
                        duration: Duration(milliseconds: 300),
                        curve: Curves.easeOutCubic,
                        padding: EdgeInsets.all(8),
                        decoration: BoxDecoration(
                          color: isSelected ? AppColors.activeBtn : Colors.transparent,
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: Icon(
                          icon,
                          color: isSelected ? AppColors.bgWhite : color,
                          size: 24,
                        ),
                      );
                    },
                  ),
                  if (index == 2 && !isSelected) // Only show badge for cart when not selected
                    Positioned(
                      top: 2,     // Changed from -5 to 2
                      right: 2,   // Changed from -5 to 2
                      child: Consumer<CartProvider>(
                        builder: (context, cart, child) {
                          final totalItems = cart.items.fold(
                            0, 
                            (sum, item) => sum + item.quantity
                          );
                          
                          if (totalItems == 0) return const SizedBox.shrink();
                          
                          return Container(
                            padding: const EdgeInsets.all(3),  // Reduced padding from 4 to 3
                            constraints: const BoxConstraints(
                              minWidth: 16,    // Reduced from 18 to 16
                              minHeight: 16,   // Reduced from 18 to 16
                            ),
                            decoration: const BoxDecoration(
                              color: Colors.red,
                              shape: BoxShape.circle,
                            ),
                            child: Center(
                              child: Text(
                                totalItems.toString(),
                                style: const TextStyle(
                                  color: Colors.white,
                                  fontSize: 10,
                                  fontWeight: FontWeight.bold,
                                ),
                                textAlign: TextAlign.center,
                              ),
                            ),
                          );
                        },
                      ),
                    ),
                ],
              ),
            ),
            ClipRect(
              child: AnimatedAlign(
                duration: Duration(milliseconds: 300),
                curve: Curves.easeOutCubic,
                alignment: Alignment.centerLeft,
                widthFactor: isSelected ? 1 : 0,
                child: Padding(
                  padding: EdgeInsets.only(left: 8),
                  child: AnimatedOpacity(
                    duration: Duration(milliseconds: 200),
                    curve: Curves.easeOut,
                    opacity: isSelected ? 1.0 : 0.0,
                    child: Text(
                      label,
                      style: TextStyle(
                        color: AppColors.activeBtn,
                        fontWeight: FontWeight.bold,
                        fontSize: 14,
                      ),
                    ),
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
