import 'package:pocketbase/pocketbase.dart';
import '../config/app_config.dart';

class PocketbaseService {
  static final PocketbaseService _instance = PocketbaseService._internal();
  factory PocketbaseService() => _instance;
  PocketbaseService._internal();
  
  PocketBase? _pb;
  bool _initialized = false;

  Future<PocketBase> get pb async {
    if (!_initialized) {
      await _initialize();
    }
    return _pb!;
  }

  Future<void> _initialize() async {
    if (!_initialized) {
      await AppConfig.initializeNetwork();
      _pb = PocketBase(AppConfig.baseUrl);
      _initialized = true;
    }
  }
}