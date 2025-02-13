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

  // New synchronous method for initial load
  static Product fromRecordSync(RecordModel record) {
    final expandData = record.expand['category_id'];
    final categoryRecord = expandData != null && expandData.isNotEmpty 
        ? expandData.first
        : null;

    final category = Category(
      id: categoryRecord?.id ?? 'k9164x1pi9602tt',
      name: categoryRecord?.data['name'] ?? 'Uncategorized',
      image: categoryRecord?.data['image'] ?? '',
    );

    final List<String> images = List<String>.from(record.data['images'] ?? []);

    return Product(
      id: record.id,
      viewName: record.data['view_name'] ?? '',
      description: record.data['description'] ?? '',
      category: category,
      brand: record.data['brand']?.toString().trim().isNotEmpty == true 
          ? record.data['brand'] 
          : DEFAULT_BRAND,
      price: (record.data['price'] ?? 0).toInt(),
      discountPrice: record.data['discount_price']?.toInt(),
      images: ImageValidator.getInitialImages(images),
      unit: record.data['unit'] == 'kilo' ? ProductUnit.kilo : ProductUnit.piece,
    );
  }

  // Simplified to just use fromRecordSync
  static Future<Product> fromRecord(RecordModel record) async {
    return fromRecordSync(record);
  }
}