import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:uiux/core/colors.dart';
import 'package:uiux/providers/category_provider.dart';
import 'package:uiux/providers/brand_provider.dart';
import 'package:uiux/views/category/category_widget.dart';
import 'package:uiux/views/shared/app_bar.dart';
import '../category/filtered_product_screen.dart'; // Add this import

class CategoryPage extends StatefulWidget {
  const CategoryPage({super.key});

  @override
  State<CategoryPage> createState() => _CategoryPageState();
}

class _CategoryPageState extends State<CategoryPage> with SingleTickerProviderStateMixin {
  late TabController _tabController;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
    
    // Initialize data
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final categoryProvider = Provider.of<CategoryProvider>(context, listen: false);
      final brandProvider = Provider.of<BrandProvider>(context, listen: false);
      
      if (!categoryProvider.isInitialized) {
        categoryProvider.loadCategories();
      }
      if (!brandProvider.isInitialized) {
        brandProvider.loadBrands();
      }
    });
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  Widget _buildLoadingIndicator() {
    return const Center(
      child: CircularProgressIndicator(),
    );
  }

  Widget _buildErrorView(String message, VoidCallback onRetry) {
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
              'Failed to connect to server',
              style: TextStyle(
                fontSize: 16,
                color: Colors.grey[600],
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 24),
            ElevatedButton.icon(
              onPressed: onRetry,
              icon: const Icon(Icons.refresh, color: AppColors.bgWhite,),
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

  Widget _buildCategoryGrid(List<dynamic> items, bool isCategory) {
    return GridView.builder(
      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 2,
        crossAxisSpacing: 16,
        mainAxisSpacing: 16,
        childAspectRatio: 1.2,
      ),
      itemCount: items.length,
      itemBuilder: (context, index) {
        final sortedItems = items.toList()
          ..sort((a, b) {
            if (a.name.toLowerCase() == 'other') return 1;
            if (b.name.toLowerCase() == 'other') return -1;
            return a.name.compareTo(b.name);
          });
        final item = sortedItems[index];
        
        return GestureDetector(
          onTap: () {
            if (isCategory) {
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (context) => FilteredProductScreen(
                    categoryId: item.id,
                    title: item.name,
                  ),
                ),
              );
            } else {
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (context) => FilteredProductScreen(
                    brandId: item.id,
                    title: item.name,
                  ),
                ),
              );
            }
          },
          child: ItemCard(
            name: item.name,
            image: item.image,
          ),
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: CustomAppBar(title: 'Categories & Brands',
        onSearchTap: () {},),
      backgroundColor: AppColors.bgWhite,
      body: Column(
        children: [
          Container(
            color: Colors.white,
            child: TabBar(
              controller: _tabController,
              labelColor: AppColors.primary,
              unselectedLabelColor: Colors.grey,
              indicatorColor: AppColors.primary,
              tabs: const [
                Tab(text: 'Categories'),
                Tab(text: 'Brands'),
              ],
            ),
          ),
          Expanded(
            child: TabBarView(
              controller: _tabController,
              children: [
                // Categories Tab
                Consumer<CategoryProvider>(
                  builder: (context, categoryProvider, child) {
                    if (categoryProvider.isLoading) {
                      return _buildLoadingIndicator();
                    }

                    if (categoryProvider.error != null) {
                      return _buildErrorView(
                        categoryProvider.error!,
                        () => categoryProvider.refreshCategories(),
                      );
                    }

                    final categories = categoryProvider.categories;
                    if (categories.isEmpty) {
                      return const Center(
                        child: Text('No categories available'),
                      );
                    }

                    return RefreshIndicator(
                      onRefresh: categoryProvider.refreshCategories,
                      child: Padding(
                        padding: const EdgeInsets.all(16.0),
                        child: _buildCategoryGrid(categories, true),
                      ),
                    );
                  },
                ),
                // Brands Tab
                Consumer<BrandProvider>(
                  builder: (context, brandProvider, child) {
                    if (brandProvider.isLoading) {
                      return _buildLoadingIndicator();
                    }

                    if (brandProvider.error != null) {
                      return _buildErrorView(
                        brandProvider.error!,
                        () => brandProvider.refreshBrands(),
                      );
                    }

                    final brands = brandProvider.brands;
                    if (brands.isEmpty) {
                      return const Center(
                        child: Text('No brands available'),
                      );
                    }

                    return RefreshIndicator(
                      onRefresh: brandProvider.refreshBrands,
                      child: Padding(
                        padding: const EdgeInsets.all(16.0),
                        child: _buildCategoryGrid(brands, false),
                      ),
                    );
                  },
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
