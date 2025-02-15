import 'dart:async';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import '../config/app_config.dart';

class ImageValidator {
  static const Duration _timeout = Duration(seconds: 5);
  static const String _fallbackImage = 'assets/images/placeholder.png';
  
  static Future<bool> isValidImage(String imageUrl) async {
    if (imageUrl.isEmpty) return false;
    
    Uri? uri;
    try {
      uri = Uri.parse(imageUrl);
      
      // Accept our PocketBase URLs without validation using AppConfig
      if (AppConfig.isValidHost(uri.host)) {
        if (uri.port == AppConfig.PB_PORT && uri.path.contains('/api/files/')) {
          return true;
        }
      }

      final response = await http.head(uri).timeout(_timeout);
      return response.statusCode < 400; // Accept any successful response
    } catch (e) {
      print('Error validating image $imageUrl: $e');
      // If HEAD request fails, try GET request as fallback
      try {
        if (uri != null) {
          final response = await http.get(uri).timeout(_timeout);
          return response.statusCode < 400;
        }
        return false;
      } catch (e) {
        return false;
      }
    }
  }

  static List<String> getInitialImages(List<String> images) {
    if (images.isEmpty) return [_fallbackImage];
    
    // Accept PocketBase URLs and regular URLs
    final validUrls = images.where((url) => 
      url.isNotEmpty && 
      (url.startsWith('http://') || 
       url.startsWith('https://') ||
       url.contains('${AppConfig.apiUrl}/files/'))
    ).toList();
    
    return validUrls.isEmpty ? [_fallbackImage] : validUrls;
  }

  static Future<List<String>> validateImagesInBackground(List<String> images) async {
    if (images.isEmpty) return [_fallbackImage];

    // First, filter using basic URL validation
    final initialImages = getInitialImages(images);
    if (initialImages.first == _fallbackImage) return initialImages;

    // Then validate URLs in parallel
    final results = await Future.wait(
      initialImages.map((url) => isValidImage(url)),
      eagerError: false
    );

    final validImages = [
      for (var i = 0; i < initialImages.length; i++)
        if (results[i]) initialImages[i]
    ];

    return validImages.isEmpty ? [_fallbackImage] : validImages;
  }
}

class ValidatedNetworkImage extends StatelessWidget {
  final String imageUrl;
  final BoxFit fit;
  final double? width;
  final double? height;

  const ValidatedNetworkImage({
    super.key,
    required this.imageUrl,
    this.fit = BoxFit.cover,
    this.width,
    this.height,
  });

  @override
  Widget build(BuildContext context) {
    if (imageUrl.startsWith('assets/')) {
      return Image.asset(
        imageUrl,
        fit: fit,
        width: width,
        height: height,
      );
    }

    return Image.network(
      imageUrl,
      fit: fit,
      width: width,
      height: height,
      errorBuilder: (context, error, stackTrace) {
        return Image.asset(
          ImageValidator._fallbackImage,
          fit: fit,
          width: width,
          height: height,
        );
      },
      loadingBuilder: (context, child, loadingProgress) {
        if (loadingProgress == null) return child;
        return SizedBox(
          width: width,
          height: height,
          child: Center(
            child: CircularProgressIndicator(
              value: loadingProgress.expectedTotalBytes != null
                  ? loadingProgress.cumulativeBytesLoaded / loadingProgress.expectedTotalBytes!
                  : null,
            ),
          ),
        );
      },
      headers: const {'Accept': 'image/*'},
      cacheWidth: 800,
    );
  }
}
