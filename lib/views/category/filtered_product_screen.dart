import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../core/colors.dart';
import '../../providers/product_provider.dart';  // Changed back to product_provider
import '../shared/app_bar.dart';
import '../product/product_widget.dart';

class FilteredProductScreen extends StatelessWidget {
  final String? categoryId;
  final String? brandId;
  final String title;

  const FilteredProductScreen({
    super.key,
    this.categoryId,
    this.brandId,
    required this.title,
  });

  @override
  Widget build(BuildContext context) {
    final productProvider = Provider.of<ProductProvider>(context, listen: false);
    
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (categoryId != null) {
        productProvider.loadProductsByCategory(categoryId!);
      } else if (brandId != null) {
        productProvider.loadProductsByBrand(brandId!);
      }
    });

    return Scaffold(
      backgroundColor: AppColors.bgWhite,
      appBar: CustomAppBar(
        title: title,
        onSearchTap: () {},
      ),
      body: Consumer<ProductProvider>(
        builder: (context, provider, child) {
          if (provider.isLoading) {
            return const Center(child: CircularProgressIndicator());
          }

          if (provider.error != null) {
            return Center(
              child: Container(
                padding: const EdgeInsets.all(24),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    const Icon(
                      Icons.cloud_off_rounded,
                      size: 64,
                      color: Colors.grey,
                    ),
                    const SizedBox(height: 16),
                    Text(
                      'Connection Error',
                      style: TextStyle(
                        fontSize: 20,
                        fontWeight: FontWeight.bold,
                        color: Colors.grey[800],
                      ),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      provider.error!,
                      style: TextStyle(
                        fontSize: 16,
                        color: Colors.grey[600],
                      ),
                      textAlign: TextAlign.center,
                    ),
                    const SizedBox(height: 24),
                    ElevatedButton.icon(
                      onPressed: () {
                        if (categoryId != null) {
                          provider.loadProductsByCategory(categoryId!);
                        } else if (brandId != null) {
                          provider.loadProductsByBrand(brandId!);
                        }
                      },
                      icon: const Icon(Icons.refresh, color: Colors.white),
                      label: const Text('Try Again'),
                      style: ElevatedButton.styleFrom(
                        foregroundColor: Colors.white,
                        backgroundColor: AppColors.primary,
                        padding: const EdgeInsets.symmetric(
                          horizontal: 24,
                          vertical: 12,
                        ),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(8),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            );
          }

          final products = provider.filteredProducts;  // Use filteredProducts instead
          if (products.isEmpty) {
            return Center(
              child: Text('No products available in ${title.toLowerCase()}'),
            );
          }

          return RefreshIndicator(
            onRefresh: () {
              if (categoryId != null) {
                return provider.loadProductsByCategory(categoryId!);
              } else {
                return provider.loadProductsByBrand(brandId!);
              }
            },
            child: GridView.builder(
              padding: const EdgeInsets.fromLTRB(4, 4, 4, 13), // Updated padding
              physics: const AlwaysScrollableScrollPhysics(),
              gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                crossAxisCount: MediaQuery.of(context).orientation == Orientation.landscape ? 4 : 3, // Updated columns
                childAspectRatio: MediaQuery.of(context).orientation == Orientation.landscape
                    ? 0.95
                    : MediaQuery.of(context).size.width /
                      (MediaQuery.of(context).size.height * 0.70), // Updated ratio
                crossAxisSpacing: 4, // Reduced spacing
                mainAxisSpacing: 4, // Reduced spacing
              ),
              itemCount: products.length,
              itemBuilder: (context, index) {
                final product = products[index];
                return BuildItemCard(product: product);
              },
            ),
          );
        },
      ),
    );
  }
}
