import 'package:http/http.dart' as http;

class AppConfig {
  static const String privateIp = "192.168.0.102";
  static const String publicIp = "65.20.191.118";
  static const int pbPort = 8090;
  static const Duration _timeout = Duration(seconds: 2);
  
  static String _currentIP = privateIp;
  static bool? _isLocalNetwork;
  
  static String get currentIP => _currentIP;
  static bool get isLocalNetwork => _isLocalNetwork ?? false;
  
  static String get baseUrl => "http://$_currentIP:$pbPort";
  static String get apiUrl => "$baseUrl/api";
  
  static String getFileUrl(String collectionId, String recordId, String fileName) {
    return "$apiUrl/files/$collectionId/$recordId/$fileName";
  }

  static bool isValidHost(String host) {
    return host == privateIp || host == publicIp;
  }

  static Future<bool> checkLocalNetworkAccess() async {
    try {
      final response = await http
          .get(Uri.parse('http://$privateIp:$pbPort/api/health'))
          .timeout(_timeout);
      return response.statusCode == 200;
    } catch (e) {
      return false;
    }
  }

  static Future<void> initializeNetwork() async {
    _isLocalNetwork = await checkLocalNetworkAccess();
    _currentIP = _isLocalNetwork! ? privateIp : publicIp;
  }
}
