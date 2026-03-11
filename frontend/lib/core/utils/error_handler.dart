import 'dart:io';
import 'package:dio/dio.dart';
import '../constants/app_constants.dart';
import '../utils/app_logger.dart';

/// Custom exception types for better error handling
abstract class AppException implements Exception {
  final String message;
  final String? code;
  final dynamic details;

  const AppException(this.message, {this.code, this.details});

  @override
  String toString() => message;
}

/// Network related exceptions
class NetworkException extends AppException {
  const NetworkException(super.message, {super.code, super.details});
}

/// API related exceptions
class ApiException extends AppException {
  final int? statusCode;

  ApiException(super.message, {this.statusCode, super.code, super.details});
}

/// Validation exceptions
class ValidationException extends AppException {
  final Map<String, String>? fieldErrors;
  final int? statusCode;

  const ValidationException(super.message, {this.fieldErrors, this.statusCode, super.code, super.details});
}

/// Authentication exceptions
class AuthException extends AppException {
  final int? statusCode;

  const AuthException(super.message, {this.statusCode, super.code, super.details});
}

/// Cache exceptions
class CacheException extends AppException {
  const CacheException(super.message, {super.code, super.details});
}

/// Permission exceptions
class PermissionException extends AppException {
  final int? statusCode;

  const PermissionException(super.message, {this.statusCode, super.code, super.details});
}

/// Error handler utility class
class ErrorHandler {
  /// Handle Dio exceptions and convert to appropriate AppException
  static AppException handleDioException(DioException dioException) {
    AppLogger.error('Dio exception occurred', error: dioException, stackTrace: dioException.stackTrace);
    
    switch (dioException.type) {
      case DioExceptionType.connectionTimeout:
      case DioExceptionType.sendTimeout:
      case DioExceptionType.receiveTimeout:
        return const NetworkException(ErrorMessages.timeout);
        
      case DioExceptionType.badResponse:
        return _handleHttpResponse(dioException.response!);
        
      case DioExceptionType.cancel:
        return const NetworkException('Request was cancelled');
        
      case DioExceptionType.connectionError:
        return const NetworkException(ErrorMessages.noInternet);
        
      case DioExceptionType.unknown:
        if (dioException.error is SocketException) {
          return const NetworkException(ErrorMessages.noInternet);
        }
        return NetworkException(
          ErrorMessages.somethingWentWrong,
          details: dioException.error.toString(),
        );
        
      default:
        return NetworkException(
          ErrorMessages.somethingWentWrong,
          details: dioException.message,
        );
    }
  }
  
  /// Handle HTTP response errors
  static AppException _handleHttpResponse(Response response) {
    final statusCode = response.statusCode ?? 0;
    final message = response.statusMessage ?? 'Unknown error';
    
    AppLogger.error('HTTP error: $statusCode - $message', tag: 'HTTP');
    
    switch (statusCode) {
      case 400:
        return ApiException('Bad request: $message', statusCode: statusCode);
      case 401:
        return const AuthException(ErrorMessages.unauthorized, statusCode: 401);
      case 403:
        return const PermissionException(ErrorMessages.forbidden, statusCode: 403);
      case 404:
        return ApiException(ErrorMessages.notFound, statusCode: 404);
      case 422:
        return ValidationException(
          'Validation error: $message',
          statusCode: statusCode,
          fieldErrors: _extractFieldErrors(response.data),
        );
      case 429:
        return ApiException('Too many requests', statusCode: 429);
      case 500:
      case 502:
      case 503:
      case 504:
        return ApiException(ErrorMessages.serverError, statusCode: statusCode);
      default:
        return ApiException(
          'HTTP Error $statusCode: $message',
          statusCode: statusCode,
        );
    }
  }
  
  /// Extract field errors from response data
  static Map<String, String>? _extractFieldErrors(dynamic data) {
    if (data is Map<String, dynamic> && data.containsKey('errors')) {
      final errors = data['errors'];
      if (errors is Map<String, dynamic>) {
        return errors.map((key, value) => MapEntry(key, value.toString()));
      }
    }
    return null;
  }
  
