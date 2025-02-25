import 'package:pocketbase/pocketbase.dart';
import '../config/app_config.dart';

class Category {
  final String id;
  final String name;
  final String image;

  Category({
    required this.id,
    required this.name,
    required this.image,
  });

  factory Category.fromJson(Map<String, dynamic> json) {
    return Category(
      id: json['id'] ?? '',
      name: json['name'] ?? '',
      image: json['image'] ?? '',
    );
  }

  factory Category.fromRecord(RecordModel record) {
    final fileName = record.getStringValue('image');
    final imageUrl = fileName.isNotEmpty 
        ? '${AppConfig.baseUrl}/api/files/${record.collectionId}/${record.id}/$fileName'
        : '';
        
    return Category(
      id: record.id,
      name: record.getStringValue('name'),
      image: imageUrl,
    );
  }
}
