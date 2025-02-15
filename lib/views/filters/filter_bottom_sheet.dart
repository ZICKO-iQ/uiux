import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../providers/category_provider.dart';
import '../../providers/brand_provider.dart';
import '../../providers/filter_provider.dart';
import '../../core/colors.dart';

class FilterBottomSheet extends StatefulWidget {
  const FilterBottomSheet({Key? key}) : super(key: key);

  @override
  State<FilterBottomSheet> createState() => _FilterBottomSheetState();
}

class _FilterBottomSheetState extends State<FilterBottomSheet> {
  String? selectedCategory;
  String? selectedBrandId;
  String selectedSort = 'none';

  @override
  void initState() {
    super.initState();
    final filterProvider = Provider.of<FilterProvider>(context, listen: false);
    selectedCategory = filterProvider.selectedCategoryId;
    selectedBrandId = filterProvider.selectedBrandId;
    selectedSort = filterProvider.sortBy;
  }

  @override
  Widget build(BuildContext context) {
    return Consumer<FilterProvider>(
      builder: (context, filterProvider, child) {
        final availableBrands = filterProvider.getAvailableBrandsForCategory();
        
        // Reset brand selection if current brand is not available for selected category
        if (selectedBrandId != null && 
            !availableBrands.any((b) => b.id == selectedBrandId)) {
          selectedBrandId = null;
        }

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
                      filterProvider.clearAllFilters();
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
              Consumer<CategoryProvider>(
                builder: (context, categoryProvider, _) {
                  return _buildSection(
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
                                  '(${filterProvider.getCategoryItemCount(null)})',
                                  style: TextStyle(
                                    color: AppColors.textSecondary.withOpacity(0.7),
                                  ),
                                ),
                              ],
                            ),
                          ),
                          ...categoryProvider.categories
                            .where((category) => filterProvider.getCategoryItemCount(category.id) > 0) // Only show categories with products
                            .map((category) {
                            final count = filterProvider.getCategoryItemCount(category.id);
                            return DropdownMenuItem(
                              value: category.id,
                              child: Row(
                                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                children: [
                                  Flexible(
                                    child: Text(
                                      category.name,
                                      overflow: TextOverflow.ellipsis,
                                    ),
                                  ),
                                  const SizedBox(width: 8),
                                  Text(
                                    '($count)',
                                    style: TextStyle(
                                      color: AppColors.textSecondary.withOpacity(0.7),
                                    ),
                                  ),
                                ],
                              ),
                            );
                          }),
                        ],
                        onChanged: (value) => setState(() {
                          selectedCategory = value;
                          selectedBrandId = null; // Reset brand when category changes
                        }),
                      ),
                    ),
                  );
                },
              ),
              Consumer<BrandProvider>(
                builder: (context, brandProvider, _) {
                  return _buildSection(
                    'Brand',
                    Theme(
                      data: Theme.of(context).copyWith(
                        canvasColor: AppColors.bgWhite,
                      ),
                      child: DropdownButton<String>(
                        value: selectedBrandId,
                        isExpanded: true,
                        hint: Text('Select Brand', 
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
                                const Text('All Brands'),
                                Text(
                                  '(${filterProvider.getBrandItemCount(null, selectedCategory)})',
                                  style: TextStyle(
                                    color: AppColors.textSecondary.withOpacity(0.7),
                                  ),
                                ),
                              ],
                            ),
                          ),
                          ...availableBrands
                            .where((brand) => filterProvider.getBrandItemCount(brand.id, selectedCategory) > 0) // Only show brands with products
                            .map((brand) {
                            final count = filterProvider.getBrandItemCount(brand.id, selectedCategory);
                            return DropdownMenuItem(
                              value: brand.id,
                              child: Row(
                                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                children: [
                                  Flexible(
                                    child: Text(
                                      brand.name,
                                      overflow: TextOverflow.ellipsis,
                                    ),
                                  ),
                                  const SizedBox(width: 8),
                                  Text(
                                    '($count)',
                                    style: TextStyle(
                                      color: AppColors.textSecondary.withOpacity(0.7),
                                    ),
                                  ),
                                ],
                              ),
                            );
                          }),
                        ],
                        onChanged: (value) => setState(() => selectedBrandId = value),
                      ),
                    ),
                  );
                },
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
                    filterProvider.applyFilters(
                      categoryId: selectedCategory,
                      brandId: selectedBrandId,
                      sortBy: selectedSort,
                    );
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
