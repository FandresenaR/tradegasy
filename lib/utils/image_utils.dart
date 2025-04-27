import 'dart:io';
import 'dart:ui' as ui;
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:path_provider/path_provider.dart';

class ImageUtils {
  // Singleton instance
  static final ImageUtils _instance = ImageUtils._internal();
  factory ImageUtils() => _instance;
  ImageUtils._internal();

  // Cache for preloaded images
  final Map<String, ui.Image> _imageCache = {};

  // Preload app logo for faster display
  Future<void> preloadAppLogo(BuildContext context) async {
    try {
      // Preload the app logo with increased timeout
      await _cacheImage('assets/images/logo.png').timeout(
        const Duration(seconds: 15),
        onTimeout: () {
          print('Logo preloading timed out, trying alternative method');
          return null;
        },
      );

      // Also create a copy in local storage for persistence with retry
      for (int attempt = 1; attempt <= 3; attempt++) {
        try {
          await _saveImageToLocalStorage(
            'assets/images/logo.png',
            'app_logo.png',
          ).timeout(const Duration(seconds: 10));
          break; // Break if successful
        } catch (e) {
          print('Attempt $attempt failed: $e');
          if (attempt == 3) rethrow;
          await Future.delayed(
            Duration(seconds: attempt),
          ); // Exponential backoff
        }
      }

      print('App logo preloaded successfully');
    } catch (e) {
      print('Error preloading app logo: $e');
    }
  }

  // Cache image in memory
  Future<ui.Image?> _cacheImage(String assetPath) async {
    if (_imageCache.containsKey(assetPath)) {
      return _imageCache[assetPath];
    }

    try {
      final ByteData data = await rootBundle.load(assetPath);
      final Uint8List bytes = data.buffer.asUint8List();
      final ui.Codec codec = await ui.instantiateImageCodec(bytes);
      final ui.FrameInfo frameInfo = await codec.getNextFrame();

      _imageCache[assetPath] = frameInfo.image;
      return frameInfo.image;
    } catch (e) {
      print('Error caching image $assetPath: $e');
      return null;
    }
  }

  // Save image to local storage for persistence
  Future<String?> _saveImageToLocalStorage(
    String assetPath,
    String fileName,
  ) async {
    try {
      final ByteData data = await rootBundle.load(assetPath);
      final Uint8List bytes = data.buffer.asUint8List();

      final Directory directory = await getApplicationDocumentsDirectory();
      final String path = '${directory.path}/$fileName';

      final File file = File(path);
      await file.writeAsBytes(bytes);

      return path;
    } catch (e) {
      print('Error saving image to local storage: $e');
      return null;
    }
  }

  // Get image from local storage or assets
  Future<ImageProvider> getAppLogo() async {
    try {
      // Use a safe approach to handle potential plugin issues
      Directory? directory;
      try {
        directory = await getApplicationDocumentsDirectory();
      } catch (e) {
        print('Path provider error: $e');
        // Fall back to asset directly if path_provider fails
        return const AssetImage('assets/images/logo.png');
      }

      final String path = '${directory.path}/app_logo.png';
      final File file = File(path);

      if (await file.exists()) {
        return FileImage(file);
      } else {
        // Fall back to asset
        return const AssetImage('assets/images/logo.png');
      }
    } catch (e) {
      print('Error getting app logo: $e');
      // Default fallback
      return const AssetImage('assets/images/logo.png');
    }
  }

  // Clear image cache
  void clearCache() {
    _imageCache.clear();
  }
}
