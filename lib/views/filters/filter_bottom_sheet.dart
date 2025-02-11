import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../providers/product_provider.dart';
import '../../core/colors.dart';

class FilterBottomSheet extends StatefulWidget {
  const FilterBottomSheet({Key? key}) : super(key: key);

  @override
  State<FilterBottomSheet> createState() => _FilterBottomSheetState();
}

class _FilterBottomSheetState extends State<FilterBottomSheet> {
  String? selectedCategory;
  String? selectedBrand;
  String selectedSort = 'none';

  @override
  void initState() {
    super.initState();
    final provider = Provider.of<ProductProvider>(context, listen: false);
    selectedCategory = provider.selectedCategoryId;
    selectedBrand = provider.selectedBrand;
    selectedSort = provider.sortBy;
  }

  @override
  Widget build(BuildContext context) {
    return Consumer<ProductProvider>(
      builder: (context, provider, child) {
        // Filter out brands with 0 products for the current category
        final availableBrands = provider.availableBrands.where(
          (brand) => provider.getBrandCount(brand, selectedCategory) > 0
        ).toList();

        return Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: AppColors.bgWhite,
            borderRadius: const BorderRadius.vertical(top: Radius.circular(20)),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity(0.1),
                blurRadius: 10,
                offset: const Offset(0, -5),
              ),
            ],
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    'Filter & Sort',
                    style: TextStyle(
                      fontSize: 20,
                      fontWeight: FontWeight.bold,
                      color: AppColors.textSecondary,
                    ),
                  ),
                  TextButton(
                    onPressed: () {
                      provider.clearFilters();
                      Navigator.pop(context);
                    },
                    style: TextButton.styleFrom(
                      foregroundColor: AppColors.error,
                    ),
                    child: const Text(
                      'Clear All',
                      style: TextStyle(fontWeight: FontWeight.bold),
                    ),
                  ),
                ],
              ),
              Divider(color: AppColors.primary.withOpacity(0.2)),
              _buildSection(
                'Category',
                Theme(
                  data: Theme.of(context).copyWith(
                    canvasColor: AppColors.bgWhite,
                  ),
                  child: DropdownButton<String>(
                    value: selectedCategory,
                    isExpanded: true,
                    hint: Text('Select Category', 
                      style: TextStyle(color: AppColors.textSecondary.withOpacity(0.7))
                    ),
                    icon: Icon(Icons.arrow_drop_down, color: AppColors.primary),
                    underline: Container(
                      height: 2,
                      color: AppColors.primary.withOpacity(0.3),
                    ),
                    items: [
                      DropdownMenuItem(
                        value: null,
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            const Text('All Categories'),
                            Text(
                              '(${provider.getCategoryCount(null)})',
                              style: TextStyle(color: Colors.grey[600]),
                            ),
                          ],
                        ),
                      ),
                      ...provider.categories.map((category) {
                        return DropdownMenuItem(
                          value: category.id,
                          child: Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              Text(category.name),
                              Text(
                                '(${provider.getCategoryCount(category.id)})',
                                style: TextStyle(color: Colors.grey[600]),
                              ),
                            ],
                          ),
                        );
                      }),
                    ],
                    onChanged: (value) => setState(() {
                      selectedCategory = value;
                      selectedBrand = null;
                    }),
                  ),
                ),
              ),
              _buildSection(
                'Brand',
                Theme(
                  data: Theme.of(context).copyWith(
                    canvasColor: AppColors.bgWhite,
                  ),
                  child: DropdownButton<String>(
                    value: selectedBrand,
                    isExpanded: true,
                    hint: Text('Select Brand', style: TextStyle(color: AppColors.textSecondary.withOpacity(0.7))),
                    icon: Icon(Icons.arrow_drop_down, color: AppColors.primary),
                    underline: Container(
                      height: 2,
                      color: AppColors.primary.withOpacity(0.3),
                    ),
                    items: [
                      DropdownMenuItem(
                        value: null,
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            const Text('All Brands'),
                            Text(
                              '(${provider.getBrandCount(null, selectedCategory)})',
                              style: TextStyle(color: Colors.grey[600]),
                            ),
                          ],
                        ),
                      ),
                      ...availableBrands.map((brand) {
                        return DropdownMenuItem(
                          value: brand,
                          child: Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              Text(brand),
                              Text(
                                '(${provider.getBrandCount(brand, selectedCategory)})',
                                style: TextStyle(color: Colors.grey[600]),
                              ),
                            ],
                          ),
                        );
                      }),
                    ],
                    onChanged: (value) => setState(() => selectedBrand = value),
                  ),
                ),
              ),
              _buildSection(
                'Sort By',
                Theme(
                  data: Theme.of(context).copyWith(
                    canvasColor: AppColors.bgWhite,
                  ),
                  child: DropdownButton<String>(
                    value: selectedSort,
                    isExpanded: true,
                    hint: Text('Select Sorting', 
                      style: TextStyle(color: AppColors.textSecondary.withOpacity(0.7))
                    ),
                    icon: Icon(Icons.arrow_drop_down, color: AppColors.primary),
                    underline: Container(
                      height: 2,
                      color: AppColors.primary.withOpacity(0.3),
                    ),
                    items: const [
                      DropdownMenuItem(value: 'none', child: Text('None')),
                      DropdownMenuItem(value: 'price_asc', child: Text('Price: Low to High')),
                      DropdownMenuItem(value: 'price_desc', child: Text('Price: High to Low')),
                      DropdownMenuItem(value: 'name_asc', child: Text('Name: A to Z')),
                      DropdownMenuItem(value: 'name_desc', child: Text('Name: Z to A')),
                    ],
                    onChanged: (value) => setState(() => selectedSort = value!),
                  ),
                ),
              ),
              const SizedBox(height: 16),
              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppColors.primary,
                    padding: const EdgeInsets.symmetric(vertical: 16),
                    elevation: 2,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                  onPressed: () {
                    provider.setFilters(
                      categoryId: selectedCategory,
                      brand: selectedBrand,
                    );
                    provider.setSortBy(selectedSort);
                    Navigator.pop(context);
                  },
                  child: const Text(
                    'Apply',
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  Widget _buildSection(String title, Widget child) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          title,
          style: TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.bold,
            color: AppColors.textSecondary,
          ),
        ),
        const SizedBox(height: 8),
        child,
        const SizedBox(height: 16),
      ],
    );
  }
}
