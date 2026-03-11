import 'dart:developer' as developer;
import 'package:flutter/foundation.dart';
import '../constants/app_constants.dart';

/// Enhanced logger for the application following best practices
class AppLogger {
  static const String _tag = 'SmartLivestock';
  
  /// Log debug information
  static void debug(String message, {String? tag, dynamic error, StackTrace? stackTrace}) {
    if (!AppConstants.enableLogging || !kDebugMode) return;
    
    final logTag = tag ?? _tag;
    developer.log(
      '🔍 DEBUG: $message',
      name: logTag,
      error: error,
      stackTrace: stackTrace,
    );
  }
  
  /// Log information
  static void info(String message, {String? tag, dynamic error, StackTrace? stackTrace}) {
    if (!AppConstants.enableLogging) return;
    
    final logTag = tag ?? _tag;
    developer.log(
      'ℹ️ INFO: $message',
      name: logTag,
      error: error,
      stackTrace: stackTrace,
    );
  }
  
  /// Log warning
  static void warning(String message, {String? tag, dynamic error, StackTrace? stackTrace}) {
    if (!AppConstants.enableLogging) return;
    
    final logTag = tag ?? _tag;
    developer.log(
      '⚠️ WARNING: $message',
      name: logTag,
      error: error,
      stackTrace: stackTrace,
    );
  }
  
  /// Log error
  static void error(String message, {Object? error, StackTrace? stackTrace, String? tag}) {
    if (!AppConstants.enableLogging) return;
    
    final logTag = tag ?? _tag;
    developer.log(
      '❌ ERROR: $message',
      name: logTag,
      error: error,
      stackTrace: stackTrace,
    );
  }
  
  /// Log critical error
  static void critical(String message, {Object? error, StackTrace? stackTrace, String? tag}) {
    if (!AppConstants.enableLogging) return;
    
    final logTag = tag ?? _tag;
    developer.log(
      '🚨 CRITICAL: $message',
      name: logTag,
      error: error,
      stackTrace: stackTrace,
    );
  }
  
  /// Log network requests
  static void network(String message, {String? tag, dynamic data}) {
    if (!AppConstants.enableLogging || !kDebugMode) return;
    
    final logTag = tag ?? _tag;
    developer.log(
      '🌐 NETWORK: $message${data != null ? ' - Data: $data' : ''}',
      name: logTag,
    );
  }
  
  /// Log API request
  static void api(String method, String url, {dynamic data, String? tag}) {
    if (!AppConstants.enableLogging || !kDebugMode) return;
    
    final logTag = tag ?? _tag;
    developer.log(
      '🌐 API: $method $url${data != null ? ' - Data: $data' : ''}',
      name: logTag,
    );
  }
  
  /// Log API response
  static void apiResponse(String method, String url, int statusCode, {dynamic data, String? tag}) {
    if (!AppConstants.enableLogging || !kDebugMode) return;
    
    final logTag = tag ?? _tag;
    developer.log(
      '📡 API Response: $method $url - Status: $statusCode${data != null ? ' - Data: $data' : ''}',
      name: logTag,
    );
  }
  
  /// Log authentication events
  static void auth(String message, {String? tag, dynamic data}) {
    if (!AppConstants.enableLogging) return;
    
    final logTag = tag ?? _tag;
    developer.log(
      '🔐 AUTH: $message${data != null ? ' - Data: $data' : ''}',
      name: logTag,
    );
  }
  
  /// Log database operations
  static void database(String message, {String? tag, dynamic data}) {
    if (!AppConstants.enableLogging || !kDebugMode) return;
    
    final logTag = tag ?? _tag;
    developer.log(
      '💾 DATABASE: $message${data != null ? ' - Data: $data' : ''}',
      name: logTag,
    );
  }
  
  /// Log user actions
  static void userAction(String action, {Map<String, dynamic>? data, String? tag}) {
    if (!AppConstants.enableLogging) return;
    
    final logTag = tag ?? _tag;
    developer.log(
      '👤 USER ACTION: $action${data != null ? ' - Data: $data' : ''}',
      name: logTag,
    );
  }
  
  /// Log performance metrics
  static void performance(String operation, Duration duration, {String? tag}) {
    if (!AppConstants.enableLogging || !kDebugMode) return;
    
    final logTag = tag ?? _tag;
    developer.log(
      '⏱️ PERFORMANCE: $operation took ${duration.inMilliseconds}ms',
      name: logTag,
    );
  }
  
  /// Log state changes
  static void stateChange(String state, {String? tag, dynamic data}) {
    if (!AppConstants.enableLogging || !kDebugMode) return;
    
    final logTag = tag ?? _tag;
    developer.log(
      '🔄 STATE CHANGE: $state${data != null ? ' - Data: $data' : ''}',
      name: logTag,
    );
  }
  
  /// Log navigation events
  static void navigation(String route, {String? from, String? tag}) {
    if (!AppConstants.enableLogging) return;
    
    final logTag = tag ?? _tag;
    developer.log(
      '🧭 NAVIGATION: $route${from != null ? ' from $from' : ''}',
      name: logTag,
    );
  }
  
  /// Log validation errors
  static void validation(String field, String error, {String? tag}) {
    if (!AppConstants.enableLogging) return;
    
    final logTag = tag ?? _tag;
    developer.log(
      '🚫 VALIDATION: $field - $error',
      name: logTag,
    );
  }
  
  /// Log cache operations
  static void cache(String operation, String key, {String? tag}) {
    if (!AppConstants.enableLogging || !kDebugMode) return;
    
    final logTag = tag ?? _tag;
    developer.log(
      '💾 CACHE: $operation - $key',
      name: logTag,
    );
  }
}
