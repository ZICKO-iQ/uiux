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
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const Icon(Icons.error_outline, size: 60, color: Colors.red),
                  const SizedBox(height: 16),
                  Text(provider.error!),
                  TextButton(
                    onPressed: () {
                      if (categoryId != null) {
                        provider.loadProductsByCategory(categoryId!);
                      } else if (brandId != null) {
                        provider.loadProductsByBrand(brandId!);
                      }
                    },
                    child: const Text('Retry'),
                  ),
                ],
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
