import 'dart:async';
import 'dart:convert';
import 'package:dio/dio.dart';
import 'package:connectivity_plus/connectivity_plus.dart';
import 'package:frontend/core/constants/api_constants.dart';
import 'package:frontend/core/network/network_error_handler.dart';
import 'package:frontend/core/utils/app_logger.dart';

/// API client for making HTTP requests
class ApiClient {
  /// Base URL for API requests
  final String baseUrl;
  
  /// Dio HTTP client
  final Dio dio;
  
  /// Connectivity checker
  final Connectivity connectivity;
  
  /// Network error handler
  final NetworkErrorHandler errorHandler;
  
  /// Default request timeout
  static const Duration _defaultTimeout = Duration(seconds: 30);
  
  /// Max retry attempts
  static const int _maxRetries = 3;
  
  /// Constructor
  ApiClient({
    required this.baseUrl,
    required this.dio,
    required this.connectivity,
    required this.errorHandler,
  }) {
    _initializeDio();
  }
  
  /// Initialize Dio with interceptors and default options
  void _initializeDio() {
    dio.options = BaseOptions(
      baseUrl: baseUrl,
      connectTimeout: _defaultTimeout,
      receiveTimeout: _defaultTimeout,
      sendTimeout: _defaultTimeout,
      contentType: Headers.jsonContentType,
      responseType: ResponseType.json,
    );
    
    dio.interceptors.add(
      InterceptorsWrapper(
        onRequest: (options, handler) {
          AppLogger.d('API REQUEST: ${options.method} ${options.uri}');
          if (options.data != null && options.data is! FormData) {
            try {
              AppLogger.d('REQUEST DATA: ${jsonEncode(options.data)}');
            } catch (e) {
              AppLogger.d('REQUEST DATA: (not JSON serializable)');
            }
          }
          return handler.next(options);
        },
        onResponse: (response, handler) {
          AppLogger.d('API RESPONSE [${response.statusCode}]: ${response.requestOptions.uri}');
          return handler.next(response);
        },
        onError: (error, handler) {
          AppLogger.e(
            'API ERROR [${error.response?.statusCode}]: ${error.requestOptions.uri}',
            error,
          );
          return handler.next(error);
        },
      ),
    );
  }
  
  /// Set auth token for requests
  void setToken(String token) {
    dio.options.headers['Authorization'] = 'Bearer $token';
  }
  
  /// Clear auth token
  void clearToken() {
    dio.options.headers.remove('Authorization');
  }
  
  /// Check if device is connected to the internet
  Future<bool> _isConnected() async {
    final result = await connectivity.checkConnectivity();
    return result != ConnectivityResult.none;
  }
  
  /// Make a GET request
  Future<dynamic> get(
    String path, {
    Map<String, dynamic>? queryParameters,
    Options? options,
    CancelToken? cancelToken,
    ProgressCallback? onReceiveProgress,
    int retryCount = 0,
  }) async {
    try {
      if (!await _isConnected()) {
        throw DioException(
          requestOptions: RequestOptions(path: path),
          type: DioExceptionType.connectionError,
          error: 'No internet connection',
        );
      }
      
      final response = await dio.get(
        path,
        queryParameters: queryParameters,
        options: options,
        cancelToken: cancelToken,
        onReceiveProgress: onReceiveProgress,
      );
      
      return response.data;
    } catch (e) {
      if (_shouldRetry(e, retryCount)) {
        return get(
          path,
          queryParameters: queryParameters,
          options: options,
          cancelToken: cancelToken,
          onReceiveProgress: onReceiveProgress,
          retryCount: retryCount + 1,
        );
      }
      
      throw errorHandler.handleError(e);
    }
  }
  
  /// Make a POST request
  Future<dynamic> post(
    String path, {
    dynamic data,
    Map<String, dynamic>? queryParameters,
    Options? options,
    CancelToken? cancelToken,
    ProgressCallback? onSendProgress,
    ProgressCallback? onReceiveProgress,
    int retryCount = 0,
  }) async {
    try {
      if (!await _isConnected()) {
        throw DioException(
          requestOptions: RequestOptions(path: path),
          type: DioExceptionType.connectionError,
          error: 'No internet connection',
        );
      }
      
      final response = await dio.post(
        path,
        data: data,
        queryParameters: queryParameters,
        options: options,
        cancelToken: cancelToken,
        onSendProgress: onSendProgress,
        onReceiveProgress: onReceiveProgress,
      );
      
      return response.data;
    } catch (e) {
      if (_shouldRetry(e, retryCount)) {
        return post(
          path,
          data: data,
          queryParameters: queryParameters,
          options: options,
          cancelToken: cancelToken,
          onSendProgress: onSendProgress,
          onReceiveProgress: onReceiveProgress,
          retryCount: retryCount + 1,
        );
      }
      
      throw errorHandler.handleError(e);
    }
  }
  
