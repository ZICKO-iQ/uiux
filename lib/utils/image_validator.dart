import 'dart:async';
import 'package:flutter/material.dart';

class ImageValidator {
  static Future<bool> isValidImage(String imageUrl) async {
    try {
      final ImageProvider provider = NetworkImage(imageUrl);
      final ImageStream stream = provider.resolve(ImageConfiguration.empty);
      final Completer<bool> completer = Completer<bool>();
      
      final ImageStreamListener listener = ImageStreamListener(
        (ImageInfo info, bool synchronousCall) {
          completer.complete(true);
        },
        onError: (dynamic exception, StackTrace? stackTrace) {
          completer.complete(false);
        },
      );
      
      stream.addListener(listener);
      final bool isValid = await completer.future;
      stream.removeListener(listener);
      
      return isValid;
    } catch (e) {
      return false;
    }
  }

  static Future<List<String>> filterValidImages(List<String> images) async {
    final List<String> validImages = [];
    
    for (final String image in images) {
      if (await isValidImage(image)) {
        validImages.add(image);
      }
    }
    
    return validImages.isEmpty ? ['assets/images/placeholder.png'] : validImages;
  }
}
