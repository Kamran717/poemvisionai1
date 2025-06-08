import 'dart:convert';
import 'package:hive_flutter/hive_flutter.dart';
import 'package:frontend/core/utils/app_logger.dart';

/// Manages offline data storage using Hive database
class OfflineDatabase {
  static const String userBoxName = 'user_box';
  static const String creationsBoxName = 'creations_box';
  static const String poemTypesBoxName = 'poem_types_box';
  static const String membershipPlansBoxName = 'membership_plans_box';
  static const String settingsBoxName = 'settings_box';
  static const String cacheBoxName = 'cache_box';
  
  /// Initialize Hive database
  static Future<void> init() async {
    try {
      await Hive.initFlutter();
      
      // Open all boxes
      await Future.wait([
        Hive.openBox(userBoxName),
        Hive.openBox(creationsBoxName),
        Hive.openBox(poemTypesBoxName),
        Hive.openBox(membershipPlansBoxName),
        Hive.openBox(settingsBoxName),
        Hive.openBox(cacheBoxName),
      ]);
      
      AppLogger.d('Hive database initialized successfully');
    } catch (e) {
      AppLogger.e('Error initializing Hive database', e);
      rethrow;
    }
  }
  
  /// Close all Hive boxes
  static Future<void> close() async {
    try {
      await Hive.close();
      AppLogger.d('Hive database closed successfully');
    } catch (e) {
      AppLogger.e('Error closing Hive database', e);
    }
  }
  
  /// Save data to a box
  static Future<void> saveData(String boxName, String key, dynamic data) async {
    try {
      final box = await _getBox(boxName);
      
      // Convert data to string if it's a map or list
      if (data is Map || data is List) {
        data = jsonEncode(data);
      }
      
      await box.put(key, data);
      AppLogger.d('Data saved to $boxName: $key');
    } catch (e) {
      AppLogger.e('Error saving data to $boxName: $key', e);
      rethrow;
    }
  }
  
  /// Get data from a box
  static Future<dynamic> getData(String boxName, String key, {dynamic defaultValue}) async {
    try {
      final box = await _getBox(boxName);
      final data = box.get(key, defaultValue: defaultValue);
      
      // Try to decode JSON if it's a string
      if (data is String) {
        try {
          return jsonDecode(data);
        } catch (_) {
          return data;
        }
      }
      
      return data;
    } catch (e) {
      AppLogger.e('Error getting data from $boxName: $key', e);
      return defaultValue;
    }
  }
  
  /// Delete data from a box
  static Future<void> deleteData(String boxName, String key) async {
    try {
      final box = await _getBox(boxName);
      await box.delete(key);
      AppLogger.d('Data deleted from $boxName: $key');
    } catch (e) {
      AppLogger.e('Error deleting data from $boxName: $key', e);
      rethrow;
    }
  }
  
  /// Clear all data from a box
  static Future<void> clearBox(String boxName) async {
    try {
      final box = await _getBox(boxName);
      await box.clear();
      AppLogger.d('Box cleared: $boxName');
    } catch (e) {
      AppLogger.e('Error clearing box: $boxName', e);
      rethrow;
    }
  }
  
  /// Get all keys from a box
  static Future<List<dynamic>> getAllKeys(String boxName) async {
    try {
      final box = await _getBox(boxName);
      return box.keys.toList();
    } catch (e) {
      AppLogger.e('Error getting keys from $boxName', e);
      return [];
    }
  }
  
  /// Get all values from a box
  static Future<List<dynamic>> getAllValues(String boxName) async {
    try {
      final box = await _getBox(boxName);
      return box.values.toList();
    } catch (e) {
      AppLogger.e('Error getting values from $boxName', e);
      return [];
    }
  }
  
  /// Get all entries from a box
  static Future<Map<dynamic, dynamic>> getAllEntries(String boxName) async {
    try {
      final box = await _getBox(boxName);
      final Map<dynamic, dynamic> result = {};
      
      for (var key in box.keys) {
        result[key] = box.get(key);
      }
      
      return result;
    } catch (e) {
      AppLogger.e('Error getting entries from $boxName', e);
      return {};
    }
  }
  
  /// Check if a key exists in a box
  static Future<bool> containsKey(String boxName, String key) async {
    try {
      final box = await _getBox(boxName);
      return box.containsKey(key);
    } catch (e) {
      AppLogger.e('Error checking key in $boxName: $key', e);
      return false;
    }
  }
  
  /// Helper method to get a box
  static Future<Box> _getBox(String boxName) async {
    if (!Hive.isBoxOpen(boxName)) {
      return await Hive.openBox(boxName);
    }
    return Hive.box(boxName);
  }
  
  /// Save user profile data
  static Future<void> saveUserProfile(Map<String, dynamic> userData) async {
    await saveData(userBoxName, 'profile', userData);
  }
  
  /// Get user profile data
  static Future<Map<String, dynamic>?> getUserProfile() async {
    return await getData(userBoxName, 'profile');
  }
  
  /// Save auth tokens
  static Future<void> saveAuthTokens({
    required String accessToken,
    required String refreshToken,
    required DateTime expiresAt,
  }) async {
    final tokenData = {
      'access_token': accessToken,
      'refresh_token': refreshToken,
      'expires_at': expiresAt.toIso8601String(),
    };
    
    await saveData(userBoxName, 'auth_tokens', tokenData);
  }
  
