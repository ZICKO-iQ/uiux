import 'package:pocketbase/pocketbase.dart';

class PocketbaseService {
  static final PocketbaseService _instance = PocketbaseService._internal();
  factory PocketbaseService() => _instance;
  PocketbaseService._internal();
  
  final pb = PocketBase('http://10.0.2.2:8090');
}