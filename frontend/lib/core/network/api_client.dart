import 'dart:io';
import 'package:dio/dio.dart';
import 'package:frontend/core/utils/app_logger.dart';
import 'package:frontend/core/network/api_response.dart';
import 'package:frontend/core/network/api_exception.dart';
import 'package:frontend/core/constants/api_constants.dart';

/// API client for handling network requests
class ApiClient {
  final Dio _dio;
  
  ApiClient(this._dio) {
    _dio.options.baseUrl = ApiConstants.baseUrl;
    
    // Add authorization interceptor
    _dio.interceptors.add(
      InterceptorsWrapper(
        onRequest: (options, handler) async {
          // This is where we would add the auth token if we have one
          // Will be implemented when we build the auth module
          
          AppLogger.d('API Request: ${options.method} ${options.path}');
          return handler.next(options);
        },
        onResponse: (response, handler) {
          AppLogger.d('API Response [${response.statusCode}]: ${response.requestOptions.path}');
          return handler.next(response);
        },
        onError: (DioException error, handler) {
          AppLogger.e(
            'API Error [${error.response?.statusCode}]: ${error.requestOptions.path}',
            error,
            error.stackTrace,
          );
          return handler.next(error);
        },
      ),
    );
  }
  
  /// Perform a GET request
  Future<ApiResponse<T>> get<T>(
    String path, {
    Map<String, dynamic>? queryParameters,
    Options? options,
    CancelToken? cancelToken,
    ProgressCallback? onReceiveProgress,
  }) async {
    try {
      final response = await _dio.get<dynamic>(
        path,
        queryParameters: queryParameters,
        options: options,
        cancelToken: cancelToken,
        onReceiveProgress: onReceiveProgress,
      );
      
      return ApiResponse<T>.success(response.data);
    } on DioException catch (e) {
      return _handleError<T>(e);
    } catch (e) {
      return ApiResponse<T>.error(
        ApiException(
          message: e.toString(),
          code: ApiExceptionType.unknown,
        ),
      );
    }
  }
  
  /// Perform a POST request
  Future<ApiResponse<T>> post<T>(
    String path, {
    dynamic data,
    Map<String, dynamic>? queryParameters,
    Options? options,
    CancelToken? cancelToken,
    ProgressCallback? onSendProgress,
    ProgressCallback? onReceiveProgress,
  }) async {
    try {
      final response = await _dio.post<dynamic>(
        path,
        data: data,
        queryParameters: queryParameters,
        options: options,
        cancelToken: cancelToken,
        onSendProgress: onSendProgress,
        onReceiveProgress: onReceiveProgress,
      );
      
      return ApiResponse<T>.success(response.data);
    } on DioException catch (e) {
      return _handleError<T>(e);
    } catch (e) {
      return ApiResponse<T>.error(
        ApiException(
          message: e.toString(),
          code: ApiExceptionType.unknown,
        ),
      );
    }
  }
  
  /// Upload image and analyze
  Future<ApiResponse<Map<String, dynamic>>> analyzeImage(File imageFile) async {
    try {
      String fileName = imageFile.path.split('/').last;
      FormData formData = FormData.fromMap({
        "image": await MultipartFile.fromFile(
          imageFile.path,
          filename: fileName,
        ),
      });
      
      final response = await _dio.post<dynamic>(
        ApiConstants.analyzeImage,
        data: formData,
        options: Options(
          contentType: 'multipart/form-data',
        ),
      );
      
      return ApiResponse<Map<String, dynamic>>.success(response.data);
    } on DioException catch (e) {
      return _handleError<Map<String, dynamic>>(e);
    } catch (e) {
      return ApiResponse<Map<String, dynamic>>.error(
        ApiException(
          message: e.toString(),
          code: ApiExceptionType.unknown,
        ),
      );
    }
  }
  
