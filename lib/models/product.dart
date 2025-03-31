import 'package:pocketbase/pocketbase.dart';
import '../utils/image_validator.dart';
import 'category.dart';
import 'brand.dart';
import '../config/app_config.dart';

enum ProductUnit {
  piece,
  kilo
}

class Product {
  static const String DEFAULT_BRAND = 'Other';
  static const String DEFAULT_BRAND_ID = '96klof1763k9f59';
  static final Brand defaultBrand = Brand(
    id: DEFAULT_BRAND_ID,
    name: DEFAULT_BRAND,
  );
  static final Category defaultCategory = Category(
    id: 'k9164x1pi9602tt',
    name: 'Other',
    image: '',
  );

  final String id;
  final String viewName;
  final String description;
  final Category category;
  final Brand brand;  // Changed from String to Brand
  final int price;
  final int? discountPrice;
  final List<String> images;
  final ProductUnit unit;
  final int quantity; // Add quantity field
  final int maxQuantity; // Add maxQuantity field
  
  Product({
    required this.id,
    required this.viewName,
    required this.description,
    required this.category,
    required this.brand,  // Changed type to Brand
    required this.images,
    required this.unit,
    this.price = 0,
    this.discountPrice,
    required this.quantity, // Initialize quantity
    required this.maxQuantity, // Initialize maxQuantity
  });

  factory Product.fromJson(Map<String, dynamic> json) {
    final quantity = json['quantity']?.toInt() ?? 0;
    var maxQuantity = json['maxQuantity']?.toInt() ?? 0;
    
    // If both quantity and maxQuantity are 0, set maxQuantity to 5
    if (quantity == 0 && maxQuantity == 0) {
      maxQuantity = 5;
    } 
    // If only maxQuantity is 0, set it equal to quantity
    else if (maxQuantity == 0) {
      maxQuantity = quantity;
    }

    return Product(
      id: json['id'] ?? '',
      viewName: json['viewName'] ?? '',
      brand: Brand.fromJson(json['brand'] ?? {}),  // Changed type to Brand
      description: json['description'] ?? '',
      category: Category.fromJson(json['category'] ?? {}),  // Added category conversion
      images: List<String>.from(json['images'] ?? []),
      price: json['price']?.toInt() ?? 0,
      discountPrice: json['discountPrice']?.toInt(),
      unit: json['unit'] == 'kilo' ? ProductUnit.kilo : ProductUnit.piece,  // New field conversion
      quantity: quantity,
      maxQuantity: maxQuantity,
    );
  }

  static Product fromRecordSync(RecordModel record) {
    final expandData = record.expand;
    
    final categoryRecord = expandData['category_id']?.first;
    final brandRecord = expandData['brand_id']?.first;  // Get brand from expand

    final category = Category(
      id: categoryRecord?.id ?? 'k9164x1pi9602tt',
      name: categoryRecord?.data['name'] ?? 'Uncategorized',
      image: categoryRecord?.data['image'] ?? '',
    );

    final brand = brandRecord != null 
        ? Brand(
            id: brandRecord.id,
            name: brandRecord.data['name'] ?? DEFAULT_BRAND,
          )
        : defaultBrand;

    // Handle multiple images from files field
    List<String> images = [];
    if (record.data['images'] != null) {
      final List<String> imageNames = List<String>.from(record.data['images']);
      images = imageNames.map((name) => 
        AppConfig.getFileUrl(record.collectionId, record.id, name)
      ).toList();
    }

    final quantity = (record.data['quantity'] ?? 0).toInt();
    var maxQuantity = (record.data['max_quantity'] ?? 0).toInt();
    
    // If both quantity and maxQuantity are 0, set maxQuantity to 5
    if (quantity == 0 && maxQuantity == 0) {
      maxQuantity = 5;
    }
    // If only maxQuantity is 0, set it equal to quantity
    else if (maxQuantity == 0) {
      maxQuantity = quantity;
    }

    return Product(
      id: record.id,
      viewName: record.data['view_name'] ?? '',
      description: record.data['description'] ?? '',
      category: category,
      brand: brand,
      price: (record.data['price'] ?? 0).toInt(),
      discountPrice: record.data['discount_price']?.toInt(),
      images: ImageValidator.getInitialImages(images),
      unit: record.data['unit'] == 'kilo' ? ProductUnit.kilo : ProductUnit.piece,
      quantity: quantity,
      maxQuantity: maxQuantity,
    );
  }

  static Future<Product> fromRecord(RecordModel record) async {
    return fromRecordSync(record);
  }
}