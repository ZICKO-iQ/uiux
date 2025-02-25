import 'package:flutter/material.dart';
import 'package:uiux/core/colors.dart';
import '../../utils/image_validator.dart';

class ItemCard extends StatelessWidget {
  final String name;
  final String image;

  const ItemCard({
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
      child: Padding(
        padding: const EdgeInsets.all(8),
        child: Column(
          children: [
            Expanded(
              child: ValidatedNetworkImage(
                imageUrl: image,
                width: double.infinity,
                height: double.infinity,
                fit: BoxFit.contain,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              name,
              style: const TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.w600,
                color: Colors.black87,
              ),
              textAlign: TextAlign.center,
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
            ),
          ],
        ),
      ),
    );
  }
}