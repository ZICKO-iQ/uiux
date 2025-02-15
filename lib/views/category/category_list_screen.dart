import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:uiux/core/colors.dart';
import 'package:uiux/providers/category_provider.dart';
import 'package:uiux/providers/brand_provider.dart';
import 'package:uiux/views/category/category_widget.dart';
import 'package:uiux/views/shared/app_bar.dart';

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

  Widget _buildErrorView(String message) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const Icon(Icons.error_outline, size: 48, color: Colors.red),
          const SizedBox(height: 16),
          Text(
            message,
            style: const TextStyle(color: Colors.red),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: CustomAppBar(title: 'Categories & Brands'),
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
                      return _buildErrorView(categoryProvider.error!);
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
                        child: GridView.builder(
                          gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                            crossAxisCount: 2,
                            crossAxisSpacing: 16,
                            mainAxisSpacing: 16,
                            childAspectRatio: 1.2,
                          ),
                          itemCount: categories.length,
                          itemBuilder: (context, index) {
                            final category = categories[index];
                            return CategoryCard(
                              name: category.name,
                              image: category.image,  // Changed from icon to image
                            );
                          },
                        ),
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
                      return _buildErrorView(brandProvider.error!);
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
                        child: GridView.builder(
                          gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                            crossAxisCount: 2,
                            crossAxisSpacing: 16,
                            mainAxisSpacing: 16,
                            childAspectRatio: 1.2,
                          ),
                          itemCount: brands.length,
                          itemBuilder: (context, index) {
                            final brand = brands[index];
                            return BrandCard(
                              name: brand.name,
                              imagePath: brand.image,  // Make sure Brand model has image field
                            );
                          },
                        ),
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