  /// Generate poem from analysis
  Future<ApiResponse<Map<String, dynamic>>> generatePoem({
    required String analysisId,
    required String poemType,
    required String poemLength,
    List<String>? emphasis,
    Map<String, dynamic>? customPrompt,
    bool isRegeneration = false,
  }) async {
    try {
      final data = {
        'analysisId': analysisId,
        'poemType': poemType,
        'poemLength': poemLength,
        'emphasis': emphasis ?? [],
        'isRegeneration': isRegeneration,
      };
      
      if (customPrompt != null) {
        data['customPrompt'] = customPrompt;
      }
      
      final response = await _dio.post<dynamic>(
        ApiConstants.generatePoem,
        data: data,
      );
      
      return ApiResponse<Map<String, dynamic>>.success(response.data);
    } on DioException catch (e) {
      return _handleError<Map<String, dynamic>>(e);
    } catch (e) {
      return ApiResponse<Map<String, dynamic>>.error(
        ApiException(
          message: e.toString(),
          code: ApiExceptionType.unknown,
        ),
      );
    }
  }
  
  /// Create final image with poem
  Future<ApiResponse<Map<String, dynamic>>> createFinalImage({
    required String analysisId,
    required String frameStyle,
  }) async {
    try {
      final data = {
        'analysisId': analysisId,
        'frameStyle': frameStyle,
      };
      
      final response = await _dio.post<dynamic>(
        ApiConstants.createFinalImage,
        data: data,
      );
      
      return ApiResponse<Map<String, dynamic>>.success(response.data);
    } on DioException catch (e) {
      return _handleError<Map<String, dynamic>>(e);
    } catch (e) {
      return ApiResponse<Map<String, dynamic>>.error(
        ApiException(
          message: e.toString(),
          code: ApiExceptionType.unknown,
        ),
      );
    }
  }
  
  /// Login user
  Future<ApiResponse<Map<String, dynamic>>> login({
    required String email,
    required String password,
  }) async {
    try {
      final data = {
        'email': email,
        'password': password,
      };
      
      final response = await _dio.post<dynamic>(
        ApiConstants.login,
        data: FormData.fromMap(data),
      );
      
      return ApiResponse<Map<String, dynamic>>.success(response.data);
    } on DioException catch (e) {
      return _handleError<Map<String, dynamic>>(e);
    } catch (e) {
      return ApiResponse<Map<String, dynamic>>.error(
        ApiException(
          message: e.toString(),
          code: ApiExceptionType.unknown,
        ),
      );
    }
  }
  
  /// Register user
  Future<ApiResponse<Map<String, dynamic>>> signup({
    required String username,
    required String email,
    required String password,
    required String confirmPassword,
  }) async {
    try {
      final data = {
        'username': username,
        'email': email,
        'password': password,
        'confirm_password': confirmPassword,
      };
      
      final response = await _dio.post<dynamic>(
        ApiConstants.signup,
        data: FormData.fromMap(data),
      );
      
      return ApiResponse<Map<String, dynamic>>.success(response.data);
    } on DioException catch (e) {
      return _handleError<Map<String, dynamic>>(e);
    } catch (e) {
      return ApiResponse<Map<String, dynamic>>.error(
        ApiException(
          message: e.toString(),
          code: ApiExceptionType.unknown,
        ),
      );
    }
  }
  
  /// Get user profile
  Future<ApiResponse<Map<String, dynamic>>> getUserProfile() async {
    try {
      final response = await _dio.get<dynamic>(ApiConstants.profile);
      
      return ApiResponse<Map<String, dynamic>>.success(response.data);
    } on DioException catch (e) {
      return _handleError<Map<String, dynamic>>(e);
    } catch (e) {
      return ApiResponse<Map<String, dynamic>>.error(
        ApiException(
          message: e.toString(),
          code: ApiExceptionType.unknown,
        ),
      );
    }
  }
  
