/// Exception class for API related errors
class ApiException implements Exception {
  final String message;
  final ApiExceptionType code;
  final int? statusCode;
  final dynamic rawData;

  ApiException({
    required this.message,
    required this.code,
    this.statusCode,
    this.rawData,
  });

  @override
  String toString() => message;

  /// Returns true if the error is due to network issues
  bool get isNetworkError => code == ApiExceptionType.network;

  /// Returns true if the error is due to timeout
  bool get isTimeoutError => code == ApiExceptionType.timeout;

  /// Returns true if the error is due to server issues
  bool get isServerError => code == ApiExceptionType.server;

  /// Returns true if the error is due to unauthorized access
  bool get isUnauthorizedError => code == ApiExceptionType.unauthorized;

  /// Returns true if the error is due to not found resource
  bool get isNotFoundError => code == ApiExceptionType.notFound;
  
  /// Returns true if the error is due to forbidden access
  bool get isForbiddenError => code == ApiExceptionType.forbidden;
  
  /// Returns true if the error is a validation error
  bool get isValidationError => code == ApiExceptionType.validation;
  
  /// Returns true if the error is due to connection issues
  bool get isConnectionError => 
      code == ApiExceptionType.network || 
      code == ApiExceptionType.timeout;
  
  /// Returns true if the error requires authentication
  bool get requiresAuthentication => 
      code == ApiExceptionType.unauthorized || 
      code == ApiExceptionType.forbidden;
}

/// Types of API exceptions
enum ApiExceptionType {
  /// Network error (no internet connection)
  network,
  
  /// Timeout error
  timeout,
  
  /// Server error (500)
  server,
  
  /// Unauthorized error (401)
  unauthorized,
  
  /// Forbidden error (403)
  forbidden,
  
  /// Not found error (404)
  notFound,
  
  /// Validation error
  validation,
  
  /// Unknown error
  unknown,
}