  /// Get auth tokens
  static Future<Map<String, dynamic>?> getAuthTokens() async {
    return await getData(userBoxName, 'auth_tokens');
  }
  
  /// Clear auth data on logout
  static Future<void> clearAuthData() async {
    await deleteData(userBoxName, 'auth_tokens');
    await deleteData(userBoxName, 'profile');
  }
  
  /// Save creations
  static Future<void> saveCreations(List<Map<String, dynamic>> creations) async {
    await saveData(creationsBoxName, 'all_creations', creations);
  }
  
  /// Save a single creation
  static Future<void> saveCreation(String id, Map<String, dynamic> creation) async {
    await saveData(creationsBoxName, id, creation);
  }
  
  /// Get all creations
  static Future<List<Map<String, dynamic>>?> getCreations() async {
    final creations = await getData(creationsBoxName, 'all_creations');
    if (creations == null) return null;
    
    if (creations is List) {
      return creations.cast<Map<String, dynamic>>();
    }
    
    return null;
  }
  
  /// Get a single creation
  static Future<Map<String, dynamic>?> getCreation(String id) async {
    return await getData(creationsBoxName, id);
  }
  
  /// Delete a creation
  static Future<void> deleteCreation(String id) async {
    await deleteData(creationsBoxName, id);
    
    // Also update the all_creations list
    final allCreations = await getCreations();
    if (allCreations != null) {
      final updatedCreations = allCreations.where((creation) => 
        creation['id'] != id
      ).toList();
      
      await saveCreations(updatedCreations);
    }
  }
  
  /// Save poem types
  static Future<void> savePoemTypes(List<Map<String, dynamic>> poemTypes) async {
    await saveData(poemTypesBoxName, 'all_poem_types', poemTypes);
  }
  
  /// Get poem types
  static Future<List<Map<String, dynamic>>?> getPoemTypes() async {
    final poemTypes = await getData(poemTypesBoxName, 'all_poem_types');
    if (poemTypes == null) return null;
    
    if (poemTypes is List) {
      return poemTypes.cast<Map<String, dynamic>>();
    }
    
    return null;
  }
  
  /// Save membership plans
  static Future<void> saveMembershipPlans(List<Map<String, dynamic>> plans) async {
    await saveData(membershipPlansBoxName, 'all_plans', plans);
  }
  
  /// Get membership plans
  static Future<List<Map<String, dynamic>>?> getMembershipPlans() async {
    final plans = await getData(membershipPlansBoxName, 'all_plans');
    if (plans == null) return null;
    
    if (plans is List) {
      return plans.cast<Map<String, dynamic>>();
    }
    
    return null;
  }
  
  /// Save app settings
  static Future<void> saveSettings(Map<String, dynamic> settings) async {
    await saveData(settingsBoxName, 'app_settings', settings);
  }
  
  /// Get app settings
  static Future<Map<String, dynamic>?> getSettings() async {
    return await getData(settingsBoxName, 'app_settings');
  }
  
  /// Save a setting value
  static Future<void> saveSetting(String key, dynamic value) async {
    final settings = await getSettings() ?? {};
    settings[key] = value;
    await saveSettings(settings);
  }
  
  /// Get a setting value
  static Future<dynamic> getSetting(String key, {dynamic defaultValue}) async {
    final settings = await getSettings();
    if (settings == null) return defaultValue;
    return settings[key] ?? defaultValue;
  }
  
  /// Cache API response
  static Future<void> cacheApiResponse(String endpoint, dynamic data, {Duration? expiry}) async {
    final cacheData = {
      'data': data,
      'timestamp': DateTime.now().toIso8601String(),
      'expiry': expiry?.inSeconds,
    };
    
    await saveData(cacheBoxName, endpoint, cacheData);
  }
  
  /// Get cached API response
  static Future<dynamic> getCachedApiResponse(String endpoint) async {
    final cachedData = await getData(cacheBoxName, endpoint);
    if (cachedData == null) return null;
    
    // Check if cache is expired
    final timestamp = DateTime.parse(cachedData['timestamp']);
    final expiry = cachedData['expiry'];
    
    if (expiry != null) {
      final expiryDuration = Duration(seconds: expiry);
      final now = DateTime.now();
      
      if (now.difference(timestamp) > expiryDuration) {
        // Cache expired
        await deleteData(cacheBoxName, endpoint);
        return null;
      }
    }
    
    return cachedData['data'];
  }
  
  /// Clear expired cache
  static Future<void> clearExpiredCache() async {
    try {
      final box = await _getBox(cacheBoxName);
      final now = DateTime.now();
      
      for (var key in box.keys) {
        final cachedData = box.get(key);
        if (cachedData == null) continue;
        
        // Try to parse the cached data
        Map<String, dynamic> data;
        if (cachedData is String) {
          try {
            data = jsonDecode(cachedData);
          } catch (_) {
            continue;
          }
        } else if (cachedData is Map) {
          data = Map<String, dynamic>.from(cachedData);
        } else {
          continue;
        }
        
        // Check if cache is expired
        if (!data.containsKey('timestamp') || !data.containsKey('expiry')) continue;
        
        final timestamp = DateTime.parse(data['timestamp']);
        final expiry = data['expiry'];
        
        if (expiry != null) {
          final expiryDuration = Duration(seconds: expiry);
          
          if (now.difference(timestamp) > expiryDuration) {
            // Cache expired
            await box.delete(key);
          }
        }
      }
    } catch (e) {
      AppLogger.e('Error clearing expired cache', e);
    }
  }
}
