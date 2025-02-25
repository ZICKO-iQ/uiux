import 'package:pocketbase/pocketbase.dart';
import '../config/app_config.dart';

class Brand {
  final String id;
  final String name;
  final String image;  // Add this field

  Brand({
    required this.id,
    required this.name,
    this.image = '',  // Add this parameter
  });

  factory Brand.fromJson(Map<String, dynamic> json) {
    return Brand(
      id: json['id'] ?? '',
      name: json['name'] ?? '',
    );
  }

  factory Brand.fromRecord(RecordModel record) {
    final fileName = record.getStringValue('image');
    final imageUrl = fileName.isNotEmpty 
        ? '${AppConfig.baseUrl}/api/files/${record.collectionId}/${record.id}/$fileName'
        : '';

    return Brand(
      id: record.id,
      name: record.getStringValue('name'),
      image: imageUrl,
    );
  }

  static Brand defaultBrand = Brand(
    id: 'default',
    name: 'Other',
  );
}
