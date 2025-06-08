import 'package:frontend/core/network/api_exception.dart';

/// A generic class that holds a value with its loading status
/// Used for UI to show proper loading/error states
class ApiResponse<T> {
  final Status status;
  final T? data;
  final ApiException? error;

  const ApiResponse._(this.status, this.data, this.error);

  /// Returns true if the request is successful
  bool get isSuccess => status == Status.success;

  /// Returns true if the request is loading
  bool get isLoading => status == Status.loading;

  /// Returns true if the request has an error
  bool get isError => status == Status.error;

  /// Factory constructor for loading state
  factory ApiResponse.loading() => const ApiResponse._(Status.loading, null, null);

  /// Factory constructor for success state
  factory ApiResponse.success(T data) => ApiResponse._(Status.success, data, null);

  /// Factory constructor for error state
  factory ApiResponse.error(ApiException error) => ApiResponse._(Status.error, null, error);

  /// Maps the current response to a new type
  ApiResponse<R> map<R>(R Function(T data) transform) {
    if (isSuccess && data != null) {
      return ApiResponse.success(transform(data!));
    } else if (isError) {
      return ApiResponse.error(error!);
    } else {
      return ApiResponse.loading();
    }
  }

  /// Handles each possible state with a function
  R when<R>({
    required R Function(T data) success,
    required R Function(ApiException error) error,
    required R Function() loading,
  }) {
    if (isLoading) {
      return loading();
    } else if (isSuccess && data != null) {
      return success(data!);
    } else if (isError && this.error != null) {
      return error(this.error!);
    } else {
      throw Exception('Invalid state');
    }
  }
}

/// Status of a network request
enum Status {
  /// Request is in progress
  loading,

  /// Request completed successfully
  success,

  /// Request completed with an error
  error,
}
