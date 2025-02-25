import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../core/colors.dart';
import '../../providers/product_provider.dart';
import '../../providers/category_provider.dart';
import '../../providers/brand_provider.dart';
import '../../providers/filter_provider.dart';
import '../shared/app_bar.dart';
import '../filters/filter_bottom_sheet.dart';
import 'product_widget.dart';

class HomePage extends StatelessWidget {
  const HomePage({super.key});

  void _initializeProviders(BuildContext context) {
    // Initialize providers
    final productProvider = Provider.of<ProductProvider>(context, listen: false);
    final categoryProvider = Provider.of<CategoryProvider>(context, listen: false);
    final brandProvider = Provider.of<BrandProvider>(context, listen: false);
    final filterProvider = Provider.of<FilterProvider>(context, listen: false);

    if (!productProvider.isInitialized) {
      productProvider.loadProducts();
    }
    if (!categoryProvider.isInitialized) {
      categoryProvider.loadCategories();
    }
    if (!brandProvider.isInitialized) {
      brandProvider.loadBrands();
    }
    
    filterProvider.initialize(context);
  }

  @override
  Widget build(BuildContext context) {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _initializeProviders(context);
    });

    return Scaffold(
      backgroundColor: AppColors.bgWhite,
      appBar: CustomAppBar(
        title: "Home",
        onSearchTap: () {},
        onFilterTap: () {
          showModalBottomSheet(
            context: context,
            isScrollControlled: true,
            shape: const RoundedRectangleBorder(
              borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
            ),
            builder: (context) => const FilterBottomSheet(),
          );
        },
      ),
      body: Consumer<FilterProvider>(
        builder: (context, filterProvider, child) {
          return Consumer<ProductProvider>(
            builder: (context, productProvider, child) {
              if (productProvider.isLoading) {
                return const Center(child: CircularProgressIndicator());
              }

              if (productProvider.error != null) {
                return Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      const Icon(Icons.error_outline, size: 60, color: Colors.red),
                      const SizedBox(height: 16),
                      Text(
                        'Error loading products',
                        style: Theme.of(context).textTheme.titleLarge,
                      ),
                      TextButton(
                        onPressed: () => productProvider.loadProducts(),
                        child: const Text('Retry'),
                      ),
                    ],
                  ),
                );
              }

              if (productProvider.products.isEmpty) {
                return const Center(
                  child: Text('No products available'),
                );
              }

              final filteredProducts = filterProvider.getFilteredAndSortedProducts();

              return Column(
                children: [
                  if (filterProvider.hasActiveFilters)
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                      decoration: BoxDecoration(
                        color: AppColors.primary.withOpacity(0.15),
                        border: Border(
                          bottom: BorderSide(
                            color: AppColors.primary.withOpacity(0.2),
                            width: 1,
                          ),
                        ),
                      ),
                      child: Row(
                        children: [
                          Icon(
                            Icons.filter_list,
                            size: 24,
                            color: AppColors.primary.withOpacity(0.8),
                          ),
                          const SizedBox(width: 8),
                          Expanded(
                            child: Text(
                              filterProvider.getActiveFiltersText(),
                              style: const TextStyle(
                                color: AppColors.primary,
                                fontSize: 16,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                          ),
                          InkWell(
                            onTap: () => filterProvider.clearAllFilters(),
                            child: Container(
                              padding: const EdgeInsets.all(4),
                              decoration: BoxDecoration(
                                color: AppColors.error.withOpacity(0.1),
                                borderRadius: BorderRadius.circular(4),
                              ),
                              child: const Icon(
                                Icons.close,
                                size: 20,
                                color: AppColors.error,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  Expanded(
                    child: RefreshIndicator(
                      onRefresh: productProvider.refreshProducts,
                      color: AppColors.primary,
                      child: GridView.builder(
                        padding: const EdgeInsets.all(8),
                        physics: const AlwaysScrollableScrollPhysics(),
                        gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                          crossAxisCount: MediaQuery.of(context).orientation == Orientation.landscape ? 3 : 2, // Changed from 4 to 3
                          childAspectRatio: MediaQuery.of(context).orientation == Orientation.landscape
                              ? 1.05  // Changed from 1.0 to 0.85 for better proportion
                              : MediaQuery.of(context).size.width /
                                (MediaQuery.of(context).size.height * 0.5),
                          crossAxisSpacing: 8,
                          mainAxisSpacing: 8,
                        ),
                        itemCount: filteredProducts.length,
                        itemBuilder: (context, index) {
                          final product = filteredProducts[index];
                          return BuildItemCard(product: product);
                        },
                      ),
                    ),
                  ),
                ],
              );
            },
          );
        },
      ),
    );
  }
}
