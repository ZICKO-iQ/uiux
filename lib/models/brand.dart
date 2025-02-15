import 'package:pocketbase/pocketbase.dart';

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
    return Brand(
      id: record.id,
      name: record.get<String>('name'),
      image: record.get<String>('image'),  // Add this field
    );
  }

  static Brand defaultBrand = Brand(
    id: 'default',
    name: 'Other',
  );
}
