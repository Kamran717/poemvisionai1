import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:http/http.dart' as http;

class SessionService {
  static const String _sessionCookieKey = 'session_cookie';
  static const String _userIdKey = 'user_id';
  static const String _tempCreationsKey = 'temp_creations';
  static const String _authTokenKey = 'auth_token';
  
  static SessionService? _instance;
  SharedPreferences? _prefs;
  String? _sessionCookie;
  
  SessionService._();
  
  static Future<SessionService> getInstance() async {
    _instance ??= SessionService._();
    await _instance!._init();
    return _instance!;
  }
  
  Future<void> _init() async {
    _prefs = await SharedPreferences.getInstance();
    _sessionCookie = _prefs?.getString(_sessionCookieKey);
  }
  
  // Session cookie management
  String? get sessionCookie => _sessionCookie;
  
  Future<void> setSessionCookie(String cookie) async {
    _sessionCookie = cookie;
    await _prefs?.setString(_sessionCookieKey, cookie);
  }
  
  Future<void> clearSessionCookie() async {
    _sessionCookie = null;
    await _prefs?.remove(_sessionCookieKey);
  }
  
  // User session management
  Future<void> setUserId(int userId) async {
    await _prefs?.setInt(_userIdKey, userId);
  }
  
  int? getUserId() {
    return _prefs?.getInt(_userIdKey);
  }
  
  Future<void> clearUserId() async {
    await _prefs?.remove(_userIdKey);
  }
  
  // Authentication token management
  Future<void> setAuthToken(String token) async {
    await _prefs?.setString(_authTokenKey, token);
  }
  
  String? getAuthToken() {
    return _prefs?.getString(_authTokenKey);
  }
  
  Future<void> clearAuthToken() async {
    await _prefs?.remove(_authTokenKey);
  }
  
  // Temporary creation management for analysis IDs
  Future<void> storeTempCreation(String analysisId, Map<String, dynamic> creationData) async {
    final tempCreations = getTempCreations();
    tempCreations[analysisId] = {
      ...creationData,
      'timestamp': DateTime.now().millisecondsSinceEpoch,
    };
    
    // Clean up old entries (older than 1 hour)
    final now = DateTime.now().millisecondsSinceEpoch;
    tempCreations.removeWhere((key, value) {
      final timestamp = value['timestamp'] as int? ?? 0;
      return now - timestamp > 3600000; // 1 hour in milliseconds
    });
    
    await _prefs?.setString(_tempCreationsKey, jsonEncode(tempCreations));
  }
  
  Map<String, dynamic> getTempCreations() {
    final stored = _prefs?.getString(_tempCreationsKey);
    if (stored == null) return {};
    
    try {
      return Map<String, dynamic>.from(jsonDecode(stored));
    } catch (e) {
      print('Error parsing temp creations: $e');
      return {};
    }
  }
  
  Map<String, dynamic>? getTempCreation(String analysisId) {
    final tempCreations = getTempCreations();
    return tempCreations[analysisId];
  }
  
  Future<void> removeTempCreation(String analysisId) async {
    final tempCreations = getTempCreations();
    tempCreations.remove(analysisId);
    await _prefs?.setString(_tempCreationsKey, jsonEncode(tempCreations));
  }
  
  Future<void> clearTempCreations() async {
    await _prefs?.remove(_tempCreationsKey);
  }
  
  // Extract session cookie from response headers
  String? extractSessionCookie(Map<String, String> responseHeaders) {
    final setCookieHeader = responseHeaders['set-cookie'];
    if (setCookieHeader != null) {
      // Parse the session cookie from Set-Cookie header
      final cookies = setCookieHeader.split(';');
      for (final cookie in cookies) {
        if (cookie.trim().startsWith('session=')) {
          return cookie.trim();
        }
      }
    }
    return null;
  }
  
  // Add session headers to requests
  Map<String, String> addSessionHeaders(Map<String, String> headers) {
    final modifiedHeaders = Map<String, String>.from(headers);
    
    if (_sessionCookie != null) {
      modifiedHeaders['cookie'] = _sessionCookie!;
    }
    
    final authToken = getAuthToken();
    if (authToken != null) {
      modifiedHeaders['authorization'] = 'Bearer $authToken';
    }
    
    return modifiedHeaders;
  }
  
  // Full session cleanup
  Future<void> clearSession() async {
    await clearSessionCookie();
    await clearUserId();
    await clearAuthToken();
    await clearTempCreations();
  }
  
  // Check if session is valid
  bool get isSessionValid {
    return _sessionCookie != null || getAuthToken() != null;
  }
  
  // Session persistence and restoration
  Future<void> persistSession() async {
    // This is called automatically when setting values
    // Can be extended for additional persistence logic
  }
  
  Future<void> restoreSession() async {
    await _init();
    // Additional restoration logic can be added here
  }
}