  /// Get available poem types
  Future<ApiResponse<Map<String, dynamic>>> getAvailablePoemTypes() async {
    try {
      final response = await _dio.get<dynamic>(ApiConstants.availablePoemTypes);
      
      return ApiResponse<Map<String, dynamic>>.success(response.data);
    } on DioException catch (e) {
      return _handleError<Map<String, dynamic>>(e);
    } catch (e) {
      return ApiResponse<Map<String, dynamic>>.error(
        ApiException(
          message: e.toString(),
          code: ApiExceptionType.unknown,
        ),
      );
    }
  }
  
  /// Get available frames
  Future<ApiResponse<Map<String, dynamic>>> getAvailableFrames() async {
    try {
      final response = await _dio.get<dynamic>(ApiConstants.availableFrames);
      
      return ApiResponse<Map<String, dynamic>>.success(response.data);
    } on DioException catch (e) {
      return _handleError<Map<String, dynamic>>(e);
    } catch (e) {
      return ApiResponse<Map<String, dynamic>>.error(
        ApiException(
          message: e.toString(),
          code: ApiExceptionType.unknown,
        ),
      );
    }
  }
  
  /// Get creation by share code
  Future<ApiResponse<Map<String, dynamic>>> getSharedCreation(String shareCode) async {
    try {
      final response = await _dio.get<dynamic>(
        '${ApiConstants.shared}/$shareCode',
      );
      
      return ApiResponse<Map<String, dynamic>>.success(response.data);
    } on DioException catch (e) {
      return _handleError<Map<String, dynamic>>(e);
    } catch (e) {
      return ApiResponse<Map<String, dynamic>>.error(
        ApiException(
          message: e.toString(),
          code: ApiExceptionType.unknown,
        ),
      );
    }
  }
  
  /// Delete creation
  Future<ApiResponse<Map<String, dynamic>>> deleteCreation(int creationId) async {
    try {
      final response = await _dio.delete<dynamic>(
        '${ApiConstants.deleteCreation}/$creationId',
      );
      
      return ApiResponse<Map<String, dynamic>>.success(response.data);
    } on DioException catch (e) {
      return _handleError<Map<String, dynamic>>(e);
    } catch (e) {
      return ApiResponse<Map<String, dynamic>>.error(
        ApiException(
          message: e.toString(),
          code: ApiExceptionType.unknown,
        ),
      );
    }
  }
  
  /// Handle error responses
  ApiResponse<T> _handleError<T>(DioException exception) {
    ApiExceptionType code = ApiExceptionType.unknown;
    String message = 'An unexpected error occurred';
    
    if (exception.type == DioExceptionType.connectionTimeout ||
        exception.type == DioExceptionType.sendTimeout ||
        exception.type == DioExceptionType.receiveTimeout) {
      code = ApiExceptionType.timeout;
      message = 'Connection timed out';
    } else if (exception.type == DioExceptionType.connectionError) {
      code = ApiExceptionType.network;
      message = 'No internet connection';
    } else if (exception.response != null) {
      final statusCode = exception.response!.statusCode;
      
      if (statusCode == 401) {
        code = ApiExceptionType.unauthorized;
        message = 'Unauthorized access';
      } else if (statusCode == 403) {
        code = ApiExceptionType.forbidden;
        message = 'Access forbidden';
      } else if (statusCode == 404) {
        code = ApiExceptionType.notFound;
        message = 'Resource not found';
      } else if (statusCode == 500) {
        code = ApiExceptionType.server;
        message = 'Server error';
      }
      
      // Try to get error message from response
      try {
        if (exception.response?.data != null &&
            exception.response!.data is Map<String, dynamic> &&
            exception.response!.data['error'] != null) {
          message = exception.response!.data['error'].toString();
        }
      } catch (_) {
        // Ignore parsing errors
      }
    }
    
    return ApiResponse<T>.error(
      ApiException(
        message: message,
        code: code,
        statusCode: exception.response?.statusCode,
      ),
    );
  }
}
