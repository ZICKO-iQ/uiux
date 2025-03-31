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
import '../../widgets/banner_carousel.dart';

class HomePage extends StatelessWidget {
  const HomePage({super.key});

  void _initializeProviders(BuildContext context) {
    // Initialize only required providers
    final categoryProvider = Provider.of<CategoryProvider>(context, listen: false);
    final brandProvider = Provider.of<BrandProvider>(context, listen: false);
    final filterProvider = Provider.of<FilterProvider>(context, listen: false);

    // ProductProvider now auto-initializes
    if (!categoryProvider.isInitialized) {
      categoryProvider.loadCategories();
    }
    if (!brandProvider.isInitialized) {
      brandProvider.loadBrands();
    }
    
    filterProvider.initialize(context);
  }

  Widget _buildErrorView(BuildContext context, String message) {
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
              message,
              style: TextStyle(
                fontSize: 16,
                color: Colors.grey[600],
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 24),
            ElevatedButton.icon(
              onPressed: () {
                // Use the new refresh method
                Provider.of<ProductProvider>(context, listen: false).refreshProducts();
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
                return _buildErrorView(
                  context,
                  productProvider.error!,
                );
              }

              if (productProvider.products.isEmpty) {
                return const Center(
                  child: Text('No products available'),
                );
              }

              final filteredProducts = filterProvider.getFilteredAndSortedProducts();

              return RefreshIndicator(
                onRefresh: productProvider.refreshProducts,
                color: AppColors.primary,
                child: Column(
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
                      child: CustomScrollView(
                        physics: const AlwaysScrollableScrollPhysics(),
                        slivers: [
                          SliverToBoxAdapter(
                            child: Padding(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 8.0,
                                vertical: 16.0,
                              ),
                              child: PromotionalBanner(),
                            ),
                          ),
                          SliverPadding(
                            padding: const EdgeInsets.fromLTRB(4, 4, 4, 13),
                            sliver: SliverGrid(
                              gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                                crossAxisCount: MediaQuery.of(context).orientation == Orientation.landscape ? 4 : 3,
                                childAspectRatio: MediaQuery.of(context).orientation == Orientation.landscape
                                    ? 0.95
                                    : MediaQuery.of(context).size.width /
                                      (MediaQuery.of(context).size.height * 0.70),
                                crossAxisSpacing: 4,
                                mainAxisSpacing: 4,
                              ),
                              delegate: SliverChildBuilderDelegate(
                                (context, index) {
                                  final product = filteredProducts[index];
                                  return BuildItemCard(product: product);
                                },
                                childCount: filteredProducts.length,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              );
            },
          );
        },
      ),
    );
  }
}
