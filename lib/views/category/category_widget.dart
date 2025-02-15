import 'package:flutter/material.dart';
import 'package:uiux/core/colors.dart';
import '../../utils/image_validator.dart';

class CategoryCard extends StatelessWidget {
  final String name;
  final String image;

  const CategoryCard({
    super.key,
    required this.name,
    required this.image,
  });

  @override
  Widget build(BuildContext context) {
    return Card(
      color: AppColors.bgWhite,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
      ),
      elevation: 4,
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          ValidatedNetworkImage(
            imageUrl: image,
            width: 80,
            height: 80,  
            fit: BoxFit.contain,
          ),
          const SizedBox(height: 5),
          Text(
            name,
            style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }
}

class BrandCard extends StatelessWidget {
  final String name;
  final String imagePath;

  const BrandCard({
    super.key,
    required this.name,
    required this.imagePath,
  });

  @override
  Widget build(BuildContext context) {
    return Card(
      color: AppColors.bgWhite,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
      ),
      elevation: 4,
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          ValidatedNetworkImage(
            imageUrl: imagePath,
            height: 80,  // Increased from 50
            width: 80,   // Increased from 50
            fit: BoxFit.contain,
          ),
          const SizedBox(height: 12),  // Increased from 8
          Text(
            name,
            style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }
}