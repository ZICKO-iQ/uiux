import 'package:pocketbase/pocketbase.dart';
import '../utils/image_validator.dart';
import 'category.dart';

class Product {
  final String id;
  final String viewName;
  final String description;
  final Category category;
  final String brand;
  final int price;
  final int? discountPrice;
  final List<String> images;
  
  Product({
    required this.id,
    required this.viewName,
    required this.brand,
    required this.description,
    required this.category,  // Added required category
    required this.images,
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
    );
  }

  static Future<Product> fromRecord(RecordModel record) async {
    final List<String> rawImages = List<String>.from(record.get<List>('images'));
    final List<String> validatedImages = await ImageValidator.filterValidImages(rawImages);

    return Product(
      id: record.id,
      viewName: record.get<String>('view_name'),
      description: record.get<String>('description'),
      category: (record.expand['category_id'] is List)
          ? Category.fromRecord(record.expand['category_id']?[0] as RecordModel)
          : Category.fromRecord(record.expand['category_id'] as RecordModel),
      brand: record.get<String>('brand'),
      price: record.get<int>('price'),
      discountPrice: record.get<int>('discount_price', null),
      images: validatedImages,
    );
  }
}