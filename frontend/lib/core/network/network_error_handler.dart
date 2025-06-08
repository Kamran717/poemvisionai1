import 'dart:io';

import 'package:dio/dio.dart';
import 'package:frontend/core/network/api_exception.dart';
import 'package:frontend/core/utils/app_logger.dart';

/// Handles network errors and provides standardized error messages
class NetworkErrorHandler {
  /// Convert various error types to ApiException
  static ApiException handleError(dynamic error) {
    AppLogger.e('Network error occurred', error);
    
    if (error is DioException) {
      return _handleDioError(error);
    } else if (error is SocketException) {
      return ApiException(
        message: 'No internet connection',
        code: ApiExceptionType.noInternet,
      );
    } else if (error is ApiException) {
      return error;
    } else {
      return ApiException(
        message: 'Unexpected error occurred',
        code: ApiExceptionType.unknown,
      );
    }
  }
  
  /// Handle Dio specific errors
  static ApiException _handleDioError(DioException error) {
    switch (error.type) {
      case DioExceptionType.connectionTimeout:
      case DioExceptionType.sendTimeout:
      case DioExceptionType.receiveTimeout:
        return ApiException(
          message: 'Connection timeout',
          code: ApiExceptionType.timeout,
        );
        
      case DioExceptionType.badResponse:
        return _handleResponseError(error.response);
        
      case DioExceptionType.cancel:
        return ApiException(
          message: 'Request cancelled',
          code: ApiExceptionType.cancelled,
        );
        
      case DioExceptionType.connectionError:
        return ApiException(
          message: 'No internet connection',
          code: ApiExceptionType.noInternet,
        );
        
      default:
        return ApiException(
          message: error.message ?? 'Unexpected error occurred',
          code: ApiExceptionType.unknown,
        );
    }
  }
  
  /// Handle response errors based on status code
  static ApiException _handleResponseError(Response? response) {
    if (response == null) {
      return ApiException(
        message: 'No response received',
        code: ApiExceptionType.noResponse,
      );
    }
    
    switch (response.statusCode) {
      case 400:
        return _handleBadRequestError(response);
        
      case 401:
        return ApiException(
          message: 'Unauthorized. Please login again',
          code: ApiExceptionType.unauthorized,
          data: response.data,
        );
        
      case 403:
        return ApiException(
          message: 'You don\'t have permission to access this resource',
          code: ApiExceptionType.forbidden,
          data: response.data,
        );
        
      case 404:
        return ApiException(
          message: 'Resource not found',
          code: ApiExceptionType.notFound,
          data: response.data,
        );
        
      case 409:
        return ApiException(
          message: 'Conflict occurred',
          code: ApiExceptionType.conflict,
          data: response.data,
        );
        
      case 422:
        return _handleValidationError(response);
        
      case 429:
        return ApiException(
          message: 'Too many requests. Please try again later',
          code: ApiExceptionType.tooManyRequests,
          data: response.data,
        );
        
      case 500:
      case 501:
      case 502:
      case 503:
        return ApiException(
          message: 'Server error. Please try again later',
          code: ApiExceptionType.serverError,
          data: response.data,
        );
        
      default:
        return ApiException(
          message: 'Unexpected error occurred',
          code: ApiExceptionType.unknown,
          data: response.data,
        );
    }
  }
  
  /// Handle 400 Bad Request errors
  static ApiException _handleBadRequestError(Response response) {
    String message = 'Invalid request';
    
    if (response.data is Map && response.data['message'] != null) {
      message = response.data['message'] as String;
    }
    
    return ApiException(
      message: message,
      code: ApiExceptionType.badRequest,
      data: response.data,
    );
  }
  
  /// Handle 422 Validation errors
  static ApiException _handleValidationError(Response response) {
    String message = 'Validation error';
    Map<String, dynamic> errors = {};
    
    if (response.data is Map) {
      if (response.data['message'] != null) {
        message = response.data['message'] as String;
      }
      
      if (response.data['errors'] is Map) {
        errors = response.data['errors'] as Map<String, dynamic>;
      }
    }
    
    return ApiException(
      message: message,
      code: ApiExceptionType.validation,
      data: response.data,
      validationErrors: errors,
    );
  }
  
  /// Get user friendly error message
  static String getUserFriendlyErrorMessage(dynamic error) {
    final exception = handleError(error);
    
    switch (exception.code) {
      case ApiExceptionType.noInternet:
        return 'Please check your internet connection and try again';
        
      case ApiExceptionType.timeout:
        return 'Connection timeout. Please try again';
        
      case ApiExceptionType.unauthorized:
        return 'Your session has expired. Please login again';
        
      case ApiExceptionType.forbidden:
        return 'You don\'t have permission to access this feature';
        
      case ApiExceptionType.notFound:
        return 'The requested resource could not be found';
        
      case ApiExceptionType.serverError:
        return 'Our servers are experiencing issues. Please try again later';
        
      case ApiExceptionType.tooManyRequests:
        return 'You\'ve made too many requests. Please wait and try again later';
        
      case ApiExceptionType.validation:
        return exception.message;
        
      default:
        return exception.message;
    }
  }
  
  /// Check if error should trigger auto-logout
  static bool shouldLogoutUser(dynamic error) {
    final exception = handleError(error);
    return exception.code == ApiExceptionType.unauthorized;
  }
  
  /// Check if error is related to network connectivity
  static bool isNetworkError(dynamic error) {
    final exception = handleError(error);
    return exception.code == ApiExceptionType.noInternet || 
           exception.code == ApiExceptionType.timeout;
  }
  
  /// Check if error is server-related
  static bool isServerError(dynamic error) {
    final exception = handleError(error);
    return exception.code == ApiExceptionType.serverError;
  }
}
