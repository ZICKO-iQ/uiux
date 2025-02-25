import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../providers/search_provider.dart';
import '../../core/colors.dart';
import '../shared/app_bar.dart';
import '../product/product_widget.dart';
import '../category/category_widget.dart';
import '../category/filtered_product_screen.dart';

class SearchScreen extends StatefulWidget {
  static const String routeName = 'search';
  final String searchQuery;

  const SearchScreen({
    Key? key,
    required this.searchQuery,
  }) : super(key: key);

  @override
  State<SearchScreen> createState() => _SearchScreenState();
}

class _SearchScreenState extends State<SearchScreen> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final searchProvider = Provider.of<SearchProvider>(context, listen: false);
      searchProvider.clearSearch(); // Clear previous results
      searchProvider.performSearch(widget.searchQuery);
    });
  }

  Widget _buildCategoriesAndBrandsSection(SearchProvider searchProvider) {
    if (searchProvider.categories.isEmpty && searchProvider.brands.isEmpty) {
      return const SizedBox.shrink();
    }

    // Create separate lists for categories and brands
    final categories = searchProvider.categories;
    final brands = searchProvider.brands;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'Categories & Brands',
          style: TextStyle(
            fontSize: 20,
            fontWeight: FontWeight.bold,
          ),
        ),
        const SizedBox(height: 12),
        SizedBox(
          height: 120,
          child: ListView(
            scrollDirection: Axis.horizontal,
            children: [
              // Categories
              ...categories.map((category) => Padding(
                padding: const EdgeInsets.only(right: 8),
                child: SizedBox(
                  width: 100,
                  child: GestureDetector(
                    onTap: () => Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (context) => FilteredProductScreen(
                          categoryId: category.id,
                          title: category.name,
                        ),
                      ),
                    ),
                    child: ItemCard(
                      name: category.name,
                      image: category.image,
                    ),
                  ),
                ),
              )),
              // Brands
              ...brands.map((brand) => Padding(
                padding: const EdgeInsets.only(right: 8),
                child: SizedBox(
                  width: 100,
                  child: GestureDetector(
                    onTap: () => Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (context) => FilteredProductScreen(
                          brandId: brand.id,
                          title: brand.name,
                        ),
                      ),
                    ),
                    child: ItemCard(
                      name: brand.name,
                      image: brand.image,
                    ),
                  ),
                ),
              )),
            ],
          ),
        ),
        const Divider(height: 24),
      ],
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.bgWhite,
      appBar: CustomAppBar(
        title: 'Search Results',
        onSearchTap: () {},
      ),
      body: Consumer<SearchProvider>(
        builder: (context, searchProvider, _) {
          if (searchProvider.isLoading) {
            return const Center(child: CircularProgressIndicator());
          }

          final hasCategoriesOrBrands = 
              searchProvider.categories.isNotEmpty || 
              searchProvider.brands.isNotEmpty;

          return SingleChildScrollView(
            padding: const EdgeInsets.all(16.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                if (hasCategoriesOrBrands)
                  _buildCategoriesAndBrandsSection(searchProvider),
                const Text(
                  'Products',
                  style: TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 12),
                if (searchProvider.products.isEmpty)
                  const Center(
                    child: Padding(
                      padding: EdgeInsets.all(16.0),
                      child: Text('No products found'),
                    ),
                  )
                else
                  GridView.builder(
                    shrinkWrap: true,
                    physics: const NeverScrollableScrollPhysics(),
                    gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                      crossAxisCount: 2,
                      childAspectRatio: MediaQuery.of(context).size.width /
                          (MediaQuery.of(context).size.height * 0.55),
                      crossAxisSpacing: 8,
                      mainAxisSpacing: 8,
                    ),
                    itemCount: searchProvider.products.length,
                    itemBuilder: (context, index) {
                      return BuildItemCard(
                        product: searchProvider.products[index]
                      );
                    },
                  ),
              ],
            ),
          );
        },
      ),
    );
  }
}
