import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';

/// A wrapper for SharedPreferences to provide a more convenient API
class LocalStorage {
  final SharedPreferences _prefs;
  
  LocalStorage(this._prefs);
  
  /// Save a string value
  Future<bool> setString(String key, String value) async {
    return await _prefs.setString(key, value);
  }
  
  /// Get a string value
  String? getString(String key) {
    return _prefs.getString(key);
  }
  
  /// Save a boolean value
  Future<bool> setBool(String key, bool value) async {
    return await _prefs.setBool(key, value);
  }
  
  /// Get a boolean value
  bool? getBool(String key) {
    return _prefs.getBool(key);
  }
  
  /// Save an integer value
  Future<bool> setInt(String key, int value) async {
    return await _prefs.setInt(key, value);
  }
  
  /// Get an integer value
  int? getInt(String key) {
    return _prefs.getInt(key);
  }
  
  /// Save a double value
  Future<bool> setDouble(String key, double value) async {
    return await _prefs.setDouble(key, value);
  }
  
  /// Get a double value
  double? getDouble(String key) {
    return _prefs.getDouble(key);
  }
  
  /// Save a list of strings
  Future<bool> setStringList(String key, List<String> value) async {
    return await _prefs.setStringList(key, value);
  }
  
  /// Get a list of strings
  List<String>? getStringList(String key) {
    return _prefs.getStringList(key);
  }
  
  /// Save an object as JSON
  Future<bool> setObject(String key, Map<String, dynamic> value) async {
    return await _prefs.setString(key, json.encode(value));
  }
  
  /// Get an object from JSON
  Map<String, dynamic>? getObject(String key) {
    final jsonString = _prefs.getString(key);
    if (jsonString == null) {
      return null;
    }
    return json.decode(jsonString) as Map<String, dynamic>;
  }
  
  /// Check if a key exists
  bool containsKey(String key) {
    return _prefs.containsKey(key);
  }
  
  /// Remove a key-value pair
  Future<bool> remove(String key) async {
    return await _prefs.remove(key);
  }
  
  /// Clear all data
  Future<bool> clear() async {
    return await _prefs.clear();
  }
}