  /// Make a PUT request
  Future<dynamic> put(
    String path, {
    dynamic data,
    Map<String, dynamic>? queryParameters,
    Options? options,
    CancelToken? cancelToken,
    ProgressCallback? onSendProgress,
    ProgressCallback? onReceiveProgress,
    int retryCount = 0,
  }) async {
    try {
      if (!await _isConnected()) {
        throw DioException(
          requestOptions: RequestOptions(path: path),
          type: DioExceptionType.connectionError,
          error: 'No internet connection',
        );
      }
      
      final response = await dio.put(
        path,
        data: data,
        queryParameters: queryParameters,
        options: options,
        cancelToken: cancelToken,
        onSendProgress: onSendProgress,
        onReceiveProgress: onReceiveProgress,
      );
      
      return response.data;
    } catch (e) {
      if (_shouldRetry(e, retryCount)) {
        return put(
          path,
          data: data,
          queryParameters: queryParameters,
          options: options,
          cancelToken: cancelToken,
          onSendProgress: onSendProgress,
          onReceiveProgress: onReceiveProgress,
          retryCount: retryCount + 1,
        );
      }
      
      throw errorHandler.handleError(e);
    }
  }
  
  /// Make a PATCH request
  Future<dynamic> patch(
    String path, {
    dynamic data,
    Map<String, dynamic>? queryParameters,
    Options? options,
    CancelToken? cancelToken,
    ProgressCallback? onSendProgress,
    ProgressCallback? onReceiveProgress,
    int retryCount = 0,
  }) async {
    try {
      if (!await _isConnected()) {
        throw DioException(
          requestOptions: RequestOptions(path: path),
          type: DioExceptionType.connectionError,
          error: 'No internet connection',
        );
      }
      
      final response = await dio.patch(
        path,
        data: data,
        queryParameters: queryParameters,
        options: options,
        cancelToken: cancelToken,
        onSendProgress: onSendProgress,
        onReceiveProgress: onReceiveProgress,
      );
      
      return response.data;
    } catch (e) {
      if (_shouldRetry(e, retryCount)) {
        return patch(
          path,
          data: data,
          queryParameters: queryParameters,
          options: options,
          cancelToken: cancelToken,
          onSendProgress: onSendProgress,
          onReceiveProgress: onReceiveProgress,
          retryCount: retryCount + 1,
        );
      }
      
      throw errorHandler.handleError(e);
    }
  }
  
  /// Make a DELETE request
  Future<dynamic> delete(
    String path, {
    dynamic data,
    Map<String, dynamic>? queryParameters,
    Options? options,
    CancelToken? cancelToken,
    int retryCount = 0,
  }) async {
    try {
      if (!await _isConnected()) {
        throw DioException(
          requestOptions: RequestOptions(path: path),
          type: DioExceptionType.connectionError,
          error: 'No internet connection',
        );
      }
      
      final response = await dio.delete(
        path,
        data: data,
        queryParameters: queryParameters,
        options: options,
        cancelToken: cancelToken,
      );
      
      return response.data;
    } catch (e) {
      if (_shouldRetry(e, retryCount)) {
        return delete(
          path,
          data: data,
          queryParameters: queryParameters,
          options: options,
          cancelToken: cancelToken,
          retryCount: retryCount + 1,
        );
      }
      
      throw errorHandler.handleError(e);
    }
  }
  
  /// Determine if request should be retried
  bool _shouldRetry(dynamic error, int retryCount) {
    if (retryCount >= _maxRetries) {
      return false;
    }
    
    if (error is DioException) {
      return error.type == DioExceptionType.connectionTimeout ||
          error.type == DioExceptionType.sendTimeout ||
          error.type == DioExceptionType.receiveTimeout ||
          error.type == DioExceptionType.connectionError;
    }
    
    return false;
  }
  
  /// Get user profile
  Future<Map<String, dynamic>> getProfile() async {
    return await get(ApiConstants.profile);
  }
  
  /// Update user profile
  Future<Map<String, dynamic>> updateProfile({
    String? name,
    String? email,
    String? bio,
  }) async {
    final data = <String, dynamic>{};
    
    if (name != null) data['name'] = name;
    if (email != null) data['email'] = email;
    if (bio != null) data['bio'] = bio;
    
    return await put(ApiConstants.updateProfile, data: data);
  }
  
  /// Get membership plans
  Future<Map<String, dynamic>> getMembershipPlans() async {
    return await get(ApiConstants.membershipPlans);
  }
  
  /// Subscribe to a membership plan
  Future<Map<String, dynamic>> subscribeToPlan(String planId) async {
    return await post('${ApiConstants.membershipPlans}/$planId/subscribe');
  }
  
  /// Cancel subscription
  Future<Map<String, dynamic>> cancelSubscription() async {
    return await post(ApiConstants.cancelSubscription);
  }
}
