import 'dart:io';
import 'package:dio/dio.dart';
import 'package:frontend/core/utils/app_logger.dart';
import 'package:frontend/core/network/api_exception.dart';

/// Handler for network errors
class NetworkErrorHandler {
  /// Constructor
  const NetworkErrorHandler();
  
  /// Handle error and convert it to ApiException
  ApiException handleError(dynamic error) {
    if (error is ApiException) {
      return error;
    }
    
    if (error is DioException) {
      return _handleDioError(error);
    }
    
    if (error is SocketException) {
      return ApiException(
        message: 'No internet connection',
        code: ApiExceptionType.noInternet,
      );
    }
    
    // Handle any other errors
    AppLogger.e('Unhandled error', error);
    return ApiException(
      message: 'An unexpected error occurred',
      code: ApiExceptionType.unknown,
      data: error.toString(),
    );
  }
  
  /// Handle Dio errors
  ApiException _handleDioError(DioException error) {
    switch (error.type) {
      case DioExceptionType.cancel:
        return ApiException(
          message: 'Request was cancelled',
          code: ApiExceptionType.cancelled,
        );
        
      case DioExceptionType.connectionTimeout:
      case DioExceptionType.receiveTimeout:
      case DioExceptionType.sendTimeout:
        return ApiException(
          message: 'Connection timeout',
          code: ApiExceptionType.timeout,
        );
        
      case DioExceptionType.connectionError:
        return ApiException(
          message: 'No internet connection',
          code: ApiExceptionType.noInternet,
        );
        
      case DioExceptionType.badResponse:
        return _handleResponseError(
          error.response?.statusCode ?? 0,
          error.response?.data,
        );
        
      case DioExceptionType.unknown:
      default:
        if (error.error is SocketException) {
          return ApiException(
            message: 'No internet connection',
            code: ApiExceptionType.noInternet,
          );
        }
        
        return ApiException(
          message: 'An unexpected error occurred',
          code: ApiExceptionType.unknown,
          data: error.message,
        );
    }
  }
  
  /// Handle response errors based on status code
  ApiException _handleResponseError(int statusCode, dynamic data) {
    switch (statusCode) {
      case 400:
        // Bad request
        final String message = _extractErrorMessage(data) ?? 'Bad request';
        final Map<String, dynamic>? validationErrors = _extractValidationErrors(data);
        
        return ApiException(
          message: message,
          code: ApiExceptionType.badRequest,
          data: data,
          validationErrors: validationErrors,
        );
        
      case 401:
        // Unauthorized
        return ApiException(
          message: _extractErrorMessage(data) ?? 'Unauthorized',
          code: ApiExceptionType.unauthorized,
          data: data,
        );
        
      case 403:
        // Forbidden
        return ApiException(
          message: _extractErrorMessage(data) ?? 'Forbidden',
          code: ApiExceptionType.forbidden,
          data: data,
        );
        
      case 404:
        // Not found
        return ApiException(
          message: _extractErrorMessage(data) ?? 'Not found',
          code: ApiExceptionType.notFound,
          data: data,
        );
        
      case 409:
        // Conflict
        return ApiException(
          message: _extractErrorMessage(data) ?? 'Conflict',
          code: ApiExceptionType.conflict,
          data: data,
        );
        
      case 422:
        // Validation error
        final String message = _extractErrorMessage(data) ?? 'Validation error';
        final Map<String, dynamic>? validationErrors = _extractValidationErrors(data);
        
        return ApiException(
          message: message,
          code: ApiExceptionType.validation,
          data: data,
          validationErrors: validationErrors,
        );
        
      case 429:
        // Too many requests
        return ApiException(
          message: _extractErrorMessage(data) ?? 'Too many requests',
          code: ApiExceptionType.tooManyRequests,
          data: data,
        );
        
      case 500:
      case 501:
      case 502:
      case 503:
        // Server error
        return ApiException(
          message: _extractErrorMessage(data) ?? 'Server error',
          code: ApiExceptionType.serverError,
          data: data,
        );
        
      default:
        // Unknown error
        return ApiException(
          message: _extractErrorMessage(data) ?? 'Unknown error',
          code: ApiExceptionType.unknown,
          data: data,
        );
    }
  }
  
  /// Extract error message from response data
  String? _extractErrorMessage(dynamic data) {
    if (data == null) {
      return null;
    }
    
    if (data is Map<String, dynamic>) {
      // Check common error message fields
      if (data['message'] != null) {
        return data['message'] as String;
      }
      
      if (data['error'] != null) {
        if (data['error'] is String) {
          return data['error'] as String;
        } else if (data['error'] is Map && data['error']['message'] != null) {
          return data['error']['message'] as String;
        }
      }
      
      if (data['errors'] != null && data['errors'] is List && (data['errors'] as List).isNotEmpty) {
        final firstError = (data['errors'] as List).first;
        if (firstError is String) {
          return firstError;
        } else if (firstError is Map && firstError['message'] != null) {
          return firstError['message'] as String;
        }
      }
    }
    
    return null;
  }
  
  /// Extract validation errors from response data
  Map<String, dynamic>? _extractValidationErrors(dynamic data) {
    if (data == null || data is! Map<String, dynamic>) {
      return null;
    }
    
    // Check common validation error fields
    if (data['errors'] != null && data['errors'] is Map<String, dynamic>) {
      return data['errors'] as Map<String, dynamic>;
    }
    
    if (data['validationErrors'] != null && data['validationErrors'] is Map<String, dynamic>) {
      return data['validationErrors'] as Map<String, dynamic>;
    }
    
    return null;
  }
  
  /// Get user-friendly error message
  String getUserFriendlyErrorMessage(ApiException exception) {
    switch (exception.code) {
      case ApiExceptionType.noInternet:
        return 'Please check your internet connection and try again.';
        
      case ApiExceptionType.timeout:
        return 'The request timed out. Please try again later.';
        
      case ApiExceptionType.unauthorized:
        return 'You are not authorized to perform this action. Please log in again.';
        
      case ApiExceptionType.forbidden:
        return 'You do not have permission to perform this action.';
        
      case ApiExceptionType.notFound:
        return 'The requested resource was not found.';
        
      case ApiExceptionType.validation:
        return 'Please check your input and try again.';
        
      case ApiExceptionType.serverError:
        return 'There was a problem with the server. Please try again later.';
        
      case ApiExceptionType.tooManyRequests:
        return 'You\'ve made too many requests. Please try again later.';
        
      case ApiExceptionType.cancelled:
        return 'The request was cancelled.';
        
      case ApiExceptionType.noResponse:
        return 'No response received from the server. Please try again.';
        
      case ApiExceptionType.badRequest:
      case ApiExceptionType.conflict:
      case ApiExceptionType.unknown:
      default:
        // Use the original message if it's user-friendly enough
        if (exception.message.isNotEmpty) {
          return exception.message;
        }
        return 'An unexpected error occurred. Please try again later.';
    }
  }
}
