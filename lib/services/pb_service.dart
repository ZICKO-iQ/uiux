import 'package:pocketbase/pocketbase.dart';

class PocketbaseService {
  static final PocketbaseService _instance = PocketbaseService._internal();
  factory PocketbaseService() => _instance;
  PocketbaseService._internal();
  
  final pb = PocketBase('http://192.168.0.102:8090');
}