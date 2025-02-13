import 'package:pocketbase/pocketbase.dart';
import '../utils/image_validator.dart';
import 'category.dart';

enum ProductUnit {
  piece,
  kilo
}

class Product {
  static const String DEFAULT_BRAND = 'Other';
  static final Category defaultCategory = Category(
    id: 'k9164x1pi9602tt',
    name: 'Other',
    image: '',
  );

  final String id;
  final String viewName;
  final String description;
  final Category category;
  final String brand;
  final int price;
  final int? discountPrice;
  final List<String> images;
  final ProductUnit unit;  // New field
  
  Product({
    required this.id,
    required this.viewName,
    required this.brand,
    required this.description,
    required this.category,  // Added required category
    required this.images,
    required this.unit,    // New required parameter
    this.price = 0,
    this.discountPrice,
  });

  factory Product.fromJson(Map<String, dynamic> json) {
    return Product(
      id: json['id'] ?? '',
      viewName: json['viewName'] ?? '',
      brand: json['brand'] ?? '',
      description: json['description'] ?? '',
      category: Category.fromJson(json['category'] ?? {}),  // Added category conversion
      images: List<String>.from(json['images'] ?? []),
      price: json['price']?.toInt() ?? 0,
      discountPrice: json['discountPrice']?.toInt(),
      unit: json['unit'] == 'kilo' ? ProductUnit.kilo : ProductUnit.piece,  // New field conversion
    );
  }

  static Future<Product> fromRecord(RecordModel record) async {
    final List<String> rawImages = List<String>.from(record.get<List>('images'));
    final List<String> validatedImages = await ImageValidator.filterValidImages(rawImages);

    // Handle empty or null brand
    String brand = record.get<String>('brand');
    if (brand.trim().isEmpty) {
      brand = DEFAULT_BRAND;
    }

    // Handle missing or invalid category
    Category category;
    try {
      category = (record.expand['category_id'] is List)
          ? Category.fromRecord(record.expand['category_id']?[0] as RecordModel)
          : Category.fromRecord(record.expand['category_id'] as RecordModel);
    } catch (e) {
      category = defaultCategory;
    }

    return Product(
      id: record.id,
      viewName: record.get<String>('view_name'),
      description: record.get<String>('description'),
      category: category,
      brand: brand,
      price: record.get<int>('price'),
      discountPrice: record.get<int>('discount_price', null),
      images: validatedImages,
      unit: record.get<String>('unit') == 'kilo' ? ProductUnit.kilo : ProductUnit.piece,  // New field
    );
  }
}