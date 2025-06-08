import 'dart:convert';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';

/// A wrapper for FlutterSecureStorage to provide a more convenient API
/// for storing sensitive information like authentication tokens
class SecureStorage {
  final FlutterSecureStorage _storage;
  
  SecureStorage(this._storage);
  
  /// Save a string value securely
  Future<void> setString(String key, String value) async {
    await _storage.write(key: key, value: value);
  }
  
  /// Get a string value
  Future<String?> getString(String key) async {
    return await _storage.read(key: key);
  }
  
  /// Save an object as JSON securely
  Future<void> setObject(String key, Map<String, dynamic> value) async {
    await _storage.write(key: key, value: json.encode(value));
  }
  
  /// Get an object from JSON
  Future<Map<String, dynamic>?> getObject(String key) async {
    final jsonString = await _storage.read(key: key);
    if (jsonString == null) {
      return null;
    }
    return json.decode(jsonString) as Map<String, dynamic>;
  }
  
  /// Check if a key exists
  Future<bool> containsKey(String key) async {
    return await _storage.containsKey(key: key);
  }
  
  /// Remove a key-value pair
  Future<void> remove(String key) async {
    await _storage.delete(key: key);
  }
  
  /// Clear all data
  Future<void> clear() async {
    await _storage.deleteAll();
  }
  
  /// Helper method for storing authentication token
  Future<void> setAuthToken(String token) async {
    await setString('auth_token', token);
  }
  
  /// Helper method for retrieving authentication token
  Future<String?> getAuthToken() async {
    return await getString('auth_token');
  }
  
  /// Helper method for storing user information
  Future<void> setUserInfo(Map<String, dynamic> userInfo) async {
    await setObject('user_info', userInfo);
  }
  
  /// Helper method for retrieving user information
  Future<Map<String, dynamic>?> getUserInfo() async {
    return await getObject('user_info');
  }
  
  /// Helper method for clearing authentication data
  Future<void> clearAuthData() async {
    await remove('auth_token');
    await remove('user_info');
  }
}
