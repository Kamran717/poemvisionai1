import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:flutter/foundation.dart';
import 'session_service.dart';
import '../config/api_config.dart';

class PaymentService {
  late SessionService _sessionService;
  
  Future<void> _initSession() async {
    _sessionService = await SessionService.getInstance();
  }

  Future<Map<String, String>> _getHeaders() async {
    await _initSession();
    
    final baseHeaders = {
      'Content-Type': 'application/json',
      'Accept': 'application/json',
      'X-Requested-With': 'XMLHttpRequest',
    };
    
    // Use the same session management as ApiService
    return _sessionService.addSessionHeaders(baseHeaders);
  }

  Future<void> _handleResponse(http.Response response) async {
    await _initSession();
    
    // Extract and store session cookie if present
    final sessionCookie = _sessionService.extractSessionCookie(response.headers);
    if (sessionCookie != null) {
      await _sessionService.setSessionCookie(sessionCookie);
    }
  }
  
  Future<Map<String, dynamic>> getUpgradeDetails() async {
    try {
      final headers = await _getHeaders();
      
      debugPrint('Sending upgrade request with headers: $headers');
      
      final response = await http.get(
        Uri.parse('${ApiConfig.baseUrl}/upgrade'),
        headers: headers,
      );

      await _handleResponse(response);

      debugPrint('Upgrade details response status: ${response.statusCode}');
      debugPrint('Upgrade details response body: ${response.body}');
      
      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        debugPrint('Upgrade details response: $data');
        return data;
      } else if (response.statusCode == 401) {
        // User needs to be logged in
        throw Exception('Authentication required. Please log in to upgrade.');
      } else {
        throw Exception('Failed to get upgrade details: ${response.statusCode}');
      }
    } catch (e) {
      debugPrint('Error getting upgrade details: $e');
      if (e is Exception) {
        rethrow;
      }
      throw Exception('Failed to connect to payment service');
    }
  }

  Future<Map<String, dynamic>> createSubscription({
    required String paymentMethodId,
    required Map<String, dynamic> billingDetails,
  }) async {
    try {
      final requestBody = {
        'payment_method_id': paymentMethodId,
        'billing_details': billingDetails,
      };

      debugPrint('Creating subscription with: $requestBody');

      final headers = await _getHeaders();
      final response = await http.post(
        Uri.parse('${ApiConfig.baseUrl}/upgrade'),
        headers: headers,
        body: json.encode(requestBody),
      );

      await _handleResponse(response);

      debugPrint('Subscription response status: ${response.statusCode}');
      debugPrint('Subscription response body: ${response.body}');

      final data = json.decode(response.body);

      if (response.statusCode == 200) {
        return data;
      } else {
        throw Exception(data['error'] ?? 'Payment failed');
      }
    } catch (e) {
      debugPrint('Error creating subscription: $e');
      if (e is Exception) {
        rethrow;
      }
      throw Exception('Failed to process payment');
    }
  }

  Future<Map<String, dynamic>> getMembershipPlans() async {
    try {
      final headers = await _getHeaders();
      final response = await http.get(
        Uri.parse('${ApiConfig.baseUrl}/membership'),
        headers: headers,
      );

      await _handleResponse(response);

      debugPrint('Membership plans response status: ${response.statusCode}');
      
      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        debugPrint('Membership plans response: $data');
        return data;
      } else {
        throw Exception('Failed to get membership plans: ${response.statusCode}');
      }
    } catch (e) {
      debugPrint('Error getting membership plans: $e');
      throw Exception('Failed to load membership plans');
    }
  }

  Future<Map<String, dynamic>> cancelSubscription() async {
    try {
      final headers = await _getHeaders();
      final response = await http.post(
        Uri.parse('${ApiConfig.baseUrl}/cancel-subscription'),
        headers: headers,
      );

      await _handleResponse(response);

      debugPrint('Cancel subscription response status: ${response.statusCode}');
      
      final data = json.decode(response.body);

      if (response.statusCode == 200) {
        return data;
      } else {
        throw Exception(data['error'] ?? 'Failed to cancel subscription');
      }
    } catch (e) {
      debugPrint('Error canceling subscription: $e');
      if (e is Exception) {
        rethrow;
      }
      throw Exception('Failed to cancel subscription');
    }
  }
}
