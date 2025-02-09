import 'package:pocketbase/pocketbase.dart';

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
    return Category(
      id: record.id,
      name: record.get<String>('name'),
      image: record.get<String>('image'),
    );
  }
}
