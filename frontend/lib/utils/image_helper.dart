import 'dart:io';
import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

class ImageHelper {
  /// Displays an image from a base64 string with a fallback
  static Widget displayBase64Image(String? base64Image, {double? width, double? height}) {
    if (base64Image == null || base64Image.isEmpty || base64Image == 'mock_image_data') {
      return _buildPlaceholder(width: width, height: height);
    }
    
    try {
      return Image.memory(
        base64Decode(base64Image),
        width: width,
        height: height,
        fit: BoxFit.cover,
        errorBuilder: (context, error, stackTrace) {
          return _buildErrorWidget(width: width, height: height);
        },
      );
    } catch (e) {
      return _buildErrorWidget(width: width, height: height);
    }
  }
  
  /// Displays an image from a file with a fallback
  static Widget displayFileImage(File? file, {double? width, double? height}) {
    if (file == null) {
      return _buildPlaceholder(width: width, height: height);
    }
    
    return Image.file(
      file,
      width: width,
      height: height,
      fit: BoxFit.cover,
      errorBuilder: (context, error, stackTrace) {
        return _buildErrorWidget(width: width, height: height);
      },
    );
  }
  
  /// Displays an image from an asset with a fallback
  static Widget displayAssetImage(String assetPath, {double? width, double? height}) {
    return Image.asset(
      assetPath,
      width: width,
      height: height,
      fit: BoxFit.cover,
      errorBuilder: (context, error, stackTrace) {
        return _buildErrorWidget(width: width, height: height);
      },
    );
  }
  
  /// Creates a placeholder for when an image is null or empty
  static Widget _buildPlaceholder({double? width, double? height}) {
    return Container(
      width: width,
      height: height,
      color: Colors.grey.shade200,
      child: const Center(
        child: Icon(
          Icons.image,
          size: 40,
          color: Colors.grey,
        ),
      ),
    );
  }
  
  /// Creates an error widget for when an image fails to load
  static Widget _buildErrorWidget({double? width, double? height}) {
    return Container(
      width: width,
      height: height,
      color: Colors.grey.shade200,
      child: const Center(
        child: Icon(
          Icons.broken_image,
          size: 40,
          color: Colors.red,
        ),
      ),
    );
  }
  
  /// Helper method to decode base64 data
  static Uint8List base64Decode(String base64String) {
    String sanitized = base64String;
    
    // Remove any prefix like "data:image/jpeg;base64,"
    if (base64String.contains(',')) {
      sanitized = base64String.split(',')[1];
    }
    
    return base64.decode(sanitized);
  }
}
