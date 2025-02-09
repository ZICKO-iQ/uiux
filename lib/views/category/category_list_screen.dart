import 'package:flutter/material.dart';
import 'package:uiux/core/colors.dart';
import 'package:uiux/views/category/category_widget.dart';
import 'package:uiux/views/shared/app_bar.dart';

class CategoryPage extends StatefulWidget {
  const CategoryPage({super.key});

  @override
  State<CategoryPage> createState() => _CategoryPageState();
}

class _CategoryPageState extends State<CategoryPage> with SingleTickerProviderStateMixin {
  late TabController _tabController;

  final List<Map<String, String>> categories = [
    {'name': 'Fruits', 'icon': '🍎'},
    {'name': 'Vegetables', 'icon': '🥕'},
    {'name': 'Dairy', 'icon': '🧀'},
    {'name': 'Bakery', 'icon': '🍞'},
    {'name': 'Meat', 'icon': '🍖'},
    {'name': 'Snacks', 'icon': '🍪'},
  ];

  final List<Map<String, String>> brands = [
    {'name': 'Nike', 'image': 'assets/images/item0.png'},
    {'name': 'Adidas', 'image': 'assets/images/item0.png'},
    {'name': 'Puma', 'image': 'assets/images/item0.png'},
    {'name': 'Apple', 'image': 'assets/images/item0.png'},
    {'name': 'Samsung', 'image': 'assets/images/item0.png'},
  ];

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
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
                Padding(
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
                        name: category['name']!,
                        icon: category['icon']!,
                      );
                    },
                  ),
                ),
                // Brands Tab
                Padding(
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
                        name: brand['name']!,
                        imagePath: brand['image']!,
                      );
                    },
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
