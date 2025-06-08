import 'dart:convert';
import 'package:dio/dio.dart';
import 'package:connectivity_plus/connectivity_plus.dart';
import 'package:retry/retry.dart';
import 'package:frontend/core/network/api_response.dart';
import 'package:frontend/core/network/api_exception.dart';
import 'package:frontend/core/network/network_error_handler.dart';
import 'package:frontend/core/utils/app_logger.dart';

/// Client for API requests
class ApiClient {
  final Dio _dio;
  final Connectivity _connectivity = Connectivity();
  
  ApiClient(this._dio) {
    _setupInterceptors();
  }
  
  /// Configure Dio interceptors
  void _setupInterceptors() {
    _dio.interceptors.add(
      InterceptorsWrapper(
        onRequest: (options, handler) {
          AppLogger.d('API Request: ${options.method} ${options.uri}');
          return handler.next(options);
        },
        onResponse: (response, handler) {
          AppLogger.d('API Response: ${response.statusCode} ${response.requestOptions.uri}');
          return handler.next(response);
        },
        onError: (DioException error, handler) {
          AppLogger.e('API Error: ${error.requestOptions.uri}', error);
          return handler.next(error);
        },
      ),
    );
  }
  
  /// Add authentication token to request headers
  void setAuthToken(String token) {
    _dio.options.headers['Authorization'] = 'Bearer $token';
  }
  
  /// Remove authentication token from request headers
  void clearAuthToken() {
    _dio.options.headers.remove('Authorization');
  }
  
  /// Check if device is connected to the internet
  Future<bool> _checkConnectivity() async {
    final connectivityResult = await _connectivity.checkConnectivity();
    return connectivityResult != ConnectivityResult.none;
  }
  
  /// Perform a GET request with retry logic
  Future<ApiResponse> get(
    String path, {
    Map<String, dynamic>? queryParameters,
    Options? options,
    CancelToken? cancelToken,
    int maxRetries = 3,
  }) async {
    return _executeRequest(
      () => _dio.get(
        path,
        queryParameters: queryParameters,
        options: options,
        cancelToken: cancelToken,
      ),
      maxRetries: maxRetries,
    );
  }
  
  /// Perform a POST request with retry logic
  Future<ApiResponse> post(
    String path, {
    dynamic data,
    Map<String, dynamic>? queryParameters,
    Options? options,
    CancelToken? cancelToken,
    int maxRetries = 3,
  }) async {
    return _executeRequest(
      () => _dio.post(
        path,
        data: data,
        queryParameters: queryParameters,
        options: options,
        cancelToken: cancelToken,
      ),
      maxRetries: maxRetries,
    );
  }
  
  /// Perform a PUT request with retry logic
  Future<ApiResponse> put(
    String path, {
    dynamic data,
    Map<String, dynamic>? queryParameters,
    Options? options,
    CancelToken? cancelToken,
    int maxRetries = 3,
  }) async {
    return _executeRequest(
      () => _dio.put(
        path,
        data: data,
        queryParameters: queryParameters,
        options: options,
        cancelToken: cancelToken,
      ),
      maxRetries: maxRetries,
    );
  }
  
  /// Perform a PATCH request with retry logic
  Future<ApiResponse> patch(
    String path, {
    dynamic data,
    Map<String, dynamic>? queryParameters,
    Options? options,
    CancelToken? cancelToken,
    int maxRetries = 3,
  }) async {
    return _executeRequest(
      () => _dio.patch(
        path,
        data: data,
        queryParameters: queryParameters,
        options: options,
        cancelToken: cancelToken,
      ),
      maxRetries: maxRetries,
    );
  }
  
  /// Perform a DELETE request with retry logic
  Future<ApiResponse> delete(
    String path, {
    dynamic data,
    Map<String, dynamic>? queryParameters,
    Options? options,
    CancelToken? cancelToken,
    int maxRetries = 3,
  }) async {
    return _executeRequest(
      () => _dio.delete(
        path,
        data: data,
        queryParameters: queryParameters,
        options: options,
        cancelToken: cancelToken,
      ),
      maxRetries: maxRetries,
    );
  }
  