  /// Handle general exceptions
  static AppException handleException(Exception exception) {
    AppLogger.error('Exception occurred', error: exception);
    
    if (exception is AppException) {
      return exception;
    }
    
    if (exception is SocketException) {
      return const NetworkException(ErrorMessages.noInternet);
    }
    
    if (exception is FormatException) {
      return const NetworkException('Invalid data format');
    }
    
    if (exception is HttpException) {
      return NetworkException(
        'HTTP Error: ${exception.message}',
        details: exception,
      );
    }
    
    return NetworkException(
      ErrorMessages.somethingWentWrong,
      details: exception.toString(),
    );
  }
  
  /// Get user-friendly error message
  static String getUserMessage(AppException exception) {
    AppLogger.debug('Getting user message for exception: ${exception.runtimeType}');
    
    if (exception is NetworkException) {
      return exception.message;
    }
    
    if (exception is ApiException) {
      switch (exception.statusCode) {
        case 401:
          return 'Please log in to continue';
        case 403:
          return 'You don\'t have permission to perform this action';
        case 404:
          return 'The requested resource was not found';
        case 422:
          return 'Please check your input and try again';
        case 429:
          return 'Too many requests. Please try again later';
        case final code when code != null && code >= 500:
          return 'Server is temporarily unavailable. Please try again later';
        default:
          return exception.message;
      }
    }
    
    if (exception is ValidationException) {
      return exception.message;
    }
    
    if (exception is AuthException) {
      return exception.message;
    }
    
    if (exception is PermissionException) {
      return exception.message;
    }
    
    if (exception is CacheException) {
      return 'Data storage error. Please try again';
    }
    
    return exception.message;
  }
  
  /// Check if exception is recoverable
  static bool isRecoverable(AppException exception) {
    if (exception is NetworkException) {
      return true; // Network issues are usually recoverable
    }
    
    if (exception is ApiException) {
      switch (exception.statusCode) {
        case 429: // Rate limit
        case 500: // Server error
        case 502: // Bad gateway
        case 503: // Service unavailable
        case 504: // Gateway timeout
          return true;
        default:
          return false;
      }
    }
    
    return false;
  }
  
  /// Get retry delay for recoverable exceptions
  static Duration getRetryDelay(AppException exception, int attemptNumber) {
    const baseDelay = AppConstants.retryDelay;
    const maxDelay = Duration(seconds: 30);
    
    if (exception is ApiException && exception.statusCode == 429) {
      // For rate limiting, use exponential backoff
      final delay = baseDelay * (1 << (attemptNumber - 1));
      return delay > maxDelay ? maxDelay : delay;
    }
    
    // For other recoverable errors, use linear backoff
    final delay = baseDelay * attemptNumber;
    return delay > maxDelay ? maxDelay : delay;
  }
}

/// Result wrapper for better error handling
class Result<T> {
  final T? data;
  final AppException? error;
  final bool isSuccess;
  
  const Result._({required this.isSuccess, this.data, this.error});
  
  factory Result.success(T data) => Result._(data: data, isSuccess: true);
  factory Result.failure(AppException error) => Result._(error: error, isSuccess: false);
  
  /// Execute a function and return Result
  static Future<Result<T>> guard<T>(Future<T> Function() function) async {
    try {
      final data = await function();
      return Result.success(data);
    } on Exception catch (exception) {
      final appException = ErrorHandler.handleException(exception);
      return Result.failure(appException);
    }
  }
  
  /// Execute a synchronous function and return Result
  static Result<T> guardSync<T>(T Function() function) {
    try {
      final data = function();
      return Result.success(data);
    } on Exception catch (exception) {
      final appException = ErrorHandler.handleException(exception);
      return Result.failure(appException);
    }
  }
  
  /// Map success data
  Result<R> map<R>(R Function(T data) mapper) {
    if (isSuccess && data != null) {
      return Result.success(mapper(data!));
    }
    return Result.failure(error!);
  }
  
  /// Handle both success and error cases
  R fold<R>(R Function(T data) onSuccess, R Function(AppException error) onError) {
    if (isSuccess && data != null) {
      return onSuccess(data!);
    }
    return onError(error!);
  }
}
