import 'package:http/http.dart' as http;

class AppConfig {
  static const String PRIVATE_IP = "192.168.0.102";
  static const String PUBLIC_IP = "65.20.191.118";
  static const int PB_PORT = 8090;
  static const Duration _timeout = Duration(seconds: 2);
  
  static String _currentIP = PRIVATE_IP;
  static bool? _isLocalNetwork;
  
  static String get currentIP => _currentIP;
  static bool get isLocalNetwork => _isLocalNetwork ?? false;
  
  static String get baseUrl => "http://$_currentIP:$PB_PORT";
  static String get apiUrl => "$baseUrl/api";
  
  static String getFileUrl(String collectionId, String recordId, String fileName) {
    return "$apiUrl/files/$collectionId/$recordId/$fileName";
  }

  static bool isValidHost(String host) {
    return host == PRIVATE_IP || host == PUBLIC_IP;
  }

  static Future<bool> checkLocalNetworkAccess() async {
    try {
      final response = await http
          .get(Uri.parse('http://$PRIVATE_IP:$PB_PORT/api/health'))
          .timeout(_timeout);
      return response.statusCode == 200;
    } catch (e) {
      return false;
    }
  }

  static Future<void> initializeNetwork() async {
    _isLocalNetwork = await checkLocalNetworkAccess();
    _currentIP = _isLocalNetwork! ? PRIVATE_IP : PUBLIC_IP;
  }
}