  /// Execute request with retry logic and error handling
  Future<ApiResponse> _executeRequest(
    Future<Response> Function() request, {
    int maxRetries = 3,
  }) async {
    if (!await _checkConnectivity()) {
      return ApiResponse.error(
        NetworkErrorHandler.handleError(
          ApiException(
            message: 'No internet connection',
            code: ApiExceptionType.noInternet,
          ),
        ),
      );
    }
    
    try {
      // Use retry package to automatically retry failed requests
      final response = await retry(
        () => request(),
        retryIf: (e) => _shouldRetry(e),
        maxAttempts: maxRetries,
        onRetry: (e, attempt) {
          AppLogger.d('Retrying API request (Attempt: $attempt): ${e.toString()}');
        },
      );
      
      return _processResponse(response);
    } catch (error) {
      final apiException = NetworkErrorHandler.handleError(error);
      return ApiResponse.error(apiException);
    }
  }
  
  /// Process API response
  ApiResponse _processResponse(Response response) {
    final int statusCode = response.statusCode ?? 0;
    
    if (statusCode >= 200 && statusCode < 300) {
      return ApiResponse.success(response.data);
    } else {
      final apiException = NetworkErrorHandler.handleError(response);
      return ApiResponse.error(apiException);
    }
  }
  
  /// Determine if a request should be retried
  bool _shouldRetry(Exception error) {
    if (error is DioException) {
      // Retry on connection timeout, network errors and server errors
      return error.type == DioExceptionType.connectionTimeout ||
             error.type == DioExceptionType.receiveTimeout ||
             error.type == DioExceptionType.sendTimeout ||
             error.type == DioExceptionType.connectionError ||
             (error.response != null && error.response!.statusCode != null && 
              error.response!.statusCode! >= 500 && error.response!.statusCode! < 600);
    }
    return false;
  }
  
  /// Download file with progress tracking
  Future<ApiResponse> downloadFile(
    String url,
    String savePath, {
    ProgressCallback? onReceiveProgress,
    CancelToken? cancelToken,
    int maxRetries = 3,
  }) async {
    if (!await _checkConnectivity()) {
      return ApiResponse.error(
        NetworkErrorHandler.handleError(
          ApiException(
            message: 'No internet connection',
            code: ApiExceptionType.noInternet,
          ),
        ),
      );
    }
    
    try {
      final response = await retry(
        () => _dio.download(
          url,
          savePath,
          onReceiveProgress: onReceiveProgress,
          cancelToken: cancelToken,
        ),
        retryIf: (e) => _shouldRetry(e),
        maxAttempts: maxRetries,
      );
      
      if (response.statusCode == 200) {
        return ApiResponse.success({'path': savePath});
      } else {
        throw DioException(
          requestOptions: response.requestOptions,
          response: response,
          error: 'Download failed with status: ${response.statusCode}',
        );
      }
    } catch (error) {
      final apiException = NetworkErrorHandler.handleError(error);
      return ApiResponse.error(apiException);
    }
  }
  
  /// Upload file with progress tracking
  Future<ApiResponse> uploadFile(
    String path,
    String filePath, {
    String fileField = 'file',
    Map<String, dynamic>? data,
    ProgressCallback? onSendProgress,
    CancelToken? cancelToken,
    int maxRetries = 3,
  }) async {
    if (!await _checkConnectivity()) {
      return ApiResponse.error(
        NetworkErrorHandler.handleError(
          ApiException(
            message: 'No internet connection',
            code: ApiExceptionType.noInternet,
          ),
        ),
      );
    }
    
    try {
      final formData = FormData.fromMap({
        ...?data,
        fileField: await MultipartFile.fromFile(filePath),
      });
      
      final response = await retry(
        () => _dio.post(
          path,
          data: formData,
          onSendProgress: onSendProgress,
          cancelToken: cancelToken,
        ),
        retryIf: (e) => _shouldRetry(e),
        maxAttempts: maxRetries,
      );
      
      return _processResponse(response);
    } catch (error) {
      final apiException = NetworkErrorHandler.handleError(error);
      return ApiResponse.error(apiException);
    }
  }
}
