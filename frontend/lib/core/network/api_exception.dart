/// API exception types
enum ApiExceptionType {
  /// Bad request (400)
  badRequest,
  
  /// Unauthorized (401)
  unauthorized,
  
  /// Forbidden (403)
  forbidden,
  
  /// Not found (404)
  notFound,
  
  /// Conflict (409)
  conflict,
  
  /// Validation error (422)
  validation,
  
  /// Too many requests (429)
  tooManyRequests,
  
  /// Server error (500, 501, 502, 503)
  serverError,
  
  /// No internet connection
  noInternet,
  
  /// Connection timeout
  timeout,
  
  /// Request cancelled
  cancelled,
  
  /// No response received
  noResponse,
  
  /// Unknown error
  unknown,
}

/// API exception class
class ApiException implements Exception {
  /// Exception message
  final String message;
  
  /// Exception type
  final ApiExceptionType code;
  
  /// Additional data
  final dynamic data;
  
  /// Validation errors
  final Map<String, dynamic>? validationErrors;
  
  /// Constructor
  ApiException({
    required this.message,
    required this.code,
    this.data,
    this.validationErrors,
  });
  
  @override
  String toString() => message;
}
